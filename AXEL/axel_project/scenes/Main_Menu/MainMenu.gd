extends Control

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	for button in [start_button, continue_button, quit_button]:
		AxelUiButtons.apply_terminal_style(button, 30, 56.0)
	start_button.pressed.connect(_on_start_pressed)
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	var corridor_test_scene := "res://scenes/Arc_1/1.2_Corridor.tscn"
	var default_scene := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
	var target_scene := corridor_test_scene if ResourceLoader.exists(corridor_test_scene) else default_scene
	get_tree().change_scene_to_file(target_scene)

func _on_continue_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Continue"
	dialog.dialog_text = "Continue/save support is not implemented yet."
	add_child(dialog)
	dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
