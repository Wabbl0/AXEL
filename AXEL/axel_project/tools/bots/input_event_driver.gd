extends RefCounted
class_name InputEventDriver


var _tree: SceneTree
var _held_keys: Dictionary = {}
var _event_log: Array[Dictionary] = []
var _physics_frame: int = 0
var _verbose: bool = false


func _init(tree: SceneTree, verbose: bool = false) -> void:
	_tree = tree
	_verbose = verbose


func physics_frame() -> int:
	return _physics_frame


func held_keys() -> Array:
	return _held_keys.keys()


func event_log() -> Array[Dictionary]:
	return _event_log


func press(keycode: int) -> void:
	if _held_keys.has(keycode):
		return
	_held_keys[keycode] = true
	_emit(keycode, true)


func release(keycode: int) -> void:
	if not _held_keys.has(keycode):
		return
	_held_keys.erase(keycode)
	_emit(keycode, false)


func tap(keycode: int, frames: int = 1) -> void:
	press(keycode)
	await await_physics_frames(maxi(frames, 1))
	release(keycode)


func hold_for_frames(keycode: int, frames: int) -> void:
	press(keycode)
	await await_physics_frames(maxi(frames, 1))
	release(keycode)


func release_all() -> void:
	for keycode in _held_keys.keys():
		_emit(keycode, false)
	_held_keys.clear()


func await_physics_frames(frames: int) -> void:
	for _i in maxi(frames, 0):
		await _tree.physics_frame
		_physics_frame += 1


func await_process_frames(frames: int) -> void:
	for _i in maxi(frames, 0):
		await _tree.process_frame


func _emit(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode as Key
	event.physical_keycode = keycode as Key
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)
	_event_log.append({
		"op": "press" if pressed else "release",
		"keycode": keycode,
		"frame": _physics_frame,
		"t_ms": Time.get_ticks_msec(),
	})
	if _verbose:
		var op := "PRESS" if pressed else "RELEASE"
		print("[bot.input] frame=%d %s keycode=%d" % [_physics_frame, op, keycode])
