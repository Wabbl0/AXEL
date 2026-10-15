extends SceneTree

const SCENE := "res://combat/combat_test.tscn"
const SIZE := Vector2i(1920, 1280)

var _out_dir := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	call_deferred("_main")


func _main() -> void:
	if _out_dir.is_empty():
		_out_dir = ProjectSettings.globalize_path("user://curse_capture")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	root.size = SIZE
	DisplayServer.window_set_position(Vector2i(-10000, -10000))
	await process_frame
	if change_scene_to_file(SCENE) != OK:
		push_error("curse_hud_capture: could not load scene")
		quit(1)
		return
	await _frames(60)
	var combat := current_scene.find_child("CombatRoot", true, false)
	if combat == null:
		push_error("curse_hud_capture: no CombatRoot")
		quit(1)
		return
	combat.call("set_fight_curses", [
		{"id": &"short_fuse", "params": {"spins": 2}},
		{"id": &"blind"},
		{"id": &"heavy_meter"},
	])
	combat.call("debug_restart_fight")
	await _frames(150)
	await _shot("1_idle_spins_left")
	combat.call("_blind_cover_all")
	combat.call("_refresh_cells_visual")
	await _frames(5)
	await _shot("2_blind_face_down")
	combat.call("_blind_reveal_all")
	combat.set("enable_symbol_fx", false)
	combat.call("spin_sync")
	combat.set("enable_symbol_fx", true)
	await _frames(20)
	await _shot("3_one_spin_left")
	combat.call("spin")
	await _frames(24)
	await _shot("4_last_chance")
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
