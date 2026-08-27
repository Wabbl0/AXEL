#!/usr/bin/env python3
"""One-shot: cut kävely plates into a 12-cell Mike walk strip.

Reads ASCII copies (or Finnish names) under exports/Drawings/, writes
assets/sprites/mike_walking-Sheet.png after backing up the live 13-frame sheet.

Run from repo root:
  python AXEL/axel_project/tools/pack_mike_walk_sheet.py
"""

from __future__ import annotations

import os
import shutil
from collections import deque
from typing import List, Tuple

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DRAWINGS = os.path.join(ROOT, "exports", "Drawings")
SPRITES = os.path.join(ROOT, "assets", "sprites")
OUT_SHEET = os.path.join(SPRITES, "mike_walking-Sheet.png")
LEGACY_SHEET = os.path.join(SPRITES, "mike_walking-Sheet_legacy13.png")

INK_THRESH = 8
MIN_COL_INK = 6
MIN_GAP = 10
SPECK_MAX_PIXELS = 12
# Isolated blobs this far from the main pose (pixels) are leftover brush, not body.
FAR_BLOB_DIST = 40
# After pack, drop extra islands smaller than this (stray strokes near head/feet).
ISLAND_MAX_PIXELS = 120
CELL_PAD = 20
BODY_INK_RGBA = (255, 255, 255, 255)
NECK_WIDTH_RATIO = 0.28
CHIN_PAD_PX = 6
FACE_BELOW_PEAK = 0.62
NECK_THIN_ROWS = 6
# Soft painted-white overflow inverts to a dark halo; drop those faint pixels.
FACE_FRINGE_LUMA = 90
FACE_FRINGE_ALPHA = 80


def _find_source(preferred: str, *needles: str) -> str:
	path = os.path.join(DRAWINGS, preferred)
	if os.path.isfile(path):
		return path
	for name in os.listdir(DRAWINGS):
		if not name.lower().endswith(".png"):
			continue
		if name.endswith(".import"):
			continue
		lower = name.lower()
		if all(n in lower for n in needles):
			return os.path.join(DRAWINGS, name)
	raise FileNotFoundError(f"Missing drawing for {preferred} / {needles}")


def _alpha(im: Image.Image) -> Image.Image:
	if im.mode != "RGBA":
		im = im.convert("RGBA")
	return im.split()[-1]


def _column_ink(a: Image.Image, thresh: int = INK_THRESH) -> List[int]:
	w, h = a.size
	cols = [0] * w
	pix = a.load()
	for x in range(w):
		c = 0
		for y in range(h):
			if pix[x, y] > thresh:
				c += 1
		cols[x] = c
	return cols


def _pose_x_spans(cols: List[int], min_col: int = MIN_COL_INK, min_gap: int = MIN_GAP) -> List[Tuple[int, int]]:
	runs: List[Tuple[int, int]] = []
	start = None
	for i, v in enumerate(cols):
		if v >= min_col and start is None:
			start = i
		elif v < min_col and start is not None:
			runs.append((start, i - 1))
			start = None
	if start is not None:
		runs.append((start, len(cols) - 1))
	merged: List[Tuple[int, int]] = []
	for s, e in runs:
		if merged and s - merged[-1][1] < min_gap:
			merged[-1] = (merged[-1][0], e)
		else:
			merged.append((s, e))
	return merged


def _bbox_for_span(a: Image.Image, x0: int, x1: int, thresh: int = INK_THRESH) -> Tuple[int, int, int, int]:
	pix = a.load()
	_w, h = a.size
	ymin, ymax = h, -1
	xmin, xmax = x1, x0
	for x in range(x0, x1 + 1):
		for y in range(h):
			if pix[x, y] > thresh:
				if y < ymin:
					ymin = y
				if y > ymax:
					ymax = y
				if x < xmin:
					xmin = x
				if x > xmax:
					xmax = x
	if ymax < 0:
		raise RuntimeError(f"empty span {x0}-{x1}")
	return xmin, ymin, xmax, ymax


def _drop_specks(mask: Image.Image, max_pixels: int = SPECK_MAX_PIXELS) -> Image.Image:
	"""Keep only connected components larger than max_pixels (4-connected)."""
	w, h = mask.size
	pix = mask.load()
	visited = [[False] * w for _ in range(h)]
	out = Image.new("L", (w, h), 0)
	out_pix = out.load()
	dirs = ((1, 0), (-1, 0), (0, 1), (0, -1))
	for y in range(h):
		for x in range(w):
			if pix[x, y] == 0 or visited[y][x]:
				continue
			q = deque([(x, y)])
			visited[y][x] = True
			comp = [(x, y)]
			while q:
				cx, cy = q.popleft()
				for dx, dy in dirs:
					nx, ny = cx + dx, cy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					if visited[ny][nx] or pix[nx, ny] == 0:
						continue
					visited[ny][nx] = True
					q.append((nx, ny))
					comp.append((nx, ny))
			if len(comp) > max_pixels:
				for px, py in comp:
					out_pix[px, py] = 255
	return out


