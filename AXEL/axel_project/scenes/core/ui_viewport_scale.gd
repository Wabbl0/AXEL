class_name UiViewportScale

const DESIGN_VIEWPORT_H := 1280.0
const MIN_SCALE := 0.5
const MAX_SCALE := 2.5

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


static func settings_ui_scale(node: Node) -> float:
	var settings := node.get_node_or_null("/root/AxelSettings")
	if settings == null:
		return 1.0
	return clampf(float(settings.call("ui_scale")), 0.5, 2.0)


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
