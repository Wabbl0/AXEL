@tool
## Combat test UI — drawing-backed HUD (`HudCanvas` + white plate + piece nodes), free editor placement, integer economy.
## `HudArtGuide` (`axel_ui.png`) is optional in the 2D editor (eye icon). Play always hides it.
## Canonical entry: `res://combat/combat_test.tscn` (F6). See `README_COMBAT_TEST_VERSIONS.md`.
extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")
const QaCanonValidatorsScript := preload("res://tools/qa/qa_canon_validators.gd")
const SCAFFOLD_BASELINE_SCENE := "res://combat/combat_test_scaffold_baseline.tscn"
## Must not be re-added as local children under instanced %CombatRoot (see combat_root.tscn).
const COMBAT_ROOT_INSTANCED_CHILDREN := [
	"GridManager", "GridFrame", "GridUI", "GridFlashOverlay", "PowerIntroLayer",
	"RoundWinningsLabel", "EncounterWonLabel", "MultiplierLabel",
]
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const PRINCESS_LOVE: StringName = &"love"
const PRINCESS_STAR: StringName = &"star"
const PRINCESS_STORM: StringName = &"storm"
const RARITY_GLYPHS := ["◇", "◈", "◆", "★", "✦"]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const GRID_COLUMN_GAP := 10.0
const PREMIUM_BAR_HEIGHT := 10.0
const PREMIUM_BAR_LAYOUT_PAD := 1.0
const RESPONSIVE_NARROW_W := 900.0

## Drawing canvas size (axel_ui.png). Widgets are authored in these pixels.
const HUD_ART_SIZE := Vector2(3508.0, 2480.0)
const CENTER_COLUMN_SEPARATION := 10
const GRID_HOST_MIN_HEIGHT := 200.0
const WINNINGS_BAND_MIN_HEIGHT := 40.0
const WINNINGS_ROW_SEPARATION := 8
const CENTER_FOOTER_SEPARATION := 12
const ECONOMICS_STACK_SEPARATION := 4
## Fallback only. BALANCE and the bet strip normally auto-fit to their drawn bars.
const BANKROLL_READOUT_FONT := 36
## BALANCE + BETS share one size that almost fills the shorter of the two bars.
const ECON_BAR_FONT_FILL := 0.9
const ECON_BAR_FONT_MIN := 24
const ECON_BAR_FONT_MAX := 200
## Widest BALANCE string the bar has to hold without clipping.
const ECON_BAR_FIT_SAMPLE := "BALANCE: 0000/0000"
## The "|" dividers stay slightly shorter than the numbers, as drawn.
const BET_STRIP_SEPARATOR_FONT_RATIO := 0.875
const EXECUTE_BUTTON_MIN_HEIGHT := 72.0
const BOTTOM_WINDOW_MARGIN := 18.0

