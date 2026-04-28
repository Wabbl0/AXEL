class_name CombatRoot
extends Node2D

enum State { IDLE, SPINNING, POWER, FREE_SPINS_CHOOSE, ENDED }

@export var symbol_resources: Array[Resource] = []

@export_group("Visual pacing (async spin() only)")
## Pause at the start of a spin so the initial grid reads before anything resolves.
@export var pause_at_spin_start_sec: float = 0.85
## Pause after clusters are cleared and wilds are placed (before gravity).
@export var pause_after_cluster_resolve_sec: float = 1.6
## Pause after symbols fall and new symbols spawn.
@export var pause_after_gravity_refill_sec: float = 1.5
## Pause after princess power modifies the grid.
@export var pause_after_power_sec: float = 1.2
@export var girl_power_chance: float = 0.6
@export var encounter_def: Resource
@export var total_bet: int = 1

@onready var grid: GridManager = $GridManager
@onready var grid_ui: GridContainer = $GridUI
@onready var multiplier_label: Label = $MultiplierLabel

const SYMBOL_SLOT_SCENE := preload("res://combat/scenes/symbol.tscn")
const PrincessControllerScript := preload("res://combat/scripts/princess_controller.gd")
const LineDetectorScript := preload("res://combat/scripts/line_detector.gd")
const MeterScript := preload("res://combat/scripts/meter.gd")
const FreeSpinsScript := preload("res://combat/scripts/free_spins.gd")
const GoalTrackerScript := preload("res://combat/scripts/goal_tracker.gd")
const EncounterScript := preload("res://combat/scripts/encounter.gd")

## Safety cap so pathological grids / RNG cannot infinite-loop cascade resolution.
const MAX_CASCADE_ITERATIONS := 512

var rng := CombatRNG.new()
var multiplier := CombatMultiplier.new()
var princesses := PrincessControllerScript.new()
var meter := MeterScript.new()
var free_spins := FreeSpinsScript.new()
var goal_tracker := GoalTrackerScript.new()
var wild_symbol: SymbolDef
var low_symbol_pool: Array[SymbolDef] = []
var premium_symbol_pool: Array[SymbolDef] = []

var _state: State = State.IDLE
var _weights: Dictionary = {}
var _spins_used: int = 0
var _encounter_complete: bool = false
var _encounter_won: bool = false
var _in_trinity_round: bool = false
var _pending_free_spins: bool = false


func _ready() -> void:
	_ensure_symbol_slots()
	_load_symbols_from_export()
	grid.grid_populated.connect(_on_grid_populated)
	grid.cells_cleared.connect(_on_cells_cleared)
	grid.symbols_fell.connect(_on_symbols_fell)
	grid.symbols_spawned.connect(_on_symbols_spawned)
	_refresh_multiplier_label()


func _load_symbols_from_export() -> void:
	_weights.clear()
	low_symbol_pool.clear()
	premium_symbol_pool.clear()
	wild_symbol = null
	for res in symbol_resources:
		var sd := res as SymbolDef
		if sd == null:
			continue
		if sd.tier == SymbolDef.Tier.WILD:
			wild_symbol = sd
		elif sd.tier == SymbolDef.Tier.LOW:
			low_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
		elif sd.tier == SymbolDef.Tier.PREMIUM:
			premium_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
	if wild_symbol == null:
		push_error("CombatRoot: assign wild SymbolDef in symbol_resources.")
	if low_symbol_pool.is_empty():
		push_error("CombatRoot: assign at least one LOW symbol in symbol_resources.")


func get_state() -> int:
	return _state as int


func get_multiplier_value() -> int:
	return multiplier.value


func get_princess_current_id() -> StringName:
	return princesses.current_id()


func get_princess_next_id() -> StringName:
	return princesses.next_id()


func get_goal_label() -> String:
	return goal_tracker.label()


func get_spins_used() -> int:
	return _spins_used


func get_spin_budget() -> int:
	var encounter := encounter_def as EncounterScript
	if encounter == null:
		return 0
	return encounter.spin_budget


func is_encounter_complete() -> bool:
	return _encounter_complete


func did_win_encounter() -> bool:
	return _encounter_won


