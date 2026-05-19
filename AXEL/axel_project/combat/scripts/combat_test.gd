## Combat test UI — mirrored playtest shell (SPINS | grid | ITEMS), percentage layout, integer economy.
## Canonical entry: `res://combat/combat_test.tscn` (F6). See `README_COMBAT_TEST_VERSIONS.md`.
extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")
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
const GOAL_LABEL_FONT := 26
const WINNINGS_READOUT_FONT := 31
const CASCADE_MULT_READOUT_FONT := 24
const WINNINGS_READOUT_OUTLINE := 1
const CASCADE_MULT_READOUT_OUTLINE := 1
const HISTORY_BODY_FONT := 13
const LAYOUT_GOAL_BOX_START := 0.86
const LAYOUT_GOAL_BOX_END := 0.992

var RARITY_COLORS: Dictionary = {
	0: Color(0.65, 0.65, 0.65),
	1: Color(0.4, 0.78, 0.4),
	2: Color(0.4, 0.6, 0.9),
	3: Color(0.72, 0.4, 0.88),
	4: Color(0.95, 0.75, 0.2),
}

@onready var seed_spin: SpinBox = %SeedSpinBox
@onready var spin_btn: Button = %SpinButton
@onready var bet_minus_btn: Button = %BetMinusButton
@onready var bet_plus_btn: Button = %BetPlusButton
@onready var bet_label: Label = %BetLabel
@onready var mult_label: Label = %MultiplierReadout
@onready var goal_label: Label = %GoalLabel
@onready var budget_label: Label = %BudgetLabel
@onready var bankroll_label: Label = %BankrollLabel
@onready var combat: CombatRootScript = %CombatRoot
@onready var encounter_win_overlay: Control = %EncounterWinOverlay
@onready var encounter_win_label: Label = %EncounterWinLabel
@onready var super_fs_choice_overlay: Control = %SuperFSChoiceOverlay
@onready var choose_love_button: Button = %ChooseLoveButton
@onready var choose_star_button: Button = %ChooseStarButton
@onready var choose_storm_button: Button = %ChooseStormButton
@onready var top_bar: Control = $TopBar
@onready var meta_box: PanelContainer = %MetaBox
@onready var goal_box: PanelContainer = %GoalBox
@onready var stake_selector: Control = $StakeSelector

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


func _ready() -> void:
	seed_spin.min_value = 0
	seed_spin.max_value = 2147483647
	seed_spin.value = _pick_start_seed()
	_queued_seed = int(seed_spin.value)
	_hide_legacy_meter_nodes()
	_organize_top_hud()
	_configure_hud_layers()
	_build_play_shell()
	spin_btn.pressed.connect(_on_spin_pressed)
	bet_minus_btn.pressed.connect(_on_bet_minus_pressed)
	bet_plus_btn.pressed.connect(_on_bet_plus_pressed)
	combat.spin_started.connect(_on_spin_started)
	combat.line_win_resolved.connect(_on_line_win_resolved)
	combat.readouts_progressed.connect(_refresh_readouts)
	combat.spin_finished.connect(_on_spin_finished)
	combat.premium_meter_changed.connect(_on_premium_meter_changed)
	combat.meter_full_transition_started.connect(_on_meter_full_transition_started)
	choose_love_button.pressed.connect(_on_choose_love_pressed)
	choose_star_button.pressed.connect(_on_choose_star_pressed)
	choose_storm_button.pressed.connect(_on_choose_storm_pressed)
	resized.connect(_on_size_changed)
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
	seed_spin.value_changed.connect(_on_seed_spin_value_changed)
	_set_default_bet()
	_build_item_picker()
	_style_stake_pill()
	_configure_spin_button_layer()
	if budget_label != null:
		budget_label.visible = false
	call_deferred("_finish_initial_layout")
	_refresh_readouts()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()
	_refresh_spin_button_state()


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
		return
	node.get_parent().remove_child(node)
	add_child(node)
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


