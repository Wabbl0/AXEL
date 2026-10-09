class_name CombatRoot
extends Node2D

enum State { IDLE, SPINNING, POWER, FREE_SPINS_CHOOSE, ENDED }
signal spin_started(seed_value: int)
signal readouts_progressed()
signal spin_finished()
signal premium_meter_changed(previous_sections: int, next_sections: int)
signal meter_full_transition_started()
signal matched_symbols_resolved(entries: Array)
signal line_win_resolved(event: Dictionary)
signal winnings_popup_border_touched(event: Dictionary)
signal round_winnings_hold_started()
signal free_spins_bonus_granted(added: int)
signal encounter_finished(success: bool)
signal sfx_requested(cue: StringName)
signal goal_victory_requested()
signal vice_banner_finished()

@export var symbol_resources: Array[Resource] = []

@export_group("Visual pacing (async spin() only)")
@export var pause_at_spin_start_sec: float = 1.275
@export var pause_after_cluster_resolve_sec: float = 0.15
@export var pause_after_gravity_refill_sec: float = 0.2
@export var pause_after_power_sec: float = 0.25
@export_group("Symbol FX")
@export var enable_symbol_fx: bool = true
@export var drop_duration_sec: float = 0.2
@export var spawn_drop_duration_sec: float = 0.24
@export var count_flash_duration_sec: float = 0.2
@export var fx_stagger_sec: float = 0.01
@export var cascade_column_step_sec: float = 0.05
@export_group("Board swap FX (populate only)")
@export var board_swap_fall_cell_sec: float = 0.08
@export var board_swap_fall_column_step_sec: float = 0.08
@export var board_swap_fill_cell_sec: float = 0.13
@export var board_swap_fall_overshoot_cells: float = 0.5
@export_group("Transition FX")
@export var enable_transition_fx: bool = true
@export var grid_flash_duration_sec: float = 0.48
@export_range(1, 4, 1) var grid_flash_count: int = 2
@export_range(0.0, 1.0, 0.01) var grid_flash_peak_alpha: float = 0.7
@export var grid_border_pulse_duration_sec: float = 0.45
@export var meter_handoff_pause_sec: float = 0.75
@export var free_spin_handoff_pause_sec: float = 0.90
@export_group("Power Intro FX")
@export var enable_power_intro_fx: bool = true
@export var power_intro_scale_in_sec: float = 0.54
@export var power_intro_hold_sec: float = 0.31
@export var power_intro_scale_out_sec: float = 0.42
@export var power_intro_peak_scale: float = 1.8
@export_range(0.0, 1.0, 0.01) var power_intro_glow_alpha: float = 0.5
@export var girl_power_chance: float = 0.01
@export var encounter_def: Resource
@export var total_bet: float = 100.0

@onready var grid: GridManager = $GridManager
@onready var grid_ui: GridContainer = $GridUI
@onready var multiplier_label: Label = $MultiplierLabel
@onready var round_winnings_label: Label = $RoundWinningsLabel
@onready var grid_frame: ReferenceRect = $GridFrame
@onready var grid_flash_overlay: ColorRect = $GridFlashOverlay
@onready var power_intro_layer: Control = $PowerIntroLayer
@onready var power_intro_glow: ColorRect = $PowerIntroLayer/PowerIntroGlow
@onready var power_intro_icon: TextureRect = $PowerIntroLayer/PowerIntroIcon

const SYMBOL_SLOT_SCENE := preload("res://combat/scenes/symbol.tscn")
const WIN_SKULL := preload("res://combat/art/grid_symbols/satanic_wild.png")
const PowerControllerScript := preload("res://combat/scripts/power_controller.gd")
const LineDetectorScript := preload("res://combat/scripts/line_detector.gd")
const MeterScript := preload("res://combat/scripts/meter.gd")
const FreeSpinsScript := preload("res://combat/scripts/free_spins.gd")
const GoalTrackerScript := preload("res://combat/scripts/goal_tracker.gd")
const EncounterScript := preload("res://combat/scripts/encounter.gd")
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const ItemInventoryScript := preload("res://combat/scripts/item_inventory.gd")
const ItemEffectDispatcherScript := preload("res://combat/scripts/item_effect_dispatcher.gd")
const CombatFeelScript := preload("res://combat/scripts/combat_feel.gd")

const MAX_CASCADE_ITERATIONS := 512
const ECONOMY_DISPLAY_SCALE := 1
const CHIP_BAR_SECTIONS := 11
const CHIP_BAR_FULL_CENTS := 1000
const CHIP_BAR_GOAL_MULTIPLE := 10
const STARTING_BANKROLL_CENTS := 3000
const GRID_VISUAL_SCALE := 1.5
const GRID_EDGE_MARGIN := 8.0
const VIEWPORT_TOP_SAFE := 84.0
const VIEWPORT_BOTTOM_SAFE := 292.0
const CELL_SIZE_MIN := 48.0
const CELL_SIZE_MAX := 80.0
const ROUND_WINNINGS_GAP := 12.0
const ROUND_WINNINGS_HEIGHT := 36.0
const BET_LADDER: Array[float] = [
	100.0, 200.0, 300.0, 400.0, 500.0, 1000.0,
]
const BASELINE_PAYOUT_SCALAR := 0.431
const PAYTABLE_SCALE := 10.0
const TUTORIAL_LAST_SPIN_SEED := 12
const TUTORIAL_SCRIPT_SEEDS: Array[int] = [10, 8, 1, 12]

var rng := CombatRNG.new()
var multiplier := CombatMultiplier.new()
var powers := PowerControllerScript.new()
var meter := MeterScript.new()
var free_spins := FreeSpinsScript.new()
var goal_tracker := GoalTrackerScript.new()
var wild_symbol: SymbolDef
var low_symbol_pool: Array[SymbolDef] = []
var premium_symbol_pool: Array[SymbolDef] = []
var _premium_symbol_ids: Dictionary = {}
var _symbols_by_id: Dictionary = {}
var _current_bet_index: int = 0

var _state: State = State.IDLE
var _weights: Dictionary = {}
var _base_weights: Dictionary = {}
var _spins_used: int = 0
var _bets_used_cents: int = 0
var _lifetime_spins_used: int = 0
var _current_seed: int = 0
var _encounter_complete: bool = false
var _encounter_won: bool = false
var _in_trinity_round: bool = false
var _pending_free_spins: bool = false
var _awaiting_free_spin_choice: bool = false
var _free_spin_opened_fresh: bool = false
var _free_spin_open_ids: String = ""
var _free_spin_open_had_lines: bool = false
var _pending_fall_moves: Array = []
var _pending_spawns: Array = []
var _slot_positions_ready: bool = false
var _round_winnings_cents: int = 0
var _feature_hold: StringName = &""
var _feature_held_cents: int = 0
var _bankroll_cents: int = STARTING_BANKROLL_CENTS
var _encounter_goal_winnings_cents: int = 0
var _encounter_goal_base_target_cents: int = CHIP_BAR_FULL_CENTS * CHIP_BAR_GOAL_MULTIPLE
var _lore_goal_bonus: float = 0.0
var _final_spin_goal_assist: float = 0.0
var _final_spin_assist_rolled: bool = false
var _tutorial_last_spin_lock: bool = false
var _tutorial_script_seeds: Array[int] = []
var _tutorial_last_spin_seed: int = TUTORIAL_LAST_SPIN_SEED
var _playtest_spin_budget: int = 8
var _playtest_limit_spins: bool = false
var _item_fx := ItemEffectDispatcherScript.new()
var _round_winnings_default_modulate: Color = Color.WHITE
var _grid_width_cached: float = 0.0
var _grid_height_cached: float = 0.0
var _grid_flash_tween: Tween
var _grid_border_tween: Tween
var _power_intro_tween: Tween
var _round_winnings_glow_tween: Tween
var _last_spin_summary: Dictionary = {}
var _default_grid_border_color: Color = Color(0.78, 0.03, 0.03, 0.95)
var _power_symbol_by_id: Dictionary = {}
var _power_intro_fallback_label: Label
var _suppress_grid_populated_fx: bool = false
var _board_swap_fx_active: bool = false
var _board_swap_fx_gen: int = 0
var _cached_multiplier_emit_value: int = -1
var _winnings_popup_target: Control = null
var _feel: Node
var inventory := ItemInventoryScript.new()
const GRID_FRAME_OUTSET := 4.0
const POWER_INTRO_ICON_SIZE_RATIO := 0.55
const POWER_ACT_SEC := 0.48
var _dev_guarantee_trinity: bool = false
var _dev_guarantee_fs_clear: bool = false
var _dev_guarantee_payout_1000x: bool = false
var _dev_skip_visuals: bool = false
var vice_entry_gate_open: bool = true
var _goal_burst_playing: bool = false
var _power_fx_log: Array = []
var _power_fx_depth: int = 0
var _power_sfx_emitted: bool = false
var _hold_item_pulses: bool = false
var _held_item_pulses: Array[StringName] = []

func _ready() -> void:
	add_to_group("combat_root")
	if _is_headless_runtime():
		enable_symbol_fx = false
		enable_transition_fx = false
		enable_power_intro_fx = false
	_ensure_symbol_slots()
	_load_symbols_from_export()
	_init_playtest_budget_from_encounter()
	grid.grid_populated.connect(_on_grid_populated)
	grid.cells_cleared.connect(_on_cells_cleared)
	grid.symbols_fell.connect(_on_symbols_fell)
	grid.symbols_spawned.connect(_on_symbols_spawned)
	if multiplier_label != null:
		multiplier_label.visible = false
	if round_winnings_label != null:
		_round_winnings_default_modulate = round_winnings_label.self_modulate
		round_winnings_label.add_theme_color_override("font_outline_color", Color(1.0, 0.36, 0.36, 0.22))
		round_winnings_label.add_theme_constant_override("outline_size", 1)
		round_winnings_label.visible = false
	if grid_frame != null:
		_default_grid_border_color = grid_frame.border_color
	if grid_flash_overlay != null:
		grid_flash_overlay.visible = false
		grid_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	if power_intro_layer != null:
		power_intro_layer.visible = false
	if power_intro_icon != null:
		power_intro_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
		power_intro_icon.scale = Vector2(0.4, 0.4)
	if power_intro_glow != null:
		power_intro_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	_refresh_multiplier_label()
	_refresh_round_winnings_label()
	_refresh_grid_border_for_state()
	_feel = CombatFeelScript.new()
	_feel.name = "CombatFeel"
	add_child(_feel)
	_feel.setup(self, grid_ui)

func _load_symbols_from_export() -> void:
	_weights.clear()
	_base_weights.clear()
	low_symbol_pool.clear()
	premium_symbol_pool.clear()
	_premium_symbol_ids.clear()
	_symbols_by_id.clear()
	_power_symbol_by_id.clear()
	wild_symbol = null
	for res in symbol_resources:
		var sd := res as SymbolDef
		if sd == null:
			continue
		_symbols_by_id[sd.id] = sd
		if sd.tier == SymbolDef.Tier.WILD:
			wild_symbol = sd
		elif sd.tier == SymbolDef.Tier.LOW:
			low_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
			_base_weights[sd.id] = sd.base_weight
		elif sd.tier == SymbolDef.Tier.PREMIUM:
			premium_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
			_base_weights[sd.id] = sd.base_weight
			_premium_symbol_ids[sd.id] = true
		if sd.power_id != &"":
			_power_symbol_by_id[sd.power_id] = sd
	if wild_symbol == null:
		push_error("CombatRoot: assign wild SymbolDef in symbol_resources.")
	if low_symbol_pool.is_empty():
		push_error("CombatRoot: assign at least one LOW symbol in symbol_resources.")
	for sd in _symbols_by_id.values():
		var symbol := sd as SymbolDef
		if symbol == null:
			continue
		if symbol.payout_x3 <= 0.0 or symbol.payout_x4 <= 0.0 or symbol.payout_x5 <= 0.0:
			push_warning("CombatRoot: symbol %s is missing payout_x3/x4/x5 values." % String(symbol.id))

func get_bet_ladder() -> Array[float]:
	return BET_LADDER.duplicate()

func get_current_bet() -> float:
	return total_bet

func get_bet_index() -> int:
	return _current_bet_index

func set_bet_index(index: int) -> void:
	if BET_LADDER.is_empty():
		return
	var max_index := BET_LADDER.size() - 1
	_current_bet_index = clampi(index, 0, max_index)
	total_bet = BET_LADDER[_current_bet_index]
	emit_signal("readouts_progressed")

func step_bet(delta: int) -> void:
	set_bet_index(_current_bet_index + delta)

func get_state() -> int:
	return _state as int

func get_multiplier_value() -> int:
	return multiplier.value

func is_multiplier_cap_active() -> bool:
	return multiplier.cap_enabled

func get_multiplier_cap_value() -> int:
	return multiplier.cap_value

func get_power_current_id() -> StringName:
	return powers.current_id()

func get_power_next_id() -> StringName:
	return powers.next_id()

func get_goal_label() -> String:
	return get_chip_bar_goal_label()

func get_chip_bar_section_count() -> int:
	return CHIP_BAR_SECTIONS

func get_chip_bar_full_value() -> float:
	return float(CHIP_BAR_FULL_CENTS)

func get_chip_bar_health_ratio() -> float:
	return clampf(float(_bankroll_cents) / float(CHIP_BAR_FULL_CENTS), 0.0, 1.0)

func get_chip_bar_goal_target_cents() -> int:
	return get_effective_goal_target_cents()

func get_goal_base_target_cents() -> int:
	return _encounter_goal_base_target_cents

