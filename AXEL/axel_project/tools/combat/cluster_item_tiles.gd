extends SceneTree
## Group LimeZu interior singles that are the same object in different colors.
## Groups by opaque silhouette + brightness buckets (ignores hue and filename numbers).
## Usage (from repo root):
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/combat/cluster_item_tiles.gd -- "<Theme_Sorter_Singles_48x48>" [room_subdir]
## If room_subdir is omitted, processes every child folder under the singles root.
## Output (gitignored): res://tools/combat/.icon_scan/

const OUT_RES := "res://tools/combat/.icon_scan"
const TILE := 48
const CELL_PAD := 4
const LABEL_H := 10
const SHEET_COLS := 10
const ALPHA_CUT := 0.15


func _digit_glyphs() -> Array:
	# 3x5 digit glyphs (bits top→bottom, MSB left). Used to stamp cell indices on sheets.
	return [
		PackedByteArray([0b111, 0b101, 0b101, 0b101, 0b111]), # 0
		PackedByteArray([0b010, 0b110, 0b010, 0b010, 0b111]), # 1
		PackedByteArray([0b111, 0b001, 0b111, 0b100, 0b111]), # 2
		PackedByteArray([0b111, 0b001, 0b111, 0b001, 0b111]), # 3
		PackedByteArray([0b101, 0b101, 0b111, 0b001, 0b001]), # 4
		PackedByteArray([0b111, 0b100, 0b111, 0b001, 0b111]), # 5
		PackedByteArray([0b111, 0b100, 0b111, 0b101, 0b111]), # 6
		PackedByteArray([0b111, 0b001, 0b010, 0b010, 0b010]), # 7
		PackedByteArray([0b111, 0b101, 0b111, 0b101, 0b111]), # 8
		PackedByteArray([0b111, 0b101, 0b111, 0b001, 0b111]), # 9
	]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("CLUSTER_ITEM_TILES needs <Theme_Sorter_Singles_48x48> [room_subdir]")
		quit(1)
		return
	var singles_root := args[0].strip_edges().trim_suffix("/").trim_suffix("\\")
	if not DirAccess.dir_exists_absolute(singles_root):
		push_error("CLUSTER_ITEM_TILES missing folder: %s" % singles_root)
		quit(1)
		return
	var out_abs := ProjectSettings.globalize_path(OUT_RES)
	DirAccess.make_dir_recursive_absolute(out_abs)

	var rooms: PackedStringArray = PackedStringArray()
	if args.size() >= 2:
		rooms.append(args[1].strip_edges())
	else:
		var d := DirAccess.open(singles_root)
		if d == null:
			push_error("CLUSTER_ITEM_TILES cannot open: %s" % singles_root)
			quit(1)
			return
		d.list_dir_begin()
		var n := d.get_next()
		while n != "":
			if d.current_is_dir() and not n.begins_with("."):
				rooms.append(n)
			n = d.get_next()
		d.list_dir_end()
		rooms.sort()

	var total_clusters := 0
	var total_files := 0
	for room in rooms:
		var room_path := singles_root.path_join(room)
		if not DirAccess.dir_exists_absolute(room_path):
			push_warning("CLUSTER_ITEM_TILES skip missing room: %s" % room_path)
			continue
		var result := _cluster_room(room_path, room)
		total_clusters += int(result.get("clusters", 0))
		total_files += int(result.get("files", 0))
		var json_path := out_abs.path_join("%s_clusters.json" % room)
		var jf := FileAccess.open(json_path, FileAccess.WRITE)
		if jf != null:
			jf.store_string(JSON.stringify(result, "\t"))
			jf.close()
		var sheet: Image = result.get("sheet") as Image
		if sheet != null:
			sheet.save_png(out_abs.path_join("%s_sheet.png" % room))
		print(
			"CLUSTER_ITEM_TILES room=%s files=%d clusters=%d"
			% [room, int(result.get("files", 0)), int(result.get("clusters", 0))]
		)

	print("CLUSTER_ITEM_TILES done files=%d clusters=%d out=%s" % [total_files, total_clusters, out_abs])
	quit(0)


