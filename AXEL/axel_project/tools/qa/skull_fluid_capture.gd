extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)

var _out_dir := "user://"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	root.size = WINDOW
	root.get_node("AxelProfile").call("debug_use_memory_only")
	if change_scene_to_file(SCENE_PATH) != OK:
		quit(1)
		return
	_run()


func _run() -> void:
	root.get_node("AxelTutorial").call("debug_set_enabled", false)
	for i in 60:
		await process_frame
	var skull := current_scene.find_child("PremiumSkull", true, false) as Control
	if skull == null:
		quit(1)
		return
	skull.call("set_fill", 1.0 / 3.0)
	await _hold(50)
	await _shot(skull, "fluid_1of3.png")
	skull.call("set_fill", 2.0 / 3.0)
	await _hold(50)
	await _shot(skull, "fluid_2of3.png")
	skull.call("set_full_face_locked", true)
	skull.call("set_fill", 1.0)
	await _hold(60)
	await _shot(skull, "fluid_full.png")
	skull.call("play_spit", true)
	await _hold(14)
	await _shot(skull, "fluid_spit_a.png")
	await _hold(14)
	await _shot(skull, "fluid_spit_b.png")
	quit(0)


func _hold(frames: int) -> void:
	for i in frames:
		_hide_tutorial_glow()
		await process_frame
	_hide_tutorial_glow()


func _hide_tutorial_glow() -> void:
	var highlight := current_scene.get_node_or_null("HudHighlightLayer") as CanvasLayer
	if highlight != null:
		highlight.visible = false


func _shot(skull: Control, file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		return
	var box := Rect2i(skull.get_global_rect().grow(260.0)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	img.get_region(box).save_png(_out_dir.path_join(file))
	print("SHOT ", file, " level=", skull.call("fluid_level"))
