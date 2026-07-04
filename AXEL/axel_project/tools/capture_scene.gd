extends SceneTree
## Generic scene -> PNG capture helper.
##
## Loads an arbitrary scene, renders a few frames, then saves the root
## viewport to a PNG. Intended to be driven by `tools/capture_scene.sh`
## (which supplies a virtual X display + software rendering), but can also be
## run directly:
##
##   godot --path AXEL/axel_project -s res://tools/capture_scene.gd -- \
##       res://scenes/Main_Menu/0.1_MainMenu.tscn /tmp/out.png 30
##
## User args (after `--`):
##   1: scene path   (res:// path to a .tscn)   [required]
##   2: output path  (absolute .png path)       [required]
##   3: warmup frames (int, default 30)          [optional]
##
## Exit 0 on success, non-zero on failure.

const _DEFAULT_WARMUP_FRAMES := 30


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -s res://tools/capture_scene.gd -- <res://scene.tscn> <output.png> [frames]")
		quit(1)
		return

	var scene_path := String(args[0])
	var out_path := String(args[1])
	var warmup_frames := _DEFAULT_WARMUP_FRAMES
	if args.size() >= 3 and String(args[2]).is_valid_int():
		warmup_frames = maxi(1, int(args[2]))

	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: %s" % scene_path)
		quit(1)
		return

	var err := change_scene_to_file(scene_path)
	if err != OK:
		push_error("change_scene_to_file failed (%d) for %s" % [err, scene_path])
		quit(1)
		return

	# Let the scene enter the tree and become current.
	for _i in 4:
		await process_frame
	if current_scene == null:
		push_error("current_scene is null after loading %s" % scene_path)
		quit(1)
		return

	# Render enough frames for tweens / shaders / layout to settle.
	for _i in warmup_frames:
		await process_frame

	if not _save_viewport_png(out_path):
		push_error("Failed to capture viewport to %s" % out_path)
		quit(1)
		return

	print("Captured %s -> %s" % [scene_path, out_path])
	quit(0)


func _save_viewport_png(out_path: String) -> bool:
	var vp := root.get_viewport()
	if vp == null:
		return false
	var tex := vp.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.is_empty():
		return false
	var dir := out_path.get_base_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dir)
	return img.save_png(out_path) == OK