func setup_new_grid(seed_value: int) -> void:
	rng.seed(seed_value)
	princesses.randomize_start(rng)
	multiplier.reset()
	multiplier.cap_enabled = false
	meter.reset()
	free_spins.reset()
	_spins_used = 0
	_encounter_complete = false
	_encounter_won = false
	_state = State.IDLE
	_in_trinity_round = false
	_pending_free_spins = false
	var encounter := encounter_def as EncounterScript
	var goal = encounter.get("goal") if encounter != null else null
	goal_tracker.call("set_goal", goal)
	_refresh_multiplier_label()
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_refresh_cells_visual()


func spin() -> void:
	if _state != State.IDLE or _encounter_complete:
		return
	_state = State.SPINNING
	if not free_spins.active:
		multiplier.reset()
	_refresh_multiplier_label()
	await _pause_visual(pause_at_spin_start_sec)
	var spin_summary := await _play_one_spin_async()
	var should_trigger_power: bool = not bool(spin_summary["produced_any_win"])
	if should_trigger_power and _should_trigger_girl_power():
		_state = State.POWER
		princesses.trigger_current_power(_make_princess_ctx())
		spin_summary["princess_triggered"] = true
		_refresh_cells_visual()
		await _pause_visual(pause_after_power_sec)
		await _apply_gravity_and_refill()
		var after_power: Dictionary = await _resolve_cascade_loop_async()
		_merge_spin_summary(spin_summary, after_power)
		princesses.advance_rotation()
	spin_summary["grid_cleared"] = _is_grid_empty()
	if spin_summary["grid_cleared"] and not _in_trinity_round:
		spin_summary["payout"] += 50 * total_bet * multiplier.value
	if _pending_free_spins:
		_state = State.FREE_SPINS_CHOOSE
		choose_free_spins_princess(princesses.current_id())
		_pending_free_spins = false
	if free_spins.active:
		free_spins.consume_spin()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	_spins_used += 1
	goal_tracker.on_spin_completed(spin_summary)
	_finalize_encounter_if_needed()
	if _state != State.ENDED:
		_state = State.IDLE
	_refresh_multiplier_label()


## Headless / determinism: same logic as spin() without awaiting the renderer.
func spin_sync() -> void:
	if _state != State.IDLE or _encounter_complete:
		return
	_state = State.SPINNING
	if not free_spins.active:
		multiplier.reset()
	var spin_summary := _play_one_spin_sync()
	var should_trigger_power: bool = not bool(spin_summary["produced_any_win"])
	if should_trigger_power and _should_trigger_girl_power():
		_state = State.POWER
		princesses.trigger_current_power(_make_princess_ctx())
		spin_summary["princess_triggered"] = true
		_refresh_cells_visual()
		_apply_gravity_and_refill_sync()
		var after_power: Dictionary = _resolve_cascade_loop_sync()
		_merge_spin_summary(spin_summary, after_power)
		princesses.advance_rotation()
	spin_summary["grid_cleared"] = _is_grid_empty()
	if spin_summary["grid_cleared"] and not _in_trinity_round:
		spin_summary["payout"] += 50 * total_bet * multiplier.value
	if _pending_free_spins:
		_state = State.FREE_SPINS_CHOOSE
		choose_free_spins_princess(princesses.current_id())
		_pending_free_spins = false
	if free_spins.active:
		free_spins.consume_spin()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	_spins_used += 1
	goal_tracker.on_spin_completed(spin_summary)
	_finalize_encounter_if_needed()
	if _state != State.ENDED:
		_state = State.IDLE


func debug_trigger_power() -> void:
	princesses.trigger_current_power(_make_princess_ctx())
	_refresh_cells_visual()


func serialize_spin_result() -> String:
	return "%s|%d|%s" % [grid.snapshot_ids(), multiplier.value, String(princesses.current_id())]


func choose_free_spins_princess(princess_id: StringName) -> void:
	free_spins.start_with_princess(princess_id)
	multiplier.cap_enabled = true
	multiplier.cap_value = free_spins.multiplier_cap
	_state = State.IDLE


func end_encounter(success: bool) -> void:
	_encounter_complete = true
	_encounter_won = success
	_state = State.ENDED


func _play_one_spin_async() -> Dictionary:
	var summary := await _resolve_cascade_loop_async()
	if not free_spins.active and meter.is_full() and not summary["produced_any_win"]:
		var trinity_summary := await _run_trinity_round_async()
		_merge_spin_summary(summary, trinity_summary)
	if free_spins.active and meter.is_full():
		free_spins.award_from_meter()
		meter.reset()
	return summary


