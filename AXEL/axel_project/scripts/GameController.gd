extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var key_area: Area2D = %KeyArea
@onready var exit_area: Area2D = %ExitArea
@onready var timer_label: Label = %TimerLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel

var has_key: bool = false
var game_over: bool = false
var win_state: bool = false
var time_left: float = 45.0
var can_interact_with_key: bool = false
var can_interact_with_exit: bool = false

func _ready() -> void:
	key_area.body_entered.connect(_on_key_area_body_entered)
	key_area.body_exited.connect(_on_key_area_body_exited)
	exit_area.body_entered.connect(_on_exit_area_body_entered)
	exit_area.body_exited.connect(_on_exit_area_body_exited)
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		_restart_level()

	if game_over:
		return

	time_left = max(time_left - delta, 0.0)
	if time_left == 0.0:
		_end_game(false, "Time ran out. Press R to restart.")
		return

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
		_try_interact()

	_update_hud()

func _try_interact() -> void:
	if can_interact_with_key and not has_key:
		has_key = true
		key_area.queue_free()
		_update_hud()
		return

	if can_interact_with_exit:
		if has_key:
			_end_game(true, "You escaped with the key. Press R to play again.")
		else:
			_end_game(false, "The door is locked. Find the key first. Press R to restart.")

func _end_game(did_win: bool, text: String) -> void:
	game_over = true
	win_state = did_win
	player.set_physics_process(false)
	message_panel.visible = true
	message_label.text = text
	if did_win:
		message_panel.modulate = Color(0.2, 0.6, 0.2, 1.0)
	else:
		message_panel.modulate = Color(0.6, 0.2, 0.2, 1.0)

func _restart_level() -> void:
	get_tree().reload_current_scene()

func _update_hud() -> void:
	timer_label.text = "TIME: %d" % int(ceil(time_left))
	if has_key:
		objective_label.text = "Objective: Reach the exit door."
	else:
		objective_label.text = "Objective: Find the key."

	if game_over:
		return

	if can_interact_with_key and not has_key:
		objective_label.text = "Objective: Press Enter/Space to pick up the key."
	elif can_interact_with_exit:
		if has_key:
			objective_label.text = "Objective: Press Enter/Space to escape."
		else:
			objective_label.text = "Objective: Door locked. Find key first."

func _on_key_area_body_entered(body: Node) -> void:
	if body == player:
		can_interact_with_key = true

func _on_key_area_body_exited(body: Node) -> void:
	if body == player:
		can_interact_with_key = false

func _on_exit_area_body_entered(body: Node) -> void:
	if body == player:
		can_interact_with_exit = true

func _on_exit_area_body_exited(body: Node) -> void:
	if body == player:
		can_interact_with_exit = false
