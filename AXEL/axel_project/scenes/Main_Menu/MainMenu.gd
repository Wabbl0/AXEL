extends Control

@onready var _continue_button: Button = %ContinueButton
@onready var _new_button: Button = %NewGameButton
@onready var _load_button: Button = %LoadGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton

var _backdrop: TextureRect
var _box: VBoxContainer
var _time := 0.0
var _overwrite_box: VBoxContainer
var _overwrite_label: Label


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self, true)
	var chrome := MenuLook.make_chrome_layer(self)
	_box = $CenterBox as VBoxContainer
	_box.reparent(chrome)
	_style_buttons()
	_refresh_continue()
	_continue_button.pressed.connect(_on_continue)
	_new_button.pressed.connect(_on_new_game)
	_build_overwrite_prompt(chrome)
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
	_quit_button.visible = not OS.has_feature("web")
	get_viewport().size_changed.connect(_style_buttons)
	_focus_start.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	MenuLook.drift_backdrop(_backdrop, _time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		if _overwrite_box != null and _overwrite_box.visible:
			_hide_overwrite()
			return
		if OS.has_feature("web"):
			return
		get_tree().quit()


func _on_continue() -> void:
	if not AxelSaves.continue_last():
		_refresh_continue()


func _on_new_game() -> void:
	_hide_overwrite()
	var free := AxelSaves.first_free_slot()
	if free >= 0:
		if not await AxelSaves.begin_new_game_and_enter(free):
			if is_inside_tree():
				_refresh_continue()
		return
	_show_overwrite()


func _build_overwrite_prompt(chrome: CanvasLayer) -> void:
	_overwrite_box = VBoxContainer.new()
	_overwrite_box.name = "OverwriteOldestBox"
	_overwrite_box.visible = false
	_overwrite_box.set_anchors_preset(Control.PRESET_CENTER)
	_overwrite_box.offset_left = -320
	_overwrite_box.offset_right = 320
	_overwrite_box.offset_top = 220
	_overwrite_box.offset_bottom = 360
	_overwrite_box.add_theme_constant_override("separation", 8)
	chrome.add_child(_overwrite_box)
	_overwrite_label = Label.new()
	_overwrite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overwrite_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overwrite_label.custom_maximum_size = Vector2(640, -1)
	MenuLook.apply_label(_overwrite_label, MenuLook.scaled_font(self, 28), MenuLook.TEXT)
	_overwrite_label.text = "Overwrite oldest save file?"
	_overwrite_box.add_child(_overwrite_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	_overwrite_box.add_child(row)
	var yes := Button.new()
	yes.text = "Yes"
	MenuLook.apply_button(yes, MenuLook.scaled_font(self, 32))
	yes.pressed.connect(_confirm_overwrite_oldest)
	row.add_child(yes)
	var no := Button.new()
	no.text = "No"
	MenuLook.apply_button(no, MenuLook.scaled_font(self, 32))
	no.pressed.connect(_hide_overwrite)
	row.add_child(no)


func _show_overwrite() -> void:
	if _overwrite_box == null:
		return
	_overwrite_box.visible = true
	MenuLook.grab_first_focus(_overwrite_box)


func _hide_overwrite() -> void:
	if _overwrite_box != null:
		_overwrite_box.visible = false
	_focus_start()


func _confirm_overwrite_oldest() -> void:
	var oldest := AxelSaves.oldest_living_slot()
	_hide_overwrite()
	if oldest < 0:
		_on_new_game()
		return
	if not await AxelSaves.begin_new_game_and_enter(oldest):
		if is_inside_tree():
			_refresh_continue()


func _refresh_continue() -> void:
	MenuLook.set_button_disabled(_continue_button, not AxelSaves.has_living_slot())
	MenuLook.set_button_disabled(_load_button, not AxelSaves.has_any_slot())


func _focus_start() -> void:
	if AxelSaves.has_living_slot():
		MenuLook.grab_silent(_continue_button)
	elif AxelSaves.has_any_slot():
		MenuLook.grab_silent(_load_button)
	else:
		MenuLook.grab_silent(_new_button)


func _style_buttons() -> void:
	var title := _box.get_node_or_null("TitleLabel") as Label if _box != null else null
	if title != null:
		MenuLook.apply_label(title, PortraitUi.font(self, 96, 3.2), MenuLook.ACCENT)
	for button in [_continue_button, _new_button, _load_button, _options_button, _credits_button, _quit_button]:
		MenuLook.apply_button(button, PortraitUi.font(self, 36, 2.4))
	_layout_box()
	_layout_overwrite()


func _layout_box() -> void:
	if _box == null:
		return
	if not PortraitUi.is_portrait(self):
		_box.set_anchors_preset(Control.PRESET_CENTER)
		_box.offset_left = -280
		_box.offset_top = -280
		_box.offset_right = 280
		_box.offset_bottom = 280
		_box.add_theme_constant_override("separation", 12)
		return
	var safe := PortraitUi.safe_rect(self)
	var rect := Rect2(
		safe.position.x + safe.size.x * 0.05,
		safe.position.y + safe.size.y * 0.12,
		safe.size.x * 0.9,
		safe.size.y * 0.78
	)
	_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_box.offset_left = rect.position.x
	_box.offset_top = rect.position.y
	_box.offset_right = rect.end.x
	_box.offset_bottom = rect.end.y
	var used := 0.0
	var shown := 0
	for child in _box.get_children():
		var c := child as Control
		if c == null or not c.visible:
			continue
		used += c.get_combined_minimum_size().y
		shown += 1
	var gap := 12.0
	if shown > 1:
		gap = maxf((rect.size.y - used) / float(shown - 1), 12.0)
	_box.add_theme_constant_override("separation", roundi(gap))


func _layout_overwrite() -> void:
	if _overwrite_box == null:
		return
	var portrait := PortraitUi.is_portrait(self)
	var half := PortraitUi.view_size(self).x * 0.45 if portrait else 320.0
	_overwrite_box.offset_left = -half
	_overwrite_box.offset_right = half
	_overwrite_label.custom_maximum_size = Vector2(half * 2.0, -1)
	MenuLook.apply_label(_overwrite_label, PortraitUi.font(self, 28, 2.0), MenuLook.TEXT)
	for row in _overwrite_box.get_children():
		if row is HBoxContainer:
			for b in row.get_children():
				if b is Button:
					MenuLook.apply_button(b, PortraitUi.font(self, 32, 2.2))