func _play_one_spin_sync() -> Dictionary:
	var summary := _resolve_cascade_loop_sync()
	if not free_spins.active and meter.is_full() and not summary["produced_any_win"]:
		var trinity_summary := _run_trinity_round_sync()
		_merge_spin_summary(summary, trinity_summary)
	if free_spins.active and meter.is_full():
		free_spins.award_from_meter()
		meter.reset()
	return summary


func _resolve_cascade_loop_async() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: cascade exceeded MAX_CASCADE_ITERATIONS (async).")
			break
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		await _resolve_lines(lines)
		await _apply_gravity_and_refill()
		multiplier.add(1)
		_refresh_multiplier_label()
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		out["payout"] = int(out["payout"]) + _estimate_payout(lines)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		_apply_meter_from_lines(lines)
	return out


func _resolve_cascade_loop_sync() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: cascade exceeded MAX_CASCADE_ITERATIONS (sync).")
			break
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		_resolve_lines_sync(lines)
		_apply_gravity_and_refill_sync()
		multiplier.add(1)
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		out["payout"] = int(out["payout"]) + _estimate_payout(lines)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		_apply_meter_from_lines(lines)
	return out


func _make_princess_ctx() -> Dictionary:
	return {
		"grid": grid,
		"rng": rng,
		"wild": wild_symbol,
		"low_pool": low_symbol_pool,
		"premium_pool": premium_symbol_pool,
		"multiplier": multiplier,
	}


func _resolve_lines(lines: Array) -> void:
	_resolve_lines_impl(lines)
	await _pause_visual(pause_after_cluster_resolve_sec)


func _resolve_lines_sync(lines: Array) -> void:
	_resolve_lines_impl(lines)


func _resolve_lines_impl(lines: Array) -> void:
	var to_clear: Dictionary = {}
	var wild_spawns: Dictionary = {}
	for line in lines:
		var cells: Array = line["cells"]
		for p in cells:
			to_clear[p] = true
		if int(line["length"]) == 3:
			var mid: Vector2i = cells[1]
			wild_spawns[mid] = true
	var all_cleared: Array = to_clear.keys()
	grid.clear_cells_and_emit(all_cleared)
	for p in wild_spawns.keys():
		if grid.get_cell(p) == null:
			grid.set_cell(p, wild_symbol)
	_refresh_cells_visual()


