extends SceneTree

const SIZE := 256
const OUT_DIR := "res://combat/art/item_icons/"
const ITEM_DIR := "res://combat/data/items/"
const REDS := [Color("1a0000"), Color("4a0000"), Color("8a0000"), Color("ff1a1a")]
const GREYS := [Color("2a2a2a"), Color("6a5a5a")]
const BLACKS := [Color("000000"), Color("0a0a0a")]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		push_error("bake_item_icons_256: missing items dir")
		quit(1)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var written := 0
	while name != "":
		if name.ends_with(".tres"):
			var res := load(ITEM_DIR + name)
			if res != null:
				var item_id := String(res.get("id"))
				if item_id != "L-A" and not item_id.is_empty():
					_write_icon(item_id, String(res.get("display_name")))
					written += 1
		name = dir.get_next()
	dir.list_dir_end()
	print("bake_item_icons_256 wrote %d icons at %dpx" % [written, SIZE])
	quit(0)


func _write_icon(item_id: String, display_name: String) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var h := item_id.hash()
	var bg: Color = BLACKS[h % 2]
	var ink: Color = REDS[(h >> 3) % REDS.size()]
	var grey: Color = GREYS[(h >> 6) % GREYS.size()]
	img.fill(bg)
	_frame(img, ink)
	_draw_glyph(img, display_name.to_lower(), ink, grey, h)
	img.save_png(ProjectSettings.globalize_path("%s%s.png" % [OUT_DIR, item_id]))


func _frame(img: Image, ink: Color) -> void:
	for y in range(12, SIZE - 12):
		for x in range(12, SIZE - 12):
			if x <= 16 or y <= 16 or x >= SIZE - 17 or y >= SIZE - 17:
				img.set_pixel(x, y, ink)


func _draw_glyph(img: Image, name_l: String, ink: Color, grey: Color, h: int) -> void:
	if name_l.contains("coin") or name_l.contains("token"):
		_fill_circle(img, 128, 128, 58, ink)
		_fill_circle(img, 128, 128, 28, grey)
	elif name_l.contains("pin") or name_l.contains("needle") or name_l.contains("syringe"):
		_fill_rect(img, 118, 40, 20, 140, ink)
		_fill_circle(img, 128, 40, 16, grey)
	elif name_l.contains("cigarette") or name_l.contains("wick") or name_l.contains("match"):
		_fill_rect(img, 70, 118, 120, 18, grey)
		_fill_rect(img, 178, 110, 22, 34, ink)
	elif name_l.contains("bottle") or name_l.contains("cap"):
		_fill_rect(img, 96, 80, 64, 100, ink)
		_fill_rect(img, 112, 56, 32, 28, grey)
	elif name_l.contains("gauze") or name_l.contains("tape") or name_l.contains("label") or name_l.contains("slip") or name_l.contains("ticket"):
		_fill_rect(img, 64, 80, 128, 90, grey)
		_fill_rect(img, 72, 88, 112, 16, ink)
	elif name_l.contains("battery"):
		_fill_rect(img, 88, 72, 80, 120, ink)
		_fill_rect(img, 112, 56, 32, 20, grey)
	elif name_l.contains("key") or name_l.contains("hasp") or name_l.contains("lock"):
		_fill_circle(img, 128, 96, 36, ink)
		_fill_rect(img, 120, 120, 16, 70, grey)
	elif name_l.contains("lighter") or name_l.contains("spark") or name_l.contains("burn"):
		_fill_rect(img, 100, 100, 56, 80, grey)
		_fill_circle(img, 128, 84, 22, ink)
	elif name_l.contains("charm") or name_l.contains("star") or name_l.contains("sigil") or name_l.contains("pentagram") or name_l.contains("glyph"):
		_fill_circle(img, 128, 128, 64, ink)
		_fill_rect(img, 120, 64, 16, 128, grey)
		_fill_rect(img, 64, 120, 128, 16, grey)
	elif name_l.contains("map") or name_l.contains("chalk"):
		_fill_rect(img, 60, 60, 136, 136, grey)
		_fill_rect(img, 76, 76, 104, 8, ink)
		_fill_rect(img, 76, 100, 80, 8, ink)
	elif name_l.contains("crown") or name_l.contains("halo"):
		_fill_rect(img, 64, 140, 128, 24, ink)
		_fill_circle(img, 80, 128, 16, grey)
		_fill_circle(img, 128, 112, 18, grey)
		_fill_circle(img, 176, 128, 16, grey)
	elif name_l.contains("satchel") or name_l.contains("ledger"):
		_fill_rect(img, 72, 88, 112, 96, ink)
		_fill_rect(img, 88, 72, 80, 20, grey)
	else:
		var rad := 36 + (h % 28)
		_fill_circle(img, 128, 128, rad, ink)
		_fill_rect(img, 118, 70, 20, 116, grey)


func _fill_circle(img: Image, cx: int, cy: int, rad: int, color: Color) -> void:
	for y in range(cy - rad, cy + rad + 1):
		for x in range(cx - rad, cx + rad + 1):
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= rad * rad:
				img.set_pixel(x, y, color)


func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, color: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			img.set_pixel(x, y, color)
