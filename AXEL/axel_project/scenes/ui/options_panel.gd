class_name OptionsPanel
extends Control

signal closed

const _WINDOW_MODES: PackedStringArray = ["windowed", "borderless", "fullscreen"]
const _QUALITY: PackedStringArray = ["low", "medium", "high"]
const _COMBAT_SPEEDS: PackedStringArray = ["slow", "normal", "fast"]
const _SIZE_CANDIDATES: PackedStringArray = [
	"1280x720", "1366x768", "1600x900", "1920x1080",
	"1920x1200", "1920x1280", "2560x1440", "3840x2160",
]
const _BAR_SCREEN_FRACTION := 1.0 / 6.0
const _CAPTION_WIDTH := 376
const _ROW_GAP := 6
const _SettingsScript := preload("res://scripts/autoload/axel_settings.gd")

var _sliders: Array[HSlider] = []
var _size_option: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_viewport().size_changed.connect(_apply_scale)
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _build() -> void:
	_sliders.clear()
	for child in get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.focus_mode = Control.FOCUS_NONE
	scroll.follow_focus = true
	MenuLook.apply_scroll(scroll)
	add_child(scroll)

	var center := CenterContainer.new()
	center.name = "OptionsCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var col := VBoxContainer.new()
	col.name = "OptionsColumn"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	center.add_child(col)

	var title := Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 64, MenuLook.ACCENT)
	_center(title)
	col.add_child(title)

	_section(col, "AUDIO")
	_slider(col, "Master", "audio", "master_volume")
	_slider(col, "Music", "audio", "music_volume")
	_slider(col, "Effects", "audio", "effects_volume")

	_section(col, "VIDEO")
	_option(col, "Window mode", "video", "window_mode", _WINDOW_MODES)
	_size_option = _size_dropdown(col)
	_toggle(col, "VSync", "video", "vsync")
	_option(col, "Graphics quality", "video", "graphics_quality", _QUALITY)

	_section(col, "GAMEPLAY")
	_option(col, "Combat speed", "gameplay", "combat_speed", _COMBAT_SPEEDS)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, 43)
	_center(back)
	back.pressed.connect(func() -> void: closed.emit())
	col.add_child(back)
	_apply_scale()
	MenuLook.grab_first_focus(self)


func _section(col: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	MenuLook.apply_label(label, 37, MenuLook.ACCENT)
	col.add_child(label)


func _caption(text: String) -> Label:
	var caption_label := Label.new()
	caption_label.text = text
	caption_label.custom_minimum_size.x = _CAPTION_WIDTH
	caption_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	MenuLook.apply_label(caption_label, 32)
	return caption_label


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _ROW_GAP)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


func _slider(col: VBoxContainer, caption: String, section: String, key: String, lo := 0.0, hi := 1.0) -> void:
	var row := _row()
	var caption_label := _caption(caption)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = 0.01 if hi <= 2.0 else 1.0
	_pin_slider(slider)
	slider.value = float(AxelSettings.get_value(section, key))
	slider.value_changed.connect(func(v: float) -> void:
		AxelSettings.set_value(section, key, v)
	)
	MenuLook.apply_slider(slider)
	row.add_child(caption_label)
	row.add_child(slider)
	col.add_child(row)


func _toggle(col: VBoxContainer, caption: String, section: String, key: String) -> void:
	var row := _row()
	row.add_child(_caption(caption))
	var box := CheckBox.new()
	box.name = caption
	box.text = ""
	MenuLook.apply_check(box)
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.button_pressed = bool(AxelSettings.get_value(section, key))
	box.toggled.connect(func(on: bool) -> void:
		AxelSettings.set_value(section, key, on)
	)
	row.add_child(box)
	col.add_child(row)


func _option(col: VBoxContainer, caption: String, section: String, key: String, values: PackedStringArray) -> OptionButton:
	var row := _row()
	row.add_child(_caption(caption))
	var opt := OptionButton.new()
	MenuLook.apply_button(opt, 32, Control.SIZE_SHRINK_BEGIN)
	var current := String(AxelSettings.get_value(section, key))
	for i in values.size():
		opt.add_item(values[i], i)
		if values[i] == current:
			opt.select(i)
	opt.item_selected.connect(func(idx: int) -> void:
		AxelSettings.set_value(section, key, values[idx])
	)
	row.add_child(opt)
	col.add_child(row)
	return opt


func _size_dropdown(col: VBoxContainer) -> OptionButton:
	var allowed: PackedStringArray = []
	var screen := DisplayServer.screen_get_size()
	for raw in _SIZE_CANDIDATES:
		var parsed := _SettingsScript.parse_size_string(raw)
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


func _pin_slider(slider: HSlider) -> void:
	slider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sliders.append(slider)


func _center(node: Control) -> void:
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _apply_scale() -> void:
	var screen_w := get_viewport().get_visible_rect().size.x
	if screen_w <= 1.0:
		return
	var bar_w := screen_w * _BAR_SCREEN_FRACTION
	for slider in _sliders:
		slider.custom_minimum_size.x = bar_w