def _drop_far_blobs(pose: Image.Image, min_dist: int = FAR_BLOB_DIST) -> Image.Image:
	"""Erase disconnected specks sitting well off the main silhouette."""
	w, h = pose.size
	pix = pose.load()
	alpha = [[pix[x, y][3] > INK_THRESH for x in range(w)] for y in range(h)]
	visited = [[False] * w for _ in range(h)]
	dirs = ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1))
	comps: List[List[Tuple[int, int]]] = []
	for y in range(h):
		for x in range(w):
			if visited[y][x] or not alpha[y][x]:
				continue
			q = deque([(x, y)])
			visited[y][x] = True
			comp = [(x, y)]
			while q:
				cx, cy = q.popleft()
				for dx, dy in dirs:
					nx, ny = cx + dx, cy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					if visited[ny][nx] or not alpha[ny][nx]:
						continue
					visited[ny][nx] = True
					q.append((nx, ny))
					comp.append((nx, ny))
			comps.append(comp)
	if len(comps) <= 1:
		return pose
	comps.sort(key=len, reverse=True)
	main = set(comps[0])
	reach = min_dist * min_dist
	out = pose.copy()
	op = out.load()
	for comp in comps[1:]:
		near = False
		for x, y in comp:
			for dx in range(-min_dist + 1, min_dist):
				for dy in range(-min_dist + 1, min_dist):
					if dx * dx + dy * dy >= reach:
						continue
					if (x + dx, y + dy) in main:
						near = True
						break
				if near:
					break
			if near:
				break
		if not near:
			for x, y in comp:
				op[x, y] = (0, 0, 0, 0)
	return out


def _keep_main_island(pose: Image.Image, max_extra: int = ISLAND_MAX_PIXELS) -> Image.Image:
	"""Erase leftover brush islands that sit near Mike but are not the body."""
	w, h = pose.size
	pix = pose.load()
	visited = [[False] * w for _ in range(h)]
	dirs = ((1, 0), (-1, 0), (0, 1), (0, -1))
	comps: List[List[Tuple[int, int]]] = []
	for y in range(h):
		for x in range(w):
			if visited[y][x] or pix[x, y][3] <= INK_THRESH:
				continue
			q = deque([(x, y)])
			visited[y][x] = True
			comp = [(x, y)]
			while q:
				cx, cy = q.popleft()
				for dx, dy in dirs:
					nx, ny = cx + dx, cy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					if visited[ny][nx] or pix[nx, ny][3] <= INK_THRESH:
						continue
					visited[ny][nx] = True
					q.append((nx, ny))
					comp.append((nx, ny))
			comps.append(comp)
	if len(comps) <= 1:
		return pose
	comps.sort(key=len, reverse=True)
	out = pose.copy()
	op = out.load()
	for comp in comps[1:]:
		if len(comp) > max_extra:
			continue
		for x, y in comp:
			op[x, y] = (0, 0, 0, 0)
	return out


def _extract_poses(path: str, expect: int) -> List[Image.Image]:
	src = Image.open(path).convert("RGBA")
	a = _alpha(src)
	# Build binary mask and drop dust
	mask = Image.new("L", a.size, 0)
	ap = a.load()
	mp = mask.load()
	for y in range(a.size[1]):
		for x in range(a.size[0]):
			if ap[x, y] > INK_THRESH:
				mp[x, y] = 255
	mask = _drop_specks(mask)
	cols = _column_ink(mask, thresh=1)
	spans = _pose_x_spans(cols)
	if len(spans) != expect:
		raise RuntimeError(f"{os.path.basename(path)}: expected {expect} poses, got {len(spans)}: {spans}")
	poses: List[Image.Image] = []
	for x0, x1 in spans:
		xmin, ymin, xmax, ymax = _bbox_for_span(mask, x0, x1, thresh=1)
		# Crop from source; keep original alpha so brush edges stay (mask only drops dust)
		crop = src.crop((xmin, ymin, xmax + 1, ymax + 1)).copy()
		m_crop = mask.crop((xmin, ymin, xmax + 1, ymax + 1))
		r, g, b, oa = crop.split()
		rp, gp, bp, oap = r.load(), g.load(), b.load(), oa.load()
		mpx = m_crop.load()
		kept = Image.new("RGBA", crop.size, (0, 0, 0, 0))
		kp = kept.load()
		for y in range(crop.size[1]):
			for x in range(crop.size[0]):
				if mpx[x, y]:
					kp[x, y] = (rp[x, y], gp[x, y], bp[x, y], oap[x, y])
		kept = _drop_far_blobs(kept)
		poses.append(kept)
		print(f"  pose {len(poses)}: {kept.size[0]}x{kept.size[1]} from x {xmin}-{xmax} y {ymin}-{ymax}")
	return poses