func get_effective_goal_target_cents() -> int:
	var pct := _item_fx.goal_percent(inventory.items) + _lore_goal_bonus
	var raw := int(round(float(_encounter_goal_base_target_cents) * (1.0 + pct)))
	return _ceil_to_multiple(raw, 5)


func _ceil_to_multiple(n: int, step: int) -> int:
	if n <= 0 or step <= 1:
		return maxi(n, 0)
	var remainder := n % step
	if remainder == 0:
		return n
	return n + (step - remainder)


func set_lore_goal_bonus(pct: float) -> void:
	_lore_goal_bonus = maxf(pct, 0.0)
	emit_signal("readouts_progressed")


func get_lore_goal_bonus() -> float:
	return _lore_goal_bonus

func set_spins_used(n: int) -> void:
	_spins_used = clampi(n, 0, 99)
	emit_signal("readouts_progressed")

func set_spin_budget(n: int) -> void:
	_playtest_spin_budget = maxi(n, 0)
	emit_signal("readouts_progressed")

func get_playtest_spin_budget() -> int:
	return _playtest_spin_budget

func set_limit_spins(on: bool) -> void:
	_playtest_limit_spins = on
	emit_signal("readouts_progressed")

func is_limit_spins() -> bool:
	return _playtest_limit_spins

func set_goal_base_target_cents(n: int) -> void:
	_encounter_goal_base_target_cents = maxi(n, 1)
	_on_loadout_or_goal_changed()

func set_final_spin_goal_assist(p: float) -> void:
	_final_spin_goal_assist = clampf(p, 0.0, 1.0)

func get_final_spin_goal_assist() -> float:
	return _final_spin_goal_assist

func set_tutorial_script_seeds(seeds: Array) -> void:
	_tutorial_script_seeds.clear()
	for value in seeds:
		_tutorial_script_seeds.append(int(value))

func get_tutorial_script_seeds() -> Array[int]:
	return _tutorial_script_seeds

func set_tutorial_last_spin_lock(on: bool) -> void:
	_tutorial_last_spin_lock = on

func get_tutorial_last_spin_lock() -> bool:
	return _tutorial_last_spin_lock

func set_tutorial_last_spin_seed(n: int) -> void:
	_tutorial_last_spin_seed = n if n != 0 else TUTORIAL_LAST_SPIN_SEED

func get_tutorial_last_spin_seed() -> int:
	return _tutorial_last_spin_seed

func is_last_affordable_paid_spin() -> bool:
	if free_spins.active or _in_trinity_round:
		return false
	if not _can_afford_spin():
		return false

	return _bankroll_cents < _to_cents(total_bet) * 2

func set_goal_progress_cents(n: int) -> void:
	_encounter_goal_winnings_cents = maxi(n, 0)
	_on_loadout_or_goal_changed()

func set_bankroll_cents(n: int) -> void:

	if not OS.is_debug_build():
		return
	restore_run_bankroll(n)


func restore_run_bankroll(n: int) -> void:
	_bankroll_cents = n
	_clamp_bankroll()
	emit_signal("readouts_progressed")

func debug_set_guarantee_trinity(on: bool) -> void:
	if not OS.is_debug_build():
		return
	_dev_guarantee_trinity = on

func debug_set_guarantee_fs_clear(on: bool) -> void:
	if not OS.is_debug_build():
		return
	_dev_guarantee_fs_clear = on

func debug_set_guarantee_payout_1000x(on: bool) -> void:
	if not OS.is_debug_build():
		return
	_dev_guarantee_payout_1000x = on

func debug_get_guarantee_trinity() -> bool:
	return OS.is_debug_build() and _dev_guarantee_trinity

func debug_get_guarantee_fs_clear() -> bool:
	return OS.is_debug_build() and _dev_guarantee_fs_clear

func debug_get_guarantee_payout_1000x() -> bool:
	return OS.is_debug_build() and _dev_guarantee_payout_1000x

func debug_skip_current_loop() -> void:
	if not OS.is_debug_build():
		return
	if _state == State.IDLE or _state == State.FREE_SPINS_CHOOSE or _state == State.ENDED:
		return
	_dev_skip_visuals = true
	_kill_tween(_grid_flash_tween)
	_kill_tween(_grid_border_tween)
	_kill_tween(_power_intro_tween)
	_kill_tween(_round_winnings_glow_tween)

func get_item_payout_scalar() -> float:
	return _get_item_payout_scalar()

func get_sealed_grid_payout_bonus() -> float:
	return _item_fx.sealed_payout(inventory.items, _is_regular_spin_mode())

func get_paid_spin_item_hint() -> String:
	return _item_fx.paid_spin_hint(inventory.items, _spins_used)

func set_ignore_slot_cap(on: bool) -> void:
	inventory.ignore_slot_cap = on

func replace_item_at(index: int, item: Resource) -> bool:
	var ok: bool = inventory.replace_at(index, item)
	if ok:
		_on_loadout_or_goal_changed()
	return ok

func get_chip_bar_goal_progress_cents() -> int:
	return _encounter_goal_winnings_cents

func get_chip_bar_goal_progress_ratio() -> float:
	var target := get_chip_bar_goal_target_cents()
	if target <= 0:
		return 0.0
	return clampf(float(_encounter_goal_winnings_cents) / float(target), 0.0, 1.0)

func get_spin_win_bet_ratio() -> float:
	if total_bet <= 0.0:
		return 0.0
	return get_round_winnings() / total_bet

func get_chip_bar_goal_label() -> String:
	var target_units := get_chip_bar_goal_target_cents()
	var current_units := _encounter_goal_winnings_cents
	return "GOAL: (%d / %d)" % [current_units, target_units]

func is_chip_bar_goal_complete() -> bool:
	return _encounter_goal_winnings_cents >= get_chip_bar_goal_target_cents()

func get_meter_sections_filled() -> int:
	return meter.sections_filled

func get_spins_used() -> int:
	return _spins_used

func get_bets_used() -> int:
	return _bets_used_cents

func get_lifetime_spins_used() -> int:
	return _lifetime_spins_used

func get_spin_budget() -> int:
	var encounter := encounter_def as EncounterScript
	if encounter == null:
		return 0
	return encounter.spin_budget

func get_current_seed() -> int:
	return _current_seed

func get_round_winnings() -> float:
	return float(_round_winnings_cents)

func set_winnings_popup_target(target: Control) -> void:
	_winnings_popup_target = target

func get_bankroll() -> float:
	return float(_bankroll_cents)

func get_bankroll_cap() -> float:
	return float(CHIP_BAR_FULL_CENTS)

func _clamp_bankroll() -> void:
	_bankroll_cents = maxi(_bankroll_cents, 0)

func get_last_spin_summary() -> Dictionary:
	return _last_spin_summary.duplicate(true)

func is_encounter_complete() -> bool:
	return _encounter_complete

func did_win_encounter() -> bool:
	return _encounter_won

func is_waiting_for_free_spin_choice() -> bool:
	return _awaiting_free_spin_choice

func is_bonus_skull_held() -> bool:
	return (
		_in_trinity_round
		or _pending_free_spins
		or _awaiting_free_spin_choice
		or free_spins.active
	)

func get_free_spin_counter() -> Vector2i:
	if not free_spins.active:
		return Vector2i.ZERO
	var total := free_spins.spins_awarded_total
	var left := free_spins.spins_remaining
	if total <= 0 or left <= 0:
		return Vector2i.ZERO
	return Vector2i(total - left + 1, total)

func setup_new_grid(seed_value: int) -> void:
	_current_seed = seed_value
	rng.seed(seed_value)
	powers.randomize_start(rng)
	multiplier.reset()
	multiplier.cap_enabled = false
	meter.reset()
	free_spins.reset()
	_spins_used = 0
	_bets_used_cents = 0
	_encounter_complete = false
	_encounter_won = false
	_state = State.IDLE
	_in_trinity_round = false
	_pending_free_spins = false
	_awaiting_free_spin_choice = false
	_clear_free_spin_open()
	_round_winnings_cents = 0
	_feature_hold = &""
	_feature_held_cents = 0
	_encounter_goal_winnings_cents = 0
	_final_spin_assist_rolled = false
	_last_spin_summary = _empty_spin_summary()
	_bankroll_cents = STARTING_BANKROLL_CENTS
	_clamp_bankroll()
	_lifetime_spins_used = 0
	_item_fx.reset_encounter()
	_refresh_spin_weights()
	var encounter := encounter_def as EncounterScript
	var goal = encounter.get("goal") if encounter != null else null
	goal_tracker.call("set_goal", goal)
	_refresh_multiplier_label()
	_refresh_round_winnings_label()
	_hide_encounter_won_banner()
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	if not enable_symbol_fx:
		_refresh_cells_visual()
	_refresh_grid_border_for_state()
	_music_reset_combat_encounter()
	_item_fx.note_param(inventory.items, &"true_path_goal", "goal_percent")
	_flush_item_procs()
	emit_signal("spin_started", _current_seed)
	emit_signal("readouts_progressed")

func spin() -> void:
	if _state != State.IDLE or _encounter_complete:
		emit_signal("spin_finished")
		return
	if not free_spins.active and not _can_use_paid_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		emit_signal("spin_finished")
		return
	if not free_spins.active and not _can_afford_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		emit_signal("spin_finished")
		return
	_state = State.SPINNING
	if not free_spins.active:
		_round_winnings_cents = 0
		_hide_round_winnings_overlay(false)
		_refresh_round_winnings_label()
	_begin_spin_round()
	if not free_spins.active:
		multiplier.reset()
	_refresh_multiplier_label()
	emit_signal("readouts_progressed")


	if _board_swap_fx_active:
		await _await_board_swap_fx()
	else:
		await _pause_visual(pause_at_spin_start_sec)
	_release_item_pulses()
	var spin_summary := _empty_spin_summary()
	_stamp_free_spin_open(spin_summary)
	await _try_regular_spin_start_girl_power_async(spin_summary)
	await _try_free_spin_power_async(spin_summary)
	var main_summary := await _play_one_spin_async()
	_merge_spin_summary(spin_summary, main_summary)
	_finish_item_spin_hooks(spin_summary)
	spin_summary["grid_cleared"] = _is_grid_cleared_for_current_mode()
	if _pending_free_spins:
		if free_spin_handoff_pause_sec > 0.0:
			await _pause_visual(free_spin_handoff_pause_sec)
		_state = State.FREE_SPINS_CHOOSE
		_awaiting_free_spin_choice = true
		_pending_free_spins = false
		await _notify_free_spins_entry_async()
		emit_signal("readouts_progressed")
	if free_spins.active and not _awaiting_free_spin_choice:
		free_spins.consume_spin()
		if not free_spins.active:
			_commit_feature_hold()
			_music_notify_free_spins_ended()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	goal_tracker.on_spin_completed(spin_summary)
	if free_spins.active and goal_tracker.is_complete():
		_settle_symbols_down_without_refill()
	_apply_dev_payout_override(spin_summary)
	_bankroll_cents += int(spin_summary["payout"])
	_clamp_bankroll()
	_reset_premium_meter_after_paid_spin()
	_refresh_grid_border_for_state()
	_finalize_encounter_if_needed()
	if _state != State.ENDED and _state != State.FREE_SPINS_CHOOSE:
		_state = State.IDLE
	if int(spin_summary.get("payout", 0)) > 0:
		_play_round_winnings_win_glow()
	_refresh_multiplier_label()
	_last_spin_summary = spin_summary.duplicate(true)
	_dev_skip_visuals = false
	_release_item_pulses()
	emit_signal("readouts_progressed")
	emit_signal("spin_finished")

func spin_sync() -> void:
	if _state != State.IDLE or _encounter_complete:
		return
	if not free_spins.active and not _can_use_paid_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		return
	if not free_spins.active and not _can_afford_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		return
	_state = State.SPINNING
	if not free_spins.active:
		_round_winnings_cents = 0
		_hide_round_winnings_overlay(false)
		_refresh_round_winnings_label()
	_begin_spin_round()
	_release_item_pulses()
	if not free_spins.active:
		multiplier.reset()
	emit_signal("readouts_progressed")
	var spin_summary := _empty_spin_summary()
	_stamp_free_spin_open(spin_summary)
	_try_regular_spin_start_girl_power_sync(spin_summary)
	_try_free_spin_power_sync(spin_summary)
	var main_summary := _play_one_spin_sync()
	_merge_spin_summary(spin_summary, main_summary)
	_finish_item_spin_hooks(spin_summary)
	spin_summary["grid_cleared"] = _is_grid_cleared_for_current_mode()
	if _pending_free_spins:
		_state = State.FREE_SPINS_CHOOSE
		_awaiting_free_spin_choice = true
		_pending_free_spins = false
		_notify_free_spins_entry()
		emit_signal("readouts_progressed")
	if free_spins.active and not _awaiting_free_spin_choice:
		free_spins.consume_spin()
		if not free_spins.active:
			_commit_feature_hold()
			_music_notify_free_spins_ended()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	goal_tracker.on_spin_completed(spin_summary)
	if free_spins.active and goal_tracker.is_complete():
		_settle_symbols_down_without_refill()
	_apply_dev_payout_override(spin_summary)
	_bankroll_cents += int(spin_summary["payout"])
	_clamp_bankroll()
	_reset_premium_meter_after_paid_spin()
	_refresh_grid_border_for_state()
	_finalize_encounter_if_needed()
	if _state != State.ENDED and _state != State.FREE_SPINS_CHOOSE:
		_state = State.IDLE
	if int(spin_summary.get("payout", 0)) > 0:
		_play_round_winnings_win_glow()
	_last_spin_summary = spin_summary.duplicate(true)
	_dev_skip_visuals = false
	_release_item_pulses()
	emit_signal("readouts_progressed")

