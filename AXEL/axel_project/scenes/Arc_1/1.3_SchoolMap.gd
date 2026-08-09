extends Control

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"

const DESTINATIONS: Array[Dictionary] = [
	{"label": "Go to the cafeteria", "path": "res://scenes/Arc_2/2.1_Cafeteria.tscn"},
	{"label": "Go to the classroom", "path": "res://scenes/Arc_5/5.1_Classroom.tscn"},
	{"label": "Go to the backyard", "path": "res://scenes/Arc_3/3.1_Backyard.tscn"},
	{"label": "Go to the teacher's lounge", "path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn"},
]

@onready var _choices_panel: VBoxContainer = $UiLayer/ChoicesPanel
@onready var _exit_button: Button = $UiLayer/ExitButton

var _is_transitioning := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_build_destination_buttons()


func _build_destination_buttons() -> void:
	for child in _choices_panel.get_children():
		child.queue_free()
	for destination in DESTINATIONS:
		var button := Button.new()
		button.text = destination["label"]
		button.custom_minimum_size = Vector2(320.0, 42.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var scene_path: String = destination["path"]
		if ResourceLoader.exists(scene_path):
			button.pressed.connect(func() -> void:
				_go_to_scene(scene_path)
			)
		else:
			button.disabled = true
			button.modulate = Color(0.45, 0.45, 0.45, 1.0)
		_choices_panel.add_child(button)

	var basement := Button.new()
	basement.text = "ENTER THE BASEMENT"
	basement.custom_minimum_size = Vector2(320.0, 42.0)
	basement.alignment = HORIZONTAL_ALIGNMENT_LEFT
	basement.disabled = true
	basement.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	basement.add_theme_color_override("font_disabled_color", Color(1, 0, 0, 1))
	_choices_panel.add_child(basement)


func _on_exit_pressed() -> void:
	_go_to_scene(LOCKER_HUB_SCENE)


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
