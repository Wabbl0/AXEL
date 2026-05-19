#!/usr/bin/env python3
"""Write 32x32 RGBA PNG placeholders (red-on-black) for combat symbols. Stdlib only."""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

RGBA = tuple[int, int, int, int]

# Allowed palette from requested HSL:
# HSL(0,0,0), HSL(0,100,25), HSL(0,100,50), HSL(0,100,100)
BLACK: RGBA = (0, 0, 0, 255)
DARK_RED: RGBA = (128, 0, 0, 255)
RED: RGBA = (255, 0, 0, 255)
WHITE: RGBA = (255, 255, 255, 255)


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


def solid_rgba(w: int, h: int, rgba: RGBA) -> bytes:
    r, g, b, a = rgba
    return bytes([r, g, b, a]) * (w * h)


def _set_px(buf: bytearray, w: int, h: int, x: int, y: int, rgba: RGBA) -> None:
    if 0 <= x < w and 0 <= y < h:
        r, g, b, a = rgba
        i = (y * w + x) * 4
        buf[i : i + 4] = bytes([r, g, b, a])


def draw_circle(buf: bytearray, w: int, h: int, cx: float, cy: float, rad: float, rgba: RGBA) -> None:
    r, g, b, a = rgba
    for y in range(h):
        for x in range(w):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
                i = (y * w + x) * 4
                buf[i : i + 4] = bytes([r, g, b, a])


def draw_triangle(buf: bytearray, w: int, h: int, pts: list[tuple[int, int]], rgba: RGBA) -> None:
    r, g, b, a = rgba

    def point_in_tri(px: int, py: int, a, b, c) -> bool:
        ax, ay = a
        bx, by = b
        cx, cy = c

        def sign(p1x, p1y, p2x, p2y, p3x, p3y) -> float:
            return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y)

        d1 = sign(px, py, ax, ay, bx, by)
        d2 = sign(px, py, bx, by, cx, cy)
        d3 = sign(px, py, cx, cy, ax, ay)
        has_neg = d1 < 0 or d2 < 0 or d3 < 0
        has_pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (has_neg and has_pos)

    for y in range(h):
        for x in range(w):
            if point_in_tri(x, y, *pts):
                i = (y * w + x) * 4
                buf[i : i + 4] = bytes([r, g, b, a])


def _draw_line(buf: bytearray, w: int, h: int, x0: int, y0: int, x1: int, y1: int, rgba: RGBA) -> None:
    r, g, b, a = rgba
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        _set_px(buf, w, h, x, y, rgba)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy


def draw_rect(buf: bytearray, w: int, h: int, x0: int, y0: int, x1: int, y1: int, rgba: RGBA) -> None:
    r, g, b, a = rgba
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(max(0, x0), min(w, x1 + 1)):
            i = (y * w + x) * 4
            buf[i : i + 4] = bytes([r, g, b, a])


def draw_rect_outline(
    buf: bytearray, w: int, h: int, x0: int, y0: int, x1: int, y1: int, thickness: int, rgba: RGBA
) -> None:
    for t in range(thickness):
        _draw_line(buf, w, h, x0 + t, y0 + t, x1 - t, y0 + t, rgba)
        _draw_line(buf, w, h, x0 + t, y1 - t, x1 - t, y1 - t, rgba)
        _draw_line(buf, w, h, x0 + t, y0 + t, x0 + t, y1 - t, rgba)
        _draw_line(buf, w, h, x1 - t, y0 + t, x1 - t, y1 - t, rgba)


def draw_circle_outline(
    buf: bytearray, w: int, h: int, cx: float, cy: float, rad: float, thickness: float, rgba: RGBA
) -> None:
    inner_sq = (rad - thickness) * (rad - thickness)
    outer_sq = rad * rad
    for y in range(h):
        for x in range(w):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if inner_sq <= d <= outer_sq:
                _set_px(buf, w, h, x, y, rgba)


def draw_polyline(buf: bytearray, w: int, h: int, pts: list[tuple[int, int]], rgba: RGBA) -> None:
    if len(pts) < 2:
        return
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        _draw_line(buf, w, h, x0, y0, x1, y1, rgba)


