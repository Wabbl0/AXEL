#!/usr/bin/env python3
"""Write 32x32 RGBA PNG placeholders (red-on-black) for combat symbols. Stdlib only."""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


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


def solid_rgba(w: int, h: int, rgba: tuple[int, int, int, int]) -> bytes:
    r, g, b, a = rgba
    return bytes([r, g, b, a]) * (w * h)


def draw_circle(buf: bytearray, w: int, h: int, cx: float, cy: float, rad: float, rgba: tuple[int, int, int, int]) -> None:
    r, g, b, a = rgba
    for y in range(h):
        for x in range(w):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
                i = (y * w + x) * 4
                buf[i : i + 4] = bytes([r, g, b, a])


def draw_triangle(buf: bytearray, w: int, h: int, pts: list[tuple[int, int]], rgba: tuple[int, int, int, int]) -> None:
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


def _draw_line(buf: bytearray, w: int, h: int, x0: int, y0: int, x1: int, y1: int, rgba: tuple[int, int, int, int]) -> None:
    r, g, b, a = rgba
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 4
            buf[i : i + 4] = bytes([r, g, b, a])
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy


def main() -> None:
    out_dir = Path(__file__).resolve().parent / "placeholders"
    out_dir.mkdir(parents=True, exist_ok=True)
    w = h = 32
    black = (0, 0, 0, 255)

    buf = bytearray(solid_rgba(w, h, black))
    draw_circle(buf, w, h, 16, 16, 10, (0, 255, 0, 255))
    write_png(out_dir / "green_circle.png", w, h, bytes(buf))

    buf = bytearray(solid_rgba(w, h, black))
    draw_triangle(buf, w, h, [(16, 6), (6, 26), (26, 26)], (255, 255, 0, 255))
    write_png(out_dir / "yellow_triangle.png", w, h, bytes(buf))

    buf = bytearray(solid_rgba(w, h, black))
    col = (0, 120, 255, 255)
    for y in range(h):
        for x in range(w):
            cx, cy = 16, 16
            if abs(x - cx) <= 1 or abs(y - cy) <= 1 or abs(x - y) <= 1 or abs(x + y - 32) <= 1:
                if 6 <= x <= 26 and 6 <= y <= 26:
                    i = (y * w + x) * 4
                    buf[i : i + 4] = bytes(col)
    write_png(out_dir / "blue_star.png", w, h, bytes(buf))

    buf = bytearray(solid_rgba(w, h, black))
    draw_circle(buf, w, h, 12, 12, 6, (255, 0, 0, 255))
    draw_circle(buf, w, h, 20, 12, 6, (255, 0, 0, 255))
    draw_triangle(buf, w, h, [(16, 28), (8, 14), (24, 14)], (255, 0, 0, 255))
    write_png(out_dir / "red_heart.png", w, h, bytes(buf))

    buf = bytearray(solid_rgba(w, h, black))
    cx, cy = 16, 16
    r_outer = 11
    pts = []
    for k in range(5):
        ang = k * 2 * math.pi / 5 - math.pi / 2
        pts.append((cx + int(round(r_outer * math.cos(ang))), cy + int(round(r_outer * math.sin(ang)))))
    for k in range(5):
        x0, y0 = pts[k]
        x1, y1 = pts[(k + 1) % 5]
        _draw_line(buf, w, h, x0, y0, x1, y1, (255, 0, 0, 255))
    write_png(out_dir / "satanic_wild.png", w, h, bytes(buf))
    print("Wrote:", out_dir)


if __name__ == "__main__":
    main()
