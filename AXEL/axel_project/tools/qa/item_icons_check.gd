extends SceneTree
## Phase 4: 75 icons at 256×256, every tres resolves, L-A has no file.

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
						elif img.get_width() != 256 or img.get_height() != 256:
							failures.append("%s icon is %dx%d not 256x256" % [item_id, img.get_width(), img.get_height()])
					if res.get("icon") == null:
						failures.append("%s tres has no icon" % item_id)
		name = dir.get_next()
	dir.list_dir_end()
	if icon_count != 75:
		failures.append("expected 75 item icons, got %d" % icon_count)
	if failures.is_empty():
		print("Item icons check OK (75 × 256).")
		quit(0)
	else:
		for f in failures:
			push_error("item_icons_check: %s" % f)
		quit(1)
