extends Control
## Editable click polygon for the Execute skull. Drag Polygon2D vertices in the editor.

signal pressed

@onready var _poly: Polygon2D = $Polygon

var _pressing := false


func _ready() -> void:
	## Clicks live on Execute's MOVE_TextBox. This polygon is editor tracing only.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _poly != null:
		_poly.color = Color(1.0, 1.0, 1.0, 0.0)


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
