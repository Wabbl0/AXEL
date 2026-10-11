extends Node

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const DIR := "user://saves"
const PLAY_SCENE_DIR := "user://saves_play_scene"
const NEW_GAME_SCENE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MENU_PREFIX := "res://scenes/Main_Menu/"
const MAP_MEMORY_KEY := "scene_3"
const _SCENE_ARG := "--scene"

signal slots_changed
signal active_slot_changed(slot: int)

var active_slot: int = -1
var dir_override := ""
var _playtime_sec: float = 0.0
var _save_queued := false
var _write_blocked: Dictionary = {}
var _before_slot_write := Callable()
var _pending_tex := Vector2.ZERO
var _pending_tex_valid := false
var _skip_intro_once := false
var _last_slot: int = -1
var _play_scene_session := false
var _play_scene_dir := ""
var _flush_scene_override := ""


func _enter_tree() -> void:
	_purge_directory(PLAY_SCENE_DIR)
	DirAccess.make_dir_recursive_absolute(_abs_dir())
	_last_slot = _read_index_last_slot()


func _exit_tree() -> void:
	if _play_scene_session:
		end_play_scene_session()


func _ready() -> void:
	_purge_dead_slots()
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_active() and not _play_scene_session:
		save_active_now()


func _process(delta: float) -> void:
	if not is_active():
		return
	if get_tree().paused:
		return
	if _is_menu_scene():
		return
	_playtime_sec += delta


func is_active() -> bool:
	return active_slot >= 0 and active_slot < SLOT_COUNT


func last_living_slot() -> int:
	if _is_living(_last_slot):
		return _last_slot
	for i in SLOT_COUNT:
		if _is_living(i):
			return i
	return -1


func has_living_slot() -> bool:
	return last_living_slot() >= 0


func has_any_slot() -> bool:
	for i in SLOT_COUNT:
		if not is_empty(i):
			return true
	return false


func has_map() -> bool:
	return GameManager.has_memory_scene(MAP_MEMORY_KEY)


func consume_skip_intro() -> bool:
	var once := _skip_intro_once
	_skip_intro_once = false
	return once