func _cluster_room(room_path: String, room_name: String) -> Dictionary:
	var files: PackedStringArray = PackedStringArray()
	var d := DirAccess.open(room_path)
	if d == null:
		return {"room": room_name, "files": 0, "clusters": 0, "items": []}
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not d.current_is_dir() and n.to_lower().ends_with(".png"):
			files.append(n)
		n = d.get_next()
	d.list_dir_end()
	files.sort()

	# fingerprint hex -> {files: [], scores: [], images: []}
	var buckets: Dictionary = {}
	for file_name in files:
		var full := room_path.path_join(file_name)
		var img := Image.new()
		if img.load(full) != OK:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var fp := _fingerprint_hex(img)
		if not buckets.has(fp):
			buckets[fp] = {"files": [], "scores": [], "images": []}
		var bucket: Dictionary = buckets[fp]
		(bucket["files"] as Array).append(file_name)
		(bucket["scores"] as Array).append(_contrast_score(img))
		(bucket["images"] as Array).append(img)

	var cluster_list: Array = []
	for fp in buckets.keys():
		var bucket: Dictionary = buckets[fp]
		var file_list: Array = bucket["files"]
		var scores: Array = bucket["scores"]
		var images: Array = bucket["images"]
		var best_i := 0
		var best_score := -1.0
		for i in scores.size():
			var s := float(scores[i])
			if s > best_score:
				best_score = s
				best_i = i
		cluster_list.append({
			"fingerprint": str(fp),
			"count": file_list.size(),
			"representative": str(file_list[best_i]),
			"files": file_list.duplicate(),
			"_img": images[best_i],
		})

	cluster_list.sort_custom(func(a, b): return str(a["representative"]) < str(b["representative"]))

	var items_out: Array = []
	var sheet := _build_sheet(cluster_list, items_out)
	return {
		"room": room_name,
		"files": files.size(),
		"clusters": cluster_list.size(),
		"sheet_cols": SHEET_COLS,
		"note": "Cell index is stamped on the sheet; map index → representative filename below. Do not use Theme_Sorter grid slots.",
		"items": items_out,
		"sheet": sheet,
	}


func _build_sheet(cluster_list: Array, items_out: Array) -> Image:
	var count := cluster_list.size()
	var cols := SHEET_COLS
	var rows := maxi(1, int(ceil(float(count) / float(cols))))
	var cell_w := TILE + CELL_PAD
	var cell_h := TILE + LABEL_H + CELL_PAD
	var sheet := Image.create(cols * cell_w + CELL_PAD, rows * cell_h + CELL_PAD, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.05, 0.0, 0.0, 1.0))
	for i in count:
		var cluster: Dictionary = cluster_list[i]
		var col := i % cols
		var row := int(i / cols)
		var ox := CELL_PAD + col * cell_w
		var oy := CELL_PAD + row * cell_h
		var src: Image = cluster["_img"] as Image
		if src != null:
			var blit := src.duplicate()
			if blit.get_width() != TILE or blit.get_height() != TILE:
				blit.resize(TILE, TILE, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(blit, Rect2i(0, 0, TILE, TILE), Vector2i(ox, oy))
		_stamp_index(sheet, ox, oy + TILE + 1, i)
		items_out.append({
			"index": i,
			"cell": "r%dc%d" % [row, col],
			"count": int(cluster["count"]),
			"representative": str(cluster["representative"]),
			"files": cluster["files"],
		})
	return sheet


func _fingerprint_hex(img: Image) -> String:
	# Opaque silhouette only — LimeZu recolors change which regions are light/dark.
	var w := img.get_width()
	var h := img.get_height()
	var bytes := PackedByteArray()
	bytes.resize(w * h)
	var i := 0
	for y in h:
		for x in w:
			var px := img.get_pixel(x, y)
			bytes[i] = 0 if px.a < ALPHA_CUT else 1
			i += 1
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


func _contrast_score(img: Image) -> float:
	var sum := 0.0
	var sum_sq := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a < ALPHA_CUT:
				continue
			var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
			sum += lum
			sum_sq += lum * lum
			n += 1
	if n < 2:
		return 0.0
	var mean := sum / float(n)
	var var_ := (sum_sq / float(n)) - mean * mean
	return var_ * float(n)


func _stamp_index(img: Image, x: int, y: int, index: int) -> void:
	var s := str(index)
	var cursor := x
	for ch in s:
		var digit := int(ch) - int("0")
		if digit < 0 or digit > 9:
			continue
		_blit_digit(img, cursor, y, digit)
		cursor += 4


func _blit_digit(img: Image, x: int, y: int, digit: int) -> void:
	var glyphs := _digit_glyphs()
	var glyph: PackedByteArray = glyphs[digit]
	var ink := Color(0.95, 0.35, 0.35, 1.0)
	for row in 5:
		var bits: int = glyph[row]
		for col in 3:
			if (bits & (1 << (2 - col))) != 0:
				var px := x + col
				var py := y + row
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, ink)
