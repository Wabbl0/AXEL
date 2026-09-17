extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const OUT_PATH := "user://hud_capture.png"
const WINDOW := Vector2i(1920, 1280)
const WARMUP_FRAMES := 220


func _initialize() -> void:
	root.size = WINDOW

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
