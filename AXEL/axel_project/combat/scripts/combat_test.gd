extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")

@onready var seed_spin: SpinBox = %SeedSpinBox
@onready var new_grid_btn: Button = %NewGridButton
@onready var spin_btn: Button = %SpinButton
@onready var mult_label: Label = %MultiplierReadout
@onready var current_princess_label: Label = %CurrentPrincessLabel
@onready var goal_label: Label = %GoalLabel
@onready var budget_label: Label = %BudgetLabel
@onready var combat: CombatRootScript = %CombatRoot


func _ready() -> void:
	seed_spin.min_value = 0
	seed_spin.max_value = 4294967295
	seed_spin.value = 12345
	new_grid_btn.pressed.connect(_on_new_grid)
	spin_btn.pressed.connect(_on_spin_pressed)
	combat.setup_new_grid(int(seed_spin.value))
	_refresh_readouts()


func _on_new_grid() -> void:
	combat.setup_new_grid(int(seed_spin.value))
	_refresh_readouts()


func _on_spin_pressed() -> void:
	spin_btn.disabled = true
	await combat.spin()
	spin_btn.disabled = false
	_refresh_readouts()


func _refresh_readouts() -> void:
	mult_label.text = "Multiplier (after last action): %d×" % combat.get_multiplier_value()
	current_princess_label.text = "Current princess: %s" % String(combat.get_princess_current_id())
	goal_label.text = "Goal: %s" % combat.get_goal_label()
	var state := "running"
	if combat.is_encounter_complete():
		state = "won" if combat.did_win_encounter() else "lost"
	budget_label.text = "Spins: %d / %d (%s)" % [combat.get_spins_used(), combat.get_spin_budget(), state]
