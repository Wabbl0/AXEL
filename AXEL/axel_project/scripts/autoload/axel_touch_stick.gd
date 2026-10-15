extends Node

const LAYER := 109
const RING_RADIUS := 90.0
const RING_WIDTH := 3.0
const KNOB_RADIUS := 34.0
const DEAD_ZONE := 0.2
const TAP_MAX_SEC := 0.25
const FADE_SEC := 0.1
const RING_COLOR := Color(0.62, 0.56, 0.52, 0.25)
const KNOB_COLOR := Color(0.9, 0.0, 0.0, 0.35)
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MENU_PREFIX := "res://scenes/Main_Menu/"
const TAP_GROUP := &"touch_tap_target"
const MOUSE_FINGER := -2
const NO_FINGER := -1

var _override := -1
var _finger := NO_FINGER
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _down_ms := 0
var _left_dead_zone := false
var _held := {}
var _alpha := 0.0
var _layer: CanvasLayer
var _canvas: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.name = "TouchStickLayer"
	_layer.layer = LAYER
	add_child(_layer)
	_canvas = Control.new()
	_canvas.name = "TouchStick"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.modulate.a = 0.0
	_canvas.visible = false
	_canvas.draw.connect(_on_canvas_draw)
	_layer.add_child(_canvas)
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_signal("pause_state_changed"):
		pause.connect("pause_state_changed", _on_pause_state_changed)
	get_tree().scene_changed.connect(release_all)


func is_touch_mode() -> bool:
	if _override >= 0:
		return _override == 1
	return PortraitUi.is_touch_device() or OS.get_environment("AXEL_TOUCH_STICK") == "1"


func set_touch_mode_override(on: bool) -> void:
	_override = 1 if on else 0
	if not on:
		release_all()


func is_finger_down() -> bool:
	return _finger != NO_FINGER


func stick_radius() -> float:
	return RING_RADIUS * UiViewportScale.factor(self)


func release_all() -> void:
	for action in _held.keys():
		Input.action_release(action)
	_held.clear()
	_finger = NO_FINGER
	_left_dead_zone = false


func _on_pause_state_changed(_paused: bool) -> void:
	release_all()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin(touch.index, touch.position)
		elif touch.index == _finger:
			_end(touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _finger:
			_drag(drag.position)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.device == InputEvent.DEVICE_ID_EMULATION or button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_begin(MOUSE_FINGER, button.position)
		elif _finger == MOUSE_FINGER:
			_end(button.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.device != InputEvent.DEVICE_ID_EMULATION and _finger == MOUSE_FINGER:
			_drag(motion.position)


func _begin(index: int, pos: Vector2) -> void:
	if _finger != NO_FINGER:
		return
	_finger = index
	_center = pos
	_knob = pos
	_down_ms = Time.get_ticks_msec()
	_left_dead_zone = false


func _drag(pos: Vector2) -> void:
	var radius := stick_radius()
	var offset := (pos - _center).limit_length(radius)
	_knob = _center + offset
	if offset.length() >= radius * DEAD_ZONE:
		_left_dead_zone = true


func _end(pos: Vector2) -> void:
	_drag(pos)
	var quick := Time.get_ticks_msec() - _down_ms <= int(TAP_MAX_SEC * 1000.0)
	var was_tap := quick and not _left_dead_zone
	release_all()
	if was_tap:
		_try_tap(pos)


func _process(delta: float) -> void:
	if _is_active():
		_apply_stick()
	elif _finger != NO_FINGER or not _held.is_empty():
		release_all()
	_update_fade(delta)


func _apply_stick() -> void:
	if _finger == NO_FINGER:
		_release_moves()
		return
	var v := ((_knob - _center) / maxf(stick_radius(), 0.001)).limit_length(1.0)
	if v.length() < DEAD_ZONE:
		_release_moves()
		return
	_set_action(&"move_right", maxf(v.x, 0.0))
	_set_action(&"move_left", maxf(-v.x, 0.0))
	_set_action(&"move_down", maxf(v.y, 0.0))
	_set_action(&"move_up", maxf(-v.y, 0.0))


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
		_held[action] = true
	elif _held.has(action):
		Input.action_release(action)
		_held.erase(action)


func _release_moves() -> void:
	for action in MOVE_ACTIONS:
		if _held.has(action):
			Input.action_release(action)
			_held.erase(action)


func _update_fade(delta: float) -> void:
	var target := 1.0 if _finger != NO_FINGER else 0.0
	_alpha = move_toward(_alpha, target, delta / FADE_SEC)
	_canvas.modulate.a = _alpha
	_canvas.visible = _alpha > 0.0
	if _canvas.visible:
		_canvas.queue_redraw()


func _on_canvas_draw() -> void:
	var f := UiViewportScale.factor(self)
	_canvas.draw_arc(_center, RING_RADIUS * f, 0.0, TAU, 64, RING_COLOR, RING_WIDTH * f, true)
	_canvas.draw_circle(_knob, KNOB_RADIUS * f, KNOB_COLOR, true, -1.0, true)


func _try_tap(pos: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var prompt := scene.get_node_or_null("InteractPromptOverlay")
	if (
		prompt != null
		and prompt.has_method("tap_hit")
		and bool(prompt.call("is_prompt_visible"))
		and bool(prompt.call("tap_hit", pos))
	):
		_fire_interact()
		return
	for node in get_tree().get_nodes_in_group(TAP_GROUP):
		if node.has_method("touch_tap_hit") and bool(node.call("touch_tap_hit", pos)):
			_fire_interact()
			return


func _fire_interact() -> void:
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)


func _is_active() -> bool:
	if not is_touch_mode():
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.begins_with(MENU_PREFIX):
		return false
	var player := scene.get_node_or_null("PlayerLayer/Player")
	if player == null:
		return false
	if player.has_method("is_input_enabled") and not bool(player.call("is_input_enabled")):
		return false
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and (bool(pause.call("is_paused")) or bool(pause.call("is_focus_frozen"))):
		return false
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("is_in_encounter") and bool(run.call("is_in_encounter")):
		return false
	return not InteractZoneGate.dialogue_busy(scene.get_node_or_null("TopDialogueOverlay"))
