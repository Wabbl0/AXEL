extends Control

const CombatRootScript := preload("res://combat/scripts/combat_root.gd")

@onready var seed_spin: SpinBox = %SeedSpinBox
@onready var new_grid_btn: Button = %NewGridButton
@onready var spin_btn: Button = %SpinButton
@onready var mult_label: Label = %MultiplierReadout
@onready var combat: CombatRootScript = %CombatRoot


func _ready() -> void:
	seed_spin.min_value = 0
	seed_spin.max_value = 4294967295
	seed_spin.value = 12345
	new_grid_btn.pressed.connect(_on_new_grid)
	spin_btn.pressed.connect(_on_spin_pressed)
	combat.setup_new_grid(int(seed_spin.value))
	_refresh_multiplier_readout()


func _on_new_grid() -> void:
	combat.setup_new_grid(int(seed_spin.value))
	_refresh_multiplier_readout()


func _on_spin_pressed() -> void:
	spin_btn.disabled = true
	await combat.spin()
	spin_btn.disabled = false
	_refresh_multiplier_readout()


func _refresh_multiplier_readout() -> void:
	mult_label.text = "Multiplier (after last action): %d×" % combat.get_multiplier_value()