func read_header(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return {}
	var path := _meta_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed


func is_dead(slot: int) -> bool:
	var header := read_header(slot)
	return not header.is_empty() and bool(header.get("dead", false))


func is_empty(slot: int) -> bool:
	return read_header(slot).is_empty()


func first_free_slot() -> int:
	for i in SLOT_COUNT:
		if is_empty(i) or is_dead(i):
			return i
	return -1


func oldest_living_slot() -> int:
	var best := -1
	var best_ts := 9223372036854775807
	for i in SLOT_COUNT:
		if not _is_living(i):
			continue
		var stamp := int(read_header(i).get("timestamp_unix", 0))
		if stamp < best_ts or (stamp == best_ts and (best < 0 or i < best)):
			best = i
			best_ts = stamp
	return best


func living_slot_count() -> int:
	var n := 0
	for i in SLOT_COUNT:
		if _is_living(i):
			n += 1
	return n


func begin_new_game_and_enter(slot: int) -> bool:
	var fx := get_node_or_null("/root/AxelEventFx")
	if fx != null and fx.has_method("fade_to_black"):
		await fx.fade_to_black()
	if not new_game(slot):
		if fx != null and fx.has_method("fade_from_black"):
			await fx.fade_from_black()
		return false
	await _wait_floor_spots()
	_play_overworld_music()
	if not _change_scene(NEW_GAME_SCENE):
		if fx != null and fx.has_method("fade_from_black"):
			await fx.fade_from_black()
		return false
	if fx != null and fx.has_method("reveal_after_intro_pose"):
		await fx.reveal_after_intro_pose()
	return true


func begin_new_game_immediate(slot: int) -> bool:
	if not new_game(slot):
		return false
	_play_overworld_music()
	return _change_scene(NEW_GAME_SCENE)


func _play_overworld_music() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_overworld"):
		music.call("to_overworld")


func _wait_floor_spots() -> void:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("map_spots_settled"):
		return
	var tree := get_tree()
	if tree == null:
		return
	var spins := 0
	while is_inside_tree() and not bool(world.call("map_spots_settled")):
		spins += 1
		if spins > 1800:
			break
		await tree.process_frame


func new_game(slot: int) -> bool:
	if not _valid_slot(slot):
		return false
	_save_queued = false
	_write_blocked.erase(slot)
	_delete_slot_files(slot)
	GameManager.reset_state()
	var profile := get_node_or_null("/root/AxelProfile")
	if profile != null and profile.has_method("begin_new_run"):
		profile.call("begin_new_run")
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("forget_session_marks"):
		tutorial.call("forget_session_marks")
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("reset_run"):
		run.call("reset_run", slot)
	var world := get_node_or_null("/root/AxelWorld")
	if run != null and world != null and world.has_method("plan_floor_items"):
		world.call("plan_floor_items", int(run.state.seed))
	active_slot = slot
	_playtime_sec = 0.0
	_pending_tex_valid = false
	_skip_intro_once = false
	_write_index(slot)
	_flush_save(NEW_GAME_SCENE)
	active_slot_changed.emit(slot)
	slots_changed.emit()
	return true


func maybe_begin_play_scene() -> bool:
	if not OS.is_debug_build():
		return false
	if _play_scene_session or is_active():
		return false
	if not dir_override.is_empty():
		return false
	var scene_path := _cmdline_scene_path()
	if scene_path.is_empty() or _is_menu_path(scene_path):
		return false
	if not begin_play_scene_session(scene_path):
		return false
	var profile := get_node_or_null("/root/AxelProfile")
	if profile != null and profile.has_method("begin_play_scene_profile"):
		profile.call("begin_play_scene_profile")
	return true


func begin_play_scene_session(scene_path: String, save_dir: String = "") -> bool:
	if _play_scene_session or is_active():
		return false
	if scene_path.is_empty() or _is_menu_path(scene_path):
		return false
	if not ResourceLoader.exists(scene_path):
		return false
	var folder := PLAY_SCENE_DIR if save_dir.is_empty() else save_dir
	if folder == DIR:
		return false
	_purge_directory(folder)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	dir_override = folder
	if not new_game(0):
		dir_override = ""
		_purge_directory(folder)
		return false
	_play_scene_session = true
	_play_scene_dir = folder
	_stamp_play_scene_arrival(scene_path)
	return true


func end_play_scene_session() -> void:
	if not _play_scene_session:
		return
	_save_queued = false
	_flush_scene_override = ""
	var slot := active_slot
	if slot >= 0:
		_write_blocked[slot] = true
	var folder := _play_scene_dir
	_play_scene_session = false
	_play_scene_dir = ""
	if dir_override == folder:
		dir_override = ""
	var was_active := active_slot >= 0
	active_slot = -1
	_pending_tex_valid = false
	_purge_directory(folder)
	if was_active:
		active_slot_changed.emit(-1)


func load_slot(slot: int) -> bool:
	if not _valid_slot(slot) or is_empty(slot) or is_dead(slot):
		return false
	var body := _read_body(slot)
	if body.is_empty():
		return false
	GameManager.import_save_body(body)
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("from_dict"):
		run.call("from_dict", body.get("run_state", {}))
		var profile := get_node_or_null("/root/AxelProfile")
		if profile != null:
			profile.call("merge_from_run", run.get("state"))
	active_slot = slot
	_playtime_sec = float(body.get("playtime_sec", 0.0))
	_write_index(slot)
	var scene_path := String(body.get("current_scene", NEW_GAME_SCENE))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		scene_path = NEW_GAME_SCENE
	if body.has("player_tex_x") and body.has("player_tex_y"):
		_pending_tex = Vector2(float(body["player_tex_x"]), float(body["player_tex_y"]))
		_pending_tex_valid = true
		_skip_intro_once = true
	active_slot_changed.emit(slot)
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_overworld"):
		music.call("to_overworld")
	return _change_scene(scene_path)


func continue_last() -> bool:
	var slot := last_living_slot()
	if slot < 0:
		return false
	return load_slot(slot)


func save_active() -> void:
	if not is_active() or _is_write_blocked(active_slot):
		return
	_queue_save()


func save_active_now() -> void:
	if not is_active() or _is_write_blocked(active_slot):
		return
	var scene := get_tree().current_scene
	var path := ""
	if scene != null:
		path = scene.scene_file_path
	_flush_save(path)


func delete_slot(slot: int) -> bool:
	if not _valid_slot(slot) or is_empty(slot):
		return false
	_save_queued = false
	_write_blocked[slot] = true
	if not _delete_slot_files(slot):
		_write_blocked.erase(slot)
		return false
	if active_slot == slot:
		active_slot = -1
		active_slot_changed.emit(-1)
	slots_changed.emit()
	return true


func write_tombstone(slot: int) -> void:
	delete_slot(slot)


func deactivate() -> void:
	if _play_scene_session:
		end_play_scene_session()
		return
	if is_active():
		save_active_now()
	active_slot = -1
	_pending_tex_valid = false
	active_slot_changed.emit(-1)


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if _play_scene_session and scene != null and _is_menu_path(scene.scene_file_path):
		end_play_scene_session()
		return
	if not is_active() or _is_write_blocked(active_slot):
		return
	if scene == null or _is_menu_path(scene.scene_file_path):
		return
	if _pending_tex_valid:
		_restore_player_tex.call_deferred(scene)
	_flush_save(scene.scene_file_path)


func _restore_player_tex(scene: Node) -> void:
	if not _pending_tex_valid:
		return
	for _i in 10:
		await get_tree().process_frame
	if scene != get_tree().current_scene:
		return
	var env := scene.get_node_or_null("EnvironmentColliders") as Node2D
	var player := scene.find_child("Player", true, false) as Node2D
	if env != null and player != null:
		var spawn_tex := PlayerSpawnSync.capture_tex(env, player)
		PlayerSpawnSync.apply_tex(env, player, _pending_tex)
		if _player_in_named_exit(scene, player):
			PlayerSpawnSync.apply_tex(env, player, spawn_tex)
	_pending_tex_valid = false
	if scene.scene_file_path != "":
		_flush_save(scene.scene_file_path)


func _queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	_flush_save_deferred.call_deferred()


func _flush_save_deferred() -> void:
	_save_queued = false
	var forced := _flush_scene_override
	_flush_scene_override = ""
	if not is_active() or _is_write_blocked(active_slot):
		return
	if not forced.is_empty():
		_flush_save(forced)
		return
	var scene := get_tree().current_scene
	var path := ""
	if scene != null:
		path = scene.scene_file_path
	_flush_save(path)


func _tex_save_allowed(scene: Node, player: Node2D) -> bool:
	if scene.has_method("blocks_player_tex_save") and bool(scene.call("blocks_player_tex_save")):
		return false
	return not _player_in_named_exit(scene, player)


func _player_in_named_exit(scene: Node, player: Node2D) -> bool:
	var exit := scene.find_child("ExitTrigger", true, false) as Area2D
	if exit == null or player == null:
		return false
	return InteractZoneGate.body_in_area(exit, player)


func _keep_previous_tex(body: Dictionary, slot: int, scene_path: String) -> void:
	var previous := _read_body(slot)
	if String(previous.get("current_scene", "")) != scene_path:
		return
	if not previous.has("player_tex_x") or not previous.has("player_tex_y"):
		return
	body["player_tex_x"] = previous["player_tex_x"]
	body["player_tex_y"] = previous["player_tex_y"]


func _flush_save(scene_path: String) -> void:
	if not is_active() or _is_write_blocked(active_slot):
		return
	if _is_menu_path(scene_path):
		return
	var slot := active_slot
	var body := GameManager.export_save_body()
	body["playtime_sec"] = _playtime_sec
	if not scene_path.is_empty():
		body["current_scene"] = scene_path
	var scene := get_tree().current_scene
	if _pending_tex_valid:
		body["player_tex_x"] = _pending_tex.x
		body["player_tex_y"] = _pending_tex.y
	elif scene != null and scene.scene_file_path == scene_path:
		var env := scene.get_node_or_null("EnvironmentColliders") as Node2D
		var player := scene.find_child("Player", true, false) as Node2D
		if env != null and player != null and _tex_save_allowed(scene, player):
			var tex := PlayerSpawnSync.capture_tex(env, player)
			body["player_tex_x"] = tex.x
			body["player_tex_y"] = tex.y
		else:
			_keep_previous_tex(body, slot, scene_path)
	if not _can_write_slot(slot):
		return
	if _before_slot_write.is_valid():
		_before_slot_write.call(slot)
	if not _can_write_slot(slot):
		return
	var header := _header_from_body(body, scene_path)
	_atomic_write(_meta_path(slot), header)
	if not _can_write_slot(slot):
		_delete_slot_files(slot)
		return
	_atomic_write(_body_path(slot), body)
	if not _can_write_slot(slot):
		_delete_slot_files(slot)
		return
	_write_index(slot)
	slots_changed.emit()


func _header_from_live(scene_path: String) -> Dictionary:
	return _header_from_body(GameManager.export_save_body(), scene_path)


func _header_from_body(body: Dictionary, scene_path: String) -> Dictionary:
	var state: Dictionary = body.get("game_state", {})
	var flags: Dictionary = state.get("flags", {})
	var items: Array = []
	if bool(flags.get("hasFlashlight", false)):
		items.append("Flashlight")
	if bool(flags.get("hasKey", false)):
		items.append("Key")
	if bool(flags.get("hasShovel", false)):
		items.append("Shovel")
	if bool(flags.get("hasName", false)):
		items.append("Name")
	var room := scene_path.get_file().get_basename()
	if room.is_empty():
		room = String(body.get("current_scene", "")).get_file().get_basename()
	var run_state: Dictionary = body.get("run_state", {})
	var combat_items: Array = run_state.get("owned_item_ids", [])
	return {
		"version": SAVE_VERSION,
		"dead": false,
		"memories": int(state.get("memories", 0)),
		"items": items,
		"combat_items": combat_items,
		"act": int(run_state.get("act", 1)),
		"seed": int(run_state.get("seed", 0)),
		"playtime_sec": float(body.get("playtime_sec", _playtime_sec)),
		"last_room": room,
		"timestamp_unix": int(Time.get_unix_time_from_system()),
	}


func _read_body(slot: int) -> Dictionary:
	var path := _body_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Dictionary:
		push_warning("AxelSaves: corrupt slot body %s" % path)
		return {}
	if not (parsed as Dictionary).has("game_state"):
		push_warning("AxelSaves: slot body missing game_state %s" % path)
		return {}
	return parsed


func _atomic_write(path: String, data: Dictionary) -> void:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("AxelSaves: could not write %s" % tmp)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp)
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)
	var err := DirAccess.rename_absolute(abs_tmp, abs_path)
	if err != OK:
		push_warning("AxelSaves: rename failed (%d) for %s" % [err, path])


