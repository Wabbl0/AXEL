extends SceneTree

const MENU := "res://scenes/Main_Menu/0.1_MainMenu.tscn"

var _out_dir := ""
var _size := Vector2i(1920, 1280)


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--size="):
			var parts := arg.substr(7).split("x")
			if parts.size() == 2:
				_size = Vector2i(int(parts[0]), int(parts[1]))
	call_deferred("_main")


func _main() -> void:
	if _out_dir.is_empty():
		_out_dir = ProjectSettings.globalize_path("user://feedback_capture")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	root.size = _size
	DisplayServer.window_set_size(_size)
	DisplayServer.window_set_position(Vector2i(-10000, -10000))
	await process_frame
	var fb := root.get_node_or_null("AxelFeedback")
	fb.set("outbox_dir", "user://feedback_capture_outbox")
	fb.set("network_enabled", false)
	if change_scene_to_file(MENU) != OK:
		quit(1)
		return
	await _frames(90)
	var tag := "%dx%d" % [_size.x, _size.y]
	await _shot("1_title_bar_" + tag)
	var form = fb.call("open_form")
	await _frames(10)
	await _shot("2_form_top_" + tag)
	form.call("set_choice", "overall", "4")
	form.call("set_choice", "difficulty", "Just right")
	form.call("set_text", "one_word", "creepy")
	await _frames(4)
	await _shot("2b_form_picked_" + tag)
	var scroll := form.find_child("Scroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 100000
	await _frames(10)
	await _shot("3_form_bottom_" + tag)
	form.call("press_send")
	await _frames(6)
	await _shot("4_form_saved_" + tag)
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := _out_dir.path_join(name + ".png")
	img.save_png(path)
	print("CAPTURE_OK %s" % path)
