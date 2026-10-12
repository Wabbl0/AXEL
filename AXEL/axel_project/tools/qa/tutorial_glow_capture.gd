extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)

var _lesson := "fight_stakes"
var _out := "user://tutorial_glow_capture.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lesson="):
			_lesson = arg.substr(9)
		elif arg.begins_with("--out="):
			_out = arg.substr(6)
	root.size = WINDOW
	root.get_node("AxelProfile").call("debug_use_memory_only")
	if change_scene_to_file(SCENE_PATH) != OK:
		quit(1)
		return
	_run()


func _run() -> void:
	for i in 60:
		await process_frame
	var tutorial := root.get_node("AxelTutorial")
	tutorial.call("debug_set_enabled", true)
	tutorial.call("request", _lesson)
	for i in 400:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		quit(1)
		return
	img.save_png(_out)
	var layer := current_scene.get_node_or_null("HudHighlightLayer/HighlightRoot")
	if layer != null:
		for glow in layer.get_children():
			var art: Variant = glow.get("_art")
			if art is Control:
				var a := art as Control
				print("GLOW ", a.get_path(), " art_rect=", a.get_global_rect(), " glow_rect=", Rect2(glow.position, glow.size))
	for slot in tutorial.get("_slots"):
		if slot.card_host != null and slot.card_host.visible:
			print("CARD ", slot.open_id, " rect=", slot.card_host.get_global_rect(), " column=", slot.column.get_global_rect(), " vp=", root.get_visible_rect().size)
	quit(0)
