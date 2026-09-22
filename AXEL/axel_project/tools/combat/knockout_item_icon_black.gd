extends SceneTree

const ICON_DIR := "res://combat/art/item_icons/"
const BLACK_MAX := 10


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var dir := DirAccess.open(ICON_DIR)
	if dir == null:
		push_error("knockout_item_icon_black: missing %s" % ICON_DIR)
		quit(1)
		return
	var written := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".png") and not name.begins_with("L-A"):
			var path := ICON_DIR + name
			var img := Image.new()
			if img.load(ProjectSettings.globalize_path(path)) != OK:
				push_error("knockout_item_icon_black: failed %s" % name)
				quit(1)
				return
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
			var data := img.get_data()
			var i := 0
			var n := data.size()
			while i < n:
				if maxi(data[i], maxi(data[i + 1], data[i + 2])) <= BLACK_MAX:
					data[i] = 0
					data[i + 1] = 0
					data[i + 2] = 0
					data[i + 3] = 0
				i += 4
			img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
			if img.save_png(ProjectSettings.globalize_path(path)) != OK:
				push_error("knockout_item_icon_black: could not save %s" % name)
				quit(1)
				return
			written += 1
		name = dir.get_next()
	dir.list_dir_end()
	print("knockout_item_icon_black wrote %d" % written)
	quit(0)
