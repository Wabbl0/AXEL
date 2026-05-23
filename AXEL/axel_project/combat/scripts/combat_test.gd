@tool
## Combat test UI — mirrored playtest shell (SPINS | grid | ITEMS), percentage layout, integer economy.
## Canonical entry: `res://combat/combat_test.tscn` (F6). See `README_COMBAT_TEST_VERSIONS.md`.
extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")
const QaCanonValidatorsScript := preload("res://test/qa/qa_canon_validators.gd")
const SCAFFOLD_BASELINE_SCENE := "res://combat/combat_test_scaffold_baseline.tscn"
## Must not be re-added as local children under instanced %CombatRoot (see combat_root.tscn).
const COMBAT_ROOT_INSTANCED_CHILDREN := [
	"GridManager", "GridFrame", "GridUI", "GridFlashOverlay", "PowerIntroLayer",
	"RoundWinningsLabel", "EncounterWonLabel", "MultiplierLabel",
]
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const DEBUG_LOG_PATH := "res://../../logs/debug/debug-1d1bdd.log"
const DEBUG_SESSION_ID := "1d1bdd"
const PRINCESS_LOVE: StringName = &"love"
const PRINCESS_STAR: StringName = &"star"
const PRINCESS_STORM: StringName = &"storm"
const RARITY_GLYPHS := ["◇", "◈", "◆", "★", "✦"]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const GRID_COLUMN_GAP := 10.0
const PREMIUM_BAR_HEIGHT := 10.0
const PREMIUM_BAR_LAYOUT_PAD := 1.0
const RESPONSIVE_NARROW_W := 900.0

## Vertical rhythm (fractions of viewport height; all root-anchored).
const LAYOUT_CORNER_Y0 := 0.025
const LAYOUT_CORNER_Y1 := 0.135
const LAYOUT_CENTER_HUD_Y0 := 0.03
const LAYOUT_CENTER_HUD_Y1 := 0.14
const LAYOUT_MAIN_Y0 := 0.145
const LAYOUT_MAIN_END := 0.99
const CENTER_COLUMN_SEPARATION := 10
const WINNINGS_BAND_MIN_HEIGHT := 40.0
const WINNINGS_ROW_SEPARATION := 8
const CENTER_FOOTER_SEPARATION := 12
const ECONOMICS_STACK_SEPARATION := 4
const BANKROLL_READOUT_FONT := 36
const BANKROLL_READOUT_FONT_NARROW := 28
const EXECUTE_BUTTON_MIN_HEIGHT := 72.0
const BOTTOM_WINDOW_MARGIN := 18.0

## Horizontal symmetry (fractions of viewport width).
const LAYOUT_SIDE_START := 0.02
const LAYOUT_SIDE_END := 0.22
const LAYOUT_CENTER_START := 0.24
const LAYOUT_CENTER_END := 0.76
const LAYOUT_SIDE_RIGHT_START := 0.78
const LAYOUT_SIDE_RIGHT_END := 0.98
const LAYOUT_TOP_BOX_START := 0.008
const LAYOUT_TOP_BOX_END := 0.14
const LAYOUT_CENTER_HUD_START := 0.36
const LAYOUT_CENTER_HUD_END := 0.64
const LAYOUT_META_ICONS_SEPARATION := 4
const META_ICON_GLYPH := "⬡"
const META_ICON_FONT := 31
const SIDE_PANEL_HEADER_FONT := 24
const SIDE_PANEL_BODY_FONT := 16
const SIDE_PANEL_HINT_FONT := 14
const WINNINGS_READOUT_FONT := 31
const CASCADE_MULT_READOUT_FONT := 24
const WINNINGS_READOUT_OUTLINE := 1
const CASCADE_MULT_READOUT_OUTLINE := 1
const WINNINGS_COUNTER_MAX_DURATION := 0.25
const WINNINGS_COUNTER_MIN_STEP := 0.004
const WINNINGS_COUNTER_MAX_STEP := 0.02
const HISTORY_BODY_FONT := 13
const HISTORY_MINI_ICON_SIZE := 14
const HISTORY_ROW_SEPARATION := 3
const HISTORY_LINE2_LEFT_MARGIN := 18
const HISTORY_TEXT_OUTLINE := 2
const LAYOUT_GOAL_BOX_START := 0.86
const LAYOUT_GOAL_BOX_END := 0.992

var RARITY_COLORS: Dictionary = {
	0: Color(0.65, 0.65, 0.65),
	1: Color(0.4, 0.78, 0.4),
	2: Color(0.4, 0.6, 0.9),
	3: Color(0.72, 0.4, 0.88),
	4: Color(0.95, 0.75, 0.2),
}

@export_group("Editor Preview")
## When enabled, the 2D editor runs the same layout shell as runtime (no spin gameplay).
@export var editor_preview_enabled: bool = false:
	set(value):
		if editor_preview_enabled == value:
			return
		editor_preview_enabled = value
		_queue_editor_preview_refresh()
## Deterministic seed for editor grid preview.
@export var editor_preview_seed: int = 12345:
	set(value):
		if editor_preview_seed == value:
			return
		editor_preview_seed = value
		_queue_editor_preview_refresh()

## Resolved lazily via `_cache_scene_refs()` — do not use @onready in this @tool script.
var seed_spin: SpinBox
var spin_btn: Button
var bet_minus_btn: Button
var bet_plus_btn: Button
var bet_label: Label
var mult_label: Label
var goal_label: Label
var budget_label: Label
var bankroll_label: Label
var combat: CombatRootScript
var encounter_win_overlay: Control
var encounter_win_label: Label
var super_fs_choice_overlay: Control
var choose_love_button: Button
var choose_star_button: Button
var choose_storm_button: Button
var top_bar: Control
var meta_box: PanelContainer
var goal_box: PanelContainer
var stake_selector: Control

var _queued_seed: int = 0
var _play_area: Control
var _play_row: HBoxContainer
var _center_column: VBoxContainer
var _center_footer: VBoxContainer
var _bottom_window_margin: Control
var _winnings_center: CenterContainer
var _grid_host: Control
var _premium_progress: ProgressBar
var _spin_history_panel: PanelContainer
var _history_spin_list: VBoxContainer
var _item_picker_panel: PanelContainer
var _item_picker_title: Label
var _item_entries: Array = []
var _stake_pill: PanelContainer
var _economics_center: CenterContainer
var _economics_stack: VBoxContainer
var _cascade_mult_label: Label
var _cascade_mult_pill: PanelContainer
var _last_displayed_cascade_mult: int = 1
var _displayed_round_winnings: int = 0
var _target_round_winnings: int = 0
var _winnings_counter_running: bool = false
var _winnings_counter_generation: int = 0
var _runtime_initialized: bool = false
var _editor_preview_refresh_queued: bool = false
var _editor_tree_ready_attempts: int = 0
var _runtime_tree_ready_attempts: int = 0

## Layout-only editor fallbacks when %CombatRoot is a placeholder (no script instance).
const EDITOR_FALLBACK_BANKROLL := 1000
const EDITOR_FALLBACK_BANKROLL_CAP := 1000
const EDITOR_FALLBACK_BET := 100
const EDITOR_FALLBACK_MAX_ITEM_SLOTS := 7

## Mirrors combat_root.fit_to_panel fill-panel math for editor placeholder fallback.
const FALLBACK_GRID_COLS := 5
const FALLBACK_GRID_ROWS := 5
const FALLBACK_GRID_EDGE_MARGIN := 8.0
const FALLBACK_CELL_SIZE_MIN := 48.0
const FALLBACK_CELL_SIZE_MAX := 128.0

var _fallback_grid_width: float = 0.0


func _can_use_combat_api() -> bool:
	if combat == null or not is_instance_valid(combat):
		return false
	# Instanced CombatRoot is a placeholder in @tool editor; never call gameplay API there.
	if Engine.is_editor_hint():
		return false
	return combat.has_method("setup_new_grid") and combat.has_method("get_current_seed")


func _can_layout_combat_grid() -> bool:
	if not _can_use_combat_api():
		return false
	return combat.has_method("fit_to_panel") and combat.get("grid_ui") != null


func _safe_get_current_seed() -> int:
	if _can_use_combat_api():
		return combat.get_current_seed()
	return _queued_seed


func _safe_get_current_bet() -> float:
	if _can_use_combat_api():
		return combat.get_current_bet()
	return float(EDITOR_FALLBACK_BET)


func _safe_get_round_winnings() -> float:
	if _can_use_combat_api():
		return combat.get_round_winnings()
	return 0.0


func _safe_get_meter_sections_filled() -> int:
	if _can_use_combat_api():
		return combat.get_meter_sections_filled()
	return 0


func _safe_get_bankroll() -> float:
	if _can_use_combat_api():
		return combat.get_bankroll()
	return float(EDITOR_FALLBACK_BANKROLL)


