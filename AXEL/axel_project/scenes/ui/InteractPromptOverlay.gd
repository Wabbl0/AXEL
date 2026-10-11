extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")

@export var key_label := "[E]"
@export var screen_offset := Vector2.ZERO

const _CHIP_FONT_BASE := 26
const _CHIP_OUTLINE_BASE := 2
const _TAP_PULSE_SEC := 1.2
const _TAP_RING_RADIUS := 34.0
const _TAP_RING_WIDTH := 3.0
const _TAP_HIT_RADIUS := 70.0
const _TAP_COLOR := Color(0.9, 0.0, 0.0, 1.0)
const _TAP_ALPHA_MIN := 0.25
const _TAP_ALPHA_MAX := 0.6
const _TAP_SCALE_MAX := 1.15

@onready var _root: Control = $ViewportRoot/ChipRoot
@onready var _panel: PanelContainer = $ViewportRoot/ChipRoot/BarPanel
@onready var _beam: ColorRect = $ViewportRoot/ChipRoot/BarPanel/PowerBeam
@onready var _bloom: ColorRect = $ViewportRoot/ChipRoot/BarPanel/Bloom
@onready var _label: Label = $ViewportRoot/ChipRoot/BarPanel/InnerPanel/KeyLabel

var _world_anchor := Vector2.ZERO
var _below_sprite: CanvasItem = null
var _below_gap_px := -1.0
var _is_active := false
var _crt_settled := false
var _anim_token := 0
var _crt_opts = CrtPowerFx.compact_chip_options()
var _tap_pulse: Control = null


func _ready() -> void:
	layer = 110
	_label.text = key_label
	if _touch_mode():
		_build_tap_pulse()
	_apply_chip_scale()
	get_viewport().size_changed.connect(_apply_chip_scale)
	_root.visible = false
	_root.modulate.a = 0.0
	_beam.visible = false
	_set_ignore_mouse_recursive(self)
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)
	tree_exiting.connect(_on_tree_exiting)


func _apply_chip_scale() -> void:
	var f := UiViewportScale.factor(self)
	_label.add_theme_font_size_override("font_size", roundi(_CHIP_FONT_BASE * f))
	_label.add_theme_constant_override("outline_size", roundi(_CHIP_OUTLINE_BASE * f))
	if _tap_pulse != null:
		_tap_pulse.queue_redraw()
	if _is_active:
		_update_screen_position()


func _on_tree_exiting() -> void:
	_anim_token += 1

	if is_instance_valid(_root) and is_instance_valid(_panel):
		CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_is_active = false
	_crt_settled = false
	set_process(false)


func _host_alive() -> bool:
	return is_instance_valid(self) and is_inside_tree() and get_tree() != null


func _process(_delta: float) -> void:
	if not _is_active:
		return
	_update_screen_position()


func set_world_anchor(world_pos: Vector2) -> void:
	_world_anchor = world_pos
	if _is_active:
		_update_screen_position()


func show_prompt_below_sprite(sprite: CanvasItem, gap_px: float) -> void:
	_below_sprite = sprite
	_below_gap_px = gap_px
	var anchor := Vector2.ZERO
	if sprite is Node2D:
		anchor = (sprite as Node2D).global_position
	show_prompt(anchor)


func show_prompt_below_sprite_immediate(sprite: CanvasItem, gap_px: float) -> void:
	_below_sprite = sprite
	_below_gap_px = gap_px
	var anchor := Vector2.ZERO
	if sprite is Node2D:
		anchor = (sprite as Node2D).global_position
	show_prompt_immediate(anchor)


func anchored_items_indicator_screen_rect() -> Rect2:
	if _below_sprite == null or not is_instance_valid(_below_sprite):
		return Rect2()
	return _canvas_item_screen_rect(_below_sprite)


func show_prompt(world_pos: Vector2) -> void:
	_world_anchor = world_pos
	if _is_active and _crt_settled:
		_update_screen_position()
		return

	if _is_active and not _crt_settled:
		_snap_shown()
		return
	_run_show_async()


func hide_prompt() -> void:
	if not _is_active:
		return

	if not _crt_settled:
		hide_prompt_immediate()
		return
	_run_hide_async()


