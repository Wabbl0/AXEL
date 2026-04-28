class_name CombatMultiplier
extends RefCounted

var value: int = 1
var cap_enabled: bool = false
var cap_value: int = 100


func reset() -> void:
	value = 1


func add(amount: int) -> void:
	value += amount
	if cap_enabled:
		value = mini(value, cap_value)
