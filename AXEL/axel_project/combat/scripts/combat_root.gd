class_name CombatRoot
extends Node2D

enum State { IDLE, SPINNING, POWER, FREE_SPINS_CHOOSE, ENDED }
signal spin_started(seed_value: int)
signal readouts_progressed()
signal spin_finished()
signal premium_meter_changed(previous_sections: int, next_sections: int)
## Emitted when the premium meter has filled and the trinity/free-spin transition
## animation begins. UI hosts can use this to glow / pulse the meter readout.
signal meter_full_transition_started()
## Fired after line wins resolve with matched symbol entries for the spin log UI.
## Each entry: { "symbol_id": StringName, "texture": Texture2D }
signal matched_symbols_resolved(entries: Array)
## Fired once per winning line when payout is known.
## Payload: { "symbol_id", "symbol_name", "length", "bet", "symbol_value", "cascade_multiplier", "payout_cents" }
signal line_win_resolved(event: Dictionary)
## Fired when a line-win popup first overlaps the total winnings readout border.
## Payload: { "payout_cents": int }
signal winnings_popup_border_touched(event: Dictionary)

@export var symbol_resources: Array[Resource] = []

@export_group("Visual pacing (async spin() only)")
## Pause at the start of a spin so the initial grid reads before anything resolves.
@export var pause_at_spin_start_sec: float = 1.275
## Pause after clusters are cleared and wilds are placed (before gravity).
@export var pause_after_cluster_resolve_sec: float = 0.6
## Pause after symbols fall (gravity-only cascade; no top refill).
@export var pause_after_gravity_refill_sec: float = 1.0
## Pause after princess power modifies the grid.
@export var pause_after_power_sec: float = 1.8
@export_group("Symbol FX")
@export var enable_symbol_fx: bool = true
@export var drop_duration_sec: float = 0.2
@export var spawn_drop_duration_sec: float = 0.24
@export var count_flash_duration_sec: float = 0.2
@export var fx_stagger_sec: float = 0.01
@export_group("Transition FX")
## Master toggle for premium-meter-full and free-spin entry animations.
@export var enable_transition_fx: bool = true
## Total duration of one grid white-flash pulse (rises then falls).
@export var grid_flash_duration_sec: float = 0.48
## Number of grid flashes performed during the meter-full transition.
@export_range(1, 4, 1) var grid_flash_count: int = 2
## Peak alpha of the grid flash overlay during a pulse.
@export_range(0.0, 1.0, 0.01) var grid_flash_peak_alpha: float = 0.7
## Duration of the grid border red->white tween during the transition.
@export var grid_border_pulse_duration_sec: float = 0.45
## Hold pause after the meter-full transition before the new grid populates.
@export var meter_handoff_pause_sec: float = 0.375
## Brief pause before `choose_free_spins_princess` so the free-spin handoff reads as its own beat.
@export var free_spin_handoff_pause_sec: float = 0.18
@export_group("Power Intro FX")
## Master toggle for the center power intro flash before princess powers apply.
@export var enable_power_intro_fx: bool = true
## Time spent scaling the icon up from small/transparent to the peak.
@export var power_intro_scale_in_sec: float = 0.27
## Time the icon holds at peak scale + glow before scaling out.
@export var power_intro_hold_sec: float = 0.27
## Time spent scaling the icon back down and fading out.
@export var power_intro_scale_out_sec: float = 0.21
## Peak scale of the icon during the intro flash.
@export var power_intro_peak_scale: float = 1.8
## Peak alpha of the power intro background glow.
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
const PrincessControllerScript := preload("res://combat/scripts/princess_controller.gd")
const LineDetectorScript := preload("res://combat/scripts/line_detector.gd")
const MeterScript := preload("res://combat/scripts/meter.gd")
const FreeSpinsScript := preload("res://combat/scripts/free_spins.gd")
const GoalTrackerScript := preload("res://combat/scripts/goal_tracker.gd")
const EncounterScript := preload("res://combat/scripts/encounter.gd")
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const ItemInventoryScript := preload("res://combat/scripts/item_inventory.gd")

## Safety cap so pathological grids / RNG cannot infinite-loop cascade resolution.
const MAX_CASCADE_ITERATIONS := 512
## Chip-bar economy (integer playtest units; bankroll cap = full bar).
const ECONOMY_DISPLAY_SCALE := 1
const CHIP_BAR_SECTIONS := 11
const CHIP_BAR_FULL_CENTS := 1000
const CHIP_BAR_GOAL_MULTIPLE := 10
const STARTING_BANKROLL_CENTS := CHIP_BAR_FULL_CENTS
const GRID_VISUAL_SCALE := 1.5
const GRID_EDGE_MARGIN := 8.0
const VIEWPORT_TOP_SAFE := 84.0
const VIEWPORT_BOTTOM_SAFE := 292.0
const CELL_SIZE_MIN := 48.0
const CELL_SIZE_MAX := 80.0
const PANEL_FILL_CELL_MAX := 128.0
const ROUND_WINNINGS_GAP := 12.0
const ROUND_WINNINGS_HEIGHT := 36.0
const BET_LADDER: Array[float] = [
	100.0, 200.0, 300.0, 400.0, 500.0, 1000.0,
]
const BASELINE_PAYOUT_SCALAR := 0.431

