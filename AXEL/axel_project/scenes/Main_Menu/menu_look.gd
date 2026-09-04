class_name MenuLook
extends RefCounted
## Shared title-screen look: drifting 1.1 drawing, VT323, red-on-black buttons.

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const BACKDROP := preload("res://exports/Drawings/1.1_SchoolExterior.png")
const ACCENT := Color(0.86, 0.08, 0.08)
const TEXT := Color(0.92, 0.88, 0.88)
const DIM := Color(0.45, 0.18, 0.18)
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const SAVES_SCENE := "res://scenes/Main_Menu/Saves.tscn"
const OPTIONS_SCENE := "res://scenes/Main_Menu/Options.tscn"
const CREDITS_SCENE := "res://scenes/Main_Menu/Credits.tscn"


static func apply_label(label: Label, size_px: int, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)


static func apply_button(button: Button, size_px: int = 36) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size_px)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_focus_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", DIM)
	button.flat = true


static func make_chrome_layer(parent: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "MenuChrome"
	layer.layer = 110
	parent.add_child(layer)
	return layer


static func make_backdrop(parent: Control) -> TextureRect:
	var bg := TextureRect.new()
	bg.name = "MenuBackdrop"
	bg.texture = BACKDROP
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate = Color(0.85, 0.85, 0.85, 1.0)
	parent.add_child(bg)
	parent.move_child(bg, 0)
	return bg


static func drift_backdrop(bg: TextureRect, time_sec: float) -> void:
	if bg == null:
		return
	var ox := sin(time_sec * 0.07) * 18.0
	var oy := cos(time_sec * 0.05) * 12.0
	bg.offset_left = ox
	bg.offset_top = oy
	bg.offset_right = ox
	bg.offset_bottom = oy


static func scaled_font(node: Node, authored: int) -> int:
	return maxi(roundi(float(authored) * UiViewportScale.factor(node)), 8)


static func go(tree: SceneTree, path: String) -> void:
	if tree.change_scene_to_file(path) != OK:
		push_error("MenuLook: could not open %s" % path)
