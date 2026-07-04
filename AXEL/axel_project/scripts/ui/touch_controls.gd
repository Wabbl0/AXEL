extends CanvasLayer
## Autoloaded mobile touch layer: fixed bottom-center translucent ("liminal")
## virtual joystick for player movement.
##
## - Active only when a touch UI is wanted (touchscreen device, mobile/web-mobile
##   feature tags, or AXEL_FORCE_TOUCH=1 for desktop/Xvfb testing).
## - The joystick only renders while a Player (group "axel_player") is in the tree.
## - Touches that begin inside the joystick grab radius are captured (by touch
##   index) and consumed; all other touches pass through to dialogue advance,
##   interact taps, and UI hotspots.
## - Player.gd polls `get_move_vector()` and merges it with keyboard actions.

## Emitted when the joystick appears/disappears (player enters/leaves the tree),
## so bottom-anchored UI (dialogue bar) can re-layout around the reserved space.
signal stick_visibility_changed(stick_visible: bool)

const ENV_FORCE_TOUCH := "AXEL_FORCE_TOUCH"
const PLAYER_GROUP := "axel_player"

const LAYER_INDEX := 120
const DEAD_ZONE := 0.12
const GRAB_RADIUS_SCALE := 1.45
const BOTTOM_MARGIN_PX := 26.0
const IDLE_ALPHA := 0.28
const ACTIVE_ALPHA := 0.5

var _enabled := false
var _stick_root: Control
var _center := Vector2.ZERO
var _radius := 110.0
var _knob_radius := 44.0
var _touch_index := -1
var _vector := Vector2.ZERO


static func detect_touch_ui() -> bool:
	if OS.get_environment(ENV_FORCE_TOUCH) == "1":
		return true
	if OS.has_feature("mobile"):
		return true
	# Note: DisplayServer.is_touchscreen_available() is NOT usable here — the
	# project enables pointing/emulate_touch_from_mouse, which makes it return
	# true on every desktop. Feature tags identify real handheld targets.
	return OS.has_feature("web_android") or OS.has_feature("web_ios")


func _ready() -> void:
	layer = LAYER_INDEX
	_enabled = detect_touch_ui()
	_build_stick()
	set_process(_enabled)
	set_process_input(_enabled)
	if not _enabled:
		return
	get_tree().root.size_changed.connect(_refresh_geometry)
	_refresh_geometry()


func is_touch_ui_enabled() -> bool:
	return _enabled


## Analog movement vector (length <= 1). Zero when idle or touch UI disabled.
func get_move_vector() -> Vector2:
	if not _enabled:
		return Vector2.ZERO
	return _vector


## True when a screen-space point falls inside the joystick grab zone while the
## stick is shown. Other touch consumers (dialogue advance, interact taps) use
## this to leave joystick touches alone.
func is_point_in_stick_zone(pos: Vector2) -> bool:
	if not _enabled or _stick_root == null or not _stick_root.visible:
		return false
	return _is_inside_grab_zone(pos)


## Vertical canvas space reserved by the joystick at the bottom of the screen.
## Zero when the stick is hidden (non-exploration scenes) or touch UI is off.
func get_reserved_bottom_px() -> float:
	if not _enabled or _stick_root == null or not _stick_root.visible:
		return 0.0
	return _canvas_size().y - (_center.y - _radius * GRAB_RADIUS_SCALE)


func _build_stick() -> void:
	_stick_root = Control.new()
	_stick_root.name = "JoystickDraw"
	_stick_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stick_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_root.visible = false
	_stick_root.draw.connect(_draw_stick)
	add_child(_stick_root)


func _refresh_geometry() -> void:
	var view_size := _canvas_size()
	_radius = clampf(minf(view_size.x, view_size.y) * 0.17, 84.0, 150.0)
	_knob_radius = _radius * 0.42
	var bottom_inset := _safe_area_bottom_inset() + BOTTOM_MARGIN_PX
	_center = Vector2(view_size.x * 0.5, view_size.y - bottom_inset - _radius)
	_stick_root.queue_redraw()


func _canvas_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(720.0, 1560.0)
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(720.0, 1560.0)
	return size


## Home-indicator / notch inset converted from window pixels to canvas units.
func _safe_area_bottom_inset() -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.y <= 0.0:
		return 0.0
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var inset_px := maxf(window_size.y - (safe.position.y + safe.size.y), 0.0)
	if inset_px <= 0.0:
		return 0.0
	var canvas_size := _canvas_size()
	return inset_px * (canvas_size.y / window_size.y)


func _process(_delta: float) -> void:
	var want_visible := _has_player()
	if _stick_root.visible != want_visible:
		_stick_root.visible = want_visible
		if not want_visible:
			_release_stick()
		stick_visibility_changed.emit(want_visible)
	if want_visible and _touch_index != -1:
		_stick_root.queue_redraw()


func _has_player() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	return tree.get_first_node_in_group(PLAYER_GROUP) != null


func _input(event: InputEvent) -> void:
	if not _enabled or not _stick_root.visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index == -1 and _is_inside_grab_zone(touch.position):
				_touch_index = touch.index
				_update_vector(touch.position)
				_consume_event()
		elif touch.index == _touch_index:
			_release_stick()
			_consume_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_vector(drag.position)
			_consume_event()


func _consume_event() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _is_inside_grab_zone(pos: Vector2) -> bool:
	return pos.distance_to(_center) <= _radius * GRAB_RADIUS_SCALE


func _update_vector(pos: Vector2) -> void:
	var offset := (pos - _center) / _radius
	if offset.length() > 1.0:
		offset = offset.normalized()
	_vector = Vector2.ZERO if offset.length() < DEAD_ZONE else offset
	_stick_root.queue_redraw()


func _release_stick() -> void:
	_touch_index = -1
	_vector = Vector2.ZERO
	_stick_root.queue_redraw()


func _draw_stick() -> void:
	var active := _touch_index != -1
	var alpha := ACTIVE_ALPHA if active else IDLE_ALPHA
	_stick_root.draw_circle(_center, _radius, Color(1.0, 1.0, 1.0, alpha * 0.16))
	_stick_root.draw_arc(
		_center, _radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha * 0.65), 2.0, true
	)
	var knob_offset := _vector * (_radius - _knob_radius * 0.5)
	_stick_root.draw_circle(_center + knob_offset, _knob_radius, Color(1.0, 1.0, 1.0, alpha))
	_stick_root.draw_arc(
		_center + knob_offset, _knob_radius, 0.0, TAU, 32,
		Color(0.29, 0.0, 0.0, alpha), 1.5, true
	)
