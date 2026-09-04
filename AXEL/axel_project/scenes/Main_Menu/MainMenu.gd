extends Control

@onready var _continue_button: Button = %ContinueButton
@onready var _new_button: Button = %NewGameButton
@onready var _load_button: Button = %LoadGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton

var _backdrop: TextureRect
var _time := 0.0


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self)
	var chrome := MenuLook.make_chrome_layer(self)
	$CenterBox.reparent(chrome)
	_style_buttons()
	_refresh_continue()
	_continue_button.pressed.connect(_on_continue)
	_new_button.pressed.connect(func() -> void:
		SavesScreen.open_mode = "new"
		MenuLook.go(get_tree(), MenuLook.SAVES_SCENE)
	)
	_load_button.pressed.connect(func() -> void:
		SavesScreen.open_mode = "load"
		MenuLook.go(get_tree(), MenuLook.SAVES_SCENE)
	)
	_options_button.pressed.connect(func() -> void:
		MenuLook.go(get_tree(), MenuLook.OPTIONS_SCENE)
	)
	_credits_button.pressed.connect(func() -> void:
		MenuLook.go(get_tree(), MenuLook.CREDITS_SCENE)
	)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	get_viewport().size_changed.connect(_style_buttons)
	if AxelSaves.has_living_slot():
		_continue_button.grab_focus()
	else:
		_new_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	MenuLook.drift_backdrop(_backdrop, _time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_tree().quit()
		get_viewport().set_input_as_handled()


func _on_continue() -> void:
	if not AxelSaves.continue_last():
		_refresh_continue()


func _refresh_continue() -> void:
	var living := AxelSaves.has_living_slot()
	_continue_button.disabled = not living
	_load_button.disabled = not living


func _style_buttons() -> void:
	var title := find_child("TitleLabel", true, false) as Label
	if title != null:
		MenuLook.apply_label(title, MenuLook.scaled_font(self, 96), MenuLook.ACCENT)
	for button in [_continue_button, _new_button, _load_button, _options_button, _credits_button, _quit_button]:
		MenuLook.apply_button(button, MenuLook.scaled_font(self, 36))
	MenuLook.apply_button(_quit_button, MenuLook.scaled_font(self, 28))
	_quit_button.add_theme_color_override("font_color", MenuLook.DIM)
