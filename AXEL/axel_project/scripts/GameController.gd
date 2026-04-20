extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var key_area: Area2D = %KeyArea
@onready var exit_area: Area2D = %ExitArea
@onready var memory_pickup_area: Area2D = %MemoryPickupArea
@onready var hud: CanvasLayer = $HUD
@onready var timer_label: Label = %TimerLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var memory_label: Label = %MemoryLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var dialogue_text_label: Label = %DialogueTextLabel
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var inventory_items_label: Label = %InventoryItemsLabel

var has_key: bool = false
var game_over: bool = false
var win_state: bool = false
var time_left: float = 45.0
var memory_points: int = 0
var can_interact_with_key: bool = false
var can_interact_with_exit: bool = false
var can_interact_with_memory_pickup: bool = false
var has_memory_token: bool = false

var inventory_items: Array[Dictionary] = []

var dialogue_lines: Array[String] = []
var dialogue_line_index: int = 0
var dialogue_is_open: bool = false
var dialogue_is_typing: bool = false
var dialogue_char_progress: float = 0.0
var dialogue_chars_per_second: float = 45.0
var dialogue_current_full_text: String = ""

var _open_panel_key: String = "none"

func _ready() -> void:
	hud.visible = true
	key_area.body_entered.connect(_on_key_area_body_entered)
	key_area.body_exited.connect(_on_key_area_body_exited)
	exit_area.body_entered.connect(_on_exit_area_body_entered)
	exit_area.body_exited.connect(_on_exit_area_body_exited)
	memory_pickup_area.body_entered.connect(_on_memory_pickup_area_body_entered)
	memory_pickup_area.body_exited.connect(_on_memory_pickup_area_body_exited)
	_show_only_panel("none")
	_start_intro_dialogue()
	_refresh_inventory_label()
	_update_hud()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		_restart_level()

	if Input.is_key_pressed(KEY_I):
		_toggle_inventory()

	if dialogue_is_open:
		_handle_dialogue_input(delta)
		_update_hud()
		return

	if game_over:
		return

	time_left = max(time_left - delta, 0.0)
	if time_left == 0.0:
		_end_game(false, "Time ran out. Press R to restart.")
		return

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
		_try_interact()

	_update_hud()

func _start_intro_dialogue() -> void:
	dialogue_lines = [
		"You only remember pieces of how you got here.",
		"Search the room, collect what matters, and escape before time runs out."
	]
	dialogue_line_index = 0
	_open_dialogue()

func _open_dialogue() -> void:
	dialogue_is_open = true
	player.set_physics_process(false)
	_show_only_panel("dialogue")
	_set_dialogue_line(dialogue_lines[dialogue_line_index])

func _set_dialogue_line(text: String) -> void:
	dialogue_current_full_text = text
	dialogue_char_progress = 0.0
	dialogue_is_typing = true
	dialogue_text_label.text = ""

func _handle_dialogue_input(delta: float) -> void:
	if dialogue_is_typing:
		dialogue_char_progress += dialogue_chars_per_second * delta
		var visible_chars := mini(int(floor(dialogue_char_progress)), dialogue_current_full_text.length())
		dialogue_text_label.text = dialogue_current_full_text.substr(0, visible_chars)
		if visible_chars >= dialogue_current_full_text.length():
			dialogue_is_typing = false

	if Input.is_key_pressed(KEY_TAB) and dialogue_is_typing:
		dialogue_char_progress = float(dialogue_current_full_text.length())
		dialogue_text_label.text = dialogue_current_full_text
		dialogue_is_typing = false

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
		if dialogue_is_typing:
			dialogue_char_progress = float(dialogue_current_full_text.length())
			dialogue_text_label.text = dialogue_current_full_text
			dialogue_is_typing = false
		else:
			dialogue_line_index += 1
			if dialogue_line_index >= dialogue_lines.size():
				_close_dialogue()
			else:
				_set_dialogue_line(dialogue_lines[dialogue_line_index])

func _close_dialogue() -> void:
	dialogue_is_open = false
	_show_only_panel("none")
	if not game_over:
		player.set_physics_process(true)

func _toggle_inventory() -> void:
	if dialogue_is_open or game_over:
		return
	if _is_panel_open("inventory"):
		_show_only_panel("none")
		player.set_physics_process(true)
	else:
		_show_only_panel("inventory")
		player.set_physics_process(false)
	_refresh_inventory_label()

func _try_interact() -> void:
	if can_interact_with_key and not has_key:
		has_key = true
		_add_memory(2)
		_add_inventory_item({
			"id": "teacher_key",
			"name": "Teacher Key",
			"description": "A heavy key that fits the exit door.",
			"icon": "key_placeholder"
		})
		key_area.queue_free()
		_update_hud()
		return

	if can_interact_with_memory_pickup and not has_memory_token:
		has_memory_token = true
		_add_memory(3)
		_add_inventory_item({
			"id": "memory_token",
			"name": "Memory Token",
			"description": "A chipped token that sharpens your memory.",
			"icon": "token_placeholder"
		})
		memory_pickup_area.queue_free()
		_update_hud()
		return

	if can_interact_with_exit:
		if has_key:
			_add_memory(5)
			_end_game(true, "You escaped with the key. Press R to play again.")
		else:
			_end_game(false, "The door is locked. Find the key first. Press R to restart.")

func _end_game(did_win: bool, text: String) -> void:
	game_over = true
	win_state = did_win
	player.set_physics_process(false)
	_show_only_panel("message")
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
	memory_label.text = "MEMORY: %d" % memory_points
	if has_key:
		objective_label.text = "Objective: Reach the exit door."
	else:
		objective_label.text = "Objective: Find the key."

	if game_over or dialogue_is_open:
		return

	if _is_panel_open("inventory"):
		objective_label.text = "Objective: Review your items and close inventory."
		return

	if can_interact_with_key and not has_key:
		objective_label.text = "Objective: Press Enter/Space to pick up the key."
	elif can_interact_with_memory_pickup and not has_memory_token:
		objective_label.text = "Objective: Press Enter/Space to collect memory token."
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

func _on_memory_pickup_area_body_entered(body: Node) -> void:
	if body == player:
		can_interact_with_memory_pickup = true

func _on_memory_pickup_area_body_exited(body: Node) -> void:
	if body == player:
		can_interact_with_memory_pickup = false

func _add_memory(amount: int) -> void:
	memory_points += max(0, amount)
	_update_hud()

func _add_inventory_item(item: Dictionary) -> void:
	inventory_items.append(item)
	_refresh_inventory_label()

func _refresh_inventory_label() -> void:
	if inventory_items.is_empty():
		inventory_items_label.text = "No items collected yet."
		return

	var lines: Array[String] = []
	for item in inventory_items:
		var item_name := str(item.get("name", "Unknown item"))
		var item_description := str(item.get("description", "No description."))
		lines.append("- %s: %s" % [item_name, item_description])
	inventory_items_label.text = "\n".join(lines)

func _show_only_panel(panel_key: String) -> void:
	_open_panel_key = panel_key
	dialogue_panel.visible = panel_key == "dialogue"
	inventory_panel.visible = panel_key == "inventory"
	message_panel.visible = panel_key == "message"

func _is_panel_open(panel_key: String) -> bool:
	return _open_panel_key == panel_key
