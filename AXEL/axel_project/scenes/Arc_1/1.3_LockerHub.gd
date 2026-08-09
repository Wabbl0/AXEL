extends Control

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const MEMORY_KEY := "scene_3"

@onready var _map_hotspot = $MapHotspot
@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _exit_button: Button = $ExitLayer/ExitButton

var _is_transitioning := false
var _first_visit_dialogue_running := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_map_hotspot.activated.connect(_on_map_hotspot_activated)
	call_deferred("_play_first_visit_dialogue")


func _play_first_visit_dialogue() -> void:
	if GameManager.has_memory_scene(MEMORY_KEY):
		return
	_first_visit_dialogue_running = true
	await _top_dialogue.show_lines([
		"Oh look, a map of the school.",
		"Was your memory so bad you needed a map of the school?",
	])
	GameManager.add_memory_once(MEMORY_KEY)
	_first_visit_dialogue_running = false


func _on_map_hotspot_activated() -> void:
	if _first_visit_dialogue_running:
		return
	_go_to_scene(MAP_SCENE)


func _on_exit_pressed() -> void:
	_go_to_scene(CORRIDOR_SCENE)


func _go_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
