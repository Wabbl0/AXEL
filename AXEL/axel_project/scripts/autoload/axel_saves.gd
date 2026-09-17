extends Node

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const DIR := "user://saves"
const NEW_GAME_SCENE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const MENU_PREFIX := "res://scenes/Main_Menu/"
const MAP_MEMORY_KEY := "scene_3"

signal slots_changed
signal active_slot_changed(slot: int)

var active_slot: int = -1
var dir_override := ""
var _playtime_sec: float = 0.0
var _save_queued := false
var _pending_tex := Vector2.ZERO
var _pending_tex_valid := false
var _skip_intro_once := false
var _last_slot: int = -1


func _enter_tree() -> void:
	DirAccess.make_dir_recursive_absolute(_abs_dir())
	_last_slot = _read_index_last_slot()


func _ready() -> void:
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)


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


func new_game(slot: int) -> bool:
	if not _valid_slot(slot):
		return false
	_delete_slot_files(slot)
	GameManager.reset_state()
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("reset_run"):
		run.call("reset_run")
	active_slot = slot
	_playtime_sec = 0.0
	_pending_tex_valid = false
	_skip_intro_once = false
	_write_index(slot)
	_flush_save(NEW_GAME_SCENE)
	active_slot_changed.emit(slot)
	slots_changed.emit()
	return true


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
	if not is_active():
		return
	_queue_save()


func save_active_now() -> void:
	if not is_active():
		return
	var scene := get_tree().current_scene
	var path := ""
	if scene != null:
		path = scene.scene_file_path
	_flush_save(path)


func delete_slot(slot: int) -> bool:
	if not _valid_slot(slot) or is_empty(slot):
		return false
	_delete_slot_files(slot)
	if active_slot == slot:
		active_slot = -1
		active_slot_changed.emit(-1)
	slots_changed.emit()
	return true


func write_tombstone(slot: int) -> void:
	if not _valid_slot(slot):
		return
	var header := read_header(slot)
	if header.is_empty():
		header = _header_from_live(get_tree().current_scene.scene_file_path if get_tree().current_scene else "")
	header["dead"] = true
	header["timestamp_unix"] = int(Time.get_unix_time_from_system())
	_atomic_write(_meta_path(slot), header)
	var body_path := _body_path(slot)
	if FileAccess.file_exists(body_path):
		DirAccess.remove_absolute(body_path)
	if active_slot == slot:
		active_slot = -1
		active_slot_changed.emit(-1)
	slots_changed.emit()


func deactivate() -> void:
	if is_active():
		save_active_now()
	active_slot = -1
	_pending_tex_valid = false
	active_slot_changed.emit(-1)


func _on_scene_changed() -> void:
	if not is_active():
		return
	var scene := get_tree().current_scene
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
		PlayerSpawnSync.apply_tex(env, player, _pending_tex)
	_pending_tex_valid = false


func _queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	_flush_save_deferred.call_deferred()


func _flush_save_deferred() -> void:
	_save_queued = false
	if not is_active():
		return
	var scene := get_tree().current_scene
	var path := ""
	if scene != null:
		path = scene.scene_file_path
	_flush_save(path)


func _flush_save(scene_path: String) -> void:
	if not is_active():
		return
	if _is_menu_path(scene_path):
		return
	var body := GameManager.export_save_body()
	body["playtime_sec"] = _playtime_sec
	if not scene_path.is_empty():
		body["current_scene"] = scene_path
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path == scene_path:
		var env := scene.get_node_or_null("EnvironmentColliders") as Node2D
		var player := scene.find_child("Player", true, false) as Node2D
		if env != null and player != null:
			var tex := PlayerSpawnSync.capture_tex(env, player)
			body["player_tex_x"] = tex.x
			body["player_tex_y"] = tex.y
	var header := _header_from_body(body, scene_path)
	_atomic_write(_meta_path(active_slot), header)
	_atomic_write(_body_path(active_slot), body)
	_write_index(active_slot)
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


func _delete_slot_files(slot: int) -> void:
	for path in [_meta_path(slot), _body_path(slot)]:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			DirAccess.remove_absolute(abs_path)


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


func _dir() -> String:
	return dir_override if not dir_override.is_empty() else DIR


func _meta_path(slot: int) -> String:
	return "%s/slot_%d.meta.json" % [_dir(), slot]


func _body_path(slot: int) -> String:
	return "%s/slot_%d.json" % [_dir(), slot]


func _abs_dir() -> String:
	return ProjectSettings.globalize_path(_dir())
