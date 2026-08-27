extends SceneTree
## Render the combat HUD to a PNG for visual review.
##
## Run (needs a real GPU context - do NOT pass --headless):
##   tools\cmd\godot.cmd --path AXEL/axel_project -s res://tools/qa/hud_capture.gd
##
## Output: user://hud_capture.png (path is printed on exit).

const SCENE_PATH := "res://combat/combat_test.tscn"
const OUT_PATH := "user://hud_capture.png"
const WINDOW := Vector2i(1920, 1280)
## Long enough for the scene-change glitch and interface pulse to settle.
const WARMUP_FRAMES := 220


func _initialize() -> void:
	root.size = WINDOW
	## Go through change_scene_to_file so autoloads (post-FX, music) wire up like a real run.
	if change_scene_to_file(SCENE_PATH) != OK:
		push_error("Could not load %s" % SCENE_PATH)
		quit(1)
		return
	_run()


func _run() -> void:
	for i in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		push_error("No frame captured (is this running headless?)")
		quit(1)
		return
	var err := img.save_png(OUT_PATH)
	if err != OK:
		push_error("save_png failed: %d" % err)
		quit(1)
		return
	print("hud_capture -> %s" % ProjectSettings.globalize_path(OUT_PATH))
	quit(0)