func _purge_dead_slots() -> void:
	for i in SLOT_COUNT:
		if is_dead(i):
			_delete_slot_files(i)
	slots_changed.emit()


func _delete_slot_files(slot: int) -> bool:
	var paths: Array[String] = [
		_meta_path(slot),
		_body_path(slot),
		_meta_path(slot) + ".tmp",
		_body_path(slot) + ".tmp",
	]
	for path in paths:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			DirAccess.remove_absolute(abs_path)
	for path in [_meta_path(slot), _body_path(slot)]:
		if FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			return false
	return true


func _is_write_blocked(slot: int) -> bool:
	return bool(_write_blocked.get(slot, false))


func _can_write_slot(slot: int) -> bool:
	return is_active() and active_slot == slot and not _is_write_blocked(slot)


func _write_index(slot: int) -> void:
	_last_slot = slot
	_atomic_write("%s/index.json" % _dir(), {"last_slot": slot, "version": SAVE_VERSION})


func _read_index_last_slot() -> int:
	var path := "%s/index.json" % _dir()
	if not FileAccess.file_exists(path):
		return -1
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return int(parsed.get("last_slot", -1))
	return -1


func _change_scene(path: String) -> bool:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("AxelSaves: could not change scene to %s (%d)" % [path, err])
		return false
	return true