func _safe_get_bankroll_cap() -> float:
	if _can_use_combat_api():
		return combat.get_bankroll_cap()
	return float(EDITOR_FALLBACK_BANKROLL_CAP)


func _safe_get_goal_label() -> String:
	if _can_use_combat_api():
		return combat.get_goal_label()
	return "GOAL: WIN 10x CHIP-BAR  (0 / 0)"


func _safe_get_multiplier_value() -> int:
	if _can_use_combat_api():
		return combat.get_multiplier_value()
	return 1


func _safe_is_multiplier_cap_active() -> bool:
	if _can_use_combat_api():
		return combat.is_multiplier_cap_active()
	return false


func _safe_get_multiplier_cap_value() -> int:
	if _can_use_combat_api():
		return combat.get_multiplier_cap_value()
	return 0


func _safe_is_encounter_complete() -> bool:
	if _can_use_combat_api():
		return combat.is_encounter_complete()
	return false


func _safe_did_win_encounter() -> bool:
	if _can_use_combat_api():
		return combat.did_win_encounter()
	return false


func _safe_is_waiting_for_free_spin_choice() -> bool:
	if _can_use_combat_api():
		return combat.is_waiting_for_free_spin_choice()
	return false


func _safe_get_combat_state() -> int:
	if _can_use_combat_api():
		return combat.get_state()
	return CombatRoot.State.IDLE


func _safe_get_spins_used() -> int:
	if _can_use_combat_api():
		return combat.get_spins_used()
	return 0


func _safe_get_item_max_slots() -> int:
	if not _can_use_combat_api():
		return EDITOR_FALLBACK_MAX_ITEM_SLOTS
	var inv = combat.get("inventory")
	if inv == null:
		return EDITOR_FALLBACK_MAX_ITEM_SLOTS
	if inv.has_method("get_current_max_slots"):
		return inv.get_current_max_slots()
	return EDITOR_FALLBACK_MAX_ITEM_SLOTS


func _safe_get_item_inventory_size() -> int:
	if not _can_use_combat_api():
		return 0
	var inv = combat.get("inventory")
	if inv == null:
		return 0
	if inv.has_method("size"):
		return inv.size()
	return 0


func _safe_get_grid_ui_width() -> float:
	if _can_layout_combat_grid():
		var grid_ui: GridContainer = combat.grid_ui
		if grid_ui != null:
			return grid_ui.size.x
	if _fallback_grid_width >= 8.0:
		return _fallback_grid_width
	return _get_center_column_interior_width(260.0)


func _warn_duplicate_combat_root_children() -> void:
	if combat == null:
		return
	var dupes: PackedStringArray = PackedStringArray()
	for base_name in COMBAT_ROOT_INSTANCED_CHILDREN:
		var count := 0
		for child in combat.get_children():
			if child.name == base_name:
				count += 1
		if count > 1:
			dupes.append("%s (%d×)" % [base_name, count])
	for base_name in COMBAT_ROOT_INSTANCED_CHILDREN:
		if combat.get_node_or_null(NodePath("%s2" % base_name)) != null:
			dupes.append("%s2" % base_name)
	if not dupes.is_empty():
		push_error(
			(
				"CombatTest: duplicate CombatRoot children: %s. "
				+ "Remove inline grid nodes from combat_test.tscn; use instanced combat_root.tscn only "
				+ "(pre-commit: tools/qa/check_combat_test_scaffold.py)."
			) % ", ".join(dupes)
		)


func _suppress_combat_root_legacy_labels() -> void:
	if combat == null:
		return
	for node_name in ["MultiplierLabel", "RoundWinningsLabel", "EncounterWonLabel"]:
		var legacy := combat.get_node_or_null(node_name) as CanvasItem
		if legacy != null:
			legacy.visible = false


func _get_center_column_interior_width(default_w: float) -> float:
	if _center_column != null and _center_column.size.x >= 64.0:
		return _center_column.size.x
	if size.x > 0.0:
		var play_w := size.x * (LAYOUT_SIDE_RIGHT_END - LAYOUT_SIDE_START)
		var side_w := size.x * (LAYOUT_SIDE_END - LAYOUT_SIDE_START)
		if size.x < RESPONSIVE_NARROW_W:
			side_w = size.x * 0.18
		return maxf(play_w - 2.0 * side_w - 2.0 * GRID_COLUMN_GAP, 260.0)
	return maxf(default_w, 260.0)


func _layout_combat_grid_fallback(host_w: float, host_h: float, bottom_reserve: float) -> float:
	if combat == null or _grid_host == null:
		return _get_center_column_interior_width(host_w)
	_suppress_combat_root_legacy_labels()
	combat.position = Vector2.ZERO
	var grid_ui := combat.get_node_or_null("GridUI") as GridContainer
	if grid_ui == null:
		return _get_center_column_interior_width(host_w)
	var safe_w := maxf(host_w, 64.0)
	var safe_h := maxf(host_h - bottom_reserve, 64.0)
	var sep_h := float(grid_ui.get_theme_constant("h_separation"))
	var sep_v := float(grid_ui.get_theme_constant("v_separation"))
	var inner_w := safe_w - FALLBACK_GRID_EDGE_MARGIN * 2.0
	var inner_h := safe_h - FALLBACK_GRID_EDGE_MARGIN
	var by_w := (inner_w - float(FALLBACK_GRID_COLS - 1) * sep_h) / float(FALLBACK_GRID_COLS)
	var by_h := (inner_h - float(FALLBACK_GRID_ROWS - 1) * sep_v) / float(FALLBACK_GRID_ROWS)
	var cell_size := clampf(minf(by_w, by_h), FALLBACK_CELL_SIZE_MIN, FALLBACK_CELL_SIZE_MAX)
	var grid_width := float(FALLBACK_GRID_COLS) * cell_size + float(FALLBACK_GRID_COLS - 1) * sep_h
	var grid_height := float(FALLBACK_GRID_ROWS) * cell_size + float(FALLBACK_GRID_ROWS - 1) * sep_v
	var grid_x := maxf((safe_w - grid_width) * 0.5, FALLBACK_GRID_EDGE_MARGIN)
	var grid_y := FALLBACK_GRID_EDGE_MARGIN
	grid_ui.position = Vector2(grid_x, grid_y)
	grid_ui.size = Vector2(grid_width, grid_height)
	for child in grid_ui.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	var grid_frame := combat.get_node_or_null("GridFrame") as Control
	if grid_frame != null:
		grid_frame.position = Vector2(grid_x - 4.0, grid_y - 4.0)
		grid_frame.size = Vector2(grid_width + 8.0, grid_height + 8.0)
	var flash := combat.get_node_or_null("GridFlashOverlay") as Control
	if flash != null:
		flash.position = grid_ui.position
		flash.size = grid_ui.size
	var power_layer := combat.get_node_or_null("PowerIntroLayer") as Control
	if power_layer != null:
		power_layer.position = grid_ui.position
		power_layer.size = grid_ui.size
	return grid_width


func _ready() -> void:
	if Engine.is_editor_hint():
		if editor_preview_enabled:
			call_deferred("_run_editor_preview_when_ready")
		return
	call_deferred("_run_runtime_when_ready")


func _resolve_scaffold_node(unique_name: String) -> Node:
	var node_path := NodePath("%" + unique_name)
	if has_node(node_path):
		return get_node(node_path)
	return find_child(unique_name, true, false)


func _missing_scaffold_refs() -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	if seed_spin == null:
		missing.append("%SeedSpinBox")
	if spin_btn == null:
		missing.append("%SpinButton")
	if bet_minus_btn == null:
		missing.append("%BetMinusButton")
	if bet_plus_btn == null:
		missing.append("%BetPlusButton")
	if bet_label == null:
		missing.append("%BetLabel")
	if mult_label == null:
		missing.append("%MultiplierReadout")
	if goal_label == null:
		missing.append("%GoalLabel")
	if bankroll_label == null:
		missing.append("%BankrollLabel")
	if combat == null:
		missing.append("%CombatRoot")
	if meta_box == null:
		missing.append("%MetaBox")
	if goal_box == null:
		missing.append("%GoalBox")
	if stake_selector == null and _resolve_scaffold_node("BetMinusButton") == null:
		missing.append("StakeSelector/BetMinusButton")
	if choose_love_button == null:
		missing.append("%ChooseLoveButton")
	if choose_star_button == null:
		missing.append("%ChooseStarButton")
	if choose_storm_button == null:
		missing.append("%ChooseStormButton")
	return missing


