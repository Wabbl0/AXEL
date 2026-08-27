extends Control
## Editable click polygon for the Execute skull. Drag Polygon2D vertices in the editor.

signal pressed

@onready var _poly: Polygon2D = $Polygon

var _pressing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _poly != null:
		_poly.color = Color(1.0, 1.0, 1.0, 0.0)


func _has_point(point: Vector2) -> bool:
	if _poly == null or _poly.polygon.is_empty():
		return false
	return Geometry2D.is_point_in_polygon(point, _poly.polygon)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressing = true
			accept_event()
		else:
			if _pressing:
				_pressing = false
				pressed.emit()
				accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_pressing = false
