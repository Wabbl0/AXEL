class_name MeterState
extends RefCounted

var sections_filled: int = 0
var saved_active_princess: StringName = &""


func reset() -> void:
	sections_filled = 0
	saved_active_princess = &""


func is_full() -> bool:
	return sections_filled >= 3


func add_from_line_length(length: int) -> bool:
	if length <= 0:
		return is_full()
	sections_filled = mini(3, sections_filled + _line_to_sections(length))
	return is_full()


func _line_to_sections(length: int) -> int:
	match length:
		3:
			return 1
		4:
			return 2
		_:
			return 3