func debug_trigger_power() -> void:
	_trigger_item_power(powers.current_id(), 1.0, false, false)
	_release_item_pulses()
	_refresh_cells_visual()

func serialize_spin_result() -> String:
	return "%s|%d|%s" % [grid.snapshot_ids(), multiplier.value, String(powers.current_id())]

func choose_free_spins_power(power_id: StringName) -> void:
	if not _awaiting_free_spin_choice:
		return

	var fs_mods: Dictionary = _item_fx.free_spins_mods(inventory.items)
	free_spins.start_with_power(power_id, int(fs_mods.get("extra_spins", 0)))
	_item_fx.note_param(inventory.items, &"free_spins", "extra_spins")
	powers.set_current_id(power_id)
	_repopulate_grid_handoff("super_fs_entry")
	_start_free_spin_winnings_hold()
	var burst := float(fs_mods.get("enter_burst", 0.0))
	if burst > 0.0:
		var burst_cents := _to_cents(burst * total_bet)
		_add_round_winnings(burst_cents)
		_bankroll_cents += burst_cents
		_clamp_bankroll()
		_item_fx.note_param(inventory.items, &"free_spins", "enter_burst")
	_flush_item_procs()
	_awaiting_free_spin_choice = false
	multiplier.cap_enabled = true
	multiplier.cap_value = free_spins.multiplier_cap
	_state = State.IDLE
	_refresh_grid_border_for_state()
	emit_signal("readouts_progressed")

func run_free_spin_round() -> void:
	var guard := 0
	var limit := free_spins.total_spin_cap + 5
	while free_spins.active and guard < limit:
		guard += 1
		if _state != State.IDLE or _encounter_complete:
			break
		await spin()

func run_free_spin_round_sync() -> void:
	var guard := 0
	var limit := free_spins.total_spin_cap + 5
	while free_spins.active and guard < limit:
		guard += 1
		if _state != State.IDLE or _encounter_complete:
			break
		spin_sync()

func end_encounter(success: bool) -> void:
	if _encounter_complete:
		return
	_encounter_complete = true
	_encounter_won = success
	_state = State.ENDED
	if success:
		_show_encounter_won_banner()
	else:
		_hide_encounter_won_banner()
	encounter_finished.emit(success)
	sfx_requested.emit(&"win" if success else &"loss")
	if success:
		goal_victory_requested.emit()

func equip_item(item: Resource) -> bool:
	var ok: bool = inventory.equip(item)
	if ok:
		_on_loadout_or_goal_changed()
	return ok

func unequip_item(item: Resource) -> void:
	inventory.unequip(item)
	_on_loadout_or_goal_changed()

func set_equipped_items(items: Array) -> void:
	inventory.set_all(items)
	_on_loadout_or_goal_changed()

func begin_next_playtest_encounter(seed_value: int) -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("is_in_encounter") and bool(run.call("is_in_encounter")):
		return
	var preserved_bankroll := _bankroll_cents
	_current_seed = seed_value
	rng.seed(seed_value)
	powers.randomize_start(rng)
	multiplier.reset()
	multiplier.cap_enabled = false
	meter.reset()
	free_spins.reset()
	_spins_used = 0
	_bets_used_cents = 0
	_encounter_complete = false
	_encounter_won = false
	_state = State.IDLE
	_in_trinity_round = false
	_pending_free_spins = false
	_awaiting_free_spin_choice = false
	_clear_free_spin_open()
	_round_winnings_cents = 0
	_feature_hold = &""
	_feature_held_cents = 0
	_encounter_goal_winnings_cents = 0
	_final_spin_assist_rolled = false
	_bankroll_cents = preserved_bankroll
	_clamp_bankroll()
	_item_fx.reset_encounter()
	_refresh_spin_weights()
	var encounter := encounter_def as EncounterScript
	var goal = encounter.get("goal") if encounter != null else null
	goal_tracker.call("set_goal", goal)
	_refresh_multiplier_label()
	_refresh_round_winnings_label()
	_hide_encounter_won_banner()
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	if not enable_symbol_fx:
		_refresh_cells_visual()
	_refresh_grid_border_for_state()
	_music_reset_combat_encounter()
	_item_fx.note_param(inventory.items, &"true_path_goal", "goal_percent")
	_flush_item_procs()
	emit_signal("spin_started", _current_seed)
	emit_signal("readouts_progressed")

func _play_one_spin_async() -> Dictionary:
	_dev_fill_meter_for_guarantee_trinity()
	var summary := await _resolve_cascade_loop_async()
	if not free_spins.active and meter.is_full():
		var trinity_summary := await _run_trinity_round_async()
		_merge_spin_summary(summary, trinity_summary)
	_grant_free_spin_meter_bonus()
	return summary

func _play_one_spin_sync() -> Dictionary:
	_dev_fill_meter_for_guarantee_trinity()
	var summary := _resolve_cascade_loop_sync()
	if not free_spins.active and meter.is_full():
		var trinity_summary := _run_trinity_round_sync()
		_merge_spin_summary(summary, trinity_summary)
	_grant_free_spin_meter_bonus()
	return summary

func _try_regular_spin_start_girl_power_async(spin_summary: Dictionary) -> void:
	if free_spins.active:
		return
	if not _should_trigger_girl_power():
		return
	_state = State.POWER
	var power_id := _pick_power_for_current_spin()
	await _play_power_intro_flash_async(power_id)
	_trigger_item_power(power_id, 1.0, false, true)
	spin_summary["power_triggered"] = true
	await _play_power_act_fx(_power_fx_log)
	await _apply_gravity_and_refill(true)
	var after_power: Dictionary = await _resolve_cascade_loop_async()
	_merge_spin_summary(spin_summary, after_power)
	powers.advance_rotation()

func _try_regular_spin_start_girl_power_sync(spin_summary: Dictionary) -> void:
	if free_spins.active:
		return
	if not _should_trigger_girl_power():
		return
	_state = State.POWER
	var power_id := _pick_power_for_current_spin()
	_trigger_item_power(power_id, 1.0, false, true)
	spin_summary["power_triggered"] = true
	_refresh_cells_visual()
	_apply_gravity_and_refill_sync(true)
	var after_power: Dictionary = _resolve_cascade_loop_sync()
	_merge_spin_summary(spin_summary, after_power)
	powers.advance_rotation()

func _resolve_cascade_loop_async() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: cascade exceeded MAX_CASCADE_ITERATIONS (async).")
			break
		var lines: Array = _find_lines()
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		await _resolve_lines(lines)
		await _apply_gravity_and_refill(not free_spins.active)
		_emit_line_win_events(lines)
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		var line_win := _estimate_payout(lines)
		out["payout"] = int(out["payout"]) + line_win
		out["line_payout"] = int(out["line_payout"]) + line_win
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
		var fs_mods_sync: Dictionary = _item_fx.free_spins_mods(inventory.items)
		if free_spins.active and int(fs_mods_sync.get("cascade_payout_step", 0)) != 0:
			multiplier.add(int(fs_mods_sync.get("cascade_payout_step", 0)))
			_item_fx.note_param(inventory.items, &"free_spins", "cascade_payout_step")
			_flush_item_procs()
		_apply_board_count_bonus(out, true)
		_apply_glyph_payouts(lines, out)
		_refresh_multiplier_label()
	return out

func _resolve_cascade_loop_sync() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: cascade exceeded MAX_CASCADE_ITERATIONS (sync).")
			break
		var lines: Array = _find_lines()
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		_resolve_lines_sync(lines)
		_apply_gravity_and_refill_sync(not free_spins.active)
		_emit_line_win_events(lines)
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		var line_win := _estimate_payout(lines)
		out["payout"] = int(out["payout"]) + line_win
		out["line_payout"] = int(out["line_payout"]) + line_win
		_note_paid_line_procs(lines)
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
		var fs_mods_sync: Dictionary = _item_fx.free_spins_mods(inventory.items)
		if free_spins.active and int(fs_mods_sync.get("cascade_payout_step", 0)) != 0:
			multiplier.add(int(fs_mods_sync.get("cascade_payout_step", 0)))
			_item_fx.note_param(inventory.items, &"free_spins", "cascade_payout_step")
			_flush_item_procs()
		_apply_board_count_bonus(out, true)
		_apply_glyph_payouts(lines, out)
	return out

func _resolve_trinity_cascade_loop_async() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: trinity cascade exceeded MAX_CASCADE_ITERATIONS (async).")
			break
		if _grid_has_floating_symbols():
			await _apply_gravity_and_refill(false)
		var lines: Array = _find_lines()
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		await _resolve_lines(lines)
		await _apply_gravity_and_refill(false)
		_emit_line_win_events(lines)
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		var line_win := _estimate_payout(lines)
		out["payout"] = int(out["payout"]) + line_win
		out["line_payout"] = int(out["line_payout"]) + line_win
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
		var fs_mods_sync: Dictionary = _item_fx.free_spins_mods(inventory.items)
		if free_spins.active and int(fs_mods_sync.get("cascade_payout_step", 0)) != 0:
			multiplier.add(int(fs_mods_sync.get("cascade_payout_step", 0)))
			_item_fx.note_param(inventory.items, &"free_spins", "cascade_payout_step")
			_flush_item_procs()
		_apply_board_count_bonus(out, true)
		_apply_glyph_payouts(lines, out)
		_refresh_multiplier_label()
	return out

func _resolve_trinity_cascade_loop_sync() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: trinity cascade exceeded MAX_CASCADE_ITERATIONS (sync).")
			break
		if _grid_has_floating_symbols():
			_settle_symbols_down_without_refill()
		var lines: Array = _find_lines()
		if lines.is_empty():
			break
		out["produced_any_win"] = true
		_resolve_lines_sync(lines)
		_apply_gravity_and_refill_sync(false)
		_emit_line_win_events(lines)
		out["cascade_drops"] = int(out["cascade_drops"]) + 1
		var line_win := _estimate_payout(lines)
		out["payout"] = int(out["payout"]) + line_win
		out["line_payout"] = int(out["line_payout"]) + line_win
		_note_paid_line_procs(lines)
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
		var fs_mods_sync: Dictionary = _item_fx.free_spins_mods(inventory.items)
		if free_spins.active and int(fs_mods_sync.get("cascade_payout_step", 0)) != 0:
			multiplier.add(int(fs_mods_sync.get("cascade_payout_step", 0)))
			_item_fx.note_param(inventory.items, &"free_spins", "cascade_payout_step")
			_flush_item_procs()
		_apply_board_count_bonus(out, true)
		_apply_glyph_payouts(lines, out)
	return out

func _make_power_ctx(potency: float = 1.0, power_id: StringName = &"") -> Dictionary:
	var pid: StringName = power_id
	if pid == &"":
		pid = powers.current_id()
	var charm: Dictionary = _item_fx.charm_mods(inventory.items, pid)
	return {
		"grid": grid,
		"rng": rng,
		"wild": wild_symbol,
		"low_pool": low_symbol_pool,
		"premium_pool": premium_symbol_pool,
		"multiplier": multiplier,
		"potency": potency,
		"diag_opts": _item_fx.diagonal_opts(inventory.items),
		"extra_set_chance": float(charm.get("extra_set_chance", 0.0)),
		"extra_wild_chance": float(charm.get("extra_wild_chance", 0.0)),
		"extra_transform_chance": float(charm.get("extra_transform_chance", 0.0)),
	}

func _resolve_lines(lines: Array) -> void:
	_release_item_pulses()
	_note_line_glyph_procs(lines)
	_note_paid_line_procs(lines)
	await _play_count_flash_for_lines(lines)
	_resolve_lines_impl(lines)
	_apply_meter_from_lines(lines)
	await _pause_visual(pause_after_cluster_resolve_sec)

func _resolve_lines_sync(lines: Array) -> void:
	_resolve_lines_impl(lines)
	_apply_meter_from_lines(lines)
	_emit_matched_symbols_from_lines(lines)

func _resolve_lines_impl(lines: Array) -> void:
	var to_clear: Dictionary = {}
	var wild_spawns: Dictionary = {}
	var diag_opts: Dictionary = _item_fx.diagonal_opts(inventory.items)
	var allow_diag_wilds: bool = bool(diag_opts.get("wilds", false)) or bool(diag_opts.get("full_lines", false))
	for line in lines:
		var cells: Array = line["cells"]
		for p in cells:
			to_clear[p] = true
		var axis := str(line.get("axis", ""))
		var can_wild := int(line["length"]) == 3 and not free_spins.active
		if axis == "d" and not allow_diag_wilds:
			can_wild = false
		if can_wild:
			var mid: Vector2i = cells[1]
			wild_spawns[mid] = true
	var all_cleared: Array = to_clear.keys()
	grid.clear_cells_and_emit(all_cleared)
	for p in wild_spawns.keys():
		if grid.get_cell(p) == null:
			grid.set_cell(p, wild_symbol)
			_spawn_item_extra_wilds(p)
	_maybe_fs_first_win_wild(lines)
	_refresh_cells_visual()

func _apply_gravity_and_refill(_allow_refill: bool = true) -> void:
	_pending_fall_moves.clear()
	_pending_spawns.clear()
	grid.apply_gravity()
	if _allow_refill and not _item_fx.should_skip_refill(inventory.items, _in_trinity_round, free_spins.active):
		pass
	await _play_pending_gravity_refill_fx()
	await _pause_visual(pause_after_gravity_refill_sec)

func _apply_gravity_and_refill_sync(_allow_refill: bool = true) -> void:
	_pending_fall_moves.clear()
	_pending_spawns.clear()
	grid.apply_gravity()
	if _allow_refill and not _item_fx.should_skip_refill(inventory.items, _in_trinity_round, free_spins.active):
		pass
	_refresh_cells_visual()