var rng := CombatRNG.new()
var multiplier := CombatMultiplier.new()
var princesses := PrincessControllerScript.new()
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
var _spins_used: int = 0
var _lifetime_spins_used: int = 0
var _current_seed: int = 0
var _encounter_complete: bool = false
var _encounter_won: bool = false
var _in_trinity_round: bool = false
var _pending_free_spins: bool = false
var _awaiting_free_spin_choice: bool = false
var _pending_fall_moves: Array = []
var _pending_spawns: Array = []
var _slot_positions_ready: bool = false
var _round_winnings_cents: int = 0
var _bankroll_cents: int = STARTING_BANKROLL_CENTS
var _encounter_goal_winnings_cents: int = 0
var _round_winnings_default_modulate: Color = Color.WHITE
var _grid_width_cached: float = 0.0
var _grid_height_cached: float = 0.0
var _grid_flash_tween: Tween
var _grid_border_tween: Tween
var _power_intro_tween: Tween
var _last_spin_summary: Dictionary = {}
var _default_grid_border_color: Color = Color(0.78, 0.03, 0.03, 0.95)
var _power_symbol_by_id: Dictionary = {}
var _power_intro_fallback_label: Label
var _suppress_grid_populated_fx: bool = false
var _cached_multiplier_emit_value: int = -1
var _winnings_popup_target: Control = null
var inventory := ItemInventoryScript.new()
const GRID_FRAME_OUTSET := 4.0
const POWER_INTRO_ICON_SIZE_RATIO := 0.55
const DEBUG_LOG_PATH := "res://../../logs/debug/debug-1d1bdd.log"
const DEBUG_SESSION_ID := "1d1bdd"
const AGENT_DEBUG_LOG_PATH := "res://../../logs/debug/debug-c9d495.log"
const AGENT_DEBUG_SESSION_ID := "c9d495"
const SESSION_DEBUG_LOG_PATH := "res://../../debug-d2c366.log"
const SESSION_DEBUG_SESSION_ID := "d2c366"


func _ready() -> void:
	if _is_headless_runtime():
		enable_symbol_fx = false
		enable_transition_fx = false
		enable_power_intro_fx = false
	_ensure_symbol_slots()
	_load_symbols_from_export()
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


func _load_symbols_from_export() -> void:
	_weights.clear()
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
		elif sd.tier == SymbolDef.Tier.PREMIUM:
			premium_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
			_premium_symbol_ids[sd.id] = true
		if sd.princess_id != &"":
			_power_symbol_by_id[sd.princess_id] = sd
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


func get_princess_current_id() -> StringName:
	return princesses.current_id()


func get_princess_next_id() -> StringName:
	return princesses.next_id()


func get_goal_label() -> String:
	return get_chip_bar_goal_label()


func get_chip_bar_section_count() -> int:
	return CHIP_BAR_SECTIONS


func get_chip_bar_full_value() -> float:
	return float(CHIP_BAR_FULL_CENTS)


func get_chip_bar_health_ratio() -> float:
	return clampf(float(_bankroll_cents) / float(CHIP_BAR_FULL_CENTS), 0.0, 1.0)


func get_chip_bar_goal_target_cents() -> int:
	return CHIP_BAR_FULL_CENTS * CHIP_BAR_GOAL_MULTIPLE


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
	return "GOAL: WIN 10x CHIP-BAR  (%d / %d)" % [current_units, target_units]


func is_chip_bar_goal_complete() -> bool:
	return _encounter_goal_winnings_cents >= get_chip_bar_goal_target_cents()


func get_meter_sections_filled() -> int:
	return meter.sections_filled


func get_spins_used() -> int:
	return _spins_used


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
	_bankroll_cents = clampi(_bankroll_cents, 0, CHIP_BAR_FULL_CENTS)


func get_last_spin_summary() -> Dictionary:
	return _last_spin_summary.duplicate(true)


func is_encounter_complete() -> bool:
	return _encounter_complete


func did_win_encounter() -> bool:
	return _encounter_won


func is_waiting_for_free_spin_choice() -> bool:
	return _awaiting_free_spin_choice


