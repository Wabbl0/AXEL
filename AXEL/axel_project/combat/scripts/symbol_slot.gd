extends Control

signal win_popup_border_touched(payout_cents: int)

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const WIN_POPUP_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")

const WIN_POPUP_FONT_SIZE := 70
const WIN_POPUP_SCALE_START := 0.72
const WIN_POPUP_SCALE_PEAK := 1.45
const WIN_POPUP_SCALE_LOB_END := 0.92
const WIN_POPUP_ARC_HEIGHT := 52.0
const WIN_POPUP_TOTAL_DURATION := 1.24
const WIN_POPUP_PHASE_APPEAR_SHARE := 0.12
const WIN_POPUP_PHASE_SCALE_SHARE := 0.22
const WIN_POPUP_PHASE_GLOW_SHARE := 0.18
const WIN_POPUP_PHASE_LOB_SHARE := 0.36
const WIN_POPUP_PHASE_FADE_SHARE := 0.12
const WIN_POPUP_GLOW_PEAK_ALPHA := 1.0

var _drop_tween: Tween
var _flash_tween: Tween
var _win_tween: Tween
var _flash_overlay: ColorRect
var _icon: TextureRect
var _win_label: Label
var _win_glow_label: Label
var _lob_p0: Vector2 = Vector2.ZERO
var _lob_p1: Vector2 = Vector2.ZERO
var _lob_p2: Vector2 = Vector2.ZERO
var _lob_use_target: bool = false
var _touch_target_rect_global: Rect2 = Rect2()
var _touch_payout_cents: int = 0
var _touch_emitted: bool = false


func _ready() -> void:
	_ensure_icon()
	_ensure_flash_overlay()


func set_symbol(sym: SymbolDefScript) -> void:
	_ensure_icon()
	if sym != null and sym.texture != null:
		_icon.texture = sym.texture
	else:
		_icon.texture = null


func show_win_skull(tex: Texture2D) -> void:
	_ensure_icon()
	_icon.texture = tex
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func play_drop(from_local: Vector2, to_local: Vector2, duration: float, delay: float = 0.0) -> void:
	_ensure_icon()
	_cancel_tween(_drop_tween)
	_icon.position = from_local - to_local
	_drop_tween = create_tween()
	if delay > 0.0:
		_drop_tween.tween_interval(delay)
	_drop_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(_icon, "position", Vector2.ZERO, max(duration, 0.01))
	_drop_tween.tween_property(_icon, "scale", Vector2(1.18, 0.78), 0.05)
	_drop_tween.tween_property(_icon, "scale", Vector2.ONE, 0.08)


func has_visible_symbol() -> bool:
	_ensure_icon()
	return _icon.texture != null


func play_fall_off(distance_px: float, duration: float, delay: float = 0.0) -> void:
	_ensure_icon()
	_cancel_tween(_drop_tween)
	_icon.position = Vector2.ZERO
	_icon.scale = Vector2.ONE
	_drop_tween = create_tween()
	if delay > 0.0:
		_drop_tween.tween_interval(delay)
	_drop_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_drop_tween.tween_property(_icon, "position", Vector2(0.0, distance_px), max(duration, 0.01))
	_drop_tween.tween_callback(_clear_icon_after_fall_off)


func _clear_icon_after_fall_off() -> void:
	if _icon == null or not is_instance_valid(_icon):
		return
	_icon.texture = null
	_icon.position = Vector2.ZERO


func play_tube_in(distance_px: float, duration: float) -> void:
	_ensure_icon()
	_cancel_tween(_drop_tween)
	_icon.scale = Vector2.ONE
	_icon.position = Vector2(0.0, -distance_px)
	_drop_tween = create_tween()
	_drop_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
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
	_reset_win_popup_visuals()
	_icon.position = Vector2.ZERO
	_icon.scale = Vector2.ONE


func play_win_popup(
	amount_text: String,
	_duration: float = 0.4,
	delay: float = 0.0,
	throw_target_global: Vector2 = Vector2.INF,
	throw_target_rect_global: Rect2 = Rect2(),
	payout_cents: int = 0,
) -> void:
	_ensure_win_label()
	_ensure_win_glow_label()
	_cancel_tween(_win_tween)
	_win_label.text = amount_text
	_win_glow_label.text = amount_text
	_reset_win_popup_visuals()
	_win_label.visible = true
	_win_glow_label.visible = true

	var pivot := _popup_pivot()
	_apply_popup_pivot(pivot)
	var start_pos := _popup_start_position(pivot)
	var end_pos := _resolve_throw_target_local(throw_target_global, pivot)
	var use_lob := throw_target_global != Vector2.INF and end_pos.distance_to(start_pos) > 4.0
	_lob_use_target = use_lob
	_touch_target_rect_global = throw_target_rect_global if use_lob else Rect2()
	_touch_payout_cents = maxi(payout_cents, 0)
	_touch_emitted = false

	_win_label.position = start_pos
	_win_glow_label.position = start_pos
	_win_label.scale = Vector2.ONE * WIN_POPUP_SCALE_START
	_win_glow_label.scale = Vector2.ONE * WIN_POPUP_SCALE_START
	_win_label.modulate.a = 0.0
	_win_glow_label.modulate.a = 0.0

	var phase := _win_popup_phase_durations()
	_win_tween = create_tween()
	if delay > 0.0:
		_win_tween.tween_interval(delay)


	_win_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_win_tween.tween_property(_win_label, "modulate:a", 0.65, phase.appear)
	_win_tween.parallel().tween_property(_win_glow_label, "modulate:a", 0.35, phase.appear)


	_win_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_win_tween.tween_property(_win_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_PEAK, phase.scale_up)
	_win_tween.parallel().tween_property(_win_glow_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_PEAK, phase.scale_up)
	_win_tween.parallel().tween_property(_win_label, "modulate:a", 1.0, phase.scale_up)
	_win_tween.parallel().tween_property(_win_glow_label, "modulate:a", 0.85, phase.scale_up)


	var glow_half: float = float(phase.glow_hold) * 0.5
	_win_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_win_tween.tween_property(_win_glow_label, "modulate:a", WIN_POPUP_GLOW_PEAK_ALPHA, glow_half)
	_win_tween.tween_property(_win_glow_label, "modulate:a", 0.9, glow_half)

	if use_lob:
		_lob_p0 = start_pos
		_lob_p2 = end_pos
		_lob_p1 = (start_pos + end_pos) * 0.5 + Vector2(0.0, -WIN_POPUP_ARC_HEIGHT)

		_win_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_win_tween.tween_method(_apply_lob_position, 0.0, 1.0, phase.lob)
		_win_tween.parallel().tween_property(_win_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_LOB_END, phase.lob)
		_win_tween.parallel().tween_property(_win_glow_label, "scale", Vector2.ONE * WIN_POPUP_SCALE_LOB_END, phase.lob)
	else:

		_win_tween.tween_interval(phase.lob)


	_win_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_win_tween.tween_property(_win_label, "modulate:a", 0.0, phase.fade_out)
	_win_tween.parallel().tween_property(_win_glow_label, "modulate:a", 0.0, phase.fade_out)

	_win_tween.finished.connect(_on_win_popup_finished)


