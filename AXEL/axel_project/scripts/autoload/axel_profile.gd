extends Node

signal profile_changed()

const PROFILE_PATH := "user://axel_profile.cfg"
const PATH_ENV := "AXEL_PROFILE_PATH"
const SECTION := "profile"
const PLAY_SCENE_PATH := "user://axel_profile_play_scene.cfg"

var _config := ConfigFile.new()
var _path := ""
var _play_scene := false
var _real_path := ""
var _session := ConfigFile.new()


func _enter_tree() -> void:
	_delete_play_scene_file()
	_path = _resolve_path()
	_load()


func _exit_tree() -> void:
	if _play_scene:
		_delete_play_scene_file()


func begin_play_scene_profile() -> void:
	_delete_play_scene_file()
	if not _play_scene:
		_real_path = _path
	_path = PLAY_SCENE_PATH
	_config = ConfigFile.new()
	_play_scene = true
	profile_changed.emit()


func is_play_scene_profile() -> bool:
	return _play_scene


func end_play_scene_profile() -> void:
	if not _play_scene:
		return
	_play_scene = false
	_delete_play_scene_file()
	_path = _real_path
	_load()
	profile_changed.emit()


func is_guide_unlocked() -> bool:
	return bool(_tutorial_config().get_value(SECTION, "guide_unlocked", false))


func unlock_guide() -> void:
	if _fresh_tutorials():
		_session.set_value(SECTION, "guide_unlocked", true)
		profile_changed.emit()
		return
	_set_flag("guide_unlocked")


func has_seen_free_spins() -> bool:
	return bool(_tutorial_config().get_value(SECTION, "free_spins_seen", false))


func mark_free_spins_seen() -> void:
	if _fresh_tutorials():
		_session.set_value(SECTION, "free_spins_seen", true)
		return
	_set_flag("free_spins_seen")


func is_ticket_machine_unlocked() -> bool:
	return bool(_config.get_value(SECTION, "ticket_machine_unlocked", false))


func unlock_ticket_machine() -> void:
	_set_flag("ticket_machine_unlocked")


func items_found() -> PackedStringArray:
	return _list("items_found")


func has_found_item(item_id: String) -> bool:
	return _list("items_found").has(item_id)


func mark_item_found(item_id: String) -> void:
	_add_to_list("items_found", item_id)


func has_seen_tutorial(id: String) -> bool:
	if _fresh_tutorials():
		return false
	return _list("tutorials_seen").has(id)


func mark_tutorial_seen(id: String) -> void:
	if _fresh_tutorials():
		return
	_add_to_list("tutorials_seen", id)


func merge_from_run(state: Object) -> void:
	if state == null:
		return
	var changed := false
	var found := _list("items_found")
	for item_id in PackedStringArray(state.get("owned_item_ids")):
		if not item_id.is_empty() and not found.has(item_id):
			found.append(item_id)
			changed = true
	if _fresh_tutorials():
		if bool(state.get("tutorial_fight_done")):
			_session.set_value(SECTION, "guide_unlocked", true)
		if changed:
			_config.set_value(SECTION, "items_found", found)
			_save()
		return
	var seen := _list("tutorials_seen")
	for id in PackedStringArray(state.get("tutorial_seen")):
		if not id.is_empty() and not seen.has(id):
			seen.append(id)
			changed = true
	if bool(state.get("tutorial_fight_done")) and not is_guide_unlocked():
		_config.set_value(SECTION, "guide_unlocked", true)
		changed = true
	if changed:
		_config.set_value(SECTION, "items_found", found)
		_config.set_value(SECTION, "tutorials_seen", seen)
		_save()


func begin_new_run() -> void:
	_session = ConfigFile.new()


func reset_profile() -> void:
	_config = ConfigFile.new()
	_session = ConfigFile.new()
	_save()


func debug_use_memory_only() -> void:
	_path = ""
	_config = ConfigFile.new()


func _fresh_tutorials() -> bool:
	return OS.has_feature("editor_runtime") and DisplayServer.get_name() != "headless"


func _tutorial_config() -> ConfigFile:
	return _session if _fresh_tutorials() else _config


func _resolve_path() -> String:
	var override := OS.get_environment(PATH_ENV)
	if not override.is_empty():
		return override
	if DisplayServer.get_name() == "headless":
		return ""
	return PROFILE_PATH


func _load() -> void:
	_config = ConfigFile.new()
	if _path.is_empty():
		return
	var err := _config.load(_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("AxelProfile: could not read %s (err %d); starting fresh." % [_path, err])
		_config = ConfigFile.new()


func _save() -> void:
	profile_changed.emit()
	if _path.is_empty():
		return
	var err := _config.save(_path)
	if err != OK:
		push_warning("AxelProfile: could not write %s (err %d)." % [_path, err])


func _delete_play_scene_file() -> void:
	var abs_path := ProjectSettings.globalize_path(PLAY_SCENE_PATH)
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)


func _set_flag(key: String) -> void:
	if bool(_config.get_value(SECTION, key, false)):
		return
	_config.set_value(SECTION, key, true)
	_save()


func _list(key: String) -> PackedStringArray:
	return PackedStringArray(_config.get_value(SECTION, key, PackedStringArray()))


func _add_to_list(key: String, value: String) -> void:
	if value.is_empty():
		return
	var values := _list(key)
	if values.has(value):
		return
	values.append(value)
	_config.set_value(SECTION, key, values)
	_save()
