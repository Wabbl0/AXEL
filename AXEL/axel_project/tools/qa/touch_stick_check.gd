extends SceneTree

const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const WINDOW := Vector2i(1920, 1280)
const CENTER := Vector2(960, 900)
const PROBE_SOURCE := "extends Node\nvar count := 0\nfunc _input(event: InputEvent) -> void:\n\tif event.is_action_pressed(\"interact\"):\n\t\tcount += 1\n"

var _failures: Array[String] = []
var _stick: Node
var _probe: Node


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	_stick = root.get_node_or_null("AxelTouchStick")
	if _stick == null:
		_fail("AxelTouchStick autoload missing")
		_finish()
		return
	_stick.call("set_touch_mode_override", true)
	var probe_script := GDScript.new()
	probe_script.source_code = PROBE_SOURCE
	probe_script.reload()
	_probe = Node.new()
	_probe.set_script(probe_script)
	root.add_child(_probe)
	var gm := root.get_node_or_null("GameManager")
	if gm != null:
		gm.basement_door_line_seen = true
	change_scene_to_file(ROOM)
	for _i in 24:
		await process_frame
	var scene := current_scene
	if scene == null:
		_fail("1.4 failed to load")
		_finish()
		return
	var dialogue := scene.get_node_or_null("TopDialogueOverlay")
	if dialogue != null and dialogue.has_method("interrupt_line"):
		dialogue.call("interrupt_line")
	for _i in 30:
		await process_frame
	var player := scene.get_node_or_null("PlayerLayer/Player")
	if player == null:
		_fail("1.4 has no PlayerLayer/Player")
		_finish()
		return
	await _check_drag()
	await _check_dead_zone()
	await _check_pause(player)
	await _check_pause_button(player)
	await _check_input_disabled(player)
	await _check_dialogue_tap(dialogue)
	await _check_prompt_tap(scene, player)
	_finish()


