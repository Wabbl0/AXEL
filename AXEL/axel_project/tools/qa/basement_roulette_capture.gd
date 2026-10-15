extends SceneTree

var _out := "user://basement_roulette_capture.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	root.size = Vector2i(1920, 1280)
	root.get_node("AxelProfile").call("debug_use_memory_only")
	_run()


func _run() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-10000, -10000))
	await process_frame
	root.size = Vector2i(1920, 1280)
	DisplayServer.window_set_position(Vector2i(-10000, -10000))
	await process_frame
	var world := root.get_node("AxelWorld")
	var run := root.get_node("AxelRun")
	run.call("reset_run")
	run.state.seed = 4242
	run.state.tickets = 2
	world.call("reset_world")
	world.call("plan_floor_items", 4242)
	change_scene_to_file("res://scenes/Arc_6/6.4_BasementMain.tscn")
	for i in 30:
		await process_frame
	var greybox := current_scene
	var dialogue := greybox.get("_dialogue") as Node
	if dialogue != null and dialogue.has_method("interrupt_line"):
		dialogue.call("interrupt_line")
	greybox.call("_run_roulette")
	for i in 10:
		await process_frame
	var roulette := greybox.get("_roulette") as Node
	for child in roulette.find_children("*", "Button", true, false):
		if (child as Button).text == "Spin":
			(child as Button).emit_signal("pressed")
	while bool(roulette.call("is_spinning")):
		await process_frame
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out)
	print("ROULETTE_ITEM ", world.call("roulette_item"))
	quit(0)