def main() -> None:
    out_dir = Path(__file__).resolve().parent / "grid_symbols"
    out_dir.mkdir(parents=True, exist_ok=True)
    w = h = 32
    buf = bytearray(solid_rgba(w, h, BLACK))
    # Replaces circle visual with square outline while keeping file/resource name.
    draw_rect_outline(buf, w, h, 6, 6, 25, 25, 2, RED)
    write_png(out_dir / "green_circle.png", w, h, bytes(buf))

    buf = bytearray(solid_rgba(w, h, BLACK))
    tri_pts = [(16, 6), (6, 26), (26, 26), (16, 6)]
    draw_polyline(buf, w, h, tri_pts, RED)
    draw_polyline(buf, w, h, [(16, 7), (7, 25), (25, 25), (16, 7)], DARK_RED)
    write_png(out_dir / "yellow_triangle.png", w, h, bytes(buf))

    # Star: outline-style lines only.
    buf = bytearray(solid_rgba(w, h, BLACK))
    cx, cy = 16, 16
    r_outer = 11
    outer_pts = []
    for k in range(5):
        ang = k * 2 * math.pi / 5 - math.pi / 2
        outer_pts.append((cx + int(round(r_outer * math.cos(ang))), cy + int(round(r_outer * math.sin(ang)))))
    for k in range(5):
        x0, y0 = outer_pts[k]
        x1, y1 = outer_pts[(k + 2) % 5]
        _draw_line(buf, w, h, x0, y0, x1, y1, RED)
    write_png(out_dir / "blue_star.png", w, h, bytes(buf))

    # Heart: outline only (no fill).
    buf = bytearray(solid_rgba(w, h, BLACK))
    heart_pts = [
        (16, 27),
        (8, 19),
        (8, 12),
        (12, 8),
        (16, 10),
        (20, 8),
        (24, 12),
        (24, 19),
        (16, 27),
    ]
    draw_polyline(buf, w, h, heart_pts, RED)
    inner_heart_pts = [
        (16, 24),
        (10, 18),
        (10, 13),
        (13, 10),
        (16, 12),
        (19, 10),
        (22, 13),
        (22, 18),
        (16, 24),
    ]
    draw_polyline(buf, w, h, inner_heart_pts, DARK_RED)
    write_png(out_dir / "red_heart.png", w, h, bytes(buf))

    # Wild: white screaming skull.
    buf = bytearray(solid_rgba(w, h, BLACK))
    draw_circle(buf, w, h, 16, 13, 8, WHITE)
    draw_rect(buf, w, h, 11, 20, 21, 27, WHITE)
    # Eye sockets and nose cavity.
    draw_circle(buf, w, h, 13, 12, 2, BLACK)
    draw_circle(buf, w, h, 19, 12, 2, BLACK)
    draw_triangle(buf, w, h, [(16, 16), (14, 19), (18, 19)], BLACK)
    # Screaming mouth cavity and teeth separators.
    draw_rect(buf, w, h, 13, 22, 19, 26, BLACK)
    _draw_line(buf, w, h, 15, 22, 15, 26, DARK_RED)
    _draw_line(buf, w, h, 17, 22, 17, 26, DARK_RED)
    # Cracks to make it more skull-like and less "star-like".
    _draw_line(buf, w, h, 10, 9, 12, 7, DARK_RED)
    _draw_line(buf, w, h, 22, 9, 20, 7, DARK_RED)
    write_png(out_dir / "satanic_wild.png", w, h, bytes(buf))

    # Premium power alias: Storm (sprite id/file kept as cigarette for compatibility)
    buf = bytearray(solid_rgba(w, h, BLACK))
    draw_rect(buf, w, h, 7, 14, 22, 17, WHITE)
    draw_rect(buf, w, h, 23, 14, 26, 17, RED)
    _draw_line(buf, w, h, 6, 15, 4, 13, DARK_RED)
    _draw_line(buf, w, h, 5, 16, 3, 14, DARK_RED)
    write_png(out_dir / "cigarette.png", w, h, bytes(buf))

    # Premium power alias: Star (sprite id/file kept as booze for compatibility)
    # Distinct silhouette: outlined bottle with dark label.
    buf = bytearray(solid_rgba(w, h, BLACK))
    draw_rect_outline(buf, w, h, 13, 5, 18, 10, 1, RED)
    draw_rect_outline(buf, w, h, 10, 11, 21, 25, 2, RED)
    draw_rect(buf, w, h, 12, 16, 19, 20, DARK_RED)
    _draw_line(buf, w, h, 12, 18, 19, 18, WHITE)
    write_png(out_dir / "booze.png", w, h, bytes(buf))

    # Premium power alias: Love (sprite id/file kept as bloody_hand for compatibility)
    # Distinct silhouette: handprint with palm outline + finger drips.
    buf = bytearray(solid_rgba(w, h, BLACK))
    draw_rect_outline(buf, w, h, 10, 13, 21, 24, 2, RED)
    draw_rect(buf, w, h, 10, 25, 12, 28, RED)
    draw_rect(buf, w, h, 15, 25, 16, 29, DARK_RED)
    draw_rect(buf, w, h, 20, 25, 21, 27, RED)
    draw_rect(buf, w, h, 9, 7, 11, 13, RED)
    draw_rect(buf, w, h, 12, 5, 14, 13, RED)
    draw_rect(buf, w, h, 15, 4, 17, 13, RED)
    draw_rect(buf, w, h, 18, 6, 20, 13, RED)
    draw_rect(buf, w, h, 21, 9, 23, 14, RED)
    draw_rect(buf, w, h, 13, 16, 18, 20, DARK_RED)
    write_png(out_dir / "bloody_hand.png", w, h, bytes(buf))
    print("Wrote:", out_dir)


if __name__ == "__main__":
    main()