func _win_popup_phase_durations() -> Dictionary:
	var total: float = WIN_POPUP_TOTAL_DURATION
	return {
		"appear": total * WIN_POPUP_PHASE_APPEAR_SHARE,
		"scale_up": total * WIN_POPUP_PHASE_SCALE_SHARE,
		"glow_hold": total * WIN_POPUP_PHASE_GLOW_SHARE,
		"lob": total * WIN_POPUP_PHASE_LOB_SHARE,
		"fade_out": total * WIN_POPUP_PHASE_FADE_SHARE,
	}


func _apply_lob_position(t: float) -> void:
	var pos := _bezier_quad(_lob_p0, _lob_p1, _lob_p2, t)
	if is_instance_valid(_win_label):
		_win_label.position = pos
	if is_instance_valid(_win_glow_label):
		_win_glow_label.position = pos
	_try_emit_border_touch()


func _bezier_quad(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


func _popup_pivot() -> Vector2:
	return size * 0.5


func _popup_position_for_center(local_center: Vector2, pivot: Vector2) -> Vector2:
	return local_center - pivot


func _popup_start_position(pivot: Vector2) -> Vector2:
	return _popup_position_for_center(size * 0.5, pivot)


func _resolve_throw_target_local(throw_target_global: Vector2, pivot: Vector2) -> Vector2:
	if throw_target_global == Vector2.INF:
		return _popup_start_position(pivot)
	var local_center := get_global_transform_with_canvas().affine_inverse() * throw_target_global
	return _popup_position_for_center(local_center, pivot)


func _apply_popup_pivot(pivot: Vector2) -> void:
	_win_label.pivot_offset = pivot
	_win_glow_label.pivot_offset = pivot


func _try_emit_border_touch() -> void:
	if _touch_emitted or not _lob_use_target:
		return
	if _touch_target_rect_global.size.x <= 0.0 or _touch_target_rect_global.size.y <= 0.0:
		return
	if _touch_payout_cents <= 0:
		return
	if _win_label == null or not is_instance_valid(_win_label):
		return
	var popup_rect := _win_label.get_global_rect()
	if not popup_rect.intersects(_touch_target_rect_global):
		return
	_touch_emitted = true
	win_popup_border_touched.emit(_touch_payout_cents)


func _reset_win_popup_visuals() -> void:
	_lob_use_target = false
	_touch_target_rect_global = Rect2()
	_touch_payout_cents = 0
	_touch_emitted = false
	var pivot := _popup_pivot()
	var origin := _popup_start_position(pivot)
	if _win_label != null:
		_apply_popup_pivot(pivot)
		_win_label.visible = false
		_win_label.modulate.a = 0.0
		_win_label.position = origin
		_win_label.scale = Vector2.ONE
	if _win_glow_label != null:
		_apply_popup_pivot(pivot)
		_win_glow_label.visible = false
		_win_glow_label.modulate.a = 0.0
		_win_glow_label.position = origin
		_win_glow_label.scale = Vector2.ONE


func _on_win_popup_finished() -> void:
	_reset_win_popup_visuals()


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
	_apply_win_popup_font(_win_label)
	_win_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_win_label.remove_theme_color_override("font_outline_color")
	_win_label.add_theme_constant_override("outline_size", 0)
	_win_label.add_theme_color_override("font_shadow_color", Color(0.22, 0.22, 0.22, 0.72))
	_win_label.add_theme_constant_override("shadow_offset_x", 0)
	_win_label.add_theme_constant_override("shadow_offset_y", 1)
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
	_apply_win_popup_font(_win_glow_label)
	_win_glow_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28, 0.9))
	_win_glow_label.add_theme_color_override("font_outline_color", Color(0.55, 0.0, 0.0, 0.85))
	_win_glow_label.add_theme_constant_override("outline_size", 5)
	_win_glow_label.visible = false
	_win_glow_label.modulate.a = 0.0
	add_child(_win_glow_label)
	if _win_label != null and is_instance_valid(_win_label):
		move_child(_win_glow_label, _win_label.get_index())


func _apply_win_popup_font(label: Label) -> void:
	label.add_theme_font_override("font", WIN_POPUP_FONT)
	label.add_theme_font_size_override("font_size", WIN_POPUP_FONT_SIZE)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _cancel_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()