func _run_runtime_when_ready() -> void:
	if Engine.is_editor_hint():
		return
	if not _cache_scene_refs():
		if _restore_scaffold_from_baseline():
			if _cache_scene_refs():
				_runtime_tree_ready_attempts = 0
				_initialize_runtime()
				return
		_runtime_tree_ready_attempts += 1
		if _runtime_tree_ready_attempts < 12:
			call_deferred("_run_runtime_when_ready")
		return
	_runtime_tree_ready_attempts = 0
	_initialize_runtime()


func _restore_scaffold_from_baseline() -> bool:
	if find_child("CombatRoot", true, false) != null:
		return false
	if not ResourceLoader.exists(SCAFFOLD_BASELINE_SCENE):
		push_error("CombatTest baseline scaffold missing: %s" % SCAFFOLD_BASELINE_SCENE)
		return false
	var packed: PackedScene = load(SCAFFOLD_BASELINE_SCENE) as PackedScene
	if packed == null:
		return false
	var baseline: Node = packed.instantiate()
	if baseline == null:
		return false
	var restored := 0
	for child in baseline.get_children():
		if child.name == "BlackBackground" or child.name == "ScanlineOverlay":
			continue
		if find_child(child.name, true, false) != null:
			continue
		var dup := child.duplicate() as Node
		if dup == null:
			continue
		add_child(dup)
		restored += 1
	baseline.queue_free()
	if restored > 0:
		push_warning("CombatTest restored %d scaffold nodes from baseline scene." % restored)
	return restored > 0


func _cache_scene_refs() -> bool:
	if not is_inside_tree():
		return false
	if seed_spin == null or not is_instance_valid(seed_spin):
		seed_spin = _resolve_scaffold_node("SeedSpinBox") as SpinBox
	if spin_btn == null or not is_instance_valid(spin_btn):
		spin_btn = _resolve_scaffold_node("SpinButton") as Button
	if bet_minus_btn == null or not is_instance_valid(bet_minus_btn):
		bet_minus_btn = _resolve_scaffold_node("BetMinusButton") as Button
	if bet_plus_btn == null or not is_instance_valid(bet_plus_btn):
		bet_plus_btn = _resolve_scaffold_node("BetPlusButton") as Button
	if bet_label == null or not is_instance_valid(bet_label):
		bet_label = _resolve_scaffold_node("BetLabel") as Label
	if mult_label == null or not is_instance_valid(mult_label):
		mult_label = _resolve_scaffold_node("MultiplierReadout") as Label
	if goal_label == null or not is_instance_valid(goal_label):
		goal_label = _resolve_scaffold_node("GoalLabel") as Label
	if budget_label == null or not is_instance_valid(budget_label):
		budget_label = _resolve_scaffold_node("BudgetLabel") as Label
	if bankroll_label == null or not is_instance_valid(bankroll_label):
		bankroll_label = _resolve_scaffold_node("BankrollLabel") as Label
	if combat == null or not is_instance_valid(combat):
		combat = _resolve_scaffold_node("CombatRoot") as CombatRootScript
	if encounter_win_overlay == null or not is_instance_valid(encounter_win_overlay):
		encounter_win_overlay = _resolve_scaffold_node("EncounterWinOverlay") as Control
	if encounter_win_label == null or not is_instance_valid(encounter_win_label):
		encounter_win_label = _resolve_scaffold_node("EncounterWinLabel") as Label
	if super_fs_choice_overlay == null or not is_instance_valid(super_fs_choice_overlay):
		super_fs_choice_overlay = _resolve_scaffold_node("SuperFSChoiceOverlay") as Control
	if choose_love_button == null or not is_instance_valid(choose_love_button):
		choose_love_button = _resolve_scaffold_node("ChooseLoveButton") as Button
	if choose_star_button == null or not is_instance_valid(choose_star_button):
		choose_star_button = _resolve_scaffold_node("ChooseStarButton") as Button
	if choose_storm_button == null or not is_instance_valid(choose_storm_button):
		choose_storm_button = _resolve_scaffold_node("ChooseStormButton") as Button
	if top_bar == null or not is_instance_valid(top_bar):
		top_bar = get_node_or_null("TopBar") as Control
	if meta_box == null or not is_instance_valid(meta_box):
		meta_box = _resolve_scaffold_node("MetaBox") as PanelContainer
	if goal_box == null or not is_instance_valid(goal_box):
		goal_box = _resolve_scaffold_node("GoalBox") as PanelContainer
	if stake_selector == null or not is_instance_valid(stake_selector):
		stake_selector = find_child("StakeSelector", true, false) as Control
	var missing := _missing_scaffold_refs()
	if not missing.is_empty():
		push_error(
			"CombatTest scaffold missing required nodes: %s. Restore combat_test.tscn from git (bab7ec5) or run combat_test_scaffold_check.gd."
			% ", ".join(missing)
		)
		return false
	return true


func _run_editor_preview_when_ready() -> void:
	if not Engine.is_editor_hint() or not editor_preview_enabled:
		return
	if not _cache_scene_refs():
		_editor_tree_ready_attempts += 1
		if _editor_tree_ready_attempts < 12:
			call_deferred("_run_editor_preview_when_ready")
		return
	_editor_tree_ready_attempts = 0
	_initialize_editor_preview()


func _is_editor_preview() -> bool:
	return Engine.is_editor_hint() and editor_preview_enabled


func _queue_editor_preview_refresh() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _editor_preview_refresh_queued:
		return
	_editor_preview_refresh_queued = true
	call_deferred("_run_queued_editor_preview_refresh")


func _run_queued_editor_preview_refresh() -> void:
	_editor_preview_refresh_queued = false
	if not Engine.is_editor_hint() or not editor_preview_enabled:
		return
	call_deferred("_run_editor_preview_when_ready")


func _initialize_runtime() -> void:
	if _runtime_initialized:
		return
	if not _cache_scene_refs():
		return
	_runtime_initialized = true
	_warn_duplicate_combat_root_children()
	_initialize_shared_layout(false)
	_connect_runtime_signals()
	_wire_winnings_popup_target()
	_queued_seed = int(seed_spin.value)
	combat.setup_new_grid(int(seed_spin.value))
	_debug_log(
		"seed-ui-ready",
		"H5",
		"combat_test.gd:_ready",
		"initial setup_new_grid called from _ready",
		{
			"seed_spin_value": int(seed_spin.value),
			"combat_seed_after_setup": combat.get_current_seed(),
		}
	)
	_set_default_bet()
	call_deferred("_finish_initial_layout")
	_refresh_readouts()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()
	_refresh_spin_button_state()


func _initialize_editor_preview() -> void:
	if not _cache_scene_refs():
		return
	_warn_duplicate_combat_root_children()
	_initialize_shared_layout(true)
	_apply_editor_combat_preview()
	call_deferred("_finish_editor_preview_layout")
	_refresh_readouts()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()
	_refresh_spin_button_state()


func _initialize_shared_layout(editor_mode: bool) -> void:
	if not _cache_scene_refs():
		return
	if seed_spin != null:
		seed_spin.min_value = 0
		seed_spin.max_value = 2147483647
		if editor_mode:
			seed_spin.set_value_no_signal(float(editor_preview_seed))
			_queued_seed = editor_preview_seed
		else:
			seed_spin.value = _pick_start_seed()
			_queued_seed = int(seed_spin.value)
	elif editor_mode:
		_queued_seed = editor_preview_seed
	_hide_legacy_meter_nodes()
	_organize_top_hud()
	_configure_hud_layers()
	_ensure_play_shell()
	_style_stake_pill()
	_configure_spin_button_layer()
	if budget_label != null:
		budget_label.visible = false
	_build_item_picker()
	if not resized.is_connected(_on_size_changed):
		resized.connect(_on_size_changed)


func _wire_winnings_popup_target() -> void:
	if not _can_use_combat_api() or mult_label == null:
		return
	if combat.has_method("set_winnings_popup_target"):
		combat.set_winnings_popup_target(mult_label)


