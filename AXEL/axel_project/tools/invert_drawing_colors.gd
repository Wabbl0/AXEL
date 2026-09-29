extends SceneTree

const DRAWINGS_DIR := "res://exports/Drawings/"
const BACKUP_DIR := "res://exports/Drawings/backup_pre_invert/"
const FILES: PackedStringArray = [
	"axel_combat_grid.png",
	"axel_combat_history.png",
	"axel_combat_items.png",
	"axel_combat_bets.png",
	"axel_combat_goal.png",
	"axel_combat_multiplier.png",
	"axel_combat_exit.png",
	"axel_skull_1.png",
	"axel_skull_2.png",
	"axel_skull_3.png",
]
const ALREADY_INVERTED_MEAN_LUM := 0.50
const ALPHA_OPAQUE := 0.06


func _initialize() -> void:
	var abs_backup := ProjectSettings.globalize_path(BACKUP_DIR)
	var dir_err := DirAccess.make_dir_recursive_absolute(abs_backup)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("invert_drawing_colors: cannot create backup dir (%s) -> %s" % [str(dir_err), BACKUP_DIR])
		quit(1)
		return

	var inverted := 0
	var skipped := 0
	var failed := 0
	for file_name in FILES:
		var src_path := DRAWINGS_DIR + file_name
		var result := _process_one(src_path, file_name)
		match result:
			"inverted":
				inverted += 1
			"skipped":
				skipped += 1
			_:
				failed += 1

	print(
		"invert_drawing_colors: inverted=%d skipped=%d failed=%d (backup=%s)"
		% [inverted, skipped, failed, BACKUP_DIR]
	)
	quit(0 if failed == 0 else 1)


func _process_one(src_path: String, file_name: String) -> String:
	if not FileAccess.file_exists(src_path):
		push_error("invert_drawing_colors: missing %s" % src_path)
		return "failed"

	var img := Image.new()
	var load_err := img.load(src_path)
	if load_err != OK:
		push_error("invert_drawing_colors: load failed (%s) -> %s" % [str(load_err), src_path])
		return "failed"

	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var mean_lum := _mean_opaque_luminance(img)
	if mean_lum >= ALREADY_INVERTED_MEAN_LUM:
		print("invert_drawing_colors: already inverted (mean_lum=%.3f) — skip %s" % [mean_lum, file_name])
		return "skipped"

	var backup_path := BACKUP_DIR + file_name
	if not FileAccess.file_exists(backup_path):
		var copy_err := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(src_path),
			ProjectSettings.globalize_path(backup_path)
		)
		if copy_err != OK:
			push_error("invert_drawing_colors: backup failed (%s) -> %s" % [str(copy_err), backup_path])
			return "failed"
		print("invert_drawing_colors: backed up %s" % file_name)
	else:
		print("invert_drawing_colors: backup exists — keep %s" % file_name)

	_invert_opaque_rgb(img)
	var save_err := img.save_png(src_path)
	if save_err != OK:
		push_error("invert_drawing_colors: save_png failed (%s) -> %s" % [str(save_err), src_path])
		return "failed"

	print("invert_drawing_colors: inverted %s (was mean_lum=%.3f)" % [file_name, mean_lum])
	return "inverted"


func _mean_opaque_luminance(img: Image) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var sum := 0.0
	var count := 0

	@warning_ignore("integer_division")
	var step := maxi(1, mini(w, h) / 200)
	for y in range(0, h, step):
		for x in range(0, w, step):
			var c := img.get_pixel(x, y)
			if c.a < ALPHA_OPAQUE:
				continue
			sum += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			count += 1
	if count == 0:
		return 1.0
	return sum / float(count)


func _invert_opaque_rgb(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a < ALPHA_OPAQUE:
				continue
			img.set_pixel(x, y, Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a))
