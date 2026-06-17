@tool
class_name UiPolygonHotspot
extends Control

signal activated

@export var background_path: NodePath
@export var polygon_node_path: NodePath = ^"PolygonAnchor/CollisionPolygon2D"
@export var hover_tint: Color = Color(1.0, 0.0, 0.0, 0.07)
@export var use_pointing_hand_cursor: bool = true

@export_group("Editor Preview")
@export var show_editor_preview: bool = false
@export var editor_fill_color: Color = Color(0.2, 0.9, 0.35, 0.12)
@export var editor_line_color: Color = Color(0.2, 0.9, 0.35, 0.9)

var _enabled := true
var _hovered := false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_enabled(_enabled)
	_sync_polygon_anchor()
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	_sync_polygon_anchor()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_polygon_anchor()
		queue_redraw()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	mouse_filter = MOUSE_FILTER_STOP if _enabled else MOUSE_FILTER_IGNORE
	if not _enabled:
		_set_hovered(false)


func _get_background() -> TextureRect:
	return get_node_or_null(background_path) as TextureRect


func _get_polygon_node() -> CollisionPolygon2D:
	return get_node_or_null(polygon_node_path) as CollisionPolygon2D


func _get_polygon_anchor() -> Node2D:
	var polygon_node := _get_polygon_node()
	if polygon_node == null:
		return null
	return polygon_node.get_parent() as Node2D


func _get_background_draw_rect(bg: TextureRect) -> Rect2:
	var tex := bg.texture
	if tex == null:
		return Rect2(Vector2.ZERO, bg.size)
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, bg.size)
	var control_size := bg.size
	var cover_scale := maxf(control_size.x / tex_size.x, control_size.y / tex_size.y)
	var drawn_size := tex_size * cover_scale
	var offset := (control_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)


func _sync_polygon_anchor() -> void:
	var bg := _get_background()
	var anchor := _get_polygon_anchor()
	if bg == null or anchor == null or bg.texture == null:
		return
	var bg_draw_rect := _get_background_draw_rect(bg)
	var tex_size := bg.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	anchor.position = bg_draw_rect.position
	anchor.scale = bg_draw_rect.size / tex_size


func _get_screen_polygon() -> PackedVector2Array:
	var polygon_node := _get_polygon_node()
	if polygon_node == null or polygon_node.polygon.size() < 3:
		return PackedVector2Array()
	var to_control_local := get_global_transform_with_canvas().affine_inverse()
	var local_points := PackedVector2Array()
	local_points.resize(polygon_node.polygon.size())
	for i in polygon_node.polygon.size():
		local_points[i] = to_control_local * polygon_node.to_global(polygon_node.polygon[i])
	return local_points


func _has_point(point: Vector2) -> bool:
	if not _enabled:
		return false
	var local_points := _get_screen_polygon()
	if local_points.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, local_points)


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			activated.emit()
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			activated.emit()
			accept_event()


func _draw() -> void:
	var local_points := _get_screen_polygon()
	if local_points.size() < 3:
		return
	if Engine.is_editor_hint() and show_editor_preview:
		draw_colored_polygon(local_points, editor_fill_color)
		var closed := local_points.duplicate()
		closed.append(local_points[0])
		draw_polyline(closed, editor_line_color, false, 2.0)
	elif _hovered and _enabled:
		draw_colored_polygon(local_points, hover_tint)


func _on_mouse_entered() -> void:
	_set_hovered(true)


func _on_mouse_exited() -> void:
	_set_hovered(false)


func _set_hovered(hovering: bool) -> void:
	if _hovered == hovering:
		return
	_hovered = hovering
	queue_redraw()
	if use_pointing_hand_cursor and _enabled:
		if hovering:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
