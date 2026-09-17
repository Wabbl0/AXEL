extends SceneTree
## One-off: writes a pure-white 3508×2480 plate for combat HudArt.


func _initialize() -> void:
	var img := Image.create(3508, 2480, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var path := "res://exports/Drawings/axel_combat_plate_white.png"
	var err := img.save_png(path)
	if err != OK:
		push_error("make_white_plate: save_png failed (%s) -> %s" % [str(err), path])
		quit(1)
		return
	print("make_white_plate: wrote %s" % path)
	quit(0)
