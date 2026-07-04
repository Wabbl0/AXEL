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
## So to get a visible "black panel, red border, red text" button on screen,
## we author a BRIGHT fill with BLACK border/text and let the shader invert.
## These buttons also get finger-sized hit targets for the mobile build.

const TERMINAL_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")

## Renders blood red under the noir filter.
const SRC_RED := Color(0.0, 0.0, 0.0, 1.0)
## Renders dark red under the noir filter.
const SRC_DARK_RED := Color(0.25, 0.25, 0.25, 1.0)
## Renders black under the noir filter.
const SRC_BLACK := Color(0.92, 0.92, 0.92, 1.0)


static func apply_terminal_style(button: Button, font_size: int = 28, min_height: float = 56.0) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _panel(SRC_BLACK, SRC_RED, 2))
	button.add_theme_stylebox_override("hover", _panel(SRC_BLACK, SRC_RED, 3))
	button.add_theme_stylebox_override("pressed", _panel(SRC_DARK_RED, SRC_RED, 3))
	button.add_theme_stylebox_override("focus", _panel(Color(0.0, 0.0, 0.0, 0.0), SRC_RED, 3))
	button.add_theme_stylebox_override("disabled", _panel(SRC_BLACK, SRC_DARK_RED, 2))
	button.add_theme_font_override("font", TERMINAL_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", SRC_RED)
	button.add_theme_color_override("font_hover_color", SRC_RED)
	button.add_theme_color_override("font_pressed_color", SRC_BLACK)
	button.add_theme_color_override("font_focus_color", SRC_RED)
	button.add_theme_color_override("font_disabled_color", SRC_DARK_RED)
	button.custom_minimum_size = Vector2(
		button.custom_minimum_size.x, maxf(button.custom_minimum_size.y, min_height)
	)


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
