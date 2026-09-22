extends SceneTree

const SIZE := 1024
const SRC_DIR := "res://tools/combat/ai_icon_src/"
const OUT_DIR := "res://combat/art/item_icons/"
const PALETTE := [
	Color("000000"), Color("0a0a0a"),
	Color("2a2a2a"), Color("6a5a5a"),
	Color("1a0000"), Color("4a0000"), Color("8a0000"), Color("ff1a1a"),
]


func _init() -> void:
	var abs_src := ProjectSettings.globalize_path(SRC_DIR)
	if not DirAccess.dir_exists_absolute(abs_src):
		print("remap_item_icons_noir: no staging dir")
		quit(0)
		return
	var dir := DirAccess.open(abs_src)
	if dir == null:
		quit(0)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var written := 0
	var failed := false
	while name != "":
		if name.ends_with(".png") and not name.begins_with("L-A"):
			var img := Image.new()
			if img.load(abs_src.path_join(name)) != OK:
				push_error("remap_item_icons_noir: failed to load %s" % name)
				failed = true
			elif not _fit_to_size(img, name):
				failed = true
			else:
				_posterize(img)
				img.save_png(ProjectSettings.globalize_path(OUT_DIR + name))
				written += 1
				print("remap_item_icons_noir wrote %s" % name)
		name = dir.get_next()
	dir.list_dir_end()
	print("remap_item_icons_noir wrote %d icons" % written)
	quit(1 if failed else 0)


func _fit_to_size(img: Image, name: String) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	if w > SIZE or h > SIZE:
		push_error("remap_item_icons_noir: %s is %dx%d (larger than %d). Will not downscale." % [name, w, h, SIZE])
		return false
	if w < SIZE or h < SIZE:
		img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return true


func _posterize(img: Image) -> void:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	var n := data.size()
	var pal := PALETTE
	var i := 0
	while i < n:
		if data[i + 3] < 20 or _is_matte_black(data[i], data[i + 1], data[i + 2]):
			data[i] = 0
			data[i + 1] = 0
			data[i + 2] = 0
			data[i + 3] = 0
		else:
			var r := float(data[i]) / 255.0
			var g := float(data[i + 1]) / 255.0
			var b := float(data[i + 2]) / 255.0
			var best: Color = pal[0]
			var best_d := 999.0
			for p in pal:
				var pc: Color = p
				var d := absf(r - pc.r) + absf(g - pc.g) + absf(b - pc.b)
				if d < best_d:
					best_d = d
					best = pc
			data[i] = int(best.r * 255.0)
			data[i + 1] = int(best.g * 255.0)
			data[i + 2] = int(best.b * 255.0)
			if _is_matte_black(data[i], data[i + 1], data[i + 2]):
				data[i + 3] = 0
			else:
				data[i + 3] = 255
		i += 4
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)


func _is_matte_black(r: int, g: int, b: int) -> bool:
	return maxi(r, maxi(g, b)) <= 10