func _pause_visual(seconds: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if _dev_skip_visuals or seconds <= 0.0:
		await tree.process_frame
		return
	await CombatPace.await_seconds(seconds, _visual_skip_requested)


func _visual_skip_requested() -> bool:
	return _dev_skip_visuals

func _on_grid_populated() -> void:
	if _suppress_grid_populated_fx:
		if not enable_symbol_fx:
			_refresh_cells_visual()
		return
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	_play_board_swap_fx()

func _on_cells_cleared(_coords: Array) -> void:
	pass

func _on_symbols_fell(_moves: Array) -> void:
	_pending_fall_moves = _moves.duplicate(true)

func _on_symbols_spawned(_spawns: Array) -> void:
	_pending_spawns = _spawns.duplicate(true)

func _refresh_multiplier_label() -> void:
	if multiplier_label:
		var suffix := ""
		if free_spins.active:
			var progress := get_free_spin_counter()
			suffix = " (%d/%d)" % [progress.x, progress.y]
		multiplier_label.text = "Multiplier: %d×%s" % [multiplier.value, suffix]
	if _cached_multiplier_emit_value != multiplier.value:
		_cached_multiplier_emit_value = multiplier.value
		emit_signal("readouts_progressed")

func _refresh_round_winnings_label() -> void:
	if round_winnings_label:
		round_winnings_label.visible = false
		round_winnings_label.text = ""

func _ensure_symbol_slots() -> void:
	var total_slots := GridManager.COLS * GridManager.ROWS
	while grid_ui.get_child_count() < total_slots:
		grid_ui.add_child(SYMBOL_SLOT_SCENE.instantiate())

func _coord_to_index(coord: Vector2i) -> int:
	return coord.y * GridManager.COLS + coord.x

func _get_slot(coord: Vector2i) -> Node:
	var idx := _coord_to_index(coord)
	if idx < 0 or idx >= grid_ui.get_child_count():
		return null
	return grid_ui.get_child(idx)

func _ensure_slot_positions() -> void:
	if _slot_positions_ready:
		return
	await get_tree().process_frame
	_slot_positions_ready = true

func _slot_target_position(coord: Vector2i) -> Vector2:
	var slot := _get_slot(coord)
	if slot == null:
		return Vector2.ZERO
	return (slot as Control).position

func fit_to_viewport(viewport_size: Vector2) -> void:
	var min_dim: float = min(viewport_size.x, viewport_size.y)
	var cell_size: float = clamp(min_dim * 0.08 * GRID_VISUAL_SCALE, CELL_SIZE_MIN, CELL_SIZE_MAX)
	var sep_h := float(grid_ui.get_theme_constant("h_separation"))
	var sep_v := float(grid_ui.get_theme_constant("v_separation"))
	var grid_width: float = float(GridManager.COLS) * cell_size + float(GridManager.COLS - 1) * sep_h
	var grid_height: float = float(GridManager.ROWS) * cell_size + float(GridManager.ROWS - 1) * sep_v
	_grid_width_cached = grid_width
	_grid_height_cached = grid_height
	var grid_x: float = max((viewport_size.x - grid_width) * 0.5, GRID_EDGE_MARGIN)
	var total_height := 48.0 + grid_height + ROUND_WINNINGS_GAP + ROUND_WINNINGS_HEIGHT
	var usable_top: float = VIEWPORT_TOP_SAFE
	var usable_bottom: float = max(viewport_size.y - VIEWPORT_BOTTOM_SAFE, usable_top + total_height + GRID_EDGE_MARGIN)
	var usable_height: float = usable_bottom - usable_top
	var grid_y: float = usable_top + max((usable_height - total_height) * 0.5, 0.0)
	position = Vector2(grid_x, grid_y)
	if multiplier_label != null:
		multiplier_label.visible = false
	grid_ui.position = Vector2(0.0, 48.0)
	grid_ui.size = Vector2(grid_width, grid_height)
	_apply_slot_min_size(Vector2(cell_size, cell_size))
	if round_winnings_label != null:
		round_winnings_label.visible = false
	_layout_grid_fx_nodes()
	_slot_positions_ready = false

func fit_to_panel(
	panel_size: Vector2,
	bottom_inset: float = 12.0,
	align_grid_top: bool = false,
	fill_panel: bool = false,
) -> void:
	var safe_w: float = max(panel_size.x, 64.0)
	var safe_h: float = max(panel_size.y - bottom_inset, 64.0)
	var sep_h := float(grid_ui.get_theme_constant("h_separation"))
	var sep_v := float(grid_ui.get_theme_constant("v_separation"))
	var edge: float = 0.0 if fill_panel else GRID_EDGE_MARGIN
	var cell: Vector2
	if fill_panel:
		cell = Vector2(
			(safe_w - float(GridManager.COLS - 1) * sep_h) / float(GridManager.COLS),
			(safe_h - float(GridManager.ROWS - 1) * sep_v) / float(GridManager.ROWS)
		)
		cell.x = maxf(cell.x, CELL_SIZE_MIN)
		cell.y = maxf(cell.y, CELL_SIZE_MIN)
	else:
		var min_dim: float = min(safe_w - edge * 2.0, safe_h - edge * 2.0)
		var square: float = clamp(min_dim * 0.11 * GRID_VISUAL_SCALE, CELL_SIZE_MIN, CELL_SIZE_MAX)
		cell = Vector2(square, square)
	var grid_width: float = float(GridManager.COLS) * cell.x + float(GridManager.COLS - 1) * sep_h
	var grid_height: float = float(GridManager.ROWS) * cell.y + float(GridManager.ROWS - 1) * sep_v
	_grid_width_cached = grid_width
	_grid_height_cached = grid_height
	var grid_x: float = max((safe_w - grid_width) * 0.5, edge)
	var grid_y: float = edge
	if not align_grid_top:
		grid_y += max((safe_h - grid_height) * 0.5, 0.0)
	position = Vector2.ZERO
	if multiplier_label != null:
		multiplier_label.visible = false
	grid_ui.position = Vector2(grid_x, grid_y)
	grid_ui.size = Vector2(grid_width, grid_height)
	_apply_slot_min_size(cell)
	if round_winnings_label != null:
		round_winnings_label.visible = false
	_layout_grid_fx_nodes()
	_slot_positions_ready = false

func _layout_grid_fx_nodes() -> void:
	if grid_frame != null:
		grid_frame.position = grid_ui.position - Vector2(GRID_FRAME_OUTSET, GRID_FRAME_OUTSET)
		grid_frame.size = grid_ui.size + Vector2(GRID_FRAME_OUTSET, GRID_FRAME_OUTSET) * 2.0
	if grid_flash_overlay != null:
		grid_flash_overlay.position = grid_ui.position
		grid_flash_overlay.size = grid_ui.size
	if power_intro_layer != null:
		power_intro_layer.position = grid_ui.position
		power_intro_layer.size = grid_ui.size
	if power_intro_icon != null:
		var icon_dim: float = max(min(grid_ui.size.x, grid_ui.size.y) * POWER_INTRO_ICON_SIZE_RATIO, 32.0)
		var icon_size := Vector2(icon_dim, icon_dim)
		power_intro_icon.size = icon_size
		power_intro_icon.position = (grid_ui.size - icon_size) * 0.5
		power_intro_icon.pivot_offset = icon_size * 0.5
		power_intro_icon.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_layout_power_intro_fallback_label()
func _show_encounter_won_banner() -> void:

	return

func _hide_encounter_won_banner() -> void:
	return

func _play_round_winnings_win_glow() -> void:
	sfx_requested.emit(&"round_winnings")
	if _dev_skip_visuals:
		return
	if _winnings_popup_target == null or not is_instance_valid(_winnings_popup_target):
		return
	var label := _winnings_popup_target as Control
	if label == null:
		return
	if _round_winnings_glow_tween != null and _round_winnings_glow_tween.is_valid():
		_round_winnings_glow_tween.kill()
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE
	label.modulate = Color.WHITE
	_round_winnings_glow_tween = CombatPace.bind(create_tween())
	_round_winnings_glow_tween.set_parallel(true)
	_round_winnings_glow_tween.tween_property(label, "scale", Vector2(1.14, 1.14), 0.12)
	_round_winnings_glow_tween.tween_property(label, "modulate", Color(1.55, 1.55, 1.55), 0.12)
	_round_winnings_glow_tween.chain()
	_round_winnings_glow_tween.set_parallel(true)
	_round_winnings_glow_tween.tween_property(label, "scale", Vector2.ONE, 0.16)
	_round_winnings_glow_tween.tween_property(label, "modulate", Color.WHITE, 0.16)

func _hide_round_winnings_overlay(_immediate: bool = false) -> void:
	pass

func _apply_slot_min_size(cell_size: Vector2) -> void:
	for child in grid_ui.get_children():
		var slot := child as Control
		if slot != null:
			slot.custom_minimum_size = cell_size

func _cell_size_px() -> float:
	if grid_ui.get_child_count() == 0:
		return 32.0
	var slot := grid_ui.get_child(0) as Control
	if slot == null:
		return 32.0
	if slot.size.y > 0.0:
		return slot.size.y
	if slot.custom_minimum_size.y > 0.0:
		return slot.custom_minimum_size.y
	return 32.0

func _row_pitch_px() -> float:
	return _cell_size_px() + float(grid_ui.get_theme_constant("v_separation"))

func _play_board_swap_fx() -> void:
	if _dev_skip_visuals:
		_refresh_cells_visual()
		return
	_board_swap_fx_gen += 1
	var gen := _board_swap_fx_gen
	_board_swap_fx_active = true
	await _ensure_slot_positions()
	if gen != _board_swap_fx_gen:
		return


	grid_ui.clip_contents = true
	var pitch := _row_pitch_px()
	await _play_board_fall_off_fx(pitch)
	if gen == _board_swap_fx_gen:
		await _play_board_stream_in_fx(pitch)
	if gen != _board_swap_fx_gen:
		return
	grid_ui.clip_contents = false
	sfx_requested.emit(&"land")
	_refresh_cells_visual()
	_board_swap_fx_active = false

func _play_board_fall_off_fx(pitch: float) -> void:
	var travel_rows := float(GridManager.ROWS) + maxf(board_swap_fall_overshoot_cells, 0.0)
	var duration: float = maxf(travel_rows * board_swap_fall_cell_sec, 0.01)
	var max_total := 0.0
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			var slot := _get_slot(Vector2i(c, r))
			if slot == null or not slot.has_method("play_fall_off"):
				continue
			if slot.has_method("has_visible_symbol") and not bool(slot.call("has_visible_symbol")):
				continue
			var delay := float(c) * board_swap_fall_column_step_sec
			max_total = maxf(max_total, delay + duration)
			slot.call("play_fall_off", pitch * travel_rows, duration, delay)
	if max_total <= 0.0:
		return
	await _pause_visual(max_total)

func _play_board_stream_in_fx(pitch: float) -> void:
	var max_total := 0.0
	for c in GridManager.COLS:
		var travel_rows := float(GridManager.ROWS + c)
		var distance := pitch * travel_rows
		var duration: float = maxf(travel_rows * board_swap_fill_cell_sec, 0.01)
		max_total = maxf(max_total, duration)
		for r in GridManager.ROWS:
			var coord := Vector2i(c, r)
			var slot := _get_slot(coord)
			if slot == null:
				continue
			if slot.has_method("cancel_active_fx"):
				slot.call("cancel_active_fx")
			if slot.has_method("set_symbol"):
				slot.call("set_symbol", grid.cells[r][c] as SymbolDef)
			if slot.has_method("play_tube_in"):
				slot.call("play_tube_in", distance, duration)
	if max_total <= 0.0:
		return
	await _pause_visual(max_total)

func _await_board_swap_fx() -> void:
	var tree := get_tree()
	if tree == null:
		return
	while _board_swap_fx_active and not _dev_skip_visuals:
		await tree.process_frame

func get_feel() -> Node:
	return _feel


func is_goal_burst_playing() -> bool:
	return _goal_burst_playing


func play_goal_win_burst() -> void:
	_goal_burst_playing = true
	await _play_goal_win_burst()
	_goal_burst_playing = false


func _play_goal_win_burst() -> void:
	if _dev_skip_visuals or grid_ui == null:
		return
	if not _power_reduce_flashing():
		var any_eaten := false
		for child in grid_ui.get_children():
			if not child.has_method("play_power_act") or not child.has_method("icon_texture"):
				continue
			var tex: Texture2D = child.call("icon_texture") as Texture2D
			if tex == null:
				continue
			var is_win_skull := tex == WIN_SKULL or (
				not String(tex.resource_path).is_empty()
				and tex.resource_path == WIN_SKULL.resource_path
			)
			if is_win_skull:
				continue
			child.call("play_power_act", &"eat", tex, WIN_SKULL, 0.48, false)
			any_eaten = true
		if any_eaten:
			await _pause_visual(0.48)
	for child in grid_ui.get_children():
		if child.has_method("show_win_skull"):
			child.call("show_win_skull", WIN_SKULL)
		if child.has_method("play_count_flash"):
			child.call("play_count_flash", 0.4, 0.85)
	var tree := get_tree()
	if tree == null:
		return
	await _pause_visual(0.4)
	if tree != null:
		await _pause_visual(0.25)


func await_victory_confirm() -> void:
	if _dev_skip_visuals:
		return
	if DisplayServer.get_name() == "headless":
		return
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.4).timeout
	while tree != null:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("dialogue_advance"):
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		await tree.process_frame


func _notify_free_spins_entry() -> void:
	sfx_requested.emit(&"free_spins")
	if _feel != null:
		_feel.play_banner("FREE SPINS", 1.8, 0.78)


