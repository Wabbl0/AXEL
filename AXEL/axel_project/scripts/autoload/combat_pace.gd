class_name CombatPace
extends Node

const SPEED_SLOW := 0.5
const SPEED_NORMAL := 1.0
const SPEED_FAST := 2.0
const RUSH_MULT := 4.0

static var _live: CombatPace

var _rush_latched := false
var _rush_beat := false
var _beat_pending := false
var _beat_tweens: Array[Tween] = []
var _beat_waits: Dictionary = {}
var _waits: Dictionary = {}
var _next_wait_id := 0
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


static func rush_beat() -> void:
	if _live == null:
		return
	_live._start_beat()


static func is_beat_rushing() -> bool:
	if _live == null:
		return false
	return _live._rush_beat


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
	return _live._rush_latched or _live._rush_beat


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
	if (_rush_latched or _rush_beat) and not _is_paused():
		scale *= RUSH_MULT
	return scale


func _set_rush(on: bool) -> void:
	_rush_latched = on
	if not on:
		_end_beat()
	_apply_tween_scales()


func _start_beat() -> void:
	_rush_beat = true
	for tween in _tweens:
		if _beat_counts(tween) and not _beat_tweens.has(tween):
			_beat_tweens.append(tween)
	for id in _waits.keys():
		_beat_waits[id] = true
	_beat_pending = _beat_tweens.is_empty() and _beat_waits.is_empty()
	_apply_tween_scales()


func _end_beat() -> void:
	_rush_beat = false
	_beat_pending = false
	_beat_tweens.clear()
	_beat_waits.clear()


func _beat_counts(tween: Tween) -> bool:
	if tween == null or not is_instance_valid(tween) or not tween.is_valid():
		return false
	return tween.get_loops_left() >= 0


func _tick_beat() -> void:
	if not _rush_beat:
		return
	var live: Array[Tween] = []
	for tween in _beat_tweens:
		if _beat_counts(tween):
			live.append(tween)
	_beat_tweens = live
	var empty := _beat_tweens.is_empty() and _beat_waits.is_empty()
	if _beat_pending:
		if not empty:
			_beat_pending = false
		return
	if empty:
		_end_beat()
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
	if _rush_beat and _beat_pending and _beat_counts(tween):
		_beat_tweens.append(tween)
	return tween


func _await_seconds(seconds: float, should_stop: Callable = Callable()) -> void:
	var id := _next_wait_id
	_next_wait_id += 1
	_waits[id] = true
	if _rush_beat and _beat_pending:
		_beat_waits[id] = true
	await _await_inner(seconds, should_stop)
	_waits.erase(id)
	_beat_waits.erase(id)


func _await_inner(seconds: float, should_stop: Callable) -> void:
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
	_tick_beat()
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