func _is_living(slot: int) -> bool:
	return _valid_slot(slot) and not is_empty(slot) and not is_dead(slot)


func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT


func _is_menu_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and _is_menu_path(scene.scene_file_path)


func _is_menu_path(path: String) -> bool:
	return path.begins_with(MENU_PREFIX)


func _stamp_play_scene_arrival(scene_path: String) -> void:
	if scene_path == NEW_GAME_SCENE:
		_flush_save(scene_path)
		return
	_flush_scene_override = scene_path
	if scene_path != CORRIDOR_SCENE:
		GameManager.set_corridor_spawn_line_seen(true)
		GameManager.set_corridor_locker_line_seen(true)
		GameManager.mark_room_visited(CORRIDOR_SCENE)
	GameManager.mark_room_visited(NEW_GAME_SCENE)
	GameManager.mark_room_visited(scene_path)
	_flush_save(scene_path)


func _cmdline_scene_path() -> String:
	var args := OS.get_cmdline_args()
	for i in args.size():
		var arg := String(args[i])
		if arg == _SCENE_ARG and i + 1 < args.size():
			return _normalize_scene_arg(String(args[i + 1]))
		if arg.begins_with(_SCENE_ARG + "="):
			return _normalize_scene_arg(arg.substr(_SCENE_ARG.length() + 1))
	return ""


func _normalize_scene_arg(arg: String) -> String:
	var text := arg.strip_edges()
	if text.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(text)
		if not ResourceUID.has_id(uid):
			return ""
		return ResourceUID.uid_to_path(text)
	return text


func _purge_directory(path: String) -> void:
	if path.is_empty() or path == DIR:
		return
	var abs_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs_path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != ".." and not dir.current_is_dir():
			names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	for entry_name in names:
		dir.remove(entry_name)
	DirAccess.remove_absolute(abs_path)


func _dir() -> String:
	return dir_override if not dir_override.is_empty() else DIR


func _meta_path(slot: int) -> String:
	return "%s/slot_%d.meta.json" % [_dir(), slot]


func _body_path(slot: int) -> String:
	return "%s/slot_%d.json" % [_dir(), slot]


func _abs_dir() -> String:
	return ProjectSettings.globalize_path(_dir())