func _notify_free_spins_entry_async() -> void:
	sfx_requested.emit(&"free_spins")
	if _feel != null and not _dev_skip_visuals:
		await _feel.play_banner("FREE SPINS", 1.8, 0.78)


func _play_count_flash_for_lines(lines: Array) -> void:
	_emit_matched_symbols_from_lines(lines)
	_feel_on_line_wins(lines)
	if not enable_symbol_fx:
		_show_win_popups_for_lines(lines)
		emit_signal("readouts_progressed")
		return
	var flash_index := 0
	for line in lines:
		var cells: Array = line["cells"]
		var payout_text := _format_currency_from_cents(_line_payout_cents(line))
		for p in cells:
			var coord := p as Vector2i
			var slot := _get_slot(coord)
			if slot == null:
				continue
			var delay := fx_stagger_sec * flash_index
			if slot.has_method("play_count_flash"):
				slot.call("play_count_flash", count_flash_duration_sec, 0.55, delay)
			emit_signal("readouts_progressed")
			flash_index += 1
		if not payout_text.is_empty():
			var popup_coord := _line_popup_anchor_coord(cells)
			var popup_slot := _get_slot(popup_coord)
			if popup_slot != null and popup_slot.has_method("play_win_popup"):
				var popup_delay: float = fx_stagger_sec * float(max(flash_index - 1, 0))
				var throw_target := _get_winnings_popup_target_global()
				var payout_cents := _line_payout_cents(line)
				_wire_win_popup_border_touch(popup_slot, payout_cents)
				popup_slot.call(
					"play_win_popup",
					"+%s" % payout_text,
					count_flash_duration_sec + 0.2,
					popup_delay,
					throw_target,
					_get_winnings_popup_target_rect_global(),
					payout_cents,
				)
	await _pause_visual(count_flash_duration_sec + fx_stagger_sec * max(flash_index - 1, 0))

func _show_win_popups_for_lines(lines: Array) -> void:
	for line in lines:
		var payout_text := _format_currency_from_cents(_line_payout_cents(line))
		if payout_text.is_empty():
			continue
		var cells: Array = line["cells"]
		var popup_coord := _line_popup_anchor_coord(cells)
		var popup_slot := _get_slot(popup_coord)
		if popup_slot != null and popup_slot.has_method("play_win_popup"):
			var throw_target := _get_winnings_popup_target_global()
			var payout_cents := _line_payout_cents(line)
			_wire_win_popup_border_touch(popup_slot, payout_cents)
			popup_slot.call(
				"play_win_popup",
				"+%s" % payout_text,
				0.01,
				0.0,
				throw_target,
				_get_winnings_popup_target_rect_global(),
				payout_cents,
			)

func _get_winnings_popup_target_global() -> Vector2:
	if _winnings_popup_target == null or not is_instance_valid(_winnings_popup_target):
		return Vector2.INF
	return _winnings_popup_target.get_global_rect().get_center()

func _get_winnings_popup_target_rect_global() -> Rect2:
	if _winnings_popup_target == null or not is_instance_valid(_winnings_popup_target):
		return Rect2()
	return _winnings_popup_target.get_global_rect()

func _wire_win_popup_border_touch(popup_slot: Node, payout_cents: int) -> void:
	if payout_cents <= 0:
		return
	if not popup_slot.has_signal("win_popup_border_touched"):
		return
	var handler := Callable(self, "_on_win_popup_border_touched")
	if popup_slot.is_connected("win_popup_border_touched", handler):
		popup_slot.disconnect("win_popup_border_touched", handler)
	popup_slot.connect("win_popup_border_touched", handler, CONNECT_ONE_SHOT)

func _on_win_popup_border_touched(payout_cents: int) -> void:
	if payout_cents <= 0:
		return
	emit_signal("winnings_popup_border_touched", {"payout_cents": payout_cents})

func _line_popup_anchor_coord(cells: Array) -> Vector2i:
	if cells.is_empty():
		return Vector2i(-1, -1)
	var center := Vector2.ZERO
	for p in cells:
		var coord := p as Vector2i
		center += Vector2(float(coord.x), float(coord.y))
	center /= float(cells.size())
	var best := cells[0] as Vector2i
	var best_dist := INF
	for p in cells:
		var coord := p as Vector2i
		var dist := Vector2(float(coord.x), float(coord.y)).distance_squared_to(center)
		if dist < best_dist:
			best_dist = dist
			best = coord
	return best

func _emit_line_win_events(lines: Array) -> void:
	for line in lines:
		var payout_cents := _line_payout_cents(line)
		if payout_cents <= 0:
			continue
		emit_signal("line_win_resolved", _line_win_event_from_line(line, payout_cents))

func _line_win_event_from_line(line: Dictionary, payout_cents: int) -> Dictionary:
	var symbol_id: StringName = line.get("symbol_id", &"")
	if symbol_id == &"wild" and wild_symbol != null:
		symbol_id = wild_symbol.id
	var sd := _symbols_by_id.get(symbol_id, null) as SymbolDef
	var symbol_name := String(symbol_id)
	var symbol_value := 0.0
	if sd != null:
		var dn := sd.display_name.strip_edges()
		if not dn.is_empty():
			symbol_name = dn
		var line_length: int = int(line.get("length", 0))
		symbol_value = sd.payout_multiplier_for_length(line_length)
	var tex: Texture2D = sd.texture if sd != null else null
	return {
		"symbol_id": symbol_id,
		"symbol_name": symbol_name,
		"texture": tex,
		"length": int(line.get("length", 0)),
		"bet": int(total_bet),
		"symbol_value": symbol_value,
		"cascade_multiplier": multiplier.value,
		"payout_cents": payout_cents,
	}

func _start_spin_with_new_grid() -> void:
	if not _maybe_reseed_tutorial_script():
		_maybe_reseed_tutorial_last_spin()
	_item_fx.reset_spin()
	_refresh_spin_weights()
	var used_before := _spins_used
	var bankroll_before := _bankroll_cents
	var r1_free: bool = _item_fx.first_paid_spin_free(inventory.items) and used_before == 0
	if not r1_free:
		_bankroll_cents -= _to_cents(total_bet)
		var refund := _item_fx.first_paid_spin_refund(inventory.items)
		if refund > 0.0 and used_before == 0:
			_bankroll_cents += _to_cents(total_bet * refund)
			_clamp_bankroll()
			_item_fx.note_effect(inventory.items, &"first_paid_spin_refund")
			_flush_item_procs()
	_bets_used_cents += maxi(bankroll_before - _bankroll_cents, 0)
	_item_fx.note_paid_spin_passives(inventory.items)
	_flush_item_procs()

	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_item_fx.roll_glyphs(inventory.items, rng)
	_flush_item_procs()
	if not enable_symbol_fx:
		_refresh_cells_visual()
	_spins_used += 1
	_lifetime_spins_used += 1
	emit_signal("spin_started", _current_seed)
	sfx_requested.emit(&"spin")
	emit_signal("readouts_progressed")

func _begin_spin_round() -> void:
	_hold_item_pulses = true
	if free_spins.active:

		_free_spin_opened_fresh = false
		if free_spins.spins_remaining < free_spins.spins_awarded_total:
			_repopulate_grid_handoff("free_spin_next")
			_free_spin_opened_fresh = true
		_free_spin_open_ids = grid.snapshot_ids()
		_free_spin_open_had_lines = not _find_lines().is_empty()
		_item_fx.reset_spin()
		_item_fx.roll_glyphs(inventory.items, rng)
		_flush_item_procs()
		emit_signal("spin_started", _current_seed)
		sfx_requested.emit(&"spin")
		emit_signal("readouts_progressed")
		return
	_clear_free_spin_open()
	_start_spin_with_new_grid()

func _clear_free_spin_open() -> void:
	_free_spin_opened_fresh = false
	_free_spin_open_ids = ""
	_free_spin_open_had_lines = false

func _stamp_free_spin_open(spin_summary: Dictionary) -> void:
	if not free_spins.active:
		return
	spin_summary["free_spin_opened_fresh"] = _free_spin_opened_fresh
	spin_summary["free_spin_open_ids"] = _free_spin_open_ids
	spin_summary["free_spin_open_had_lines"] = _free_spin_open_had_lines

func _repopulate_grid_handoff(_handoff: String) -> void:
	_suppress_grid_populated_fx = true
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_suppress_grid_populated_fx = false
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	_play_board_swap_fx()

func _repopulate_grid_handoff_async(_handoff: String) -> void:
	_suppress_grid_populated_fx = true
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_suppress_grid_populated_fx = false
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	await _play_board_swap_fx()

func _can_afford_spin() -> bool:
	return _bankroll_cents >= _to_cents(total_bet)


func _maybe_reseed_tutorial_script() -> bool:
	if _spins_used >= _tutorial_script_seeds.size() or free_spins.active:
		return false
	var scripted_seed := _tutorial_script_seeds[_spins_used]
	rng.seed(scripted_seed)
	_current_seed = scripted_seed
	powers.randomize_start(rng)
	return true

func _maybe_reseed_tutorial_last_spin() -> void:
	if not _tutorial_last_spin_lock:
		return
	if is_chip_bar_goal_complete():
		return
	if not is_last_affordable_paid_spin():
		return
	rng.seed(_tutorial_last_spin_seed)
	_current_seed = _tutorial_last_spin_seed
	powers.randomize_start(rng)

func _is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"

func _add_round_winnings(amount_cents: int) -> void:
	if amount_cents <= 0:
		return
	_round_winnings_cents += amount_cents
	_encounter_goal_winnings_cents += amount_cents
	if _feature_hold != &"":
		_feature_held_cents += amount_cents
	_refresh_round_winnings_label()
	emit_signal("readouts_progressed")

func _begin_feature_winnings_hold(kind: StringName) -> void:
	if _feature_hold != &"" and _feature_hold != kind:
		_commit_feature_hold()
	_feature_hold = kind
	_feature_held_cents = 0
	_round_winnings_cents = 0
	_refresh_round_winnings_label()
	emit_signal("round_winnings_hold_started")
	emit_signal("readouts_progressed")

func _start_free_spin_winnings_hold() -> void:
	_begin_feature_winnings_hold(&"free")

func _begin_vice_winnings_hold() -> void:
	if _feature_hold == &"free":
		_commit_feature_hold()
	_feature_hold = &"vice"
	_feature_held_cents = 0

func _commit_feature_hold() -> void:
	if _feature_hold == &"":
		return
	_feature_held_cents = 0
	_feature_hold = &""
	emit_signal("readouts_progressed")

func _grant_free_spin_meter_bonus() -> void:
	if not free_spins.active or not meter.is_full():
		return
	var before := free_spins.spins_awarded_total
	free_spins.award_from_meter()
	meter.reset()
	var added := free_spins.spins_awarded_total - before
	if added > 0:
		emit_signal("free_spins_bonus_granted", added)
		emit_signal("readouts_progressed")

func _play_pending_gravity_refill_fx() -> void:
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	await _ensure_slot_positions()
	var max_total := 0.0
	for move in _pending_fall_moves:
		var from: Vector2i = move.get("from", Vector2i(-1, -1))
		var to: Vector2i = move.get("to", Vector2i(-1, -1))
		var from_slot := _get_slot(from)
		var to_slot := _get_slot(to)
		if from_slot == null or to_slot == null:
			continue
		var moved_sym := grid.get_cell(to)
		if from_slot.has_method("set_symbol"):
			from_slot.call("set_symbol", null)
		if to_slot.has_method("set_symbol"):
			to_slot.call("set_symbol", moved_sym)
		var from_pos := _slot_target_position(from)
		var to_pos := _slot_target_position(to)
		var distance_rows: int = abs(to.y - from.y)
		var duration := drop_duration_sec + float(distance_rows) * 0.03
		max_total = max(max_total, duration)
		var fall_delay := float(to.x) * cascade_column_step_sec
		max_total = max(max_total, fall_delay + duration)
		if to_slot.has_method("play_drop"):
			to_slot.call("play_drop", from_pos, to_pos, duration, fall_delay)
	for spawn in _pending_spawns:
		var coord: Vector2i = spawn.get("coord", Vector2i(-1, -1))
		var slot := _get_slot(coord)
		if slot == null:
			continue
		var sym: SymbolDef = spawn.get("sym", null)
		if slot.has_method("set_symbol"):
			slot.call("set_symbol", sym)
		var to_pos := _slot_target_position(coord)
		var rows_from_top := coord.y + 1
		var from_pos := to_pos - Vector2(0.0, float(rows_from_top) * _cell_size_px())
		var delay := float(coord.x) * cascade_column_step_sec
		var duration := spawn_drop_duration_sec + float(rows_from_top) * 0.02
		max_total = max(max_total, delay + duration)
		if slot.has_method("play_drop"):
			slot.call("play_drop", from_pos, to_pos, duration, delay)
	if max_total > 0.0:
		await _pause_visual(max_total)
	sfx_requested.emit(&"land")
	_refresh_cells_visual()

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
		"line_payout": 0,
		"clear_bonus_payout": 0,
		"power_triggered": false,
		"grid_cleared": false,
	}

func _merge_spin_summary(base: Dictionary, extra: Dictionary) -> void:
	base["produced_any_win"] = bool(base["produced_any_win"]) or bool(extra.get("produced_any_win", false))
	base["cascade_drops"] = int(base["cascade_drops"]) + int(extra.get("cascade_drops", 0))
	base["wilds_placed"] = int(base["wilds_placed"]) + int(extra.get("wilds_placed", 0))
	base["payout"] = int(base["payout"]) + int(extra.get("payout", 0))
	base["line_payout"] = int(base["line_payout"]) + int(extra.get("line_payout", 0))
	base["clear_bonus_payout"] = int(base["clear_bonus_payout"]) + int(extra.get("clear_bonus_payout", 0))
	base["power_triggered"] = bool(base["power_triggered"]) or bool(extra.get("power_triggered", false))
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
		total += _line_payout_cents(line)
	return total

