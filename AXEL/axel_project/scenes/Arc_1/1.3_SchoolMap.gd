extends Control

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"

const DESTINATIONS: Array[Dictionary] = [
	{"label": "Go to the cafeteria", "path": "res://scenes/Arc_2/2.1_Cafeteria.tscn"},
	{"label": "Go to the classroom", "path": "res://scenes/Arc_5/5.1_Classroom.tscn"},
	{"label": "Go to the backyard", "path": "res://scenes/Arc_3/3.1_Backyard.tscn"},
	{"label": "Go to the teacher's lounge", "path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn"},
]

const _UI_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
## Authored (1920x1280) chrome sizes; _apply_chrome_scale multiplies by the
## live UiViewportScale factor so 4K does not shrink the travel list.
const _BUTTON_MIN_SIZE := Vector2(320.0, 42.0)
const _BUTTON_FONT_BASE := 22
const _PANEL_OFFSETS_BASE := Vector4(24.0, -320.0, 360.0, -24.0)
const _PANEL_SEPARATION_BASE := 10.0

@onready var _choices_panel: VBoxContainer = $UiLayer/ChoicesPanel
@onready var _exit_button: Button = $UiLayer/ExitButton

var _is_transitioning := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	set_process_input(true)
	_build_destination_buttons()
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)


func _build_destination_buttons() -> void:
	for child in _choices_panel.get_children():
		child.queue_free()
	for destination in DESTINATIONS:
		var button := Button.new()
		button.text = destination["label"]
		button.custom_minimum_size = _BUTTON_MIN_SIZE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", _UI_FONT)
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
	basement.custom_minimum_size = _BUTTON_MIN_SIZE
	basement.alignment = HORIZONTAL_ALIGNMENT_LEFT
	basement.add_theme_font_override("font", _UI_FONT)
	basement.disabled = true
	basement.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	basement.add_theme_color_override("font_disabled_color", Color(1, 0, 0, 1))
	_choices_panel.add_child(basement)


func _apply_chrome_scale() -> void:
	var f := UiViewportScale.factor(self)
	UiViewportScale.apply_exit_button(_exit_button, f)
	_choices_panel.offset_left = _PANEL_OFFSETS_BASE.x * f
	_choices_panel.offset_top = _PANEL_OFFSETS_BASE.y * f
	_choices_panel.offset_right = _PANEL_OFFSETS_BASE.z * f
	_choices_panel.offset_bottom = _PANEL_OFFSETS_BASE.w * f
	_choices_panel.add_theme_constant_override("separation", roundi(_PANEL_SEPARATION_BASE * f))
	for child in _choices_panel.get_children():
		var button := child as Button
		if button == null:
			continue
		button.custom_minimum_size = _BUTTON_MIN_SIZE * f
		button.add_theme_font_size_override("font_size", roundi(_BUTTON_FONT_BASE * f))


func _input(event: InputEvent) -> void:
	if not _is_exit_key(event):
		return
	get_viewport().set_input_as_handled()
	_on_exit_pressed()


func _is_exit_key(event: InputEvent) -> bool:
	# Named InputMap action (Esc/Backspace/Delete + gamepad B). Excludes echo presses.
	return event.is_action_pressed("back")


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