func _build_play_shell() -> void:
	_play_area = Control.new()
	_play_area.name = "PlayArea"
	_play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_play_area)
	move_child(_play_area, 1)

	_play_row = HBoxContainer.new()
	_play_row.name = "PlayRow"
	_play_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_row.add_theme_constant_override("separation", int(GRID_COLUMN_GAP))
	_play_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_play_area.add_child(_play_row)

	_spin_history_panel = _build_history_placeholder()
	_spin_history_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_spin_history_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_play_row.add_child(_spin_history_panel)

	_center_column = VBoxContainer.new()
	_center_column.name = "CenterColumn"
	_center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_column.add_theme_constant_override("separation", CENTER_COLUMN_SEPARATION)
	_play_row.add_child(_center_column)

	_grid_host = Control.new()
	_grid_host.name = "GridHost"
	_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_host.custom_minimum_size = Vector2(260, 200)
	_grid_host.clip_contents = true
	_center_column.add_child(_grid_host)
	if combat.get_parent() != _grid_host:
		combat.reparent(_grid_host)
	combat.visible = true

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

	_winnings_center = CenterContainer.new()
	_winnings_center.name = "WinningsCenter"
	_winnings_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_winnings_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_winnings_center.custom_minimum_size = Vector2(0.0, WINNINGS_BAND_MIN_HEIGHT)
	_center_column.add_child(_winnings_center)

	var winnings_row := HBoxContainer.new()
	winnings_row.name = "WinningsRow"
	winnings_row.alignment = BoxContainer.ALIGNMENT_CENTER
	winnings_row.add_theme_constant_override("separation", WINNINGS_ROW_SEPARATION)
	winnings_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	winnings_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_winnings_center.add_child(winnings_row)

	if mult_label.get_parent() != null:
		mult_label.get_parent().remove_child(mult_label)
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
	winnings_pill.add_child(mult_label)
	winnings_row.add_child(winnings_pill)

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

	_center_footer = VBoxContainer.new()
	_center_footer.name = "CenterFooter"
	_center_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_footer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_center_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_footer.add_theme_constant_override("separation", CENTER_FOOTER_SEPARATION)
	_center_column.add_child(_center_footer)

	if spin_btn.get_parent() != null:
		spin_btn.get_parent().remove_child(spin_btn)
	spin_btn.visible = true
	_reset_container_child_layout(spin_btn)
	spin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spin_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_btn.custom_minimum_size = Vector2(0.0, EXECUTE_BUTTON_MIN_HEIGHT)
	_center_footer.add_child(spin_btn)

	_bottom_window_margin = Control.new()
	_bottom_window_margin.name = "BottomWindowMargin"
	_bottom_window_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_window_margin.custom_minimum_size = Vector2(0.0, BOTTOM_WINDOW_MARGIN)
	_bottom_window_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_window_margin.size_flags_vertical = Control.SIZE_SHRINK_END
	_center_column.add_child(_bottom_window_margin)


func _integrate_economics_into_center_hud() -> void:
	if bankroll_label == null or stake_selector == null:
		return
	if _economics_center == null:
		_economics_center = CenterContainer.new()
		_economics_center.name = "EconomicsCenter"
		_economics_center.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_economics_center)
		move_child(_economics_center, 2)
	else:
		if _economics_center.get_parent() != self:
			_economics_center.get_parent().remove_child(_economics_center)
			add_child(_economics_center)
			move_child(_economics_center, 2)

	if _economics_stack == null:
		_economics_stack = VBoxContainer.new()
		_economics_stack.name = "EconomicsStack"
		_economics_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		_economics_stack.add_theme_constant_override("separation", ECONOMICS_STACK_SEPARATION)
		_economics_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_economics_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_economics_center.add_child(_economics_stack)

	if bankroll_label.get_parent() != null:
		bankroll_label.get_parent().remove_child(bankroll_label)
	bankroll_label.visible = true
	bankroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_container_child_layout(bankroll_label)
	bankroll_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bankroll_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_economics_stack.add_child(bankroll_label)

	if stake_selector.get_parent() != null:
		stake_selector.get_parent().remove_child(stake_selector)
	_reset_container_child_layout(stake_selector)
	stake_selector.visible = true
	stake_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stake_selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_economics_stack.add_child(stake_selector)


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
		goal_label.add_theme_font_size_override("font_size", GOAL_LABEL_FONT)


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
	if bet_label.get_parent() == null:
		return
	var bet_row := bet_label.get_parent() as HBoxContainer
	if bet_row == null:
		return
	var idx := bet_label.get_index()
	bet_row.remove_child(bet_label)
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
	_stake_pill.add_child(bet_label)
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", 22)
	bet_row.add_child(_stake_pill)
	bet_row.move_child(_stake_pill, idx)


func _on_spin_pressed() -> void:
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
	var display_seed := combat.get_current_seed()
	if _can_queue_seed_change():
		display_seed = _queued_seed
	_set_seed_spin_value_no_signal(display_seed)
	var stake_value := int(combat.get_current_bet())
	bet_label.text = "%d" % stake_value
	mult_label.text = "%d" % int(combat.get_round_winnings())
	_refresh_cascade_multiplier_readout()
	if _premium_progress != null:
		_premium_progress.value = float(combat.get_meter_sections_filled())
	var cap_units := int(combat.get_bankroll_cap())
	var bankroll_units := int(combat.get_bankroll())
	bankroll_label.text = "%d/%d" % [bankroll_units, cap_units]
	goal_label.text = "GOAL\n%s" % _goal_progress_only(combat.get_goal_label())
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()