func _connect_runtime_signals() -> void:
	if not spin_btn.pressed.is_connected(_on_spin_pressed):
		spin_btn.pressed.connect(_on_spin_pressed)
	if not bet_minus_btn.pressed.is_connected(_on_bet_minus_pressed):
		bet_minus_btn.pressed.connect(_on_bet_minus_pressed)
	if not bet_plus_btn.pressed.is_connected(_on_bet_plus_pressed):
		bet_plus_btn.pressed.connect(_on_bet_plus_pressed)
	if not combat.spin_started.is_connected(_on_spin_started):
		combat.spin_started.connect(_on_spin_started)
	if not combat.line_win_resolved.is_connected(_on_line_win_resolved):
		combat.line_win_resolved.connect(_on_line_win_resolved)
	if not combat.readouts_progressed.is_connected(_refresh_readouts):
		combat.readouts_progressed.connect(_refresh_readouts)
	if not combat.spin_finished.is_connected(_on_spin_finished):
		combat.spin_finished.connect(_on_spin_finished)
	if not combat.premium_meter_changed.is_connected(_on_premium_meter_changed):
		combat.premium_meter_changed.connect(_on_premium_meter_changed)
	if not combat.meter_full_transition_started.is_connected(_on_meter_full_transition_started):
		combat.meter_full_transition_started.connect(_on_meter_full_transition_started)
	if not combat.winnings_popup_border_touched.is_connected(_on_winnings_popup_border_touched):
		combat.winnings_popup_border_touched.connect(_on_winnings_popup_border_touched)
	if not choose_love_button.pressed.is_connected(_on_choose_love_pressed):
		choose_love_button.pressed.connect(_on_choose_love_pressed)
	if not choose_star_button.pressed.is_connected(_on_choose_star_pressed):
		choose_star_button.pressed.connect(_on_choose_star_pressed)
	if not choose_storm_button.pressed.is_connected(_on_choose_storm_pressed):
		choose_storm_button.pressed.connect(_on_choose_storm_pressed)
	if not seed_spin.value_changed.is_connected(_on_seed_spin_value_changed):
		seed_spin.value_changed.connect(_on_seed_spin_value_changed)


func _apply_editor_combat_preview() -> void:
	if combat == null:
		return
	combat.visible = true
	_suppress_combat_root_legacy_labels()
	_set_seed_spin_value_no_signal(editor_preview_seed)
	_queued_seed = editor_preview_seed
	# Editor parity: layout shell only; do not populate symbol grid or numeric gameplay state.


func _edited_scene_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	var edited := tree.edited_scene_root
	return edited if edited != null else self


func _reparent_for_layout(node: Node, new_parent: Node) -> void:
	if node == null or new_parent == null:
		return
	if node.get_parent() == new_parent:
		_reassert_node_ownership(node)
		return
	node.reparent(new_parent)
	_reassert_node_ownership(node)


func _reassert_node_ownership(node: Node) -> void:
	if not Engine.is_editor_hint() or node == null:
		return
	var scene_root := _edited_scene_root()
	node.set_owner(scene_root)
	for child in node.get_children():
		_reassert_node_ownership(child)


func _reassert_scaffold_ownership() -> void:
	if not Engine.is_editor_hint():
		return
	for node_name in [
		"CombatRoot", "MetaBox", "GoalBox", "SeedSpinBox", "SpinButton",
		"BankrollLabel", "StakeSelector", "MultiplierReadout", "GoalLabel",
		"BetMinusButton", "BetPlusButton", "BetLabel", "PlayArea", "EconomicsCenter",
	]:
		var node := find_child(node_name, true, false)
		if node != null:
			_reassert_node_ownership(node)


func _add_preview_child(node: Node, parent: Node = self) -> void:
	parent.add_child(node)
	_reassert_node_ownership(node)


func _finish_editor_preview_layout() -> void:
	if not _is_editor_preview():
		return
	await get_tree().process_frame
	_apply_responsive_layout()
	await get_tree().process_frame
	_layout_combat()
	_ensure_editor_grid_shell_visible()
	_refresh_editor_placeholder_readouts()
	_reassert_scaffold_ownership()
	_validate_editor_combat_root_structure()


func _validate_editor_combat_root_structure() -> void:
	if not Engine.is_editor_hint() or combat == null:
		return
	var violations := QaCanonValidatorsScript.check_combat_root_grid_uniqueness(combat)
	if violations.is_empty():
		return
	push_error(
		"CombatTest CombatRoot structure drift: %s. "
		% ", ".join(violations)
		+ " Keep combat_root.tscn instance only; remove inline Grid* nodes under CombatRoot. "
		+ "Pre-commit auto-fix: python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py --staged"
	)


func _ensure_editor_grid_shell_visible() -> void:
	if not _is_editor_preview() or combat == null:
		return
	_suppress_combat_root_legacy_labels()
	for node_name in ["GridUI", "GridFrame"]:
		var shell_node := combat.get_node_or_null(node_name) as CanvasItem
		if shell_node != null:
			shell_node.visible = true
	var flash := combat.get_node_or_null("GridFlashOverlay") as CanvasItem
	if flash != null:
		flash.visible = false
	var power_layer := combat.get_node_or_null("PowerIntroLayer") as CanvasItem
	if power_layer != null:
		power_layer.visible = false
	for node in [mult_label, bankroll_label, bet_label, goal_label, seed_spin, _cascade_mult_label, _cascade_mult_pill]:
		if node is CanvasItem:
			(node as CanvasItem).visible = true


func _organize_top_hud() -> void:
	if top_bar != null:
		top_bar.visible = false
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_reparent_hud_to_root(meta_box)
	_reparent_hud_to_root(goal_box)
	_strip_corner_panel_boxes()
	_configure_top_corner_hud()
	_integrate_economics_into_center_hud()

func _reparent_hud_to_root(node: Control) -> void:
	if node == null:
		return
	if node.get_parent() == self:
		_reassert_node_ownership(node)
		return
	_reparent_for_layout(node, self)
	move_child(node, 2)


func _hide_legacy_meter_nodes() -> void:
	var meter_stack := get_node_or_null("RightMeterStack")
	if meter_stack != null:
		meter_stack.visible = false
	var meter_circle := get_node_or_null("RightMeterStack/PremiumMeterCircle")
	if meter_circle == null:
		meter_circle = get_node_or_null("%PremiumMeterCircle")
	if meter_circle != null:
		meter_circle.visible = false


func _ensure_play_shell() -> void:
	if _restore_play_shell_from_scene():
		_finalize_play_shell_layout()
		return
	_build_play_shell()


func _restore_play_shell_from_scene() -> bool:
	var area := get_node_or_null("PlayArea") as Control
	if area == null:
		return false
	_play_area = area
	_play_row = area.get_node_or_null("PlayRow") as HBoxContainer
	if _play_row == null:
		return false
	_spin_history_panel = _play_row.get_node_or_null("HistoryPanel") as PanelContainer
	_center_column = _play_row.get_node_or_null("CenterColumn") as VBoxContainer
	if _center_column == null:
		return false
	_grid_host = _center_column.get_node_or_null("GridHost") as Control
	_winnings_center = _center_column.get_node_or_null("WinningsCenter") as CenterContainer
	_center_footer = _center_column.get_node_or_null("CenterFooter") as VBoxContainer
	_bottom_window_margin = _center_column.get_node_or_null("BottomWindowMargin") as Control
	if _grid_host != null:
		_premium_progress = _grid_host.get_node_or_null("PremiumProgressBar") as ProgressBar
	var winnings_row: HBoxContainer = null
	if _winnings_center != null:
		winnings_row = _winnings_center.get_node_or_null("WinningsRow") as HBoxContainer
	if winnings_row != null:
		_cascade_mult_label = winnings_row.get_node_or_null("CascadeMultiplierPill/CascadeMultiplierReadout") as Label
		_cascade_mult_pill = winnings_row.get_node_or_null("CascadeMultiplierPill") as PanelContainer
		if _cascade_mult_label == null:
			_cascade_mult_label = winnings_row.get_node_or_null("CascadeMultiplierReadout") as Label
	return _grid_host != null and _center_footer != null


func _finalize_play_shell_layout() -> void:
	if combat == null or _grid_host == null:
		return
	if combat.get_parent() != _grid_host:
		combat.reparent(_grid_host)
	combat.visible = true
	_suppress_combat_root_legacy_labels()
	if spin_btn != null and _center_footer != null and spin_btn.get_parent() != _center_footer:
		spin_btn.visible = true
		_reset_container_child_layout(spin_btn)
		spin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		spin_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		spin_btn.custom_minimum_size = Vector2(0.0, EXECUTE_BUTTON_MIN_HEIGHT)
		_reparent_for_layout(spin_btn, _center_footer)
	if mult_label != null and mult_label.visible:
		mult_label.visible = true
	_wire_winnings_popup_target()