func _line_payout_cents(line: Dictionary) -> int:
	var symbol_id: StringName = line.get("symbol_id", &"")
	if symbol_id == &"wild" and wild_symbol != null:
		symbol_id = wild_symbol.id
	var sd := _symbols_by_id.get(symbol_id, null) as SymbolDef
	if sd == null:
		return 0
	var line_length: int = int(line.get("length", 0))
	var payout_multiplier: float = sd.payout_multiplier_for_length(line_length)
	if payout_multiplier <= 0.0:
		return 0
	var item_scalar := 1.0 + _get_item_payout_scalar() + _line_item_bonus(line)
	return _to_cents(
		total_bet * payout_multiplier * float(multiplier.value) * item_scalar * BASELINE_PAYOUT_SCALAR / PAYTABLE_SCALE
	)

func _to_cents(amount: float) -> int:
	return int(round(amount))

func _dev_fill_meter_for_guarantee_trinity() -> void:
	if not OS.is_debug_build():
		return

	if not _dev_guarantee_trinity and not _dev_guarantee_fs_clear:
		return
	if free_spins.active:
		return
	var before := meter.sections_filled
	meter.sections_filled = 3
	if before != 3:
		emit_signal("premium_meter_changed", before, 3)
		emit_signal("readouts_progressed")

func _dev_clear_non_wild_for_fs_guarantee() -> void:
	if not OS.is_debug_build() or not _dev_guarantee_fs_clear:
		return
	if not _in_trinity_round:
		return
	var coords: Array = []
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			var sym: SymbolDef = grid.cells[r][c]
			if sym == null:
				continue
			if sym.tier == SymbolDef.Tier.WILD:
				continue
			coords.append(Vector2i(c, r))
	if coords.is_empty():
		return
	grid.clear_cells_and_emit(coords)
	_refresh_cells_visual()

func _apply_dev_payout_override(spin_summary: Dictionary) -> void:
	if not OS.is_debug_build() or not _dev_guarantee_payout_1000x:
		return
	var forced := _to_cents(1000.0 * total_bet)
	var already := _round_winnings_cents
	var delta := forced - already
	spin_summary["payout"] = forced
	_round_winnings_cents = forced
	if delta != 0:
		_encounter_goal_winnings_cents = maxi(_encounter_goal_winnings_cents + delta, 0)
	if _feature_hold != &"":
		_feature_held_cents = forced
	_refresh_round_winnings_label()
	emit_signal("readouts_progressed")

func _get_item_payout_scalar() -> float:
	var total := _item_fx.paid_spin_payout_scalar(inventory.items, _spins_used)
	total += _item_fx.sealed_payout(inventory.items, _is_regular_spin_mode())
	return total

func _format_currency_from_cents(amount_cents: int) -> String:
	if amount_cents <= 0:
		return ""
	return str(amount_cents)

func _summarize_lines(lines: Array) -> Array:
	var out: Array = []
	for line in lines:
		var cells: Array = line.get("cells", [])
		var coords: Array = []
		for p in cells:
			var v := p as Vector2i
			coords.append("%d:%d" % [v.x, v.y])
		out.append(
			{
				"symbol_id": String(line.get("symbol_id", &"")),
				"axis": String(line.get("axis", "")),
				"length": int(line.get("length", 0)),
				"cells": coords,
			}
		)
	return out

func _should_trigger_girl_power() -> bool:
	return rng.randf() <= _item_fx.girl_power_chance(inventory.items, girl_power_chance)

func _try_free_spin_power_async(spin_summary: Dictionary) -> void:
	if not free_spins.active or not _free_spin_power_should_fire():
		return
	_state = State.POWER
	var power_id := free_spins.chosen_power
	await _play_power_intro_flash_async(power_id)
	_trigger_item_power(power_id, 1.0, false, false)
	spin_summary["power_triggered"] = true
	await _play_power_act_fx(_power_fx_log)
	await _apply_gravity_and_refill(false)
	var after_power: Dictionary = await _resolve_cascade_loop_async()
	_merge_spin_summary(spin_summary, after_power)

func _try_free_spin_power_sync(spin_summary: Dictionary) -> void:
	if not free_spins.active or not _free_spin_power_should_fire():
		return
	_state = State.POWER
	var power_id := free_spins.chosen_power
	_trigger_item_power(power_id, 1.0, false, false)
	spin_summary["power_triggered"] = true
	_refresh_cells_visual()
	_apply_gravity_and_refill_sync(false)
	var after_power: Dictionary = _resolve_cascade_loop_sync()
	_merge_spin_summary(spin_summary, after_power)

func _free_spin_power_should_fire() -> bool:
	if _find_lines().is_empty():
		return true
	return _should_trigger_girl_power()

func _reset_premium_meter_after_paid_spin() -> void:
	if free_spins.active:
		return
	meter.reset()

func _apply_meter_from_lines(lines: Array) -> void:
	var mods: Dictionary = _item_fx.meter_mods(inventory.items)
	meter.allow_overflow = bool(mods.get("overflow", false))
	var before_sections := meter.sections_filled
	for line in lines:
		var axis := str(line.get("axis", ""))
		var is_premium := _line_is_premium(line)
		var diag_frac := float(mods.get("diag_meter_frac", 0.0))
		if not is_premium and not (axis == "d" and diag_frac > 0.0):
			continue
		var base_add := meter.sections_for_length(int(line["length"]))
		var add := base_add + int(mods.get("length_boost", 0))
		if add != base_add:
			_item_fx.note_param(inventory.items, &"premium_meter", "length_boost")
		if bool(mods.get("first_fills_section", false)) and _item_fx.first_premium_this_spin:
			add = 1
			_item_fx.note_param(inventory.items, &"premium_meter", "first_fills_section")
		if bool(mods.get("any_line_fills", false)) and add < 3:
			add = 3
			_item_fx.note_param(inventory.items, &"premium_meter", "any_line_fills")
		var pre_mult := add
		add = int(round(float(add) * float(mods.get("gain_mult", 1.0))))
		if add != pre_mult:
			_item_fx.note_param(inventory.items, &"premium_meter", "gain_mult")
		if _item_fx.first_premium_this_spin and int(mods.get("first_line_bonus", 0)) != 0:
			add += int(mods.get("first_line_bonus", 0))
			_item_fx.note_param(inventory.items, &"premium_meter", "first_line_bonus")
		if _line_has_wild(line) and int(mods.get("wild_extra", 0)) != 0:
			add += int(mods.get("wild_extra", 0))
			_item_fx.note_param(inventory.items, &"premium_meter", "wild_extra")
		if axis == "d" and diag_frac > 0.0:
			_item_fx.meter_frac_accum += float(add) * diag_frac
			add = int(floor(_item_fx.meter_frac_accum))
			_item_fx.meter_frac_accum -= float(add)
		meter.add_sections(add)
		_item_fx.first_premium_this_spin = false
	_flush_item_procs()
	var after_sections := meter.sections_filled
	if after_sections != before_sections:
		emit_signal("premium_meter_changed", before_sections, after_sections)
		emit_signal("readouts_progressed")

func _line_is_premium(line: Dictionary) -> bool:
	var symbol_id: StringName = line.get("symbol_id", &"")
	return _premium_symbol_ids.has(symbol_id)

func _is_grid_empty() -> bool:
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			if grid.cells[r][c] != null:
				return false
	return true

func _is_grid_cleared_for_current_mode() -> bool:
	if free_spins.active:
		return _count_non_wild_symbols() == 0
	return _is_grid_empty()

func _count_non_wild_symbols() -> int:
	var count := 0
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			var sym: SymbolDef = grid.cells[r][c]
			if sym == null:
				continue
			if sym.tier == SymbolDef.Tier.WILD:
				continue
			count += 1
	return count

func _grid_has_floating_symbols() -> bool:
	for c in GridManager.COLS:
		for r in range(GridManager.ROWS - 1):
			if grid.cells[r][c] != null and grid.cells[r + 1][c] == null:
				return true
	return false

func _settle_symbols_down_without_refill() -> void:
	var guard := GridManager.ROWS
	while guard > 0 and _grid_has_floating_symbols():
		grid.apply_gravity()
		guard -= 1
	_refresh_cells_visual()

func _pick_power_for_current_spin() -> StringName:
	if not free_spins.active:
		return powers.current_id()
	var order: Array[StringName] = [&"bloody_hand", &"alcohol", &"cigarette"]
	for power_id in order:
		if not free_spins.has_used_power(power_id):
			powers.set_current_id(power_id)
			return power_id
	var fallback := powers.current_id()
	powers.set_current_id(fallback)
	return fallback

func _play_meter_full_transition_async() -> void:
	emit_signal("meter_full_transition_started")
	emit_signal("readouts_progressed")
	sfx_requested.emit(&"trinity")
	if _feel != null and not _dev_skip_visuals:
		await _feel.play_banner("VICE ROUND", 1.8, 0.82, false, grid_ui)
		_feel.highlight_power(powers.current_id())
	vice_banner_finished.emit()
	if _dev_skip_visuals or not enable_transition_fx:
		await _pause_visual(pause_after_power_sec * 0.6)
		return
	var border_target := Color(1.0, 1.0, 1.0, 1.0)
	var border_wait_sec: float = maxf(grid_border_pulse_duration_sec, 0.05)
	if grid_frame != null:
		_kill_tween(_grid_border_tween)
		_grid_border_tween = CombatPace.bind(create_tween())
		_grid_border_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_grid_border_tween.tween_property(grid_frame, "border_color", border_target, border_wait_sec)
	for i in maxi(grid_flash_count, 1):
		await _play_grid_white_flash_async(grid_flash_duration_sec, grid_flash_peak_alpha)


	if grid_frame != null and _grid_border_tween != null and is_instance_valid(_grid_border_tween):
		await _pause_visual(border_wait_sec)
	await _pause_visual(meter_handoff_pause_sec)

func _play_meter_full_transition_sync() -> void:
	emit_signal("meter_full_transition_started")
	emit_signal("readouts_progressed")

func _play_grid_white_flash_async(duration: float, peak_alpha: float) -> void:
	if grid_flash_overlay == null:
		await _pause_visual(duration)
		return
	_kill_tween(_grid_flash_tween)
	grid_flash_overlay.visible = true
	grid_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	var half: float = max(duration * 0.5, 0.04)
	_grid_flash_tween = CombatPace.bind(create_tween())
	_grid_flash_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_grid_flash_tween.tween_property(grid_flash_overlay, "color:a", clampf(peak_alpha, 0.0, 1.0), half)
	_grid_flash_tween.set_ease(Tween.EASE_IN)
	_grid_flash_tween.tween_property(grid_flash_overlay, "color:a", 0.0, half)
	await _grid_flash_tween.finished
	if is_instance_valid(grid_flash_overlay):
		grid_flash_overlay.visible = false
		grid_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

func _power_display_name_for(power_id: StringName, sym: SymbolDef) -> String:
	if sym != null:
		var dn: String = sym.display_name.strip_edges()
		if not dn.is_empty():
			return dn
	return String(power_id).capitalize()

func _ensure_power_intro_fallback_label() -> void:
	if _power_intro_fallback_label != null and is_instance_valid(_power_intro_fallback_label):
		return
	if power_intro_layer == null:
		return
	var lb := Label.new()
	lb.name = "PowerIntroFallbackLabel"
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	lb.add_theme_font_size_override("font_size", 22)
	lb.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	lb.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	lb.add_theme_constant_override("outline_size", 2)
	lb.visible = false
	power_intro_layer.add_child(lb)
	_power_intro_fallback_label = lb

func _layout_power_intro_fallback_label() -> void:
	if _power_intro_fallback_label == null or not is_instance_valid(_power_intro_fallback_label):
		return
	if power_intro_icon == null:
		return
	_power_intro_fallback_label.position = power_intro_icon.position
	_power_intro_fallback_label.size = power_intro_icon.size
	_power_intro_fallback_label.pivot_offset = power_intro_icon.pivot_offset

