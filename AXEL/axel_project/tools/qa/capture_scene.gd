extends SceneTree

const DEFAULT_FRAMES := 60
const DEFAULT_SIZE := Vector2i(1920, 1280)

var _scene_path := ""
var _out_path := ""
var _frames := DEFAULT_FRAMES
var _size := DEFAULT_SIZE
var _mode := "windowed"


func _init() -> void:
	_parse_args()
	call_deferred("_main")


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var eq := arg.find("=")
		if eq < 0:
			continue
		var key := arg.substr(0, eq)
		var value := arg.substr(eq + 1)
		match key:
			"--scene":
				_scene_path = value
			"--out":
				_out_path = value
			"--frames":
				_frames = maxi(value.to_int(), 1)
			"--size":
				var parts := value.to_lower().split("x")
				if parts.size() == 2:
					_size = Vector2i(maxi(parts[0].to_int(), 64), maxi(parts[1].to_int(), 64))
			"--mode":
				_mode = value.to_lower()


func _main() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("capture_scene: headless has no GPU/shaders — run without --headless.")
		quit(1)
		return
	if _scene_path.is_empty() or _out_path.is_empty():
		push_error("capture_scene: --scene and --out are required (after the -- separator).")
		quit(1)
		return
	if not ResourceLoader.exists(_scene_path):
		push_error("capture_scene: scene not found: %s" % _scene_path)
		quit(1)
		return


	match _mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			root.size = _size
		_:
			root.size = _size
	await process_frame


	if change_scene_to_file(_scene_path) != OK:
		push_error("capture_scene: could not load %s" % _scene_path)
		quit(1)
		return

	for _i in _frames:
		await process_frame
	await RenderingServer.frame_post_draw

	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("capture_scene: no frame captured (headless or no GPU context?).")
		quit(1)
		return

	var abs_out := _resolve_out_path(_out_path)
	var dir := abs_out.get_base_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("capture_scene: save_png failed (%d) for %s" % [err, abs_out])
		quit(1)
		return

	print("CAPTURE_OK %s %dx%d" % [abs_out, img.get_width(), img.get_height()])
	quit(0)


func _resolve_out_path(raw: String) -> String:
	if raw.begins_with("user://") or raw.begins_with("res://"):
		return ProjectSettings.globalize_path(raw)
	return raw
