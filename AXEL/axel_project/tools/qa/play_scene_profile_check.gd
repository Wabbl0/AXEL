extends SceneTree

const _REAL_PROFILE := "user://axel_profile_qa_real_tmp.cfg"
const _PLAY_PROFILE := "user://axel_profile_play_scene.cfg"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame

	var profile := root.get_node_or_null("AxelProfile")
	if profile == null:
		push_error("play_scene_profile_check: AxelProfile autoload missing")
		quit(1)
		return

	_remove(_REAL_PROFILE)
	_remove(_PLAY_PROFILE)
	profile.set("_path", _REAL_PROFILE)
	profile.call("reset_profile")
	profile.call("unlock_guide")
	profile.call("mark_tutorial_seen", "move_walk")
	var before := _read(_REAL_PROFILE)

	profile.call("begin_play_scene_profile")
	if not bool(profile.call("is_play_scene_profile")):
		_fail("play scene profile not active")
	if bool(profile.call("is_guide_unlocked")):
		_fail("guide still unlocked in play scene profile")
	if bool(profile.call("has_seen_tutorial", "move_walk")):
		_fail("tutorial still seen in play scene profile")

	profile.call("unlock_guide")
	profile.call("mark_tutorial_seen", "fight_spin")
	profile.call("mark_item_found", "C1")
	if not FileAccess.file_exists(_PLAY_PROFILE):
		_fail("play scene profile file was not written")
	if _read(_REAL_PROFILE) != before:
		_fail("real profile file changed during play scene")

	profile.call("end_play_scene_profile")
	if FileAccess.file_exists(_PLAY_PROFILE):
		_fail("play scene profile file not deleted")
	if not bool(profile.call("has_seen_tutorial", "move_walk")):
		_fail("real profile not restored")
	if bool(profile.call("has_seen_tutorial", "fight_spin")):
		_fail("play scene tutorial leaked into real profile")

	profile.call("debug_use_memory_only")
	_remove(_REAL_PROFILE)
	_remove(_PLAY_PROFILE)

	if _failures.is_empty():
		print("Play scene profile check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("play_scene_profile_check: %s" % f)
		quit(1)


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _remove(path: String) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)
