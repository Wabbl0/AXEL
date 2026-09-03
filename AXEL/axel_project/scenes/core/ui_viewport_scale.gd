class_name UiViewportScale
## Shared scaling for fixed-pixel UI chrome (corner X buttons, map travel
## buttons, the [E] chip). Same live-viewport formula as
## TopDialogueOverlay._dialogue_window_scale — window stretch stays disabled
## (D21), so chrome must rescale itself from the real window height — times the
## player's ui_scale setting (D4). Authored baseline is 1920x1280.
##
## Callers apply on _ready and again on get_viewport().size_changed, using a
## bound method (not a lambda) so the connection dies with the scene.

const DESIGN_VIEWPORT_H := 1280.0
const MIN_SCALE := 0.5
const MAX_SCALE := 2.5

## Shared corner "X" authored values: 58x58 box, 24 px corner margin, VT323 36.
const EXIT_BUTTON_FONT := 36
const EXIT_BUTTON_SIZE := 58.0
const EXIT_BUTTON_MARGIN := 24.0


static func factor(node: Node) -> float:
	var height := 0.0
	var viewport := node.get_viewport()
	if viewport != null:
		height = viewport.get_visible_rect().size.y
	if height <= 0.0:
		height = DESIGN_VIEWPORT_H
	return clampf(height / DESIGN_VIEWPORT_H, MIN_SCALE, MAX_SCALE) * settings_ui_scale(node)


## Player ui_scale from AxelSettings (1.0 when the autoload is unavailable).
static func settings_ui_scale(node: Node) -> float:
	var settings := node.get_node_or_null("/root/AxelSettings")
	if settings == null:
		return 1.0
	return clampf(float(settings.call("ui_scale")), 0.5, 2.0)


## Rescales the shared bottom-right corner X button (hub, map, memory stills).
static func apply_exit_button(button: Button, f: float) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_font_size_override("font_size", roundi(EXIT_BUTTON_FONT * f))
	var size := EXIT_BUTTON_SIZE * f
	var margin := EXIT_BUTTON_MARGIN * f
	button.offset_left = -(size + margin)
	button.offset_top = -(size + margin)
	button.offset_right = -margin
	button.offset_bottom = -margin
