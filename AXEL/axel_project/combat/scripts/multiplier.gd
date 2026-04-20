class_name CombatMultiplier
extends RefCounted

const MAX_VALUE := 100

var value: int = 1


func reset() -> void:
	value = 1


func add(amount: int) -> void:
	value = mini(value + amount, MAX_VALUE)
