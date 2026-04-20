#!/usr/bin/env python3
"""
Batch restyle PNG assets via PixelLab v2 REST API (Edit images Pro).

Place source PNGs under asset_input/ (or pass --input). Results go to asset_output/.

Requires: pip install -r requirements.txt
Token: set PIXELLAB_API_TOKEN or pass --token (never commit tokens).
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
import os
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

import requests
from PIL import Image

API_BASE = "https://api.pixellab.ai/v2"
EDIT_ENDPOINT = f"{API_BASE}/edit-images-v2"

# PixelLab edit-images-v2: input tiles max 256x256; output image_size min 32x32 (see OpenAPI).
MAX_INPUT_SIDE = 256
MIN_OUTPUT_SIDE = 32

DEFAULT_PROMPT = (
    "Recolor as dark red ink sketch on black: keep only edge and detail lines, "
    "color them dark red (#880000), make all fill areas black (#000000)"
)
PALETTE_BLACK = (0, 0, 0)
PALETTE_DARK_RED = (136, 0, 0)
CACHE_FILE_NAME = ".restyle_cache.json"
_PRINT_LOCK = threading.Lock()


def _ui_print(message: str, error: bool = False) -> None:
    ts = time.strftime("%H:%M:%S")
    with _PRINT_LOCK:
        print(f"[{ts}] {message}", file=sys.stderr if error else sys.stdout)


def _ui_progress(done: int, total: int, ok: int, failed: int, skipped: int) -> None:
    width = 24
    filled = int((done / total) * width) if total else width
    bar = "#" * filled + "-" * (width - filled)
    _ui_print(
        f"Progress [{bar}] {done}/{total} | ok={ok} failed={failed} skipped={skipped}"
    )


def _unwrap_response(body: dict[str, Any]) -> dict[str, Any]:
    """Handle both raw JSON and { success, data } wrapper shapes."""
    if isinstance(body.get("data"), dict) and (
        "background_job_id" in body["data"] or "id" in body["data"]
    ):
        return body["data"]
    return body


def _read_job_id(post_json: dict[str, Any]) -> str:
    data = _unwrap_response(post_json)
    job_id = data.get("background_job_id") or data.get("job_id")
    if not job_id:
        raise RuntimeError(f"No background_job_id in response: {post_json!r}")
    return str(job_id)


def _prepare_image_for_api(img: Image.Image) -> tuple[Image.Image, int, int]:
    """
    Return (padded_rgb_or_rgba, width, height) valid for edit-images-v2.
    Pads to at least MIN_OUTPUT_SIDE if needed; rejects if larger than MAX_INPUT_SIDE.
    """
    w, h = img.size
    if w > MAX_INPUT_SIDE or h > MAX_INPUT_SIDE:
        raise ValueError(
            f"Image {w}x{h} exceeds API max input {MAX_INPUT_SIDE}x{MAX_INPUT_SIDE}. "
            "Split sprite sheets or resize first."
        )
    out_w = max(w, MIN_OUTPUT_SIDE)
    out_h = max(h, MIN_OUTPUT_SIDE)
    if w == out_w and h == out_h:
        return img, w, h
    # Center on min canvas (transparent for RGBA, black for RGB)
    mode = img.mode
    if mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA")
        mode = "RGBA"
    bg = (0, 0, 0, 0) if mode == "RGBA" else (0, 0, 0)
    canvas = Image.new(mode, (out_w, out_h), bg)
    ox = (out_w - w) // 2
    oy = (out_h - h) // 2
    canvas.paste(img, (ox, oy))
    return canvas, out_w, out_h


def _pil_to_png_base64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return base64.standard_b64encode(buf.getvalue()).decode("ascii")


def _is_valid_encoded_image(data: bytes) -> bool:
    """True if bytes represent a decodable encoded image payload."""
    if not data:
        return False
    try:
        with Image.open(io.BytesIO(data)) as im:
            im.verify()
        return True
    except Exception:
        return False


def _to_png_bytes(image_bytes: bytes) -> bytes:
    """Re-encode any supported image payload to PNG bytes."""
    with Image.open(io.BytesIO(image_bytes)) as im:
        out = io.BytesIO()
        im.save(out, format="PNG")
        return out.getvalue()


def _clamp_to_two_colors_png_bytes(
    image_bytes: bytes,
    color_a: tuple[int, int, int] = PALETTE_BLACK,
    color_b: tuple[int, int, int] = PALETTE_DARK_RED,
) -> bytes:
    """Force output to exactly two RGB colors using fixed-palette quantization."""
    with Image.open(io.BytesIO(image_bytes)) as im:
        rgb = im.convert("RGB")
        palette = Image.new("P", (1, 1))
        palette_data = [*color_a, *color_b] + [0, 0, 0] * (256 - 2)
        palette.putpalette(palette_data)
        quantized = rgb.quantize(palette=palette, dither=Image.Dither.NONE)
        out = io.BytesIO()
        quantized.convert("RGB").save(out, format="PNG")
        return out.getvalue()


def _rgba_bytes_obj_to_png_bytes(obj: dict[str, Any]) -> bytes | None:
    """Convert API {type: rgba_bytes, width, [height], base64} to PNG bytes."""
    if obj.get("type") != "rgba_bytes":
        return None
    if "base64" not in obj or "width" not in obj:
        return None
    try:
        raw = base64.standard_b64decode(str(obj["base64"]))
        width = int(obj["width"])
        if width <= 0:
            return None
        # 4 channels (RGBA) per pixel.
        pixels = len(raw) // 4
        if pixels == 0 or len(raw) % 4 != 0:
            return None
        height = int(obj.get("height") or (pixels // width))
        if height <= 0 or width * height * 4 != len(raw):
            return None
        image = Image.frombytes("RGBA", (width, height), raw)
        out = io.BytesIO()
        image.save(out, format="PNG")
        return out.getvalue()
    except Exception:
        return None


def _extract_first_png_bytes(last_response: dict[str, Any] | None) -> bytes:
    """Pull first PNG bytes from completed job last_response (schema varies)."""
    if not last_response:
        raise RuntimeError("Job completed but last_response is empty.")

    def from_obj(obj: Any) -> bytes | None:
        if obj is None:
            return None
        if isinstance(obj, str):
            s = obj.strip()
            if s.startswith("data:") and "base64," in s:
                s = s.split("base64,", 1)[1]
            try:
                decoded = base64.standard_b64decode(s)
                if _is_valid_encoded_image(decoded):
                    return decoded
                return None
            except Exception:
                return None
        if isinstance(obj, (bytes, bytearray)):
            raw = bytes(obj)
            if _is_valid_encoded_image(raw):
                return raw
            return None
        if isinstance(obj, dict):
            rgba_png = _rgba_bytes_obj_to_png_bytes(obj)
            if rgba_png:
                return rgba_png
            if "base64" in obj:
                return from_obj(obj["base64"])
            for k in ("image", "data", "png", "result"):
                if k in obj:
                    b = from_obj(obj[k])
                    if b:
                        return b
        if isinstance(obj, list):
            for item in obj:
                b = from_obj(item)
                if b:
                    return b
        return None

    for key in (
        "edited_images",
        "images",
        "output_images",
        "results",
        "image",
        "edited_image",
    ):
        if key in last_response:
            b = from_obj(last_response[key])
            if b:
                return b

    b = from_obj(last_response)
    if b:
        return b

    raise RuntimeError(
        "Could not find image data in last_response. Keys: "
        f"{list(last_response.keys())!r}\nFull JSON:\n{json.dumps(last_response, indent=2)[:4000]}"
    )


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _load_cache(cache_path: Path) -> dict[str, Any]:
    if not cache_path.exists():
        return {}
    try:
        raw = json.loads(cache_path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    if not isinstance(raw, dict):
        return {}
    return raw


def _save_cache(cache_path: Path, cache: dict[str, Any]) -> None:
    cache_path.write_text(json.dumps(cache, indent=2, sort_keys=True), encoding="utf-8")


def _is_cache_hit(
    cache: dict[str, Any],
    rel: str,
    src: Path,
    dst: Path,
    prompt_hash: str,
    enforce_two_colors: bool,
) -> bool:
    if not dst.exists():
        return False
    entry = cache.get(rel)
    if not isinstance(entry, dict):
        return False
    expected_input_hash = entry.get("input_sha256")
    expected_prompt_hash = entry.get("prompt_sha256")
    expected_cleanup = entry.get("enforce_two_colors")
    if not all(isinstance(v, str) for v in (expected_input_hash, expected_prompt_hash)):
        return False
    if expected_cleanup is not enforce_two_colors:
        return False
    return _sha256_file(src) == expected_input_hash and prompt_hash == expected_prompt_hash


def submit_edit(
    session: requests.Session,
    token: str,
    png_b64: str,
    width: int,
    height: int,
    description: str,
) -> str:
    payload = {
        "method": "edit_with_text",
        "description": description,
        "image_size": {"width": width, "height": height},
        "edit_images": [
            {
                "width": width,
                "height": height,
                "image": {
                    "type": "base64",
                    "base64": png_b64,
                    "format": "png",
                },
            }
        ],
        "no_background": False,
    }
    r = session.post(
        EDIT_ENDPOINT,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=120,
    )
    try:
        body = r.json()
    except Exception as exc:
        raise RuntimeError(f"Invalid JSON from edit-images-v2 ({r.status_code}): {r.text[:500]}") from exc

    if r.status_code not in (200, 202):
        err = body.get("error") or body.get("detail") or body
        raise RuntimeError(f"edit-images-v2 failed ({r.status_code}): {err}")

    return _read_job_id(body)


def poll_job(
    session: requests.Session,
    token: str,
    job_id: str,
    poll_seconds: float,
    max_wait_seconds: float = 600,
) -> dict[str, Any]:
    url = f"{API_BASE}/background-jobs/{job_id}"
    deadline = time.monotonic() + max_wait_seconds
    while time.monotonic() < deadline:
        r = session.get(
            url,
            headers={"Authorization": f"Bearer {token}"},
            timeout=60,
        )
        r.raise_for_status()
        body = r.json()
        job = _unwrap_response(body)
        status = (job.get("status") or "").lower()
        if status == "completed":
            return job
        if status == "failed":
            raise RuntimeError(f"Job failed: {job.get('last_response') or job}")
        time.sleep(poll_seconds)
    raise TimeoutError(f"Job {job_id} did not complete within {max_wait_seconds}s")


def process_one_file(
    token: str,
    src: Path,
    dst: Path,
    description: str,
    poll_seconds: float,
    dry_run: bool,
    enforce_two_colors: bool,
) -> tuple[int, int]:
    img = Image.open(src)
    img.load()
    prepared, w, h = _prepare_image_for_api(img)
    png_b64 = _pil_to_png_base64(prepared)

    if dry_run:
        return (w, h)

    dst.parent.mkdir(parents=True, exist_ok=True)
    with requests.Session() as session:
        job_id = submit_edit(session, token, png_b64, w, h, description)
        job = poll_job(session, token, job_id, poll_seconds)
    last = job.get("last_response")
    if isinstance(last, str):
        try:
            last = json.loads(last)
        except json.JSONDecodeError:
            pass
    if not isinstance(last, dict):
        raise RuntimeError(f"Unexpected last_response type: {type(last)!r}")
    image_bytes = _extract_first_png_bytes(last)
    png_bytes = _to_png_bytes(image_bytes)
    if enforce_two_colors:
        png_bytes = _clamp_to_two_colors_png_bytes(png_bytes)
    dst.write_bytes(png_bytes)
    return (w, h)


def collect_pngs(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(root.rglob("*.png")):
        if p.name == ".gitkeep":
            continue
        # Ignore Godot sidecar metadata files such as "sprite.png.import".
        if p.name.lower().endswith(".png.import"):
            continue
        if p.suffix.lower() != ".png":
            continue
        out.append(p)
    return out


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    default_in = script_dir / "asset_input"
    default_out = script_dir / "asset_output"

    p = argparse.ArgumentParser(description="Restyle PNGs via PixelLab edit-images-v2.")
    p.add_argument("--input", type=Path, default=default_in, help="Input folder (recursive PNG scan)")
    p.add_argument("--output", type=Path, default=default_out, help="Output folder (mirrors subfolders)")
    p.add_argument("--token", default=os.environ.get("PIXELLAB_API_TOKEN", ""), help="API token or set PIXELLAB_API_TOKEN")
    p.add_argument("--prompt", default=DEFAULT_PROMPT, help="Edit description sent to the API")
    p.add_argument("--poll-interval", type=float, default=1.0, help="Seconds between job status polls")
    p.add_argument("--dry-run", action="store_true", help="Only validate images, do not call API")
    p.add_argument(
        "--no-2color-cleanup",
        action="store_true",
        help="Disable post-process that clamps output to black/red only.",
    )
    p.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Number of concurrent API jobs for batch processing.",
    )
    p.add_argument(
        "--no-cache",
        action="store_true",
        help="Disable cache checks and reprocess all files.",
    )
    p.add_argument(
        "--delete-input-on-success",
        action="store_true",
        default=True,
        help="Delete source PNG after a successful (non-dry-run) process.",
    )
    p.add_argument(
        "--keep-input",
        action="store_true",
        help="Keep source PNGs even when delete-on-success is enabled by default.",
    )
    args = p.parse_args()

    token = (args.token or "").strip()
    if not token and not args.dry_run:
        print("Error: missing API token. Set PIXELLAB_API_TOKEN or pass --token.", file=sys.stderr)
        return 1

    inp: Path = args.input.resolve()
    out_root: Path = args.output.resolve()
    if not inp.is_dir():
        print(f"Error: input is not a directory: {inp}", file=sys.stderr)
        return 1

    files = collect_pngs(inp)
    if not files:
        _ui_print(f"No PNG files found under {inp}")
        return 0

    enforce_two_colors = not args.no_2color_cleanup
    delete_input_on_success = args.delete_input_on_success and (not args.keep_input)
    configured_workers = max(1, args.workers)
    prompt_hash = _sha256_bytes(args.prompt.encode("utf-8"))
    cache_path = out_root / CACHE_FILE_NAME
    cache = {} if args.no_cache else _load_cache(cache_path)
    updated_cache: dict[str, Any] = dict(cache)

    candidates: list[tuple[Path, Path, str]] = []
    skipped = 0
    for src in files:
        rel = src.relative_to(inp)
        rel_key = rel.as_posix()
        dst = out_root / rel
        if not args.no_cache and _is_cache_hit(
            cache, rel_key, src, dst, prompt_hash, enforce_two_colors
        ):
            _ui_print(f"SKIP {rel} (cache hit)")
            skipped += 1
            continue
        candidates.append((src, dst, rel_key))

    if not candidates:
        _ui_print(f"Done. Succeeded: 0, failed: 0, skipped: {skipped}")
        return 0

    workers = min(configured_workers, len(candidates))
    _ui_print(
        f"Starting batch: to_process={len(candidates)} workers={workers} "
        f"poll_interval={args.poll_interval}s cleanup_2color={enforce_two_colors}"
    )

    ok = 0
    failed = 0
    done = 0
    total = len(candidates) + skipped
    _ui_progress(done=skipped, total=total, ok=ok, failed=failed, skipped=skipped)
    if workers == 1:
        for src, dst, rel_key in candidates:
            rel = src.relative_to(inp)
            _ui_print(f"START {rel}")
            try:
                w, h = process_one_file(
                    token,
                    src,
                    dst,
                    args.prompt,
                    args.poll_interval,
                    args.dry_run,
                    enforce_two_colors,
                )
                ok += 1
                done += 1
                mode_note = "dry-run " if args.dry_run else ""
                _ui_print(f"OK {rel} ({w}x{h}) {mode_note}-> {dst}")
                if not args.dry_run:
                    updated_cache[rel_key] = {
                        "input_sha256": _sha256_file(src),
                        "prompt_sha256": prompt_hash,
                        "enforce_two_colors": enforce_two_colors,
                    }
                    if delete_input_on_success:
                        src.unlink(missing_ok=True)
            except Exception as e:
                failed += 1
                done += 1
                _ui_print(f"FAIL {rel} | {e}", error=True)
            _ui_progress(done=done + skipped, total=total, ok=ok, failed=failed, skipped=skipped)
    else:
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futures = {}
            for src, dst, rel_key in candidates:
                rel = src.relative_to(inp)
                _ui_print(f"QUEUE {rel}")
                fut = ex.submit(
                    process_one_file,
                    token,
                    src,
                    dst,
                    args.prompt,
                    args.poll_interval,
                    args.dry_run,
                    enforce_two_colors,
                )
                futures[fut] = (src, dst, rel_key)
            for fut in as_completed(futures):
                src, dst, rel_key = futures[fut]
                rel = src.relative_to(inp)
                try:
                    w, h = fut.result()
                    ok += 1
                    done += 1
                    mode_note = "dry-run " if args.dry_run else ""
                    _ui_print(f"OK {rel} ({w}x{h}) {mode_note}-> {dst}")
                    if not args.dry_run:
                        updated_cache[rel_key] = {
                            "input_sha256": _sha256_file(src),
                            "prompt_sha256": prompt_hash,
                            "enforce_two_colors": enforce_two_colors,
                        }
                        if delete_input_on_success:
                            src.unlink(missing_ok=True)
                except Exception as e:
                    failed += 1
                    done += 1
                    _ui_print(f"FAIL {rel} | {e}", error=True)
                _ui_progress(done=done + skipped, total=total, ok=ok, failed=failed, skipped=skipped)

    if not args.no_cache and not args.dry_run:
        out_root.mkdir(parents=True, exist_ok=True)
        _save_cache(cache_path, updated_cache)

    _ui_print(f"Done. Succeeded: {ok}, failed: {failed}, skipped: {skipped}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
