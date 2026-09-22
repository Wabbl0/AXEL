extends SceneTree

const WILD := "res://combat/art/grid_symbols/satanic_wild.png"
const HALO := Color(96.0 / 255.0, 96.0 / 255.0, 96.0 / 255.0, 1.0)


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var img := Image.new()
	var abs_path := ProjectSettings.globalize_path(WILD)
	if img.load(abs_path) != OK:
		push_error("strip_wild_halo: could not load wild icon")
		quit(1)
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var stripped := 0
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if _is_halo(px):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				stripped += 1
	if img.save_png(abs_path) != OK:
		push_error("strip_wild_halo: could not save")
		quit(1)
		return
	print("strip_wild_halo cleared %d pixels" % stripped)
	quit(0)


func _is_halo(px: Color) -> bool:
	return (
		absf(px.r - HALO.r) < 0.01
		and absf(px.g - HALO.g) < 0.01
		and absf(px.b - HALO.b) < 0.01
		and px.a > 0.9
	)
