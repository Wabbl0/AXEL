extends SceneTree
## One-shot bake for Mike's 12-frame walk strip (prefer the Python twin if available).
## Run: tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://tools/pack_mike_walk_sheet.gd
## Sources: exports/Drawings/kavely_etu.png + kavely_sivu.png (ASCII copies of kävely_*).

const _ETU := "res://exports/Drawings/kavely_etu.png"
const _SIVU := "res://exports/Drawings/kavely_sivu.png"
const _OUT := "res://assets/sprites/mike_walking-Sheet.png"
const _LEGACY := "res://assets/sprites/mike_walking-Sheet_legacy13.png"
const _META := "res://assets/sprites/mike_walking-Sheet_meta.txt"

const INK_THRESH := 8
const MIN_COL_INK := 6
const MIN_GAP := 10
const SPECK_MAX := 12
const CELL_PAD := 20
const HEAD_FILL := Color(0, 0, 0, 1)
const BODY_INK := Color(1, 1, 1, 1)
const NECK_WIDTH_RATIO := 0.28
const CHIN_PAD_PX := 6
const FACE_BELOW_PEAK := 0.62
const NECK_THIN_ROWS := 6


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var etu_img := _load_image(_ETU)
	var sivu_img := _load_image(_SIVU)
	if etu_img == null or sivu_img == null:
		push_error("pack_mike_walk_sheet: missing kavely_etu.png / kavely_sivu.png under exports/Drawings/")
		quit(1)
		return

	var etu_poses := _extract_poses(etu_img, 7)
	var sivu_poses := _extract_poses(sivu_img, 5)
	if etu_poses.size() != 7 or sivu_poses.size() != 5:
		push_error("pack_mike_walk_sheet: pose count mismatch")
		quit(1)
		return

	var all_poses: Array[Image] = []
	all_poses.append_array(etu_poses)
	all_poses.append_array(sivu_poses)

	var processed: Array[Image] = []
	for pose in all_poses:
		processed.append(_finish_pose(pose))

	var max_w := 0
	var max_h := 0
	for pose in processed:
		max_w = maxi(max_w, pose.get_width())
		max_h = maxi(max_h, pose.get_height())
	var cell_w := max_w + CELL_PAD * 2
	var cell_h := max_h + CELL_PAD * 2
	var sheet := Image.create(cell_w * 12, cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in processed.size():
		var pose: Image = processed[i]
		var ox := i * cell_w + int((cell_w - pose.get_width()) / 2.0)
		var oy := CELL_PAD
		sheet.blit_rect(pose, Rect2i(0, 0, pose.get_width(), pose.get_height()), Vector2i(ox, oy))

	_backup_legacy_if_needed()
	var err := sheet.save_png(ProjectSettings.globalize_path(_OUT))
	if err != OK:
		push_error("pack_mike_walk_sheet: save failed %s" % err)
		quit(1)
		return
	var meta := FileAccess.open(ProjectSettings.globalize_path(_META), FileAccess.WRITE)
	if meta:
		meta.store_string("cell_w=%d\ncell_h=%d\nframes=12\n" % [cell_w, cell_h])
		meta.close()
	print("pack_mike_walk_sheet OK: %dx%d cell %dx%d" % [sheet.get_width(), sheet.get_height(), cell_w, cell_h])
	quit(0)


func _load_image(res_path: String) -> Image:
	if not ResourceLoader.exists(res_path) and not FileAccess.file_exists(ProjectSettings.globalize_path(res_path)):
		return null
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) != OK:
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _backup_legacy_if_needed() -> void:
	var out_abs := ProjectSettings.globalize_path(_OUT)
	var legacy_abs := ProjectSettings.globalize_path(_LEGACY)
	if FileAccess.file_exists(out_abs) and not FileAccess.file_exists(legacy_abs):
		DirAccess.copy_absolute(out_abs, legacy_abs)


func _extract_poses(src: Image, expect: int) -> Array[Image]:
	var w := src.get_width()
	var h := src.get_height()
	var mask := Image.create(w, h, false, Image.FORMAT_L8)
	mask.fill(Color(0, 0, 0, 1))
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a * 255.0 > float(INK_THRESH):
				mask.set_pixel(x, y, Color(1, 1, 1, 1))
	mask = _drop_specks(mask)
	var cols: PackedInt32Array = PackedInt32Array()
	cols.resize(w)
	for x in w:
		var c := 0
		for y in h:
			if mask.get_pixel(x, y).r > 0.5:
				c += 1
		cols[x] = c
	var spans := _pose_x_spans(cols)
	var poses: Array[Image] = []
	for span in spans:
		var x0: int = span[0]
		var x1: int = span[1]
		var xmin := x1
		var xmax := x0
		var ymin := h
		var ymax := -1
		for x in range(x0, x1 + 1):
			for y in h:
				if mask.get_pixel(x, y).r > 0.5:
					xmin = mini(xmin, x)
					xmax = maxi(xmax, x)
					ymin = mini(ymin, y)
					ymax = maxi(ymax, y)
		var crop := Image.create(xmax - xmin + 1, ymax - ymin + 1, false, Image.FORMAT_RGBA8)
		crop.fill(Color(0, 0, 0, 0))
		for y in range(ymin, ymax + 1):
			for x in range(xmin, xmax + 1):
				if mask.get_pixel(x, y).r > 0.5:
					crop.set_pixel(x - xmin, y - ymin, src.get_pixel(x, y))
		poses.append(crop)
	if poses.size() != expect:
		push_warning("pack_mike_walk_sheet: expected %d poses got %d" % [expect, poses.size()])
	return poses