func hide_prompt_immediate() -> void:
	_anim_token += 1
	CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_below_sprite = null
	_below_gap_px = -1.0
	_is_active = false
	_crt_settled = false
	_root.visible = false
	_root.modulate.a = 0.0
	set_process(false)


func show_prompt_immediate(world_pos: Vector2) -> void:
	_world_anchor = world_pos
	_snap_shown()


func is_prompt_visible() -> bool:
	return _is_active and _root.visible and _root.modulate.a > 0.01


func _snap_shown() -> void:
	_anim_token += 1
	CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_is_active = true
	_crt_settled = true
	_root.visible = true
	_root.modulate.a = 1.0
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)
	set_process(true)
	_update_screen_position()


func _run_show_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_is_active = true
	_crt_settled = false
	_root.visible = true
	set_process(true)
	_update_screen_position()
	await CrtPowerFx.power_on(self, _root, _panel, _beam, _bloom, _crt_opts)
	if not _host_alive() or token != _anim_token:
		return
	_crt_settled = true
	_update_screen_position()


func _run_hide_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_crt_settled = false
	await CrtPowerFx.power_off(self, _root, _panel, _beam, _bloom, _crt_opts)
	if not _host_alive() or token != _anim_token:
		return
	_is_active = false
	_below_sprite = null
	_below_gap_px = -1.0
	_root.visible = false
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)


func chip_screen_rect() -> Rect2:
	if _using_items_indicator_gap():
		var placed := _items_indicator_chip_top_left()
		if placed.x > -100000.0:
			var chip_size := _panel_size()
			return Rect2(placed, chip_size)
	var viewport := get_viewport()
	if viewport == null:
		return Rect2()
	var panel_size := Vector2.ZERO
	if _panel != null and is_instance_valid(_panel):
		panel_size = _panel.get_combined_minimum_size()
		if panel_size.x <= 1.0 or panel_size.y <= 1.0:
			panel_size = _panel.size
	if panel_size.x <= 1.0 or panel_size.y <= 1.0:
		panel_size = Vector2(36.0, 28.0)
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	return Rect2(screen_pos + screen_offset - panel_size * 0.5, panel_size)


func _update_screen_position() -> void:
	if _using_items_indicator_gap():
		var placed := _items_indicator_chip_top_left()
		if placed.x > -100000.0:
			_chip_root_position(placed)
			return
	var viewport := get_viewport()
	if viewport == null:
		return
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	var panel_size := _panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = _panel.get_combined_minimum_size()
	_chip_root_position(screen_pos + screen_offset - panel_size * 0.5)


func _chip_root_position(pos: Vector2) -> void:
	_root.position = pos
	if _tap_pulse != null:
		_tap_pulse.position = _panel_size() * 0.5


func _touch_mode() -> bool:
	var stick := get_node_or_null("/root/AxelTouchStick")
	return stick != null and bool(stick.call("is_touch_mode"))


func _build_tap_pulse() -> void:
	_panel.visible = false
	_tap_pulse = Control.new()
	_tap_pulse.name = "TapPulse"
	_tap_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tap_pulse.position = _panel_size() * 0.5
	_tap_pulse.draw.connect(_draw_tap_pulse)
	_root.add_child(_tap_pulse)
	if UiViewportScale._reduce_flashing(self):
		_tap_pulse.modulate.a = (_TAP_ALPHA_MIN + _TAP_ALPHA_MAX) * 0.5
		return
	_tap_pulse.modulate.a = _TAP_ALPHA_MIN
	var half := _TAP_PULSE_SEC * 0.5
	var tween := _tap_pulse.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_tap_pulse, "modulate:a", _TAP_ALPHA_MAX, half)
	tween.parallel().tween_property(_tap_pulse, "scale", Vector2.ONE * _TAP_SCALE_MAX, half)
	tween.tween_property(_tap_pulse, "modulate:a", _TAP_ALPHA_MIN, half)
	tween.parallel().tween_property(_tap_pulse, "scale", Vector2.ONE, half)


