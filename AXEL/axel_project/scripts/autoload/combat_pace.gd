class_name CombatPace
extends Node

const SPEED_SLOW := 0.5
const SPEED_NORMAL := 1.0
const SPEED_FAST := 2.0
const RUSH_MULT := 8.0
const RUSH_STEPS: Array[float] = [1.0, 3.0, RUSH_MULT]

static var _live: CombatPace

var _rush_level := 0
var _freeze := false
var _tweens: Array[Tween] = []
var _applied := -1.0


func _enter_tree() -> void:
	_live = self


static func multiplier() -> float:
	if _live == null:
		return SPEED_NORMAL
	return _live._multiplier()


static func set_rush(on: bool) -> void:
	if _live == null:
		return
	_live._set_rush(on)


static func step_rush() -> void:
	if _live == null:
		return
	_live._set_rush_level(_live._rush_level + 1)


static func rush_level() -> int:
	if _live == null:
		return 0
	return _live._rush_level


static func clear_rush() -> void:
	set_rush(false)


static func set_freeze(on: bool) -> void:
	if _live == null:
		return
	_live._set_freeze(on)


static func is_frozen() -> bool:
	if _live == null:
		return false
	return _live._freeze


static func is_rushing() -> bool:
	if _live == null:
		return false
	return _live._rush_level > 0


static func bind(tween: Tween) -> Tween:
	if _live == null:
		return tween
	return _live._bind(tween)


static func await_seconds(seconds: float, should_stop: Callable = Callable()) -> void:
	if _live == null:
		return
	await _live._await_seconds(seconds, should_stop)


func _multiplier() -> float:
	if _freeze:
		return 0.0
	var scale := _base_scale()
	if _rush_level > 0 and not _is_paused():
		scale *= RUSH_STEPS[_rush_level]
	return scale


func _set_rush(on: bool) -> void:
	_set_rush_level(RUSH_STEPS.size() - 1 if on else 0)


func _set_rush_level(level: int) -> void:
	_rush_level = clampi(level, 0, RUSH_STEPS.size() - 1)
	_apply_tween_scales()


func _set_freeze(on: bool) -> void:
	if _freeze == on:
		return
	_freeze = on
	_apply_tween_scales()


func _bind(tween: Tween) -> Tween:
	if tween == null:
		return tween
	tween.set_speed_scale(_multiplier())
	_tweens.append(tween)
	return tween


func _await_seconds(seconds: float, should_stop: Callable = Callable()) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if seconds <= 0.0:
		await tree.process_frame
		return
	var remaining := seconds
	while remaining > 0.0:
		if should_stop.is_valid() and bool(should_stop.call()):
			return
		await tree.process_frame
		if not is_inside_tree():
			return
		var step := get_process_delta_time() * _multiplier()
		if step <= 0.0:
			step = _multiplier() / 60.0
		remaining -= step


func _base_scale() -> float:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return SPEED_NORMAL
	var key := String(settings.call("get_value", "gameplay", "combat_speed", "normal")).to_lower()
	match key:
		"slow":
			return SPEED_SLOW
		"fast":
			return SPEED_FAST
		_:
			return SPEED_NORMAL


func _is_paused() -> bool:
	var pause := get_node_or_null("/root/AxelPause")
	return pause != null and pause.has_method("is_paused") and bool(pause.call("is_paused"))


func _process(_delta: float) -> void:
	var now := _multiplier()
	if not is_equal_approx(now, _applied):
		_apply_tween_scales()
		return
	if not _tweens.is_empty():
		_prune_tweens()


func _apply_tween_scales() -> void:
	var scale := _multiplier()
	_applied = scale
	var live: Array[Tween] = []
	for tween in _tweens:
		if tween == null or not is_instance_valid(tween) or not tween.is_valid():
			continue
		tween.set_speed_scale(scale)
		live.append(tween)
	_tweens = live


func _prune_tweens() -> void:
	var live: Array[Tween] = []
	for tween in _tweens:
		if tween != null and is_instance_valid(tween) and tween.is_valid():
			live.append(tween)
	_tweens = live
