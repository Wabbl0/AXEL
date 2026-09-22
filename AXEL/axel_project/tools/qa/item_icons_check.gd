extends SceneTree

const ITEM_DIR := "res://combat/data/items/"
const ICON_DIR := "res://combat/art/item_icons/"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var failures: Array[String] = []
	if FileAccess.file_exists(ICON_DIR + "L-A.png"):
		failures.append("L-A.png must not exist")
	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		push_error("item_icons_check: missing items dir")
		quit(1)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var icon_count := 0
	while name != "":
		if name.ends_with(".tres"):
			var res := load(ITEM_DIR + name)
			if res == null:
				failures.append("could not load %s" % name)
			else:
				var item_id := String(res.get("id"))
				if item_id == "L-A":
					failures.append("L-A resource must not exist")
				else:
					var icon_path := ICON_DIR + item_id + ".png"
					if not FileAccess.file_exists(icon_path):
						failures.append("%s missing %s" % [item_id, icon_path])
					else:
						icon_count += 1
						var img := Image.new()
						if img.load(ProjectSettings.globalize_path(icon_path)) != OK:
							failures.append("%s icon failed to load" % item_id)
						elif img.get_width() != 1024 or img.get_height() != 1024:
							failures.append("%s icon is %dx%d not 1024x1024" % [item_id, img.get_width(), img.get_height()])
					if res.get("icon") == null:
						failures.append("%s tres has no icon" % item_id)
		name = dir.get_next()
	dir.list_dir_end()
	if icon_count != 75:
		failures.append("expected 75 item icons, got %d" % icon_count)
	_assert_c3_alpha(failures)
	_assert_remap_keeps_black_clear(failures)
	if failures.is_empty():
		print("Item icons check OK (75 × 1024).")
		quit(0)
	else:
		for f in failures:
			push_error("item_icons_check: %s" % f)
		quit(1)


func _assert_c3_alpha(failures: Array[String]) -> void:
	var img := Image.new()
	var path := ICON_DIR + "C3.png"
	if img.load(ProjectSettings.globalize_path(path)) != OK:
		failures.append("C3.png failed to load for alpha check")
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	if img.get_pixel(0, 0).a > 0.01:
		failures.append("C3 corner should be transparent")
	var found_red := false
	var step := 8
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var px := img.get_pixel(x, y)
			if px.a > 0.9 and px.r > 0.45 and px.r > px.g * 2.0 and px.r > px.b * 2.0:
				found_red = true
				break
		if found_red:
			break
	if not found_red:
		failures.append("C3 red pin pixels should stay opaque")


func _assert_remap_keeps_black_clear(failures: Array[String]) -> void:
	var src := FileAccess.get_file_as_string("res://tools/combat/remap_item_icons_noir.gd")
	if not src.contains("_is_matte_black"):
		failures.append("remap must test matte black before keeping a pixel")
	if not src.contains("data[i + 3] = 0"):
		failures.append("remap must write alpha 0 for black pixels")