func _draw_tap_pulse() -> void:
	var f := UiViewportScale.factor(self)
	var radius := _TAP_RING_RADIUS * f
	_tap_pulse.draw_circle(Vector2.ZERO, radius * 1.4, Color(_TAP_COLOR, 0.12), true, -1.0, true)
	_tap_pulse.draw_circle(Vector2.ZERO, radius, Color(_TAP_COLOR, 0.35), true, -1.0, true)
	_tap_pulse.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, _TAP_COLOR, _TAP_RING_WIDTH * f, true)


func tap_center() -> Vector2:
	_update_screen_position()
	return _root.position + _panel_size() * 0.5


func tap_hit(screen_pos: Vector2) -> bool:
	if not is_prompt_visible():
		return false
	return screen_pos.distance_to(tap_center()) <= _TAP_HIT_RADIUS * UiViewportScale.factor(self)


func _using_items_indicator_gap() -> bool:
	return (
		_below_gap_px >= 0.0
		and _below_sprite != null
		and is_instance_valid(_below_sprite)
	)


func _panel_size() -> Vector2:
	var panel_size := _panel.size
	if panel_size.x <= 1.0 or panel_size.y <= 1.0:
		panel_size = _panel.get_combined_minimum_size()
	if panel_size.x <= 1.0 or panel_size.y <= 1.0:
		panel_size = Vector2(36.0, 28.0)
	return panel_size


func _items_indicator_chip_top_left() -> Vector2:
	var items_indicator := _canvas_item_screen_rect(_below_sprite)
	if items_indicator.size.y <= 1.0:
		return Vector2(-1000000.0, 0.0)
	var panel_size := _panel_size()
	return Vector2(items_indicator.get_center().x - panel_size.x * 0.5, items_indicator.end.y + _below_gap_px)


func _canvas_item_screen_rect(item: CanvasItem) -> Rect2:
	var local := _local_draw_rect(item)
	if local.size.x <= 0.0 or local.size.y <= 0.0:
		return Rect2()
	var xf := item.get_global_transform_with_canvas()
	var rect := Rect2(xf * local.position, Vector2.ZERO)
	rect = rect.expand(xf * (local.position + Vector2(local.size.x, 0.0)))
	rect = rect.expand(xf * (local.position + local.size))
	rect = rect.expand(xf * (local.position + Vector2(0.0, local.size.y)))
	return rect


func _local_draw_rect(item: CanvasItem) -> Rect2:
	var tex_size := Vector2.ZERO
	var sprite_offset := Vector2.ZERO
	var centered := true
	if item is AnimatedSprite2D:
		var anim := item as AnimatedSprite2D
		sprite_offset = anim.offset
		centered = anim.centered
		tex_size = _anim_frame_size(anim)
	elif item is Sprite2D:
		var sprite := item as Sprite2D
		sprite_offset = sprite.offset
		centered = sprite.centered
		if sprite.texture != null:
			tex_size = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
	var ink := _ink_rect_from_parent(item)
	if ink.size.x > 1.0 and ink.size.y > 1.0 and tex_size != Vector2.ZERO:
		var origin := ink.position + sprite_offset
		if centered:
			origin -= tex_size * 0.5
		return Rect2(origin, ink.size)
	if tex_size == Vector2.ZERO:
		return Rect2()
	var fallback := sprite_offset
	if centered:
		fallback -= tex_size * 0.5
	return Rect2(fallback, tex_size)


func _ink_rect_from_parent(item: CanvasItem) -> Rect2:
	var parent := item.get_parent()
	if parent == null or not parent.has_method("ink_local_rect"):
		return Rect2()
	var got: Variant = parent.call("ink_local_rect")
	if got is Rect2:
		return got as Rect2
	return Rect2()


func _anim_frame_size(sprite: AnimatedSprite2D) -> Vector2:
	if sprite.sprite_frames == null:
		return Vector2.ZERO
	var anim := sprite.animation
	if anim == StringName() or not sprite.sprite_frames.has_animation(anim):
		return Vector2.ZERO
	var tex := sprite.sprite_frames.get_frame_texture(anim, sprite.frame)
	if tex == null:
		return Vector2.ZERO
	return tex.get_size()


func _set_ignore_mouse_recursive(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_set_ignore_mouse_recursive(c)
