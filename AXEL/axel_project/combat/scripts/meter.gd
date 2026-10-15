class_name MeterState
extends RefCounted

var sections_filled: int = 0
var saved_active_power: StringName = &""
var allow_overflow: bool = false
var max_sections: int = 3
var cap_below_full: bool = false


func reset() -> void:
	sections_filled = 0
	saved_active_power = &""
	allow_overflow = false


func is_full() -> bool:
	return not cap_below_full and sections_filled >= max_sections


func sections_for_length(length: int) -> int:
	return _line_to_sections(length)


func add_sections(amount: int) -> bool:
	if amount <= 0:
		return is_full()
	if allow_overflow and not cap_below_full:
		sections_filled += amount
	else:
		sections_filled = mini(max_sections, sections_filled + amount)
	if cap_below_full:
		sections_filled = mini(sections_filled, max_sections - 1)
	return is_full()


func add_from_line_length(length: int) -> bool:
	if length <= 0:
		return is_full()
	return add_sections(_line_to_sections(length))


func _line_to_sections(length: int) -> int:
	match length:
		3:
			return 1
		4:
			return 2
		5:
			return 3
		_:

			return 3
