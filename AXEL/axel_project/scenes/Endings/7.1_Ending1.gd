extends Node2D
## Ending 1 — Fear: repeat "Coward." then return to the main menu.

const MAIN_MENU_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const COWARD_LINE := "Coward."
const COWARD_COUNT := 100

@onready var _top_dialogue: Node = $TopDialogueOverlay

var _is_transitioning := false


func _ready() -> void:
	call_deferred("_play_ending")


func _play_ending() -> void:
	if not is_instance_valid(_top_dialogue):
		_go_to_main_menu()
		return
	var lines: Array = []
	lines.resize(COWARD_COUNT)
	for i in COWARD_COUNT:
		lines[i] = COWARD_LINE
	await _top_dialogue.show_lines(lines)
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [MAIN_MENU_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
