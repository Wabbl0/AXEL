extends Control

const LINES: PackedStringArray = [
	"AXEL",
	"",
	"EGGK — author",
	"Music — EGGK and Tomi Räsänen",
	"Background art — Viivi Hassinen",
	"",
	"Engine — Godot (MIT)",
	"Font — VT323 by Peter Hull (SIL Open Font Licence)",
]

var _backdrop: TextureRect
var _chrome: CanvasLayer
var _time := 0.0


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self)
	_chrome = MenuLook.make_chrome_layer(self)
	_build()
	get_viewport().size_changed.connect(_build)


func _build() -> void:
	for child in _chrome.get_children():
		child.queue_free()
	var portrait := PortraitUi.is_portrait(self)
	var half_w := PortraitUi.view_size(self).x * 0.45 if portrait else 400.0
	var half_h := PortraitUi.safe_rect(self).size.y * 0.42 if portrait else 280.0
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chrome.add_child(host)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -half_w
	col.offset_right = half_w
	col.offset_top = -half_h
	col.offset_bottom = half_h
	if portrait:
		col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", roundi(8.0 * PortraitUi.boost(self, 2.0)))
	host.add_child(col)
	for line in LINES:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if portrait:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_maximum_size = Vector2(half_w * 2.0, -1.0)
		var color := MenuLook.ACCENT if line == "AXEL" else MenuLook.TEXT
		var font_px := PortraitUi.font(self, 64, 3.0) if line == "AXEL" else PortraitUi.font(self, 28, 1.7)
		MenuLook.apply_label(label, font_px, color)
		col.add_child(label)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, PortraitUi.font(self, 32, 2.2))
	back.pressed.connect(func() -> void: MenuLook.go(get_tree(), MenuLook.TITLE_SCENE))
	col.add_child(back)
	back.call_deferred("grab_focus", true)


func _process(delta: float) -> void:
	_time += delta
	MenuLook.drift_backdrop(_backdrop, _time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		MenuLook.go(get_tree(), MenuLook.TITLE_SCENE)
