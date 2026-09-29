extends Control

signal win_popup_border_touched(payout_cents: int)

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const WIN_POPUP_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const POWER_FX_SHADER := preload("res://combat/shaders/power_symbol_fx.gdshader")

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
var _power_tween: Tween
var _power_mat: ShaderMaterial
var _power_glow: TextureRect
var _power_skull: TextureRect
var _power_ash: Control
var _extra_tweens: Array[Tween] = []
var _power_fx_active: bool = false
var _clip_before_power: bool = false

static var _blank_tex: Texture2D
static var _burn_noise: Texture2D


func _ready() -> void:
	_ensure_icon()
	_ensure_flash_overlay()


func set_symbol(sym: SymbolDefScript) -> void:
	_clear_power_fx()
	_ensure_icon()
	if sym != null and sym.texture != null:
		_icon.texture = sym.texture
	else:
		_icon.texture = null


func show_win_skull(tex: Texture2D) -> void:
	_clear_power_fx()
	_ensure_icon()
	_icon.texture = tex
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func play_drop(from_local: Vector2, to_local: Vector2, duration: float, delay: float = 0.0) -> void:
	_clear_power_fx()
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
	_clear_power_fx()
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
	_clear_power_fx()
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
	_clear_power_fx()
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


func play_power_act(kind: StringName, from_tex: Texture2D, to_tex: Texture2D, duration: float, reduce_flash: bool) -> void:
	if not is_inside_tree():
		return
	var mode := -1.0
	if kind == &"morph":
		mode = 0.0
	elif kind == &"eat":
		mode = 1.0
	elif kind == &"burn":
		mode = 2.0
	else:
		return
	duration = maxf(duration, 0.01)
	_begin_power_fx(from_tex, to_tex, mode, reduce_flash)
	_power_tween = create_tween()
	_power_tween.set_parallel(true)
	_power_tween.tween_method(_set_power_progress, 0.0, 1.0, duration)
	if mode < 0.5:
		_play_morph_motion(duration, reduce_flash, from_tex)
	elif mode < 1.5:
		_play_eat_motion(duration, to_tex)
	else:
		_play_burn_motion(duration, reduce_flash)


func _begin_power_fx(from_tex: Texture2D, to_tex: Texture2D, mode: float, reduce_flash: bool) -> void:
	_clear_power_fx()
	_ensure_icon()
	_clip_before_power = clip_contents
	clip_contents = true
	_power_fx_active = true
	_icon.texture = from_tex if from_tex != null else _blank_texture()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.modulate = Color.WHITE
	_icon.position = Vector2.ZERO
	_icon.scale = Vector2.ONE
	_center_pivot(_icon)
	_power_mat = ShaderMaterial.new()
	_power_mat.shader = POWER_FX_SHADER
	_power_mat.set_shader_parameter("fx_mode", mode)
	_power_mat.set_shader_parameter("progress", 0.0)
	_power_mat.set_shader_parameter("skip_white_hit", 1.0 if reduce_flash else 0.0)
	_power_mat.set_shader_parameter("next_tex", to_tex if to_tex != null else _blank_texture())
	_power_mat.set_shader_parameter("noise_tex", _noise_texture())
	_icon.material = _power_mat


func _play_morph_motion(duration: float, reduce_flash: bool, from_tex: Texture2D) -> void:
	_icon.scale = Vector2(0.92, 0.92)
	var scale_tw := _power_tween.tween_property(_icon, "scale", Vector2.ONE, duration)
	scale_tw.set_trans(Tween.TRANS_CUBIC)
	scale_tw.set_ease(Tween.EASE_OUT)
	if reduce_flash or from_tex == null:
		return
	_power_glow = _make_full_rect_texture("PowerGlow", from_tex)
	_power_glow.modulate = Color(1.6, 1.6, 1.6, 0.0)
	_insert_behind_icon(_power_glow)
	_center_pivot(_power_glow)
	_power_glow.scale = Vector2(1.08, 1.08)
	var glow_tw := create_tween()
	_extra_tweens.append(glow_tw)
	var hit := duration * 0.17
	glow_tw.tween_property(_power_glow, "modulate:a", 0.5, hit)
	glow_tw.tween_property(_power_glow, "modulate:a", 0.0, maxf(duration - hit, 0.01))


