class_name CombatRNG
extends RefCounted

var _rng := RandomNumberGenerator.new()


func seed(s: int) -> void:
	_rng.seed = s


func randf() -> float:
	return _rng.randf()


func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)


func randf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b)
