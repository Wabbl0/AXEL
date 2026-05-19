extends Control

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")

## Winnings popup — Concept A (white + heavy gray outline, no yellow).
## Alternates: B = micro red/black pill badge; C = red outer-glow pulse, less drift.
const WIN_POPUP_FONT_SIZE := 16
const WIN_POPUP_DRIFT_PX := -6.0
const WIN_POPUP_SCALE_PEAK := 1.5

var _drop_tween: Tween
var _flash_tween: Tween
var _win_tween: Tween
var _flash_overlay: ColorRect
var _icon: TextureRect
var _win_label: Label
var _win_glow_label: Label


func _ready() -> void:
	_ensure_icon()
	_ensure_flash_overlay()


func set_symbol(sym: SymbolDefScript) -> void:
	_ensure_icon()
	if sym != null and sym.texture != null:
		_icon.texture = sym.texture
	else:
		_icon.texture = null


func play_drop(from_local: Vector2, to_local: Vector2, duration: float, delay: float = 0.0) -> void:
	_ensure_icon()
	_cancel_tween(_drop_tween)
	_icon.position = from_local - to_local
	_drop_tween = create_tween()
	if delay > 0.0:
		_drop_tween.tween_interval(delay)
	_drop_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(_icon, "position", Vector2.ZERO, max(duration, 0.01))


func play_count_flash(duration: float, peak_alpha: float = 0.55, delay: float = 0.0) -> void:
	_ensure_flash_overlay()
	_cancel_tween(_flash_tween)
	_flash_overlay.color.a = 0.0
	_flash_overlay.visible = true
	_flash_tween = create_tween()
	if delay > 0.0:
		_flash_tween.tween_interval(delay)
	var half: float = max(duration * 0.5, 0.01)
	_flash_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_flash_overlay, "color:a", clamp(peak_alpha, 0.0, 1.0), half)
	_flash_tween.set_ease(Tween.EASE_IN)
	_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, half)
	_flash_tween.finished.connect(func() -> void:
		if is_instance_valid(_flash_overlay):
			_flash_overlay.visible = false
	)


func cancel_active_fx() -> void:
	_ensure_icon()
	_cancel_tween(_drop_tween)
	_cancel_tween(_flash_tween)
	_cancel_tween(_win_tween)
	if _flash_overlay != null:
		_flash_overlay.color.a = 0.0
		_flash_overlay.visible = false
	if _win_label != null:
		_win_label.visible = false
		_win_label.modulate.a = 0.0
		_win_label.position = Vector2.ZERO
		_win_label.scale = Vector2.ONE
	if _win_glow_label != null:
		_win_glow_label.visible = false
		_win_glow_label.modulate.a = 0.0
		_win_glow_label.position = Vector2.ZERO
		_win_glow_label.scale = Vector2.ONE
	_icon.position = Vector2.ZERO


func _ensure_flash_overlay() -> void:
	if _flash_overlay != null and is_instance_valid(_flash_overlay):
		return
	_flash_overlay = ColorRect.new()
	_flash_overlay.name = "FlashOverlay"
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_overlay.anchor_right = 1.0
	_flash_overlay.anchor_bottom = 1.0
	_flash_overlay.offset_left = 0.0
	_flash_overlay.offset_top = 0.0
	_flash_overlay.offset_right = 0.0
	_flash_overlay.offset_bottom = 0.0
	_flash_overlay.visible = false
	add_child(_flash_overlay)


func _ensure_icon() -> void:
	if _icon != null and is_instance_valid(_icon):
		return
	_icon = get_node_or_null("Icon") as TextureRect
	if _icon != null:
		return
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.anchor_right = 1.0
	_icon.anchor_bottom = 1.0
	_icon.offset_left = 0.0
	_icon.offset_top = 0.0
	_icon.offset_right = 0.0
	_icon.offset_bottom = 0.0
	add_child(_icon)
	move_child(_icon, 0)