func _build_play_shell() -> void:
	_play_area = Control.new()
	_play_area.name = "PlayArea"
	_play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_preview_child(_play_area)
	move_child(_play_area, 1)

	_play_row = HBoxContainer.new()
	_play_row.name = "PlayRow"
	_play_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_row.add_theme_constant_override("separation", int(GRID_COLUMN_GAP))
	_play_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_play_area.add_child(_play_row)
	_reassert_node_ownership(_play_row)

	_spin_history_panel = _build_history_placeholder()
	_spin_history_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_spin_history_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_play_row.add_child(_spin_history_panel)
	_reassert_node_ownership(_spin_history_panel)

	_center_column = VBoxContainer.new()
	_center_column.name = "CenterColumn"
	_center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_column.add_theme_constant_override("separation", CENTER_COLUMN_SEPARATION)
	_play_row.add_child(_center_column)
	_reassert_node_ownership(_center_column)

	_grid_host = Control.new()
	_grid_host.name = "GridHost"
	_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_host.custom_minimum_size = Vector2(260, 200)
	_grid_host.clip_contents = true
	_center_column.add_child(_grid_host)
	_reassert_node_ownership(_grid_host)
	if combat.get_parent() != _grid_host:
		combat.reparent(_grid_host)
		_reassert_node_ownership(combat)
	combat.visible = true
	_suppress_combat_root_legacy_labels()

	_premium_progress = ProgressBar.new()
	_premium_progress.name = "PremiumProgressBar"
	_premium_progress.max_value = 3.0
	_premium_progress.value = 0.0
	_premium_progress.show_percentage = false
	_premium_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.12, 0.02, 0.02, 1.0)
	pb_bg.border_color = Color(0.78, 0.03, 0.03, 0.95)
	pb_bg.set_border_width_all(1)
	_premium_progress.add_theme_stylebox_override("background", pb_bg)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.95, 0.08, 0.08, 1.0)
	_premium_progress.add_theme_stylebox_override("fill", pb_fill)
	_grid_host.add_child(_premium_progress)
	_reassert_node_ownership(_premium_progress)

	_winnings_center = CenterContainer.new()
	_winnings_center.name = "WinningsCenter"
	_winnings_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_winnings_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_winnings_center.custom_minimum_size = Vector2(0.0, WINNINGS_BAND_MIN_HEIGHT)
	_center_column.add_child(_winnings_center)
	_reassert_node_ownership(_winnings_center)

	var winnings_row := HBoxContainer.new()
	winnings_row.name = "WinningsRow"
	winnings_row.alignment = BoxContainer.ALIGNMENT_CENTER
	winnings_row.add_theme_constant_override("separation", WINNINGS_ROW_SEPARATION)
	winnings_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	winnings_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_winnings_center.add_child(winnings_row)
	_reassert_node_ownership(winnings_row)

	if mult_label != null:
		mult_label.visible = true
		mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mult_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_configure_winnings_readout()
		_reset_container_child_layout(mult_label)
		mult_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mult_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var winnings_pill := PanelContainer.new()
		winnings_pill.name = "WinningsReadoutPill"
		winnings_pill.add_theme_stylebox_override("panel", _winnings_readout_bg_style())
		_reparent_for_layout(mult_label, winnings_pill)
		winnings_row.add_child(winnings_pill)
		_reassert_node_ownership(winnings_pill)

	_cascade_mult_label = Label.new()
	_cascade_mult_label.name = "CascadeMultiplierReadout"
	_cascade_mult_label.text = "1×"
	_cascade_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cascade_mult_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_configure_cascade_multiplier_readout()
	_reset_container_child_layout(_cascade_mult_label)
	_cascade_mult_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cascade_mult_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_cascade_mult_pill = PanelContainer.new()
	_cascade_mult_pill.name = "CascadeMultiplierPill"
	_cascade_mult_pill.pivot_offset = Vector2.ZERO
	_cascade_mult_pill.add_theme_stylebox_override("panel", _winnings_readout_bg_style())
	_cascade_mult_pill.add_child(_cascade_mult_label)
	winnings_row.add_child(_cascade_mult_pill)
	_reassert_node_ownership(_cascade_mult_pill)

	_center_footer = VBoxContainer.new()
	_center_footer.name = "CenterFooter"
	_center_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_footer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_center_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_footer.add_theme_constant_override("separation", CENTER_FOOTER_SEPARATION)
	_center_column.add_child(_center_footer)
	_reassert_node_ownership(_center_footer)

	if spin_btn != null:
		spin_btn.visible = true
		_reset_container_child_layout(spin_btn)
		spin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		spin_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		spin_btn.custom_minimum_size = Vector2(0.0, EXECUTE_BUTTON_MIN_HEIGHT)
		_reparent_for_layout(spin_btn, _center_footer)

	_bottom_window_margin = Control.new()
	_bottom_window_margin.name = "BottomWindowMargin"
	_bottom_window_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_window_margin.custom_minimum_size = Vector2(0.0, BOTTOM_WINDOW_MARGIN)
	_bottom_window_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_window_margin.size_flags_vertical = Control.SIZE_SHRINK_END
	_center_column.add_child(_bottom_window_margin)
	_reassert_node_ownership(_bottom_window_margin)
	_reassert_scaffold_ownership()


## Stake-overlap ideas (grid/symbol size fixed; stake stays off bankroll):
## - Top premium-bar mirror: thin frame-attached bar over grid top border only.
## - Border notch: stake pill in centered top-border cutout.
## - Bracket mount: frame brackets anchor floating stake pill to grid edges.
## - Transparent frame lane: shallow top-frame lane for stake UI, max height capped.
func _integrate_economics_into_center_hud() -> void:
	if not _cache_scene_refs():
		return
	if bankroll_label == null and stake_selector == null:
		return
	if _economics_center == null:
		var existing_ec := get_node_or_null("EconomicsCenter") as CenterContainer
		if existing_ec != null:
			_economics_center = existing_ec
		else:
			_economics_center = CenterContainer.new()
			_economics_center.name = "EconomicsCenter"
			_economics_center.mouse_filter = Control.MOUSE_FILTER_PASS
			_add_preview_child(_economics_center)
			move_child(_economics_center, 2)
	else:
		if _economics_center.get_parent() != self:
			_reparent_for_layout(_economics_center, self)
			move_child(_economics_center, 2)

	if _economics_stack == null:
		_economics_stack = VBoxContainer.new()
		_economics_stack.name = "EconomicsStack"
		_economics_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		_economics_stack.add_theme_constant_override("separation", ECONOMICS_STACK_SEPARATION)
		_economics_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_economics_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_economics_center.add_child(_economics_stack)

	if bankroll_label != null:
		bankroll_label.visible = true
		bankroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_reset_container_child_layout(bankroll_label)
		bankroll_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bankroll_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_reparent_for_layout(bankroll_label, _economics_stack)

	if stake_selector != null:
		_reset_container_child_layout(stake_selector)
		stake_selector.visible = true
		stake_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		stake_selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_reparent_for_layout(stake_selector, _economics_stack)


func _reset_container_child_layout(control_node: Control) -> void:
	if control_node == null:
		return
	control_node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control_node.offset_left = 0.0
	control_node.offset_top = 0.0
	control_node.offset_right = 0.0
	control_node.offset_bottom = 0.0


func _strip_corner_panel_boxes() -> void:
	var empty := StyleBoxEmpty.new()
	if meta_box != null:
		meta_box.add_theme_stylebox_override("panel", empty)
	if goal_box != null:
		goal_box.add_theme_stylebox_override("panel", empty)


func _configure_top_corner_hud() -> void:
	if meta_box == null:
		return
	var icons_row := meta_box.get_node_or_null("MetaContent/MetaIconsRow") as HBoxContainer
	if icons_row != null:
		icons_row.add_theme_constant_override("separation", LAYOUT_META_ICONS_SEPARATION)
		icons_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		for child in icons_row.get_children():
			if child is Label:
				var icon := child as Label
				icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				icon.add_theme_font_size_override("font_size", META_ICON_FONT)
	var gear := meta_box.get_node_or_null("MetaContent/MetaIconsRow/GearIcon") as Label
	if gear != null:
		gear.text = META_ICON_GLYPH
	var third := meta_box.get_node_or_null("MetaContent/MetaIconsRow/ThirdIcon") as Label
	if third != null:
		third.text = "?"
	if goal_label != null:
		goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _winnings_readout_bg_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.95)
	style.border_color = Color(0.35, 0.02, 0.02, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _configure_winnings_readout() -> void:
	if mult_label == null:
		return
	mult_label.add_theme_font_size_override("font_size", WINNINGS_READOUT_FONT)
	mult_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.95))
	mult_label.add_theme_constant_override("outline_size", WINNINGS_READOUT_OUTLINE)


func _configure_cascade_multiplier_readout() -> void:
	if _cascade_mult_label == null:
		return
	_cascade_mult_label.add_theme_font_size_override("font_size", CASCADE_MULT_READOUT_FONT)
	_cascade_mult_label.add_theme_color_override("font_color", Color(0.98, 0.35, 0.35, 1.0))
	_cascade_mult_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.95))
	_cascade_mult_label.add_theme_constant_override("outline_size", CASCADE_MULT_READOUT_OUTLINE)


func _build_history_placeholder() -> PanelContainer:
	var panel := _make_side_panel("HISTORY", true)
	panel.name = "HistoryPanel"
	var root_list: VBoxContainer = panel.get_meta("list") as VBoxContainer
	if root_list == null:
		return panel

	_history_spin_list = VBoxContainer.new()
	_history_spin_list.name = "HistorySpinList"
	_history_spin_list.add_theme_constant_override("separation", 4)
	root_list.add_child(_history_spin_list)
	return panel


