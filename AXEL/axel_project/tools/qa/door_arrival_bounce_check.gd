extends SceneTree

const CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"
const BASEMENT := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const SIZES := [
	Vector2i(1920, 1280),
	Vector2i(2560, 1440),
	Vector2i(1920, 1080),
	Vector2i(3840, 2160),
	Vector2i(1280, 720),
	Vector2i(3440, 1440),
	Vector2i(1179, 2556),
]

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _main() -> void:
	for size in SIZES:
		root.size = size
		change_scene_to_file(CORRIDOR)
		await _frames(30)
		current_scene.call("_begin_basement_transition")
		await _frames(120)
		if _path() != BASEMENT:
			_failures.append("%s: 1.2 -> 1.4 ended in %s" % [size, _path()])
			continue
		current_scene.call("_begin_corridor_return")
		await _frames(120)
		if _path() != CORRIDOR:
			_failures.append("%s: 1.4 -> 1.2 ended in %s" % [size, _path()])
	root.size = Vector2i(1920, 1280)
	if _failures.is_empty():
		print("door_arrival_bounce_check: OK")
		quit(0)
		return
	for f in _failures:
		push_error("door_arrival_bounce_check: " + f)
	quit(1)