func _play_eat_motion(duration: float, skull_tex: Texture2D) -> void:
	var skull := skull_tex if skull_tex != null else _blank_texture()
	_power_skull = _make_full_rect_texture("PowerSkull", skull)
	_power_skull.modulate = Color(1, 1, 1, 0)
	_insert_behind_icon(_power_skull)
	_center_pivot(_power_skull)
	_power_skull.scale = Vector2(0.35, 0.35)
	var grow := _power_tween.tween_property(_power_skull, "scale", Vector2.ONE, duration)
	grow.set_trans(Tween.TRANS_CUBIC)
	grow.set_ease(Tween.EASE_OUT)
	var fade := _power_tween.tween_property(_power_skull, "modulate:a", 1.0, duration * 0.42)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)
	var shrink := _power_tween.tween_property(_icon, "scale", Vector2(0.18, 0.18), duration)
	shrink.set_trans(Tween.TRANS_SINE)
	shrink.set_ease(Tween.EASE_IN)


func _play_burn_motion(duration: float, reduce_flash: bool) -> void:
	var sink := _power_tween.tween_property(_icon, "scale", Vector2(0.94, 0.94), duration)
	sink.set_trans(Tween.TRANS_SINE)
	sink.set_ease(Tween.EASE_IN)
	if reduce_flash:
		return
	_power_ash = Control.new()
	_power_ash.name = "PowerAsh"
	_power_ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_ash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_power_ash)
	if _icon != null:
		move_child(_power_ash, _icon.get_index() + 1)
	var cell := size
	if cell.x < 2.0 or cell.y < 2.0:
		cell = custom_minimum_size
	if cell.x < 2.0:
		cell = Vector2(32, 32)
	for i in 8:
		var fleck := ColorRect.new()
		fleck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ang := float(i) * TAU / 8.0 + 0.35
		var rad := 0.10 + float(i % 3) * 0.07
		var origin := cell * 0.5 + Vector2(cos(ang), sin(ang) * 0.65) * cell.x * rad
		var bits := maxf(2.0, cell.x * 0.045)
		if i % 2 == 1:
			bits += 1.0
		fleck.size = Vector2(bits, bits)
		fleck.position = origin - fleck.size * 0.5
		var grey := 0.92 if i % 3 == 0 else (0.55 + float(i % 4) * 0.06)
		fleck.color = Color(grey, grey, grey, 1.0)
		fleck.modulate.a = 0.0
		_power_ash.add_child(fleck)
		var delay := float(i) * duration * 0.055
		var span := maxf(duration - delay, 0.05)
		var rise := cell.y * 0.30
		var drift := (float(i % 5) - 2.0) * cell.x * 0.04
		var end := fleck.position + Vector2(drift, -rise)
		var tw := create_tween()
		_extra_tweens.append(tw)
		tw.tween_interval(delay)
		tw.tween_property(fleck, "modulate:a", 0.85, span * 0.18)
		tw.parallel().tween_property(fleck, "position", end, span * 0.85)
		tw.tween_property(fleck, "modulate:a", 0.0, span * 0.15)


func _set_power_progress(t: float) -> void:
	if _power_mat == null:
		return
	_power_mat.set_shader_parameter("progress", t)


func _clear_power_fx() -> void:
	_cancel_tween(_power_tween)
	_power_tween = null
	for tw in _extra_tweens:
		_cancel_tween(tw)
	_extra_tweens.clear()
	_power_mat = null
	if _icon != null and is_instance_valid(_icon):
		_icon.material = null
		if _power_fx_active:
			_icon.scale = Vector2.ONE
			_icon.pivot_offset = Vector2.ZERO
			_icon.modulate = Color.WHITE
			_icon.position = Vector2.ZERO
	_free_power_node(_power_glow)
	_power_glow = null
	_free_power_node(_power_skull)
	_power_skull = null
	_free_power_node(_power_ash)
	_power_ash = null
	if _power_fx_active:
		clip_contents = _clip_before_power
		_power_fx_active = false


func _free_power_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.free()


func _make_full_rect_texture(node_name: String, tex: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	return rect


func _insert_behind_icon(node: CanvasItem) -> void:
	add_child(node)
	if _icon != null and is_instance_valid(_icon):
		move_child(node, _icon.get_index())


func _center_pivot(node: Control) -> void:
	var pivot := size * 0.5
	if pivot == Vector2.ZERO:
		pivot = custom_minimum_size * 0.5
	if pivot == Vector2.ZERO:
		pivot = Vector2(16, 16)
	node.pivot_offset = pivot


static func _blank_texture() -> Texture2D:
	if _blank_tex != null:
		return _blank_tex
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	_blank_tex = ImageTexture.create_from_image(img)
	return _blank_tex


static func _noise_texture() -> Texture2D:
	if _burn_noise != null:
		return _burn_noise
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var n := _hash_unit(x, y)
			img.set_pixel(x, y, Color(n, n, n, 1.0))
	_burn_noise = ImageTexture.create_from_image(img)
	return _burn_noise


static func _hash_unit(x: int, y: int) -> float:
	var h: int = (x * 374761393) ^ (y * 668265263)
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 255) / 255.0


func _cancel_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()