const LAYOUT_META_ICONS_SEPARATION := 4
const META_ICON_GLYPH := "⬡"
## Single knob for combat readout size (~2×). Balance / bet strip auto-fit their bars instead.
const COMBAT_TEXT_SCALE := 2.0
const META_ICON_FONT := int(round(31.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_HEADER_FONT := int(round(32.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_BODY_FONT := int(round(18.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_BODY_FONT_MIN := int(round(14.0 * COMBAT_TEXT_SCALE))
## History fits the largest size its rectangle allows; this is only the ceiling.
const HISTORY_BODY_FONT_SCALE := 3.0
## Worst-case history row ("<bet> x <symbol value> x <cascade multiplier>").
const HISTORY_FIT_SAMPLE := "1000 x 12.5 x 20"
const ITEMS_BODY_FONT_SCALE := 1.78
const ITEMS_BODY_FONT_MIN := int(round(20.0 * COMBAT_TEXT_SCALE))
## Hover description keeps its old size — it is drawn unscaled, not inside the HudCanvas.
const ITEM_DESC_BODY_FONT_SCALE := 1.25
const SIDE_PANEL_HINT_FONT := int(round(14.0 * COMBAT_TEXT_SCALE))
const ITEM_PICKER_ROW_H_SEP := 4
const ITEM_PICKER_CHECKBOX_ICON_MAX := int(round(18.0 * COMBAT_TEXT_SCALE))
const ITEM_PICKER_CHECKBOX_COL_W := int(round(22.0 * COMBAT_TEXT_SCALE))
const ITEM_ICON_DRAW_SIZE := int(round(36.0 * COMBAT_TEXT_SCALE))
const ITEM_RANK_BTN_W := int(round(88.0 * COMBAT_TEXT_SCALE))
const ITEM_RANK_BTN_TEXT_PAD := 8.0
const ITEM_RANK_BTN_FIT_SAMPLE := "Uncommon"
const ITEM_DESC_Z := 40
const ITEM_DESC_PREFERRED_WIDTH := 420.0
const ITEM_DESC_CURSOR_GAP := 8.0
const ITEM_DESC_PANEL_INSET := 8.0
const ITEM_DESC_FADE_IN := 0.08
const ITEM_DESC_BG_ALPHA := 1.0
## Whole card (panel, border, text) renders at 90% so the rows read faintly through it.
const ITEM_DESC_OPACITY := 0.9
## Own CanvasLayer above WidgetLayer (106) and below the combat CRT (108) so the card
## draws over the item rows instead of behind them.
const ITEM_DESC_LAYER_INDEX := 107
## GOAL, the spin-rewards bar and the cascade multiplier share one big size, so GOAL
## and the multiplier number always match. ~2x the old multiplier size.
const COMBAT_HUD_MAJOR_FONT := int(round(48.0 * COMBAT_TEXT_SCALE))
const COMBAT_HUD_MAJOR_FONT_NARROW := int(round(37.5 * COMBAT_TEXT_SCALE))
const WINNINGS_READOUT_FONT := COMBAT_HUD_MAJOR_FONT
const CASCADE_MULT_READOUT_FONT := COMBAT_HUD_MAJOR_FONT
const WINNINGS_READOUT_OUTLINE := 0
const CASCADE_MULT_READOUT_OUTLINE := 0
const READOUT_ACCENT_COLOR := Color(0.98, 0.35, 0.35, 1.0)
const STAKE_BUTTON_SIZE := 34.0
const STAKE_BUTTON_SIZE_NARROW := 28.0
const WINNINGS_COUNTER_MAX_DURATION := 0.25
const WINNINGS_COUNTER_MIN_STEP := 0.004
const WINNINGS_COUNTER_MAX_STEP := 0.02
const HISTORY_MINI_ICON_SIZE := int(round(18.0 * COMBAT_TEXT_SCALE))
const HISTORY_ROW_SEPARATION := 3
const HUD_WHITE_TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const HUD_WHITE_TEXT_SHADOW_COLOR := Color(0.22, 0.22, 0.22, 0.72)
const HUD_WHITE_TEXT_SHADOW_OFFSET_Y := 1
const SETTINGS_PANEL_SCENE := preload("res://combat/scenes/combat_settings_panel.tscn")
const BET_STRIP_TWEEN_SEC := 0.15
const GOAL_READOUT_FONT := COMBAT_HUD_MAJOR_FONT
const GOAL_READOUT_FONT_NARROW := COMBAT_HUD_MAJOR_FONT_NARROW
const PREMIUM_BAR_COLORS := [
	Color(0.22, 0.22, 0.22, 1.0),
	Color(0.55, 0.12, 0.12, 1.0),
	Color(0.78, 0.08, 0.08, 1.0),
	Color(0.95, 0.08, 0.08, 1.0),
]

var RARITY_COLORS: Dictionary = {
	0: Color(0.65, 0.65, 0.65),
	1: Color(0.4, 0.78, 0.4),
	2: Color(0.4, 0.6, 0.9),
	3: Color(0.72, 0.4, 0.88),
	4: Color(0.95, 0.75, 0.2),
}

@export_group("Editor Preview")
## Deprecated: editor now shows authored HudCanvas placement without percentage layout.
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
var _hud_canvas: Control
var _play_area: Control
var _play_row: Control
var _center_column: Control
var _center_footer: Control
var _bottom_window_margin: Control
var _winnings_center: CenterContainer
var _grid_host: Control
var _premium_progress: ProgressBar
var _spin_history_panel: PanelContainer
var _history_spin_list: VBoxContainer
var _item_picker_panel: PanelContainer
var _item_picker_title: Label
## Row name strings per row kind, used to fit the item body font against real widths.
var _item_row_texts: Dictionary = {
	&"family": PackedStringArray(),
	&"unique": PackedStringArray(),
}
var _item_desc_layer: CanvasLayer
var _item_desc_clip: Control
var _item_desc_panel: PanelContainer
var _item_desc_label: Label
var _item_desc_hover_row: Control
var _item_desc_fade: Tween
var _item_entries: Array = []
var _family_rank: Dictionary = {}
var _ignore_cap_checkbox: CheckBox
var _reroll_used_spin: SpinBox
var _reroll_budget_spin: SpinBox
var _limit_spins_checkbox: CheckBox
var _reroll_hint_label: Label
var _goal_base_spin: SpinBox
var _goal_progress_spin: SpinBox
var _goal_effective_label: Label
var _playtest_tuning: VBoxContainer
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
const FALLBACK_CELL_SIZE_MIN := 48.0

var _fallback_grid_width: float = 0.0
var _spin_busy: bool = false
var _piece_goal: CombatHudPiece
var _piece_items: CombatHudPiece
var _piece_history: CombatHudPiece
var _piece_multiplier: CombatHudPiece
var _piece_settings: CombatHudPiece
var _piece_execute: CombatHudPiece
var _piece_bet_minus: CombatHudPiece
var _piece_bet_plus: CombatHudPiece
var _piece_bet_strip: CombatHudPiece
var _piece_balance: CombatHudPiece
var _piece_premium_bar: CombatHudPiece
var _piece_spin_money: CombatHudPiece
var _premium_bar_fill: ColorRect
var _premium_skull: Node
var _settings_panel: CanvasLayer
var _bet_strip_row: HBoxContainer
var _bet_strip_labels: Array[Label] = []
var _bet_strip_tween: Tween
var _widgets_bound_to_pieces: bool = false
var _last_spin_money_text: String = ""
var _widget_layer: Node
var _piece_grid: CombatHudPiece
var _skull_click_polygon: Node
var _spin_request_frame: int = -1

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
	# Catch numbered suffix drift like GridFrame2, GridFrame3, etc.
	for child in combat.get_children():
		var name_s := String(child.name)
		for base_name in COMBAT_ROOT_INSTANCED_CHILDREN:
			if not name_s.begins_with(base_name) or name_s == base_name:
				continue
			var suffix := name_s.substr(base_name.length())
			if suffix.is_empty():
				continue
			var n := suffix.to_int()
			if n >= 2 and str(n) == suffix:
				dupes.append(name_s)
				break
	if not dupes.is_empty():
		push_error(
			(
				"CombatTest: duplicate CombatRoot children: %s. "
				+ "Remove inline grid nodes from combat_test.tscn; use instanced combat_root.tscn only "
				+ "(pre-commit: tools/qa/check_combat_test_scaffold.py)."
			) % ", ".join(dupes)
		)

func _prune_orphan_economics_stacks() -> void:
	if _economics_center == null or not is_instance_valid(_economics_center):
		return
	for child in _economics_center.get_children():
		if child == _economics_stack:
			continue
		if child is VBoxContainer and (String(child.name).begins_with("@VBoxContainer@") or child.name == "EconomicsStack"):
			child.queue_free()

func _suppress_combat_root_legacy_labels() -> void:
	if combat == null:
		return
	for node_name in ["MultiplierLabel", "RoundWinningsLabel", "EncounterWonLabel"]:
		var legacy := combat.get_node_or_null(node_name) as CanvasItem
		if legacy != null:
			legacy.visible = false

func _get_center_column_interior_width(default_w: float) -> float:
	if _grid_host != null and _grid_host.size.x >= 64.0:
		return _grid_host.size.x
	if _center_column != null and _center_column.size.x >= 64.0:
		return _center_column.size.x
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
	## Mirrors combat_root.fit_to_panel: fill the host exactly with the drawing's cell aspect.
	var cell := Vector2(
		maxf((safe_w - float(FALLBACK_GRID_COLS - 1) * sep_h) / float(FALLBACK_GRID_COLS), FALLBACK_CELL_SIZE_MIN),
		maxf((safe_h - float(FALLBACK_GRID_ROWS - 1) * sep_v) / float(FALLBACK_GRID_ROWS), FALLBACK_CELL_SIZE_MIN)
	)
	var grid_width := float(FALLBACK_GRID_COLS) * cell.x + float(FALLBACK_GRID_COLS - 1) * sep_h
	var grid_height := float(FALLBACK_GRID_ROWS) * cell.y + float(FALLBACK_GRID_ROWS - 1) * sep_v
	var grid_x := maxf((safe_w - grid_width) * 0.5, 0.0)
	var grid_y := 0.0
	grid_ui.position = Vector2(grid_x, grid_y)
	grid_ui.size = Vector2(grid_width, grid_height)
	for child in grid_ui.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = cell
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
	_hide_hud_art_guide_in_game()
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
	_hud_canvas = _resolve_scaffold_node("HudCanvas") as Control
	if _hud_canvas == null:
		_hud_canvas = get_node_or_null("HudCanvas") as Control
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
	_gate_local_scanline_for_room_fx_test()
	_organize_top_hud()
	_configure_hud_layers()
	_ensure_play_shell()
	_hide_legacy_meter_nodes()
	_configure_stake_display()
	_style_stake_buttons()
	_configure_spin_button_layer()
	if budget_label != null:
		budget_label.visible = false
	_build_item_picker()
	_apply_side_panel_typography()
	if not resized.is_connected(_on_size_changed):
		resized.connect(_on_size_changed)

func _gate_local_scanline_for_room_fx_test() -> void:
	## Hide combat's own scanline when room FX are attached (avoids double scanlines).
	var scanline := get_node_or_null("ScanlineOverlay") as CanvasItem
	if scanline == null:
		return
	scanline.visible = not AxelPostFxStack.COMBAT_ROOM_FX_TEST

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
	_wire_piece_input_signals()

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
	_bind_widgets_to_pieces()
	_apply_hud_chrome()
	await get_tree().process_frame
	_layout_combat()
	_ensure_editor_grid_shell_visible()
	_refresh_editor_placeholder_readouts()
	_reassert_scaffold_ownership()
	_validate_editor_combat_root_structure()
	_validate_editor_economics_structure()

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

func _validate_editor_economics_structure() -> void:
	if not Engine.is_editor_hint():
		return
	var validators := load("res://tools/qa/qa_canon_validators.gd") as Script
	var violations: PackedStringArray = PackedStringArray()
	if validators != null:
		violations = PackedStringArray(validators.call("check_economics_center_uniqueness", self))
	if violations.is_empty():
		return
	push_error(
		"CombatTest Economics structure drift: %s. "
		% ", ".join(violations)
		+ " Keep a single EconomicsStack under EconomicsCenter; remove orphan @VBoxContainer stacks. "
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
	for node in [mult_label, bankroll_label, goal_label, seed_spin, _cascade_mult_label]:
		if node is CanvasItem:
			(node as CanvasItem).visible = true
	if bet_label != null:
		bet_label.visible = false
	if _cascade_mult_pill != null:
		_cascade_mult_pill.visible = false

func _organize_top_hud() -> void:
	if top_bar != null:
		top_bar.visible = false
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_ensure_hud_canvas_parent(meta_box)
	_ensure_hud_canvas_parent(goal_box)
	_strip_corner_panel_boxes()
	_configure_top_corner_hud()
	_configure_white_hud_readouts()
	_integrate_economics_into_center_hud()

func _hud_canvas_node() -> Control:
	if _hud_canvas != null and is_instance_valid(_hud_canvas):
		return _hud_canvas
	_hud_canvas = _resolve_scaffold_node("HudCanvas") as Control
	if _hud_canvas == null:
		_hud_canvas = get_node_or_null("HudCanvas") as Control
	return _hud_canvas

func _ensure_hud_canvas_parent(node: Control) -> void:
	if node == null:
		return
	var canvas := _hud_canvas_node()
	if canvas == null:
		return
	if node.get_parent() == canvas:
		_reassert_node_ownership(node)
		return
	_reparent_for_layout(node, canvas)

func _reparent_hud_to_root(node: Control) -> void:
	## Legacy helper — keep widgets under HudCanvas when present.
	_ensure_hud_canvas_parent(node)

func _hide_legacy_meter_nodes() -> void:
	var meter_stack := get_node_or_null("RightMeterStack")
	if meter_stack != null:
		meter_stack.visible = false
	var meter_circle := get_node_or_null("RightMeterStack/PremiumMeterCircle")
	if meter_circle == null:
		meter_circle = get_node_or_null("%PremiumMeterCircle")
	if meter_circle != null:
		meter_circle.visible = false
	if _premium_progress != null:
		_premium_progress.visible = false
	else:
		var bar := find_child("PremiumProgressBar", true, false) as CanvasItem
		if bar != null:
			bar.visible = false
	if _winnings_center != null:
		_winnings_center.visible = false
	else:
		var winnings := find_child("WinningsCenter", true, false) as CanvasItem
		if winnings != null:
			winnings.visible = false
	if budget_label != null:
		budget_label.visible = false
	for pill_name in ["WinningsReadoutPill", "CascadeMultiplierPill"]:
		var pill := find_child(pill_name, true, false) as CanvasItem
		if pill != null:
			pill.visible = false
	if meta_box != null:
		var icons := meta_box.get_node_or_null("MetaContent/MetaIconsRow") as CanvasItem
		if icons != null:
			icons.visible = false
	_suppress_combat_root_legacy_labels()

func _hide_hud_art_guide_in_game() -> void:
	## Play / headless never draw the composite guide. Editor keeps the scene-tree eye (do not force it back on).
	var guide := _resolve_scaffold_node("HudArtGuide") as CanvasItem
	if guide == null:
		guide = get_node_or_null("HudCanvas/HudArtGuide") as CanvasItem
	if guide == null:
		return
	if Engine.is_editor_hint():
		return
	guide.visible = false

func _ensure_play_shell() -> void:
	if _hud_canvas_node() != null and _restore_play_shell_from_scene():
		_finalize_play_shell_layout()
		return
	if _restore_play_shell_from_scene():
		_finalize_play_shell_layout()
		return
	_build_play_shell()

func _restore_play_shell_from_scene() -> bool:
	var area := find_child("PlayArea", true, false) as Control
	if area == null:
		return false
	_play_area = area
	_play_row = area.get_node_or_null("PlayRow") as Control
	if _play_row == null:
		return false
	_spin_history_panel = _play_row.get_node_or_null("HistoryPanel") as PanelContainer
	_bind_history_spin_list_from_panel(_spin_history_panel)
	_center_column = _play_row.get_node_or_null("CenterColumn") as Control
	if _center_column == null:
		return false
	_grid_host = _center_column.get_node_or_null("GridHost") as Control
	if _grid_host == null:
		_grid_host = find_child("GridHost", true, false) as Control
	_winnings_center = _center_column.get_node_or_null("WinningsCenter") as CenterContainer
	_center_footer = _center_column.get_node_or_null("CenterFooter") as Control
	_bottom_window_margin = _center_column.get_node_or_null("BottomWindowMargin") as Control
	if _grid_host != null:
		_premium_progress = _grid_host.get_node_or_null("PremiumProgressBar") as ProgressBar
		if _premium_progress == null:
			_premium_progress = find_child("PremiumProgressBar", true, false) as ProgressBar
	var winnings_row: HBoxContainer = null
	if _winnings_center != null:
		winnings_row = _winnings_center.get_node_or_null("WinningsRow") as HBoxContainer
	if winnings_row != null:
		_cascade_mult_label = winnings_row.get_node_or_null("CascadeMultiplierPill/CascadeMultiplierReadout") as Label
		_cascade_mult_pill = winnings_row.get_node_or_null("CascadeMultiplierPill") as PanelContainer
		if _cascade_mult_label == null:
			_cascade_mult_label = winnings_row.get_node_or_null("CascadeMultiplierReadout") as Label
		_configure_winnings_readout()
		_configure_cascade_multiplier_readout()
	return _grid_host != null and _center_footer != null

func _finalize_play_shell_layout() -> void:
	if combat == null or _grid_host == null:
		return
	if combat.get_parent() != _grid_host:
		combat.reparent(_grid_host)
	combat.visible = true
	_suppress_combat_root_legacy_labels()
	if spin_btn != null:
		spin_btn.visible = true
	if mult_label != null and mult_label.visible:
		mult_label.visible = true
	_wire_winnings_popup_target()

func _build_play_shell() -> void:
	var canvas := _hud_canvas_node()
	_play_area = Control.new()
	_play_area.name = "PlayArea"
	_play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if canvas != null:
		canvas.add_child(_play_area)
	else:
		_add_preview_child(_play_area)
		move_child(_play_area, 1)

	_play_row = Control.new()
	_play_row.name = "PlayRow"
	_play_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_area.add_child(_play_row)
	_reassert_node_ownership(_play_row)

	_spin_history_panel = _build_history_placeholder()
	_play_row.add_child(_spin_history_panel)
	_reassert_node_ownership(_spin_history_panel)

	_center_column = Control.new()
	_center_column.name = "CenterColumn"
	_center_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_row.add_child(_center_column)
	_reassert_node_ownership(_center_column)

	_grid_host = Control.new()
	_grid_host.name = "GridHost"
	_grid_host.custom_minimum_size = Vector2(260, GRID_HOST_MIN_HEIGHT)
	_grid_host.clip_contents = true
	var widget_root: Control = null
	if _widget_layer != null and _widget_layer.has_method("get_widget_root"):
		widget_root = _widget_layer.get_widget_root() as Control
	if widget_root == null:
		widget_root = find_child("WidgetRoot", true, false) as Control
	if widget_root != null:
		widget_root.add_child(_grid_host)
	else:
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
	_premium_progress.visible = false

	_winnings_center = CenterContainer.new()
	_winnings_center.name = "WinningsCenter"
	_winnings_center.visible = false
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

	_center_footer = Control.new()
	_center_footer.name = "CenterFooter"
	_center_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_column.add_child(_center_footer)
	_reassert_node_ownership(_center_footer)

	if spin_btn != null:
		spin_btn.visible = true
		spin_btn.text = ""
		_reparent_for_layout(spin_btn, _center_footer)

	_bottom_window_margin = Control.new()
	_bottom_window_margin.name = "BottomWindowMargin"
	_bottom_window_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var canvas := _hud_canvas_node()
	if _economics_center == null:
		var existing_ec := find_child("EconomicsCenter", true, false) as CenterContainer
		if existing_ec != null:
			_economics_center = existing_ec
		else:
			_economics_center = CenterContainer.new()
			_economics_center.name = "EconomicsCenter"
			_economics_center.mouse_filter = Control.MOUSE_FILTER_PASS
			if canvas != null:
				canvas.add_child(_economics_center)
			else:
				_add_preview_child(_economics_center)
	elif canvas != null and _economics_center.get_parent() != canvas:
		_reparent_for_layout(_economics_center, canvas)

	if _economics_stack == null and _economics_center != null:
		_economics_stack = _economics_center.get_node_or_null("EconomicsStack") as VBoxContainer
	if _economics_stack == null:
		_economics_stack = VBoxContainer.new()
		_economics_stack.name = "EconomicsStack"
		_economics_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		_economics_stack.add_theme_constant_override("separation", ECONOMICS_STACK_SEPARATION)
		_economics_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_economics_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_economics_center.add_child(_economics_stack)

	_prune_orphan_economics_stacks()

	if bankroll_label != null:
		bankroll_label.visible = true
		bankroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bankroll_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bankroll_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if bankroll_label.get_parent() != _economics_stack:
			_reparent_for_layout(bankroll_label, _economics_stack)

	if stake_selector != null:
		stake_selector.visible = true
		stake_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		stake_selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if stake_selector.get_parent() != _economics_stack:
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
	if goal_box != null:
		goal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var meta_content := meta_box.get_node_or_null("MetaContent") as VBoxContainer
	if meta_content != null:
		meta_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var seed_row := meta_box.get_node_or_null("MetaContent/SeedRow") as HBoxContainer
	if seed_row != null:
		seed_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		seed_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _configure_white_hud_readouts() -> void:
	for label in [bankroll_label, bet_label, goal_label, encounter_win_label]:
		if label != null:
			_apply_white_hud_text_style(label)

func _apply_white_hud_text_style(label: Label) -> void:
	label.add_theme_color_override("font_color", HUD_WHITE_TEXT_COLOR)
	label.remove_theme_color_override("font_outline_color")
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", HUD_WHITE_TEXT_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", HUD_WHITE_TEXT_SHADOW_OFFSET_Y)

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
	mult_label.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
	mult_label.remove_theme_color_override("font_outline_color")
	mult_label.add_theme_constant_override("outline_size", WINNINGS_READOUT_OUTLINE)

func _configure_cascade_multiplier_readout() -> void:
	if _cascade_mult_label == null:
		return
	_cascade_mult_label.add_theme_font_size_override("font_size", CASCADE_MULT_READOUT_FONT)
	_cascade_mult_label.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
	_cascade_mult_label.remove_theme_color_override("font_outline_color")
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

func _side_panel_style() -> StyleBox:
	return StyleBoxEmpty.new()

func _side_panel_title_style() -> StyleBox:
	return StyleBoxEmpty.new()

func _style_side_panel_header(header: Label) -> void:
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", SIDE_PANEL_HEADER_FONT)
	header.add_theme_color_override("font_color", Color(0.88, 0.4, 0.4, 1.0))
	header.visible = false

func _bind_history_spin_list_from_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	var existing := panel.find_child("HistorySpinList", true, false) as VBoxContainer
	if existing != null:
		_history_spin_list = existing
		return
	var header := panel.get_meta("header") as Label
	if header != null:
		_style_side_panel_header(header)
	var list_root := panel.get_meta("list") as VBoxContainer
	if list_root == null:
		return
	_history_spin_list = VBoxContainer.new()
	_history_spin_list.name = "HistorySpinList"
	_history_spin_list.add_theme_constant_override("separation", HISTORY_ROW_SEPARATION)
	list_root.add_child(_history_spin_list)
	_reassert_node_ownership(_history_spin_list)

func _apply_side_panel_typography() -> void:
	for panel in [_spin_history_panel, _item_picker_panel]:
		if panel == null:
			continue
		panel.add_theme_stylebox_override("panel", _side_panel_style())
		var header := panel.get_meta("header") as Label
		if header != null:
			_style_side_panel_header(header)
		var header_strip := header.get_parent() as PanelContainer if header != null else null
		if header_strip != null:
			header_strip.add_theme_stylebox_override("panel", _side_panel_title_style())
			header_strip.visible = false
		for section in panel.find_children("SectionHeader", "Label", true, false):
			if section is CanvasItem:
				(section as CanvasItem).visible = false
	_apply_item_picker_body_typography()

func _apply_item_picker_body_typography() -> void:
	if _item_picker_panel == null:
		return
	var body_font := _resolved_items_body_font()
	for child in _item_picker_panel.find_children("*", "CheckBox", true, false):
		var cb := child as CheckBox
		if cb == null:
			continue
		# Item rows use fixed checkbox columns; do not re-expand them.
		if cb.get_meta("item_row_checkbox", false):
			_style_item_row_checkbox(cb, body_font)
		else:
			_style_item_picker_checkbox(cb, body_font)
	for child in _item_picker_panel.find_children("*", "Label", true, false):
		var label := child as Label
		if label == _item_picker_title:
			continue
		if label.name == "SectionHeader":
			continue
		if bool(label.get_meta("item_row_name", false)):
			label.add_theme_font_size_override("font_size", body_font)
			continue
		if label.text == "No items available":
			label.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
	var rank_font := _resolved_item_rank_font()
	for child in _item_picker_panel.find_children("*", "Button", true, false):
		var btn := child as Button
		if btn == null or not bool(btn.get_meta("item_rank_button", false)):
			continue
		btn.add_theme_font_size_override("font_size", rank_font)
	for child in _item_picker_panel.find_children("*", "TextureRect", true, false):
		var icon := child as TextureRect
		if icon == null or not bool(icon.get_meta("item_row_icon", false)):
			continue
		icon.custom_minimum_size = Vector2(ITEM_ICON_DRAW_SIZE, ITEM_ICON_DRAW_SIZE)

func _style_item_picker_checkbox(cb: CheckBox, body_font: int = -1) -> void:
	if cb == null:
		return
	if body_font < 0:
		body_font = _resolved_items_body_font()
	cb.add_theme_font_size_override("font_size", body_font)
	cb.add_theme_constant_override("h_separation", ITEM_PICKER_ROW_H_SEP)
	cb.add_theme_constant_override("icon_max_width", ITEM_PICKER_CHECKBOX_ICON_MAX)
	cb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _style_item_row_checkbox(cb: CheckBox, body_font: int = -1) -> void:
	if cb == null:
		return
	if body_font < 0:
		body_font = _resolved_items_body_font()
	cb.add_theme_font_size_override("font_size", body_font)
	cb.add_theme_constant_override("h_separation", ITEM_PICKER_ROW_H_SEP)
	cb.add_theme_constant_override("icon_max_width", ITEM_PICKER_CHECKBOX_ICON_MAX)
	cb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cb.custom_minimum_size.x = float(ITEM_PICKER_CHECKBOX_COL_W)

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
		list.alignment = BoxContainer.ALIGNMENT_BEGIN
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

func _configure_stake_display() -> void:
	if bet_label == null:
		return
	var bet_row := bet_label.get_parent() as HBoxContainer
	if bet_row == null:
		bet_row = bet_label.get_parent().get_parent() as HBoxContainer if bet_label.get_parent() != null else null
	if bet_label.get_parent() is PanelContainer:
		var pill := bet_label.get_parent() as PanelContainer
		bet_row = pill.get_parent() as HBoxContainer
		if bet_row != null:
			var idx := pill.get_index()
			_reparent_for_layout(bet_label, bet_row)
			bet_row.move_child(bet_label, idx)
			pill.queue_free()
			_stake_pill = null
	elif bet_label.get_parent() != null and bet_label.get_parent().name == "StakePill":
		var pill_node := bet_label.get_parent()
		bet_row = pill_node.get_parent() as HBoxContainer
		if bet_row != null:
			var idx := pill_node.get_index()
			_reparent_for_layout(bet_label, bet_row)
			bet_row.move_child(bet_label, idx)
			pill_node.queue_free()
			_stake_pill = null
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _stake_button_style() -> StyleBoxFlat:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	flat.border_color = Color(0.78, 0.03, 0.03, 0.85)
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(2)
	flat.content_margin_left = 4
	flat.content_margin_right = 4
	flat.content_margin_top = 2
	flat.content_margin_bottom = 2
	return flat

func _style_stake_buttons() -> void:
	_cache_hud_pieces()
	## The live buttons sit above the drawings and eat the hover, so they own the cursor.
	for btn in [bet_minus_btn, bet_plus_btn]:
		if btn == null:
			continue
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## Piece drawings own +/- look; do not paint the old computer boxes on top.
	if _piece_bet_minus != null or _piece_bet_plus != null:
		var empty := StyleBoxEmpty.new()
		for btn in [bet_minus_btn, bet_plus_btn]:
			if btn == null:
				continue
			btn.add_theme_stylebox_override("normal", empty)
			btn.add_theme_stylebox_override("hover", empty)
			btn.add_theme_stylebox_override("pressed", empty)
			btn.add_theme_stylebox_override("focus", empty)
			btn.add_theme_stylebox_override("disabled", empty)
		return
	for btn in [bet_minus_btn, bet_plus_btn]:
		if btn == null:
			continue
		var flat := _stake_button_style()
		btn.add_theme_stylebox_override("normal", flat)
		btn.add_theme_stylebox_override("hover", flat.duplicate())
		btn.add_theme_stylebox_override("pressed", flat.duplicate())
		btn.add_theme_stylebox_override("focus", flat.duplicate())
		btn.add_theme_stylebox_override("disabled", flat.duplicate())

func _on_spin_pressed() -> void:
	await _request_spin()


func _request_spin() -> void:
	if Engine.is_editor_hint():
		return
	var frame := Engine.get_process_frames()
	if _spin_request_frame == frame:
		return
	if _spin_busy:
		return
	if combat == null or not _can_use_combat_api():
		return
	_spin_request_frame = frame
	_spin_busy = true
	if combat.is_encounter_complete():
		combat.begin_next_playtest_encounter(_queued_seed)
	if _can_apply_queued_seed_on_execute():
		combat.setup_new_grid(_queued_seed)
	if spin_btn != null:
		spin_btn.disabled = true
	_refresh_spin_button_state()
	await combat.spin()
	if spin_btn != null:
		spin_btn.disabled = false
	_spin_busy = false
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
		bankroll_label.text = "BALANCE: %d/%d" % [bankroll_units, cap_units]
	if goal_label != null:
		goal_label.text = "GOAL:\n%s" % _goal_progress_only(_safe_get_goal_label())
	_refresh_bet_strip()
	_sync_skull_meter(_safe_get_meter_sections_filled())
	_sync_premium_bar_color(_safe_get_meter_sections_filled())
	_maybe_pop_spin_money()
	_refresh_playtest_readouts()
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
		_cascade_mult_label.text = "1X"
	_last_displayed_cascade_mult = 1
	if _premium_progress != null:
		_premium_progress.value = 0.0
	if bankroll_label != null:
		bankroll_label.text = "BALANCE: %d/%d" % [EDITOR_FALLBACK_BANKROLL, EDITOR_FALLBACK_BANKROLL_CAP]
	if goal_label != null:
		goal_label.text = "GOAL:\n0 / 0"
	_refresh_bet_strip()
	_sync_skull_meter(0)
	_sync_premium_bar_color(0)
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
	return "%dX" % mult

func _pulse_cascade_multiplier() -> void:
	if _piece_multiplier != null:
		_piece_multiplier.pop()
		return
	if _cascade_mult_pill == null:
		return
	_cascade_mult_pill.scale = Vector2.ONE
	_cascade_mult_pill.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var peak := create_tween()
	peak.set_parallel(true)
	peak.tween_property(_cascade_mult_pill, "modulate", Color(1.25, 0.35, 0.35, 1.0), 0.1)
	peak.tween_property(_cascade_mult_pill, "scale", Vector2(1.06, 1.06), 0.1)
	var settle := peak.chain()
	settle.set_parallel(true)
	settle.tween_property(_cascade_mult_pill, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
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
	if _piece_premium_bar != null:
		_piece_premium_bar.pop()
	elif _premium_progress != null:
		var peak := create_tween()
		peak.tween_property(_premium_progress, "modulate", Color(1.4, 1.1, 1.1, 1.0), 0.12)
		peak.tween_property(_premium_progress, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_premium_meter_changed(_previous_sections: int, next_sections: int) -> void:
	if _premium_progress != null and _piece_premium_bar == null:
		var tween := create_tween()
		tween.tween_property(_premium_progress, "value", float(next_sections), 0.2)
	_sync_skull_meter(next_sections)
	_sync_premium_bar_color(next_sections, true)

func _on_seed_spin_value_changed(value: float) -> void:
	if not _can_queue_seed_change():
		return
	_queued_seed = int(value)
	_refresh_readouts()
	_refresh_spin_button_state()

func _on_bet_minus_pressed() -> void:
	combat.step_bet(-1)
	_refresh_readouts()
	_animate_bet_strip()

func _on_bet_plus_pressed() -> void:
	combat.step_bet(1)
	_refresh_readouts()
	_animate_bet_strip()

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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", HISTORY_ROW_SEPARATION)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_size := _history_mini_icon_size()
	var tex: Texture2D = event.get("texture") as Texture2D
	if tex != null:
		var icon := TextureRect.new()
		icon.name = "HistorySymbolIcon"
		icon.texture = tex
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	var row_label := Label.new()
	row_label.text = "%d x %s x %d" % [bet, _format_history_factor(symbol_value), cascade_mult]
	row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row_label.clip_text = true
	row_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_apply_history_text_style(row_label)
	row.add_child(row_label)
	_history_spin_list.add_child(row)

func _apply_history_text_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", _resolved_history_body_font())
	_apply_white_hud_text_style(label)

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


func _find_hud_piece(piece_name: String) -> CombatHudPiece:
	var node := find_child(piece_name, true, false)
	if node == null and piece_name.begins_with("MOVE_"):
		node = find_child("NEW_" + piece_name.trim_prefix("MOVE_"), true, false)
	if node == null and not piece_name.begins_with("NEW_") and not piece_name.begins_with("MOVE_"):
		node = find_child("NEW_" + piece_name.trim_prefix("Piece"), true, false)
		if node == null:
			node = find_child("MOVE_" + piece_name.trim_prefix("Piece"), true, false)
	return node as CombatHudPiece


func _cache_hud_pieces() -> void:
	_piece_goal = _find_hud_piece("NEW_Goal")
	_piece_items = _find_hud_piece("NEW_Items")
	_piece_history = _find_hud_piece("NEW_History")
	_piece_multiplier = _find_hud_piece("NEW_Multiplier")
	_piece_settings = _find_hud_piece("NEW_Settings")
	_piece_execute = _find_hud_piece("NEW_Execute")
	_piece_grid = _find_hud_piece("NEW_Grid")
	_piece_bet_minus = _find_hud_piece("MOVE_BetMinus")
	_piece_bet_plus = _find_hud_piece("MOVE_BetPlus")
	_piece_bet_strip = _find_hud_piece("MOVE_BetStrip")
	_piece_balance = _find_hud_piece("MOVE_Balance")
	_piece_premium_bar = _find_hud_piece("MOVE_PremiumBar")
	_piece_spin_money = _find_hud_piece("MOVE_SpinMoney")
	if _piece_premium_bar != null:
		_premium_bar_fill = _piece_premium_bar.get_node_or_null("PremiumBarFill") as ColorRect
	_premium_skull = find_child("PremiumSkull", true, false)
	_skull_click_polygon = find_child("SkullClickPolygon", true, false)
	_widget_layer = get_node_or_null("WidgetLayer")
	if _widget_layer == null:
		_widget_layer = find_child("WidgetLayer", true, false)


func _host_for_piece(piece: CombatHudPiece, id: String) -> Control:
	if piece == null or _widget_layer == null or not _widget_layer.has_method("register"):
		return null
	var box := piece.get_text_box()
	if box == null:
		return null
	return _widget_layer.register(box, id) as Control


func _bind_widgets_to_pieces() -> void:
	if Engine.is_editor_hint() and not editor_preview_enabled and not _is_editor_preview():
		## Still bind in editor so TextBox previews look correct when opening the scene.
		pass
	_cache_hud_pieces()
	_cache_scene_refs()
	if _piece_goal != null and goal_label != null:
		if goal_box != null:
			goal_box.visible = false
		_piece_goal.attach(goal_label, _host_for_piece(_piece_goal, "goal"))
		goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _piece_items != null and _item_picker_panel != null:
		_piece_items.attach(_item_picker_panel, _host_for_piece(_piece_items, "items"))
	if _piece_history != null and _spin_history_panel != null:
		_piece_history.attach(_spin_history_panel, _host_for_piece(_piece_history, "history"))
	if _piece_multiplier != null and _cascade_mult_label != null:
		_piece_multiplier.attach(_cascade_mult_label, _host_for_piece(_piece_multiplier, "multiplier"))
	if _cascade_mult_pill != null:
		_cascade_mult_pill.visible = false
	if _piece_balance != null and bankroll_label != null:
		_piece_balance.attach(bankroll_label, _host_for_piece(_piece_balance, "balance"))
		bankroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bankroll_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _piece_bet_strip != null and bet_label != null:
		## Keep %BetLabel for scaffold; hide it and show the sliding strip instead.
		_piece_bet_strip.attach(bet_label, _host_for_piece(_piece_bet_strip, "bet_strip"))
		bet_label.visible = false
		_ensure_bet_strip_row()
	if _piece_bet_minus != null and bet_minus_btn != null:
		_piece_bet_minus.attach(bet_minus_btn, _host_for_piece(_piece_bet_minus, "bet_minus"))
		bet_minus_btn.text = ""
	if _piece_bet_plus != null and bet_plus_btn != null:
		_piece_bet_plus.attach(bet_plus_btn, _host_for_piece(_piece_bet_plus, "bet_plus"))
		bet_plus_btn.text = ""
	if _piece_spin_money != null and mult_label != null:
		_piece_spin_money.attach(mult_label, _host_for_piece(_piece_spin_money, "spin_money"))
	if _winnings_center != null:
		_winnings_center.visible = false
	var winnings_pill := find_child("WinningsReadoutPill", true, false) as CanvasItem
	if winnings_pill != null:
		winnings_pill.visible = false
	if _piece_execute != null and spin_btn != null:
		## Authored under NEW_Execute; keep transparent and mouse-ignore (piece/polygon click).
		if spin_btn.get_parent() != _piece_execute:
			spin_btn.reparent(_piece_execute)
		spin_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		spin_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spin_btn.z_index = 5
		var empty := StyleBoxEmpty.new()
		spin_btn.add_theme_stylebox_override("normal", empty)
		spin_btn.add_theme_stylebox_override("pressed", empty)
		spin_btn.add_theme_stylebox_override("hover", empty)
		spin_btn.add_theme_stylebox_override("disabled", empty)
		spin_btn.text = ""
	_bind_grid_host_to_piece()
	if _economics_center != null:
		_economics_center.visible = false
	if meta_box != null:
		meta_box.visible = false
	if goal_box != null:
		goal_box.visible = false
	if _premium_progress != null:
		_premium_progress.visible = false
	_ensure_settings_panel()
	_wire_piece_input_signals()
	## Slide, not just recolour, so the strip opens with the current bet centred.
	_animate_bet_strip()
	_sync_skull_meter(_safe_get_meter_sections_filled())
	_sync_premium_bar_color(_safe_get_meter_sections_filled())
	_widgets_bound_to_pieces = true


func _bind_grid_host_to_piece() -> void:
	if _piece_grid == null or _grid_host == null:
		return
	var box := _piece_grid.get_text_box()
	if box == null:
		return
	if _widget_layer != null and _widget_layer.has_method("register"):
		_widget_layer.register(box, "grid", _grid_host)
	_grid_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_host.clip_contents = true


func _wire_piece_input_signals() -> void:
	if _piece_execute != null and not _piece_execute.activated.is_connected(_on_piece_execute_activated):
		_piece_execute.activated.connect(_on_piece_execute_activated)
	## Skull polygon is display/editor only — Execute MOVE_TextBox owns the click.
	if _skull_click_polygon != null:
		if _skull_click_polygon is Control:
			(_skull_click_polygon as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _skull_click_polygon.has_signal("pressed"):
			if _skull_click_polygon.pressed.is_connected(_on_piece_execute_activated):
				_skull_click_polygon.pressed.disconnect(_on_piece_execute_activated)
	## Skull art is display-only; disconnect any leftover pressed wiring.
	if _premium_skull != null and _premium_skull.has_signal("pressed"):
		if _premium_skull.pressed.is_connected(_on_piece_execute_activated):
			_premium_skull.pressed.disconnect(_on_piece_execute_activated)
		if _premium_skull is Control:
			(_premium_skull as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _piece_settings != null and not _piece_settings.activated.is_connected(_on_settings_activated):
		_piece_settings.activated.connect(_on_settings_activated)


func _on_piece_execute_activated() -> void:
	await _request_spin()


func _ensure_settings_panel() -> void:
	if Engine.is_editor_hint():
		return
	if _settings_panel != null and is_instance_valid(_settings_panel):
		return
	_settings_panel = SETTINGS_PANEL_SCENE.instantiate() as CanvasLayer
	add_child(_settings_panel)


func _on_settings_activated() -> void:
	_ensure_settings_panel()
	if _settings_panel != null and _settings_panel.has_method("toggle_panel"):
		_settings_panel.toggle_panel()


func _ensure_bet_strip_row() -> void:
	if _piece_bet_strip == null:
		return
	var box := _piece_bet_strip.get_text_box()
	var container: Control = null
	if bet_label != null and is_instance_valid(bet_label):
		container = bet_label.get_parent() as Control
	if container == null:
		container = box
	if container == null:
		return
	if _bet_strip_row != null and is_instance_valid(_bet_strip_row):
		if _bet_strip_row.get_parent() != container:
			## reparent() keeps the global transform, which leaves the row far outside the
			## new host; re-pin it the same way CombatHudPiece.attach() does.
			_bet_strip_row.reparent(container)
			_bet_strip_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	_bet_strip_row = HBoxContainer.new()
	_bet_strip_row.name = "BetStripRow"
	_bet_strip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_bet_strip_row.add_theme_constant_override("separation", 8)
	_bet_strip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bet_strip_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(_bet_strip_row)
	_bet_strip_labels.clear()
	var ladder: Array = []
	if _can_use_combat_api():
		ladder = combat.get_bet_ladder()
	else:
		ladder = [100.0, 200.0, 300.0, 400.0, 500.0, 1000.0]
	for i in range(ladder.size()):
		if i > 0:
			var sep := Label.new()
			sep.text = "|"
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sep.set_meta("bet_strip_separator", true)
			sep.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
			sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_bet_strip_row.add_child(sep)
		var lab := Label.new()
		lab.text = "%d" % int(ladder[i])
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_white_hud_text_style(lab)
		_bet_strip_row.add_child(lab)
		_bet_strip_labels.append(lab)
	_apply_bet_strip_typography(_fitted_balance_bet_font())


func _refresh_bet_strip() -> void:
	if _bet_strip_row == null or _bet_strip_labels.is_empty():
		_ensure_bet_strip_row()
	if _bet_strip_labels.is_empty():
		return
	var selected := 0
	if _can_use_combat_api() and combat.has_method("get_bet_index"):
		selected = int(combat.get_bet_index())
	elif bet_label != null:
		var current := bet_label.text.strip_edges()
		for i in range(_bet_strip_labels.size()):
			if _bet_strip_labels[i].text == current:
				selected = i
				break
	for i in range(_bet_strip_labels.size()):
		var lab := _bet_strip_labels[i]
		if i == selected:
			lab.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
			lab.modulate = Color(1, 1, 1, 1)
		else:
			lab.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			lab.modulate = Color(1, 1, 1, 0.55)


func _animate_bet_strip() -> void:
	_refresh_bet_strip()
	if _bet_strip_row == null or _bet_strip_labels.is_empty() or _piece_bet_strip == null:
		return
	var selected := 0
	if _can_use_combat_api() and combat.has_method("get_bet_index"):
		selected = int(combat.get_bet_index())
	selected = clampi(selected, 0, _bet_strip_labels.size() - 1)
	var lab := _bet_strip_labels[selected]
	var container := _bet_strip_row.get_parent() as Control
	if container == null:
		container = _piece_bet_strip.get_text_box()
	if container == null:
		return
	await get_tree().process_frame
	var center_x := container.size.x * 0.5
	var label_center := lab.position.x + lab.size.x * 0.5 + _bet_strip_row.position.x
	var target_x := _bet_strip_row.position.x + (center_x - label_center)
	if _bet_strip_tween != null and _bet_strip_tween.is_valid():
		_bet_strip_tween.kill()
	_bet_strip_tween = create_tween()
	_bet_strip_tween.tween_property(_bet_strip_row, "position:x", target_x, BET_STRIP_TWEEN_SEC).set_ease(Tween.EASE_OUT)


func _sync_skull_meter(sections: int) -> void:
	var filled := clampi(sections, 0, 3)
	if _premium_skull != null and _premium_skull.has_method("set_fill"):
		_premium_skull.set_fill(float(filled) / 3.0)


func _sync_premium_bar_color(sections: int, animate: bool = false) -> void:
	if _premium_bar_fill == null:
		return
	var idx := clampi(sections, 0, PREMIUM_BAR_COLORS.size() - 1)
	var target: Color = PREMIUM_BAR_COLORS[idx]
	if animate:
		var tween := create_tween()
		tween.tween_property(_premium_bar_fill, "color", target, 0.2)
	else:
		_premium_bar_fill.color = target


func _maybe_pop_spin_money() -> void:
	if mult_label == null or _piece_spin_money == null:
		return
	var text := mult_label.text
	if text != _last_spin_money_text and not _last_spin_money_text.is_empty():
		_piece_spin_money.pop()
	_last_spin_money_text = text


func _finish_initial_layout() -> void:
	await get_tree().process_frame
	_fit_hud_canvas()
	_bind_widgets_to_pieces()
	_hide_legacy_meter_nodes()
	_apply_hud_chrome()
	await get_tree().process_frame
	_layout_combat()
	_hide_legacy_meter_nodes()

func _on_size_changed() -> void:
	if Engine.is_editor_hint():
		return
	_fit_hud_canvas(size)
	_apply_hud_chrome()
	call_deferred("_layout_combat")

func _fit_hud_canvas(viewport_override: Vector2 = Vector2.ZERO) -> void:
	if Engine.is_editor_hint():
		return
	var canvas := _hud_canvas_node()
	if canvas == null:
		return
	var vp := viewport_override
	if vp.x <= 1.0 or vp.y <= 1.0:
		vp = size
	if vp.x <= 1.0 or vp.y <= 1.0:
		vp = get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var s := minf(vp.x / HUD_ART_SIZE.x, vp.y / HUD_ART_SIZE.y)
	canvas.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	canvas.anchor_left = 0.0
	canvas.anchor_top = 0.0
	canvas.anchor_right = 0.0
	canvas.anchor_bottom = 0.0
	canvas.size = HUD_ART_SIZE
	canvas.scale = Vector2(s, s)
	canvas.position = Vector2(
		(vp.x - HUD_ART_SIZE.x * s) * 0.5,
		(vp.y - HUD_ART_SIZE.y * s) * 0.5
	)

func _apply_hud_chrome() -> void:
	_apply_economics_typography()
	_apply_side_panel_typography()
	_refresh_history_row_typography()

func _layout_combat() -> void:
	if _widget_layer != null and _widget_layer.has_method("sync_now"):
		_widget_layer.sync_now()
	if _grid_host == null:
		return
	var host_w := maxf(_grid_host.size.x, 64.0)
	var host_h := maxf(_grid_host.size.y, GRID_HOST_MIN_HEIGHT)
	if host_w < 64.0 and _center_column != null:
		host_w = maxf(_center_column.size.x, 260.0)
	## The drawing-backed HUD owns its own premium bar (MOVE_PremiumBar), so the grid box
	## is purely cells and nothing has to be reserved inside it.
	var bottom_reserve := 0.0
	if _piece_premium_bar == null:
		bottom_reserve = PREMIUM_BAR_HEIGHT + PREMIUM_BAR_LAYOUT_PAD
	_suppress_combat_root_legacy_labels()
	var grid_w := 0.0
	if _can_layout_combat_grid():
		combat.fit_to_panel(Vector2(host_w, host_h), bottom_reserve, true, true)
		grid_w = _safe_get_grid_ui_width()
		_fallback_grid_width = grid_w
		if _piece_premium_bar == null:
			_layout_premium_bar()
	elif combat != null:
		grid_w = _layout_combat_grid_fallback(host_w, host_h, bottom_reserve)
		_fallback_grid_width = grid_w
		if _piece_premium_bar == null:
			_layout_premium_bar_fallback_aligned(grid_w, host_h)
	else:
		grid_w = _get_center_column_interior_width(host_w)
		_fallback_grid_width = grid_w
		if _piece_premium_bar == null:
			_layout_premium_bar_fallback(grid_w, host_h)
	_layout_item_desc_overlay()
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
	## EXECUTE size is authored in the editor; do not overwrite.
	pass

func _layout_execute_button_to_grid_width(_grid_w: float) -> void:
	## EXECUTE size is authored in the editor; do not overwrite.
	pass

func _apply_responsive_layout() -> void:
	## Percentage layout retired — HudCanvas free placement + _fit_hud_canvas.
	_apply_hud_chrome()

func _get_center_column_footer_stack_height() -> float:
	var stack_h := 0.0
	if _bottom_window_margin != null:
		stack_h += maxf(_bottom_window_margin.size.y, 0.0)
	if _center_footer != null:
		stack_h += maxf(_center_footer.size.y, 0.0)
	if _winnings_center != null:
		stack_h += maxf(_winnings_center.size.y, 0.0)
	return stack_h

func _shrink_grid_host_to_content(_host_w: float) -> void:
	## GridHost size is authored in the editor; do not overwrite.
	pass

func _side_panel_inner_width(panel: PanelContainer) -> float:
	if panel == null:
		return 200.0
	## A PanelContainer grows to fit its content, so measuring the panel would feed the
	## font fitters their own output and let a big font push the rows past the clipped
	## host. Measure the fixed host (the piece's MOVE_TextBox follower) instead.
	var panel_w := panel.size.x
	var host := panel.get_parent() as Control
	if host != null and host.size.x > 32.0:
		panel_w = minf(panel_w, host.size.x - panel.offset_left + panel.offset_right)
	if panel_w < 32.0:
		panel_w = panel.custom_minimum_size.x
	var style := panel.get_theme_stylebox("panel") as StyleBox
	if style != null:
		panel_w -= style.get_content_margin(Side.SIDE_LEFT) + style.get_content_margin(Side.SIDE_RIGHT)
	return maxf(panel_w - 6.0, 64.0)

func _fit_body_font_size(
	sample_text: String,
	target_scale: float,
	max_width: float,
	font: Font,
	min_size: int = SIDE_PANEL_BODY_FONT_MIN,
) -> int:
	var max_size := maxi(int(round(float(SIDE_PANEL_BODY_FONT) * target_scale)), min_size)
	if font == null or max_width <= 0.0:
		return max_size
	for font_size in range(max_size, min_size - 1, -1):
		var text_size := font.get_string_size(sample_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if text_size.x <= max_width:
			return font_size
	return min_size

## Largest size that still fits the HISTORY rectangle. The mini-icon grows with the
## font, so the icon column has to be re-measured for every candidate size.
func _resolved_history_body_font() -> int:
	var inner_w := _side_panel_inner_width(_spin_history_panel)
	var max_size := maxi(
		int(round(float(SIDE_PANEL_BODY_FONT) * HISTORY_BODY_FONT_SCALE)), SIDE_PANEL_BODY_FONT_MIN
	)
	var font := get_theme_font("font", "Label")
	if font == null or inner_w <= 0.0:
		return max_size
	for font_size in range(max_size, SIDE_PANEL_BODY_FONT_MIN - 1, -1):
		var avail := inner_w - float(_history_mini_icon_size_for_font(font_size)) - float(HISTORY_ROW_SEPARATION)
		if avail <= 0.0:
			continue
		if font.get_string_size(HISTORY_FIT_SAMPLE, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= avail:
			return font_size
	return SIDE_PANEL_BODY_FONT_MIN

func _item_row_body_font() -> Font:
	var font := get_theme_font("font", "CheckBox")
	if font == null:
		font = get_theme_font("font", "Label")
	return font

## Widest name actually in the list, so the fit is measured against real rows instead
## of a sample. Family and unique rows are tracked apart — only family rows carry a
## rank button, so they have less room for the name.
func _widest_item_row_text(kind: StringName) -> String:
	var texts: PackedStringArray = _item_row_texts.get(kind, PackedStringArray())
	if texts.is_empty():
		return "◈ Void Satchel"
	var font := _item_row_body_font()
	if font == null:
		return texts[0]
	var best := texts[0]
	var best_w := 0.0
	for text in texts:
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIDE_PANEL_BODY_FONT).x
		if w > best_w:
			best_w = w
			best = text
	return best

## Row furniture (checkbox column, icon, rank button, separators) is reserved so the
## bigger name text cannot push a row wider than the ITEMS rectangle.
func _resolved_items_body_font() -> int:
	var inner_w := _side_panel_inner_width(_item_picker_panel)
	var font := _item_row_body_font()
	var fixed := float(ITEM_PICKER_CHECKBOX_COL_W + ITEM_ICON_DRAW_SIZE)
	var family_budget := inner_w - fixed - float(ITEM_RANK_BTN_W + ITEM_PICKER_ROW_H_SEP * 3)
	var unique_budget := inner_w - fixed - float(ITEM_PICKER_ROW_H_SEP * 2)
	return mini(
		_fit_body_font_size(
			_widest_item_row_text(&"family"),
			ITEMS_BODY_FONT_SCALE,
			family_budget,
			font,
			ITEMS_BODY_FONT_MIN,
		),
		_fit_body_font_size(
			_widest_item_row_text(&"unique"),
			ITEMS_BODY_FONT_SCALE,
			unique_budget,
			font,
			ITEMS_BODY_FONT_MIN,
		),
	)

## Rank buttons keep their authored width, so their label grows only as far as the
## widest rarity name fits.
func _resolved_item_rank_font() -> int:
	var max_size := _resolved_items_body_font()
	var font := _item_row_body_font()
	if font == null:
		return SIDE_PANEL_HINT_FONT
	var avail := float(ITEM_RANK_BTN_W) - ITEM_RANK_BTN_TEXT_PAD * 2.0
	for font_size in range(max_size, SIDE_PANEL_HINT_FONT - 1, -1):
		if font.get_string_size(
			ITEM_RANK_BTN_FIT_SAMPLE, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		).x <= avail:
			return font_size
	return SIDE_PANEL_HINT_FONT

func _resolved_item_desc_font() -> int:
	var inner_w := _side_panel_inner_width(_item_picker_panel)
	return _fit_body_font_size(
		"◈ Void Satchel",
		ITEM_DESC_BODY_FONT_SCALE,
		inner_w - float(ITEM_PICKER_CHECKBOX_ICON_MAX + ITEM_PICKER_ROW_H_SEP),
		_item_row_body_font(),
	)

func _history_mini_icon_size_for_font(body_font: int) -> int:
	return maxi(
		int(round(float(HISTORY_MINI_ICON_SIZE) * float(body_font) / float(SIDE_PANEL_BODY_FONT))),
		HISTORY_MINI_ICON_SIZE,
	)

func _history_mini_icon_size() -> int:
	return _history_mini_icon_size_for_font(_resolved_history_body_font())

func _refresh_history_row_typography() -> void:
	if _history_spin_list == null:
		return
	var body_font := _resolved_history_body_font()
	var icon_size := _history_mini_icon_size_for_font(body_font)
	for row in _history_spin_list.get_children():
		if not row is HBoxContainer:
			continue
		for child in row.get_children():
			if child is TextureRect:
				(child as TextureRect).custom_minimum_size = Vector2(icon_size, icon_size)
			elif child is Label:
				_apply_history_text_style(child as Label)

## One size for BALANCE and the bet strip, sized off the drawn bars so the text almost
## fills them. Height sets the ceiling; the widest BALANCE string caps it so the bar
## (which clips its text) can never cut the readout off.
func _fitted_balance_bet_font() -> int:
	_cache_hud_pieces()
	var bar_h := 0.0
	var bar_w := 0.0
	for piece_variant in [_piece_balance, _piece_bet_strip]:
		var piece := piece_variant as CombatHudPiece
		if piece == null or not is_instance_valid(piece):
			continue
		var box: Control = piece.get_text_box()
		if box == null or box.size.y <= 0.0:
			continue
		var inset: float = 2.0 * piece.text_inset_px
		var usable_h := maxf(box.size.y - inset, 8.0)
		bar_h = usable_h if bar_h <= 0.0 else minf(bar_h, usable_h)
		if piece == _piece_balance:
			bar_w = maxf(box.size.x - inset, 8.0)
	if bar_h <= 0.0:
		return BANKROLL_READOUT_FONT
	var font: Font = null
	if bankroll_label != null and is_instance_valid(bankroll_label):
		font = bankroll_label.get_theme_font("font")
	if font == null:
		font = get_theme_font("font", "Label")
	var height_limit := bar_h * ECON_BAR_FONT_FILL
	if font == null:
		return clampi(int(round(height_limit)), ECON_BAR_FONT_MIN, ECON_BAR_FONT_MAX)
	for font_size in range(ECON_BAR_FONT_MAX, ECON_BAR_FONT_MIN - 1, -1):
		var text_size := font.get_string_size(
			ECON_BAR_FIT_SAMPLE, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		)
		if text_size.y > height_limit:
			continue
		if bar_w > 0.0 and text_size.x > bar_w:
			continue
		return font_size
	return clampi(int(round(height_limit)), ECON_BAR_FONT_MIN, ECON_BAR_FONT_MAX)

func _apply_bet_strip_typography(font_size: int) -> void:
	if _bet_strip_row == null or not is_instance_valid(_bet_strip_row):
		return
	var sep_size := maxi(int(round(float(font_size) * BET_STRIP_SEPARATOR_FONT_RATIO)), 8)
	for child in _bet_strip_row.get_children():
		var lab := child as Label
		if lab == null:
			continue
		var is_sep := bool(lab.get_meta("bet_strip_separator", false))
		lab.add_theme_font_size_override("font_size", sep_size if is_sep else font_size)

func _apply_economics_typography() -> void:
	var bankroll_font := _fitted_balance_bet_font()
	var goal_font := GOAL_READOUT_FONT
	if size.x < RESPONSIVE_NARROW_W:
		goal_font = GOAL_READOUT_FONT_NARROW
	if bankroll_label != null:
		bankroll_label.add_theme_font_size_override("font_size", bankroll_font)
	if goal_label != null:
		goal_label.add_theme_font_size_override("font_size", goal_font)
	if bet_label != null:
		bet_label.add_theme_font_size_override("font_size", bankroll_font)
	_apply_bet_strip_typography(bankroll_font)
	if bet_minus_btn != null and bet_plus_btn != null:
		var btn_size := STAKE_BUTTON_SIZE if size.x >= RESPONSIVE_NARROW_W else STAKE_BUTTON_SIZE_NARROW
		bet_minus_btn.custom_minimum_size = Vector2(btn_size, btn_size)
		bet_plus_btn.custom_minimum_size = Vector2(btn_size, btn_size)
		_style_stake_buttons()

func _place_control_rect(_control_node: Control, _x0: float, _y0: float, _x1: float, _y1: float) -> void:
	## Percentage placement retired — keep authored HudCanvas offsets.
	pass

func _refresh_spin_button_state() -> void:
	if spin_btn == null:
		return
	## Drawing paints EXECUTE; keep live button text empty so chrome stays see-through.
	spin_btn.text = ""

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
		_bind_item_picker_live_nodes()
		_rebuild_item_picker_contents()
		return
	var existing_panel := find_child("ItemPickerPanel", true, false) as PanelContainer
	if existing_panel == null:
		existing_panel = get_node_or_null("HudCanvas/PlayArea/PlayRow/ItemPickerPanel") as PanelContainer
	if existing_panel == null:
		existing_panel = get_node_or_null("PlayArea/PlayRow/ItemPickerPanel") as PanelContainer
	if existing_panel != null:
		_item_picker_panel = existing_panel
		_bind_item_picker_live_nodes()
	else:
		_item_picker_panel = _make_side_panel("ITEMS")
		_item_picker_panel.name = "ItemPickerPanel"
		_item_picker_title = _item_picker_panel.get_meta("header") as Label
		_item_picker_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_item_picker_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if _play_row != null:
			_play_row.add_child(_item_picker_panel)
			_reassert_node_ownership(_item_picker_panel)
		else:
			_add_preview_child(_item_picker_panel)
	if _item_picker_title != null:
		_style_side_panel_header(_item_picker_title)
	_ensure_item_desc_overlay()
	_ensure_playtest_tuning()
	_rebuild_item_picker_contents()


## Scene-saved metadata Object() copies are not the live children. Rebind to the tree.
func _bind_item_picker_live_nodes() -> void:
	if _item_picker_panel == null:
		return
	var header := _item_picker_panel.find_child("SectionHeader", true, false) as Label
	if header != null:
		_item_picker_title = header
		_item_picker_panel.set_meta("header", header)
	var scroll := _first_descendant_of_class(_item_picker_panel, "ScrollContainer") as ScrollContainer
	if scroll == null:
		return
	_item_picker_panel.set_meta("scroll", scroll)
	for child in scroll.get_children():
		if child is VBoxContainer:
			_item_picker_panel.set_meta("list", child)
			break


func _first_descendant_of_class(node: Node, class_nm: String) -> Node:
	for child in node.get_children():
		if child.is_class(class_nm):
			return child
		var nested := _first_descendant_of_class(child, class_nm)
		if nested != null:
			return nested
	return null


func _item_desc_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, ITEM_DESC_BG_ALPHA)
	style.border_color = Color(0.45, 0.03, 0.03, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


## The card is hosted on its own CanvasLayer so it paints over the item rows, which
## live on WidgetLayer (106). Transform stays identity, so the existing global-rect
## layout math is unchanged.
func _ensure_item_desc_layer() -> CanvasLayer:
	if _item_desc_layer != null and is_instance_valid(_item_desc_layer):
		return _item_desc_layer
	_item_desc_layer = get_node_or_null("ItemDescLayer") as CanvasLayer
	if _item_desc_layer == null:
		_item_desc_layer = CanvasLayer.new()
		_item_desc_layer.name = "ItemDescLayer"
		add_child(_item_desc_layer)
	_item_desc_layer.layer = ITEM_DESC_LAYER_INDEX
	return _item_desc_layer


func _ensure_item_desc_overlay() -> void:
	if _item_desc_panel != null and is_instance_valid(_item_desc_panel):
		_ensure_item_desc_scroll_hook()
		return
	_item_desc_clip = Control.new()
	_item_desc_clip.name = "ItemDescClip"
	_item_desc_clip.visible = false
	_item_desc_clip.z_index = ITEM_DESC_Z
	_item_desc_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_desc_clip.clip_contents = true
	_item_desc_clip.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_ensure_item_desc_layer().add_child(_item_desc_clip)
	_item_desc_panel = PanelContainer.new()
	_item_desc_panel.name = "ItemDescOverlay"
	_item_desc_panel.visible = false
	_item_desc_panel.modulate.a = 0.0
	_item_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_desc_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_item_desc_panel.add_theme_stylebox_override("panel", _item_desc_style())
	_item_desc_label = Label.new()
	_item_desc_label.name = "ItemDescLabel"
	_item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_item_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_white_hud_text_style(_item_desc_label)
	_item_desc_panel.add_child(_item_desc_label)
	_item_desc_clip.add_child(_item_desc_panel)
	_ensure_item_desc_scroll_hook()


func _ensure_item_desc_scroll_hook() -> void:
	if _item_picker_panel == null:
		return
	var scroll := _item_picker_panel.get_meta("scroll") as ScrollContainer
	if scroll == null:
		return
	var bar := scroll.get_v_scroll_bar()
	if bar != null and not bar.value_changed.is_connected(_on_item_picker_scrolled):
		bar.value_changed.connect(_on_item_picker_scrolled)


func _on_item_picker_scrolled(_value: float) -> void:
	_layout_item_desc_overlay()


func _item_desc_text_for_item(item: Resource, fallback: String = "") -> String:
	if item == null:
		return fallback.strip_edges()
	return str(item.description).strip_edges()


func _bind_item_row_hover(row: Control, desc: String) -> void:
	if row == null:
		return
	row.set_meta("item_desc", desc)
	_bind_item_hover_tree(row)


func _bind_item_hover_tree(node: Node) -> void:
	if node is Control:
		var ctrl := node as Control
		if not bool(ctrl.get_meta("item_desc_hover_bound", false)):
			ctrl.set_meta("item_desc_hover_bound", true)
			ctrl.mouse_entered.connect(_on_item_desc_source_entered.bind(ctrl))
			ctrl.mouse_exited.connect(_on_item_desc_source_exited.bind(ctrl))
	for child in node.get_children():
		_bind_item_hover_tree(child)


func _item_row_from_node(node: Node) -> Control:
	var n := node
	while n != null and n != _item_picker_panel:
		if n is Control and (n as Control).has_meta("item_desc"):
			return n as Control
		n = n.get_parent()
	return null


func _on_item_desc_source_entered(source: Control) -> void:
	var row := _item_row_from_node(source)
	if row == null:
		return
	_show_item_desc_for_row(row)


func _on_item_desc_source_exited(_source: Control) -> void:
	call_deferred("_finish_item_row_unhover")


func _finish_item_row_unhover() -> void:
	if not is_instance_valid(_item_desc_hover_row):
		_hide_item_desc()
		return
	var mouse := get_global_mouse_position()
	if _item_desc_hover_row.get_global_rect().has_point(mouse):
		return
	if _item_picker_panel != null and _item_desc_panel != null:
		var items_hit := _piece_items.get_global_rect() if _piece_items != null else _item_picker_panel.get_global_rect()
		var kept := _item_desc_panel.get_global_rect().intersection(items_hit)
		if kept.has_area() and kept.has_point(mouse):
			return
	_hide_item_desc()


func _show_item_desc_for_row(row: Control) -> void:
	_ensure_item_desc_overlay()
	if _item_desc_label == null or _item_desc_panel == null:
		return
	var desc := str(row.get_meta("item_desc", "")).strip_edges()
	if desc.is_empty():
		_hide_item_desc()
		return
	var already_shown := _item_desc_panel.visible and _item_desc_panel.modulate.a > 0.05
	_item_desc_hover_row = row
	_item_desc_label.text = desc
	_item_desc_label.add_theme_font_size_override("font_size", _resolved_item_desc_font())
	if _item_desc_clip != null:
		_item_desc_clip.visible = true
	_item_desc_panel.visible = true
	_layout_item_desc_overlay()
	call_deferred("_layout_item_desc_overlay")
	if already_shown:
		_stop_item_desc_fade()
		_item_desc_panel.modulate.a = ITEM_DESC_OPACITY
		return
	_item_desc_panel.modulate.a = 0.0
	_stop_item_desc_fade()
	_item_desc_fade = create_tween()
	_item_desc_fade.tween_property(_item_desc_panel, "modulate:a", ITEM_DESC_OPACITY, ITEM_DESC_FADE_IN)


func _hide_item_desc() -> void:
	_item_desc_hover_row = null
	_stop_item_desc_fade()
	if _item_desc_panel != null:
		_item_desc_panel.visible = false
		_item_desc_panel.modulate.a = 0.0
	if _item_desc_clip != null:
		_item_desc_clip.visible = false


func _stop_item_desc_fade() -> void:
	if _item_desc_fade != null and _item_desc_fade.is_valid():
		_item_desc_fade.kill()
	_item_desc_fade = null


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and not editor_preview_enabled:
		return
	if _item_desc_panel == null or not _item_desc_panel.visible:
		return
	_layout_item_desc_overlay()


func _layout_item_desc_overlay() -> void:
	if _item_desc_panel == null or not _item_desc_panel.visible or _item_desc_label == null:
		return
	if _item_picker_panel == null or not is_instance_valid(_item_desc_hover_row):
		return
	var items_rect: Rect2
	if _piece_items != null:
		items_rect = _piece_items.get_global_rect()
	else:
		items_rect = _item_picker_panel.get_global_rect()
	var row_rect := _item_desc_hover_row.get_global_rect()
	var list_rect := items_rect
	var scroll := _item_picker_panel.get_meta("scroll") as Control
	if scroll != null:
		list_rect = scroll.get_global_rect()
	if not list_rect.intersects(row_rect):
		_hide_item_desc()
		return
	if _item_desc_clip != null:
		_item_desc_clip.global_position = items_rect.position
		_item_desc_clip.size = items_rect.size
	var inset := ITEM_DESC_PANEL_INSET
	var inner_w := maxf(items_rect.size.x - inset * 2.0, 64.0)
	var desc_w := minf(ITEM_DESC_PREFERRED_WIDTH, inner_w)
	var style := _item_desc_panel.get_theme_stylebox("panel") as StyleBox
	var text_w := desc_w
	if style != null:
		text_w -= style.get_content_margin(Side.SIDE_LEFT) + style.get_content_margin(Side.SIDE_RIGHT)
	text_w = maxf(text_w, 48.0)
	_item_desc_label.custom_minimum_size.x = text_w
	_item_desc_label.size.x = text_w
	var desc_h := maxf(_item_desc_panel.get_combined_minimum_size().y, 32.0)
	var mouse := get_global_mouse_position()
	var local_mouse := mouse - items_rect.position
	var row_bottom := row_rect.position.y + row_rect.size.y - items_rect.position.y
	var x := local_mouse.x - desc_w * 0.5
	var y := maxf(local_mouse.y, row_bottom) + ITEM_DESC_CURSOR_GAP
	var x_min := inset
	var x_max := items_rect.size.x - inset - desc_w
	if x_max < x_min:
		x = x_min
	else:
		x = clampf(x, x_min, x_max)
	y = maxf(y, inset)
	_item_desc_panel.position = Vector2(x, y)
	_item_desc_panel.size = Vector2(desc_w, desc_h)


func _ensure_playtest_tuning() -> void:
	if _item_picker_panel == null:
		return
	var vbox := _item_picker_panel.get_child(0) as VBoxContainer
	if vbox == null:
		return
	var existing := vbox.get_node_or_null("PlaytestTuning") as VBoxContainer
	if existing != null:
		_playtest_tuning = existing
		_reroll_used_spin = existing.find_child("RerollUsedSpin", true, false) as SpinBox
		_reroll_budget_spin = existing.find_child("RerollBudgetSpin", true, false) as SpinBox
		_limit_spins_checkbox = existing.find_child("LimitSpinsCheck", true, false) as CheckBox
		_reroll_hint_label = existing.find_child("RerollHint", true, false) as Label
		_goal_base_spin = existing.find_child("GoalBaseSpin", true, false) as SpinBox
		_goal_progress_spin = existing.find_child("GoalProgressSpin", true, false) as SpinBox
		_goal_effective_label = existing.find_child("GoalEffectiveLabel", true, false) as Label
		_ignore_cap_checkbox = existing.find_child("IgnoreCapCheck", true, false) as CheckBox
		_hide_playtest_goal_controls(existing)
		_goal_base_spin = null
		_goal_progress_spin = null
		_goal_effective_label = null
		return
	_playtest_tuning = VBoxContainer.new()
	_playtest_tuning.name = "PlaytestTuning"
	_playtest_tuning.add_theme_constant_override("separation", 3)
	_ignore_cap_checkbox = CheckBox.new()
	_ignore_cap_checkbox.name = "IgnoreCapCheck"
	_ignore_cap_checkbox.text = "Ignore slot cap"
	_style_item_picker_checkbox(_ignore_cap_checkbox, SIDE_PANEL_HINT_FONT)
	_ignore_cap_checkbox.toggled.connect(_on_ignore_cap_toggled)
	_playtest_tuning.add_child(_ignore_cap_checkbox)
	_playtest_tuning.add_child(_make_playtest_label("REROLLS"))
	var used_row := _make_spin_row("Used", 0, 99, "RerollUsedSpin")
	_reroll_used_spin = used_row.get_node("RerollUsedSpin") as SpinBox
	_reroll_used_spin.value_changed.connect(_on_reroll_used_changed)
	_playtest_tuning.add_child(used_row)
	var budget_row := _make_spin_row("Budget", 0, 99, "RerollBudgetSpin")
	_reroll_budget_spin = budget_row.get_node("RerollBudgetSpin") as SpinBox
	_reroll_budget_spin.value_changed.connect(_on_reroll_budget_changed)
	_playtest_tuning.add_child(budget_row)
	_limit_spins_checkbox = CheckBox.new()
	_limit_spins_checkbox.name = "LimitSpinsCheck"
	_limit_spins_checkbox.text = "Limit spins"
	_style_item_picker_checkbox(_limit_spins_checkbox, SIDE_PANEL_HINT_FONT)
	_limit_spins_checkbox.toggled.connect(_on_limit_spins_toggled)
	_playtest_tuning.add_child(_limit_spins_checkbox)
	_reroll_hint_label = Label.new()
	_reroll_hint_label.name = "RerollHint"
	_reroll_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reroll_hint_label.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
	_playtest_tuning.add_child(_reroll_hint_label)
	# GOAL SpinBoxes live in AxelCombatDevTools (debug wrench menu).
	_goal_base_spin = null
	_goal_progress_spin = null
	_goal_effective_label = null
	vbox.add_child(_playtest_tuning)
	vbox.move_child(_playtest_tuning, 1)
	if _can_use_combat_api() and combat.has_method("get_playtest_spin_budget"):
		_reroll_budget_spin.set_value_no_signal(float(combat.get_playtest_spin_budget()))


func _hide_playtest_goal_controls(tuning: VBoxContainer) -> void:
	if tuning == null:
		return
	for child in tuning.get_children():
		var n := child as Node
		if n == null:
			continue
		var name_str := String(n.name)
		if name_str == "GoalBaseSpin" or name_str == "GoalProgressSpin" or name_str == "GoalEffectiveLabel":
			n.visible = false
			continue
		# Parent rows that wrap the SpinBoxes
		if n.find_child("GoalBaseSpin", true, false) != null or n.find_child("GoalProgressSpin", true, false) != null:
			n.visible = false
			continue
		if n is Label and String((n as Label).text).strip_edges() == "GOAL":
			n.visible = false


func _make_playtest_label(text: String) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
	lab.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
	return lab


func _make_spin_row(label_text: String, min_v: int, max_v: int, spin_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = label_text
	lab.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var spin := SpinBox.new()
	spin.name = spin_name
	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = 1
	spin.custom_minimum_size.x = 88
	row.add_child(spin)
	return row


func _rebuild_item_picker_contents() -> void:
	if _item_picker_panel == null:
		return
	var items_vbox: VBoxContainer = _item_picker_panel.get_meta("list") as VBoxContainer
	if items_vbox == null or not items_vbox.is_inside_tree():
		_bind_item_picker_live_nodes()
		items_vbox = _item_picker_panel.get_meta("list") as VBoxContainer
	if items_vbox == null:
		return
	_hide_item_desc()
	for child in items_vbox.get_children():
		items_vbox.remove_child(child)
		child.free()
	_item_entries.clear()
	_item_row_texts[&"family"] = PackedStringArray()
	_item_row_texts[&"unique"] = PackedStringArray()
	var available := _discover_available_items()
	var by_id: Dictionary = {}
	for item in available:
		by_id[String(item.id)] = item
	var family_defs := [
		{"letter": "A", "name": "Power Chain"},
		{"letter": "B", "name": "Premium Meter"},
		{"letter": "C", "name": "Trinity"},
		{"letter": "D", "name": "Free Spins"},
		{"letter": "E", "name": "Diagonal"},
		{"letter": "F", "name": "Board-count"},
		{"letter": "M", "name": "Corner glyphs"},
		{"letter": "G", "name": "Sealed grid"},
		{"letter": "H", "name": "True-path"},
	]
	var fam_header := Label.new()
	fam_header.text = "FAMILIES"
	fam_header.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
	fam_header.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
	items_vbox.add_child(fam_header)
	for fam in family_defs:
		var letter: String = str(fam["letter"])
		if not _family_rank.has(letter):
			_family_rank[letter] = 0
		var rank: int = int(_family_rank[letter])
		var item: Resource = _family_item_at_rank(by_id, letter, rank)
		items_vbox.add_child(_make_family_row(letter, str(fam["name"]), item, rank))
	var uniques: Dictionary = {0: [], 1: [], 2: [], 3: [], 4: []}
	for item in available:
		var family := str(item.get("family"))
		var rarity: int = int(item.get("rarity"))
		if family != "" and rarity < 4:
			continue
		uniques[rarity].append(item)
	for rarity_idx in 5:
		var group: Array = uniques[rarity_idx]
		if group.is_empty():
			continue
		group.sort_custom(func(a, b): return _item_id_sort_key(String(a.id)) < _item_id_sort_key(String(b.id)))
		var rh := Label.new()
		rh.text = RARITY_NAMES[rarity_idx]
		rh.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
		rh.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
		items_vbox.add_child(rh)
		for item in group:
			items_vbox.add_child(_make_unique_row(item))
	if available.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items available"
		empty_label.add_theme_font_size_override("font_size", SIDE_PANEL_HINT_FONT)
		items_vbox.add_child(empty_label)
	_refresh_item_picker_title()
	_refresh_playtest_readouts()
	_apply_item_picker_body_typography()


func _family_item_at_rank(by_id: Dictionary, letter: String, rank: int) -> Resource:
	var prefixes: Array[String] = ["C", "U", "R", "E"]
	var r: int = clampi(rank, 0, 3)
	var key := "%s-%s" % [prefixes[r], letter]
	return by_id.get(key, null)


## Tags a row name for the typography refresh, records its width for the fitter, and
## makes it trim rather than push the row past the panel if a name is ever too long.
func _mark_item_row_name(name_lab: Label, kind: StringName) -> void:
	name_lab.set_meta("item_row_name", true)
	name_lab.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lab.clip_text = true
	name_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var texts: PackedStringArray = _item_row_texts.get(kind, PackedStringArray())
	texts.append(name_lab.text)
	_item_row_texts[kind] = texts


func _make_item_icon(item: Resource) -> TextureRect:
	var icon := TextureRect.new()
	icon.set_meta("item_row_icon", true)
	icon.custom_minimum_size = Vector2(ITEM_ICON_DRAW_SIZE, ITEM_ICON_DRAW_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if item != null:
		icon.texture = item.get("icon") as Texture2D
	return icon


func _make_family_row(letter: String, family_name: String, item: Resource, rank: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", ITEM_PICKER_ROW_H_SEP)
	var cb := CheckBox.new()
	cb.text = ""
	cb.set_meta("item_row_checkbox", true)
	_style_item_row_checkbox(cb)
	cb.toggled.connect(_on_family_toggled.bind(letter, cb))
	row.add_child(cb)
	row.add_child(_make_item_icon(item))
	var name_lab := Label.new()
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.text = family_name
	name_lab.mouse_filter = Control.MOUSE_FILTER_PASS
	_mark_item_row_name(name_lab, &"family")
	var rarity_idx: int = clampi(rank, 0, 3)
	name_lab.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
	name_lab.add_theme_font_size_override("font_size", _resolved_items_body_font())
	row.add_child(name_lab)
	var rank_btn := Button.new()
	rank_btn.text = RARITY_NAMES[rarity_idx]
	rank_btn.custom_minimum_size.x = ITEM_RANK_BTN_W
	rank_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	rank_btn.set_meta("item_rank_button", true)
	rank_btn.add_theme_font_size_override("font_size", _resolved_item_rank_font())
	rank_btn.pressed.connect(_on_family_rank_pressed.bind(letter))
	row.add_child(rank_btn)
	_bind_item_row_hover(row, _item_desc_text_for_item(item, family_name))
	_item_entries.append({
		"kind": "family",
		"letter": letter,
		"checkbox": cb,
		"item": item,
		"icon": row.get_child(1),
		"name": name_lab,
		"rank_btn": rank_btn,
		"row": row,
	})
	return row


func _make_unique_row(item: Resource) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", ITEM_PICKER_ROW_H_SEP)
	var cb := CheckBox.new()
	var rarity_idx: int = clampi(int(item.get("rarity")), 0, RARITY_GLYPHS.size() - 1)
	cb.text = ""
	cb.set_meta("item_row_checkbox", true)
	_style_item_row_checkbox(cb)
	cb.toggled.connect(_on_item_checkbox_toggled.bind(item, cb))
	row.add_child(cb)
	row.add_child(_make_item_icon(item))
	var name_lab := Label.new()
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.text = "%s %s" % [RARITY_GLYPHS[rarity_idx], item.display_name]
	name_lab.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
	name_lab.add_theme_font_size_override("font_size", _resolved_items_body_font())
	name_lab.mouse_filter = Control.MOUSE_FILTER_PASS
	_mark_item_row_name(name_lab, &"unique")
	row.add_child(name_lab)
	_bind_item_row_hover(row, _item_desc_text_for_item(item))
	_item_entries.append({"kind": "unique", "checkbox": cb, "item": item, "row": row})
	return row


## Baseline C1..C10 before C-A; digit order not string order (C10 after C9).
func _item_id_sort_key(item_id: String) -> String:
	var id := item_id.strip_edges()
	if id.contains("-"):
		return "1_%s" % id
	var i := 0
	while i < id.length() and _is_ascii_letter(id.unicode_at(i)):
		i += 1
	var prefix := id.substr(0, i)
	var digits := id.substr(i)
	if digits.is_valid_int():
		return "0_%s_%04d" % [prefix, digits.to_int()]
	return "2_%s" % id


func _is_ascii_letter(code: int) -> bool:
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122)


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
	found.sort_custom(func(a, b): return _item_id_sort_key(String(a.id)) < _item_id_sort_key(String(b.id)))
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
	_refresh_playtest_readouts()


func _on_family_toggled(toggled_on: bool, letter: String, cb: CheckBox) -> void:
	if not _can_use_combat_api():
		cb.set_pressed_no_signal(false)
		return
	var item: Resource = _current_family_item(letter)
	if item == null:
		cb.set_pressed_no_signal(false)
		return
	if toggled_on:
		if not combat.equip_item(item):
			cb.set_pressed_no_signal(false)
			return
	else:
		combat.unequip_item(item)
	_refresh_item_picker_title()
	_refresh_playtest_readouts()


func _current_family_item(letter: String) -> Resource:
	for entry in _item_entries:
		if str(entry.get("kind", "")) == "family" and str(entry.get("letter", "")) == letter:
			return entry.get("item") as Resource
	return null


func _on_family_rank_pressed(letter: String) -> void:
	var next_rank: int = (int(_family_rank.get(letter, 0)) + 1) % 4
	_family_rank[letter] = next_rank
	var by_id: Dictionary = {}
	for item in _discover_available_items():
		by_id[String(item.id)] = item
	var new_item: Resource = _family_item_at_rank(by_id, letter, next_rank)
	var entry: Dictionary = {}
	for e in _item_entries:
		if str(e.get("kind", "")) == "family" and str(e.get("letter", "")) == letter:
			entry = e
			break
	if entry.is_empty():
		return
	var old_item: Resource = entry.get("item") as Resource
	entry["item"] = new_item
	var cb := entry.get("checkbox") as CheckBox
	var icon := entry.get("icon") as TextureRect
	var name_lab := entry.get("name") as Label
	var rank_btn := entry.get("rank_btn") as Button
	if icon != null and new_item != null:
		icon.texture = new_item.get("icon") as Texture2D
	if name_lab != null and new_item != null:
		name_lab.add_theme_color_override("font_color", RARITY_COLORS.get(next_rank, Color.WHITE))
	var row := entry.get("row") as Control
	if row != null and new_item != null:
		row.set_meta("item_desc", _item_desc_text_for_item(new_item))
		if _item_desc_hover_row == row:
			_show_item_desc_for_row(row)
	if rank_btn != null:
		rank_btn.text = RARITY_NAMES[next_rank]
	if _can_use_combat_api() and cb != null and cb.button_pressed and old_item != null and new_item != null:
		var idx: int = -1
		if combat.inventory.has_method("index_of"):
			idx = combat.inventory.index_of(old_item.id)
		if idx >= 0 and combat.has_method("replace_item_at"):
			if not combat.replace_item_at(idx, new_item):
				cb.set_pressed_no_signal(false)
		else:
			combat.unequip_item(old_item)
			if not combat.equip_item(new_item):
				cb.set_pressed_no_signal(false)
	_refresh_item_picker_title()
	_refresh_playtest_readouts()


func _on_ignore_cap_toggled(on: bool) -> void:
	if _can_use_combat_api() and combat.has_method("set_ignore_slot_cap"):
		combat.set_ignore_slot_cap(on)
	_refresh_item_picker_title()


func _on_reroll_used_changed(value: float) -> void:
	if _can_use_combat_api() and combat.has_method("set_spins_used"):
		combat.set_spins_used(int(value))
	_refresh_playtest_readouts()


func _on_reroll_budget_changed(value: float) -> void:
	if _can_use_combat_api() and combat.has_method("set_spin_budget"):
		combat.set_spin_budget(int(value))


func _on_limit_spins_toggled(on: bool) -> void:
	if _can_use_combat_api() and combat.has_method("set_limit_spins"):
		combat.set_limit_spins(on)


func _on_goal_base_changed(value: float) -> void:
	if _can_use_combat_api() and combat.has_method("set_goal_base_target_cents"):
		combat.set_goal_base_target_cents(int(value))
	_refresh_playtest_readouts()


func _on_goal_progress_changed(value: float) -> void:
	if _can_use_combat_api() and combat.has_method("set_goal_progress_cents"):
		combat.set_goal_progress_cents(int(value))
	_refresh_playtest_readouts()


func _refresh_playtest_readouts() -> void:
	if _reroll_hint_label != null and _can_use_combat_api() and combat.has_method("get_reroll_item_hint"):
		_reroll_hint_label.text = combat.get_reroll_item_hint()
	if _goal_effective_label != null and _can_use_combat_api() and combat.has_method("get_effective_goal_target_cents"):
		var eff: int = combat.get_effective_goal_target_cents()
		var base: int = combat.get_goal_base_target_cents() if combat.has_method("get_goal_base_target_cents") else 10000
		_goal_effective_label.text = "Effective %d (base %d)" % [eff, base]
	if _reroll_used_spin != null and _can_use_combat_api():
		_reroll_used_spin.set_value_no_signal(float(_safe_get_spins_used()))
	if _goal_progress_spin != null and _can_use_combat_api():
		_goal_progress_spin.set_value_no_signal(float(combat.get_chip_bar_goal_progress_cents()))


func _refresh_item_picker_title() -> void:
	if _item_picker_title != null:
		_item_picker_title.text = "ITEMS (%d/%d)" % [
			_safe_get_item_inventory_size(),
			_safe_get_item_max_slots(),
		]
