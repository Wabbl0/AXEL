extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _door_interact_area: Area2D = get_node("1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea")

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"

var _is_transitioning := false


func _ready() -> void:
	set_process_unhandled_input(true)
	if _should_skip_intro():
		return
	_run_intro_dialogue()


func _should_skip_intro() -> bool:
	return OS.has_environment("AXEL_SKIP_INTRO") and OS.get_environment("AXEL_SKIP_INTRO") == "1"


func _run_intro_dialogue() -> void:
	await _top_dialogue.show_line("You promised, you'd never come back.", 2.0)
	await get_tree().create_timer(0.8).timeout
	await _top_dialogue.show_line("Yet, here we are...", 2.5)
	await get_tree().create_timer(0.55).timeout
	await _top_dialogue.show_line("Pathetic.", 1.6)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if not _is_player_near_door():
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(_NEXT_SCENE_PATH)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [_NEXT_SCENE_PATH, err])
		_is_transitioning = false


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _is_player_near_door() -> bool:
	if not is_instance_valid(_door_interact_area) or not is_instance_valid(_player):
		return false
	for body in _door_interact_area.get_overlapping_bodies():
		if body == _player:
			return true
	return false
