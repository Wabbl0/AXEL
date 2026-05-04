extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")

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


func _ready() -> void:
	seed_spin.min_value = 0
	seed_spin.max_value = 12345
	seed_spin.value = _pick_start_seed()
	spin_btn.pressed.connect(_on_spin_pressed)
	bet_minus_btn.pressed.connect(_on_bet_minus_pressed)
	bet_plus_btn.pressed.connect(_on_bet_plus_pressed)
	combat.spin_started.connect(_on_spin_started)
	combat.readouts_progressed.connect(_refresh_readouts)
	combat.meter_full_transition_started.connect(_on_meter_full_transition_started)
	resized.connect(_on_size_changed)
	combat.setup_new_grid(int(seed_spin.value))
	seed_spin.value_changed.connect(_on_seed_spin_value_changed)
	_set_default_bet()
	_layout_combat()
	_refresh_readouts()
	_refresh_spin_button_state()


func _on_spin_pressed() -> void:
	if combat.is_encounter_complete():
		combat.setup_new_grid(int(seed_spin.value))
		_refresh_readouts()
		_refresh_spin_button_state()
		return
	spin_btn.disabled = true
	_refresh_spin_button_state()
	await combat.spin()
	spin_btn.disabled = false
	_refresh_readouts()
	_refresh_spin_button_state()


func _refresh_readouts() -> void:
	seed_spin.value = combat.get_current_seed()
	bet_label.text = "STAKE  %.2f" % combat.get_current_bet()
	mult_label.text = "AMPLIFIER  %dX" % combat.get_multiplier_value()
	var meter_sections := combat.get_meter_sections_filled()
	meter_circle.call("set_sections", meter_sections)
	goal_label.text = _goal_progress_only(combat.get_goal_label())
	budget_label.text = "SPIN LOG  %d" % combat.get_spins_used()
	bankroll_label.text = "BANKROLL  %.2f" % combat.get_bankroll()


func _on_spin_started(seed_value: int) -> void:
	seed_spin.value = seed_value


func _on_meter_full_transition_started() -> void:
	if meter_circle != null and meter_circle.has_method("play_full_flash"):
		meter_circle.call("play_full_flash")


func _on_seed_spin_value_changed(value: float) -> void:
	if combat.is_encounter_complete():
		return
	if combat.get_spins_used() != 0:
		return
	if combat.get_state() != CombatRoot.State.IDLE:
		return
	combat.setup_new_grid(int(value))
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
