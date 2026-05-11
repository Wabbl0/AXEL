@tool
extends CanvasLayer

func _ready() -> void:
	if Engine.is_editor_hint():
		visible = false
