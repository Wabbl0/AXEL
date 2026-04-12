extends Control

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_continue_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Continue"
	dialog.dialog_text = "Continue/save support is not implemented yet."
	add_child(dialog)
	dialog.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
