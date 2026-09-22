class_name MenuLook
extends RefCounted

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const BACKDROP := preload("res://assets/ui/title_backdrop.png")
const ACCENT := Color(0.86, 0.08, 0.08)
const TEXT := Color(0.92, 0.88, 0.88)
const DIM := Color(0.45, 0.18, 0.18)
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const SAVES_SCENE := "res://scenes/Main_Menu/Saves.tscn"
const OPTIONS_SCENE := "res://scenes/Main_Menu/Options.tscn"
const CREDITS_SCENE := "res://scenes/Main_Menu/Credits.tscn"
const BACKDROP_LAYER := 100
const BACKDROP_ZOOM_OUT := 1.33
const _FOCUS_PAD_X := 16.0
const _FOCUS_PAD_Y := 10.0
const _FOCUS_BORDER := 4


static func apply_label(label: Label, size_px: int, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)


static func apply_button(button: Button, size_px: int = 36, h_flags: int = Control.SIZE_SHRINK_CENTER) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size_px)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_focus_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", DIM)
	button.flat = true
	button.clip_text = false
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.size_flags_horizontal = h_flags
	var pad := _button_pad_style()
	button.add_theme_stylebox_override("normal", pad)
	button.add_theme_stylebox_override("hover", pad)
	button.add_theme_stylebox_override("pressed", pad)
	button.add_theme_stylebox_override("hover_pressed", pad)
	button.add_theme_stylebox_override("disabled", pad)
	button.add_theme_stylebox_override("focus", _button_focus_style())


static func apply_slider(slider: HSlider) -> void:
	slider.add_theme_font_override("font", FONT)
	slider.add_theme_stylebox_override("slider", _slider_track())
	slider.add_theme_stylebox_override("grabber_area", _slider_fill())
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_fill())
	var grab := _pixel_texture(ACCENT, 14, 22)
	slider.add_theme_icon_override("grabber", grab)
	slider.add_theme_icon_override("grabber_highlight", grab)
	slider.add_theme_icon_override("grabber_disabled", _pixel_texture(DIM, 14, 22))
	slider.custom_minimum_size.y = 28


static func apply_scroll(scroll: ScrollContainer) -> void:
	var theme := Theme.new()
	theme.default_font = FONT
	var track := _scroll_track()
	var grab := _scroll_grab()
	var blank := _pixel_texture(Color(0, 0, 0, 0), 8, 8)
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, track)
		theme.set_stylebox("scroll_focus", bar, track)
		theme.set_stylebox("grabber", bar, grab)
		theme.set_stylebox("grabber_highlight", bar, grab)
		theme.set_stylebox("grabber_pressed", bar, grab)
		for icon_name in [
			"increment", "increment_highlight", "increment_pressed",
			"decrement", "decrement_highlight", "decrement_pressed",
		]:
			theme.set_icon(icon_name, bar, blank)
	scroll.theme = theme


static func _slider_track() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.0, 1.0)
	style.border_color = ACCENT
	style.set_border_width_all(1)
	style.anti_aliasing = false
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func _slider_fill() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.04, 0.04, 1.0)
	style.anti_aliasing = false
	return style


static func _scroll_track() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	style.anti_aliasing = false
	return style


static func _scroll_grab() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT
	style.anti_aliasing = false
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


static func _pixel_texture(color: Color, w: int, h: int) -> Texture2D:
	var image := Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


static func make_chrome_layer(parent: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "MenuChrome"
	layer.layer = 110
	parent.add_child(layer)
	return layer


static func make_backdrop(parent: Control) -> TextureRect:
	var layer := CanvasLayer.new()
	layer.name = "MenuBackdropLayer"
	layer.layer = BACKDROP_LAYER
	parent.add_child(layer)
	parent.move_child(layer, 0)
	var fill := ColorRect.new()
	fill.name = "MenuBackdropFill"
	fill.color = Color.BLACK
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fill)
	var bg := TextureRect.new()
	bg.name = "MenuBackdrop"
	bg.texture = BACKDROP
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate = Color.WHITE
	layer.add_child(bg)
	layout_backdrop(bg, 0.0)
	return bg


static func layout_backdrop(bg: TextureRect, time_sec: float) -> void:
	if bg == null or bg.texture == null:
		return
	var vp := bg.get_viewport_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return
	var tex := bg.texture.get_size()
	if tex.x < 1.0 or tex.y < 1.0:
		return
	var cover := maxf(vp.x / tex.x, vp.y / tex.y)
	var drawn := tex * (cover / BACKDROP_ZOOM_OUT)
	var origin := (vp - drawn) * 0.5
	var ox := sin(time_sec * 0.07) * 18.0
	var oy := cos(time_sec * 0.05) * 12.0
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 0.0
	bg.anchor_bottom = 0.0
	bg.offset_left = origin.x + ox
	bg.offset_top = origin.y + oy
	bg.offset_right = origin.x + drawn.x + ox
	bg.offset_bottom = origin.y + drawn.y + oy


static func drift_backdrop(bg: TextureRect, time_sec: float) -> void:
	layout_backdrop(bg, time_sec)


static func scaled_font(node: Node, authored: int) -> int:
	return maxi(roundi(float(authored) * UiViewportScale.factor(node)), 8)


static func go(tree: SceneTree, path: String) -> void:
	if tree.change_scene_to_file(path) != OK:
		push_error("MenuLook: could not open %s" % path)


static func _button_pad_style() -> StyleBoxEmpty:
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = _FOCUS_PAD_X
	empty.content_margin_right = _FOCUS_PAD_X
	empty.content_margin_top = _FOCUS_PAD_Y
	empty.content_margin_bottom = _FOCUS_PAD_Y
	return empty


static func _button_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = ACCENT
	style.border_blend = false
	style.anti_aliasing = false
	style.anti_aliasing_size = 0.0
	style.corner_detail = 1
	style.set_corner_radius_all(0)
	style.set_border_width_all(_FOCUS_BORDER)
	style.set_expand_margin_all(0)
	style.content_margin_left = _FOCUS_PAD_X
	style.content_margin_right = _FOCUS_PAD_X
	style.content_margin_top = _FOCUS_PAD_Y
	style.content_margin_bottom = _FOCUS_PAD_Y
	return style


static func set_button_disabled(button: BaseButton, disabled: bool) -> void:
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL


static func first_focusable(root: Node) -> Control:
	if root == null:
		return null
	if root is Control:
		var ctrl := root as Control
		if _can_take_focus(ctrl):
			return ctrl
	for child in root.get_children():
		var found := first_focusable(child)
		if found != null:
			return found
	return null


static func grab_first_focus(root: Node) -> void:
	var ctrl := first_focusable(root)
	if ctrl != null:
		ctrl.call_deferred("grab_focus", true)


static func grab_silent(ctrl: Control) -> void:
	if ctrl != null:
		ctrl.grab_focus(true)


static func _can_take_focus(ctrl: Control) -> bool:
	if ctrl == null or not ctrl.is_visible_in_tree():
		return false
	if ctrl.focus_mode == Control.FOCUS_NONE:
		return false
	if ctrl is BaseButton and (ctrl as BaseButton).disabled:
		return false
	return ctrl is BaseButton or ctrl is Range or ctrl is LineEdit or ctrl is TextEdit