func _touch(pressed: bool, pos: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressed
	ev.position = pos
	Input.parse_input_event(ev)


func _drag(pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = pos
	ev.relative = rel
	Input.parse_input_event(ev)


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _all_moves_released() -> bool:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if Input.get_action_strength(action) > 0.0:
			return false
	return true


func _check_drag() -> void:
	_touch(true, CENTER)
	await _frames(2)
	_drag(CENTER + Vector2(200, 0), Vector2(200, 0))
	await _frames(3)
	var strength := Input.get_action_strength("move_right")
	if strength < 0.95:
		_fail("drag right should press move_right near 1, got %.2f" % strength)
	if Input.get_action_strength("move_left") > 0.0:
		_fail("drag right should not press move_left")
	_touch(false, CENTER + Vector2(200, 0))
	await _frames(3)
	if not _all_moves_released():
		_fail("finger up should release every move action")


func _check_dead_zone() -> void:
	_touch(true, CENTER)
	await _frames(2)
	_drag(CENTER + Vector2(5, 0), Vector2(5, 0))
	await _frames(3)
	if not _all_moves_released():
		_fail("a drag inside the dead zone should press nothing")
	_touch(false, CENTER + Vector2(5, 0))
	await _frames(2)


func _check_pause(player: Node) -> void:
	var pause := root.get_node_or_null("AxelPause")
	if pause == null:
		_fail("AxelPause missing")
		return
	_touch(true, CENTER)
	await _frames(2)
	_drag(CENTER + Vector2(0, -200), Vector2(0, -200))
	await _frames(3)
	if Input.get_action_strength("move_up") < 0.95:
		_fail("drag up should press move_up before pause")
	if not bool(pause.call("request_pause")):
		_fail("pause request was refused in 1.4")
	await _frames(4)
	if not _all_moves_released() or bool(_stick.call("is_finger_down")):
		_fail("pause mid-drag should release everything")
	pause.call("request_unpause")
	await _frames(4)
	_touch(false, CENTER + Vector2(0, -200))
	await _frames(2)
	if not bool(player.call("is_input_enabled")):
		player.call("set_input_enabled", true)


func _click(pressed: bool, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)


func _check_pause_button(player: Node) -> void:
	var pause := root.get_node_or_null("AxelPause")
	await _frames(3)
	if not bool(_stick.call("is_pause_button_visible")):
		_fail("touch pause button should show in 1.4")
		return
	var center: Vector2 = _stick.call("pause_button_center")
	if center.x < WINDOW.x * 0.5 or center.y > WINDOW.y * 0.5:
		_fail("touch pause button should sit top-right, got %s" % center)
	_touch(true, center)
	await _frames(2)
	if bool(_stick.call("is_finger_down")):
		_fail("a touch on the pause button should not start the stick")
	_touch(false, center)
	_click(true, center)
	await _frames(1)
	_click(false, center)
	await _frames(4)
	if not bool(pause.call("is_paused")):
		_fail("a tap on the pause button should pause")
	if bool(_stick.call("is_pause_button_visible")):
		_fail("touch pause button should hide while paused")
	pause.call("request_unpause")
	await _frames(4)
	if not bool(player.call("is_input_enabled")):
		player.call("set_input_enabled", true)
	_stick.call("set_touch_mode_override", false)
	await _frames(2)
	if bool(_stick.call("is_pause_button_visible")):
		_fail("touch pause button should hide outside touch mode")
	_stick.call("set_touch_mode_override", true)
	await _frames(2)


func _check_input_disabled(player: Node) -> void:
	player.call("set_input_enabled", false)
	await _frames(2)
	_touch(true, CENTER)
	await _frames(2)
	_drag(CENTER + Vector2(200, 0), Vector2(200, 0))
	await _frames(3)
	if not _all_moves_released():
		_fail("stick should do nothing while player input is disabled")
	_touch(false, CENTER + Vector2(200, 0))
	await _frames(2)
	player.call("set_input_enabled", true)
	await _frames(2)


func _check_prompt_tap(scene: Node, player: Node) -> void:
	var prompt := scene.get_node_or_null("InteractPromptOverlay")
	var door := scene.get_node_or_null("WalkableWorld/EnvironmentColliders/DoorInteractArea") as Area2D
	if prompt == null or door == null:
		_fail("1.4 missing prompt or door")
		return
	var bar := prompt.get_node_or_null("ViewportRoot/ChipRoot/BarPanel") as Control
	if bar != null and bar.visible:
		_fail("[E] box should be hidden in touch mode")
	if prompt.get_node_or_null("ViewportRoot/ChipRoot/TapPulse") == null:
		_fail("TapPulse missing in touch mode")
	(player as Node2D).global_position = door.global_position
	for _i in 30:
		await physics_frame
	if scene.has_method("refresh_active_zone"):
		scene.call("refresh_active_zone")
	await _frames(30)
	if not bool(prompt.call("is_prompt_visible")):
		_fail("prompt did not show at the door")
		return
	var center: Vector2 = prompt.call("tap_center")
	var before := int(_probe.get("count"))
	_touch(true, center + Vector2(500, 0))
	_touch(false, center + Vector2(500, 0))
	await _frames(3)
	if int(_probe.get("count")) != before:
		_fail("a far tap should not fire interact")
	_touch(true, center)
	_touch(false, center)
	await _frames(3)
	var fired := int(_probe.get("count")) - before
	if fired != 1:
		_fail("a tap on the pulse should fire interact once, got %d" % fired)
	await _frames(10)


func _check_dialogue_tap(dialogue: Node) -> void:
	if dialogue == null:
		_fail("1.4 missing TopDialogueOverlay")
		return
	dialogue.call("show_line", "One tap should move this line forward only one step at a time.", 3.0)
	var start := Time.get_ticks_msec()
	while int(dialogue.get("_line_phase")) == 0 and Time.get_ticks_msec() - start < 3000:
		await process_frame
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = CENTER
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = CENTER
	var count := 0
	if bool(dialogue.call("wants_advance_event", touch)):
		count += 1
	if bool(dialogue.call("wants_advance_event", mouse)):
		count += 1
	if count != 1:
		_fail("one emulated tap should advance dialogue once, got %d" % count)
	if dialogue.has_method("interrupt_line"):
		dialogue.call("interrupt_line")
	await _frames(30)


func _finish() -> void:
	if _stick != null:
		_stick.call("set_touch_mode_override", false)
	if _failures.is_empty():
		print("Touch stick check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("touch_stick_check: %s" % msg)
	quit(1)
