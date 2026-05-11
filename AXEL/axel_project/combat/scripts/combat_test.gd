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
@onready var meter_circle: Control = %PremiumMeterCircle
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

var _last_meter_sections: int = -1
var _queued_seed: int = 0
var _item_picker_panel: PanelContainer
var _item_picker_title: Label
var _item_entries: Array = []

func _ready() -> void:
	seed_spin.min_value = 0
	seed_spin.max_value = 12345
	seed_spin.value = _pick_start_seed()
	_queued_seed = int(seed_spin.value)
	spin_btn.pressed.connect(_on_spin_pressed)
	bet_minus_btn.pressed.connect(_on_bet_minus_pressed)
	bet_plus_btn.pressed.connect(_on_bet_plus_pressed)
	combat.spin_started.connect(_on_spin_started)
	combat.readouts_progressed.connect(_refresh_readouts)
	combat.spin_finished.connect(_on_spin_finished)
	combat.premium_meter_changed.connect(_on_premium_meter_changed)
	combat.meter_full_transition_started.connect(_on_meter_full_transition_started)
	choose_love_button.pressed.connect(_on_choose_love_pressed)
	choose_star_button.pressed.connect(_on_choose_star_pressed)
	choose_storm_button.pressed.connect(_on_choose_storm_pressed)
	resized.connect(_on_size_changed)
	combat.setup_new_grid(int(seed_spin.value))
	# #region agent log
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
	# #endregion
	seed_spin.value_changed.connect(_on_seed_spin_value_changed)
	_set_default_bet()
	_build_item_picker()
	_layout_combat()
	_refresh_readouts()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()
	_refresh_spin_button_state()


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
	bet_label.text = "STAKE  %.2f" % combat.get_current_bet()
	mult_label.text = "AMPLIFIER  %dX" % combat.get_multiplier_value()
	var meter_sections := combat.get_meter_sections_filled()
	if _last_meter_sections < 0:
		meter_circle.call("set_sections", meter_sections)
	elif meter_sections < _last_meter_sections:
		meter_circle.call("set_sections", meter_sections)
	elif meter_sections > _last_meter_sections and not meter_circle.has_method("animate_to_sections"):
		# Fallback path when meter widget does not expose tweened section animation.
		meter_circle.call("set_sections", meter_sections)
	_last_meter_sections = meter_sections
	goal_label.text = _goal_progress_only(combat.get_goal_label())
	budget_label.text = "SPIN LOG  %d" % combat.get_lifetime_spins_used()
	bankroll_label.text = "BANKROLL  %.2f" % combat.get_bankroll()
	_refresh_encounter_win_overlay()
	_refresh_super_fs_choice_overlay()


func _on_spin_started(seed_value: int) -> void:
	_queued_seed = seed_value
	_set_seed_spin_value_no_signal(seed_value)


func _on_spin_finished() -> void:
	# Defensive unlock: if combat spin lifecycle reports completion, keep button recoverable.
	if combat.get_state() == CombatRoot.State.IDLE or combat.is_encounter_complete():
		spin_btn.disabled = false
	_refresh_spin_button_state()


func _on_meter_full_transition_started() -> void:
	if meter_circle != null and meter_circle.has_method("play_full_flash"):
		meter_circle.call("play_full_flash")


func _on_premium_meter_changed(previous_sections: int, next_sections: int) -> void:
	if meter_circle == null:
		return
	if meter_circle.has_method("animate_to_sections"):
		meter_circle.call("animate_to_sections", previous_sections, next_sections)
	else:
		meter_circle.call("set_sections", next_sections)
	_last_meter_sections = next_sections


func _on_seed_spin_value_changed(value: float) -> void:
	if not _can_queue_seed_change():
		return
	_queued_seed = int(value)
	# #region agent log
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
	# #endregion
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
	var default_index := ladder.find(1.0)
	if default_index == -1:
		default_index = 0
	combat.set_bet_index(default_index)


func _on_size_changed() -> void:
	_layout_combat()


func _layout_combat() -> void:
	combat.fit_to_viewport(size)


func _refresh_spin_button_state() -> void:
	if spin_btn.disabled:
		spin_btn.text = "SPIN LOCKED"
	elif combat.is_encounter_complete():
		spin_btn.text = "EXECUTE"
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
	_item_picker_panel = PanelContainer.new()
	_item_picker_panel.name = "ItemPickerPanel"

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.0, 0.92)
	style.border_color = Color(0.78, 0.03, 0.03, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	_item_picker_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	_item_picker_title = Label.new()
	_item_picker_title.text = "ITEMS (0/%d)" % combat.inventory.get_current_max_slots()
	_item_picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_picker_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_item_picker_title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 120)

	var items_vbox := VBoxContainer.new()
	items_vbox.add_theme_constant_override("separation", 2)
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var available := _discover_available_items()
	for item in available:
		var cb := CheckBox.new()
		var rarity_idx: int = clampi(int(item.get("rarity")), 0, RARITY_GLYPHS.size() - 1)
		cb.text = "%s %s" % [RARITY_GLYPHS[rarity_idx], item.display_name]
		cb.tooltip_text = "%s | %s" % [RARITY_NAMES[rarity_idx], item.description]
		cb.add_theme_font_size_override("font_size", 13)
		cb.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
		cb.toggled.connect(_on_item_checkbox_toggled.bind(item, cb))
		items_vbox.add_child(cb)
		_item_entries.append({"checkbox": cb, "item": item})

	if available.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items available"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3, 0.8))
		items_vbox.add_child(empty_label)

	scroll.add_child(items_vbox)
	vbox.add_child(scroll)
	_item_picker_panel.add_child(vbox)

	add_child(_item_picker_panel)
	_item_picker_panel.anchor_left = 0.0
	_item_picker_panel.anchor_top = 0.0
	_item_picker_panel.anchor_right = 0.0
	_item_picker_panel.anchor_bottom = 1.0
	_item_picker_panel.offset_left = 12.0
	_item_picker_panel.offset_top = 60.0
	_item_picker_panel.offset_right = 260.0
	_item_picker_panel.offset_bottom = -110.0


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