func _refresh_cascade_multiplier_readout() -> void:
	if _cascade_mult_label == null:
		return
	var mult := int(combat.get_multiplier_value())
	_cascade_mult_label.text = _format_cascade_multiplier_text(mult)
	if mult > _last_displayed_cascade_mult:
		_pulse_cascade_multiplier()
	_last_displayed_cascade_mult = mult


func _format_cascade_multiplier_text(mult: int) -> String:
	var text := "%d×" % mult
	if combat.is_multiplier_cap_active():
		text += " / %d" % combat.get_multiplier_cap_value()
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


func _on_spin_finished() -> void:
	if combat.get_state() == CombatRoot.State.IDLE or combat.is_encounter_complete():
		spin_btn.disabled = false
	_refresh_spin_button_state()


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
			"combat_seed_current": combat.get_current_seed(),
			"spins_used": combat.get_spins_used(),
			"state": combat.get_state(),
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
	var symbol_name: String = String(event.get("symbol_name", ""))
	var bet: int = int(event.get("bet", 0))
	var symbol_value: float = float(event.get("symbol_value", 0.0))
	var cascade_mult: int = int(event.get("cascade_multiplier", 1))
	var row := Label.new()
	row.text = "%s — %d x %s x %d" % [
		symbol_name,
		bet,
		_format_history_factor(symbol_value),
		cascade_mult,
	]
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_font_size_override("font_size", HISTORY_BODY_FONT)
	row.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 1.0))
	_history_spin_list.add_child(row)


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
	combat.fit_to_panel(Vector2(host_w, host_h), bottom_reserve, true, true)
	_layout_premium_bar()
	_layout_execute_button_width()


func _layout_premium_bar() -> void:
	if _premium_progress == null or _grid_host == null:
		return
	var grid_bottom := combat.position.y + combat.grid_ui.position.y + combat.grid_ui.size.y
	var grid_left := combat.position.x + combat.grid_ui.position.x
	_premium_progress.position = Vector2(grid_left, grid_bottom)
	_premium_progress.size = Vector2(combat.grid_ui.size.x, PREMIUM_BAR_HEIGHT)
	_premium_progress.z_index = 6


func _layout_execute_button_width() -> void:
	if spin_btn == null or combat == null:
		return
	var grid_w := combat.grid_ui.size.x
	if grid_w < 8.0:
		return
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
	if bankroll_label == null:
		return
	var bankroll_font := BANKROLL_READOUT_FONT
	if size.x < RESPONSIVE_NARROW_W:
		bankroll_font = BANKROLL_READOUT_FONT_NARROW
	bankroll_label.add_theme_font_size_override("font_size", bankroll_font)
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
	if spin_btn.disabled:
		spin_btn.text = "SPIN LOCKED"
	else:
		spin_btn.text = "EXECUTE"


func _refresh_encounter_win_overlay() -> void:
	if encounter_win_overlay == null:
		return
	var should_show := combat.is_encounter_complete() and combat.did_win_encounter()
	encounter_win_overlay.visible = should_show
	if encounter_win_label != null and should_show:
		encounter_win_label.text = "Encounter won!"


func _refresh_super_fs_choice_overlay() -> void:
	if super_fs_choice_overlay == null:
		return
	var awaiting_choice: bool = combat.is_waiting_for_free_spin_choice()
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
	if not combat.is_encounter_complete() and combat.get_spins_used() != 0:
		return false
	return combat.get_state() == CombatRoot.State.IDLE


func _can_apply_queued_seed_on_execute() -> bool:
	if not _can_queue_seed_change():
		return false
	return _queued_seed != combat.get_current_seed()


func _set_seed_spin_value_no_signal(seed_value: int) -> void:
	if int(seed_spin.value) == seed_value:
		return
	seed_spin.set_value_no_signal(seed_value)


func _build_item_picker() -> void:
	_item_picker_panel = _make_side_panel("ITEMS")
	_item_picker_panel.name = "ItemPickerPanel"

	var items_vbox: VBoxContainer = _item_picker_panel.get_meta("list") as VBoxContainer

	_item_picker_title = _item_picker_panel.get_meta("header") as Label
	_item_picker_title.text = "ITEMS (0/%d)" % combat.inventory.get_current_max_slots()
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
	else:
		add_child(_item_picker_panel)


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
	if toggled_on:
		if not combat.equip_item(item):
			cb.set_pressed_no_signal(false)
			return
	else:
		combat.unequip_item(item)
	_refresh_item_picker_title()


func _refresh_item_picker_title() -> void:
	if _item_picker_title != null:
		_item_picker_title.text = "ITEMS (%d/%d)" % [combat.inventory.size(), combat.inventory.get_current_max_slots()]


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
