extends SceneTree

const ROOM := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const ENDING := "7.1_Ending1.tscn"


func _init() -> void:
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	var saves := root.get_node_or_null("AxelSaves")
	if saves == null:
		push_error("continue_exit_spawn_check: AxelSaves missing")
		quit(1)
		return
	saves.dir_override = "user://saves_qa_exit_tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(saves.dir_override))
	for i in 3:
		saves._delete_slot_files(i)
	await process_frame
	change_scene_to_file(ROOM)
	if not await _wait_room():
		push_error("continue_exit_spawn_check: 1.1 failed to load")
		quit(1)
		return
	var scene := current_scene
	var env := scene.get_node_or_null("EnvironmentColliders") as Node2D
	var player := scene.find_child("Player", true, false) as Node2D
	var exit_area := scene.find_child("ExitTrigger", true, false) as Area2D
	if env == null or player == null or exit_area == null:
		push_error("continue_exit_spawn_check: room nodes missing")
		quit(1)
		return
	for _i in 5:
		await process_frame
	if not bool(saves.call("new_game", 0)):
		push_error("continue_exit_spawn_check: new_game failed")
		quit(1)
		return
	player.global_position = exit_area.global_position
	await process_frame
	var bad := PlayerSpawnSync.capture_tex(env, player)
	var body: Dictionary = saves.call("_read_body", 0)
	body["player_tex_x"] = bad.x
	body["player_tex_y"] = bad.y
	body["current_scene"] = ROOM
	saves.call("_atomic_write", saves.call("_body_path", 0), body)
	saves.call("deactivate")
	if not bool(saves.call("load_slot", 0)):
		push_error("continue_exit_spawn_check: load_slot failed")
		quit(1)
		return
	if not await _wait_room():
		push_error("continue_exit_spawn_check: reload failed")
		quit(1)
		return
	for _i in 45:
		await process_frame
		var path := ""
		if current_scene != null:
			path = current_scene.scene_file_path
		if path.ends_with(ENDING):
			push_error("continue_exit_spawn_check: load started Ending 1")
			quit(1)
			return
	var final_path := ""
	if current_scene != null:
		final_path = current_scene.scene_file_path
	if not final_path.ends_with("1.1_SchoolExterior.tscn"):
		push_error("continue_exit_spawn_check: expected 1.1, got %s" % final_path)
		quit(1)
		return
	var loaded := current_scene
	var loaded_player := loaded.find_child("Player", true, false) as Node2D
	var loaded_exit := loaded.find_child("ExitTrigger", true, false) as Area2D
	if loaded_player != null and loaded_exit != null:
		if InteractZoneGate.body_in_area(loaded_exit, loaded_player):
			push_error("continue_exit_spawn_check: player still overlaps the exit")
			quit(1)
			return
	print("Continue exit spawn check OK.")
	quit(0)


func _wait_room() -> bool:
	for _i in 180:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ROOM:
			return true
	return false
