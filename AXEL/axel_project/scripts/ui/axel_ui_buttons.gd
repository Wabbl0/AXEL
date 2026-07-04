class_name AxelUiButtons
extends RefCounted
## Shared button styling for hub/menu navigation in noir-filtered scenes.
##
## Every non-combat scene is covered by NoirPaletteOverlay, whose shader maps
## source luminance INVERTED into the AXEL palette (after a 1.25x contrast
## boost around 0.5):
##   source lum < ~0.16  -> blood red
##   source lum < ~0.35  -> dark red
##   otherwise           -> black
## Buttons drawn UNDER the filter stack (filtered=true) must author a BRIGHT
## fill with BLACK border/text and let the shader invert. Buttons hoisted onto
## a CanvasLayer ABOVE the filters (filtered=false, like the dialogue bar)
## use the real red-on-black terminal palette for crisp, readable text.
## These buttons also get finger-sized hit targets for the mobile build.

const TERMINAL_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")

## Layer above the post-fx stack (noir 90 / scanline 105 / CRT 108), below
## the dialogue bar (110) and interact prompt (111).
const CHROME_LAYER := 109

## Renders blood red under the noir filter.
const SRC_RED := Color(0.0, 0.0, 0.0, 1.0)
## Renders dark red under the noir filter.
const SRC_DARK_RED := Color(0.25, 0.25, 0.25, 1.0)
## Renders black under the noir filter.
const SRC_BLACK := Color(0.92, 0.92, 0.92, 1.0)

const RED := Color(1.0, 0.22, 0.18, 1.0)
const RED_BRIGHT := Color(1.0, 0.45, 0.4, 1.0)
const RED_DIM := Color(0.5, 0.1, 0.08, 1.0)
const PANEL_BLACK := Color(0.02, 0.0, 0.0, 0.88)
const PANEL_BLACK_PRESSED := Color(0.28, 0.03, 0.03, 0.92)


static func apply_terminal_style(
	button: Button, font_size: int = 28, min_height: float = 56.0, filtered: bool = true
) -> void:
	if button == null:
		return
	if filtered:
		button.add_theme_stylebox_override("normal", _panel(SRC_BLACK, SRC_RED, 2))
		button.add_theme_stylebox_override("hover", _panel(SRC_BLACK, SRC_RED, 3))
		button.add_theme_stylebox_override("pressed", _panel(SRC_DARK_RED, SRC_RED, 3))
		button.add_theme_stylebox_override("focus", _panel(Color(0.0, 0.0, 0.0, 0.0), SRC_RED, 3))
		button.add_theme_stylebox_override("disabled", _panel(SRC_BLACK, SRC_DARK_RED, 2))
		button.add_theme_color_override("font_color", SRC_RED)
		button.add_theme_color_override("font_hover_color", SRC_RED)
		button.add_theme_color_override("font_pressed_color", SRC_BLACK)
		button.add_theme_color_override("font_focus_color", SRC_RED)
		button.add_theme_color_override("font_disabled_color", SRC_DARK_RED)
	else:
		button.add_theme_stylebox_override("normal", _panel(PANEL_BLACK, RED, 2))
		button.add_theme_stylebox_override("hover", _panel(PANEL_BLACK, RED_BRIGHT, 3))
		button.add_theme_stylebox_override("pressed", _panel(PANEL_BLACK_PRESSED, RED_BRIGHT, 3))
		button.add_theme_stylebox_override("focus", _panel(Color(0.0, 0.0, 0.0, 0.0), RED_BRIGHT, 3))
		button.add_theme_stylebox_override("disabled", _panel(PANEL_BLACK, RED_DIM, 2))
		button.add_theme_color_override("font_color", RED)
		button.add_theme_color_override("font_hover_color", RED_BRIGHT)
		button.add_theme_color_override("font_pressed_color", RED_BRIGHT)
		button.add_theme_color_override("font_focus_color", RED_BRIGHT)
		button.add_theme_color_override("font_disabled_color", RED_DIM)
	button.add_theme_font_override("font", TERMINAL_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size = Vector2(
		button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, min_height)
	)


## Reparents `node` onto a shared CanvasLayer above the noir/scanline/CRT
## post-fx stack so interactive chrome stays crisp and readable (matching how
## the dialogue bar and interact prompt already render).
static func hoist_above_post_fx(node: Node) -> void:
	if node == null or not node.is_inside_tree():
		return
	var scene_root := node.get_tree().current_scene
	if scene_root == null:
		scene_root = node.get_parent()
	var chrome := scene_root.get_node_or_null("AxelTouchChrome") as CanvasLayer
	if chrome == null:
		chrome = CanvasLayer.new()
		chrome.name = "AxelTouchChrome"
		chrome.layer = CHROME_LAYER
		scene_root.add_child(chrome)
	node.get_parent().remove_child(node)
	chrome.add_child(node)


static func _panel(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var flat := StyleBoxFlat.new()
	flat.bg_color = bg
	flat.border_color = border
	flat.set_border_width_all(border_width)
	flat.set_corner_radius_all(2)
	flat.content_margin_left = 14
	flat.content_margin_right = 14
	flat.content_margin_top = 6
	flat.content_margin_bottom = 6
	return flat
