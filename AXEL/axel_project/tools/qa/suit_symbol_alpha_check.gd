extends SceneTree

const SUITS := [
	"res://combat/art/grid_symbols/green_circle.png",
	"res://combat/art/grid_symbols/yellow_triangle.png",
	"res://combat/art/grid_symbols/blue_star.png",
	"res://combat/art/grid_symbols/red_heart.png",
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var failures: Array[String] = []
	for path in SUITS:
		var tex := load(path) as Texture2D
		if tex == null:
			failures.append("missing %s" % path)
			continue
		var img := tex.get_image()
		if img == null:
			failures.append("no image for %s" % path)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		if _alpha_at(img, 0, 0) > 0 or _alpha_at(img, w - 1, 0) > 0:
			failures.append("%s corner is not transparent" % path)
		if _alpha_at(img, 0, h - 1) > 0 or _alpha_at(img, w - 1, h - 1) > 0:
			failures.append("%s bottom corner is not transparent" % path)
		var plug := 0
		for y in range(h):
			for x in range(w):
				var c := img.get_pixel(x, y)
				if c.a >= 0.99 and c.r <= 0.02 and c.g <= 0.02 and c.b <= 0.02:
					plug += 1
		if plug < 8:
			failures.append("%s has no inner black plug (%d px)" % [path, plug])
	if failures.is_empty():
		print("Suit symbol alpha check OK.")
		quit(0)
	else:
		for msg in failures:
			push_error("suit_symbol_alpha_check: %s" % msg)
		quit(1)


func _alpha_at(img: Image, x: int, y: int) -> float:
	return img.get_pixel(x, y).a
