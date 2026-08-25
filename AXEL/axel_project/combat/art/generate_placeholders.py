#!/usr/bin/env python3
"""Write 128x128 RGBA PNG suit symbols from Unicode silhouettes.

Suit symbols: hollow red outlines with identical stroke width.
Uses filled Unicode forms (■ ▲ ★ ♥) as silhouettes, then keeps only pixels
within a fixed distance of the edge so every symbol shares the same line
weight and has no fill.

Also adds a 1px faint white halo around the hand-authored premium/wild icons
(cigarette, booze, bloody_hand, satanic_wild) without redrawing their art.
"""
from __future__ import annotations

import struct
import zlib
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

RGBA = tuple[int, int, int, int]

BLACK: RGBA = (0, 0, 0, 255)
RED: RGBA = (255, 0, 0, 255)
# Dim grey so a 1px halo reads as a faint white edge on black.
FAINT_WHITE: RGBA = (96, 96, 96, 255)

CANVAS = 128
# ~24px margin; all four share the same content box.
CONTENT_MAX = 80
# Uniform outline thickness (pixels) after fit-to-canvas.
STROKE = 7
THRESHOLD = 128

PREMIUM_FILES = (
    "cigarette.png",
    "booze.png",
    "bloody_hand.png",
    "satanic_wild.png",
)

# Filled Unicode silhouettes — outline is carved afterward (no fill in output).
SUITS: list[tuple[str, str]] = [
    ("green_circle.png", "\u25A0"),  # ■ BLACK SQUARE
    ("yellow_triangle.png", "\u25B2"),  # ▲ BLACK UP-POINTING TRIANGLE
    ("blue_star.png", "\u2605"),  # ★ BLACK STAR
    ("red_heart.png", "\u2665"),  # ♥ BLACK HEART SUIT
]

_FONT_CANDIDATES = [
    Path(r"C:\Windows\Fonts\seguisym.ttf"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/System/Library/Fonts/Supplemental/Segoe UI Symbol.ttf"),
]


def _png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def write_png(path: Path, width: int, height: int, rgba: bytes) -> None:
    if len(rgba) != width * height * 4:
        raise ValueError("rgba length mismatch")
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        row_start = y * width * 4
        raw.extend(rgba[row_start : row_start + width * 4])
    compressed = zlib.compress(bytes(raw), level=9)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += _png_chunk(b"IHDR", ihdr)
    png += _png_chunk(b"IDAT", compressed)
    png += _png_chunk(b"IEND", b"")
    path.write_bytes(png)


def _load_symbol_font(size: int) -> ImageFont.FreeTypeFont:
    for candidate in _FONT_CANDIDATES:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size=size)
    raise FileNotFoundError(
        "No symbol font found. Install Segoe UI Symbol or DejaVu Sans."
    )


def _glyph_mask(char: str, font_size: int = 220) -> Image.Image:
    """Render one filled glyph large on black; return binary L-mode tight crop."""
    font = _load_symbol_font(font_size)
    big = 512
    img = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (big - tw) // 2 - bbox[0]
    y = (big - th) // 2 - bbox[1]
    draw.text((x, y), char, font=font, fill=255)

    ink = img.point(lambda v: 255 if v > THRESHOLD else 0)
    tight = ink.getbbox()
    if tight is None:
        raise RuntimeError(f"Glyph produced no pixels for U+{ord(char):04X}")
    return ink.crop(tight)


def _fit_mask(glyph: Image.Image, canvas: int = CANVAS, content_max: int = CONTENT_MAX) -> Image.Image:
    """Scale glyph into shared content box and center on a canvas-sized binary mask."""
    gw, gh = glyph.size
    scale = min(content_max / max(gw, 1), content_max / max(gh, 1))
    nw = max(1, int(round(gw * scale)))
    nh = max(1, int(round(gh * scale)))
    # Smooth scale then re-threshold — keeps heart curves clean.
    scaled = glyph.resize((nw, nh), Image.Resampling.LANCZOS)
    scaled = scaled.point(lambda v: 255 if v > THRESHOLD else 0)

    out = Image.new("L", (canvas, canvas), 0)
    ox = (canvas - nw) // 2
    oy = (canvas - nh) // 2
    out.paste(scaled, (ox, oy))
    return out


