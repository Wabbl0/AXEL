extends RefCounted
class_name InputEventDriver

## Test-only synthetic input layer for AXEL playthrough bots.
##
## Emits real `InputEventKey` events through `Input.parse_input_event()` so they
## traverse the engine input pipeline. This means:
##   - `_input` / `_unhandled_input` callbacks receive them (matches scene scripts
##     like `1.1_SchoolExterior.gd::_unhandled_input`).
##   - `Input.is_key_pressed(KEY_X)` and `Input.is_action_pressed(...)` reflect
##     pressed/released state (matches polling in `scripts/Player.gd`).
##
## Frame advancement is done by the caller (typically a scenario runner) by
## awaiting `tree.physics_frame` so movement integrates over deterministic ticks.
##
## Held keys are tracked so a runner can release everything between scenarios
## or on early failure, leaving no sticky input state behind.

var _tree: SceneTree
var _held_keys: Dictionary = {}
var _event_log: Array[Dictionary] = []
var _physics_frame: int = 0
var _verbose: bool = false


func _init(tree: SceneTree, verbose: bool = false) -> void:
	_tree = tree
	_verbose = verbose


## Number of physics frames advanced via `await_physics_frames`.
func physics_frame() -> int:
	return _physics_frame


## Currently held keycodes (keys that have been pressed but not released).
func held_keys() -> Array:
	return _held_keys.keys()


## Event audit trail (op, keycode, frame, timestamp_msec).
func event_log() -> Array[Dictionary]:
	return _event_log


## Press a key without releasing it. Subsequent physics frames will see it as held.
func press(keycode: int) -> void:
	if _held_keys.has(keycode):
		return
	_held_keys[keycode] = true
	_emit(keycode, true)


## Release a previously-pressed key. No-op if not held.
func release(keycode: int) -> void:
	if not _held_keys.has(keycode):
		return
	_held_keys.erase(keycode)
	_emit(keycode, false)


## Press, advance N physics frames, release. A "tap" with explicit duration.
## `frames` defaults to 1 so a synthetic tap touches at least one physics tick.
func tap(keycode: int, frames: int = 1) -> void:
	press(keycode)
	await await_physics_frames(maxi(frames, 1))
	release(keycode)


## Hold a key for N physics frames, then release. Use for movement bursts where
## the held duration drives `_physics_process` integration distance.
func hold_for_frames(keycode: int, frames: int) -> void:
	press(keycode)
	await await_physics_frames(maxi(frames, 1))
	release(keycode)


## Release every currently-held key. Safe cleanup hook for end-of-scenario.
func release_all() -> void:
	for keycode in _held_keys.keys():
		_emit(keycode, false)
	_held_keys.clear()


## Await N physics frames (deterministic: physics tick = 1/60 by default).
func await_physics_frames(frames: int) -> void:
	for _i in maxi(frames, 0):
		await _tree.physics_frame
		_physics_frame += 1


## Await N rendered process frames (use sparingly; non-deterministic timing).
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
