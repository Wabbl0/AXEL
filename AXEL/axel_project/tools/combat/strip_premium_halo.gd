extends SceneTree
## Strip the 1px faint-white halo from premium grid icons (cigarette / booze / bloody_hand).
## Halo color matches generate_placeholders.py FAINT_WHITE (96,96,96). Idempotent.
##
## Run:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/combat/strip_premium_halo.gd

const SYMBOLS_DIR := "res://combat/art/grid_symbols/"
const FILES: PackedStringArray = [
	"cigarette.png",
	"booze.png",
	"bloody_hand.png",
]
const FAINT_R := 96
const FAINT_G := 96
const FAINT_B := 96


func _initialize() -> void:
	var stripped := 0
	var skipped := 0
	var failed := 0
	for file_name in FILES:
		var path := SYMBOLS_DIR + file_name
		var result := _process_one(path)
		match result:
			"ok":
				stripped += 1
				print("strip_premium_halo: stripped %s" % path)
			"skip":
				skipped += 1
				print("strip_premium_halo: no halo on %s" % path)
			_:
				failed += 1
				push_error("strip_premium_halo: failed %s (%s)" % [path, result])
	print(
		"strip_premium_halo done: stripped=%d skipped=%d failed=%d"
		% [stripped, skipped, failed]
	)
	quit(0 if failed == 0 else 1)


func _process_one(res_path: String) -> String:
	if not ResourceLoader.exists(res_path) and not FileAccess.file_exists(res_path):
		return "missing"
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		return "load_fail"
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var painted := 0
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var r := int(round(c.r * 255.0))
			var g := int(round(c.g * 255.0))
			var b := int(round(c.b * 255.0))
			if r == FAINT_R and g == FAINT_G and b == FAINT_B:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, c.a))
				painted += 1
	if painted == 0:
		return "skip"
	var err := img.save_png(abs_path)
	if err != OK:
		return "save_fail_%d" % err
	return "ok"
