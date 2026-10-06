extends SceneTree

const SCAN_LIMIT := 4000
const PLAY_SEED := 12345

var _cr: CombatRoot
var _lines: Array = []
var _meter_max := 0
var _vice := false
var _errors: PackedStringArray = PackedStringArray()


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_cr = load("res://combat/scenes/combat_root.tscn").instantiate()
	root.add_child(_cr)
	if not _cr.is_node_ready():
		await _cr.ready
	_cr.encounter_def = null
	_cr.line_win_resolved.connect(_on_line)
	_cr.premium_meter_changed.connect(_on_meter)
	_cr.meter_full_transition_started.connect(_on_vice)
	if OS.get_cmdline_user_args().has("--scan"):
		_scan()
	else:
		_verify()
	_cr.queue_free()
	await process_frame
	if _errors.is_empty():
		print("Tutorial script seeds OK: ", CombatRoot.TUTORIAL_SCRIPT_SEEDS)
		quit(0)
		return
	for line in _errors:
		push_error(line)
	quit(1)


func _on_line(event: Dictionary) -> void:
	if int(event.get("payout_cents", 0)) > 0:
		_lines.append(event)


func _on_meter(_previous: int, next_sections: int) -> void:
	_meter_max = maxi(_meter_max, next_sections)


func _on_vice() -> void:
	_vice = true


func _reset_capture() -> void:
	_lines.clear()
	_meter_max = 0
	_vice = false


func _capture() -> Dictionary:
	return {"lines": _lines.duplicate(), "meter": _meter_max, "vice": _vice}


func _spin_with(prefix: Array, candidate: int) -> Dictionary:
	_cr.setup_new_grid(PLAY_SEED)
	var seeds: Array = prefix.duplicate()
	seeds.append(candidate)
	_cr.set_tutorial_script_seeds(seeds)
	for i in prefix.size():
		_reset_capture()
		_cr.spin_sync()
	_reset_capture()
	_cr.spin_sync()
	return _capture()


func _has_premium(info: Dictionary) -> bool:
	for event in info["lines"]:
		if _cr._premium_symbol_ids.has(event.get("symbol_id", &"")):
			return true
	return false


func _ok_match(info: Dictionary) -> bool:
	return info["lines"].size() == 1 and not _has_premium(info) and info["meter"] == 0 and not info["vice"]


func _ok_power(info: Dictionary) -> bool:
	var meter: int = info["meter"]
	return info["lines"].size() <= 2 and _has_premium(info) and meter >= 1 and meter <= 2 and not info["vice"]


func _ok_vice(info: Dictionary) -> bool:
	return info["vice"]


func _find(prefix: Array, checker: Callable) -> int:
	for candidate in range(1, SCAN_LIMIT):
		if checker.call(_spin_with(prefix, candidate)):
			return candidate
	return -1


func _scan() -> void:
	var first := _find([], _ok_match)
	var second := _find([first], _ok_power) if first > 0 else -1
	var third := _find([first, second], _ok_vice) if second > 0 else -1
	print("SCAN RESULT: [", first, ", ", second, ", ", third, "]")
	if first < 0 or second < 0 or third < 0:
		_errors.append("scan did not find all three seeds")


func _verify() -> void:
	var seeds: Array = CombatRoot.TUTORIAL_SCRIPT_SEEDS
	if seeds.size() != 3:
		_errors.append("expected 3 scripted seeds")
		return
	if not _ok_match(_spin_with([], seeds[0])):
		_errors.append("spin 1 is not a single plain match")
	if not _ok_power(_spin_with([seeds[0]], seeds[1])):
		_errors.append("spin 2 does not partly fill the skull meter")
	if not _ok_vice(_spin_with([seeds[0], seeds[1]], seeds[2])):
		_errors.append("spin 3 does not start the Vice Round")
