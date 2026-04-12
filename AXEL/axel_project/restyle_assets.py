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
import io
import json
import os
import sys
import time
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
                return base64.standard_b64decode(s)
            except Exception:
                return None
        if isinstance(obj, dict):
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
    session: requests.Session,
    token: str,
    src: Path,
    dst: Path,
    description: str,
    poll_seconds: float,
    dry_run: bool,
) -> None:
    img = Image.open(src)
    img.load()
    prepared, w, h = _prepare_image_for_api(img)
    png_b64 = _pil_to_png_base64(prepared)

    if dry_run:
        print(f"[dry-run] Would process {src} -> {dst} ({w}x{h})")
        return

    dst.parent.mkdir(parents=True, exist_ok=True)
    job_id = submit_edit(session, token, png_b64, w, h, description)
    print(f"  job {job_id} … polling")
    job = poll_job(session, token, job_id, poll_seconds)
    last = job.get("last_response")
    if isinstance(last, str):
        try:
            last = json.loads(last)
        except json.JSONDecodeError:
            pass
    if not isinstance(last, dict):
        raise RuntimeError(f"Unexpected last_response type: {type(last)!r}")
    png_bytes = _extract_first_png_bytes(last)
    dst.write_bytes(png_bytes)
    print(f"  saved {dst}")


def collect_pngs(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(root.rglob("*.png")):
        if p.name == ".gitkeep":
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
    p.add_argument("--poll-interval", type=float, default=5.0, help="Seconds between job status polls")
    p.add_argument("--dry-run", action="store_true", help="Only validate images, do not call API")
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
        print(f"No PNG files found under {inp}")
        return 0

    session = requests.Session()
    ok = 0
    failed = 0
    for src in files:
        rel = src.relative_to(inp)
        dst = out_root / rel
        print(f"Processing {rel} …")
        try:
            process_one_file(
                session,
                token,
                src,
                dst,
                args.prompt,
                args.poll_interval,
                args.dry_run,
            )
            ok += 1
        except Exception as e:
            print(f"  ERROR: {e}", file=sys.stderr)
            failed += 1

    print(f"Done. Succeeded: {ok}, failed: {failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
