@tool
extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")
const QaCanonValidatorsScript := preload("res://tools/qa/qa_canon_validators.gd")
const SCAFFOLD_BASELINE_SCENE := "res://combat/combat_test_scaffold_baseline.tscn"
const COMBAT_ROOT_INSTANCED_CHILDREN := [
	"GridManager", "GridFrame", "GridUI", "GridFlashOverlay", "PowerIntroLayer",
	"RoundWinningsLabel", "EncounterWonLabel", "MultiplierLabel",
]
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const ItemLinesScript := preload("res://combat/scripts/item_lines.gd")
const EmptyItemDvdScript := preload("res://combat/scripts/empty_item_dvd.gd")
const PlayerItemPanelScript := preload("res://combat/scripts/player_item_panel.gd")
const HudDropShadowScript := preload("res://combat/scripts/hud_drop_shadow.gd")
const POWER_BLOODY_HAND: StringName = &"bloody_hand"
const POWER_ALCOHOL: StringName = &"alcohol"
const POWER_CIGARETTE: StringName = &"cigarette"
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const GRID_COLUMN_GAP := 10.0
const RESPONSIVE_NARROW_W := 900.0

const HUD_ART_SIZE := Vector2(3508.0, 2480.0)
const CENTER_COLUMN_SEPARATION := 10
const GRID_HOST_MIN_HEIGHT := 200.0
const WINNINGS_BAND_MIN_HEIGHT := 40.0
const WINNINGS_ROW_SEPARATION := 8
const CENTER_FOOTER_SEPARATION := 12
const ECONOMICS_STACK_SEPARATION := 4
const BANKROLL_READOUT_FONT := 36
const ECON_BAR_FONT_FILL := 0.9
const ECON_BAR_FONT_MIN := 24
const ECON_BAR_FONT_MAX := 200
const ECON_BAR_FIT_SAMPLE := "BALANCE: 0000"
const BET_STRIP_SEPARATOR_FONT_RATIO := 0.875
const EXECUTE_BUTTON_MIN_HEIGHT := 72.0
const BOTTOM_WINDOW_MARGIN := 18.0