func _corner_box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.0, 0.0, 0.92)
	style.border_color = Color(0.78, 0.03, 0.03, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _side_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.0, 0.0, 0.88)
	style.border_color = Color(0.45, 0.03, 0.03, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _side_panel_title_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.0, 0.0, 0.98)
	style.border_color = Color(0.35, 0.02, 0.02, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _style_side_panel_header(header: Label) -> void:
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", SIDE_PANEL_HEADER_FONT)
	header.add_theme_color_override("font_color", Color(0.88, 0.4, 0.4, 1.0))


func _make_side_panel_header_strip(header_text: String) -> PanelContainer:
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", _side_panel_title_style())
	var header := Label.new()
	header.name = "SectionHeader"
	header.text = header_text
	_style_side_panel_header(header)
	strip.add_child(header)
	return strip


func _make_side_panel(header_text: String, with_scroll_list: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _side_panel_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var header_strip := _make_side_panel_header_strip(header_text)
	vbox.add_child(header_strip)
	var header := header_strip.get_child(0) as Label

	if with_scroll_list:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vbox.add_child(scroll)

		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)

		panel.set_meta("scroll", scroll)
		panel.set_meta("list", list)
	else:
		var placeholder := Control.new()
		placeholder.name = "HistoryPlaceholder"
		placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(placeholder)
		panel.set_meta("list", placeholder)

	panel.set_meta("header", header)
	return panel


func _style_stake_pill() -> void:
	if bet_label == null or bet_label.get_parent() == null:
		return
	var bet_row := bet_label.get_parent() as HBoxContainer
	if bet_row == null:
		return
	var idx := bet_label.get_index()
	_stake_pill = PanelContainer.new()
	_stake_pill.name = "StakePill"
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.1, 0.0, 0.0, 0.85)
	pill_style.border_color = Color(0.78, 0.03, 0.03, 0.95)
	pill_style.set_border_width_all(2)
	pill_style.set_corner_radius_all(18)
	pill_style.content_margin_left = 16
	pill_style.content_margin_right = 16
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	_stake_pill.add_theme_stylebox_override("panel", pill_style)
	_reparent_for_layout(bet_label, _stake_pill)
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", 22)
	bet_row.add_child(_stake_pill)
	bet_row.move_child(_stake_pill, idx)
	_reassert_node_ownership(_stake_pill)


func _on_spin_pressed() -> void:
	if Engine.is_editor_hint():
		return
	if combat.is_encounter_complete():
		combat.begin_next_playtest_encounter(_queued_seed)
	if _can_apply_queued_seed_on_execute():
		combat.setup_new_grid(_queued_seed)
	spin_btn.disabled = true
	_refresh_spin_button_state()
	await combat.spin()
	spin_btn.disabled = false
	_refresh_readouts()
	_refresh_spin_button_state()


func _refresh_readouts() -> void:
	if not _cache_scene_refs():
		return
	if not _can_use_combat_api():
		_refresh_editor_placeholder_readouts()
		return
	var display_seed := _safe_get_current_seed()
	if _can_queue_seed_change():
		display_seed = _queued_seed
	_set_seed_spin_value_no_signal(display_seed)
	var stake_value := int(_safe_get_current_bet())
	if bet_label != null:
		bet_label.text = "%d" % stake_value
	if mult_label != null and not _winnings_counter_running:
		var combat_total := int(_safe_get_round_winnings())
		if _displayed_round_winnings == combat_total and _target_round_winnings == combat_total:
			_apply_winnings_readout_text()
	_refresh_cascade_multiplier_readout()
	if _premium_progress != null:
		_premium_progress.value = float(_safe_get_meter_sections_filled())
	var cap_units := int(_safe_get_bankroll_cap())
	var bankroll_units := int(_safe_get_bankroll())
	if bankroll_label != null:
		bankroll_label.text = "%d/%d" % [bankroll_units, cap_units]
	if goal_label != null:
		goal_label.text = "GOAL\n%s" % _goal_progress_only(_safe_get_goal_label())
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()


func _refresh_editor_placeholder_readouts() -> void:
	if not _cache_scene_refs():
		return
	_set_seed_spin_value_no_signal(_queued_seed)
	if bet_label != null:
		bet_label.text = "%d" % EDITOR_FALLBACK_BET
	if mult_label != null:
		mult_label.text = "0"
	if _cascade_mult_label != null:
		_cascade_mult_label.text = "1×"
	_last_displayed_cascade_mult = 1
	if _premium_progress != null:
		_premium_progress.value = 0.0
	if bankroll_label != null:
		bankroll_label.text = "%d/%d" % [EDITOR_FALLBACK_BANKROLL, EDITOR_FALLBACK_BANKROLL_CAP]
	if goal_label != null:
		goal_label.text = "GOAL\n0 / 0"
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()


func _refresh_cascade_multiplier_readout() -> void:
	if _cascade_mult_label == null:
		return
	var mult := _safe_get_multiplier_value()
	_cascade_mult_label.text = _format_cascade_multiplier_text(mult)
	if mult > _last_displayed_cascade_mult:
		_pulse_cascade_multiplier()
	_last_displayed_cascade_mult = mult


func _format_cascade_multiplier_text(mult: int) -> String:
	var text := "%d×" % mult
	if _safe_is_multiplier_cap_active():
		text += " / %d" % _safe_get_multiplier_cap_value()
	return text


func _pulse_cascade_multiplier() -> void:
	if _cascade_mult_pill == null:
		return
	_cascade_mult_pill.scale = Vector2.ONE
	_cascade_mult_pill.modulate = Color.WHITE
	var peak := create_tween()
	peak.set_parallel(true)
	peak.tween_property(_cascade_mult_pill, "modulate", Color(1.45, 0.4, 0.4, 1.0), 0.1)
	peak.tween_property(_cascade_mult_pill, "scale", Vector2(1.08, 1.08), 0.1)
	var settle := peak.chain()
	settle.set_parallel(true)
	settle.tween_property(_cascade_mult_pill, "modulate", Color.WHITE, 0.18)
	settle.tween_property(_cascade_mult_pill, "scale", Vector2.ONE, 0.18)


func _on_spin_started(seed_value: int) -> void:
	_queued_seed = seed_value
	_set_seed_spin_value_no_signal(seed_value)
	_clear_history_spin_list()
	_last_displayed_cascade_mult = int(combat.get_multiplier_value())
	_reset_winnings_counter_display()


func _on_spin_finished() -> void:
	_sync_winnings_counter_to_combat_truth()
	if combat.get_state() == CombatRoot.State.IDLE or combat.is_encounter_complete():
		spin_btn.disabled = false
	_refresh_spin_button_state()


func _on_winnings_popup_border_touched(event: Dictionary) -> void:
	var cents: int = int(event.get("payout_cents", 0))
	if cents <= 0:
		return
	_target_round_winnings += cents
	_start_winnings_counter_if_needed()


func _reset_winnings_counter_display() -> void:
	_kill_winnings_counter()
	_displayed_round_winnings = 0
	_target_round_winnings = 0
	_apply_winnings_readout_text()


func _sync_winnings_counter_to_combat_truth() -> void:
	_kill_winnings_counter()
	var combat_total := int(_safe_get_round_winnings())
	_displayed_round_winnings = combat_total
	_target_round_winnings = combat_total
	_apply_winnings_readout_text()


func _apply_winnings_readout_text() -> void:
	if mult_label == null:
		return
	mult_label.text = "%d" % _displayed_round_winnings


func _kill_winnings_counter() -> void:
	_winnings_counter_generation += 1
	_winnings_counter_running = false


func _start_winnings_counter_if_needed() -> void:
	if _winnings_counter_running:
		return
	if _displayed_round_winnings >= _target_round_winnings:
		return
	_winnings_counter_running = true
	_run_winnings_counter_async()


func _run_winnings_counter_async() -> void:
	var gen := _winnings_counter_generation
	while _displayed_round_winnings < _target_round_winnings:
		if gen != _winnings_counter_generation:
			return
		var remaining := _target_round_winnings - _displayed_round_winnings
		var step_interval := WINNINGS_COUNTER_MAX_DURATION / float(max(remaining, 1))
		step_interval = clampf(step_interval, WINNINGS_COUNTER_MIN_STEP, WINNINGS_COUNTER_MAX_STEP)
		_displayed_round_winnings += 1
		_apply_winnings_readout_text()
		var tree := get_tree()
		if tree == null:
			break
		await tree.create_timer(step_interval).timeout
	if gen != _winnings_counter_generation:
		return
	_winnings_counter_running = false
	if _displayed_round_winnings < _target_round_winnings:
		_start_winnings_counter_if_needed()


