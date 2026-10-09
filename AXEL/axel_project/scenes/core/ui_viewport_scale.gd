class_name UiViewportScale

const DESIGN_VIEWPORT_H := 1280.0
const MIN_SCALE := 0.5
const MAX_SCALE := 2.5

const EXIT_BUTTON_FONT := 60
const EXIT_BUTTON_SIZE := 96.0
const EXIT_BUTTON_MARGIN := 24.0
const EXIT_PULSE_SEC := 1.4
const EXIT_PULSE_SCALE := 1.08
const EXIT_GLOW_MIN := 0.35
const EXIT_GLOW_MAX := 0.9
const EXIT_GLOW_STEADY := 0.6
const EXIT_GLOW_SPREAD := 2.2
const EXIT_GLOW_NAME := "ExitGlow"
const EXIT_TWEEN_META := &"exit_pulse_tween"


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


static func apply_exit_button(button: Button, f: float, pulse: bool = true) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_font_size_override("font_size", roundi(EXIT_BUTTON_FONT * f))
	var size := EXIT_BUTTON_SIZE * f
	var margin := EXIT_BUTTON_MARGIN * f
	button.offset_left = -(size + margin)
	button.offset_top = -(size + margin)
	button.offset_right = -margin
	button.offset_bottom = -margin
	button.pivot_offset = Vector2(size, size) * 0.5
	if pulse:
		_apply_exit_glow(button, size)


static func _apply_exit_glow(button: Button, size: float) -> void:
	var glow := button.get_node_or_null(EXIT_GLOW_NAME) as TextureRect
	if glow == null:
		glow = TextureRect.new()
		glow.name = EXIT_GLOW_NAME
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.show_behind_parent = true
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.texture = _glow_texture()
		button.add_child(glow)
	var glow_size := size * EXIT_GLOW_SPREAD
	glow.size = Vector2(glow_size, glow_size)
	glow.position = Vector2(size, size) * 0.5 - glow.size * 0.5
	if button.has_meta(EXIT_TWEEN_META):
		var old: Variant = button.get_meta(EXIT_TWEEN_META)
		if old is Tween and (old as Tween).is_valid():
			return
	if _reduce_flashing(button):
		button.scale = Vector2.ONE
		glow.modulate.a = EXIT_GLOW_STEADY
		return
	glow.modulate.a = EXIT_GLOW_MIN
	var half := EXIT_PULSE_SEC * 0.5
	var tween := button.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * EXIT_PULSE_SCALE, half)
	tween.parallel().tween_property(glow, "modulate:a", EXIT_GLOW_MAX, half)
	tween.tween_property(button, "scale", Vector2.ONE, half)
	tween.parallel().tween_property(glow, "modulate:a", EXIT_GLOW_MIN, half)
	button.set_meta(EXIT_TWEEN_META, tween)


static func _glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.05, 0.05, 0.75))
	gradient.set_color(1, Color(1.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.45, Color(0.85, 0.0, 0.0, 0.3))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


static func _reduce_flashing(node: Node) -> bool:
	var settings := node.get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))
