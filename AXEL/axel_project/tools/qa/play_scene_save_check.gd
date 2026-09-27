extends SceneTree

const _QA_DIR := "user://saves_qa_play_scene"
const _REAL_DIR := "user://saves"
const _LOCKER := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const _EXTERIOR := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const _CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _CAFETERIA := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const _MENU := "res://scenes/Main_Menu/0.1_MainMenu.tscn"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var saves := root.get_node_or_null("AxelSaves")
	var gm := root.get_node_or_null("GameManager")
	if saves == null or gm == null:
		push_error("play_scene_save_check: AxelSaves missing")
		quit(1)
		return

	var locker_from_uid := String(saves._normalize_scene_arg("uid://7iwlp6l4dus3"))
	if locker_from_uid != _LOCKER:
		failures.append("locker uid did not resolve to the locker scene")

	if bool(saves.call("maybe_begin_play_scene")):
		failures.append("auto-start ran without --scene")
	if bool(saves.call("is_active")):
		failures.append("auto-start left a slot active")
	var play_dir := ProjectSettings.globalize_path("user://saves_play_scene")
	if DirAccess.dir_exists_absolute(play_dir):
		failures.append("auto-start created the play-scene folder")

	var real_before := _snapshot_dir(_REAL_DIR)

	if not bool(saves.call("begin_play_scene_session", _LOCKER, _QA_DIR)):
		failures.append("locker session did not start")
	else:
		await process_frame
		_expect_scene(saves, gm, failures, _LOCKER, true, true)
		saves.call("end_play_scene_session")
		await process_frame
		_expect_ended(saves, failures)

	if not bool(saves.call("begin_play_scene_session", _CAFETERIA, _QA_DIR)):
		failures.append("cafeteria session did not start")
	else:
		await process_frame
		_expect_scene(saves, gm, failures, _CAFETERIA, true, true)
		saves.call("end_play_scene_session")
		await process_frame
		_expect_ended(saves, failures)

	if not bool(saves.call("begin_play_scene_session", _CORRIDOR, _QA_DIR)):
		failures.append("corridor session did not start")
	else:
		await process_frame
		_expect_scene(saves, gm, failures, _CORRIDOR, false, false)
		saves.call("end_play_scene_session")
		await process_frame
		_expect_ended(saves, failures)

	if not bool(saves.call("begin_play_scene_session", _EXTERIOR, _QA_DIR)):
		failures.append("exterior session did not start")
	else:
		await process_frame
		_expect_scene(saves, gm, failures, _EXTERIOR, false, false)
		var rooms: Array = _body(saves).get("visited_rooms", [])
		if rooms.has(_EXTERIOR) or rooms.has(_CORRIDOR):
			failures.append("exterior start marked early rooms visited")
		saves.call("end_play_scene_session")
		await process_frame
		_expect_ended(saves, failures)

	if bool(saves.call("begin_play_scene_session", _MENU, _QA_DIR)):
		failures.append("menu scene started a play-scene save")
		saves.call("end_play_scene_session")

	var real_after := _snapshot_dir(_REAL_DIR)
	if not _same_snapshot(real_before, real_after):
		failures.append("user://saves changed")

	if failures.is_empty():
		print("Play scene save check OK.")
		quit(0)
	else:
		for failure in failures:
			push_error("play_scene_save_check: %s" % failure)
		quit(1)


func _expect_scene(
	saves: Node,
	gm: Node,
	failures: Array[String],
	scene_path: String,
	spawn_seen: bool,
	locker_seen: bool,
) -> void:
	var body := _body(saves)
	if String(body.get("current_scene", "")) != scene_path:
		failures.append("%s was not the saved scene" % scene_path.get_file())
	var header: Dictionary = saves.call("read_header", 0)
	if int(header.get("seed", 0)) == 0:
		failures.append("%s header is missing seed" % scene_path.get_file())
	var run_state: Dictionary = body.get("run_state", {})
	if int(run_state.get("bankroll_cents", 0)) != 1000:
		failures.append("%s did not start at 1000 chips" % scene_path.get_file())
	if bool(gm.get("corridor_spawn_line_seen")) != spawn_seen:
		failures.append("%s corridor spawn line flag" % scene_path.get_file())
	if bool(gm.get("corridor_locker_line_seen")) != locker_seen:
		failures.append("%s corridor locker line flag" % scene_path.get_file())
	if scene_path == _EXTERIOR:
		return
	var rooms: Array = body.get("visited_rooms", [])
	if not rooms.has(_EXTERIOR):
		failures.append("%s did not mark 1.1 visited" % scene_path.get_file())
	if scene_path != _CORRIDOR and not rooms.has(_CORRIDOR):
		failures.append("%s did not mark 1.2 visited" % scene_path.get_file())
	if not rooms.has(scene_path):
		failures.append("%s did not mark itself visited" % scene_path.get_file())
	var run_flags: Dictionary = body.get("run_state", {})
	if bool(run_flags.get("tutorial_fight_done", false)):
		failures.append("%s marked the tutorial fight done" % scene_path.get_file())


func _expect_ended(saves: Node, failures: Array[String]) -> void:
	if bool(saves.call("is_active")):
		failures.append("session still active after end")
	if String(saves.get("dir_override")) != "":
		failures.append("dir override left set after end")
	var body_path := "%s/slot_0.json" % _QA_DIR
	if FileAccess.file_exists(body_path):
		failures.append("temp save file was not deleted")


func _body(saves: Node) -> Dictionary:
	return saves._read_body(0)


func _snapshot_dir(path: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != ".." and not dir.current_is_dir():
			var file := FileAccess.open("%s/%s" % [path, name], FileAccess.READ)
			if file != null:
				out[name] = file.get_as_text()
				file.close()
		name = dir.get_next()
	dir.list_dir_end()
	return out


func _same_snapshot(before: Dictionary, after: Dictionary) -> bool:
	if before.size() != after.size():
		return false
	for key in before.keys():
		if not after.has(key) or String(before[key]) != String(after[key]):
			return false
	return true
