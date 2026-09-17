extends CanvasLayer

signal closed

const LAYER := 200
const PANEL_BG_ALPHA := 0.8
const ROW_NAMES := ["HOME", "HELP", "SETTINGS", "DEV TOOLS"]
const ACCENT := Color(0.98, 0.35, 0.35, 1.0)
const DIM := Color(0.55, 0.55, 0.55, 1.0)
const TEXT := Color(0.92, 0.88, 0.88, 1.0)
const TERMINAL_THEME := preload("res://combat/ui/terminal_theme.tres")

var _panel: PanelContainer
var _outside: Control
var _open := false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func is_open() -> bool:
	return _open


func open_panel() -> void:
	_open = true
	visible = true
	if _outside != null:
		_outside.visible = true
		_outside.move_to_front()
	if _panel != null:
		_panel.visible = true
		_panel.move_to_front()
	_center_panel()


func close_panel() -> void:
	_open = false
	visible = false
	if _outside != null:
		_outside.visible = false
	if _panel != null:
		_panel.visible = false
	closed.emit()


func toggle_panel() -> void:
	if _open:
		close_panel()
	else:
		open_panel()


func _build() -> void:
	_outside = Control.new()
	_outside.name = "OutsideBlocker"
	_outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outside.mouse_filter = Control.MOUSE_FILTER_STOP
	_outside.gui_input.connect(_on_outside_gui_input)
	add_child(_outside)

	_panel = PanelContainer.new()
	_panel.name = "SettingsPanel"
	_panel.theme = TERMINAL_THEME
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	for row_name in ROW_NAMES:
		var btn := Button.new()
		btn.name = row_name.replace(" ", "")
		btn.text = row_name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.focus_mode = Control.FOCUS_NONE
		var is_dev: bool = row_name == "DEV TOOLS"
		if is_dev:
			if not OS.is_debug_build():
				btn.visible = false
			btn.add_theme_color_override("font_color", TEXT)
			btn.pressed.connect(_on_dev_tools_pressed)
		else:
			btn.disabled = true
			btn.add_theme_color_override("font_color", DIM)
			btn.add_theme_color_override("font_disabled_color", DIM)
		_style_row_button(btn, is_dev)
		vbox.add_child(btn)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, PANEL_BG_ALPHA)
	style.border_color = Color(0.45, 0.03, 0.03, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _style_row_button(btn: Button, enabled_look: bool) -> void:
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.98, 0.35, 0.35, 0.12 if enabled_look else 0.0)
	hover.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_font_size_override("font_size", 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _center_panel() -> void:
	if _panel == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var sz := _panel.get_combined_minimum_size()
	_panel.size = Vector2(maxf(sz.x, 280.0), sz.y)
	_panel.position = (vp - _panel.size) * 0.5


func _on_outside_gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton and event.pressed:
		close_panel()
		_outside.accept_event()


func _on_dev_tools_pressed() -> void:
	if not OS.is_debug_build():
		return
	var tools := _dev_tools()
	if tools != null and tools.has_method("open_dev_menu"):
		tools.open_dev_menu()
	close_panel()


func _dev_tools() -> Node:
	return get_node_or_null("/root/AxelCombatDevTools")


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return

	if event.is_action_pressed("back"):
		close_panel()
		get_viewport().set_input_as_handled()