func setup_new_grid(seed_value: int) -> void:
	# #region agent log
	_session_debug_log(
		"seed-%d" % seed_value,
		"H1",
		"combat_root.gd:setup_new_grid",
		"setup_new_grid entered",
		{
			"incoming_seed": seed_value,
			"previous_seed": _current_seed,
			"previous_state": _state,
			"previous_free_spins_active": free_spins.active,
			"previous_spins_remaining": free_spins.spins_remaining,
		}
	)
	# #endregion
	_current_seed = seed_value
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
	_awaiting_free_spin_choice = false
	_round_winnings_cents = 0
	_encounter_goal_winnings_cents = 0
	_last_spin_summary = _empty_spin_summary()
	_bankroll_cents = STARTING_BANKROLL_CENTS
	_clamp_bankroll()
	_lifetime_spins_used = 0
	var encounter := encounter_def as EncounterScript
	var goal = encounter.get("goal") if encounter != null else null
	goal_tracker.call("set_goal", goal)
	_refresh_multiplier_label()
	_refresh_round_winnings_label()
	_hide_encounter_won_banner()
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used + 1],
		"H2",
		"combat_root.gd:_start_spin_with_new_grid",
		"paid spin repopulated grid",
		{
			"next_spin": _spins_used + 1,
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	# #region agent log
	_debug_log(
		"seed-%d-setup" % _current_seed,
		"H1",
		"combat_root.gd:setup_new_grid",
		"setup_new_grid populated grid",
		{
			"seed": _current_seed,
			"spins_used": _spins_used,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	if not enable_symbol_fx:
		_refresh_cells_visual()
	_refresh_grid_border_for_state()
	emit_signal("spin_started", _current_seed)
	emit_signal("readouts_progressed")


func spin() -> void:
	if _state != State.IDLE or _encounter_complete:
		emit_signal("spin_finished")
		return
	if not _can_afford_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		emit_signal("spin_finished")
		return
	_state = State.SPINNING
	_round_winnings_cents = 0
	_hide_round_winnings_overlay(false)
	_refresh_round_winnings_label()
	_begin_spin_round()
	if not free_spins.active:
		multiplier.reset()
	_refresh_multiplier_label()
	emit_signal("readouts_progressed")
	await _pause_visual(pause_at_spin_start_sec)
	var spin_summary := _empty_spin_summary()
	await _try_regular_spin_start_girl_power_async(spin_summary)
	var main_summary := await _play_one_spin_async()
	_merge_spin_summary(spin_summary, main_summary)

	## SUPER Free Spins: keep post-resolve Girl Power on non-winning spins (MP100-style).
	if free_spins.active:
		var should_trigger_power: bool = not bool(spin_summary["produced_any_win"]) and not free_spins.all_powers_used_once()
		if should_trigger_power and _should_trigger_girl_power():
			_state = State.POWER
			var power_id := free_spins.chosen_princess
			await _play_power_intro_flash_async(power_id)
			princesses.trigger_power_by_id(power_id, _make_princess_ctx())
			free_spins.mark_power_used_once(power_id)
			spin_summary["princess_triggered"] = true
			_refresh_cells_visual()
			await _pause_visual(pause_after_power_sec)
			await _apply_gravity_and_refill(not free_spins.active)
			var after_power: Dictionary = await _resolve_cascade_loop_async()
			_merge_spin_summary(spin_summary, after_power)
	spin_summary["grid_cleared"] = _is_grid_cleared_for_current_mode()
	if spin_summary["grid_cleared"] and not _in_trinity_round:
		var clear_item_scalar := 1.0 + _get_item_payout_scalar()
		var clear_bonus := _to_cents(
			50.0 * total_bet * float(multiplier.value) * clear_item_scalar * BASELINE_PAYOUT_SCALAR
		)
		spin_summary["payout"] += clear_bonus
		spin_summary["clear_bonus_payout"] = int(spin_summary["clear_bonus_payout"]) + clear_bonus
		_add_round_winnings(clear_bonus)
	if _pending_free_spins:
		# #region agent log
		_agent_debug_log(
			"pre-fix",
			"H8",
			"combat_root.gd:spin",
			"pending free spins handoff reached",
			{
				"pending_free_spins": _pending_free_spins,
				"free_spins_active_before_choose": free_spins.active,
				"spins_remaining_before_choose": free_spins.spins_remaining,
				"state": _state,
				"spins_used": _spins_used,
			}
		)
		# #endregion
		if free_spin_handoff_pause_sec > 0.0:
			await _pause_visual(free_spin_handoff_pause_sec)
		_state = State.FREE_SPINS_CHOOSE
		_awaiting_free_spin_choice = true
		_pending_free_spins = false
		emit_signal("readouts_progressed")
	if free_spins.active and not _awaiting_free_spin_choice:
		# #region agent log
		_agent_debug_log(
			"pre-fix",
			"H8",
			"combat_root.gd:spin",
			"free spin consume reached",
			{
				"free_spins_active_before_consume": free_spins.active,
				"spins_remaining_before_consume": free_spins.spins_remaining,
				"state": _state,
				"spins_used": _spins_used,
			}
		)
		# #endregion
		free_spins.consume_spin()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	goal_tracker.on_spin_completed(spin_summary)
	if free_spins.active and goal_tracker.is_complete():
		_settle_symbols_down_without_refill()
	_bankroll_cents += int(spin_summary["payout"])
	_clamp_bankroll()
	_apply_encounter_goal_from_spin(int(spin_summary["payout"]))
	_reset_premium_meter_after_paid_spin()
	_refresh_grid_border_for_state()
	_finalize_encounter_if_needed()
	if _state != State.ENDED and _state != State.FREE_SPINS_CHOOSE:
		_state = State.IDLE
	if _round_winnings_cents > 0:
		_play_round_winnings_win_glow()
	_refresh_multiplier_label()
	_last_spin_summary = spin_summary.duplicate(true)
	emit_signal("readouts_progressed")
	emit_signal("spin_finished")


## Headless / determinism: same logic as spin() without awaiting the renderer.
func spin_sync() -> void:
	if _state != State.IDLE or _encounter_complete:
		return
	if not _can_afford_spin():
		_last_spin_summary = _empty_spin_summary()
		_finalize_encounter_if_needed()
		emit_signal("readouts_progressed")
		return
	_state = State.SPINNING
	_round_winnings_cents = 0
	_hide_round_winnings_overlay(false)
	_refresh_round_winnings_label()
	_begin_spin_round()
	if not free_spins.active:
		multiplier.reset()
	emit_signal("readouts_progressed")
	var spin_summary := _empty_spin_summary()
	_try_regular_spin_start_girl_power_sync(spin_summary)
	var main_summary := _play_one_spin_sync()
	_merge_spin_summary(spin_summary, main_summary)

	if free_spins.active:
		var should_trigger_power: bool = not bool(spin_summary["produced_any_win"]) and not free_spins.all_powers_used_once()
		if should_trigger_power and _should_trigger_girl_power():
			_state = State.POWER
			var power_id := free_spins.chosen_princess
			princesses.trigger_power_by_id(power_id, _make_princess_ctx())
			free_spins.mark_power_used_once(power_id)
			spin_summary["princess_triggered"] = true
			_refresh_cells_visual()
			_apply_gravity_and_refill_sync(not free_spins.active)
			var after_power: Dictionary = _resolve_cascade_loop_sync()
			_merge_spin_summary(spin_summary, after_power)
	spin_summary["grid_cleared"] = _is_grid_cleared_for_current_mode()
	if spin_summary["grid_cleared"] and not _in_trinity_round:
		var clear_item_scalar := 1.0 + _get_item_payout_scalar()
		var clear_bonus := _to_cents(
			50.0 * total_bet * float(multiplier.value) * clear_item_scalar * BASELINE_PAYOUT_SCALAR
		)
		spin_summary["payout"] += clear_bonus
		spin_summary["clear_bonus_payout"] = int(spin_summary["clear_bonus_payout"]) + clear_bonus
		_add_round_winnings(clear_bonus)
	if _pending_free_spins:
		_state = State.FREE_SPINS_CHOOSE
		_awaiting_free_spin_choice = true
		_pending_free_spins = false
		emit_signal("readouts_progressed")
	if free_spins.active and not _awaiting_free_spin_choice:
		free_spins.consume_spin()
		multiplier.cap_enabled = true
		multiplier.cap_value = free_spins.multiplier_cap
	goal_tracker.on_spin_completed(spin_summary)
	if free_spins.active and goal_tracker.is_complete():
		_settle_symbols_down_without_refill()
	_bankroll_cents += int(spin_summary["payout"])
	_clamp_bankroll()
	_apply_encounter_goal_from_spin(int(spin_summary["payout"]))
	_reset_premium_meter_after_paid_spin()
	_refresh_grid_border_for_state()
	_finalize_encounter_if_needed()
	if _state != State.ENDED and _state != State.FREE_SPINS_CHOOSE:
		_state = State.IDLE
	if _round_winnings_cents > 0:
		_play_round_winnings_win_glow()
	_last_spin_summary = spin_summary.duplicate(true)
	emit_signal("readouts_progressed")


func debug_trigger_power() -> void:
	princesses.trigger_current_power(_make_princess_ctx())
	_refresh_cells_visual()


func serialize_spin_result() -> String:
	return "%s|%d|%s" % [grid.snapshot_ids(), multiplier.value, String(princesses.current_id())]


func choose_free_spins_princess(princess_id: StringName) -> void:
	if not _awaiting_free_spin_choice:
		return
	## SUPER Free Spins entry (post-Trinity handoff).
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H4",
		"combat_root.gd:choose_free_spins_princess",
		"choose_free_spins_princess entered",
		{
			"princess_id": String(princess_id),
			"awaiting_choice": _awaiting_free_spin_choice,
			"free_spins_active_before_start": free_spins.active,
			"spins_remaining_before_start": free_spins.spins_remaining,
			"grid_snapshot_before_start": grid.snapshot_ids(),
		}
	)
	# #endregion
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H6",
		"combat_root.gd:choose_free_spins_princess",
		"free spins started with princess",
		{
			"princess_id": String(princess_id),
			"free_spins_active_before_start": free_spins.active,
			"spins_remaining_before_start": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	free_spins.start_with_princess(princess_id)
	princesses.set_current_id(princess_id)
	_repopulate_grid_handoff("super_fs_entry")
	_awaiting_free_spin_choice = false
	multiplier.cap_enabled = true
	multiplier.cap_value = free_spins.multiplier_cap
	_state = State.IDLE
	_refresh_grid_border_for_state()
	emit_signal("readouts_progressed")
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H4",
		"combat_root.gd:choose_free_spins_princess",
		"choose_free_spins_princess completed",
		{
			"free_spins_active_after_start": free_spins.active,
			"spins_remaining_after_start": free_spins.spins_remaining,
			"state_after_start": _state,
		}
	)
	# #endregion


func end_encounter(success: bool) -> void:
	_encounter_complete = true
	_encounter_won = success
	_state = State.ENDED
	if success:
		_show_encounter_won_banner()
	else:
		_hide_encounter_won_banner()


func equip_item(item: Resource) -> bool:
	return inventory.equip(item)


func unequip_item(item: Resource) -> void:
	inventory.unequip(item)


func set_equipped_items(items: Array) -> void:
	inventory.set_all(items)


func begin_next_playtest_encounter(seed_value: int) -> void:
	var preserved_bankroll := _bankroll_cents
	_current_seed = seed_value
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
	_awaiting_free_spin_choice = false
	_round_winnings_cents = 0
	_encounter_goal_winnings_cents = 0
	_bankroll_cents = preserved_bankroll
	_clamp_bankroll()
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
	emit_signal("spin_started", _current_seed)
	emit_signal("readouts_progressed")


func _play_one_spin_async() -> Dictionary:
	var summary := await _resolve_cascade_loop_async()
	if not free_spins.active and meter.is_full():
		var trinity_summary := await _run_trinity_round_async()
		_merge_spin_summary(summary, trinity_summary)
	if free_spins.active and meter.is_full():
		free_spins.award_from_meter()
		meter.reset()
	return summary


func _play_one_spin_sync() -> Dictionary:
	var summary := _resolve_cascade_loop_sync()
	if not free_spins.active and meter.is_full():
		var trinity_summary := _run_trinity_round_sync()
		_merge_spin_summary(summary, trinity_summary)
	if free_spins.active and meter.is_full():
		free_spins.award_from_meter()
		meter.reset()
	return summary


## Regular spins only: roll `girl_power_chance` at spin start (before main cascade).
func _try_regular_spin_start_girl_power_async(spin_summary: Dictionary) -> void:
	if free_spins.active:
		return
	if not _should_trigger_girl_power():
		return
	_state = State.POWER
	var power_id := _pick_power_for_current_spin()
	await _play_power_intro_flash_async(power_id)
	princesses.trigger_power_by_id(power_id, _make_princess_ctx())
	spin_summary["princess_triggered"] = true
	_refresh_cells_visual()
	await _pause_visual(pause_after_power_sec)
	await _apply_gravity_and_refill(true)
	var after_power: Dictionary = await _resolve_cascade_loop_async()
	_merge_spin_summary(spin_summary, after_power)
	princesses.advance_rotation()


func _try_regular_spin_start_girl_power_sync(spin_summary: Dictionary) -> void:
	if free_spins.active:
		return
	if not _should_trigger_girl_power():
		return
	_state = State.POWER
	var power_id := _pick_power_for_current_spin()
	princesses.trigger_power_by_id(power_id, _make_princess_ctx())
	spin_summary["princess_triggered"] = true
	_refresh_cells_visual()
	_apply_gravity_and_refill_sync(true)
	var after_power: Dictionary = _resolve_cascade_loop_sync()
	_merge_spin_summary(spin_summary, after_power)
	princesses.advance_rotation()


func _resolve_cascade_loop_async() -> Dictionary:
	var out := _empty_spin_summary()
	var guard := 0
	while true:
		guard += 1
		if guard > MAX_CASCADE_ITERATIONS:
			push_error("CombatRoot: cascade exceeded MAX_CASCADE_ITERATIONS (async).")
			break
		var before_snapshot := grid.snapshot_ids()
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
		# #region agent log
		_debug_log(
			"seed-%d-spin-%d-cascade-%d" % [_current_seed, _spins_used, guard],
			"H2",
			"combat_root.gd:_resolve_cascade_loop_async",
			"cascade scan result",
			{
				"seed": _current_seed,
				"spin": _spins_used,
				"iteration": guard,
				"before_snapshot": before_snapshot,
				"line_count": lines.size(),
				"lines": _summarize_lines(lines),
			}
		)
		# #endregion
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
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
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
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
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
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
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
		var lines: Array = LineDetectorScript.find_lines(grid.cells)
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
		_add_round_winnings(line_win)
		out["wilds_placed"] = int(out["wilds_placed"]) + _count_wild_spawns(lines)
		multiplier.add(1)
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
	for line in lines:
		var cells: Array = line["cells"]
		for p in cells:
			to_clear[p] = true
		if int(line["length"]) == 3 and not free_spins.active:
			var mid: Vector2i = cells[1]
			wild_spawns[mid] = true
	var all_cleared: Array = to_clear.keys()
	grid.clear_cells_and_emit(all_cleared)
	for p in wild_spawns.keys():
		if grid.get_cell(p) == null:
			grid.set_cell(p, wild_symbol)
	_refresh_cells_visual()


## Gravity-only cascade settle. allow_refill is ignored (MP100: no new symbols mid-round).
func _apply_gravity_and_refill(_allow_refill: bool = true) -> void:
	_pending_fall_moves.clear()
	_pending_spawns.clear()
	grid.apply_gravity()
	await _play_pending_gravity_refill_fx()
	await _pause_visual(pause_after_gravity_refill_sec)


func _apply_gravity_and_refill_sync(_allow_refill: bool = true) -> void:
	_pending_fall_moves.clear()
	_pending_spawns.clear()
	grid.apply_gravity()
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
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H2",
		"combat_root.gd:_on_grid_populated",
		"grid_populated signal",
		{
			"state": _state,
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H2",
		"combat_root.gd:_on_grid_populated",
		"grid_populated signal fired",
		{
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	if _suppress_grid_populated_fx:
		if not enable_symbol_fx:
			_refresh_cells_visual()
		return
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	_play_initial_grid_drop_fx()


func _on_cells_cleared(_coords: Array) -> void:
	pass


func _on_symbols_fell(_moves: Array) -> void:
	_pending_fall_moves = _moves.duplicate(true)


func _on_symbols_spawned(_spawns: Array) -> void:
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H3",
		"combat_root.gd:_on_symbols_spawned",
		"symbols_spawned signal fired",
		{
			"spawn_count": _spawns.size(),
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	_pending_spawns = _spawns.duplicate(true)


func _refresh_multiplier_label() -> void:
	if multiplier_label:
		var suffix := ""
		if free_spins.active:
			suffix = " (FS %d left)" % free_spins.spins_remaining
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
	_apply_slot_min_size(cell_size)
	if round_winnings_label != null:
		round_winnings_label.visible = false
	_layout_grid_fx_nodes()
	_slot_positions_ready = false


## Center grid inside a host panel (top-left origin). Used when CombatRoot is reparented into a frame.
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
	var cell_size: float
	if fill_panel:
		var inner_w: float = safe_w - GRID_EDGE_MARGIN * 2.0
		var inner_h: float = safe_h - GRID_EDGE_MARGIN
		var by_w: float = (inner_w - float(GridManager.COLS - 1) * sep_h) / float(GridManager.COLS)
		var by_h: float = (inner_h - float(GridManager.ROWS - 1) * sep_v) / float(GridManager.ROWS)
		cell_size = clampf(minf(by_w, by_h), CELL_SIZE_MIN, PANEL_FILL_CELL_MAX)
	else:
		var min_dim: float = min(safe_w, safe_h)
		cell_size = clamp(min_dim * 0.11 * GRID_VISUAL_SCALE, CELL_SIZE_MIN, CELL_SIZE_MAX)
	var grid_width: float = float(GridManager.COLS) * cell_size + float(GridManager.COLS - 1) * sep_h
	var grid_height: float = float(GridManager.ROWS) * cell_size + float(GridManager.ROWS - 1) * sep_v
	_grid_width_cached = grid_width
	_grid_height_cached = grid_height
	var grid_x: float = max((safe_w - grid_width) * 0.5, GRID_EDGE_MARGIN)
	var grid_y: float = GRID_EDGE_MARGIN
	if not align_grid_top:
		grid_y += max((safe_h - grid_height) * 0.5, 0.0)
	position = Vector2.ZERO
	if multiplier_label != null:
		multiplier_label.visible = false
	grid_ui.position = Vector2(grid_x, grid_y)
	grid_ui.size = Vector2(grid_width, grid_height)
	_apply_slot_min_size(cell_size)
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
	# Encounter win presentation is handled by the fullscreen overlay in CombatTest UI.
	return


func _hide_encounter_won_banner() -> void:
	return


func _play_round_winnings_win_glow() -> void:
	pass


func _hide_round_winnings_overlay(_immediate: bool = false) -> void:
	pass


func _apply_slot_min_size(cell_size: float) -> void:
	for child in grid_ui.get_children():
		var slot := child as Control
		if slot != null:
			slot.custom_minimum_size = Vector2(cell_size, cell_size)


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


func _play_initial_grid_drop_fx() -> void:
	await _ensure_slot_positions()
	var max_delay := 0.0
	for r in GridManager.ROWS:
		for c in GridManager.COLS:
			var coord := Vector2i(c, r)
			var slot := _get_slot(coord)
			if slot == null:
				continue
			var sym: SymbolDef = grid.cells[r][c]
			if slot.has_method("cancel_active_fx"):
				slot.call("cancel_active_fx")
			if slot.has_method("set_symbol"):
				slot.call("set_symbol", sym)
			var to_pos := _slot_target_position(coord)
			var lift_cells := 0.5 + rng.randf() * 0.5
			var from_pos := to_pos - Vector2(0.0, _cell_size_px() * lift_cells)
			var delay := (float(r) + float(c) * 0.25) * fx_stagger_sec
			max_delay = max(max_delay, delay)
			if slot.has_method("play_drop"):
				slot.call("play_drop", from_pos, to_pos, drop_duration_sec, delay)
	await get_tree().create_timer(max_delay + drop_duration_sec).timeout
	_refresh_cells_visual()


func _play_count_flash_for_lines(lines: Array) -> void:
	_emit_matched_symbols_from_lines(lines)
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
	await get_tree().create_timer(count_flash_duration_sec + fx_stagger_sec * max(flash_index - 1, 0)).timeout


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
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H1",
		"combat_root.gd:_start_spin_with_new_grid",
		"start_spin_with_new_grid called (about to populate)",
		{
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	_bankroll_cents -= _to_cents(total_bet)
	## Do not re-seed here: _current_seed stays the encounter seed from setup_new_grid;
	## populate and cascade logic continue the same RNG stream for reproducible spins.
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	# #region agent log
	_debug_log(
		"seed-%d-spin-%d-start" % [_current_seed, _spins_used + 1],
		"H4",
		"combat_root.gd:_start_spin_with_new_grid",
		"spin started with populated grid",
		{
			"seed": _current_seed,
			"next_spin": _spins_used + 1,
			"fixed_seed_expected": _current_seed,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	if not enable_symbol_fx:
		_refresh_cells_visual()
	_spins_used += 1
	_lifetime_spins_used += 1
	emit_signal("spin_started", _current_seed)
	emit_signal("readouts_progressed")


func _begin_spin_round() -> void:
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used + 1],
		"H3",
		"combat_root.gd:_begin_spin_round",
		"spin branch decision",
		{
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H1",
		"combat_root.gd:_begin_spin_round",
		"begin_spin_round branch check",
		{
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
			"spins_used": _spins_used,
		}
	)
	# #endregion
	if free_spins.active:
		## Super Free Spins: continue from entry grid; repopulate only at handoff (choose princess).
		emit_signal("spin_started", _current_seed)
		emit_signal("readouts_progressed")
		return
	_start_spin_with_new_grid()


## Fresh 5x5 at feature handoff; continues encounter RNG stream (no reseed).
func _repopulate_grid_handoff(handoff: String) -> void:
	_suppress_grid_populated_fx = true
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_suppress_grid_populated_fx = false
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H2",
		"combat_root.gd:_repopulate_grid_handoff",
		"handoff grid repopulated",
		{
			"handoff": handoff,
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	if not enable_symbol_fx:
		_refresh_cells_visual()


func _repopulate_grid_handoff_async(handoff: String) -> void:
	_suppress_grid_populated_fx = true
	grid.populate(rng, low_symbol_pool + premium_symbol_pool, _weights)
	_suppress_grid_populated_fx = false
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H2",
		"combat_root.gd:_repopulate_grid_handoff_async",
		"handoff grid repopulated",
		{
			"handoff": handoff,
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	if not enable_symbol_fx:
		_refresh_cells_visual()
		return
	await _play_initial_grid_drop_fx()


func _can_afford_spin() -> bool:
	return _bankroll_cents >= _to_cents(total_bet)


func _is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"


func _add_round_winnings(amount_cents: int) -> void:
	if amount_cents <= 0:
		return
	_round_winnings_cents += amount_cents
	_refresh_round_winnings_label()
	emit_signal("readouts_progressed")


func _play_pending_gravity_refill_fx() -> void:
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H5",
		"combat_root.gd:_play_pending_gravity_refill_fx",
		"gravity/refill FX payload",
		{
			"pending_fall_moves": _pending_fall_moves.size(),
			"pending_spawns": _pending_spawns.size(),
			"free_spins_active": free_spins.active,
			"spins_remaining": free_spins.spins_remaining,
			"state": _state,
		}
	)
	# #endregion
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
		if to_slot.has_method("play_drop"):
			to_slot.call("play_drop", from_pos, to_pos, duration, 0.0)
	var spawn_index := 0
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
		var delay := fx_stagger_sec * spawn_index
		var duration := spawn_drop_duration_sec + float(rows_from_top) * 0.02
		max_total = max(max_total, delay + duration)
		if slot.has_method("play_drop"):
			slot.call("play_drop", from_pos, to_pos, duration, delay)
		spawn_index += 1
	if max_total > 0.0:
		await get_tree().create_timer(max_total).timeout
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
		"princess_triggered": false,
		"grid_cleared": false,
	}


func _merge_spin_summary(base: Dictionary, extra: Dictionary) -> void:
	base["produced_any_win"] = bool(base["produced_any_win"]) or bool(extra.get("produced_any_win", false))
	base["cascade_drops"] = int(base["cascade_drops"]) + int(extra.get("cascade_drops", 0))
	base["wilds_placed"] = int(base["wilds_placed"]) + int(extra.get("wilds_placed", 0))
	base["payout"] = int(base["payout"]) + int(extra.get("payout", 0))
	base["line_payout"] = int(base["line_payout"]) + int(extra.get("line_payout", 0))
	base["clear_bonus_payout"] = int(base["clear_bonus_payout"]) + int(extra.get("clear_bonus_payout", 0))
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
	var item_scalar := 1.0 + _get_item_payout_scalar()
	return _to_cents(
		total_bet * payout_multiplier * float(multiplier.value) * item_scalar * BASELINE_PAYOUT_SCALAR
	)


func _to_cents(amount: float) -> int:
	return int(round(amount))


func _get_item_payout_scalar() -> float:
	var total := 0.0
	for item in inventory.items:
		total += _item_payout_contribution(item)
	return total


func _item_payout_contribution(item: Resource) -> float:
	var eff_id = item.get("effect_id")
	var params = item.get("effect_params")
	if eff_id == null or params == null:
		return 0.0
	match StringName(eff_id):
		&"reroll_payout_scalar":
			var per_reroll := float(params.get("per_reroll", 0.0))
			var cap := float(params.get("cap", 0.0))
			return minf(float(_spins_used) * per_reroll, cap)
	return 0.0


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


func _debug_log(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(DEBUG_LOG_PATH) else FileAccess.WRITE_READ
	var file := FileAccess.open(DEBUG_LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": DEBUG_SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000,
	}
	file.store_line(JSON.stringify(payload))
	file.close()


func _agent_debug_log(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(AGENT_DEBUG_LOG_PATH) else FileAccess.WRITE_READ
	var file := FileAccess.open(AGENT_DEBUG_LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": AGENT_DEBUG_SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000,
	}
	file.store_line(JSON.stringify(payload))
	file.close()


func _session_debug_log(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(SESSION_DEBUG_LOG_PATH) else FileAccess.WRITE_READ
	var file := FileAccess.open(SESSION_DEBUG_LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": SESSION_DEBUG_SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000,
	}
	file.store_line(JSON.stringify(payload))
	file.close()


func _should_trigger_girl_power() -> bool:
	if free_spins.active:
		return true
	return rng.randf() <= girl_power_chance


func _reset_premium_meter_after_paid_spin() -> void:
	if free_spins.active:
		return
	meter.reset()


func _apply_meter_from_lines(lines: Array) -> void:
	var before_sections := meter.sections_filled
	for line in lines:
		if _line_is_premium(line):
			meter.add_from_line_length(int(line["length"]))
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
		return princesses.current_id()
	var order: Array[StringName] = [&"love", &"star", &"storm"]
	for power_id in order:
		if not free_spins.has_used_power(power_id):
			princesses.set_current_id(power_id)
			return power_id
	var fallback := princesses.current_id()
	princesses.set_current_id(fallback)
	return fallback


func _play_meter_full_transition_async() -> void:
	emit_signal("meter_full_transition_started")
	emit_signal("readouts_progressed")
	if not enable_transition_fx:
		await _pause_visual(pause_after_power_sec * 0.6)
		return
	var border_target := Color(1.0, 1.0, 1.0, 1.0)
	var border_wait_sec: float = maxf(grid_border_pulse_duration_sec, 0.05)
	if grid_frame != null:
		_kill_tween(_grid_border_tween)
		_grid_border_tween = create_tween()
		_grid_border_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_grid_border_tween.tween_property(grid_frame, "border_color", border_target, border_wait_sec)
	for i in maxi(grid_flash_count, 1):
		await _play_grid_white_flash_async(grid_flash_duration_sec, grid_flash_peak_alpha)
	# Avoid awaiting tween.finished late; the signal may have fired already while flashes run.
	# Use deterministic wait so transition cannot deadlock even if tween was replaced/killed.
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
	_grid_flash_tween = create_tween()
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
	if not enable_power_intro_fx or power_intro_layer == null or power_intro_icon == null:
		return
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
	_power_intro_tween = create_tween()
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
	_grid_border_tween = create_tween()
	_grid_border_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_grid_border_tween.tween_property(grid_frame, "border_color", target, max(grid_border_pulse_duration_sec * 0.6, 0.08))


func _kill_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()


func _run_trinity_round_async() -> Dictionary:
	var out := _empty_spin_summary()
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H5",
		"combat_root.gd:_run_trinity_round_async",
		"trinity round entered",
		{
			"free_spins_active": free_spins.active,
			"meter_sections": meter.sections_filled,
			"state": _state,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	meter.saved_active_princess = princesses.current_id()
	multiplier.reset()
	_refresh_multiplier_label()
	_in_trinity_round = true
	var order: Array[StringName] = [&"love", &"star", &"storm"]
	await _play_meter_full_transition_async()
	await _repopulate_grid_handoff_async("trinity_entry")
	## Trinity Run: gravity-only cascades (no top refill in any mode).
	for id in order:
		princesses.set_current_id(id)
		await _play_power_intro_flash_async(id)
		princesses.trigger_power_by_id(id, _make_princess_ctx())
		out["princess_triggered"] = true
		_refresh_cells_visual()
		await _pause_visual(pause_after_power_sec)
		var post_power := await _resolve_trinity_cascade_loop_async()
		_merge_spin_summary(out, post_power)
		if _count_non_wild_symbols() == 0:
			# #region agent log
			_session_debug_log(
				"seed-%d-spin-%d" % [_current_seed, _spins_used],
				"H5",
				"combat_root.gd:_run_trinity_round_async",
				"trinity flagged pending free spins",
				{
					"trigger_princess_id": String(id),
					"non_wild_count": _count_non_wild_symbols(),
					"state": _state,
					"grid_snapshot": grid.snapshot_ids(),
				}
			)
			# #endregion
			# #region agent log
			_agent_debug_log(
				"pre-fix",
				"H7",
				"combat_root.gd:_run_trinity_round_async",
				"pending free spins flagged",
				{
					"free_spins_active": free_spins.active,
					"spins_remaining": free_spins.spins_remaining,
					"state": _state,
					"spins_used": _spins_used,
					"trigger_princess_id": String(id),
				}
			)
			# #endregion
			_pending_free_spins = true
			break
	_in_trinity_round = false
	princesses.set_current_id(meter.saved_active_princess)
	meter.reset()
	# #region agent log
	_session_debug_log(
		"seed-%d-spin-%d" % [_current_seed, _spins_used],
		"H5",
		"combat_root.gd:_run_trinity_round_async",
		"trinity round exited",
		{
			"pending_free_spins": _pending_free_spins,
			"free_spins_active": free_spins.active,
			"state": _state,
			"grid_snapshot": grid.snapshot_ids(),
		}
	)
	# #endregion
	return out


func _run_trinity_round_sync() -> Dictionary:
	var out := _empty_spin_summary()
	meter.saved_active_princess = princesses.current_id()
	multiplier.reset()
	_in_trinity_round = true
	var order: Array[StringName] = [&"love", &"star", &"storm"]
	_play_meter_full_transition_sync()
	_repopulate_grid_handoff("trinity_entry")
	## Trinity Run: gravity-only cascades (no top refill in any mode).
	for id in order:
		princesses.set_current_id(id)
		princesses.trigger_power_by_id(id, _make_princess_ctx())
		out["princess_triggered"] = true
		_refresh_cells_visual()
		var post_power := _resolve_trinity_cascade_loop_sync()
		_merge_spin_summary(out, post_power)
		if _count_non_wild_symbols() == 0:
			_pending_free_spins = true
			break
	_in_trinity_round = false
	princesses.set_current_id(meter.saved_active_princess)
	meter.reset()
	return out


func _apply_encounter_goal_from_spin(payout_cents: int) -> void:
	if payout_cents <= 0:
		return
	_encounter_goal_winnings_cents += payout_cents


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


func _finalize_encounter_if_needed() -> void:
	if is_chip_bar_goal_complete():
		end_encounter(true)
		return
	if not free_spins.active and not _can_afford_spin():
		end_encounter(false)
