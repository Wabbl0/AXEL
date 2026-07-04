extends Control

const HUB_BG_PATH := "res://exports/Drawings/2.1_Locker.png"
const MAP_BG_PATH := "res://exports/Drawings/map.png"
const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MEMORY_KEY := "scene_3"

const DESTINATIONS: Array[Dictionary] = [
	{"label": "Go to the cafeteria", "path": "res://scenes/Arc_3/3.1_Cafeteria.tscn"},
	{"label": "Go to the classroom", "path": "res://scenes/Arc_6/6.1_Classroom.tscn"},
	{"label": "Go to the backyard", "path": "res://scenes/Arc_4/4.1_Backyard.tscn"},
	{"label": "Go to the teacher's lounge", "path": "res://scenes/Arc_5/5.1_TeachersLounge.tscn"},
]

@onready var _background: TextureRect = $Background
@onready var _map_hotspot = $MapHotspot
@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _location_label: Label = $Chrome/LocationLabel
@onready var _choices_panel: VBoxContainer = $Chrome/ChoicesPanel
@onready var _exit_button: Button = $ExitButton

var _hub_texture: Texture2D
var _map_texture: Texture2D
var _showing_map := false
var _is_transitioning := false
var _first_visit_dialogue_running := false


func _ready() -> void:
	_location_label.text = "YOUR LOCKER"
	AxelUiButtons.apply_terminal_style(_exit_button, 36, 72.0)
	_exit_button.custom_minimum_size.x = 72.0
	if TouchControls.is_touch_ui_enabled():
		# Keep the exit X clear of the bottom dialogue bar on touch screens.
		_exit_button.offset_top -= 170.0
		_exit_button.offset_bottom -= 170.0
	_exit_button.pressed.connect(_on_exit_pressed)
	_map_hotspot.activated.connect(_on_map_hotspot_activated)
	_load_textures()
	_build_destination_buttons()
	call_deferred("_play_first_visit_dialogue")


func _load_textures() -> void:
	if ResourceLoader.exists(HUB_BG_PATH):
		_hub_texture = load(HUB_BG_PATH)
		_background.texture = _hub_texture
	if ResourceLoader.exists(MAP_BG_PATH):
		_map_texture = load(MAP_BG_PATH)
	else:
		_map_hotspot.set_enabled(false)


func _build_destination_buttons() -> void:
	for child in _choices_panel.get_children():
		child.queue_free()
	var touch_ui := TouchControls.is_touch_ui_enabled()
	for destination in DESTINATIONS:
		var button := Button.new()
		button.text = destination["label"]
		button.custom_minimum_size = Vector2(320.0, 42.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		AxelUiButtons.apply_terminal_style(button, 34 if touch_ui else 28, 72.0 if touch_ui else 56.0)
		var scene_path: String = destination["path"]
		if ResourceLoader.exists(scene_path):
			button.pressed.connect(func() -> void:
				_go_to_scene(scene_path)
			)
		else:
			button.disabled = true
		_choices_panel.add_child(button)
	call_deferred("_fit_choices_panel")


## The authored panel rect is too small for touch-sized buttons; grow it to fit
## the content and, on touch UI, keep it clear of the bottom dialogue bar so
## destinations stay tappable while dialogue is showing.
func _fit_choices_panel() -> void:
	if not is_instance_valid(_choices_panel):
		return
	var touch_ui := TouchControls.is_touch_ui_enabled()
	var bottom_clear := 170.0 if touch_ui else 24.0
	var needed := _choices_panel.get_combined_minimum_size()
	_choices_panel.offset_bottom = -bottom_clear
	_choices_panel.offset_top = -(bottom_clear + needed.y)
	if touch_ui:
		_choices_panel.offset_right = _choices_panel.offset_left + maxf(needed.x, 480.0)


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
	if _showing_map or _map_texture == null:
		return
	_show_map_background()


func _show_map_background() -> void:
	_background.texture = _map_texture
	_showing_map = true
	_map_hotspot.set_enabled(false)


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