func _apply_gravity_and_refill() -> void:
	grid.apply_gravity()
	grid.refill(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_refresh_cells_visual()
	await _pause_visual(pause_after_gravity_refill_sec)


func _apply_gravity_and_refill_sync() -> void:
	grid.apply_gravity()
	grid.refill(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_refresh_cells_visual()


func _pause_visual(seconds: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if seconds <= 0.0:
		await tree.process_frame
		return
	await tree.create_timer(seconds).timeout


func _on_grid_populated() -> void:
	_refresh_cells_visual()


func _on_cells_cleared(_coords: Array) -> void:
	pass


func _on_symbols_fell(_moves: Array) -> void:
	pass


func _on_symbols_spawned(_spawns: Array) -> void:
	pass


func _refresh_multiplier_label() -> void:
	if multiplier_label:
		var suffix := ""
		if free_spins.active:
			suffix = " (FS %d left)" % free_spins.spins_remaining
		multiplier_label.text = "Multiplier: %d×%s" % [multiplier.value, suffix]


func _ensure_symbol_slots() -> void:
	while grid_ui.get_child_count() < 25:
		grid_ui.add_child(SYMBOL_SLOT_SCENE.instantiate())


func _refresh_cells_visual() -> void:
	var idx := 0
	for child in grid_ui.get_children():
		var row: int = int(idx / float(GridManager.COLS))
		var col: int = idx % GridManager.COLS
		var sym: SymbolDef = grid.cells[row][col]
		if child.has_method("set_symbol"):
			child.call("set_symbol", sym)
		else:
			var tex_rect := child as TextureRect
			if tex_rect != null:
				tex_rect.texture = sym.texture if sym != null and sym.texture != null else null
		idx += 1


func _empty_spin_summary() -> Dictionary:
	return {
		"produced_any_win": false,
		"cascade_drops": 0,
		"wilds_placed": 0,
		"payout": 0,
		"princess_triggered": false,
		"grid_cleared": false,
	}


func _merge_spin_summary(base: Dictionary, extra: Dictionary) -> void:
	base["produced_any_win"] = bool(base["produced_any_win"]) or bool(extra.get("produced_any_win", false))
	base["cascade_drops"] = int(base["cascade_drops"]) + int(extra.get("cascade_drops", 0))
	base["wilds_placed"] = int(base["wilds_placed"]) + int(extra.get("wilds_placed", 0))
	base["payout"] = int(base["payout"]) + int(extra.get("payout", 0))
	base["princess_triggered"] = bool(base["princess_triggered"]) or bool(extra.get("princess_triggered", false))
	base["grid_cleared"] = bool(base["grid_cleared"]) or bool(extra.get("grid_cleared", false))


func _count_wild_spawns(lines: Array) -> int:
	var spawned_positions: Dictionary = {}
	for line in lines:
		if int(line["length"]) == 3:
			var cells: Array = line["cells"]
			spawned_positions[cells[1]] = true
	return spawned_positions.size()


func _estimate_payout(lines: Array) -> int:
	var total := 0
	for line in lines:
		var line_length: int = int(line["length"])
		total += line_length * multiplier.value
	return total


func _should_trigger_girl_power() -> bool:
	if free_spins.active:
		princesses.set_current_id(free_spins.chosen_princess)
		return true
	return rng.randf() <= girl_power_chance


func _apply_meter_from_lines(lines: Array) -> void:
	for line in lines:
		if _line_is_princess(line):
			meter.add_from_line_length(int(line["length"]))


func _line_is_princess(line: Dictionary) -> bool:
	var cells: Array = line["cells"]
	for p in cells:
		var sym: SymbolDef = grid.get_cell(p)
		if sym != null and sym.princess_id != &"":
			return true
	return false


func _is_grid_empty() -> bool:
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			if grid.cells[r][c] != null:
				return false
	return true


func _run_trinity_round_async() -> Dictionary:
	var out := _empty_spin_summary()
	meter.saved_active_princess = princesses.current_id()
	multiplier.reset()
	_refresh_multiplier_label()
	_in_trinity_round = true
	var order: Array[StringName] = [&"love", &"star", &"storm"]
	for id in order:
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
		if not lines.is_empty():
			await _resolve_lines(lines)
			await _apply_gravity_and_refill()
			multiplier.add(1)
			_refresh_multiplier_label()
			out["produced_any_win"] = true
			out["cascade_drops"] = int(out["cascade_drops"]) + 1
			out["payout"] = int(out["payout"]) + _estimate_payout(lines)
			out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		else:
			princesses.set_current_id(id)
			princesses.trigger_current_power(_make_princess_ctx())
			out["princess_triggered"] = true
			await _pause_visual(pause_after_power_sec)
			await _apply_gravity_and_refill()
		if _is_grid_empty():
			_pending_free_spins = true
			break
	_in_trinity_round = false
	princesses.set_current_id(meter.saved_active_princess)
	meter.reset()
	return out


func _run_trinity_round_sync() -> Dictionary:
	var out := _empty_spin_summary()
	meter.saved_active_princess = princesses.current_id()
	multiplier.reset()
	_in_trinity_round = true
	var order: Array[StringName] = [&"love", &"star", &"storm"]
	for id in order:
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
		if not lines.is_empty():
			_resolve_lines_sync(lines)
			_apply_gravity_and_refill_sync()
			multiplier.add(1)
			out["produced_any_win"] = true
			out["cascade_drops"] = int(out["cascade_drops"]) + 1
			out["payout"] = int(out["payout"]) + _estimate_payout(lines)
			out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		else:
			princesses.set_current_id(id)
			princesses.trigger_current_power(_make_princess_ctx())
			out["princess_triggered"] = true
			_apply_gravity_and_refill_sync()
		if _is_grid_empty():
			_pending_free_spins = true
			break
	_in_trinity_round = false
	princesses.set_current_id(meter.saved_active_princess)
	meter.reset()
	return out


func _finalize_encounter_if_needed() -> void:
	var encounter := encounter_def as EncounterScript
	if encounter == null:
		return
	if goal_tracker.is_complete():
		end_encounter(true)
		return
	if _spins_used >= encounter.spin_budget and not free_spins.active:
		end_encounter(false)
