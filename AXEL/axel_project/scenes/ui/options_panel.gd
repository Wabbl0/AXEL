class_name OptionsPanel
extends Control

signal closed

const _REBIND_ACTIONS: PackedStringArray = [
	"move_up", "move_down", "move_left", "move_right",
	"interact", "dialogue_advance", "back", "pause",
]
const _ACTION_LABELS := {
	"move_up": "Move up",
	"move_down": "Move down",
	"move_left": "Move left",
	"move_right": "Move right",
	"interact": "Interact",
	"dialogue_advance": "Advance dialogue",
	"back": "Back / cancel",
	"pause": "Pause",
}
const _WINDOW_MODES: PackedStringArray = ["windowed", "borderless", "fullscreen"]
const _QUALITY: PackedStringArray = ["low", "medium", "high"]
const _SIZE_CANDIDATES: PackedStringArray = [
	"1280x720", "1366x768", "1600x900", "1920x1080",
	"1920x1200", "1920x1280", "2560x1440", "3840x2160",
]

var _listening_action := ""
var _rebind_buttons: Dictionary = {}
var _size_option: OptionButton
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_viewport().size_changed.connect(_apply_scale)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _listening_action.is_empty():
		if event.is_action_pressed("back"):
			closed.emit()
			get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event is InputEventMouseMotion:
		return
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if absf(motion.axis_value) < 0.6:
			return
	if not event.is_pressed():
		return
	_finish_rebind(event)
	get_viewport().set_input_as_handled()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 48
	scroll.offset_top = 48
	scroll.offset_right = -48
	scroll.offset_bottom = -48
	add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)

	var title := Label.new()
	title.text = "OPTIONS"
	MenuLook.apply_label(title, 48, MenuLook.ACCENT)
	col.add_child(title)

	_section(col, "AUDIO")
	_slider(col, "Master", "audio", "master_volume")
	_slider(col, "Music", "audio", "music_volume")
	_slider(col, "Effects", "audio", "effects_volume")

	_section(col, "VIDEO")
	_option(col, "Window mode", "video", "window_mode", _WINDOW_MODES)
	_size_option = _size_dropdown(col)
	_toggle(col, "VSync", "video", "vsync")
	_int_slider(col, "FPS cap (0 = off)", "video", "fps_cap", 0, 240)
	_toggle(col, "CRT", "video", "crt_enabled")
	_option(col, "Graphics quality", "video", "graphics_quality", _QUALITY)
	_slider(col, "UI scale", "video", "ui_scale", 0.75, 1.5)

	_section(col, "GAMEPLAY")
	_slider(col, "Dialogue speed", "gameplay", "text_speed_cps", 12.0, 80.0)
	_toggle(col, "Auto-advance dialogue", "gameplay", "auto_advance")

	_section(col, "ACCESSIBILITY")
	_toggle(col, "Reduce flashing", "access", "reduce_flashing")
	_slider(col, "Screen shake", "access", "screen_shake")
	_slider(col, "Glitch intensity", "access", "glitch_intensity")

	_section(col, "CONTROLS")
	for action in _REBIND_ACTIONS:
		_rebind_row(col, action)

	var back := Button.new()
	back.text = "Back"
	MenuLook.apply_button(back, 32)
	back.pressed.connect(func() -> void: closed.emit())
	col.add_child(back)
	_apply_scale()


func _section(col: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	MenuLook.apply_label(label, 28, MenuLook.ACCENT)
	col.add_child(label)


func _slider(col: VBoxContainer, caption: String, section: String, key: String, lo := 0.0, hi := 1.0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name := Label.new()
	name.text = caption
	name.custom_minimum_size.x = 280
	MenuLook.apply_label(name, 24)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = 0.01 if hi <= 2.0 else 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = float(AxelSettings.get_value(section, key))
	slider.value_changed.connect(func(v: float) -> void:
		AxelSettings.set_value(section, key, v)
	)
	row.add_child(name)
	row.add_child(slider)
	col.add_child(row)


func _int_slider(col: VBoxContainer, caption: String, section: String, key: String, lo: int, hi: int) -> void:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = caption
	name.custom_minimum_size.x = 280
	MenuLook.apply_label(name, 24)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = int(AxelSettings.get_value(section, key))
	slider.value_changed.connect(func(v: float) -> void:
		AxelSettings.set_value(section, key, int(v))
	)
	row.add_child(name)
	row.add_child(slider)
	col.add_child(row)


func _toggle(col: VBoxContainer, caption: String, section: String, key: String) -> void:
	var box := CheckBox.new()
	box.text = caption
	MenuLook.apply_button(box, 24)
	box.button_pressed = bool(AxelSettings.get_value(section, key))
	box.toggled.connect(func(on: bool) -> void:
		AxelSettings.set_value(section, key, on)
	)
	col.add_child(box)


func _option(col: VBoxContainer, caption: String, section: String, key: String, values: PackedStringArray) -> OptionButton:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = caption
	name.custom_minimum_size.x = 280
	MenuLook.apply_label(name, 24)
	var opt := OptionButton.new()
	MenuLook.apply_button(opt, 24)
	var current := String(AxelSettings.get_value(section, key))
	for i in values.size():
		opt.add_item(values[i], i)
		if values[i] == current:
			opt.select(i)
	opt.item_selected.connect(func(idx: int) -> void:
		AxelSettings.set_value(section, key, values[idx])
	)
	row.add_child(name)
	row.add_child(opt)
	col.add_child(row)
	return opt


func _size_dropdown(col: VBoxContainer) -> OptionButton:
	var allowed: PackedStringArray = []
	var screen := DisplayServer.screen_get_size()
	for raw in _SIZE_CANDIDATES:
		var parsed := AxelSettings.parse_size_string(raw)
		if parsed.x <= screen.x and parsed.y <= screen.y:
			allowed.append(raw)
	if allowed.is_empty():
		allowed.append("1920x1280")
	var opt := _option(col, "Resolution", "video", "window_size", allowed)
	var current := String(AxelSettings.get_value("video", "window_size"))
	if allowed.find(current) < 0:
		opt.add_item(current, allowed.size())
		opt.select(allowed.size())
	return opt


func _rebind_row(col: VBoxContainer, action: String) -> void:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = String(_ACTION_LABELS.get(action, action))
	name.custom_minimum_size.x = 280
	MenuLook.apply_label(name, 24)
	var button := Button.new()
	button.text = _binding_label(action)
	MenuLook.apply_button(button, 24)
	button.pressed.connect(func() -> void:
		_listening_action = action
		button.text = "Press a key…"
	)
	_rebind_buttons[action] = button
	row.add_child(name)
	row.add_child(button)
	col.add_child(row)


func _finish_rebind(event: InputEvent) -> void:
	var action := _listening_action
	_listening_action = ""
	if action.is_empty():
		return
	var events: Array = [event]
	AxelSettings.store_action_binding(action, events)
	var button := _rebind_buttons.get(action) as Button
	if button != null:
		button.text = _binding_label(action)


func _binding_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "(none)"
	return events[0].as_text()


func _apply_scale() -> void:

	pass
