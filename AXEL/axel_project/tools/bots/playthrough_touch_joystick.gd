extends SceneTree
## Headless playthrough bot: mobile touch controls on Arc 1 / 1.1 School Exterior.
##
## Validates the touch input path end-to-end with synthetic screen touches:
##   1. Virtual joystick appears when a Player is in the tree (AXEL_FORCE_TOUCH=1).
##   2. Dragging the stick right moves the player right (analog vector -> velocity).
##   3. Steering the stick walks the player into the door interact area.
##   4. Tapping the door area triggers the 1.1 -> 1.2 scene transition.
##
## Run from repo root:
##   godot --headless --path AXEL/axel_project -s res://tools/bots/playthrough_touch_joystick.gd

const _SCENE_EXTERIOR := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const _SCENE_CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"

const _SCENE_READY_GRACE_FRAMES := 6
const _STICK_APPEAR_TIMEOUT_FRAMES := 120
const _DRAG_MOVE_FRAMES := 60
const _MIN_MOVE_PX := 40.0
const _WALK_TO_DOOR_TIMEOUT_FRAMES := 900
const _TRANSITION_TIMEOUT_FRAMES := 240
const _TOUCH_INDEX := 0


func _init() -> void:
	OS.set_environment("AXEL_FORCE_TOUCH", "1")
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	call_deferred("_main")


func _main() -> void:
	var ok := await _run()
	if ok:
		print("Touch joystick playthrough OK.")
		quit(0)
	else:
		push_error("Touch joystick playthrough FAILED.")
		quit(1)


func _run() -> bool:
	var change_err := change_scene_to_file(_SCENE_EXTERIOR)
	if change_err != OK:
		push_error("Touch bot FAIL: change_scene_to_file -> %d" % change_err)
		return false
	for _i in _SCENE_READY_GRACE_FRAMES:
		await process_frame

	var touch_controls := root.get_node_or_null("/root/TouchControls")
	if touch_controls == null:
		push_error("Touch bot FAIL: TouchControls autoload missing.")
		return false
	if not touch_controls.is_touch_ui_enabled():
		push_error("Touch bot FAIL: touch UI not enabled despite AXEL_FORCE_TOUCH=1.")
		return false

	var frames := 0
	while not touch_controls.is_stick_shown() and frames < _STICK_APPEAR_TIMEOUT_FRAMES:
		await process_frame
		frames += 1
	if not touch_controls.is_stick_shown():
		push_error("Touch bot FAIL: joystick never became visible with player in tree.")
		return false
	print("[touch_bot.OK] joystick visible (after %d frames)" % frames)

	var player := _get_player()
	if player == null:
		push_error("Touch bot FAIL: player node missing.")
		return false

	# 2) Drag the stick right; player must move right.
	var start_x := player.global_position.x
	var center: Vector2 = touch_controls.get_stick_center()
	var radius: float = touch_controls.get_stick_radius()
	_send_touch(center, true)
	_send_drag(center + Vector2(radius * 0.95, 0.0))
	for _i in _DRAG_MOVE_FRAMES:
		await physics_frame
	var moved: float = player.global_position.x - start_x
	if moved < _MIN_MOVE_PX:
		_send_touch(center, false)
		push_error("Touch bot FAIL: joystick drag moved player %.1fpx (< %.1f)." % [moved, _MIN_MOVE_PX])
		return false
	print("[touch_bot.OK] joystick drag moved player %.1fpx right" % moved)

	# 3) Keep steering toward the door interact area until overlapping.
	var door_area := _get_door_area()
	if door_area == null:
		_send_touch(center, false)
		push_error("Touch bot FAIL: door interact area missing.")
		return false
	var target := _polygon_centroid(door_area)
	frames = 0
	while frames < _WALK_TO_DOOR_TIMEOUT_FRAMES and not _player_in_area(player, door_area):
		var to_target := (target - player.global_position).normalized()
		_send_drag(center + to_target * radius * 0.95)
		await physics_frame
		frames += 1
	_send_drag(center)
	_send_touch(center, false)
	if not _player_in_area(player, door_area):
		push_error("Touch bot FAIL: player never reached door area (frames=%d pos=%s)." % [
			frames, str(player.global_position)
		])
		return false
	print("[touch_bot.OK] joystick steered player into door area (%d frames)" % frames)
	for _i in 4:
		await process_frame

	# 4) Tap the door area on screen; expect corridor transition.
	var canvas_transform := root.get_viewport().get_canvas_transform()
	var tap_pos := canvas_transform * target
	_send_touch(tap_pos, true)
	await process_frame
	_send_touch(tap_pos, false)
	frames = 0
	while frames < _TRANSITION_TIMEOUT_FRAMES:
		if current_scene != null and current_scene.scene_file_path == _SCENE_CORRIDOR:
			print("[touch_bot.OK] tap on door transitioned to corridor (%d frames)" % frames)
			return true
		await process_frame
		frames += 1
	push_error("Touch bot FAIL: no transition to corridor after door tap (tap_pos=%s)." % str(tap_pos))
	return false


## Positions are canvas coordinates; push_input(local=true) skips the window
## stretch transform that Input.parse_input_event would apply to raw positions.
func _send_touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = _TOUCH_INDEX
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func _send_drag(pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = _TOUCH_INDEX
	ev.position = pos
	root.push_input(ev, true)


func _get_player() -> CharacterBody2D:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D


func _get_door_area() -> Area2D:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("EnvironmentColliders/Doors/DoorInteractArea") as Area2D


func _player_in_area(player: CharacterBody2D, area: Area2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body == player:
			return true
	return false


func _polygon_centroid(area: Area2D) -> Vector2:
	var poly := area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null or poly.polygon.is_empty():
		return area.global_position
	var sum := Vector2.ZERO
	for point in poly.polygon:
		sum += poly.to_global(point)
	return sum / float(poly.polygon.size())