def _chin_y(pose: Image.Image) -> int:
	"""Bottom of the head: finish the circle below the widest row, then the neck."""
	w, h = pose.size
	pix = pose.load()
	widths = [0] * h
	for y in range(h):
		xmin, xmax = w, -1
		for x in range(w):
			if pix[x, y][3] > INK_THRESH:
				if x < xmin:
					xmin = x
				if x > xmax:
					xmax = x
		if xmax >= 0:
			widths[y] = xmax - xmin + 1
	search_h = max(20, int(h * 0.40))
	peak_y = max(range(search_h), key=lambda y: widths[y])
	peak_w = widths[peak_y]
	if peak_w < 8:
		return min(int(h * 0.28), h)
	# Eyes sit near the widest row; never cut the plate above the lower face.
	circle_bottom = min(h, peak_y + int(peak_w * FACE_BELOW_PEAK) + CHIN_PAD_PX)
	neck_cut = max(8, int(peak_w * NECK_WIDTH_RATIO))
	limit = min(h, circle_bottom + peak_w)
	thin_run = 0
	for y in range(circle_bottom, limit):
		if 0 < widths[y] <= neck_cut:
			thin_run += 1
			if thin_run >= NECK_THIN_ROWS:
				return min(h, y - thin_run + 1 + CHIN_PAD_PX)
		else:
			thin_run = 0
	return circle_bottom


def _finish_pose(pose: Image.Image) -> Image.Image:
	"""Invert charcoal on the whole figure (painted white becomes black holes). No solid-white body flatten. No extra head plate."""
	w, h = pose.size
	pix = pose.load()
	ink = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	ip = ink.load()
	for y in range(h):
		for x in range(w):
			r, g, b, a = pix[x, y]
			if a <= INK_THRESH:
				continue
			inv = 255 - (int(r) + int(g) + int(b)) // 3
			if inv < FACE_FRINGE_LUMA and a < FACE_FRINGE_ALPHA:
				continue
			ip[x, y] = (inv, inv, inv, a)
	return ink


def _pack(poses: List[Image.Image]) -> Tuple[Image.Image, int, int]:
	max_w = max(p.size[0] for p in poses)
	max_h = max(p.size[1] for p in poses)
	# Shared head-top: all poses already cropped to their own top ink; pad keeps head near cell top
	cell_w = max_w + CELL_PAD * 2
	cell_h = max_h + CELL_PAD * 2
	n = len(poses)
	sheet = Image.new("RGBA", (cell_w * n, cell_h), (0, 0, 0, 0))
	for i, pose in enumerate(poses):
		# Head-top align: paste at CELL_PAD from top; center horizontally
		ox = i * cell_w + (cell_w - pose.size[0]) // 2
		oy = CELL_PAD
		sheet.paste(pose, (ox, oy))
	return sheet, cell_w, cell_h


def main() -> None:
	etu_path = _find_source("kavely_etu.png", "etu")
	sivu_path = _find_source("kavely_sivu.png", "sivu")
	# Prefer ASCII copies if present
	ascii_etu = os.path.join(DRAWINGS, "kavely_etu.png")
	ascii_sivu = os.path.join(DRAWINGS, "kavely_sivu.png")
	if os.path.isfile(ascii_etu):
		etu_path = ascii_etu
	if os.path.isfile(ascii_sivu):
		sivu_path = ascii_sivu

	print("Extracting etu (7)…")
	etu = _extract_poses(etu_path, 7)
	print("Extracting sivu (5)…")
	sivu = _extract_poses(sivu_path, 5)

	all_poses = etu + sivu  # 0-3 front, 4-6 back, 7-11 side
	assert len(all_poses) == 12

	print("Invert whole figure (no head plate, no solid-white body)…")
	processed = [_keep_main_island(_finish_pose(p)) for p in all_poses]

	sheet, cell_w, cell_h = _pack(processed)
	print(f"Sheet {sheet.size[0]}x{sheet.size[1]} cell {cell_w}x{cell_h}")

	os.makedirs(SPRITES, exist_ok=True)
	if os.path.isfile(OUT_SHEET) and not os.path.isfile(LEGACY_SHEET):
		shutil.copy2(OUT_SHEET, LEGACY_SHEET)
		print(f"Backed up legacy -> {LEGACY_SHEET}")
	elif os.path.isfile(OUT_SHEET) and os.path.isfile(LEGACY_SHEET):
		# Keep first legacy backup; still overwrite live sheet
		print(f"Legacy backup already exists: {LEGACY_SHEET}")

	sheet.save(OUT_SHEET, "PNG")
	print(f"Wrote {OUT_SHEET}")
	# Machine-readable for scale math
	meta = os.path.join(SPRITES, "mike_walking-Sheet_meta.txt")
	with open(meta, "w", encoding="utf-8") as f:
		f.write(f"cell_w={cell_w}\ncell_h={cell_h}\nframes=12\n")
	print(f"Wrote {meta}")


if __name__ == "__main__":
	main()