def _distance_to_outside(inside: np.ndarray) -> np.ndarray:
    """Approx Euclidean distance from each pixel to the nearest outside pixel."""
    h, w = inside.shape
    dist = np.full((h, w), np.inf, dtype=np.float64)
    q: deque[tuple[int, int]] = deque()
    for y in range(h):
        for x in range(w):
            if not inside[y, x]:
                dist[y, x] = 0.0
                q.append((y, x))
    # 8-connected chamfer (ortho=1, diag≈√2) — uniform stroke on curves and points.
    neighbors = (
        (-1, 0, 1.0),
        (1, 0, 1.0),
        (0, -1, 1.0),
        (0, 1, 1.0),
        (-1, -1, 1.41421356237),
        (-1, 1, 1.41421356237),
        (1, -1, 1.41421356237),
        (1, 1, 1.41421356237),
    )
    while q:
        y, x = q.popleft()
        base = dist[y, x]
        for dy, dx, step in neighbors:
            ny, nx = y + dy, x + dx
            if ny < 0 or ny >= h or nx < 0 or nx >= w:
                continue
            nd = base + step
            if nd < dist[ny, nx]:
                dist[ny, nx] = nd
                q.append((ny, nx))
    return dist


def _hollow_outline(mask: Image.Image, stroke: int = STROKE) -> bytes:
    """Carve a fixed-width red ring using distance-to-edge (same weight on all shapes)."""
    inside = np.array(mask, dtype=np.uint8) > THRESHOLD
    dist = _distance_to_outside(inside)
    ring = inside & (dist > 0.0) & (dist <= float(stroke))

    rgba = bytearray()
    flat = ring.reshape(-1)
    for on in flat:
        rgba.extend(RED if on else BLACK)
    return bytes(rgba)


def _apply_faint_white_outline(path: Path) -> None:
    """Paint a 1px faint halo on black pixels that touch real art. Idempotent."""
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[0], arr.shape[1]
    r = arr[:, :, 0]
    g = arr[:, :, 1]
    b = arr[:, :, 2]
    black = (r == 0) & (g == 0) & (b == 0)
    faint = (r == FAINT_WHITE[0]) & (g == FAINT_WHITE[1]) & (b == FAINT_WHITE[2])
    art = ~black & ~faint
    halo = np.zeros((h, w), dtype=bool)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            shifted = np.zeros_like(art)
            y0, y1 = max(0, dy), h + min(0, dy)
            x0, x1 = max(0, dx), w + min(0, dx)
            shifted[y0:y1, x0:x1] = art[y0 - dy : y1 - dy, x0 - dx : x1 - dx]
            halo |= shifted
    paint = halo & black
    arr[paint] = FAINT_WHITE
    img = Image.fromarray(arr, mode="RGBA")
    write_png(path, w, h, img.tobytes())


def main() -> None:
    out_dir = Path(__file__).resolve().parent / "grid_symbols"
    out_dir.mkdir(parents=True, exist_ok=True)

    for filename, char in SUITS:
        glyph = _glyph_mask(char)
        mask = _fit_mask(glyph)
        rgba = _hollow_outline(mask, STROKE)
        write_png(out_dir / filename, CANVAS, CANVAS, rgba)
        print(f"Wrote {filename} from U+{ord(char):04X} (stroke={STROKE}, red)")

    for filename in PREMIUM_FILES:
        path = out_dir / filename
        if not path.is_file():
            print(f"Skip missing {filename}")
            continue
        _apply_faint_white_outline(path)
        print(f"Haloed {filename}")

    print("Wrote suit symbols + faint premium outlines:", out_dir)


if __name__ == "__main__":
    main()
