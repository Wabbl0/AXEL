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
var _time := 0.0


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self)
	var chrome := MenuLook.make_chrome_layer(self)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	chrome.add_child(host)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -400
	col.offset_right = 400
	col.offset_top = -280
	col.offset_bottom = 280
	col.add_theme_constant_override("separation", 8)
	host.add_child(col)
	for line in LINES:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var color := MenuLook.ACCENT if line == "AXEL" else MenuLook.TEXT
		var size := 64 if line == "AXEL" else 28
		MenuLook.apply_label(label, MenuLook.scaled_font(self, size), color)
		col.add_child(label)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, MenuLook.scaled_font(self, 32))
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
