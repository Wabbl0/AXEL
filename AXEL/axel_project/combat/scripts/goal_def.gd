class_name GoalDef
extends Resource

@export var id: StringName
@export var display_text: String = ""


func init_progress() -> Dictionary:
	return {}


func on_spin_completed(_summary: Dictionary, _progress: Dictionary) -> void:
	pass


func is_complete(_progress: Dictionary) -> bool:
	return false


func progress_label(_progress: Dictionary) -> String:
	return ""