func _on_meter_full_transition_started() -> void:
	if _premium_progress == null:
		return
	var peak := create_tween()
	peak.tween_property(_premium_progress, "modulate", Color(1.4, 1.1, 1.1, 1.0), 0.12)
	peak.tween_property(_premium_progress, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)


func _on_premium_meter_changed(_previous_sections: int, next_sections: int) -> void:
	if _premium_progress == null:
		return
	var tween := create_tween()
	tween.tween_property(_premium_progress, "value", float(next_sections), 0.2)


func _on_seed_spin_value_changed(value: float) -> void:
	if not _can_queue_seed_change():
		return
	_queued_seed = int(value)
	_debug_log(
		"seed-ui-change-%d" % int(value),
		"H5",
		"combat_test.gd:_on_seed_spin_value_changed",
		"seed change queued for execute",
		{
			"input_seed": int(value),
			"queued_seed": _queued_seed,
			"combat_seed_current": _safe_get_current_seed(),
			"spins_used": _safe_get_spins_used(),
			"state": _safe_get_combat_state(),
		}
	)
	_refresh_readouts()
	_refresh_spin_button_state()


func _on_bet_minus_pressed() -> void:
	combat.step_bet(-1)
	_refresh_readouts()


func _on_bet_plus_pressed() -> void:
	combat.step_bet(1)
	_refresh_readouts()


func _set_default_bet() -> void:
	if not _can_use_combat_api():
		return
	var ladder: Array[float] = combat.get_bet_ladder()
	var default_index := ladder.find(100.0)
	if default_index == -1:
		default_index = 0
	combat.set_bet_index(default_index)


func _on_line_win_resolved(event: Dictionary) -> void:
	var payout_cents: int = int(event.get("payout_cents", 0))
	if payout_cents <= 0:
		return
	_append_history_spin_row(event)