func _play_power_intro_flash_async(power_id: StringName) -> void:
	if _dev_skip_visuals:
		return
	if not enable_power_intro_fx or power_intro_layer == null or power_intro_icon == null:
		return
	sfx_requested.emit(&"power")
	_power_sfx_emitted = true
	var sym := _power_symbol_by_id.get(power_id, null) as SymbolDef
	var intro_texture: Texture2D = sym.texture_for_power_intro() if sym != null else null
	var display_text := _power_display_name_for(power_id, sym)
	var use_texture := intro_texture != null
	if not use_texture and display_text.is_empty():
		return
	_ensure_power_intro_fallback_label()
	_kill_tween(_power_intro_tween)
	var target: Control = power_intro_icon
	if use_texture:
		if _power_intro_fallback_label != null:
			_power_intro_fallback_label.visible = false
		power_intro_icon.visible = true
		power_intro_icon.texture = intro_texture
		target = power_intro_icon
	else:
		power_intro_icon.visible = false
		power_intro_icon.texture = null
		_power_intro_fallback_label.text = display_text
		_power_intro_fallback_label.visible = true
		_layout_power_intro_fallback_label()
		target = _power_intro_fallback_label
	power_intro_layer.visible = true
	target.modulate = Color(1.0, 1.0, 1.0, 0.0)
	target.scale = Vector2(0.4, 0.4)
	if power_intro_glow != null:
		power_intro_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	var scale_in: float = max(power_intro_scale_in_sec, 0.05)
	var hold: float = max(power_intro_hold_sec, 0.0)
	var scale_out: float = max(power_intro_scale_out_sec, 0.05)
	var peak: float = max(power_intro_peak_scale, 1.0)
	_power_intro_tween = CombatPace.bind(create_tween())
	_power_intro_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_power_intro_tween.tween_property(target, "scale", Vector2(peak, peak), scale_in)
	_power_intro_tween.parallel().tween_property(target, "modulate:a", 1.0, scale_in * 0.8)
	if power_intro_glow != null:
		_power_intro_tween.parallel().tween_property(power_intro_glow, "color:a", clampf(power_intro_glow_alpha, 0.0, 1.0), scale_in)
	if hold > 0.0:
		_power_intro_tween.tween_interval(hold)
	_power_intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_power_intro_tween.tween_property(target, "scale", Vector2(0.6, 0.6), scale_out)
	_power_intro_tween.parallel().tween_property(target, "modulate:a", 0.0, scale_out)
	if power_intro_glow != null:
		_power_intro_tween.parallel().tween_property(power_intro_glow, "color:a", 0.0, scale_out)
	await _power_intro_tween.finished
	if is_instance_valid(power_intro_layer):
		power_intro_layer.visible = false
	if is_instance_valid(power_intro_icon):
		power_intro_icon.visible = true
		power_intro_icon.scale = Vector2(0.4, 0.4)
		power_intro_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
		power_intro_icon.texture = null
	if _power_intro_fallback_label != null and is_instance_valid(_power_intro_fallback_label):
		_power_intro_fallback_label.visible = false
		_power_intro_fallback_label.scale = Vector2(0.4, 0.4)
		_power_intro_fallback_label.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _refresh_grid_border_for_state() -> void:
	if grid_frame == null:
		return
	var target := Color(1.0, 1.0, 1.0, 1.0) if free_spins.active else _default_grid_border_color
	if grid_frame.border_color.is_equal_approx(target):
		return
	_kill_tween(_grid_border_tween)
	if not is_inside_tree() or not enable_transition_fx:
		grid_frame.border_color = target
		return
	_grid_border_tween = CombatPace.bind(create_tween())
	_grid_border_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grid_border_tween.tween_property(grid_frame, "border_color", target, max(grid_border_pulse_duration_sec * 0.6, 0.08))

func _kill_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()

func _trinity_first_miss_extra_spin_count() -> int:
	var extra_n := int(_item_fx.trinity_mods(inventory.items).get("first_miss_extra_spins", 0))
	if extra_n <= 0:
		return 0
	if not _find_lines().is_empty():
		return 0
	return extra_n


func _grant_trinity_first_miss_extra_spins_sync(out: Dictionary, chosen: StringName) -> bool:
	var extra_n := _trinity_first_miss_extra_spin_count()
	if extra_n <= 0:
		return false
	_item_fx.note_param(inventory.items, &"trinity_run", "first_miss_extra_spins")
	_flush_item_procs()
	for _i in extra_n:
		_repopulate_grid_handoff("trinity_first_miss")
		var extra := _resolve_trinity_cascade_loop_sync()
		_merge_spin_summary(out, extra)
		_apply_trinity_spin_followup_sync(out, extra, chosen)
		_dev_clear_non_wild_for_fs_guarantee()
		if _count_non_wild_symbols() == 0:
			_pending_free_spins = true
			_finish_trinity_round()
			return true
	return false


func _grant_trinity_first_miss_extra_spins_async(out: Dictionary, chosen: StringName) -> bool:
	var extra_n := _trinity_first_miss_extra_spin_count()
	if extra_n <= 0:
		return false
	_item_fx.note_param(inventory.items, &"trinity_run", "first_miss_extra_spins")
	_flush_item_procs()
	for _i in extra_n:
		await _repopulate_grid_handoff_async("trinity_first_miss")
		var extra := await _resolve_trinity_cascade_loop_async()
		_merge_spin_summary(out, extra)
		await _apply_trinity_spin_followup_async(out, extra, chosen)
		_dev_clear_non_wild_for_fs_guarantee()
		if _count_non_wild_symbols() == 0:
			_pending_free_spins = true
			_finish_trinity_round()
			return true
	return false


func _await_vice_entry_gate() -> void:
	var tree := get_tree()
	while not vice_entry_gate_open and tree != null and is_inside_tree():
		await tree.process_frame


func _run_trinity_round_async() -> Dictionary:
	var out := _empty_spin_summary()
	meter.saved_active_power = powers.current_id()
	var chosen: StringName = meter.saved_active_power
	multiplier.reset()
	_refresh_multiplier_label()
	_in_trinity_round = true
	_begin_vice_winnings_hold()
	_music_notify_trinity()
	_item_fx.trinity_win_scalar_accum = 0.0
	_item_fx.trinity_first_dead_done = false
	var tmods: Dictionary = _item_fx.trinity_mods(inventory.items)
	await _play_meter_full_transition_async()
	await _await_vice_entry_gate()
	await _repopulate_grid_handoff_async("trinity_entry")
	if await _grant_trinity_first_miss_extra_spins_async(out, chosen):
		return out
	var order: Array[StringName] = [&"bloody_hand", &"alcohol", &"cigarette"]
	for id in order:
		powers.set_current_id(id)
		await _play_power_intro_flash_async(id)
		_open_power_fx_log()
		_trigger_item_power(id, 1.0, false, false)
		_maybe_trinity_crucible(id, tmods)
		var fx_log := _power_fx_log.duplicate()
		_close_power_fx_log()
		out["power_triggered"] = true
		await _play_power_act_fx(fx_log)
		var post_power := await _resolve_trinity_cascade_loop_async()
		_merge_spin_summary(out, post_power)
		await _apply_trinity_spin_followup_async(out, post_power, chosen)
		_dev_clear_non_wild_for_fs_guarantee()
		if _count_non_wild_symbols() == 0:
			_pending_free_spins = true
			break
	_finish_trinity_round()
	return out

func _run_trinity_round_sync() -> Dictionary:
	var out := _empty_spin_summary()
	meter.saved_active_power = powers.current_id()
	var chosen: StringName = meter.saved_active_power
	multiplier.reset()
	_in_trinity_round = true
	_begin_vice_winnings_hold()
	_music_notify_trinity()
	_item_fx.trinity_win_scalar_accum = 0.0
	_item_fx.trinity_first_dead_done = false
	var tmods: Dictionary = _item_fx.trinity_mods(inventory.items)
	_play_meter_full_transition_sync()
	_repopulate_grid_handoff("trinity_entry")
	if _grant_trinity_first_miss_extra_spins_sync(out, chosen):
		return out
	var order: Array[StringName] = [&"bloody_hand", &"alcohol", &"cigarette"]
	for id in order:
		powers.set_current_id(id)
		_trigger_item_power(id, 1.0, false, false)
		_maybe_trinity_crucible(id, tmods)
		out["power_triggered"] = true
		_refresh_cells_visual()
		var post_power := _resolve_trinity_cascade_loop_sync()
		_merge_spin_summary(out, post_power)
		_apply_trinity_spin_followup_sync(out, post_power, chosen)
		_dev_clear_non_wild_for_fs_guarantee()
		if _count_non_wild_symbols() == 0:
			_pending_free_spins = true
			break
	_finish_trinity_round()
	return out

func _emit_matched_symbols_from_lines(lines: Array) -> void:
	if lines.is_empty():
		return
	var entries: Array = []
	var seen: Dictionary = {}
	for line in lines:
		var symbol_id: StringName = line.get("symbol_id", &"")
		if symbol_id == &"wild" and wild_symbol != null:
			symbol_id = wild_symbol.id
		var key := String(symbol_id)
		if seen.has(key):
			continue
		seen[key] = true
		var sd := _symbols_by_id.get(symbol_id, null) as SymbolDef
		var tex: Texture2D = sd.texture if sd != null else null
		entries.append({"symbol_id": symbol_id, "texture": tex})
	if not entries.is_empty():
		emit_signal("matched_symbols_resolved", entries)

func _feel_on_line_wins(lines: Array) -> void:
	if lines.is_empty():
		return
	sfx_requested.emit(&"line_win")
	if _feel == null:
		return
	var settings := get_node_or_null("/root/AxelSettings")
	_feel.shake(multiplier.value, settings)
	if multiplier.value >= 3:
		_feel.glitch_flash(settings)
	if multiplier.value >= 4 and _feel.has_method("crt_wobble"):
		_feel.crt_wobble(multiplier.value, settings)
	_feel.set_goal_progress(
		clampf(float(_encounter_goal_winnings_cents) / float(maxi(get_effective_goal_target_cents(), 1)), 0.0, 1.0)
	)
	_feel.highlight_power(powers.current_id())


func _bonus_blocks_finalize() -> bool:
	return (
		_in_trinity_round
		or _pending_free_spins
		or _awaiting_free_spin_choice
		or free_spins.active
	)


func _finalize_encounter_if_needed() -> void:
	if _encounter_complete:
		return
	if _bonus_blocks_finalize():
		return
	if is_chip_bar_goal_complete():
		end_encounter(true)
		return
	if not _can_afford_spin():
		end_encounter(_try_final_spin_goal_assist())
		return
	if _playtest_limit_spins:
		if _playtest_spin_budget > 0 and _spins_used >= _playtest_spin_budget:
			end_encounter(_try_final_spin_goal_assist())


func _try_final_spin_goal_assist() -> bool:
	if _final_spin_goal_assist <= 0.0 or _final_spin_assist_rolled:
		return false
	_final_spin_assist_rolled = true
	if rng.randf() >= _final_spin_goal_assist:
		return false
	var shortfall := get_chip_bar_goal_target_cents() - _encounter_goal_winnings_cents
	if shortfall > 0:
		_encounter_goal_winnings_cents += shortfall
		emit_signal("readouts_progressed")
	return true


func _init_playtest_budget_from_encounter() -> void:
	var encounter := encounter_def as EncounterScript
	if encounter != null:
		_playtest_spin_budget = encounter.spin_budget


func _is_regular_spin_mode() -> bool:
	return not _in_trinity_round and not free_spins.active


func _can_use_paid_spin() -> bool:
	if not _playtest_limit_spins:
		return true
	if _playtest_spin_budget <= 0:
		return true
	return _spins_used < _playtest_spin_budget


func _refresh_spin_weights() -> void:
	_weights = _item_fx.apply_weights(inventory.items, _base_weights, _symbols_by_id)


func _on_loadout_or_goal_changed() -> void:
	_refresh_spin_weights()
	_finalize_encounter_if_needed()
	emit_signal("readouts_progressed")


func _find_lines() -> Array:
	return LineDetectorScript.find_lines(grid.cells, _item_fx.diagonal_opts(inventory.items))


func _line_item_bonus(line: Dictionary) -> float:
	var symbol_id: StringName = line.get("symbol_id", &"")
	if symbol_id == &"wild" and wild_symbol != null:
		symbol_id = wild_symbol.id
	var sd := _symbols_by_id.get(symbol_id, null) as SymbolDef
	var tier := 0
	var power_id: StringName = &""
	if sd != null:
		tier = int(sd.tier)
		power_id = sd.power_id
	return _item_fx.line_payout_bonus(inventory.items, tier, power_id, _in_trinity_round)


func _note_paid_line_procs(lines: Array) -> void:
	for line in lines:
		var symbol_id: StringName = line.get("symbol_id", &"")
		if symbol_id == &"wild" and wild_symbol != null:
			symbol_id = wild_symbol.id
		var sd := _symbols_by_id.get(symbol_id, null) as SymbolDef
		var tier := 0
		var power_id: StringName = &""
		if sd != null:
			tier = int(sd.tier)
			power_id = sd.power_id
		_item_fx.line_payout_bonus(inventory.items, tier, power_id, _in_trinity_round, true)
		if str(line.get("axis", "")) == "d":
			_item_fx.note_effect(inventory.items, &"diagonal")
	_flush_item_procs()


func _flush_item_procs() -> void:
	var ids: Array[StringName] = _item_fx.drain_procs()
	if ids.is_empty():
		return
	if _hold_item_pulses:
		_held_item_pulses.append_array(ids)
		return
	_pulse_item_ids(ids)


func _release_item_pulses() -> void:
	_hold_item_pulses = false
	_flush_item_procs()
	if _held_item_pulses.is_empty():
		return
	var ids: Array[StringName] = []
	ids.assign(_held_item_pulses)
	_held_item_pulses.clear()
	_pulse_item_ids(ids)


func _pulse_item_ids(ids: Array[StringName]) -> void:
	var panel := _player_item_panel()
	if panel != null and panel.has_method("pulse_items"):
		panel.call("pulse_items", ids)


func _note_line_glyph_procs(lines: Array) -> void:
	if _item_fx.glyphs.is_empty():
		return
	for line in lines:
		for p in line.get("cells", []):
			var v := p as Vector2i
			if _item_fx.glyphs.has("%d:%d" % [v.x, v.y]):
				_item_fx.note_effect(inventory.items, &"corner_glyphs")
				return


func _player_item_panel() -> Node:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.find_child("PlayerItemPanel", true, false)


func _line_has_wild(line: Dictionary) -> bool:
	var cells: Array = line.get("cells", [])
	for p in cells:
		var v := p as Vector2i
		var sym: SymbolDef = grid.get_cell(v)
		if sym != null and sym.tier == SymbolDef.Tier.WILD:
			return true
	return false


func _spawn_item_extra_wilds(from: Vector2i) -> void:
	if wild_symbol == null:
		return
	var extra: int = _item_fx.extra_wilds_for_create(inventory.items, rng)
	_flush_item_procs()
	for _i in extra:
		var empty: Vector2i = grid.nearest_empty(from)
		if empty.x < 0:
			return
		grid.set_cell(empty, wild_symbol)