func play_win_popup(amount_text: String, duration: float = 0.4, delay: float = 0.0) -> void:
	_ensure_win_label()
	_ensure_win_glow_label()
	_cancel_tween(_win_tween)
	_win_label.text = amount_text
	_win_glow_label.text = amount_text
	_win_label.visible = true
	_win_glow_label.visible = true
	_win_label.modulate.a = 0.0
	_win_glow_label.modulate.a = 0.0
	_win_label.position = Vector2.ZERO
	_win_glow_label.position = Vector2.ZERO
	_win_label.scale = Vector2.ONE
	_win_glow_label.scale = Vector2.ONE
	_win_tween = create_tween()
	if delay > 0.0:
		_win_tween.tween_interval(delay)
	_win_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_win_tween.tween_property(_win_label, "modulate:a", 1.0, 0.06)
	_win_tween.parallel().tween_property(_win_glow_label, "modulate:a", 0.85, 0.06)
	_win_tween.parallel().tween_property(_win_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_PEAK, 0.08)
	_win_tween.parallel().tween_property(_win_glow_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_PEAK, 0.08)
	_win_tween.parallel().tween_property(_win_label, "position:y", WIN_POPUP_DRIFT_PX, max(duration, 0.12))
	_win_tween.parallel().tween_property(_win_glow_label, "position:y", WIN_POPUP_DRIFT_PX, max(duration, 0.12))
	_win_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_win_tween.tween_property(_win_label, "scale", Vector2.ONE, 0.12)
	_win_tween.parallel().tween_property(_win_glow_label, "scale", Vector2.ONE, 0.12)
	_win_tween.tween_interval(max(duration - 0.12, 0.02))
	_win_tween.set_ease(Tween.EASE_IN)
	_win_tween.tween_property(_win_label, "modulate:a", 0.0, 0.08)
	_win_tween.parallel().tween_property(_win_glow_label, "modulate:a", 0.0, 0.08)
	_win_tween.finished.connect(func() -> void:
		if is_instance_valid(_win_label):
			_win_label.visible = false
			_win_label.position = Vector2.ZERO
			_win_label.scale = Vector2.ONE
		if is_instance_valid(_win_glow_label):
			_win_glow_label.visible = false
			_win_glow_label.position = Vector2.ZERO
			_win_glow_label.scale = Vector2.ONE
	)


func _ensure_win_label() -> void:
	if _win_label != null and is_instance_valid(_win_label):
		return
	_win_label = Label.new()
	_win_label.name = "WinPopupLabel"
	_win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_win_label.anchor_right = 1.0
	_win_label.anchor_bottom = 1.0
	_win_label.offset_left = 0.0
	_win_label.offset_top = 0.0
	_win_label.offset_right = 0.0
	_win_label.offset_bottom = 0.0
	_win_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_win_label.add_theme_color_override("font_outline_color", Color(0.22, 0.22, 0.22, 1.0))
	_win_label.add_theme_constant_override("outline_size", 4)
	_win_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.12, 0.12, 0.85))
	_win_label.add_theme_constant_override("shadow_offset_x", 1)
	_win_label.add_theme_constant_override("shadow_offset_y", 1)
	_win_label.add_theme_font_size_override("font_size", WIN_POPUP_FONT_SIZE)
	_win_label.visible = false
	_win_label.modulate.a = 0.0
	add_child(_win_label)


func _ensure_win_glow_label() -> void:
	if _win_glow_label != null and is_instance_valid(_win_glow_label):
		return
	_win_glow_label = Label.new()
	_win_glow_label.name = "WinPopupGlowLabel"
	_win_glow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_glow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_win_glow_label.anchor_right = 1.0
	_win_glow_label.anchor_bottom = 1.0
	_win_glow_label.offset_left = 0.0
	_win_glow_label.offset_top = 0.0
	_win_glow_label.offset_right = 0.0
	_win_glow_label.offset_bottom = 0.0
	_win_glow_label.add_theme_color_override("font_color", Color(1.0, 0.24, 0.24, 0.95))
	_win_glow_label.add_theme_color_override("font_outline_color", Color(0.45, 0.0, 0.0, 0.95))
	_win_glow_label.add_theme_constant_override("outline_size", 6)
	_win_glow_label.add_theme_font_size_override("font_size", WIN_POPUP_FONT_SIZE)
	_win_glow_label.visible = false
	_win_glow_label.modulate.a = 0.0
	add_child(_win_glow_label)
	if _win_label != null and is_instance_valid(_win_label):
		move_child(_win_glow_label, _win_label.get_index())


func _cancel_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()