func _pose_x_spans(cols: PackedInt32Array) -> Array:
	var runs: Array = []
	var start := -1
	for i in cols.size():
		if cols[i] >= MIN_COL_INK and start < 0:
			start = i
		elif cols[i] < MIN_COL_INK and start >= 0:
			runs.append([start, i - 1])
			start = -1
	if start >= 0:
		runs.append([start, cols.size() - 1])
	var merged: Array = []
	for run in runs:
		if merged.size() > 0 and run[0] - merged[-1][1] < MIN_GAP:
			merged[-1][1] = run[1]
		else:
			merged.append([run[0], run[1]])
	return merged


func _drop_specks(mask: Image) -> Image:
	var w := mask.get_width()
	var h := mask.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	visited.fill(0)
	var out := Image.create(w, h, false, Image.FORMAT_L8)
	out.fill(Color(0, 0, 0, 1))
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in h:
		for x in w:
			var idx := y * w + x
			if visited[idx] != 0 or mask.get_pixel(x, y).r <= 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			visited[idx] = 1
			var comp: Array[Vector2i] = []
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				comp.append(p)
				for d in dirs:
					var n: Vector2i = p + d
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
						continue
					var ni := n.y * w + n.x
					if visited[ni] != 0:
						continue
					if mask.get_pixel(n.x, n.y).r <= 0.5:
						continue
					visited[ni] = 1
					stack.append(n)
			if comp.size() > SPECK_MAX:
				for p2 in comp:
					out.set_pixel(p2.x, p2.y, Color(1, 1, 1, 1))
	return out


func _chin_y(pose: Image) -> int:
	var w := pose.get_width()
	var h := pose.get_height()
	var widths: PackedInt32Array = PackedInt32Array()
	widths.resize(h)
	for y in h:
		var xmin := w
		var xmax := -1
		for x in w:
			if pose.get_pixel(x, y).a * 255.0 > float(INK_THRESH):
				xmin = mini(xmin, x)
				xmax = maxi(xmax, x)
		if xmax >= 0:
			widths[y] = xmax - xmin + 1
	var search_h := maxi(20, int(float(h) * 0.40))
	var peak_y := 0
	var peak_w := 0
	for y in search_h:
		if widths[y] > peak_w:
			peak_w = widths[y]
			peak_y = y
	if peak_w < 8:
		return mini(int(float(h) * 0.28), h)
	var circle_bottom := mini(h, peak_y + int(float(peak_w) * FACE_BELOW_PEAK) + CHIN_PAD_PX)
	var neck_cut := maxi(8, int(float(peak_w) * NECK_WIDTH_RATIO))
	var limit := mini(h, circle_bottom + peak_w)
	var thin_run := 0
	for y in range(circle_bottom, limit):
		if widths[y] > 0 and widths[y] <= neck_cut:
			thin_run += 1
			if thin_run >= NECK_THIN_ROWS:
				return mini(h, y - thin_run + 1 + CHIN_PAD_PX)
		else:
			thin_run = 0
	return circle_bottom


func _fill_polygon(img: Image, poly: PackedVector2Array, color: Color) -> void:
	var min_y := 1e9
	var max_y := -1e9
	for p in poly:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var y0 := maxi(0, int(min_y))
	var y1 := mini(img.get_height() - 1, int(max_y))
	var n := poly.size()
	for y in range(y0, y1 + 1):
		var nodes: Array[float] = []
		for i in n:
			var p1: Vector2 = poly[i]
			var p2: Vector2 = poly[(i + 1) % n]
			if (p1.y < float(y) and p2.y >= float(y)) or (p2.y < float(y) and p1.y >= float(y)):
				var t := (float(y) - p1.y) / (p2.y - p1.y)
				nodes.append(p1.x + t * (p2.x - p1.x))
		nodes.sort()
		var j := 0
		while j + 1 < nodes.size():
			var x_a := maxi(0, int(nodes[j]))
			var x_b := mini(img.get_width() - 1, int(nodes[j + 1]))
			for x in range(x_a, x_b + 1):
				img.set_pixel(x, y, color)
			j += 2


func _finish_pose(pose: Image) -> Image:
	var w := pose.get_width()
	var h := pose.get_height()
	var chin := _chin_y(pose)
	var pts: PackedVector2Array = PackedVector2Array()
	for y in chin:
		for x in w:
			if pose.get_pixel(x, y).a * 255.0 > float(INK_THRESH):
				pts.append(Vector2(x, y))
	var plate := Image.create(w, h, false, Image.FORMAT_RGBA8)
	plate.fill(Color(0, 0, 0, 0))
	if pts.size() >= 3:
		var hull := Geometry2D.convex_hull(pts)
		if hull.size() >= 3:
			_fill_polygon(plate, hull, HEAD_FILL)
	var ink := Image.create(w, h, false, Image.FORMAT_RGBA8)
	ink.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var oc := pose.get_pixel(x, y)
			if oc.a * 255.0 > float(INK_THRESH):
				if y >= chin:
					ink.set_pixel(x, y, BODY_INK)
				else:
					var inv := 1.0 - (oc.r + oc.g + oc.b) / 3.0
					ink.set_pixel(x, y, Color(inv, inv, inv, oc.a))
	plate.blend_rect(ink, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return plate
