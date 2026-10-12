extends SceneTree

var _out := "user://glyph_mark_capture.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	root.size = Vector2i(1920, 1280)
	root.get_node("AxelProfile").call("debug_use_memory_only")
	change_scene_to_file("res://combat/combat_test.tscn")
	_run()


func _run() -> void:
	for i in 60:
		await process_frame
	var cr := current_scene.find_child("CombatRoot", true, false) as CombatRoot
	cr.inventory.equip(load("res://combat/data/items/R-M_scratch_ticket.tres"))
	cr.inventory.equip(load("res://combat/data/items/E-M_crt_etching.tres"))
	cr.spin()
	for i in 240:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out)
	var marks := 0
	for slot in cr.grid_ui.get_children():
		if slot.has_method("glyph_mark_text") and not str(slot.call("glyph_mark_text")).is_empty():
			marks += 1
	print("GLYPH_MARKS ", marks)
	quit(0)