func _append_history_spin_row(event: Dictionary) -> void:
	if _history_spin_list == null:
		return
	var bet: int = int(event.get("bet", 0))
	var symbol_value: float = float(event.get("symbol_value", 0.0))
	var cascade_mult: int = int(event.get("cascade_multiplier", 1))
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", HISTORY_ROW_SEPARATION)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 4)
	line1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tex: Texture2D = event.get("texture") as Texture2D
	if tex != null:
		var icon := TextureRect.new()
		icon.name = "HistorySymbolIcon"
		icon.texture = tex
		icon.custom_minimum_size = Vector2(HISTORY_MINI_ICON_SIZE, HISTORY_MINI_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line1.add_child(icon)
	var line1_label := Label.new()
	line1_label.text = "%d x %s" % [bet, _format_history_factor(symbol_value)]
	line1_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_history_text_style(line1_label)
	line1.add_child(line1_label)
	row.add_child(line1)

	var line2_row := HBoxContainer.new()
	line2_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line2_indent := Control.new()
	line2_indent.custom_minimum_size = Vector2(HISTORY_LINE2_LEFT_MARGIN, 0.0)
	line2_indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line2_row.add_child(line2_indent)
	var line2_label := Label.new()
	line2_label.text = "x %d" % cascade_mult
	line2_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line2_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_history_text_style(line2_label)
	line2_row.add_child(line2_label)
	row.add_child(line2_row)

	_history_spin_list.add_child(row)


func _apply_history_text_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", HISTORY_BODY_FONT)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.48, 0.48, 0.48, 1.0))
	label.add_theme_constant_override("outline_size", HISTORY_TEXT_OUTLINE)
	label.add_theme_color_override("font_shadow_color", Color(0.15, 0.15, 0.15, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)


func _format_history_factor(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%0.1f" % value


func _clear_history_spin_list() -> void:
	if _history_spin_list == null:
		return
	for child in _history_spin_list.get_children():
		child.queue_free()


func _configure_hud_layers() -> void:
	var hud_z := 20
	for node_path in ["BudgetLabel", "EconomicsCenter"]:
		var hud := get_node_or_null(node_path) as Control
		if hud != null:
			hud.z_index = hud_z
			hud.mouse_filter = Control.MOUSE_FILTER_PASS
	if meta_box != null:
		meta_box.z_index = hud_z
		meta_box.mouse_filter = Control.MOUSE_FILTER_PASS
	if goal_box != null:
		goal_box.z_index = hud_z
		goal_box.mouse_filter = Control.MOUSE_FILTER_PASS
	if stake_selector != null:
		stake_selector.mouse_filter = Control.MOUSE_FILTER_PASS


func _configure_spin_button_layer() -> void:
	if spin_btn == null:
		return
	spin_btn.z_index = 30
	spin_btn.mouse_filter = Control.MOUSE_FILTER_STOP


func _finish_initial_layout() -> void:
	await get_tree().process_frame
	_apply_responsive_layout()
	await get_tree().process_frame
	_layout_combat()


func _on_size_changed() -> void:
	if Engine.is_editor_hint() and not editor_preview_enabled:
		return
	_apply_responsive_layout()
	call_deferred("_layout_combat")


func _layout_combat() -> void:
	if _grid_host == null or _center_column == null:
		return
	var host_w := maxf(_grid_host.size.x, _center_column.size.x)
	if host_w < 64.0:
		host_w = maxf(_center_column.get_combined_minimum_size().x, 260.0)
	var host_h := maxf(_grid_host.size.y, 200.0)
	var bottom_reserve := PREMIUM_BAR_HEIGHT + PREMIUM_BAR_LAYOUT_PAD
	_suppress_combat_root_legacy_labels()
	var grid_w := 0.0
	if _can_layout_combat_grid():
		combat.fit_to_panel(Vector2(host_w, host_h), bottom_reserve, true, true)
		grid_w = _safe_get_grid_ui_width()
		_fallback_grid_width = grid_w
		_layout_premium_bar()
	elif combat != null:
		grid_w = _layout_combat_grid_fallback(host_w, host_h, bottom_reserve)
		_fallback_grid_width = grid_w
		_layout_premium_bar_fallback_aligned(grid_w, host_h)
	else:
		grid_w = _get_center_column_interior_width(host_w)
		_fallback_grid_width = grid_w
		_layout_premium_bar_fallback(grid_w, host_h)
	_layout_execute_button_to_grid_width(grid_w)
	if _is_editor_preview():
		_ensure_editor_grid_shell_visible()


func _layout_premium_bar() -> void:
	if _premium_progress == null or _grid_host == null or not _can_layout_combat_grid():
		return
	var grid_bottom := combat.position.y + combat.grid_ui.position.y + combat.grid_ui.size.y
	var grid_left := combat.position.x + combat.grid_ui.position.x
	_premium_progress.position = Vector2(grid_left, grid_bottom)
	_premium_progress.size = Vector2(combat.grid_ui.size.x, PREMIUM_BAR_HEIGHT)
	_premium_progress.z_index = 6


func _layout_premium_bar_fallback(bar_width: float, host_h: float) -> void:
	if _premium_progress == null or _grid_host == null:
		return
	var host_w := maxf(_grid_host.size.x, bar_width)
	var bar_y := maxf(host_h - PREMIUM_BAR_HEIGHT - PREMIUM_BAR_LAYOUT_PAD, 0.0)
	var bar_x := maxf((host_w - bar_width) * 0.5, 0.0)
	_premium_progress.position = Vector2(bar_x, bar_y)
	_premium_progress.size = Vector2(bar_width, PREMIUM_BAR_HEIGHT)
	_premium_progress.z_index = 6


func _layout_premium_bar_fallback_aligned(grid_w: float, host_h: float) -> void:
	if _premium_progress == null or _grid_host == null or combat == null:
		return
	var grid_ui := combat.get_node_or_null("GridUI") as Control
	if grid_ui != null:
		var grid_bottom := combat.position.y + grid_ui.position.y + grid_ui.size.y
		var grid_left := combat.position.x + grid_ui.position.x
		_premium_progress.position = Vector2(grid_left, grid_bottom)
		_premium_progress.size = Vector2(grid_ui.size.x, PREMIUM_BAR_HEIGHT)
		_premium_progress.z_index = 6
		return
	_layout_premium_bar_fallback(grid_w, host_h)


func _layout_execute_button_width() -> void:
	_layout_execute_button_to_grid_width(_safe_get_grid_ui_width())


func _layout_execute_button_to_grid_width(grid_w: float) -> void:
	if spin_btn == null:
		return
	if grid_w < 8.0:
		grid_w = _get_center_column_interior_width(260.0)
	var btn_h := maxf(spin_btn.custom_minimum_size.y, EXECUTE_BUTTON_MIN_HEIGHT)
	spin_btn.custom_minimum_size = Vector2(grid_w, btn_h)
	spin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _apply_responsive_layout() -> void:
	if _play_area == null:
		return
	_place_control_rect(meta_box, LAYOUT_TOP_BOX_START, LAYOUT_CORNER_Y0, LAYOUT_TOP_BOX_END, LAYOUT_CORNER_Y1)
	_place_control_rect(goal_box, LAYOUT_GOAL_BOX_START, LAYOUT_CORNER_Y0, LAYOUT_GOAL_BOX_END, LAYOUT_CORNER_Y1)
	_place_control_rect(_economics_center, LAYOUT_CENTER_HUD_START, LAYOUT_CENTER_HUD_Y0, LAYOUT_CENTER_HUD_END, LAYOUT_CENTER_HUD_Y1)
	_apply_economics_typography()

	var main_y0 := LAYOUT_MAIN_Y0
	var main_y1 := LAYOUT_MAIN_END
	_place_control_rect(_play_area, LAYOUT_SIDE_START, main_y0, LAYOUT_SIDE_RIGHT_END, main_y1)

	var side_w := size.x * (LAYOUT_SIDE_END - LAYOUT_SIDE_START)
	if size.x < RESPONSIVE_NARROW_W:
		side_w = size.x * 0.18
	var main_h := size.y * (main_y1 - main_y0)
	var side_panel_h := maxf(main_h - BOTTOM_WINDOW_MARGIN, 120.0)
	if _spin_history_panel != null:
		_spin_history_panel.custom_minimum_size = Vector2(side_w, side_panel_h)
		_spin_history_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if _item_picker_panel != null:
		_item_picker_panel.custom_minimum_size = Vector2(side_w, side_panel_h)
		_item_picker_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _apply_economics_typography() -> void:
	var bankroll_font := BANKROLL_READOUT_FONT
	if size.x < RESPONSIVE_NARROW_W:
		bankroll_font = BANKROLL_READOUT_FONT_NARROW
	if bankroll_label != null:
		bankroll_label.add_theme_font_size_override("font_size", bankroll_font)
	if goal_label != null:
		goal_label.add_theme_font_size_override("font_size", bankroll_font)
	if bet_label != null:
		var stake_font := 22 if size.x >= RESPONSIVE_NARROW_W else 18
		bet_label.add_theme_font_size_override("font_size", stake_font)
	if bet_minus_btn != null and bet_plus_btn != null:
		var btn_size := 40.0 if size.x >= RESPONSIVE_NARROW_W else 34.0
		bet_minus_btn.custom_minimum_size = Vector2(btn_size, btn_size)
		bet_plus_btn.custom_minimum_size = Vector2(btn_size, btn_size)


func _place_control_rect(control_node: Control, x0: float, y0: float, x1: float, y1: float) -> void:
	if control_node == null:
		return
	control_node.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	control_node.anchor_left = x0
	control_node.anchor_top = y0
	control_node.anchor_right = x1
	control_node.anchor_bottom = y1
	control_node.offset_left = 0.0
	control_node.offset_top = 0.0
	control_node.offset_right = 0.0
	control_node.offset_bottom = 0.0
	control_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control_node.grow_vertical = Control.GROW_DIRECTION_BOTH


func _refresh_spin_button_state() -> void:
	if spin_btn == null:
		return
	if spin_btn.disabled:
		spin_btn.text = "SPIN LOCKED"
	else:
		spin_btn.text = "EXECUTE"


func _refresh_encounter_win_overlay() -> void:
	if encounter_win_overlay == null:
		return
	var should_show := _safe_is_encounter_complete() and _safe_did_win_encounter()
	encounter_win_overlay.visible = should_show
	if encounter_win_label != null and should_show:
		encounter_win_label.text = "Encounter won!"


func _refresh_super_fs_choice_overlay() -> void:
	if super_fs_choice_overlay == null:
		return
	var awaiting_choice: bool = _safe_is_waiting_for_free_spin_choice()
	super_fs_choice_overlay.visible = awaiting_choice
	if choose_love_button != null:
		choose_love_button.disabled = not awaiting_choice
	if choose_star_button != null:
		choose_star_button.disabled = not awaiting_choice
	if choose_storm_button != null:
		choose_storm_button.disabled = not awaiting_choice


func _on_choose_love_pressed() -> void:
	_submit_super_fs_choice(PRINCESS_LOVE)


func _on_choose_star_pressed() -> void:
	_submit_super_fs_choice(PRINCESS_STAR)


func _on_choose_storm_pressed() -> void:
	_submit_super_fs_choice(PRINCESS_STORM)


func _submit_super_fs_choice(princess_id: StringName) -> void:
	if not combat.is_waiting_for_free_spin_choice():
		return
	combat.choose_free_spins_princess(princess_id)
	spin_btn.disabled = false
	_refresh_readouts()
	_refresh_spin_button_state()


func _goal_progress_only(goal_text: String) -> String:
	var open_idx := goal_text.find("(")
	if open_idx != -1:
		var close_idx := goal_text.find(")", open_idx + 1)
		if close_idx != -1:
			var inside := goal_text.substr(open_idx + 1, close_idx - open_idx - 1).strip_edges()
			if inside.contains("/"):
				return inside
	return "0 / 0"


func _pick_start_seed() -> int:
	var local_rng := RandomNumberGenerator.new()
	local_rng.randomize()
	return local_rng.randi_range(int(seed_spin.min_value), int(seed_spin.max_value))


func _can_queue_seed_change() -> bool:
	if Engine.is_editor_hint() and not _can_use_combat_api():
		return editor_preview_enabled
	if not _can_use_combat_api():
		return false
	if not _safe_is_encounter_complete() and _safe_get_spins_used() != 0:
		return false
	return _safe_get_combat_state() == CombatRoot.State.IDLE


func _can_apply_queued_seed_on_execute() -> bool:
	if not _can_queue_seed_change():
		return false
	if not _can_use_combat_api():
		return false
	return _queued_seed != _safe_get_current_seed()


func _set_seed_spin_value_no_signal(seed_value: int) -> void:
	if seed_spin == null:
		return
	if int(seed_spin.value) == seed_value:
		return
	seed_spin.set_value_no_signal(seed_value)


func _build_item_picker() -> void:
	if _item_picker_panel != null and is_instance_valid(_item_picker_panel):
		return
	var existing_panel := get_node_or_null("PlayArea/PlayRow/ItemPickerPanel") as PanelContainer
	if existing_panel != null:
		_item_picker_panel = existing_panel
		_item_picker_title = _item_picker_panel.get_meta("header") as Label
		return
	_item_picker_panel = _make_side_panel("ITEMS")
	_item_picker_panel.name = "ItemPickerPanel"

	var items_vbox: VBoxContainer = _item_picker_panel.get_meta("list") as VBoxContainer

	_item_picker_title = _item_picker_panel.get_meta("header") as Label
	_item_picker_title.text = "ITEMS (0/%d)" % _safe_get_item_max_slots()
	_style_side_panel_header(_item_picker_title)

	var available := _discover_available_items()
	for item in available:
		var cb := CheckBox.new()
		var rarity_idx: int = clampi(int(item.get("rarity")), 0, RARITY_GLYPHS.size() - 1)
		cb.text = "%s %s" % [RARITY_GLYPHS[rarity_idx], item.display_name]
		cb.tooltip_text = "%s | %s" % [RARITY_NAMES[rarity_idx], item.description]
		cb.add_theme_font_size_override("font_size", SIDE_PANEL_BODY_FONT)
		cb.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
		cb.toggled.connect(_on_item_checkbox_toggled.bind(item, cb))
		items_vbox.add_child(cb)
		_item_entries.append({"checkbox": cb, "item": item})

	if available.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items available"
		empty_label.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3, 0.8))
		items_vbox.add_child(empty_label)

	_item_picker_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_item_picker_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if _play_row != null:
		_play_row.add_child(_item_picker_panel)
		_reassert_node_ownership(_item_picker_panel)
	else:
		_add_preview_child(_item_picker_panel)


func _discover_available_items() -> Array:
	var found: Array = []
	var dir := DirAccess.open("res://combat/data/items")
	if dir == null:
		return found
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res := load("res://combat/data/items/".path_join(file_name))
			if res != null and res is ItemDefScript:
				found.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	found.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return found


func _on_item_checkbox_toggled(toggled_on: bool, item: Resource, cb: CheckBox) -> void:
	if not _can_use_combat_api():
		cb.set_pressed_no_signal(false)
		return
	if toggled_on:
		if not combat.equip_item(item):
			cb.set_pressed_no_signal(false)
			return
	else:
		combat.unequip_item(item)
	_refresh_item_picker_title()


func _refresh_item_picker_title() -> void:
	if _item_picker_title != null:
		_item_picker_title.text = "ITEMS (%d/%d)" % [
			_safe_get_item_inventory_size(),
			_safe_get_item_max_slots(),
		]


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
