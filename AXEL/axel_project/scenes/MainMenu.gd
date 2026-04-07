extends Control

func _debug_log(hypothesis_id: String, location: String, message: String, data: Dictionary = {}) -> void:
	var file := FileAccess.open("C:/Users/valtt/OneDrive/Godot/debug-7980eb.log", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("C:/Users/valtt/OneDrive/Godot/debug-7980eb.log", FileAccess.WRITE_READ)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": "7980eb",
		"runId": "run1",
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000
	}
	file.store_line(JSON.stringify(payload))
	file.close()

@onready var start_button: Button = %StartButton
@onready var nav_toggle: Button = %NavToggle
@onready var nav_links: HBoxContainer = %NavLinks
@onready var about_button: Button = %AboutButton
@onready var credits_button: Button = %CreditsButton
@onready var contact_button: Button = %ContactButton

func _ready() -> void:
	#region agent log
	_debug_log("H3", "MainMenu.gd:_ready", "MainMenu _ready entered", {
		"start_button_null": start_button == null,
		"nav_toggle_null": nav_toggle == null,
		"nav_links_null": nav_links == null
	})
	#endregion
	start_button.pressed.connect(_on_start_pressed)
	nav_toggle.pressed.connect(_on_nav_toggle_pressed)
	about_button.pressed.connect(func() -> void: _show_placeholder("About"))
	credits_button.pressed.connect(func() -> void: _show_placeholder("Credits"))
	contact_button.pressed.connect(func() -> void: _show_placeholder("Contact"))
	_update_nav_for_viewport()
	get_viewport().size_changed.connect(_update_nav_for_viewport)

func _on_start_pressed() -> void:
	#region agent log
	_debug_log("H3", "MainMenu.gd:_on_start_pressed", "Start pressed, changing scene", {
		"target_scene": "res://scenes/Game.tscn"
	})
	#endregion
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_nav_toggle_pressed() -> void:
	nav_links.visible = not nav_links.visible

func _update_nav_for_viewport() -> void:
	var mobile := get_viewport_rect().size.x <= 700.0
	nav_toggle.visible = mobile
	nav_links.visible = not mobile

func _show_placeholder(page_name: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = page_name
	dialog.dialog_text = page_name + " page is not implemented in Godot yet."
	add_child(dialog)
	dialog.popup_centered()
