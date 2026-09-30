extends Control

signal pressed

@export_range(0.0, 1.0, 0.01) var preview_fill: float = 0.0

const STAGE_THRESHOLDS := [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
const HOVER_SCALE := 1.06
const PRESS_SCALE := 0.94
const FILL_SCALE_1_3 := 1.08
const FILL_SCALE_2_3 := 1.1
# About 8% smaller than the old 1.16 full face, so the spin bars can sit under the jaw.
const FILL_SCALE_FULL := 1.067
const FULL_FACE_LIFT := 70.0
const GLOW_HOVER_ALPHA := 0.45
const GLOW_FILL_ALPHA := 0.55
const OUTLINE_SCALE := 1.03
const HudDropShadowScript := preload("res://combat/scripts/hud_drop_shadow.gd")
const FLAME_CROWN_SHEET := "res://assets/sprites/combat/flame_6_48x48.png"
const FLAME_CROWN_SHADER := preload("res://combat/shaders/flame_crown.gdshader")
const FLAME_CROWN_FPS := 10.0
const FLAME_CROWN_COPIES := 5.0
const FLAME_CROWN_THIN := 0.72
const FLAME_CROWN_ARC := 0.22
const FLAME_CROWN_POS := Vector2(40.0, -46.0)
const FLAME_CROWN_SIZE := Vector2(612.0, 240.0)
const PUNCH_BLACK := 0.08
const SKULL_SHADOW_OFFSET := Vector2(-4.0, 5.0)
const SKULL_SHADOW_COLOR := Color(0.04, 0.04, 0.04, 1.0)

@onready var _glow: TextureRect = $Glow
@onready var _stage1: TextureRect = $SkullStage1
@onready var _stage2: TextureRect = $SkullStage2
@onready var _stage3: TextureRect = $SkullStage3

var _fill: float = 0.0
var _hovering := false
var _pressing := false
var _base_scale := Vector2.ONE
var _shake_tween: Tween
var _press_tween: Tween
var _first_spin_hint := false
var _full_face_locked := false
var _full_face_lifted := false
var _drop_shadow: Control
var _rest_position := Vector2.ZERO
var _rest_scale := Vector2.ONE
var _motion_locks := 0
var _flame_crown: ColorRect
var _flame_crown_on := false
var _flame_frame := 0.0
var _flame_count := 1
var _flame_ink_top := 0.0
var _flame_ink_bottom := 1.0


func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_scale = scale
	pivot_offset = size * 0.5
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if _glow != null:
		_glow.visible = false
		_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for stage in [_stage1, _stage2, _stage3]:
		if stage != null:
			stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage.pivot_offset = stage.size * 0.5
	set_fill(preview_fill)
	_ensure_drop_shadow()
	_ensure_flame_crown()
	_apply_flame_crown_visible()
	set_process(true)


func _process(delta: float) -> void:
	_advance_flame_crown(delta)
	_push_shadow_live()
	if _pressing:
		return
	var t := float(Time.get_ticks_msec()) * 0.001
	var wobble := 0.035
	if _first_spin_hint and not _reduce_flashing():
		wobble = 0.07
	rotation = sin(t * 0.65) * wobble


func set_first_spin_hint(on: bool) -> void:
	_first_spin_hint = on
	_apply_fill_feel()


func set_flame_crown(on: bool) -> void:
	_flame_crown_on = on
	if not is_node_ready():
		return
	_ensure_flame_crown()
	_apply_flame_crown_visible()


func _apply_flame_crown_visible() -> void:
	if _flame_crown == null:
		return
	_flame_crown.visible = _flame_crown_on
	if _flame_crown_on and _reduce_flashing():
		_flame_frame = 0.0
		_apply_flame_frame()


func _ensure_flame_crown() -> void:
	if _flame_crown != null and is_instance_valid(_flame_crown):
		return
	var image := _load_flame_crown_image()
	if image == null:
		return
	var rect := ColorRect.new()
	rect.name = "FreeSpinFlameCrown"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.color = Color(1, 1, 1, 1)
	rect.position = FLAME_CROWN_POS
	rect.size = FLAME_CROWN_SIZE
	rect.visible = false
	add_child(rect)
	if _glow != null:
		move_child(rect, _glow.get_index() + 1)
	else:
		move_child(rect, 0)
	var mat := ShaderMaterial.new()
	mat.shader = FLAME_CROWN_SHADER
	mat.set_shader_parameter("sheet", ImageTexture.create_from_image(image))
	mat.set_shader_parameter("frame", 0.0)
	mat.set_shader_parameter("frame_count", float(_flame_count))
	mat.set_shader_parameter("copies", FLAME_CROWN_COPIES)
	mat.set_shader_parameter("thin", FLAME_CROWN_THIN)
	mat.set_shader_parameter("arc", FLAME_CROWN_ARC)
	mat.set_shader_parameter("ink_top", _flame_ink_top)
	mat.set_shader_parameter("ink_bottom", _flame_ink_bottom)
	rect.material = mat
	_flame_crown = rect


func _advance_flame_crown(delta: float) -> void:
	if _flame_crown == null or not _flame_crown.visible:
		return
	if _reduce_flashing():
		if _flame_frame != 0.0:
			_flame_frame = 0.0
			_apply_flame_frame()
		return
	if _flame_count <= 1:
		return
	_flame_frame += delta * FLAME_CROWN_FPS
	var span := float(_flame_count)
	if _flame_frame >= span:
		_flame_frame = fmod(_flame_frame, span)
	_apply_flame_frame()


func _apply_flame_frame() -> void:
	if _flame_crown == null:
		return
	var mat := _flame_crown.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("frame", _flame_frame)


func _load_flame_crown_image() -> Image:
	if not ResourceLoader.exists(FLAME_CROWN_SHEET):
		return null
	var src := load(FLAME_CROWN_SHEET) as Texture2D
	if src == null:
		return null
	var image := src.get_image()
	if image == null:
		return null
	if image.is_compressed():
		image.decompress()
	image = _punch_black(image)
	_flame_count = _flame_count_for(image)
	_measure_flame_ink(image)
	return image


func _flame_count_for(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return 1
	if width % height == 0:
		return maxi(int(width / float(height)), 1)
	var runs := 0
	var in_ink := false
	for x in width:
		var ink := false
		for y in height:
			if image.get_pixel(x, y).a > 0.1:
				ink = true
				break
		if ink and not in_ink:
			runs += 1
			in_ink = true
		elif not ink:
			in_ink = false
	if runs >= 2 and width % runs == 0:
		return runs
	return maxi(runs, 1)


func _measure_flame_ink(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var top := height
	var bottom := -1
	for y in height:
		var ink := false
		for x in width:
			if image.get_pixel(x, y).a > 0.1:
				ink = true
				break
		if not ink:
			continue
		if y < top:
			top = y
		if y > bottom:
			bottom = y
	if bottom < top or height <= 0:
		_flame_ink_top = 0.0
		_flame_ink_bottom = 1.0
		return
	_flame_ink_top = float(top) / float(height)
	_flame_ink_bottom = float(bottom + 1) / float(height)


func _punch_black(image: Image) -> Image:
	var copy := image.duplicate() as Image
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	for y in copy.get_height():
		for x in copy.get_width():
			var pixel := copy.get_pixel(x, y)
			if pixel.r <= PUNCH_BLACK and pixel.g <= PUNCH_BLACK and pixel.b <= PUNCH_BLACK:
				copy.set_pixel(x, y, Color(0, 0, 0, 0))
	return copy


func _reduce_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))


func set_full_face_locked(on: bool) -> void:
	if _full_face_locked == on:
		return
	_full_face_locked = on
	_apply_full_face_lift(on)
	_apply_stage_visibility()
	_apply_fill_feel()


func _apply_full_face_lift(on: bool) -> void:
	if on == _full_face_lifted:
		return
	var delta := -FULL_FACE_LIFT if on else FULL_FACE_LIFT
	offset_top += delta
	offset_bottom += delta
	_full_face_lifted = on


func set_fill(f: float) -> void:
	_fill = clampf(f, 0.0, 1.0)
	_apply_stage_visibility()
	if not _full_face_locked:
		_apply_fill_feel()


func _apply_stage_visibility() -> void:
	var stage_idx := 2 if _full_face_locked else _stage_index_for_fill(_fill)
	if _stage1 != null:
		_stage1.visible = stage_idx == 0
	if _stage2 != null:
		_stage2.visible = stage_idx == 1
	if _stage3 != null:
		_stage3.visible = stage_idx == 2
	_ensure_drop_shadow()


func _visible_stage() -> TextureRect:
	if _stage3 != null and _stage3.visible:
		return _stage3
	if _stage2 != null and _stage2.visible:
		return _stage2
	return _stage1


func _ensure_drop_shadow() -> void:
	var stage := _visible_stage()
	if stage == null:
		return
	if _drop_shadow == null or not is_instance_valid(_drop_shadow):
		var made := HudDropShadowScript.attach_beside(stage) as Control
		if made != null:
			_drop_shadow = made
	elif _drop_shadow.has_method("set_art"):
		_drop_shadow.set_art(stage)
	if _drop_shadow != null and is_instance_valid(_drop_shadow) and _drop_shadow.has_method("set_color"):
		_drop_shadow.call("set_color", SKULL_SHADOW_COLOR)
	if _motion_locks == 0:
		_rest_position = position
		_rest_scale = scale
	_push_shadow_live()


func _remember_rest() -> void:
	if _motion_locks > 0:
		return
	_rest_position = position
	_rest_scale = scale
	_push_shadow_live()


func _push_shadow_live() -> void:
	var stage := _visible_stage()
	if stage == null or _drop_shadow == null or not is_instance_valid(_drop_shadow):
		return
	if not _drop_shadow.has_method("set_locked_global"):
		return
	var xform := stage.get_global_transform()
	_drop_shadow.call("set_locked_global", xform, SKULL_SHADOW_OFFSET)


func _lock_motion() -> void:
	if _motion_locks == 0:
		_remember_rest()
	_motion_locks += 1


func _unlock_motion() -> void:
	_motion_locks = maxi(_motion_locks - 1, 0)
	if _motion_locks == 0:
		position = _rest_position
		_remember_rest()


func _stage_index_for_fill(f: float) -> int:
	if f >= STAGE_THRESHOLDS[3] - 0.0001:
		return 2
	if f >= STAGE_THRESHOLDS[2]:
		return 1
	return 0


func _apply_fill_feel() -> void:
	var target_scale := _base_scale
	var glow_on := false
	var glow_alpha := 0.0
	var shake_amp := 0.0
	var shake_count := 0
	var shown := 1.0 if _full_face_locked else _fill

	if shown >= STAGE_THRESHOLDS[3] - 0.0001:
		target_scale = _base_scale * FILL_SCALE_FULL
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 6.0
		shake_count = 8
	elif shown >= STAGE_THRESHOLDS[2]:
		target_scale = _base_scale * FILL_SCALE_2_3
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 4.0
		shake_count = 5
	elif shown >= STAGE_THRESHOLDS[1]:
		target_scale = _base_scale * FILL_SCALE_1_3
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA * 0.85

	if _hovering and not _pressing:
		target_scale *= HOVER_SCALE
		glow_on = true
		glow_alpha = maxf(glow_alpha, GLOW_HOVER_ALPHA)
	elif _pressing:
		target_scale *= PRESS_SCALE

	if _first_spin_hint and not _reduce_flashing():
		glow_on = true
		glow_alpha = maxf(glow_alpha, GLOW_HOVER_ALPHA)

	scale = target_scale
	_remember_rest()
	_set_glow(glow_on, glow_alpha)

	if shake_amp > 0.0 and not _pressing:
		_play_shake(shake_amp, shake_count)


func _set_glow(on: bool, alpha: float) -> void:
	if _glow == null:
		return
	_glow.visible = on
	if on:
		_glow.modulate = Color(1.0, 1.0, 1.0, alpha)
		_glow.scale = Vector2(OUTLINE_SCALE, OUTLINE_SCALE)
		_glow.pivot_offset = _glow.size * 0.5
		_glow.position = (_glow.size * (1.0 - OUTLINE_SCALE)) * 0.5
	else:
		_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_glow.scale = Vector2.ONE
		_glow.position = Vector2.ZERO


func _play_shake(amplitude: float, pulses: int) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		_unlock_motion()
	_lock_motion()
	var origin := _rest_position
	_shake_tween = CombatPace.bind(create_tween())
	for i in range(pulses):
		var dir := 1.0 if (i % 2) == 0 else -1.0
		_shake_tween.tween_property(self, "position", origin + Vector2(dir * amplitude, 0.0), 0.03)
	_shake_tween.tween_property(self, "position", origin, 0.04)
	_shake_tween.finished.connect(_unlock_motion, CONNECT_ONE_SHOT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		if _motion_locks == 0:
			_remember_rest()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressing = true
			_apply_fill_feel()
			_play_press_jitter()
			accept_event()
		else:
			if _pressing:
				_pressing = false
				_apply_fill_feel()
				pressed.emit()
				accept_event()


func _play_press_jitter() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
		_unlock_motion()
	_lock_motion()
	var origin := _rest_position
	_press_tween = create_tween()
	_press_tween.tween_property(self, "position", origin + Vector2(3.0, 2.0), 0.03)
	_press_tween.tween_property(self, "position", origin + Vector2(-2.0, -1.0), 0.03)
	_press_tween.tween_property(self, "position", origin, 0.04)
	_press_tween.finished.connect(_unlock_motion, CONNECT_ONE_SHOT)


func _on_mouse_entered() -> void:
	_hovering = true
	_apply_fill_feel()


func _on_mouse_exited() -> void:
	_hovering = false
	_pressing = false
	_apply_fill_feel()
