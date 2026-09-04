extends SceneTree
## Resize staged AI icons to 256×256 and posterize to the 8-band noir palette.

const SIZE := 256
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
	var dir := DirAccess.open(SRC_DIR)
	if dir == null:
		quit(0)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var written := 0
	while name != "":
		if name.ends_with(".png") and not name.begins_with("L-A"):
			var img := Image.new()
			if img.load(abs_src.path_join(name)) == OK:
				img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
				_posterize(img)
				img.save_png(ProjectSettings.globalize_path(OUT_DIR + name))
				written += 1
		name = dir.get_next()
	dir.list_dir_end()
	print("remap_item_icons_noir wrote %d icons" % written)
	quit(0)


func _posterize(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.08:
				img.set_pixel(x, y, Color(0, 0, 0, 1))
				continue
			var best := PALETTE[0]
			var best_d := 999.0
			for p in PALETTE:
				var d := absf(c.r - p.r) + absf(c.g - p.g) + absf(c.b - p.b)
				if d < best_d:
					best_d = d
					best = p
			img.set_pixel(x, y, best)