const LAYOUT_META_ICONS_SEPARATION := 4
const META_ICON_GLYPH := "⬡"
const COMBAT_TEXT_SCALE := 2.0
const META_ICON_FONT := int(round(31.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_HEADER_FONT := int(round(32.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_BODY_FONT := int(round(18.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_BODY_FONT_MIN := int(round(14.0 * COMBAT_TEXT_SCALE))
const HISTORY_BODY_FONT_SCALE := 3.0
const HISTORY_FIT_SAMPLE := "1000 x 12.5 x 20"
const ITEM_BOX_SIZE_MUL := 1.33
const ITEMS_BODY_FONT_SCALE := 1.78 * ITEM_BOX_SIZE_MUL
const ITEMS_BODY_FONT_MIN := int(round(20.0 * COMBAT_TEXT_SCALE * ITEM_BOX_SIZE_MUL))
const ITEM_DESC_BODY_FONT_SCALE := 1.25 * ITEM_BOX_SIZE_MUL
const SIDE_PANEL_HINT_FONT := int(round(14.0 * COMBAT_TEXT_SCALE))
const SIDE_PANEL_CHROME_FONT_MIN := int(round(float(SIDE_PANEL_HINT_FONT * 2) * ITEM_BOX_SIZE_MUL))
const ITEM_PICKER_ROW_H_SEP := 4
const ITEM_PICKER_LIST_SEP := 10
const ITEM_PICKER_CHECKBOX_ICON_MAX := int(round(18.0 * COMBAT_TEXT_SCALE * ITEM_BOX_SIZE_MUL))
const ITEM_PICKER_PLAYTEST_CHECK_MIN := int(round(float(ITEM_PICKER_CHECKBOX_ICON_MAX * 2)))
const ITEM_PICKER_CHECKBOX_COL_W := int(round(22.0 * COMBAT_TEXT_SCALE * ITEM_BOX_SIZE_MUL))
const ITEM_ICON_DRAW_SIZE := 48
const ITEM_RANK_BTN_W := int(round(88.0 * COMBAT_TEXT_SCALE * ITEM_BOX_SIZE_MUL))
const ITEM_BOX_LEFT_INSET_PX := 12.0
const ITEM_NAME_RIGHT_PAD := 8.0
const ITEM_NAME_MAX_LINES := 2
const ITEM_RANK_BTN_TEXT_PAD := 8.0
const ITEM_RANK_BTN_FIT_SAMPLE := "Uncommon"
const ITEM_DESC_Z := 40
const ITEM_DESC_PREFERRED_WIDTH := 420.0
const ITEM_DESC_CURSOR_GAP := 8.0
const ITEM_DESC_PANEL_INSET := 8.0
const ITEM_DESC_FADE_IN := 0.08
const ITEM_DESC_BG_ALPHA := 1.0
const ITEM_DESC_OPACITY := 0.9
const ITEM_DESC_LAYER_INDEX := 107
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
const FIRST_TUTORIAL_DELAY_SEC := 2.5
const FREEZE_LESSONS: Array[String] = ["slot_match", "slot_multiplier", "slot_power", "slot_vice"]
const HELD_FREEZE_BEAT_SEC := 0.2
const HELD_FREEZE_TIMEOUT_SEC := 2.0
const HISTORY_MINI_ICON_SIZE := int(round(18.0 * COMBAT_TEXT_SCALE))
const HISTORY_ROW_SEPARATION := 3
const HUD_WHITE_TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const HUD_WHITE_TEXT_SHADOW_COLOR := Color(0.22, 0.22, 0.22, 0.72)
const HUD_WHITE_TEXT_SHADOW_OFFSET_Y := 1
const TERMINAL_THEME := preload("res://combat/ui/terminal_theme.tres")
const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const SPIN_BLOCK_W := 54.0
const SPIN_BLOCK_H := 36.0
const SPIN_BLOCK_GAP := 12.0
const SPIN_BAR_SCREEN_PAD := 8.0
const SKULL_MOUTH_FRAC := Vector2(0.50, 0.62)
const SKULL_MOUTH_LIP_FRAC := 0.80
const SPIN_BAR_FILL_SEC := 0.08
const FS_CHOICE_LAYER := 116
const SPIN_COUNT_LAYER := 109
const FS_SCRIM_ALPHA := 0.72
const FS_ICON_PX := 128.0
const FS_ICON_HOVER_SCALE := 1.15
const FS_ICON_HOVER_SEC := 0.28
const FS_FADE_PAD := 120.0
const FS_FADE_INSET := 28.0
const FS_HOVER_HIGHLIGHT_PAD := 16.0
const FS_CHOICE_MARGIN := 40.0
const FS_CHOICE_PAD_X := 28.0
const FS_CHOICE_PAD_Y := 22.0
const FS_CHOICE_COL_GAP := 12.0
const FS_CHOICE_TITLE := "Choose Your Vice"
const FS_CHOICE_HINT := "Fewer spins, higher potential"
const FS_NAME_RED := Color(1, 0, 0, 1)
const FS_ICON_BLOODY_HAND := preload("res://combat/art/grid_symbols/bloody_hand.png")
const FS_ICON_ALCOHOL := preload("res://combat/art/grid_symbols/booze.png")
const FS_ICON_CIGARETTE := preload("res://combat/art/grid_symbols/cigarette.png")
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
@export var editor_preview_enabled: bool = false:
	set(value):
		if editor_preview_enabled == value:
			return
		editor_preview_enabled = value
		_queue_editor_preview_refresh()
@export var editor_preview_seed: int = 12345:
	set(value):
		if editor_preview_seed == value:
			return
		editor_preview_seed = value
		_queue_editor_preview_refresh()

var seed_spin: SpinBox
var spin_btn: Button
var bet_minus_btn: Button
var bet_plus_btn: Button
var bet_label: Label
var mult_label: Label
var _spin_bar_host: Control
var _spin_count_root: Control
var _spin_bar_label: Label
var _spin_bar_blocks: Array[Panel] = []
var _spin_block_fill: Array[float] = []
var _shown_spin_blocks: int = 0
var _spin_count_fill: float = 1.0
var _spin_bar_grow: float = 1.0
var _slime_busy: bool = false
var _vomit_token: int = 0
var _spin_bar_tween: Tween
var _spin_bar_drops: Array[ColorRect] = []
var _bar_origin: Vector2 = Vector2.ZERO
var _bar_block_w: float = 0.0
var _bar_block_h: float = 0.0
var _bar_gap: float = 0.0
var _bar_label_gap: float = 0.0
var _bar_label_h: float = 0.0
var goal_label: Label
var budget_label: Label
var bankroll_label: Label
var _balance_fit_text := ""
var combat: CombatRootScript
var encounter_win_overlay: Control
var encounter_win_label: Label
var super_fs_choice_overlay: Control
var choose_bloody_hand_button: Button
var choose_alcohol_button: Button
var choose_cigarette_button: Button
var _fs_choice_layer: CanvasLayer
var _fs_choice_ready := false
var _vice_hover_tweens: Dictionary = {}
var _vice_highlight_tex: ImageTexture
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
var _spin_history_panel: PanelContainer
var _history_spin_list: VBoxContainer
var _item_picker_panel: PanelContainer
var _item_picker_title: Label
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
var _playtest_tuning: VBoxContainer
var _player_box: Control
var _hide_tries: int = 0
var _attach_tries: int = 0
var _refresh_tries: int = 0
var _wipe_cleared: bool = false
var _playtest_check_icons: Dictionary = {}
var _stake_pill: PanelContainer
var _economics_center: CenterContainer
var _economics_stack: VBoxContainer
var _cascade_mult_label: Label
var _cascade_mult_pill: PanelContainer
var _cascade_mult_rest_pos := Vector2.ZERO
var _cascade_mult_pop_tween: Tween
var _cascade_mult_font: FontVariation
var _last_displayed_cascade_mult: int = 1
var _displayed_round_winnings: int = 0
var _target_round_winnings: int = 0
var _popup_credit_cents: int = 0
var _shown_goal_value: int = 0
var _winnings_counter_running: bool = false
var _winnings_counter_generation: int = 0
var _first_tutorial_idle_sec := 0.0
var _held_freeze_lessons: Array[String] = []
var _after_match_lessons: Array[String] = []
var _held_freeze_sec := 0.0
var _held_freeze_settled_sec := 0.0
var _runtime_initialized: bool = false
var _editor_preview_refresh_queued: bool = false
var _editor_tree_ready_attempts: int = 0
var _runtime_tree_ready_attempts: int = 0

const EDITOR_FALLBACK_BANKROLL := 1000
const EDITOR_FALLBACK_BET := 100
const EDITOR_FALLBACK_MAX_ITEM_SLOTS := 7

const FALLBACK_GRID_COLS := 5
const FALLBACK_GRID_ROWS := 5
const FALLBACK_CELL_SIZE_MIN := 48.0

var _fallback_grid_width: float = 0.0
var _spin_busy: bool = false
var _tutorial_skull_hold := false
var _freeze_layer: CanvasLayer
var _freeze_rect: ColorRect
var _freeze_tween: Tween
var _freeze_shown := false
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
	if choose_bloody_hand_button == null:
		missing.append("%ChooseBloodyHandButton")
	if choose_alcohol_button == null:
		missing.append("%ChooseAlcoholButton")
	if choose_cigarette_button == null:
		missing.append("%ChooseCigaretteButton")
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
	if choose_bloody_hand_button == null or not is_instance_valid(choose_bloody_hand_button):
		choose_bloody_hand_button = _resolve_scaffold_node("ChooseBloodyHandButton") as Button
	if choose_alcohol_button == null or not is_instance_valid(choose_alcohol_button):
		choose_alcohol_button = _resolve_scaffold_node("ChooseAlcoholButton") as Button
	if choose_cigarette_button == null or not is_instance_valid(choose_cigarette_button):
		choose_cigarette_button = _resolve_scaffold_node("ChooseCigaretteButton") as Button
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
	if _is_player_combat_host():
		_hide_playtest_chrome()
		call_deferred("_attach_player_item_box")
		call_deferred("_clear_combat_wipe")
	else:
		_build_item_picker()
	_apply_side_panel_typography()
	_install_piece_shadows()
	if not resized.is_connected(_on_size_changed):
		resized.connect(_on_size_changed)

func _gate_local_scanline_for_room_fx_test() -> void:

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
	if not combat.vice_banner_finished.is_connected(_on_vice_banner_finished):
		combat.vice_banner_finished.connect(_on_vice_banner_finished)
	if not combat.winnings_popup_border_touched.is_connected(_on_winnings_popup_border_touched):
		combat.winnings_popup_border_touched.connect(_on_winnings_popup_border_touched)
	if not combat.round_winnings_hold_started.is_connected(_on_round_winnings_hold_started):
		combat.round_winnings_hold_started.connect(_on_round_winnings_hold_started)
	if not combat.free_spins_bonus_granted.is_connected(_on_free_spins_bonus_granted):
		combat.free_spins_bonus_granted.connect(_on_free_spins_bonus_granted)
	if not combat.sfx_requested.is_connected(_on_sfx_requested):
		combat.sfx_requested.connect(_on_sfx_requested)
	if not choose_bloody_hand_button.pressed.is_connected(_on_choose_bloody_hand_pressed):
		choose_bloody_hand_button.pressed.connect(_on_choose_bloody_hand_pressed)
	if not choose_alcohol_button.pressed.is_connected(_on_choose_alcohol_pressed):
		choose_alcohol_button.pressed.connect(_on_choose_alcohol_pressed)
	if not choose_cigarette_button.pressed.is_connected(_on_choose_cigarette_pressed):
		choose_cigarette_button.pressed.connect(_on_choose_cigarette_pressed)
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

	_ensure_hud_canvas_parent(node)

func _hide_legacy_meter_nodes() -> void:
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
	mult_label.add_theme_color_override("font_color", HUD_WHITE_TEXT_COLOR)
	mult_label.remove_theme_color_override("font_outline_color")
	mult_label.add_theme_constant_override("outline_size", WINNINGS_READOUT_OUTLINE)

func _configure_cascade_multiplier_readout() -> void:
	if _cascade_mult_label == null:
		return
	if _cascade_mult_font == null:
		_cascade_mult_font = FontVariation.new()
		_cascade_mult_font.base_font = VT323_FONT
		_cascade_mult_font.variation_embolden = 0.8
	_cascade_mult_label.add_theme_font_override("font", _cascade_mult_font)
	_cascade_mult_label.add_theme_font_size_override("font_size", CASCADE_MULT_READOUT_FONT)
	_cascade_mult_label.add_theme_color_override("font_color", HUD_WHITE_TEXT_COLOR)
	_cascade_mult_label.remove_theme_color_override("font_outline_color")
	_cascade_mult_label.add_theme_constant_override("outline_size", CASCADE_MULT_READOUT_OUTLINE)
	_cascade_mult_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_cascade_mult_label.clip_text = false
	_cascade_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cascade_mult_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
			continue
		if bool(label.get_meta("item_chrome_label", false)) or _is_item_chrome_label(label):
			_style_item_chrome_label(label)
	var rank_font := _resolved_item_rank_font()
	for child in _item_picker_panel.find_children("*", "Button", true, false):
		var btn := child as Button
		if btn == null or not bool(btn.get_meta("item_rank_button", false)):
			continue
		btn.add_theme_font_override("font", VT323_FONT)
		btn.add_theme_font_size_override("font_size", rank_font)
	for child in _item_picker_panel.find_children("*", "TextureRect", true, false):
		var icon := child as TextureRect
		if icon == null or not bool(icon.get_meta("item_row_icon", false)):
			continue
		icon.custom_minimum_size = Vector2(ITEM_ICON_DRAW_SIZE, ITEM_ICON_DRAW_SIZE)
	_fit_all_item_row_names()

func _style_item_picker_checkbox(cb: CheckBox, body_font: int = -1) -> void:
	if cb == null:
		return
	var font_size := _resolved_items_chrome_font()
	if body_font >= 0:
		font_size = maxi(font_size, body_font)
	cb.add_theme_font_override("font", VT323_FONT)
	cb.add_theme_font_size_override("font_size", font_size)
	cb.add_theme_constant_override("h_separation", ITEM_PICKER_ROW_H_SEP)
	var icon_px := maxi(font_size, ITEM_PICKER_PLAYTEST_CHECK_MIN)
	cb.add_theme_constant_override("icon_max_width", icon_px)
	_apply_playtest_checkbox_icons(cb, icon_px)
	cb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _resolved_items_chrome_font() -> int:
	return maxi(_resolved_items_body_font(), SIDE_PANEL_CHROME_FONT_MIN)


func _is_item_chrome_label(label: Label) -> bool:
	if label == null:
		return false
	var t := label.text.strip_edges()
	if t == "FAMILIES":
		return true
	return t in RARITY_NAMES


func _style_item_chrome_label(lab: Label) -> void:
	if lab == null:
		return
	lab.set_meta("item_chrome_label", true)
	lab.add_theme_font_override("font", VT323_FONT)
	lab.add_theme_font_size_override("font_size", _resolved_items_chrome_font())
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.clip_text = false
	lab.max_lines_visible = ITEM_NAME_MAX_LINES
	lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _apply_playtest_checkbox_icons(cb: CheckBox, px: int) -> void:
	if cb == null:
		return
	var on := _playtest_checkbox_icon(true, px)
	var off := _playtest_checkbox_icon(false, px)
	cb.add_theme_icon_override("checked", on)
	cb.add_theme_icon_override("unchecked", off)
	cb.add_theme_icon_override("checked_disabled", on)
	cb.add_theme_icon_override("unchecked_disabled", off)
	cb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _playtest_checkbox_icon(checked: bool, px: int) -> Texture2D:
	px = maxi(px, 8)
	var key := "%d_%s" % [px, "1" if checked else "0"]
	if _playtest_check_icons.has(key):
		return _playtest_check_icons[key]
	var tex := _make_playtest_checkbox_texture(checked, px)
	_playtest_check_icons[key] = tex
	return tex


func _make_playtest_checkbox_texture(checked: bool, px: int) -> Texture2D:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 1.0))
	var ink := READOUT_ACCENT_COLOR
	var border := maxi(int(round(float(px) / 16.0)), 2)
	for y in px:
		for x in px:
			if x < border or y < border or x >= px - border or y >= px - border:
				img.set_pixel(x, y, ink)
	if checked:
		var w := maxi(border + 1, int(round(float(px) * 0.12)))
		_draw_thick_line(
			img,
			Vector2i(int(px * 0.22), int(px * 0.52)),
			Vector2i(int(px * 0.42), int(px * 0.78)),
			ink,
			w,
		)
		_draw_thick_line(
			img,
			Vector2i(int(px * 0.42), int(px * 0.78)),
			Vector2i(int(px * 0.80), int(px * 0.24)),
			ink,
			w,
		)
	return ImageTexture.create_from_image(img)


func _draw_thick_line(img: Image, a: Vector2i, b: Vector2i, color: Color, thickness: int) -> void:
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var r := maxi(int(round(float(thickness) * 0.5)), 1)
	while true:
		_stamp_px(img, x0, y0, color, r)
		if x0 == x1 and y0 == y1:
			break
		var e2 := err * 2
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func _stamp_px(img: Image, x: int, y: int, color: Color, radius: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px := x + dx
			var py := y + dy
			if px >= 0 and py >= 0 and px < w and py < h:
				img.set_pixel(px, py, color)


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
		scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vbox.add_child(scroll)

		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		list.alignment = BoxContainer.ALIGNMENT_BEGIN
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.propagate_maximum_size = true
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

	for btn in [bet_minus_btn, bet_plus_btn]:
		if btn == null:
			continue
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

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

func _input(event: InputEvent) -> void:
	_note_skull_input(event)
	if _wants_spin_hotkey(event) and _close_tutorial_freeze_card():
		get_viewport().set_input_as_handled()
		return
	if _handle_bet_hotkey(event):
		return
	if _wants_spin_hotkey(event) and _rush_allowed():
		get_viewport().set_input_as_handled()
		if _loss_presentation_open():
			CombatPace.set_rush(true)
		else:
			CombatPace.step_rush()
		_note_loss_rush_press()
		return
	if not _wants_spin_hotkey(event):
		return
	if not _spin_hotkey_allowed():
		return
	get_viewport().set_input_as_handled()
	if _piece_execute != null:
		_piece_execute.play_press()
	await _request_spin()


func _wants_spin_hotkey(event: InputEvent) -> bool:
	if Engine.is_editor_hint():
		return false
	return event.is_action_pressed("interact")


func _close_tutorial_freeze_card() -> bool:
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("close_freeze_card"):
		return false
	if not bool(tutorial.call("is_freezing")):
		return false
	return bool(tutorial.call("close_freeze_card"))


func _handle_bet_hotkey(event: InputEvent) -> bool:
	if Engine.is_editor_hint() or event.is_echo():
		return false
	var step := 0
	if event.is_action_pressed("bet_down"):
		step = -1
	elif event.is_action_pressed("bet_up"):
		step = 1
	if step == 0 or not _bet_hotkey_allowed():
		return false
	get_viewport().set_input_as_handled()
	if step < 0:
		_on_bet_minus_pressed()
	else:
		_on_bet_plus_pressed()
	return true


func _bet_hotkey_allowed() -> bool:
	if _spin_busy or combat == null or not _can_use_combat_api():
		return false
	if _tutorial_freezing():
		return false
	if combat.free_spins.active or combat.is_encounter_complete():
		return false
	if _safe_is_waiting_for_free_spin_choice():
		return false
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_method("is_paused") and bool(pause.call("is_paused")):
		return false
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("is_menu_open") and bool(tools.call("is_menu_open")):
		return false
	return true


func _rush_allowed() -> bool:
	if not _can_use_combat_api():
		return false
	if not _spin_busy and not _rush_presentation_open():
		return false
	if super_fs_choice_overlay != null and super_fs_choice_overlay.visible:
		return false
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_method("is_paused") and bool(pause.call("is_paused")):
		return false
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("is_menu_open") and bool(tools.call("is_menu_open")):
		return false
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus != null and focus.is_visible_in_tree() and _focus_uses_interact(focus):
		return false
	return true


func _rush_presentation_open() -> bool:
	if combat == null:
		return false
	if combat.has_method("is_goal_burst_playing") and bool(combat.is_goal_burst_playing()):
		return true
	if not combat.has_method("get_feel"):
		return false
	var feel: Node = combat.get_feel()
	return feel != null and feel.has_method("is_loss_presentation") and bool(feel.is_loss_presentation())


func _loss_presentation_open() -> bool:
	if combat == null or not combat.has_method("get_feel"):
		return false
	var feel: Node = combat.get_feel()
	return feel != null and feel.has_method("is_loss_presentation") and bool(feel.is_loss_presentation())


func _note_loss_rush_press() -> void:
	if not _loss_presentation_open():
		return
	var feel: Node = combat.get_feel()
	if feel.has_method("note_rush_press"):
		feel.call("note_rush_press")


func _release_spin_busy() -> void:
	_spin_busy = false
	if _rush_presentation_open():
		return
	CombatPace.clear_rush()


func _spin_hotkey_allowed() -> bool:
	if _tutorial_blocks_spin():
		return false
	if _spin_busy or not _can_use_combat_api():
		return false
	if _can_use_combat_api() and combat != null and combat.is_encounter_complete() and _is_live_axel_run():
		return false
	if _safe_is_waiting_for_free_spin_choice():
		return false
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_method("is_paused") and bool(pause.call("is_paused")):
		return false
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("is_menu_open") and bool(tools.call("is_menu_open")):
		return false
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus != null and focus.is_visible_in_tree() and _focus_uses_interact(focus):
		return false
	return true


func _is_live_axel_run() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	return run != null and run.has_method("is_in_encounter") and bool(run.call("is_in_encounter"))


func _focus_uses_interact(focus: Control) -> bool:
	if focus is LineEdit or focus is TextEdit or focus is SpinBox or focus is CheckBox:
		return true
	var parent := focus.get_parent()
	return parent is SpinBox


func _on_spin_pressed() -> void:
	await _request_spin()


func _request_spin() -> void:
	if Engine.is_editor_hint():
		return
	if _tutorial_blocks_spin():
		return
	var frame := Engine.get_process_frames()
	if _spin_request_frame == frame:
		return
	if _spin_busy:
		return
	if combat == null or not _can_use_combat_api():
		return
	if combat.free_spins.active:
		return
	_spin_request_frame = frame
	_spin_busy = true
	if combat.is_encounter_complete():
		if _is_live_axel_run():
			_release_spin_busy()
			_refresh_spin_button_state()
			return
		combat.begin_next_playtest_encounter(_queued_seed)
	if _can_apply_queued_seed_on_execute():
		combat.setup_new_grid(_queued_seed)
	if spin_btn != null:
		spin_btn.disabled = true
	_refresh_spin_button_state()
	if _premium_skull != null and _premium_skull.has_method("play_fire"):
		_premium_skull.call("play_fire")
	await combat.spin()
	var tutorial := _tutorial_node()
	if tutorial != null and tutorial.has_method("is_showing") and bool(tutorial.call("is_showing", "fight_items")):
		_tutorial_complete("fight_items")
	if spin_btn != null:
		spin_btn.disabled = false
	_release_spin_busy()
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
	var bankroll_units := int(_safe_get_bankroll())
	if bankroll_label != null:
		bankroll_label.text = "BALANCE: %d" % bankroll_units
	_apply_goal_readout_text()
	_refresh_bet_strip()
	_sync_skull_meter(_safe_get_meter_sections_filled())
	_sync_premium_bar_color(_safe_get_meter_sections_filled())
	_maybe_pop_spin_money()
	_refresh_spin_bars()
	_refresh_playtest_readouts()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()
	_refresh_skull_first_spin_hint()
	if bankroll_label != null and bankroll_label.text != _balance_fit_text:
		_balance_fit_text = bankroll_label.text
		_apply_economics_typography()

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
	if bankroll_label != null:
		bankroll_label.text = "BALANCE: %d" % EDITOR_FALLBACK_BANKROLL
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
	if _cascade_mult_rest_pos == Vector2.ZERO:
		_cascade_mult_rest_pos = _cascade_mult_label.position


func _format_cascade_multiplier_text(mult: int) -> String:
	return "%dX" % mult

func _pulse_cascade_multiplier() -> void:
	if _cascade_mult_label == null:
		return
	if _cascade_mult_pop_tween != null and _cascade_mult_pop_tween.is_valid():
		_cascade_mult_pop_tween.kill()
	var rest := _cascade_mult_rest_pos
	if rest == Vector2.ZERO:
		rest = _cascade_mult_label.position
		_cascade_mult_rest_pos = rest
	_cascade_mult_label.scale = Vector2.ONE
	_cascade_mult_label.position = rest
	_cascade_mult_pop_tween = CombatPace.bind(create_tween())
	_cascade_mult_pop_tween.tween_property(_cascade_mult_label, "scale", Vector2(1.08, 1.08), 0.07)
	_cascade_mult_pop_tween.parallel().tween_property(
		_cascade_mult_label, "position", rest + Vector2(0.0, -3.0), 0.07
	)
	var settle := _cascade_mult_pop_tween.chain()
	settle.tween_property(_cascade_mult_label, "scale", Vector2.ONE, 0.1)
	settle.parallel().tween_property(_cascade_mult_label, "position", rest, 0.1)

func _on_spin_started(seed_value: int) -> void:
	if combat != null and combat.get_spins_used() >= 1:
		_tutorial_complete("fight_spin")
	_queued_seed = seed_value
	_set_seed_spin_value_no_signal(seed_value)
	_clear_history_spin_list()
	_last_displayed_cascade_mult = int(combat.get_multiplier_value())
	if not _free_spin_round_showing():
		_reset_winnings_counter_display()
	_refresh_spin_bars()
	_refresh_skull_first_spin_hint()

func _on_round_winnings_hold_started() -> void:
	_reset_winnings_counter_display()
	_refresh_spin_bars()

func _free_spin_round_showing() -> bool:
	return _can_use_combat_api() and combat != null and combat.free_spins.active

func _on_spin_finished() -> void:
	if not _safe_is_encounter_complete() and not _safe_did_win_encounter():
		_sync_winnings_counter_to_combat_truth()
	if combat.get_state() == CombatRoot.State.IDLE or combat.is_encounter_complete():
		spin_btn.disabled = false
	_refresh_spin_button_state()

func _on_winnings_popup_border_touched(event: Dictionary) -> void:
	var cents: int = int(event.get("payout_cents", 0))
	if cents <= 0:
		return
	if _popup_credit_cents > 0:
		var used := mini(_popup_credit_cents, cents)
		_popup_credit_cents -= used
		cents -= used
		if cents <= 0:
			return
	_target_round_winnings += cents
	_start_winnings_counter_if_needed()

func _reset_winnings_counter_display() -> void:
	_kill_winnings_counter()
	_popup_credit_cents = 0
	_displayed_round_winnings = 0
	_target_round_winnings = 0
	_apply_winnings_readout_text()

func _sync_winnings_counter_to_combat_truth() -> void:
	_kill_winnings_counter()
	var combat_total := int(_safe_get_round_winnings())
	_popup_credit_cents += maxi(combat_total - _target_round_winnings, 0)
	_displayed_round_winnings = combat_total
	_target_round_winnings = combat_total
	_apply_winnings_readout_text()

func _apply_winnings_readout_text() -> void:
	if mult_label != null:
		mult_label.text = "%d" % _displayed_round_winnings
	_apply_goal_readout_text()

func _safe_get_goal_progress() -> int:
	if _can_use_combat_api() and combat.has_method("get_chip_bar_goal_progress_cents"):
		return int(combat.get_chip_bar_goal_progress_cents())
	return 0

func _safe_get_goal_target() -> int:
	if _can_use_combat_api() and combat.has_method("get_chip_bar_goal_target_cents"):
		return int(combat.get_chip_bar_goal_target_cents())
	return 0

func _goal_display_value() -> int:
	var truth := _safe_get_goal_progress()
	if truth < _shown_goal_value:
		_shown_goal_value = 0
	if _winnings_bar_settled():
		return truth
	var lag := maxi(int(_safe_get_round_winnings()) - _displayed_round_winnings, 0)
	return clampi(truth - lag, _shown_goal_value, truth)

func _apply_goal_readout_text() -> void:
	if goal_label == null or not _can_use_combat_api():
		return
	_shown_goal_value = _goal_display_value()
	goal_label.text = "GOAL:\n%d / %d" % [_shown_goal_value, _safe_get_goal_target()]

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
		await CombatPace.await_seconds(step_interval)
	if gen != _winnings_counter_generation:
		return
	_winnings_counter_running = false
	if _displayed_round_winnings < _target_round_winnings:
		_start_winnings_counter_if_needed()

func _on_meter_full_transition_started() -> void:
	if _piece_premium_bar != null:
		_piece_premium_bar.pop()

func _on_vice_banner_finished() -> void:
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("wants") or not bool(tutorial.call("wants", "slot_vice")):
		return
	combat.vice_entry_gate_open = false
	_tutorial_request("slot_vice")

func _on_premium_meter_changed(previous_sections: int, next_sections: int) -> void:
	_sync_skull_meter(next_sections)
	_sync_premium_bar_color(next_sections, true)
	if next_sections > previous_sections:
		_play_combat_sfx(&"skull")
		if next_sections < 3:
			_tutorial_request("slot_power")


func _on_sfx_requested(cue: StringName) -> void:
	_play_combat_sfx(cue)


func _play_combat_sfx(cue: StringName) -> void:
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", cue)


func _on_seed_spin_value_changed(value: float) -> void:
	if not _can_queue_seed_change():
		return
	_queued_seed = int(value)
	_refresh_readouts()
	_refresh_spin_button_state()

func _on_bet_minus_pressed() -> void:
	_tutorial_complete("fight_stakes")
	combat.step_bet(-1)
	_refresh_readouts()
	_animate_bet_strip()

func _on_bet_plus_pressed() -> void:
	_tutorial_complete("fight_stakes")
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
	_tutorial_request("slot_match")
	if int(event.get("cascade_multiplier", 1)) >= 2:
		_tutorial_request("slot_multiplier")
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
	_install_pause_gear()


func _install_piece_shadows() -> void:
	_cache_hud_pieces()
	var pieces: Array[Control] = [
		_piece_grid,
		_piece_goal,
		_piece_items,
		_find_hud_piece("NEW_Bets"),
		_piece_history,
		_piece_multiplier,
		_piece_settings,
	]
	for piece in pieces:
		var art := _frame_art(piece)
		if art == null:
			continue
		HudDropShadowScript.attach_beside(art)


func _frame_art(piece: Control) -> TextureRect:
	if piece == null:
		return null
	if piece is TextureRect:
		var own := piece as TextureRect
		if own.texture != null:
			return own
	for child in piece.get_children():
		if child.name == "DropShadow":
			continue
		if child is TextureRect:
			var art := child as TextureRect
			if art.texture != null:
				return art
	return null


const PAUSE_GEAR_CHAR := "⚙"
const PAUSE_GEAR_FILL := 0.63175
const PAUSE_GEAR_TEETH := 8
const PAUSE_GEAR_PIXELS := 16
const PAUSE_GEAR_COLOR := Color8(7, 7, 7)
const PAUSE_GEAR_ROOT := 0.72
const PAUSE_GEAR_HOLE := 0.32


class PauseGearIcon extends Control:
	var _mask := PackedByteArray()


	func _draw() -> void:
		var n := PAUSE_GEAR_PIXELS
		if n < 2 or size.x < 2.0 or size.y < 2.0:
			return
		if _mask.size() != n * n:
			_mask = _gear_mask(n)
		for y in n:
			var y0 := int(round(float(y) * size.y / float(n)))
			var y1 := int(round(float(y + 1) * size.y / float(n)))
			if y1 <= y0:
				continue
			for x in n:
				if _mask[y * n + x] == 0:
					continue
				var x0 := int(round(float(x) * size.x / float(n)))
				var x1 := int(round(float(x + 1) * size.x / float(n)))
				if x1 <= x0:
					continue
				draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), PAUSE_GEAR_COLOR, true)


	func _gear_mask(n: int) -> PackedByteArray:
		var mask := PackedByteArray()
		mask.resize(n * n)
		for y in n:
			var ny := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			for x in n:
				var nx := (float(x) + 0.5) / float(n) * 2.0 - 1.0
				if _gear_covers(nx, ny):
					mask[y * n + x] = 1
		return mask


	func _gear_covers(nx: float, ny: float) -> bool:
		var dist := Vector2(nx, ny).length()
		if dist <= PAUSE_GEAR_HOLE:
			return false
		if dist <= PAUSE_GEAR_ROOT:
			return true
		if dist > 1.0:
			return false
		var step := TAU / float(PAUSE_GEAR_TEETH)
		var tip_half := step * 0.20
		var root_half := step * 0.36
		var tooth_base := PAUSE_GEAR_ROOT * 0.90
		for i in PAUSE_GEAR_TEETH:
			var mid := -PI * 0.5 + step * float(i)
			if _point_in_poly(nx, ny, PackedVector2Array([
				Vector2.from_angle(mid - root_half) * tooth_base,
				Vector2.from_angle(mid - tip_half),
				Vector2.from_angle(mid + tip_half),
				Vector2.from_angle(mid + root_half) * tooth_base,
			])):
				return true
		return false


	func _point_in_poly(px: float, py: float, poly: PackedVector2Array) -> bool:
		var inside := false
		var j := poly.size() - 1
		for i in poly.size():
			var a := poly[i]
			var b := poly[j]
			var crosses := (a.y > py) != (b.y > py)
			if crosses and px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x:
				inside = not inside
			j = i
		return inside


func _install_pause_gear() -> void:
	if _piece_settings == null or _piece_settings.get_node_or_null("PauseGear") != null:
		return
	var gear := PauseGearIcon.new()
	gear.name = "PauseGear"
	gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear.set_meta("gear_char", PAUSE_GEAR_CHAR)
	_piece_settings.add_child(gear)
	if not _piece_settings.resized.is_connected(_fit_pause_gear):
		_piece_settings.resized.connect(_fit_pause_gear)
	_fit_pause_gear()


func _fit_pause_gear() -> void:
	if _piece_settings == null:
		return
	var gear := _piece_settings.get_node_or_null("PauseGear") as PauseGearIcon
	if gear == null:
		return
	var host := _piece_settings.size
	if host.x < 8.0 or host.y < 8.0:
		return
	var side := minf(host.x, host.y) * PAUSE_GEAR_FILL
	if side < 8.0:
		return
	gear.position = (host - Vector2(side, side)) * 0.5
	gear.size = Vector2(side, side)
	gear.queue_redraw()


func _is_player_combat_host() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("is_in_encounter"):
		return false
	return bool(run.call("is_in_encounter"))


func _hide_playtest_chrome() -> void:
	if not is_inside_tree() or not _is_player_combat_host():
		return
	for node_name in ["SeedSpinBox", "PlaytestTuning", "ItemPickerPanel"]:
		var node := find_child(node_name, true, false) as CanvasItem
		if node != null:
			node.visible = false
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus != null and not focus.is_visible_in_tree():
		focus.release_focus()
	_hide_tries += 1
	if _hide_tries < 20:
		call_deferred("_hide_playtest_chrome")


func _is_tutorial_egg() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not _is_player_combat_host():
		return false
	return run.has_method("is_tutorial_encounter") and bool(run.call("is_tutorial_encounter"))


func _attach_player_item_box() -> void:
	if not is_inside_tree() or not _is_player_combat_host():
		return
	var host := get_items_widget_host()
	var piece := find_child("NEW_Items", true, false)
	if host == null or piece == null:
		_attach_tries += 1
		if _attach_tries < 24:
			call_deferred("_attach_player_item_box")
		return
	var want_egg := _is_tutorial_egg()
	if _player_box != null and is_instance_valid(_player_box):
		var is_egg: bool = _player_box.get_script() == EmptyItemDvdScript
		if is_egg == want_egg:
			return
		_player_box.queue_free()
		_player_box = null
	if want_egg:
		_player_box = EmptyItemDvdScript.new() as Control
	else:
		_player_box = PlayerItemPanelScript.new() as Control
	host.add_child(_player_box)
	if piece.has_method("attach"):
		piece.call("attach", _player_box, host)
	_player_box.offset_left = ITEM_BOX_LEFT_INSET_PX
	if not want_egg:
		_refresh_equipped_list()


func refresh_player_item_box() -> void:
	if not is_inside_tree() or not _is_player_combat_host():
		return
	_refresh_tries = 0
	_attach_tries = 0
	_attach_player_item_box()
	_refresh_equipped_list()
	_follow_equipped_refresh()


func _follow_equipped_refresh() -> void:
	if not is_inside_tree() or not _is_player_combat_host():
		return
	if _player_box != null and is_instance_valid(_player_box) and _player_box.has_method("_fit_row_names"):
		_player_box.call("_fit_row_names")
	if not _item_list_needs_retry():
		return
	_refresh_tries += 1
	if _refresh_tries < 48:
		call_deferred("_follow_equipped_refresh")


func _item_list_needs_retry() -> bool:
	if _is_tutorial_egg():
		return false
	var root := find_child("CombatRoot", true, false)
	var inv_n := 0
	if root != null:
		var inv = root.get("inventory")
		if inv != null and inv.get("items") != null:
			inv_n = (inv.items as Array).size()
	if inv_n <= 0:
		return false
	if _player_box == null or not is_instance_valid(_player_box):
		return true
	if _player_box.size.x < 8.0:
		return true
	var list := _player_box.find_child("List", true, false)
	if list == null:
		return true
	return list.get_child_count() < inv_n


func _refresh_equipped_list() -> void:
	if _player_box == null or not _player_box.has_method("set_equipped_items"):
		return
	var root := find_child("CombatRoot", true, false)
	if root == null:
		return
	var inv = root.get("inventory")
	if inv == null:
		return
	var items: Array = []
	if inv.get("items") != null:
		items = inv.items
	if _player_box.has_method("set_slot_cap") and inv.has_method("get_current_max_slots"):
		_player_box.call("set_slot_cap", int(inv.get_current_max_slots()))
	_player_box.call("set_equipped_items", items)


func _clear_combat_wipe() -> void:
	if _wipe_cleared or not is_inside_tree() or not _is_player_combat_host():
		return
	var fx := get_node_or_null("/root/AxelEventFx")
	if fx == null or not fx.has_method("clear_combat_wipe"):
		return
	var tree := get_tree()
	if tree == null:
		return
	_wipe_cleared = true
	await tree.process_frame
	if not is_inside_tree():
		return
	fx = get_node_or_null("/root/AxelEventFx")
	if fx != null and fx.has_method("clear_combat_wipe"):
		fx.call("clear_combat_wipe")


func get_items_widget_host() -> Control:
	_cache_hud_pieces()
	return _host_for_piece(_piece_items, "items")


func _host_for_piece(piece: CombatHudPiece, id: String) -> Control:
	if piece == null or _widget_layer == null or not _widget_layer.has_method("register"):
		return null
	var box := piece.get_text_box()
	if box == null:
		return null
	return _widget_layer.register(box, id) as Control


func _bind_widgets_to_pieces() -> void:
	if Engine.is_editor_hint() and not editor_preview_enabled and not _is_editor_preview():

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
		_item_picker_panel.offset_left = ITEM_BOX_LEFT_INSET_PX
	elif _piece_items != null:
		_host_for_piece(_piece_items, "items")
	if _piece_history != null and _spin_history_panel != null:
		_piece_history.attach(_spin_history_panel, _host_for_piece(_piece_history, "history"))
	if _piece_multiplier != null and _cascade_mult_label != null:
		_piece_multiplier.attach(_cascade_mult_label, _host_for_piece(_piece_multiplier, "multiplier"))
		_cascade_mult_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_cascade_mult_label.clip_text = false
		_cascade_mult_label.pivot_offset = _cascade_mult_label.size * 0.5
		_cascade_mult_rest_pos = _cascade_mult_label.position
		_configure_cascade_multiplier_readout()
	if _cascade_mult_pill != null:
		_cascade_mult_pill.visible = false
	if _piece_balance != null and bankroll_label != null:
		_piece_balance.attach(bankroll_label, _host_for_piece(_piece_balance, "balance"))
		bankroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bankroll_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _piece_bet_strip != null and bet_label != null:

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
		_refresh_spin_bars()
	if _winnings_center != null:
		_winnings_center.visible = false
	var winnings_pill := find_child("WinningsReadoutPill", true, false) as CanvasItem
	if winnings_pill != null:
		winnings_pill.visible = false
	if _piece_execute != null and spin_btn != null:

		if spin_btn.get_parent() != _piece_execute:
			spin_btn.reparent(_piece_execute)
		spin_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		spin_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spin_btn.focus_mode = Control.FOCUS_NONE
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
	_wire_piece_input_signals()

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
	if _piece_execute != null and _premium_skull != null and _premium_skull.has_method("set_hovered"):
		_piece_execute.hover_scale = 1.0
		_piece_execute.press_scale = 1.0
		var on_hover := Callable(_premium_skull, "set_hovered")
		var on_press := Callable(_premium_skull, "set_pressed")
		if not _piece_execute.hover_changed.is_connected(on_hover):
			_piece_execute.hover_changed.connect(on_hover)
		if not _piece_execute.press_changed.is_connected(on_press):
			_piece_execute.press_changed.connect(on_press)

	if _skull_click_polygon != null:
		if _skull_click_polygon is Control:
			(_skull_click_polygon as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _skull_click_polygon.has_signal("pressed"):
			if _skull_click_polygon.pressed.is_connected(_on_piece_execute_activated):
				_skull_click_polygon.pressed.disconnect(_on_piece_execute_activated)

	if _premium_skull != null and _premium_skull.has_signal("pressed"):
		if _premium_skull.pressed.is_connected(_on_piece_execute_activated):
			_premium_skull.pressed.disconnect(_on_piece_execute_activated)
		if _premium_skull is Control:
			(_premium_skull as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _piece_settings != null and not _piece_settings.activated.is_connected(_on_settings_activated):
		_piece_settings.activated.connect(_on_settings_activated)


func _on_piece_execute_activated() -> void:
	await _request_spin()


func _on_settings_activated() -> void:
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_method("request_pause"):
		pause.call("request_pause")


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
			lab.add_theme_color_override("font_color", HUD_WHITE_TEXT_COLOR)
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
	if _premium_skull == null:
		_refresh_skull_first_spin_hint()
		return
	var held := _can_use_combat_api() and combat.has_method("is_bonus_skull_held") and combat.is_bonus_skull_held()
	if _premium_skull.has_method("set_full_face_locked"):
		_premium_skull.set_full_face_locked(held)
	if _premium_skull.has_method("set_fill"):
		_premium_skull.set_fill(float(filled) / 3.0)
	var crown_on := _can_use_combat_api() and combat != null and combat.free_spins.active
	if _premium_skull.has_method("set_flame_dim_target"):
		_premium_skull.set_flame_dim_target(_spin_history_panel)
	if _premium_skull.has_method("set_flame_crown"):
		_premium_skull.set_flame_crown(crown_on)
	_refresh_skull_first_spin_hint()


func _refresh_skull_first_spin_hint() -> void:
	if _premium_skull == null or not _premium_skull.has_method("set_first_spin_hint"):
		return
	var on := false
	if _can_use_combat_api() and combat != null:
		var state := combat.get_state()
		on = (
			not combat.is_encounter_complete()
			and combat.get_spins_used() == 0
			and state == CombatRoot.State.IDLE
			and not combat.is_waiting_for_free_spin_choice()
		)
	if _tutorial_suppresses_skull():
		on = false
	_premium_skull.call("set_first_spin_hint", on)


func _tutorial_node() -> Node:
	return get_node_or_null("/root/AxelTutorial")


func _tutorial_request(lesson_id: String) -> void:
	if FREEZE_LESSONS.has(lesson_id):
		if not _held_freeze_lessons.has(lesson_id):
			_held_freeze_lessons.append(lesson_id)
		return
	var tutorial := _tutorial_node()
	if tutorial != null and tutorial.has_method("request"):
		tutorial.call("request", lesson_id)


func _tutorial_complete(lesson_id: String) -> void:
	var tutorial := _tutorial_node()
	if tutorial != null and tutorial.has_method("complete"):
		tutorial.call("complete", lesson_id)


func _tutorial_blocks_spin() -> bool:
	var tutorial := _tutorial_node()
	return tutorial != null and tutorial.has_method("blocks_spin") and bool(tutorial.call("blocks_spin"))


func _tutorial_freezing() -> bool:
	var tutorial := _tutorial_node()
	return tutorial != null and tutorial.has_method("is_freezing") and bool(tutorial.call("is_freezing"))


func _tutorial_gate_pending() -> bool:
	if _after_match_lessons.has("fight_stakes"):
		return true
	var tutorial := _tutorial_node()
	return tutorial != null and tutorial.has_method("is_gate_open") and bool(tutorial.call("is_gate_open"))


func _tutorial_suppresses_skull() -> bool:
	var tutorial := _tutorial_node()
	return tutorial != null and tutorial.has_method("suppresses_skull_hint") and bool(tutorial.call("suppresses_skull_hint"))


func _sync_freeze_overlay() -> void:
	var tutorial := _tutorial_node()
	var want := tutorial != null and tutorial.has_method("is_freezing") and bool(tutorial.call("is_freezing"))
	if want == _freeze_shown:
		if want:
			_layout_freeze_overlay()
		return
	_freeze_shown = want
	if want:
		_show_freeze_overlay()
	else:
		_hide_freeze_overlay()


func _ensure_freeze_overlay() -> void:
	if _freeze_layer != null and is_instance_valid(_freeze_layer):
		return
	_freeze_layer = CanvasLayer.new()
	_freeze_layer.name = "TutorialFreezeLayer"
	_freeze_layer.layer = 40
	add_child(_freeze_layer)
	_freeze_rect = ColorRect.new()
	_freeze_rect.name = "TutorialFreezeRect"
	_freeze_rect.color = Color.WHITE
	_freeze_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://combat/shaders/tutorial_freeze.gdshader")
	_freeze_rect.material = mat
	_freeze_layer.add_child(_freeze_rect)
	_freeze_rect.visible = false


func _layout_freeze_overlay() -> void:
	if _freeze_rect == null:
		return
	var target: Control = null
	if combat != null and is_instance_valid(combat) and combat.grid_ui != null and is_instance_valid(combat.grid_ui):
		target = combat.grid_ui
	elif _piece_grid != null and is_instance_valid(_piece_grid):
		target = _piece_grid
	if target == null:
		return
	var xform := target.get_global_transform_with_canvas()
	var scale_now := xform.get_scale()
	_freeze_rect.position = xform.origin
	_freeze_rect.size = Vector2(target.size.x * absf(scale_now.x), target.size.y * absf(scale_now.y))


func _reduce_flashing_on() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	return settings != null and settings.has_method("get_value") and bool(settings.call("get_value", "access", "reduce_flashing", false))


func _show_freeze_overlay() -> void:
	_ensure_freeze_overlay()
	_layout_freeze_overlay()
	var mat := _freeze_rect.material as ShaderMaterial
	var calm := _reduce_flashing_on()
	mat.set_shader_parameter("jitter", 0.0 if calm else 1.0)
	mat.set_shader_parameter("burst", 0.0 if calm else 1.0)
	mat.set_shader_parameter("amount", 0.0)
	_freeze_rect.visible = true
	if _freeze_tween != null and _freeze_tween.is_valid():
		_freeze_tween.kill()
	_freeze_tween = create_tween()
	_freeze_tween.tween_property(mat, "shader_parameter/amount", 1.0, 0.18)
	if not calm:
		_freeze_tween.tween_property(mat, "shader_parameter/burst", 0.0, 0.5)


func _hide_freeze_overlay() -> void:
	if _freeze_rect == null or not is_instance_valid(_freeze_rect):
		return
	if _freeze_tween != null and _freeze_tween.is_valid():
		_freeze_tween.kill()
	var mat := _freeze_rect.material as ShaderMaterial
	_freeze_tween = create_tween()
	_freeze_tween.tween_property(mat, "shader_parameter/amount", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_freeze_tween.tween_callback(func() -> void: _freeze_rect.visible = false)


func _sync_skull_ready() -> void:
	if _premium_skull == null or not _premium_skull.has_method("set_ready"):
		return
	var ready_now := _spin_hotkey_allowed() and combat != null and not combat.free_spins.active
	if ready_now and combat.is_encounter_complete():
		ready_now = false
	_premium_skull.call("set_ready", ready_now, not _tutorial_suppresses_skull())


func _note_skull_input(event: InputEvent) -> void:
	if _premium_skull == null or not _premium_skull.has_method("note_input"):
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		_premium_skull.call("note_input")


func _sync_tutorial_skull_hint() -> void:
	var hold := _tutorial_suppresses_skull()
	if hold == _tutorial_skull_hold:
		return
	_tutorial_skull_hold = hold
	_refresh_skull_first_spin_hint()


func _maybe_queue_fight_tutorials(delta: float) -> void:
	if not _first_fight_idle():
		_first_tutorial_idle_sec = 0.0
		return
	_first_tutorial_idle_sec += delta
	if _first_tutorial_idle_sec < FIRST_TUTORIAL_DELAY_SEC:
		return
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("request"):
		return
	tutorial.call("request", "fight_spin")
	if not _after_match_lessons.has("fight_stakes"):
		_after_match_lessons.append("fight_stakes")
	if _tutorial_equipped_count() > 0 and not _after_match_lessons.has("fight_items"):
		_after_match_lessons.append("fight_items")


func _release_after_match_lessons() -> void:
	if _after_match_lessons.is_empty():
		return
	if not _can_use_combat_api() or combat == null:
		return
	if combat.get_spins_used() < 1 or combat.get_state() != CombatRoot.State.IDLE:
		return
	if not _held_freeze_lessons.is_empty() and not _after_match_lessons.has("fight_stakes"):
		return
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("request"):
		return
	if bool(tutorial.call("is_freezing")):
		return
	var lessons := _after_match_lessons.duplicate()
	_after_match_lessons.clear()
	for lesson_id in lessons:
		tutorial.call("request", lesson_id)


func _sync_tutorial_gates() -> void:
	var tutorial := _tutorial_node()
	if tutorial == null:
		return
	if tutorial.has_method("set_freeze_pending"):
		tutorial.call("set_freeze_pending", not _held_freeze_lessons.is_empty())
	if combat == null or combat.vice_entry_gate_open:
		return
	if _held_freeze_lessons.is_empty() and not bool(tutorial.call("is_freezing")):
		combat.vice_entry_gate_open = true


func _first_fight_idle() -> bool:
	if not _can_use_combat_api() or combat == null:
		return false
	if combat.is_encounter_complete() or combat.get_spins_used() != 0:
		return false
	if combat.get_state() != CombatRoot.State.IDLE:
		return false
	return not combat.is_waiting_for_free_spin_choice()


func _winnings_bar_settled() -> bool:
	if _winnings_counter_running:
		return false
	var combat_total := int(_safe_get_round_winnings())
	return _displayed_round_winnings == _target_round_winnings and _target_round_winnings == combat_total


func _release_held_freeze_lessons(delta: float) -> void:
	if _held_freeze_lessons.is_empty():
		return
	if _tutorial_gate_pending():
		return
	_held_freeze_sec += delta
	if _winnings_bar_settled():
		_held_freeze_settled_sec += delta
	else:
		_held_freeze_settled_sec = 0.0
	if _held_freeze_settled_sec < HELD_FREEZE_BEAT_SEC and _held_freeze_sec < HELD_FREEZE_TIMEOUT_SEC:
		return
	var lessons := _held_freeze_lessons.duplicate()
	_held_freeze_lessons.clear()
	_held_freeze_sec = 0.0
	_held_freeze_settled_sec = 0.0
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("request"):
		return
	for lesson_id in lessons:
		tutorial.call("request", lesson_id)


func _tutorial_equipped_count() -> int:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("is_in_encounter") or not bool(run.call("is_in_encounter")):
		return 0
	return run.state.equipped_item_ids.size()


func _push_tutorial_hud_rects() -> void:
	var tutorial := _tutorial_node()
	if tutorial == null or not tutorial.has_method("set_hud_rects"):
		return
	if not tutorial.has_method("wants_hud_rects") or not bool(tutorial.call("wants_hud_rects")):
		return
	var rects := {}
	_put_tutorial_piece(rects, "NEW_Execute", _piece_execute)
	_put_tutorial_piece(rects, "NEW_Grid", _piece_grid)
	_put_tutorial_piece(rects, "MOVE_Balance", _piece_balance)
	_put_tutorial_piece(rects, "MOVE_BetStrip", _piece_bet_strip)
	_put_tutorial_piece(rects, "NEW_Goal", _piece_goal)
	_put_tutorial_piece(rects, "NEW_Items", _piece_items)
	_put_tutorial_piece(rects, "NEW_History", _piece_history)
	tutorial.call("set_hud_rects", rects)


func _put_tutorial_piece(rects: Dictionary, piece_name: String, piece: Control) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	var xform := piece.get_global_transform_with_canvas()
	var scale_now := xform.get_scale()
	rects[piece_name] = Rect2(xform.origin, Vector2(piece.size.x * absf(scale_now.x), piece.size.y * absf(scale_now.y)))


func _sync_premium_bar_color(sections: int, animate: bool = false) -> void:
	if _premium_bar_fill == null:
		return
	var idx := clampi(sections, 0, PREMIUM_BAR_COLORS.size() - 1)
	var target: Color = PREMIUM_BAR_COLORS[idx]
	if animate:
		var tween := CombatPace.bind(create_tween())
		tween.tween_property(_premium_bar_fill, "color", target, 0.2)
	else:
		_premium_bar_fill.color = target


func _ensure_spin_bar_host() -> void:
	if _spin_bar_host != null and is_instance_valid(_spin_bar_host):
		return
	var host := Control.new()
	host.name = "FreeSpinBars"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = false
	host.z_index = 30
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	_spin_bar_host = host
	var layer := CanvasLayer.new()
	layer.name = "FreeSpinCountLayer"
	layer.layer = SPIN_COUNT_LAYER
	host.add_child(layer)
	var count_root := Control.new()
	count_root.name = "FreeSpinCountRoot"
	count_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(count_root)
	_spin_count_root = count_root
	var label := Label.new()
	label.name = "FreeSpinCount"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.modulate = Color.WHITE
	label.add_theme_font_override("font", VT323_FONT)
	count_root.add_child(label)
	_spin_bar_label = label
	_style_spin_count_label(_hud_art_scale())


func _set_spin_bars_visible(on: bool) -> void:
	if _spin_bar_host != null:
		_spin_bar_host.visible = on
	if _spin_count_root != null:
		_spin_count_root.visible = on


func _on_free_spins_bonus_granted(_added: int) -> void:
	_refresh_spin_bars()


func _refresh_spin_bars() -> void:
	_ensure_spin_bar_host()
	if not _free_spin_round_showing():
		_clear_spin_bars()
		return
	var left := combat.free_spins.spins_remaining
	var progress := combat.get_free_spin_counter()
	if progress.y <= 0 or left <= 0:
		_clear_spin_bars()
		return
	_set_spin_bars_visible(true)
	_spin_bar_label.text = "%d/%d spins" % [progress.x, progress.y]
	if _slime_busy:
		_layout_spin_bars()
		return
	if left == _shown_spin_blocks:
		_layout_spin_bars()
		return
	if left < _shown_spin_blocks:
		_set_spin_block_count(left)
		return
	if _skip_spin_bar_motion():
		_spin_count_fill = 1.0
		_set_spin_block_count(left)
		return
	_slime_busy = true
	await _vomit_spin_bars(_vomit_token)


func _clear_spin_bars() -> void:
	_vomit_token += 1
	_slime_busy = false
	_kill_spin_bar_tween()
	_clear_spin_bar_drops()
	_shown_spin_blocks = 0
	_spin_count_fill = 1.0
	_spin_block_fill.clear()
	while not _spin_bar_blocks.is_empty():
		var extra: Panel = _spin_bar_blocks.pop_back()
		if extra != null and is_instance_valid(extra):
			extra.queue_free()
	_set_spin_bars_visible(false)


func _set_spin_block_count(count: int) -> void:
	_ensure_spin_bar_host()
	var want := maxi(count, 0)
	while _spin_bar_blocks.size() > want:
		var extra: Panel = _spin_bar_blocks.pop_back()
		if not _spin_block_fill.is_empty():
			_spin_block_fill.pop_back()
		if extra != null and is_instance_valid(extra):
			extra.queue_free()
	while _spin_bar_blocks.size() < want:
		_spin_count_root.add_child(_make_spin_block())
		_spin_block_fill.append(1.0)
	_shown_spin_blocks = want
	_layout_spin_bars()


func _append_empty_spin_block() -> void:
	_ensure_spin_bar_host()
	_spin_count_root.add_child(_make_spin_block())
	_spin_block_fill.append(0.0)
	_shown_spin_blocks = _spin_bar_blocks.size()
	_layout_spin_bars()


func _make_spin_block() -> Panel:
	var block := Panel.new()
	block.name = "SpinBlock"
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.clip_contents = false
	_spin_bar_blocks.append(block)
	return block


func _style_spin_count_label(art_scale: float) -> void:
	if _spin_bar_label == null:
		return
	var grow := maxf(_spin_bar_grow, 1.0)
	var shadow := maxi(2, int(round(2.0 * grow)))
	_apply_white_hud_text_style(_spin_bar_label)
	_spin_bar_label.add_theme_color_override("font_shadow_color", Color(0.28, 0.28, 0.28, 1.0))
	_spin_bar_label.add_theme_constant_override("shadow_offset_x", shadow)
	_spin_bar_label.add_theme_constant_override("shadow_offset_y", shadow)
	var base_font := maxi(22, int(round(40.0 * art_scale)))
	_spin_bar_label.add_theme_font_size_override("font_size", maxi(22, int(round(float(base_font) * grow))))


func _spin_block_edge() -> int:
	return maxi(2, int(round(4.0 * _hud_art_scale() * maxf(_spin_bar_grow, 1.0))))


func _apply_spin_block_style(block: Panel) -> void:
	var grow := maxf(_spin_bar_grow, 1.0)
	var edge := _spin_block_edge()
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.set_border_width_all(edge)
	style.set_corner_radius_all(0)
	style.shadow_color = HudDropShadowScript.COLOR
	style.shadow_size = maxi(2, int(round(4.0 * _hud_art_scale() * grow)))
	style.shadow_offset = HudDropShadowScript.OFFSET * grow
	block.add_theme_stylebox_override("panel", style)


func _control_visual_global_rect(node: Control) -> Rect2:
	if node.size.x <= 1.0 or node.size.y <= 1.0:
		return node.get_global_rect()
	var xform := node.get_global_transform_with_canvas()
	var corners: Array[Vector2] = [
		xform * Vector2.ZERO,
		xform * Vector2(node.size.x, 0.0),
		xform * node.size,
		xform * Vector2(0.0, node.size.y),
	]
	var lo := corners[0]
	var hi := corners[0]
	for point in corners:
		lo = lo.min(point)
		hi = hi.max(point)
	return Rect2(lo, hi - lo)


func _layout_spin_bars() -> void:
	if _spin_bar_host == null or _premium_skull == null:
		return
	var skull := _premium_skull as Control
	if skull == null:
		return
	var art_scale := _hud_art_scale()
	var base_font := maxi(22, int(round(40.0 * art_scale)))
	var block_w := SPIN_BLOCK_W * art_scale
	var block_h := SPIN_BLOCK_H * art_scale
	var gap := SPIN_BLOCK_GAP * art_scale
	var label_gap := maxf(4.0, 8.0 * art_scale)
	var label_h := float(base_font) + 10.0
	var stack := block_h + label_gap + label_h
	var rect := _control_visual_global_rect(skull)
	var gap_under := maxf(8.0, 14.0 * art_scale)
	var to_local := _spin_bar_host.get_global_transform_with_canvas().affine_inverse()
	var origin := to_local * (rect.position + Vector2(0.0, rect.size.y + gap_under))
	origin = _clamp_spin_bar_origin(origin, block_h, label_gap, to_local, label_h)
	var bar_bottom := origin.y + stack
	var lip_global := rect.position + Vector2(0.0, rect.size.y * SKULL_MOUTH_LIP_FRAC)
	var lip_local := to_local * lip_global
	var grow := 1.0
	if stack > 1.0 and rect.size.y > 8.0:
		grow = (bar_bottom - lip_local.y) / stack
	_spin_bar_grow = clampf(grow, 1.0, 8.0)
	_style_spin_count_label(art_scale)
	_bar_origin = Vector2(origin.x, bar_bottom - stack * _spin_bar_grow)
	_bar_block_w = block_w * _spin_bar_grow
	_bar_block_h = block_h * _spin_bar_grow
	_bar_gap = gap * _spin_bar_grow
	_bar_label_gap = label_gap * _spin_bar_grow
	_bar_label_h = label_h * _spin_bar_grow
	_place_spin_bar_row()


func _clamp_spin_bar_origin(origin: Vector2, block_h: float, label_gap: float, to_local: Transform2D, label_h: float) -> Vector2:
	if _spin_bar_label == null:
		return origin
	var vp := get_viewport_rect().size
	if vp.y <= 1.0:
		vp = size
	if vp.y <= 1.0:
		return origin
	var row_bottom_local := origin.y + block_h + label_gap + label_h
	var row_bottom := _spin_bar_host.get_global_transform_with_canvas() * Vector2(origin.x, row_bottom_local)
	var overflow := row_bottom.y - (vp.y - SPIN_BAR_SCREEN_PAD)
	if overflow <= 0.5:
		return origin
	var delta := to_local.basis_xform(Vector2(0.0, -overflow))
	return origin + Vector2(0.0, delta.y)


func _spin_bar_global(local_point: Vector2) -> Vector2:
	return _spin_bar_host.get_global_transform_with_canvas() * local_point


func _place_spin_bar_row() -> void:
	for i in _spin_bar_blocks.size():
		_place_one_spin_block(i)
	if _spin_bar_label == null:
		return
	var font_px := float(_spin_bar_label.get_theme_font_size("font_size"))
	var text_w := font_px * 8.0
	var font := _spin_bar_label.get_theme_font("font")
	if font != null and not _spin_bar_label.text.is_empty():
		text_w = font.get_string_size(_spin_bar_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_px)).x + 12.0
	var shown_h := _bar_label_h * clampf(_spin_count_fill, 0.0, 1.0)
	_spin_bar_label.clip_text = _spin_count_fill < 0.999
	_spin_bar_label.custom_minimum_size = Vector2.ZERO
	_spin_bar_label.size = Vector2(maxf(text_w, 32.0), shown_h)
	var label_local := Vector2(_bar_origin.x, _bar_origin.y + _bar_block_h + _bar_label_gap + _bar_label_h - shown_h)
	_spin_bar_label.global_position = _spin_bar_global(label_local)


func _place_one_spin_block(index: int) -> void:
	if index < 0 or index >= _spin_bar_blocks.size():
		return
	var block := _spin_bar_blocks[index]
	if block == null or not is_instance_valid(block):
		return
	var fill := 1.0
	if index < _spin_block_fill.size():
		fill = clampf(_spin_block_fill[index], 0.0, 1.0)
	var shown_h := _bar_block_h * fill
	var local_pos := _bar_origin + Vector2(float(index) * (_bar_block_w + _bar_gap), _bar_block_h - shown_h)
	block.custom_minimum_size = Vector2.ZERO
	block.size = Vector2(_bar_block_w, maxf(shown_h, 0.0))
	block.visible = shown_h >= 1.0
	block.global_position = _spin_bar_global(local_pos)
	_apply_spin_block_style(block)


func _set_block_fill(index: int, amount: float) -> void:
	if index < 0 or index >= _spin_block_fill.size():
		return
	_spin_block_fill[index] = clampf(amount, 0.0, 1.0)
	_place_one_spin_block(index)


func _set_count_fill(amount: float) -> void:
	_spin_count_fill = clampf(amount, 0.0, 1.0)
	_place_spin_bar_row()


func _skull_mouth_local() -> Vector2:
	var stage := _premium_skull.get_node_or_null("SkullStage3") as Control
	var rect := _control_visual_global_rect(stage) if stage != null else _control_visual_global_rect(_premium_skull as Control)
	var mouth := rect.position + Vector2(rect.size.x * SKULL_MOUTH_FRAC.x, rect.size.y * SKULL_MOUTH_FRAC.y)
	return _spin_bar_host.get_global_transform_with_canvas().affine_inverse() * mouth


func _skip_spin_bar_motion() -> bool:
	return DisplayServer.get_name() == "headless" or _reduce_hud_flashing()


func _vomit_spin_bars(token: int) -> void:
	var reveal_text := _shown_spin_blocks == 0
	if reveal_text:
		_spin_count_fill = 0.0
		_layout_spin_bars()
	while token == _vomit_token and _free_spin_round_showing():
		var target := combat.free_spins.spins_remaining
		if target < _shown_spin_blocks:
			_set_spin_block_count(target)
			continue
		if target > _shown_spin_blocks:
			_append_empty_spin_block()
			await _fill_spin_block_from_bottom(_spin_bar_blocks.size() - 1, token)
			continue
		if reveal_text:
			reveal_text = false
			await _fill_spin_count_from_bottom(token)
			continue
		break
	if token == _vomit_token:
		_slime_busy = false


func _fill_spin_block_from_bottom(index: int, token: int) -> void:
	if token != _vomit_token:
		return
	if index < 0 or index >= _spin_bar_blocks.size():
		return
	if _skip_spin_bar_motion():
		_set_block_fill(index, 1.0)
		return
	var land := _block_slot_global(index).end - Vector2(_bar_block_w * 0.5, 0.0)
	await _play_mouth_drip(land, token, func(amount: float) -> void:
		_set_block_fill(index, amount)
	)
	if token == _vomit_token:
		_set_block_fill(index, 1.0)


func _fill_spin_count_from_bottom(token: int) -> void:
	if token != _vomit_token:
		return
	if _skip_spin_bar_motion():
		_set_count_fill(1.0)
		return
	var land := _spin_bar_global(_bar_origin + Vector2(_bar_block_w * 0.5, _bar_block_h + _bar_label_gap + _bar_label_h))
	await _play_mouth_drip(land, token, func(amount: float) -> void:
		_set_count_fill(amount)
	)
	if token == _vomit_token:
		_set_count_fill(1.0)


func _block_slot_global(index: int) -> Rect2:
	var local := _bar_origin + Vector2(float(index) * (_bar_block_w + _bar_gap), 0.0)
	var top_left := _spin_bar_global(local)
	var bottom_right := _spin_bar_global(local + Vector2(_bar_block_w, _bar_block_h))
	return Rect2(top_left, bottom_right - top_left)


func _play_mouth_drip(land: Vector2, token: int, on_fill: Callable) -> void:
	if token != _vomit_token or _spin_bar_host == null or _premium_skull == null:
		return
	var drip_scale := _hud_art_scale() * maxf(_spin_bar_grow, 1.0)
	var mouth := _spin_bar_global(_skull_mouth_local())
	_clear_spin_bar_drops()
	for i in 4:
		var drop := ColorRect.new()
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drop.color = Color(1.0, 1.0, 1.0, 0.92)
		drop.size = Vector2(8.0, 14.0) * drip_scale
		drop.global_position = mouth + Vector2(float(i - 1) * 6.0 * drip_scale, float(i) * 4.0 * drip_scale)
		_spin_count_root.add_child(drop)
		_spin_bar_drops.append(drop)
	var tween := CombatPace.bind(create_tween())
	tween.set_parallel(true)
	_spin_bar_tween = tween
	tween.tween_method(on_fill, 0.0, 1.0, SPIN_BAR_FILL_SEC)
	for drop in _spin_bar_drops:
		tween.tween_property(drop, "global_position", land, SPIN_BAR_FILL_SEC)
	await tween.finished
	if token == _vomit_token:
		_clear_spin_bar_drops()


func _kill_spin_bar_tween() -> void:
	if _spin_bar_tween != null and _spin_bar_tween.is_valid():
		_spin_bar_tween.kill()
	_spin_bar_tween = null


func _clear_spin_bar_drops() -> void:
	while not _spin_bar_drops.is_empty():
		var drop: ColorRect = _spin_bar_drops.pop_back()
		if drop != null and is_instance_valid(drop):
			drop.queue_free()


func _reduce_hud_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))


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
	if _is_player_combat_host():
		_hide_playtest_chrome()
		_attach_player_item_box()
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
	call_deferred("_layout_spin_bars")

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
	call_deferred("_fit_all_item_row_names")
	if _grid_host == null:
		return
	var host_w := maxf(_grid_host.size.x, 64.0)
	var host_h := maxf(_grid_host.size.y, GRID_HOST_MIN_HEIGHT)
	if host_w < 64.0 and _center_column != null:
		host_w = maxf(_center_column.size.x, 260.0)

	var bottom_reserve := 0.0
	_suppress_combat_root_legacy_labels()
	var grid_w := 0.0
	if _can_layout_combat_grid():
		combat.fit_to_panel(Vector2(host_w, host_h), bottom_reserve, true, true)
		grid_w = _safe_get_grid_ui_width()
		_fallback_grid_width = grid_w
	elif combat != null:
		grid_w = _layout_combat_grid_fallback(host_w, host_h, bottom_reserve)
		_fallback_grid_width = grid_w
	else:
		grid_w = _get_center_column_interior_width(host_w)
		_fallback_grid_width = grid_w
	_layout_item_desc_overlay()
	if _is_editor_preview():
		_ensure_editor_grid_shell_visible()

func _layout_execute_button_width() -> void:

	pass

func _layout_execute_button_to_grid_width(_grid_w: float) -> void:

	pass

func _apply_responsive_layout() -> void:

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

	pass

func _side_panel_inner_width(panel: PanelContainer) -> float:
	if panel == null:
		return 200.0


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

func _resolved_items_body_font() -> int:
	return maxi(int(round(float(SIDE_PANEL_BODY_FONT) * ITEMS_BODY_FONT_SCALE)), ITEMS_BODY_FONT_MIN)

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

func _hud_art_scale() -> float:
	var canvas := _hud_canvas_node()
	if canvas == null:
		return 1.0
	return maxf(canvas.scale.x, 0.01)


func _resolved_item_desc_font() -> int:
	var inner_w := _side_panel_inner_width(_item_picker_panel)
	var authored := _fit_body_font_size(
		"Void Satchel",
		ITEM_DESC_BODY_FONT_SCALE,
		inner_w - float(ITEM_PICKER_CHECKBOX_ICON_MAX + ITEM_PICKER_ROW_H_SEP),
		_item_row_body_font(),
	)
	return maxi(1, int(round(float(authored) * _hud_art_scale())))

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
	var fit_text := ECON_BAR_FIT_SAMPLE
	if bankroll_label != null and bankroll_label.text.length() > fit_text.length():
		fit_text = bankroll_label.text
	for font_size in range(ECON_BAR_FONT_MAX, ECON_BAR_FONT_MIN - 1, -1):
		var text_size := font.get_string_size(
			fit_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
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

	pass

func _refresh_spin_button_state() -> void:
	if spin_btn == null:
		return

	spin_btn.text = ""

func _refresh_encounter_win_overlay() -> void:
	if encounter_win_overlay == null:
		return
	if _is_player_combat_host():
		encounter_win_overlay.visible = false
		return
	var should_show := _safe_is_encounter_complete() and _safe_did_win_encounter()
	encounter_win_overlay.visible = should_show
	if encounter_win_label != null and should_show:
		encounter_win_label.text = "Encounter won!"


func _flash_goal_victory() -> void:
	pass


func await_victory_prelude() -> void:
	if combat == null:
		return
	if not _safe_is_encounter_complete() or not _safe_did_win_encounter():
		return
	if combat.get("_dev_skip_visuals") == true:
		return

	var tree := get_tree()
	if tree == null:
		return


	var waited := 0.0
	while _winnings_counter_running and waited < 1.5:
		await tree.create_timer(0.05).timeout
		waited += 0.05
	var shown_before := _shown_goal_value
	_sync_winnings_counter_to_combat_truth()

	var final_current := 0
	if combat.has_method("get_chip_bar_goal_progress_cents"):
		final_current = int(combat.get_chip_bar_goal_progress_cents())
	else:
		var progress := _goal_progress_only(_safe_get_goal_label())
		var slash := progress.find("/")
		if slash != -1:
			final_current = int(progress.substr(0, slash).strip_edges())

	var target := 0
	if combat.has_method("get_chip_bar_goal_target_cents"):
		target = int(combat.get_chip_bar_goal_target_cents())

	var gain := maxi(final_current - shown_before, 0)

	if goal_label != null:
		if gain <= 0:
			goal_label.text = "GOAL:\n%d / %d" % [final_current, target]
			await tree.create_timer(0.25).timeout
		else:
			var start_current := maxi(final_current - gain, 0)
			goal_label.text = "GOAL:\n%d / %d" % [start_current, target]
			var count_tw := create_tween()
			count_tw.tween_method(
				func(v: float) -> void:
					if goal_label != null:
						goal_label.text = "GOAL:\n%d / %d" % [int(round(v)), target],
				float(start_current),
				float(final_current),
				0.5
			)
			await count_tw.finished

		goal_label.pivot_offset = goal_label.size * 0.5
		goal_label.scale = Vector2.ONE
		goal_label.modulate = Color.WHITE
		var pop_tw := create_tween()
		pop_tw.set_parallel(true)
		pop_tw.tween_property(goal_label, "scale", Vector2(1.18, 1.18), 0.2)
		pop_tw.tween_property(goal_label, "modulate", Color(1.4, 1.4, 1.4), 0.2)
		pop_tw.chain()
		pop_tw.set_parallel(true)
		pop_tw.tween_property(goal_label, "scale", Vector2.ONE, 0.2)
		pop_tw.tween_property(goal_label, "modulate", Color.WHITE, 0.2)
		await pop_tw.finished
		goal_label.scale = Vector2.ONE
		goal_label.modulate = Color.WHITE

func _refresh_super_fs_choice_overlay() -> void:
	if super_fs_choice_overlay == null:
		return
	if not Engine.is_editor_hint():
		_ensure_free_spins_choice_presentation()
	var awaiting_choice: bool = _safe_is_waiting_for_free_spin_choice()
	var was_visible := super_fs_choice_overlay.visible
	super_fs_choice_overlay.visible = awaiting_choice
	if choose_bloody_hand_button != null:
		choose_bloody_hand_button.disabled = not awaiting_choice
	if choose_alcohol_button != null:
		choose_alcohol_button.disabled = not awaiting_choice
	if choose_cigarette_button != null:
		choose_cigarette_button.disabled = not awaiting_choice
	if not awaiting_choice:
		_reset_vice_choice_hover()
	if awaiting_choice and not was_visible:
		_layout_free_spins_choice()
		CombatPace.clear_rush()


func _ensure_free_spins_choice_presentation() -> void:
	if Engine.is_editor_hint() or super_fs_choice_overlay == null:
		return
	if not _fs_choice_ready:
		_build_free_spins_choice_presentation()
		_fs_choice_ready = true
	_layout_free_spins_choice()


func _build_free_spins_choice_presentation() -> void:
	_fs_choice_layer = CanvasLayer.new()
	_fs_choice_layer.name = "FreeSpinsChoiceLayer"
	_fs_choice_layer.layer = FS_CHOICE_LAYER
	add_child(_fs_choice_layer)
	super_fs_choice_overlay.reparent(_fs_choice_layer)
	super_fs_choice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super_fs_choice_overlay.scale = Vector2.ONE
	var dimmer := super_fs_choice_overlay.get_node_or_null("SuperFSChoiceDimmer") as ColorRect
	if dimmer != null:
		dimmer.color = Color(0, 0, 0, FS_SCRIM_ALPHA)
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := super_fs_choice_overlay.get_node_or_null("SuperFSChoicePanel") as Panel
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = false
	_ensure_fs_choice_fade(panel)
	var vbox := panel.get_node_or_null("SuperFSChoiceVBox") as VBoxContainer
	if vbox == null:
		return
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := vbox.get_node_or_null("SuperFSChoiceTitle") as Label
	var hint := vbox.get_node_or_null("SuperFSChoiceHint") as Label
	if title != null:
		_style_fs_label(title, 44)
		_split_vice_title(title)
	if hint != null:
		hint.text = FS_CHOICE_HINT
		_style_fs_label(hint, 32)
	var row := vbox.get_node_or_null("SuperFSChoiceButtons") as HBoxContainer
	if row != null:
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", int(FS_CHOICE_COL_GAP))
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dress_free_spins_choice_button(
		choose_bloody_hand_button,
		FS_ICON_BLOODY_HAND,
		PackedStringArray(["BLOODY HAND", "4 SPINS", "+4 on meter fill"])
	)
	_dress_free_spins_choice_button(
		choose_alcohol_button,
		FS_ICON_ALCOHOL,
		PackedStringArray(["ALCOHOL", "5 SPINS", "+3 on meter fill"])
	)
	_dress_free_spins_choice_button(
		choose_cigarette_button,
		FS_ICON_CIGARETTE,
		PackedStringArray(["CIGARETTE", "8 SPINS", "+2 on meter fill"])
	)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_free_spins_choice):
		vp.size_changed.connect(_layout_free_spins_choice)


func _layout_free_spins_choice() -> void:
	if not _fs_choice_ready or super_fs_choice_overlay == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var view := vp.get_visible_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	super_fs_choice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	super_fs_choice_overlay.offset_left = 0.0
	super_fs_choice_overlay.offset_top = 0.0
	super_fs_choice_overlay.offset_right = 0.0
	super_fs_choice_overlay.offset_bottom = 0.0
	super_fs_choice_overlay.position = Vector2.ZERO
	super_fs_choice_overlay.size = view
	super_fs_choice_overlay.scale = Vector2.ONE
	var buttons: Array[Button] = [choose_bloody_hand_button, choose_alcohol_button, choose_cigarette_button]
	var col_w := 180.0
	for button in buttons:
		if button == null:
			continue
		col_w = maxf(col_w, _fs_choice_column_width(button))
	var max_card_w := maxf(view.x - FS_CHOICE_MARGIN * 2.0, 320.0)
	var inner_budget := maxf(max_card_w - FS_CHOICE_PAD_X * 2.0 - FS_CHOICE_COL_GAP * 2.0, 180.0)
	col_w = minf(col_w, inner_budget / 3.0)
	var icon_px := minf(FS_ICON_PX, col_w * 0.62)
	var col_h := icon_px + 220.0
	for button in buttons:
		if button == null:
			continue
		button.custom_minimum_size = Vector2(col_w, col_h)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var slot := button.find_child("ViceIconSlot", true, false) as Control
		var icon := button.find_child("ViceIcon", true, false) as TextureRect
		if slot != null:
			slot.custom_minimum_size = Vector2(icon_px, icon_px)
		if icon == null:
			continue
		icon.custom_minimum_size = Vector2(icon_px, icon_px)
		if icon.size.x > 1.0:
			icon.pivot_offset = icon.size * 0.5
	var card_w := minf(col_w * 3.0 + FS_CHOICE_COL_GAP * 2.0 + FS_CHOICE_PAD_X * 2.0, max_card_w)
	var card_h := minf(FS_CHOICE_PAD_Y * 2.0 + 44.0 + 14.0 + 32.0 + 14.0 + col_h + 36.0, maxf(view.y - FS_CHOICE_MARGIN * 2.0, 280.0))
	var panel := super_fs_choice_overlay.get_node_or_null("SuperFSChoicePanel") as Panel
	if panel != null:
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.offset_left = -card_w * 0.5
		panel.offset_top = -card_h * 0.5
		panel.offset_right = card_w * 0.5
		panel.offset_bottom = card_h * 0.5
		_apply_fs_choice_fade(panel, card_w, card_h)


func _dress_free_spins_choice_button(button: Button, icon_tex: Texture2D, lines: PackedStringArray) -> void:
	if button == null or button.get_node_or_null("ViceChoiceColumn") != null:
		return
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, empty)
	button.flat = true
	button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.clip_contents = false
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var host := CenterContainer.new()
	host.name = "ViceChoiceColumn"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(host)
	var frame := Control.new()
	frame.name = "ViceChoiceFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.add_child(frame)
	var column := VBoxContainer.new()
	column.name = "ViceChoiceStack"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(column)
	column.minimum_size_changed.connect(_sync_vice_choice_frame.bind(frame, column))
	var slot := Control.new()
	slot.name = "ViceIconSlot"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.custom_minimum_size = Vector2(FS_ICON_PX, FS_ICON_PX)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(slot)
	var highlight := TextureRect.new()
	highlight.name = "ViceHoverHighlight"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.texture = _vice_icon_highlight_texture()
	highlight.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	highlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	highlight.stretch_mode = TextureRect.STRETCH_SCALE
	highlight.modulate = Color(1, 1, 1, 0)
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	highlight.offset_left = -FS_HOVER_HIGHLIGHT_PAD
	highlight.offset_top = -FS_HOVER_HIGHLIGHT_PAD
	highlight.offset_right = FS_HOVER_HIGHLIGHT_PAD
	highlight.offset_bottom = FS_HOVER_HIGHLIGHT_PAD
	slot.add_child(highlight)
	var icon := TextureRect.new()
	icon.name = "ViceIcon"
	icon.texture = icon_tex
	icon.custom_minimum_size = Vector2(FS_ICON_PX, FS_ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(icon)
	icon.resized.connect(_on_vice_icon_resized.bind(icon))
	button.mouse_entered.connect(_on_vice_choice_hover.bind(icon))
	button.mouse_exited.connect(_on_vice_choice_unhover.bind(icon))
	var text_block := PanelContainer.new()
	text_block.name = "ViceTextBlock"
	text_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_block.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_block.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column.add_child(text_block)
	var lines_box := VBoxContainer.new()
	lines_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines_box.alignment = BoxContainer.ALIGNMENT_CENTER
	lines_box.add_theme_constant_override("separation", 4)
	text_block.add_child(lines_box)
	var line_names: PackedStringArray = PackedStringArray(["ViceName", "ViceSpins", "ViceMeter"])
	for i in lines.size():
		if i == 1:
			var gap := Control.new()
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			gap.custom_minimum_size = Vector2(0, 12)
			lines_box.add_child(gap)
		var lab := Label.new()
		lab.name = line_names[i] if i < line_names.size() else "ViceLine"
		lab.text = lines[i]
		lab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_style_fs_label(lab, 32, FS_NAME_RED if i == 0 else HUD_WHITE_TEXT_COLOR)
		lines_box.add_child(lab)
	_sync_vice_choice_frame(frame, column)


func _ensure_fs_choice_fade(panel: Panel) -> void:
	if panel.get_node_or_null("ViceChoiceFade") != null:
		return
	var fade := TextureRect.new()
	fade.name = "ViceChoiceFade"
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(fade)
	panel.move_child(fade, 0)


func _apply_fs_choice_fade(panel: Panel, card_w: float, card_h: float) -> void:
	_ensure_fs_choice_fade(panel)
	var fade := panel.get_node_or_null("ViceChoiceFade") as TextureRect
	if fade == null:
		return
	fade.offset_left = -FS_FADE_PAD
	fade.offset_top = -FS_FADE_PAD
	fade.offset_right = FS_FADE_PAD
	fade.offset_bottom = FS_FADE_PAD
	fade.texture = _make_fs_fade_texture(card_w, card_h)


func _make_fs_fade_texture(card_w: float, card_h: float) -> ImageTexture:
	var full_w := maxf(card_w + FS_FADE_PAD * 2.0, 1.0)
	var full_h := maxf(card_h + FS_FADE_PAD * 2.0, 1.0)
	var fade_len := FS_FADE_PAD + FS_FADE_INSET
	var inset_u := clampf(fade_len / full_w, 0.02, 0.49)
	var inset_v := clampf(fade_len / full_h, 0.02, 0.49)
	var tex_w := 160
	var tex_h := 160
	var img := Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	for y in tex_h:
		for x in tex_w:
			var u := (float(x) + 0.5) / float(tex_w)
			var v := (float(y) + 0.5) / float(tex_h)
			var ax := 0.0
			if u < inset_u:
				ax = 1.0 - u / inset_u
			elif u > 1.0 - inset_u:
				ax = (u - (1.0 - inset_u)) / inset_u
			var ay := 0.0
			if v < inset_v:
				ay = 1.0 - v / inset_v
			elif v > 1.0 - inset_v:
				ay = (v - (1.0 - inset_v)) / inset_v
			var t := clampf(maxf(ax, ay), 0.0, 1.0)
			var s := t * t * (3.0 - 2.0 * t)
			img.set_pixel(x, y, Color(0, 0, 0, 1.0 - s))
	return ImageTexture.create_from_image(img)


func _tween_vice_choice_hover(icon: TextureRect, hovered: bool) -> void:
	if icon == null or not is_instance_valid(icon):
		return
	var key := icon.get_instance_id()
	var existing: Tween = _vice_hover_tweens.get(key) as Tween
	if existing != null and is_instance_valid(existing):
		existing.kill()
	icon.pivot_offset = icon.size * 0.5
	var target := FS_ICON_HOVER_SCALE if hovered else 1.0
	var highlight := _vice_hover_highlight(icon)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_parallel(true)
	tw.tween_property(icon, "scale", Vector2(target, target), FS_ICON_HOVER_SEC)
	if highlight != null:
		var show_a := 1.0 if hovered else 0.0
		tw.tween_property(highlight, "modulate:a", show_a, FS_ICON_HOVER_SEC)
	_vice_hover_tweens[key] = tw


func _vice_icon_highlight_texture() -> ImageTexture:
	if _vice_highlight_tex != null:
		return _vice_highlight_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(n - 1) * 0.5, float(n - 1) * 0.5)
	var radius := float(n) * 0.5
	for y in n:
		for x in n:
			var dist := Vector2(float(x), float(y)).distance_to(center) / radius
			var t := clampf(dist, 0.0, 1.0)
			var fade := t * t * (3.0 - 2.0 * t)
			img.set_pixel(x, y, Color(1, 1, 1, (1.0 - fade) * 0.32))
	_vice_highlight_tex = ImageTexture.create_from_image(img)
	return _vice_highlight_tex


func _sync_vice_choice_frame(frame: Control, column: Control) -> void:
	if frame == null or column == null:
		return
	var need := column.get_combined_minimum_size()
	if frame.custom_minimum_size != need:
		frame.custom_minimum_size = need


func _vice_hover_highlight(icon: TextureRect) -> CanvasItem:
	var node: Node = icon
	while node != null:
		if node is Button:
			return (node as Button).find_child("ViceHoverHighlight", true, false) as CanvasItem
		node = node.get_parent()
	return null


func _reset_vice_choice_hover() -> void:
	for key in _vice_hover_tweens.keys():
		var tw: Tween = _vice_hover_tweens[key] as Tween
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_vice_hover_tweens.clear()
	if super_fs_choice_overlay == null:
		return
	for node in super_fs_choice_overlay.find_children("ViceIcon", "TextureRect", true):
		var icon := node as TextureRect
		if icon != null:
			icon.scale = Vector2.ONE
	for node in super_fs_choice_overlay.find_children("ViceHoverHighlight", "CanvasItem", true):
		var highlight := node as CanvasItem
		if highlight != null:
			highlight.modulate.a = 0.0


func _on_vice_choice_hover(icon: TextureRect) -> void:
	_tween_vice_choice_hover(icon, true)


func _on_vice_choice_unhover(icon: TextureRect) -> void:
	_tween_vice_choice_hover(icon, false)


func _fs_choice_column_width(button: Button) -> float:
	var widest := FS_ICON_PX + 72.0
	for node in button.find_children("*", "Label", true, false):
		var lab := node as Label
		if lab == null:
			continue
		var font := lab.get_theme_font("font")
		if font == null:
			continue
		var font_px := lab.get_theme_font_size("font_size")
		widest = maxf(widest, font.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x + 72.0)
	return widest


func _split_vice_title(title: Label) -> void:
	if title.get_parent() != null and title.get_parent().name == "ViceTitleRow":
		return
	var row := HBoxContainer.new()
	row.name = "ViceTitleRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	var parent := title.get_parent()
	var index := title.get_index()
	parent.add_child(row)
	parent.move_child(row, index)
	title.reparent(row)
	title.text = "Choose Your "
	var vice := Label.new()
	vice.name = "ViceTitleWord"
	vice.text = "Vice"
	vice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_fs_label(vice, 44, FS_NAME_RED)
	row.add_child(vice)


func _style_fs_label(label: Label, font_size: int, font_color: Color = HUD_WHITE_TEXT_COLOR) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", VT323_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


func _on_vice_icon_resized(icon: TextureRect) -> void:
	if icon == null:
		return
	icon.pivot_offset = icon.size * 0.5


func _on_choose_bloody_hand_pressed() -> void:
	_submit_super_fs_choice(POWER_BLOODY_HAND)

func _on_choose_alcohol_pressed() -> void:
	_submit_super_fs_choice(POWER_ALCOHOL)

func _on_choose_cigarette_pressed() -> void:
	_submit_super_fs_choice(POWER_CIGARETTE)

func _submit_super_fs_choice(power_id: StringName) -> void:
	if not combat.is_waiting_for_free_spin_choice():
		return
	if _spin_busy:
		return
	_spin_busy = true
	if spin_btn != null:
		spin_btn.disabled = true
	var profile := get_node_or_null("/root/AxelProfile")
	if profile != null:
		profile.call("mark_free_spins_seen")
	combat.choose_free_spins_power(power_id)
	_refresh_readouts()
	await combat.run_free_spin_round()
	_release_spin_busy()
	if spin_btn != null:
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
		_ensure_playtest_tuning()
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
	_configure_item_picker_list()


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
		_apply_item_desc_typography()
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
	_item_desc_panel.add_child(_item_desc_label)
	_item_desc_clip.add_child(_item_desc_panel)
	_apply_item_desc_typography()
	_ensure_item_desc_scroll_hook()


func _apply_item_desc_typography() -> void:
	if _item_desc_clip != null:
		_item_desc_clip.theme = TERMINAL_THEME
	if _item_desc_label == null:
		return
	_item_desc_label.add_theme_font_override("font", VT323_FONT)
	_apply_white_hud_text_style(_item_desc_label)


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


func _process(delta: float) -> void:
	_tick_cascade_multiplier_idle()
	if not Engine.is_editor_hint():
		_maybe_queue_fight_tutorials(delta)
		_release_held_freeze_lessons(delta)
		_sync_tutorial_gates()
		_release_after_match_lessons()
		_push_tutorial_hud_rects()
		_sync_tutorial_skull_hint()
		_sync_skull_ready()
		_sync_freeze_overlay()
	if Engine.is_editor_hint() and not editor_preview_enabled:
		return
	if _item_desc_panel == null or not _item_desc_panel.visible:
		return
	_layout_item_desc_overlay()


func _tick_cascade_multiplier_idle() -> void:
	if _cascade_mult_label == null:
		return
	if _cascade_mult_pop_tween != null and _cascade_mult_pop_tween.is_valid():
		return
	if _cascade_mult_rest_pos == Vector2.ZERO:
		_cascade_mult_rest_pos = _cascade_mult_label.position
	if _multiplier_idle_blocked():
		_cascade_mult_label.position = _cascade_mult_rest_pos
		return
	var mult := _last_displayed_cascade_mult
	if mult < 5:
		_cascade_mult_label.position = _cascade_mult_rest_pos
		return
	var amp := clampf(2.0 + float(mult - 5) * 0.35, 2.0, 5.0)
	var t := float(Time.get_ticks_msec()) * 0.001
	_cascade_mult_label.position = _cascade_mult_rest_pos + Vector2(
		sin(t * 7.3) * amp, cos(t * 6.1) * amp
	)


func _multiplier_idle_blocked() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	if bool(settings.call("get_value", "access", "reduce_flashing", false)):
		return true
	return float(settings.call("get_value", "access", "screen_shake", 1.0)) <= 0.05


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
		_strip_retired_playtest_controls(existing)
		_playtest_tuning = existing
		_ignore_cap_checkbox = existing.find_child("IgnoreCapCheck", true, false) as CheckBox
		if _ignore_cap_checkbox == null:
			_ignore_cap_checkbox = _make_ignore_cap_checkbox()
			existing.add_child(_ignore_cap_checkbox)
			existing.move_child(_ignore_cap_checkbox, 0)
		return
	_playtest_tuning = VBoxContainer.new()
	_playtest_tuning.name = "PlaytestTuning"
	_playtest_tuning.add_theme_constant_override("separation", 3)
	_ignore_cap_checkbox = _make_ignore_cap_checkbox()
	_playtest_tuning.add_child(_ignore_cap_checkbox)
	vbox.add_child(_playtest_tuning)
	vbox.move_child(_playtest_tuning, 1)


func _make_ignore_cap_checkbox() -> CheckBox:
	var box := CheckBox.new()
	box.name = "IgnoreCapCheck"
	box.text = "Ignore slot cap"
	_style_item_picker_checkbox(box, SIDE_PANEL_HINT_FONT)
	box.toggled.connect(_on_ignore_cap_toggled)
	return box


func _strip_retired_playtest_controls(tuning: Node) -> void:
	if tuning == null:
		return
	var retired_names := [
		"PaidSpinUsedSpin", "PaidSpinBudgetSpin", "LimitSpinsCheck", "PaidSpinHint",
		"GoalBaseSpin", "GoalProgressSpin", "GoalEffectiveLabel",
	]
	for retired_name in retired_names:
		var node := tuning.find_child(retired_name, true, false)
		if node == null or not is_instance_valid(node):
			continue
		var drop := node
		var parent := node.get_parent()
		if parent != null and parent != tuning:
			drop = parent
		drop.free()
	var leftover: Array[Node] = []
	for child in tuning.get_children():
		if child is Label:
			var text := String((child as Label).text).strip_edges()
			if text == "PAID SPINS" or text == "GOAL" or text == "Used" or text == "Budget" or text == "Limit spins":
				leftover.append(child)
		elif child is CheckBox and String((child as CheckBox).text).strip_edges() == "Limit spins":
			leftover.append(child)
	for node in leftover:
		if is_instance_valid(node):
			node.free()


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
		{"letter": "C", "name": "Vice Round"},
		{"letter": "D", "name": "Free Spins"},
		{"letter": "E", "name": "Diagonal"},
		{"letter": "F", "name": "Board-count"},
		{"letter": "M", "name": "Corner glyphs"},
		{"letter": "G", "name": "Sealed grid"},
		{"letter": "H", "name": "True-path"},
	]
	for line_key in ItemLinesScript.picker_line_keys():
		family_defs.append({
			"letter": String(line_key),
			"name": ItemLinesScript.display_name(String(line_key)),
		})
	var fam_header := Label.new()
	fam_header.text = "FAMILIES"
	fam_header.add_theme_color_override("font_color", READOUT_ACCENT_COLOR)
	_style_item_chrome_label(fam_header)
	items_vbox.add_child(fam_header)
	for fam in family_defs:
		var letter: String = str(fam["letter"])
		if not _family_rank.has(letter):
			if ItemLinesScript.is_picker_line(letter):
				_family_rank[letter] = ItemLinesScript.first_picker_rank(letter)
			else:
				_family_rank[letter] = 0
		var rank: int = int(_family_rank[letter])
		if ItemLinesScript.is_picker_line(letter) and ItemLinesScript.rung_id(letter, rank).is_empty():
			rank = ItemLinesScript.first_picker_rank(letter)
			_family_rank[letter] = rank
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
		rh.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
		_style_item_chrome_label(rh)
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
	call_deferred("_fit_all_item_row_names")


func _family_item_at_rank(by_id: Dictionary, letter: String, rank: int) -> Resource:
	if ItemLinesScript.is_picker_line(letter):
		var baseline_id := ItemLinesScript.rung_id(letter, rank)
		if baseline_id.is_empty():
			baseline_id = ItemLinesScript.item_id_at_rank(letter, rank)
		return by_id.get(baseline_id, null)
	var prefixes: Array[String] = ["C", "U", "R", "E"]
	var r: int = clampi(rank, 0, 3)
	var key := "%s-%s" % [prefixes[r], letter]
	return by_id.get(key, null)


func _mark_item_row_name(name_lab: Label, kind: StringName) -> void:
	name_lab.set_meta("item_row_name", true)
	name_lab.add_theme_font_override("font", VT323_FONT)
	name_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lab.clip_text = false
	name_lab.max_lines_visible = ITEM_NAME_MAX_LINES
	name_lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var texts: PackedStringArray = _item_row_texts.get(kind, PackedStringArray())
	texts.append(name_lab.text)
	_item_row_texts[kind] = texts


func _configure_item_picker_list() -> void:
	if _item_picker_panel == null:
		return
	var list := _item_picker_panel.get_meta("list") as VBoxContainer
	if list == null:
		return
	list.propagate_maximum_size = true
	list.add_theme_constant_override("separation", ITEM_PICKER_LIST_SEP)
	var inner := _side_panel_inner_width(_item_picker_panel)
	list.custom_maximum_size = Vector2(inner, -1.0)


func _item_name_column_width(with_rank: bool) -> float:
	var inner := _side_panel_inner_width(_item_picker_panel)
	var used := float(ITEM_ICON_DRAW_SIZE + ITEM_PICKER_CHECKBOX_COL_W)
	var seps := 2
	if with_rank:
		used += float(ITEM_RANK_BTN_W)
		seps = 3
	used += float(ITEM_PICKER_ROW_H_SEP * seps) + ITEM_NAME_RIGHT_PAD
	return maxf(inner - used, 48.0)


func _item_entry_name_label(entry: Dictionary) -> Label:
	var named := entry.get("name") as Label
	if named != null:
		return named
	var row := entry.get("row") as Control
	if row == null:
		return null
	for child in row.get_children():
		var lab := child as Label
		if lab != null and bool(lab.get_meta("item_row_name", false)):
			return lab
	return null


func _fit_item_name_wrap(name_lab: Label, with_rank: bool) -> void:
	if name_lab == null:
		return
	var max_w := _item_name_column_width(with_rank)
	name_lab.custom_maximum_size = Vector2(max_w, -1.0)
	name_lab.size.x = max_w
	var line_h := name_lab.get_line_height()
	if line_h <= 0:
		line_h = _resolved_items_body_font()
	var lines := clampi(name_lab.get_line_count(), 1, ITEM_NAME_MAX_LINES)
	name_lab.custom_minimum_size = Vector2(0.0, float(line_h * lines))


func _fit_all_item_row_names() -> void:
	if _item_picker_panel == null or not is_instance_valid(_item_picker_panel):
		return
	_configure_item_picker_list()
	var inner := _side_panel_inner_width(_item_picker_panel)
	for entry in _item_entries:
		var name_lab := _item_entry_name_label(entry)
		if name_lab == null:
			continue
		_fit_item_name_wrap(name_lab, str(entry.get("kind", "")) == "family")
	for child in _item_picker_panel.find_children("*", "Label", true, false):
		var lab := child as Label
		if lab == null or not bool(lab.get_meta("item_chrome_label", false)):
			continue
		lab.custom_maximum_size = Vector2(inner, -1.0)
		lab.clip_text = false
		lab.max_lines_visible = ITEM_NAME_MAX_LINES


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
	var icon := _make_item_icon(item)
	row.add_child(icon)
	var cb := CheckBox.new()
	cb.text = ""
	cb.set_meta("item_row_checkbox", true)
	_style_item_row_checkbox(cb)
	cb.toggled.connect(_on_family_toggled.bind(letter, cb))
	row.add_child(cb)
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
	rank_btn.add_theme_font_override("font", VT323_FONT)
	rank_btn.add_theme_font_size_override("font_size", _resolved_item_rank_font())
	rank_btn.pressed.connect(_on_family_rank_pressed.bind(letter))
	row.add_child(rank_btn)
	_bind_item_row_hover(row, _item_desc_text_for_item(item, family_name))
	_item_entries.append({
		"kind": "family",
		"letter": letter,
		"checkbox": cb,
		"item": item,
		"icon": icon,
		"name": name_lab,
		"rank_btn": rank_btn,
		"row": row,
	})
	return row


func _make_unique_row(item: Resource) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", ITEM_PICKER_ROW_H_SEP)
	var rarity_idx: int = clampi(int(item.get("rarity")), 0, RARITY_NAMES.size() - 1)
	row.add_child(_make_item_icon(item))
	var cb := CheckBox.new()
	cb.text = ""
	cb.set_meta("item_row_checkbox", true)
	_style_item_row_checkbox(cb)
	cb.toggled.connect(_on_item_checkbox_toggled.bind(item, cb))
	row.add_child(cb)
	var name_lab := Label.new()
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.text = item.display_name
	name_lab.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
	name_lab.add_theme_font_size_override("font_size", _resolved_items_body_font())
	name_lab.mouse_filter = Control.MOUSE_FILTER_PASS
	_mark_item_row_name(name_lab, &"unique")
	row.add_child(name_lab)
	_bind_item_row_hover(row, _item_desc_text_for_item(item))
	_item_entries.append({"kind": "unique", "checkbox": cb, "item": item, "name": name_lab, "row": row})
	return row


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
	for file_name in ResourceLoader.list_directory("res://combat/data/items"):
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res := load("res://combat/data/items/".path_join(file_name))
			if res != null and res is ItemDefScript:
				found.append(res)
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
	var current_rank: int = int(_family_rank.get(letter, 0))
	var next_rank: int = ItemLinesScript.next_picker_rank(letter, current_rank) if ItemLinesScript.is_picker_line(letter) else ((current_rank + 1) % 4)
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


func _refresh_playtest_readouts() -> void:
	pass


func _refresh_item_picker_title() -> void:
	if _item_picker_title != null:
		_item_picker_title.text = "ITEMS (%d/%d)" % [
			_safe_get_item_inventory_size(),
			_safe_get_item_max_slots(),
		]