func _maybe_fs_first_win_wild(lines: Array) -> void:
	if not free_spins.active:
		return
	var fs_mods: Dictionary = _item_fx.free_spins_mods(inventory.items)
	if not bool(fs_mods.get("first_win_wild", false)):
		return
	if not _item_fx.fs_first_win_this_spin:
		return
	if lines.is_empty() or wild_symbol == null:
		return
	_item_fx.fs_first_win_this_spin = false
	var cells: Array = lines[0].get("cells", [])
	if cells.is_empty():
		return
	var from: Vector2i = cells[0]
	var empty: Vector2i = grid.nearest_empty(from)
	if empty.x >= 0:
		grid.set_cell(empty, wild_symbol)
		_item_fx.note_param(inventory.items, &"free_spins", "first_win_wild")
		_flush_item_procs()


func _open_power_fx_log() -> void:
	_power_fx_depth += 1
	if _power_fx_depth == 1:
		_power_fx_log = []
		_hold_item_pulses = true


func _close_power_fx_log() -> void:
	_power_fx_depth = maxi(_power_fx_depth - 1, 0)


func _play_power_act_fx(fx_log: Array) -> void:
	_release_item_pulses()
	if _dev_skip_visuals or not enable_symbol_fx:
		_power_sfx_emitted = false
		_refresh_cells_visual()
		await _pause_visual(pause_after_power_sec)
		return
	if not _power_sfx_emitted:
		sfx_requested.emit(&"power")
	_power_sfx_emitted = false
	var events := _collapse_power_fx(fx_log)
	if events.is_empty():
		_refresh_cells_visual()
		await _pause_visual(pause_after_power_sec)
		return
	await _ensure_slot_positions()
	var reduce := _power_reduce_flashing()
	for event in events:
		var cell: Vector2i = event.get("cell", Vector2i(-1, -1))
		var slot := _get_slot(cell)
		if slot == null or not slot.has_method("play_power_act"):
			continue
		slot.call(
			"play_power_act",
			event.get("kind", &""),
			event.get("from_tex", null),
			event.get("to_tex", null),
			POWER_ACT_SEC,
			reduce
		)
	await _pause_visual(POWER_ACT_SEC)
	_refresh_cells_visual()


func _collapse_power_fx(fx_log: Array) -> Array:
	var order: Array[String] = []
	var by_cell: Dictionary = {}
	for raw in fx_log:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = raw
		var cell: Vector2i = event.get("cell", Vector2i(-1, -1))
		if cell.x < 0 or cell.y < 0:
			continue
		var key := "%d,%d" % [cell.x, cell.y]
		if not by_cell.has(key):
			order.append(key)
			by_cell[key] = event.duplicate()
		else:
			var kept: Dictionary = by_cell[key]
			kept["kind"] = event.get("kind", &"")
			kept["to_tex"] = event.get("to_tex", null)
	var out: Array = []
	for key in order:
		out.append(by_cell[key])
	return out


func _power_reduce_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))


func _trigger_item_power(power_id: StringName, potency: float, is_chain: bool, is_girl_power: bool) -> void:
	var nested := _power_fx_depth > 0
	if not nested:
		_power_fx_log = []
		_hold_item_pulses = true
	_power_fx_depth += 1
	var pot := potency * (1.0 + _item_fx.power_potency_bonus(inventory.items))
	var ctx := _make_power_ctx(pot, power_id)
	ctx["fx_log"] = _power_fx_log
	powers.trigger_power_by_id(power_id, ctx)
	if bool(ctx.get("charm_hit", false)):
		_item_fx.note_charm(inventory.items, power_id)
		_flush_item_procs()
	if is_girl_power:
		_item_fx.girl_power_this_spin = true
		var echo: Dictionary = _item_fx.trinity_echo(inventory.items)
		if float(echo.get("chance", 0.0)) > 0.0 and rng.randf() <= float(echo.get("chance", 0.0)):
			var others := _item_fx.other_powers(power_id)
			if not others.is_empty():
				_item_fx.note_effect(inventory.items, &"trinity_echo")
				_flush_item_procs()
				_trigger_item_power(others[rng.randi_range(0, others.size() - 1)], float(echo.get("potency", 0.5)), true, false)
	if is_chain:
		_power_fx_depth = maxi(_power_fx_depth - 1, 0)
		return
	_run_power_chains(power_id)
	var fs_mods: Dictionary = _item_fx.free_spins_mods(inventory.items)
	var chain_p := float(fs_mods.get("chain_random_potency", 0.0))
	if free_spins.active and chain_p > 0.0:
		var others_fs := _item_fx.other_powers(power_id)
		if not others_fs.is_empty():
			_item_fx.note_param(inventory.items, &"free_spins", "chain_random_potency")
			_flush_item_procs()
			_trigger_item_power(others_fs[rng.randi_range(0, others_fs.size() - 1)], chain_p, true, false)
	_power_fx_depth = maxi(_power_fx_depth - 1, 0)


func _run_power_chains(source_id: StringName) -> void:
	if _item_fx.chaining:
		return
	for chain in _item_fx.collect_power_chains(inventory.items):
		if bool(chain.get("once_per_spin", false)) and _item_fx.overclock_used_this_spin:
			continue
		var chance := float(chain.get("chance", 0.0))
		if chance < 1.0 and rng.randf() > chance:
			continue
		_item_fx.note_same_params(inventory.items, chain)
		_flush_item_procs()
		if bool(chain.get("once_per_spin", false)):
			_item_fx.overclock_used_this_spin = true
		var others := _item_fx.other_powers(source_id)
		var count := mini(int(chain.get("other_count", 1)), others.size())
		_item_fx.chaining = true
		for i in count:
			if others.is_empty():
				break
			var pick_i := rng.randi_range(0, others.size() - 1)
			var pid: StringName = others[pick_i]
			others.remove_at(pick_i)
			_trigger_item_power(pid, float(chain.get("potency", 1.0)), true, false)
		_item_fx.chaining = false


func _maybe_trinity_crucible(power_id: StringName, tmods: Dictionary) -> void:
	var pot := float(tmods.get("chosen_plus_random", 0.0))
	if pot <= 0.0:
		return
	var others := _item_fx.other_powers(power_id)
	if others.is_empty():
		return
	_item_fx.note_param(inventory.items, &"trinity_run", "chosen_plus_random")
	_flush_item_procs()
	_trigger_item_power(others[rng.randi_range(0, others.size() - 1)], pot, true, false)


func _finish_trinity_round() -> void:
	_in_trinity_round = false
	_commit_feature_hold()
	powers.set_current_id(meter.saved_active_power)
	meter.reset()
	_music_notify_trinity_ended(_pending_free_spins)


func _apply_trinity_spin_followup_sync(out: Dictionary, step: Dictionary, chosen: StringName) -> void:
	var tmods: Dictionary = _item_fx.trinity_mods(inventory.items)
	if bool(step.get("produced_any_win", false)):
		_item_fx.trinity_win_scalar_accum += float(tmods.get("win_scalar", 0.0))
		_item_fx.note_param(inventory.items, &"trinity_run", "win_scalar")
		_flush_item_procs()
		return
	if _item_fx.trinity_first_dead_done:
		return
	if not bool(tmods.get("first_dead_chosen", false)):
		return
	_item_fx.trinity_first_dead_done = true
	_item_fx.note_param(inventory.items, &"trinity_run", "first_dead_chosen")
	_flush_item_procs()
	_trigger_item_power(chosen, 1.0, false, false)
	var extra := _resolve_trinity_cascade_loop_sync()
	_merge_spin_summary(out, extra)


func _apply_trinity_spin_followup_async(out: Dictionary, step: Dictionary, chosen: StringName) -> void:
	var tmods: Dictionary = _item_fx.trinity_mods(inventory.items)
	if bool(step.get("produced_any_win", false)):
		_item_fx.trinity_win_scalar_accum += float(tmods.get("win_scalar", 0.0))
		_item_fx.note_param(inventory.items, &"trinity_run", "win_scalar")
		_flush_item_procs()
		return
	if _item_fx.trinity_first_dead_done:
		return
	if not bool(tmods.get("first_dead_chosen", false)):
		return
	_item_fx.trinity_first_dead_done = true
	_item_fx.note_param(inventory.items, &"trinity_run", "first_dead_chosen")
	_flush_item_procs()
	_trigger_item_power(chosen, 1.0, false, false)
	var extra := await _resolve_trinity_cascade_loop_async()
	_merge_spin_summary(out, extra)


func _finish_item_spin_hooks(spin_summary: Dictionary) -> void:
	var produced: bool = bool(spin_summary.get("produced_any_win", false))
	var powered: bool = bool(spin_summary.get("power_triggered", false))
	_apply_board_count_bonus(spin_summary, false)
	if not produced and not free_spins.active and not _in_trinity_round:
		var ng := _item_fx.null_gravity_chance(inventory.items)
		if ng > 0.0 and rng.randf() <= ng:
			var pid := _pick_power_for_current_spin()
			_item_fx.note_effect(inventory.items, &"null_gravity")
			_flush_item_procs()
			_trigger_item_power(pid, 1.0, false, false)
			spin_summary["power_triggered"] = true
			powered = true
			_refresh_cells_visual()
			var after := _resolve_cascade_loop_sync() if _is_headless_runtime() or not enable_symbol_fx else _resolve_cascade_loop_sync()
			_merge_spin_summary(spin_summary, after)
	_item_fx.apply_c5_c9_from_items(inventory.items, produced, powered)


func _apply_board_count_bonus(out: Dictionary, is_cascade_step: bool) -> void:
	var rule: Dictionary = _item_fx.board_count_rule(inventory.items)
	var threshold: int = int(rule.get("threshold", 0))
	if threshold <= 0:
		return
	var once_step: bool = bool(rule.get("once_per_step", false)) or bool(rule.get("full_resolver", false))
	if is_cascade_step and not once_step:
		return
	if not is_cascade_step and once_step:
		return
	var counts: Dictionary = {}
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			var sym: SymbolDef = grid.cells[r][c]
			if sym == null or sym.tier == SymbolDef.Tier.WILD or sym.tier == SymbolDef.Tier.HAZARD:
				continue
			counts[sym.id] = int(counts.get(sym.id, 0)) + 1
	var mods: Dictionary = _item_fx.meter_mods(inventory.items)
	for sid in counts.keys():
		var n: int = int(counts[sid])
		if n < threshold:
			continue
		if bool(rule.get("full_resolver", false)):
			var cells: Array[Vector2i] = []
			for r2 in GridManager.ROWS:
				for c2 in GridManager.COLS:
					var s2: SymbolDef = grid.cells[r2][c2]
					if s2 != null and s2.id == sid:
						cells.append(Vector2i(c2, r2))
			if cells.size() >= 3:
				var fake_line := {"symbol_id": sid, "cells": cells, "length": mini(cells.size(), 5), "axis": "f"}
				var pay := _line_payout_cents(fake_line)
				out["payout"] = int(out["payout"]) + pay
				out["line_payout"] = int(out["line_payout"]) + pay
				_add_round_winnings(pay)
				_item_fx.note_effect(inventory.items, &"board_count")
				_flush_item_procs()
				out["produced_any_win"] = true
				grid.clear_cells_and_emit(cells)
				_refresh_cells_visual()
		else:
			var bonus := _to_cents(float(rule.get("bonus_stake", 0.0)) * total_bet * BASELINE_PAYOUT_SCALAR)
			out["payout"] = int(out["payout"]) + bonus
			_add_round_winnings(bonus)
			_item_fx.note_effect(inventory.items, &"board_count")
			_flush_item_procs()
			out["produced_any_win"] = true
		if bool(mods.get("board_count_meter", false)):
			meter.add_sections(1)
		break


func _apply_glyph_payouts(lines: Array, out: Dictionary) -> void:
	if _item_fx.glyphs.is_empty():
		return
	var paid: Dictionary = {}
	for line in lines:
		var cells: Array = line.get("cells", [])
		var line_pay := _line_payout_cents(line)
		for p in cells:
			var v := p as Vector2i
			var key := "%d:%d" % [v.x, v.y]
			if not _item_fx.glyphs.has(key) or paid.has(key):
				continue
			paid[key] = true
			var g: Dictionary = _item_fx.glyphs[key]
			var dest := str(g.get("dest", "winnings"))
			var mult := float(g.get("mult", 2.0))
			var win_frac := float(g.get("win_frac", 1.0))
			if dest == "winnings":
				var extra := _to_cents(float(line_pay) * (mult - 1.0))
				out["payout"] = int(out["payout"]) + extra
				_add_round_winnings(extra)
			elif dest == "split":
				var extra2 := _to_cents(float(line_pay) * (mult - 1.0) * win_frac)
				out["payout"] = int(out["payout"]) + extra2
				_add_round_winnings(extra2)
				multiplier.add(maxi(1, int(round((mult - 1.0) * (1.0 - win_frac)))))
			elif dest == "majority_mult":
				var extra3 := _to_cents(float(line_pay) * (mult - 1.0) * 0.3)
				out["payout"] = int(out["payout"]) + extra3
				_add_round_winnings(extra3)
				multiplier.add(maxi(1, int(round(mult * 0.7))))
			else:
				multiplier.add(maxi(1, int(round(mult))))


func _music_notify_trinity() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("notify_trinity"):
		music.call("notify_trinity")


func _music_notify_trinity_ended(keep_for_free_spins: bool) -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("notify_trinity_ended"):
		music.call("notify_trinity_ended", keep_for_free_spins)


func _music_notify_free_spins_ended() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("notify_free_spins_ended"):
		music.call("notify_free_spins_ended")


func _music_reset_combat_encounter() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("reset_combat_encounter"):
		music.call("reset_combat_encounter")
