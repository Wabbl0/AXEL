#!/usr/bin/env python3
"""One-shot A/B/C Mike look previews. Does not overwrite the live walk sheet."""

from __future__ import annotations

import importlib.util
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.abspath(os.path.dirname(__file__))
PACK_PATH = os.path.abspath(os.path.join(HERE, "..", "..", "pack_mike_walk_sheet.py"))
OUT_DIR = HERE

HOLE_KEEP = 52
C_LIFT = 0.58


def _load_pack():
	spec = importlib.util.spec_from_file_location("pack_mike_walk_sheet", PACK_PATH)
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return mod


def _invert_pixel(r: int, g: int, b: int, a: int, pack) -> tuple[int, int, int, int] | None:
	if a <= pack.INK_THRESH:
		return None
	inv = 255 - (int(r) + int(g) + int(b)) // 3
	if inv < pack.FACE_FRINGE_LUMA and a < pack.FACE_FRINGE_ALPHA:
		return None
	return (inv, inv, inv, a)


def finish_current(pose: Image.Image, pack) -> Image.Image:
	return pack._finish_pose(pose)


def finish_a(pose: Image.Image, pack) -> Image.Image:
	"""Invert the whole figure. Head and body share charcoal texture."""
	w, h = pose.size
	pix = pose.load()
	ink = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	ip = ink.load()
	for y in range(h):
		for x in range(w):
			r, g, b, a = pix[x, y]
			out = _invert_pixel(r, g, b, a, pack)
			if out is not None:
				ip[x, y] = out
	return ink


def finish_b(pose: Image.Image, pack) -> Image.Image:
	"""Solid white ink everywhere; keep only dark holes (eyes)."""
	w, h = pose.size
	pix = pose.load()
	ink = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	ip = ink.load()
	for y in range(h):
		for x in range(w):
			r, g, b, a = pix[x, y]
			out = _invert_pixel(r, g, b, a, pack)
			if out is None:
				continue
			inv = out[0]
			if inv < HOLE_KEEP:
				ip[x, y] = out
			else:
				ip[x, y] = pack.BODY_INK_RGBA
	return ink


def finish_c(pose: Image.Image, pack) -> Image.Image:
	"""Invert everything, then lift mid-grays toward white."""
	w, h = pose.size
	pix = pose.load()
	ink = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	ip = ink.load()
	for y in range(h):
		for x in range(w):
			r, g, b, a = pix[x, y]
			out = _invert_pixel(r, g, b, a, pack)
			if out is None:
				continue
			inv = out[0]
			if inv >= HOLE_KEEP:
				inv = int(inv + (255 - inv) * C_LIFT)
			ip[x, y] = (inv, inv, inv, a)
	return ink


def _dark_bg(size: tuple[int, int]) -> Image.Image:
	w, h = size
	bg = Image.new("RGB", (w, h), (8, 8, 10))
	px = bg.load()
	# Light grain so it reads like the overworld CRT shot.
	seed = 17
	for y in range(h):
		for x in range(w):
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
			n = (seed >> 16) % 18
			v = 8 + n
			if y % 3 == 0:
				v = max(0, v - 6)
			px[x, y] = (v, v, v + 2)
	return bg


def _paste_center(bg: Image.Image, sprite: Image.Image, box: tuple[int, int, int, int], scale: float) -> None:
	x0, y0, x1, y1 = box
	bw, bh = x1 - x0, y1 - y0
	sw = max(1, int(sprite.size[0] * scale))
	sh = max(1, int(sprite.size[1] * scale))
	resized = sprite.resize((sw, sh), Image.Resampling.NEAREST)
	px = x0 + (bw - sw) // 2
	py = y0 + (bh - sh) // 2
	bg.paste(resized, (px, py), resized)


def _font(size: int):
	for name in ("arial.ttf", "segoeui.ttf", "C:\\Windows\\Fonts\\arial.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			continue
	return ImageFont.load_default()


def _card(title: str, subtitle: str, front: Image.Image, side: Image.Image, path: str) -> None:
	w, h = 1100, 780
	img = _dark_bg((w, h))
	draw = ImageDraw.Draw(img)
	title_font = _font(36)
	sub_font = _font(20)
	draw.text((36, 22), title, fill=(230, 230, 230), font=title_font)
	draw.text((36, 68), subtitle, fill=(170, 170, 176), font=sub_font)
	# Front | side
	_paste_center(img, front, (20, 110, 540, 760), 0.62)
	_paste_center(img, side, (560, 110, 1080, 760), 0.62)
	img.save(path, "PNG")
	print(f"wrote {path}")


def _compare(cards: list[tuple[str, Image.Image]], path: str) -> None:
	# Four close-up heads in a row.
	cell_w, cell_h = 280, 420
	pad = 24
	w = pad + len(cards) * (cell_w + pad)
	h = cell_h + 90
	img = _dark_bg((w, h))
	draw = ImageDraw.Draw(img)
	font = _font(22)
	for i, (label, sprite) in enumerate(cards):
		x0 = pad + i * (cell_w + pad)
		# Crop top 42% (head + upper torso).
		cw, ch = sprite.size
		crop = sprite.crop((0, 0, cw, int(ch * 0.42)))
		scale = min((cell_w - 8) / crop.size[0], (cell_h - 8) / crop.size[1])
		box = (x0, 50, x0 + cell_w, 50 + cell_h)
		_paste_center(img, crop, box, scale)
		draw.text((x0 + 8, 14), label, fill=(230, 230, 230), font=font)
	img.save(path, "PNG")
	print(f"wrote {path}")


def main() -> None:
	pack = _load_pack()
	etu_path = pack._find_source("kavely_etu.png", "etu")
	sivu_path = pack._find_source("kavely_sivu.png", "sivu")
	print(f"etu: {etu_path}")
	print(f"sivu: {sivu_path}")
	etu = pack._extract_poses(etu_path, 7)
	sivu = pack._extract_poses(sivu_path, 5)
	front_src = etu[0]
	side_src = sivu[0]

	variants = {
		"current": (finish_current, "Current (now)", "Head inverted, body flattened to solid white."),
		"A": (finish_a, "A — body matches head", "Invert the whole figure. Pencil texture all over."),
		"B": (finish_b, "B — head matches body", "Solid white ink, black eye holes only."),
		"C": (finish_c, "C — middle", "Invert everything, then lift grays toward white."),
	}

	closeups = []
	for key, (fn, title, sub) in variants.items():
		front = pack._keep_main_island(fn(front_src, pack))
		side = pack._keep_main_island(fn(side_src, pack))
		out = os.path.join(OUT_DIR, f"mike_look_{key}.png")
		_card(title, sub, front, side, out)
		closeups.append((key.upper() if key != "current" else "NOW", front))

	_compare(closeups, os.path.join(OUT_DIR, "mike_look_compare.png"))


if __name__ == "__main__":
	main()
