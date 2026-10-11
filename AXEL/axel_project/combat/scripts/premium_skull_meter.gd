extends Control

signal pressed

@export_range(0.0, 1.0, 0.01) var preview_fill: float = 0.0

const STAGE_THRESHOLDS := [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
const FILL_SCALE_1_3 := 1.08
const FILL_SCALE_2_3 := 1.1
const FILL_SCALE_FULL := 1.067
const FULL_FACE_LIFT := 70.0
const GLOW_HOVER_ALPHA := 0.45
const GLOW_FILL_ALPHA := 0.55
const HudDropShadowScript := preload("res://combat/scripts/hud_drop_shadow.gd")
const FLAME_CROWN_SHEET := "res://assets/sprites/combat/flame_6_48x48.png"
const FLAME_CROWN_SHADER := preload("res://combat/shaders/flame_crown.gdshader")
const FLAME_CROWN_FPS := 10.0
const FLAME_CROWN_COPIES := 6.0
const FLAME_CROWN_THIN := 0.56
const FLAME_CROWN_ARC := 0.41
const FLAME_CROWN_POS := Vector2(-46.0, -97.0)
const FLAME_CROWN_SIZE := Vector2(780.0, 400.0)
const FLAME_DIM_BORDER := 14.0
const PUNCH_BLACK := 0.08
const SKULL_SHADOW_OFFSET := Vector2(-4.0, 5.0)
const SKULL_SHADOW_COLOR := Color(0.04, 0.04, 0.04, 1.0)
const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const READY_HOVER_SCALE := 1.1
const BREATH_AMP := 0.03
const BREATH_SEC := 1.6
const HEART_SEC := 1.4
const HEART_SCALE := 0.025
const HEART_GLOW := 0.6
const BUSY_ALPHA := 0.5
const READY_FADE_SPEED := 7.0
const RIM_SCALE := 1.07
const RIM_COLOR := Color(1.0, 1.0, 1.0)
const RIM_HOVER_ALPHA := 0.85
const FLASH_TINT := Color(0.12, 0.12, 0.12)
const TILT_MAX := 0.105
const IDLE_NUDGE_SEC := 6.0
const NUDGE_CHIP_SEC := 1.6
const SHAKE_BOOST := 2.0
const CALM_PUNCH := 0.4
const MOUTH_POS := Vector2(346.0, 560.0)
const CROWN_POS := Vector2(346.0, 130.0)
const CHIP_POS := Vector2(96.0, 640.0)
const CHIP_SIZE := Vector2(500.0, 100.0)
const CHIP_FONT_SIZE := 88
const EMBER_COUNTS := [24, 40, 70]
const FIRE_EMBERS := 30

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
var _ready_to_spin := true
var _nudge_allowed := true
var _ready_mix := 1.0
var _fill_glow_alpha := 0.0
var _hover_scale := 1.0
var _punch := Vector2.ONE
var _jitter := Vector2.ZERO
var _flash := 0.0
var _glow_boost := 0.0
var _tilt := 0.0
var _idle_time := 0.0
var _fired := false
var _feel_started := false
var _chip_hold := 0.0
var _hover_tween: Tween
var _punch_tween: Tween
var _jitter_tween: Tween
var _flash_tween: Tween
var _boost_tween: Tween
var _chip_tween: Tween
var _burst: CPUParticles2D
var _press_point := Vector2.INF
var _stream: CPUParticles2D
var _chip: Label
var _rng := RandomNumberGenerator.new()
var _flame_dim_target: Control


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
	_ensure_embers()
	_ensure_chip()
	_rng.seed = 7331
	_feel_started = true
	set_process(true)


func _process(delta: float) -> void:
	_advance_flame_crown(delta)
	_tick_feel(delta)
	_apply_feel_layer()
	_push_shadow_live()
	if _pressing:
		return
	var t := float(Time.get_ticks_msec()) * 0.001
	var wobble := 0.035
	if _first_spin_hint and not _reduce_flashing():
		wobble = 0.07
	wobble *= lerpf(0.4, 1.0, _ready_mix)
	rotation = sin(t * 0.65) * wobble


func set_ready(on: bool, nudge_ok: bool = true) -> void:
	_nudge_allowed = nudge_ok
	if not nudge_ok:
		_idle_time = 0.0
	if _ready_to_spin == on:
		return
	_ready_to_spin = on
	_idle_time = 0.0
	_retarget_hover()
	if not on:
		_chip_hold = 0.0
		_show_chip(false)


func is_ready_to_spin() -> bool:
	return _ready_to_spin and not _full_face_locked


func set_hovered(on: bool) -> void:
	if _hovering == on:
		return
	_hovering = on
	_idle_time = 0.0
	_retarget_hover()
	if on and is_ready_to_spin():
		if not _reduce_flashing():
			_play_jitter(6.0, 4, 0.03)
		_show_chip(true)
	elif not on and _chip_hold <= 0.0:
		_show_chip(false)


func set_pressed(on: bool) -> void:
	_idle_time = 0.0
	if on:
		_pressing = true
		_fired = false
		if is_ready_to_spin():
			var k := _punch_k()
			_tween_punch([[Vector2(1.0 + 0.08 * k, 1.0 - 0.14 * k), 0.05, Tween.TRANS_SINE]])
		else:
			_play_no_shake()
		return
	_pressing = false
	if not _fired:
		_tween_punch([[Vector2.ONE, 0.12, Tween.TRANS_BACK]])


func play_fire() -> void:
	_fired = true
	_idle_time = 0.0
	_chip_hold = 0.0
	_show_chip(false)
	var k := _punch_k()
	_tween_punch([[Vector2.ONE * (1.0 + 0.18 * k), 0.07, Tween.TRANS_SINE], [Vector2.ONE, 0.45, Tween.TRANS_ELASTIC]])
	_tween_boost(1.0, 0.4)
	if _reduce_flashing():
		return
	_tween_flash(1.0, 0.18)
	_play_jitter(5.0, 4, 0.025)
	var at := _press_point if _press_point.is_finite() else size * 0.5
	_press_point = Vector2.INF
	_emit_burst(FIRE_EMBERS, at)


func play_gulp(sections: int) -> void:
	var k := _punch_k()
	_tween_punch([[Vector2.ONE * (1.0 + 0.25 * k), 0.08, Tween.TRANS_SINE], [Vector2.ONE, 0.55, Tween.TRANS_ELASTIC]])
	_tween_boost(0.6 if _reduce_flashing() else 1.0, 0.7)
	if _reduce_flashing():
		return
	_tween_flash(0.6, 0.25)
	_emit_burst(int(EMBER_COUNTS[clampi(sections - 1, 0, EMBER_COUNTS.size() - 1)]))


func play_nudge() -> void:
	var k := _punch_k()
	_tween_punch([[Vector2.ONE * (1.0 + 0.12 * k), 0.1, Tween.TRANS_SINE], [Vector2.ONE, 0.35, Tween.TRANS_BACK]])
	_chip_hold = NUDGE_CHIP_SEC
	_show_chip(true)
	if _reduce_flashing():
		return
	_play_jitter(7.0, 6, 0.035)
	_tween_boost(0.8, 0.5)


func note_input() -> void:
	_idle_time = 0.0


func _punch_k() -> float:
	return CALM_PUNCH if _reduce_flashing() else 1.0


func _tick_feel(delta: float) -> void:
	var want := 1.0 if (_ready_to_spin or _full_face_locked) else 0.0
	_ready_mix = move_toward(_ready_mix, want, delta * READY_FADE_SPEED)
	var tilt_target := 0.0
	if _hovering and is_ready_to_spin():
		var rect := get_global_rect()
		var half := maxf(rect.size.x * 0.5, 1.0)
		var dx := get_global_mouse_position().x - rect.get_center().x
		tilt_target = clampf(dx / half, -1.0, 1.0) * TILT_MAX
	_tilt = lerpf(_tilt, tilt_target, clampf(delta * 10.0, 0.0, 1.0))
	if _chip_hold > 0.0:
		_chip_hold -= delta
		if _chip_hold <= 0.0 and not _hovering:
			_show_chip(false)
	if is_ready_to_spin() and _nudge_allowed and not _hovering and not _pressing:
		_idle_time += delta
		if _idle_time >= IDLE_NUDGE_SEC:
			_idle_time = 0.0
			play_nudge()
	else:
		_idle_time = 0.0
	if _stream != null:
		var want_stream := _shown_sections() >= 3 and not _reduce_flashing() and is_visible_in_tree()
		if _stream.emitting != want_stream:
			_stream.emitting = want_stream


func _apply_feel_layer() -> void:
	var t := float(Time.get_ticks_msec()) * 0.001
	var calm := _reduce_flashing()
	var breath_amp := BREATH_AMP * (0.5 if calm else 1.0) * _ready_mix
	var heart := 0.0 if calm else _heartbeat(t) * _ready_mix
	var s := _punch * _hover_scale * (1.0 + sin(t * TAU / BREATH_SEC) * breath_amp + heart * HEART_SCALE)
	var alpha := lerpf(BUSY_ALPHA, 1.0, _ready_mix)
	var tint := Color.WHITE.lerp(FLASH_TINT, clampf(_flash, 0.0, 1.0))
	tint.a = alpha
	for stage in [_stage1, _stage2, _stage3]:
		if stage == null:
			continue
		stage.pivot_offset = stage.size * 0.5
		stage.scale = s
		stage.rotation = _tilt
		stage.position = _jitter
		stage.modulate = tint
	if _drop_shadow != null and is_instance_valid(_drop_shadow):
		_drop_shadow.modulate.a = alpha
	if _glow == null:
		return
	var ga := maxf(_fill_glow_alpha, heart * HEART_GLOW)
	if _hovering and is_ready_to_spin():
		ga = maxf(ga, RIM_HOVER_ALPHA)
	ga = maxf(ga, _glow_boost) * alpha
	_glow.visible = ga > 0.01
	if not _glow.visible:
		return
	var shown := _visible_stage()
	if shown != null and _glow.texture != shown.texture:
		_glow.texture = shown.texture
	_glow.pivot_offset = _glow.size * 0.5
	_glow.scale = s * RIM_SCALE
	_glow.rotation = _tilt
	_glow.position = _jitter
	_glow.modulate = Color(RIM_COLOR.r, RIM_COLOR.g, RIM_COLOR.b, clampf(ga, 0.0, 1.0))


func _heartbeat(t: float) -> float:
	var period := HEART_SEC * (0.5 if _shown_sections() >= 3 else 1.0)
	var phase := fmod(t, period) / period
	var first := maxf(0.0, 1.0 - absf(phase - 0.06) / 0.06)
	var second := maxf(0.0, 1.0 - absf(phase - 0.24) / 0.06) * 0.7
	return maxf(first, second)


func _shown_sections() -> int:
	if _full_face_locked:
		return 3
	return clampi(roundi(_fill * 3.0), 0, 3)


func _retarget_hover() -> void:
	var target := READY_HOVER_SCALE if (_hovering and is_ready_to_spin()) else 1.0
	if _reduce_flashing():
		target = lerpf(1.0, target, 0.5)
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = CombatPace.bind(create_tween())
	if target > _hover_scale:
		_hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_hover_tween.tween_property(self, "_hover_scale", target, 0.18)
	else:
		_hover_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_hover_tween.tween_property(self, "_hover_scale", target, 0.14)


func _tween_punch(steps: Array) -> void:
	if _punch_tween != null and _punch_tween.is_valid():
		_punch_tween.kill()
	_punch_tween = CombatPace.bind(create_tween())
	for step in steps:
		_punch_tween.tween_property(self, "_punch", step[0], step[1]).set_trans(step[2]).set_ease(Tween.EASE_OUT)


func _tween_flash(peak: float, seconds: float) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash = peak
	_flash_tween = CombatPace.bind(create_tween())
	_flash_tween.tween_property(self, "_flash", 0.0, seconds)


func _tween_boost(peak: float, seconds: float) -> void:
	if _boost_tween != null and _boost_tween.is_valid():
		_boost_tween.kill()
	_glow_boost = peak
	_boost_tween = CombatPace.bind(create_tween())
	_boost_tween.tween_property(self, "_glow_boost", 0.0, seconds).set_ease(Tween.EASE_IN)


func _play_jitter(amp: float, steps: int, step_sec: float) -> void:
	if _jitter_tween != null and _jitter_tween.is_valid():
		_jitter_tween.kill()
	_jitter_tween = CombatPace.bind(create_tween())
	for i in steps:
		var kick := Vector2(_rng.randf_range(-amp, amp), _rng.randf_range(-amp, amp) * 0.5)
		_jitter_tween.tween_property(self, "_jitter", kick, step_sec)
	_jitter_tween.tween_property(self, "_jitter", Vector2.ZERO, step_sec)


func _play_no_shake() -> void:
	if _jitter_tween != null and _jitter_tween.is_valid():
		_jitter_tween.kill()
	_jitter_tween = CombatPace.bind(create_tween())
	for i in 3:
		_jitter_tween.tween_property(self, "_jitter", Vector2(5.0, 0.0), 0.03)
		_jitter_tween.tween_property(self, "_jitter", Vector2(-5.0, 0.0), 0.03)
	_jitter_tween.tween_property(self, "_jitter", Vector2.ZERO, 0.03)


func _ensure_embers() -> void:
	if _burst == null or not is_instance_valid(_burst):
		_burst = _make_embers("SkullEmberBurst")
		_burst.one_shot = true
		_burst.explosiveness = 0.95
		_burst.lifetime = 0.9
		_burst.amount = FIRE_EMBERS
		_burst.position = MOUTH_POS
		_burst.direction = Vector2(0.0, -1.0)
		_burst.spread = 75.0
		_burst.initial_velocity_min = 380.0
		_burst.initial_velocity_max = 820.0
		_burst.gravity = Vector2(0.0, 1100.0)
		_burst.scale_amount_min = 8.0
		_burst.scale_amount_max = 18.0
		add_child(_burst)
	if _stream == null or not is_instance_valid(_stream):
		_stream = _make_embers("SkullEmberStream")
		_stream.amount = 16
		_stream.lifetime = 1.8
		_stream.position = CROWN_POS
		_stream.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_stream.emission_rect_extents = Vector2(220.0, 20.0)
		_stream.direction = Vector2(0.0, -1.0)
		_stream.spread = 20.0
		_stream.initial_velocity_min = 90.0
		_stream.initial_velocity_max = 200.0
		_stream.gravity = Vector2(0.0, -60.0)
		_stream.scale_amount_min = 6.0
		_stream.scale_amount_max = 12.0
		add_child(_stream)
		if _glow != null:
			move_child(_stream, _glow.get_index())


func _make_embers(node_name: String) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = node_name
	p.emitting = false
	p.local_coords = false
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.02, 0.02, 0.02, 1.0))
	ramp.set_color(1, Color(0.35, 0.35, 0.35, 0.0))
	p.color_ramp = ramp
	return p


func _emit_burst(count: int, at: Vector2 = MOUTH_POS) -> void:
	_ensure_embers()
	if _burst == null:
		return
	_burst.position = at
	_burst.amount = maxi(count, 1)
	_burst.restart()
	_burst.emitting = true


func burst_amount() -> int:
	return _burst.amount if _burst != null else 0


func _ensure_chip() -> void:
	if _chip != null and is_instance_valid(_chip):
		return
	var lab := Label.new()
	lab.name = "SkullSpinChip"
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.position = CHIP_POS
	lab.size = CHIP_SIZE
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.autowrap_mode = TextServer.AUTOWRAP_OFF
	lab.add_theme_font_override("font", VT323_FONT)
	lab.add_theme_font_size_override("font_size", CHIP_FONT_SIZE)
	lab.add_theme_color_override("font_color", Color(0.03, 0.03, 0.03))
	lab.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	lab.add_theme_constant_override("outline_size", 14)
	lab.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.6))
	lab.add_theme_constant_override("shadow_offset_x", -4)
	lab.add_theme_constant_override("shadow_offset_y", 5)
	lab.text = "[%s] SPIN" % _spin_key_name()
	lab.modulate = Color(1.0, 1.0, 1.0, 0.0)
	lab.visible = false
	add_child(lab)
	_chip = lab


func _spin_key_name() -> String:
	if not InputMap.has_action("interact"):
		return "E"
	for ev in InputMap.action_get_events("interact"):
		var key := ev as InputEventKey
		if key == null:
			continue
		var text := key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
		if not text.is_empty():
			return text.to_upper()
	return "E"


func _show_chip(on: bool) -> void:
	_ensure_chip()
	if _chip == null:
		return
	if _chip_tween != null and _chip_tween.is_valid():
		_chip_tween.kill()
	_chip_tween = CombatPace.bind(create_tween())
	if on:
		_chip.visible = true
		_chip_tween.tween_property(_chip, "modulate:a", 1.0, 0.12)
	else:
		_chip_tween.tween_property(_chip, "modulate:a", 0.0, 0.12)
		_chip_tween.tween_callback(_chip.hide)


func is_chip_showing() -> bool:
	return _chip != null and _chip.visible


func set_first_spin_hint(on: bool) -> void:
	_first_spin_hint = on
	_apply_fill_feel()


func set_flame_crown(on: bool) -> void:
	_flame_crown_on = on
	if not is_node_ready():
		return
	_ensure_flame_crown()
	_apply_flame_crown_visible()


func set_flame_dim_target(target: Control) -> void:
	_flame_dim_target = target


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
	_apply_flame_dim()
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


func _apply_flame_dim() -> void:
	var mat := _flame_crown.material as ShaderMaterial
	if mat == null:
		return
	if _flame_dim_target == null or not is_instance_valid(_flame_dim_target) or not _flame_dim_target.is_visible_in_tree():
		mat.set_shader_parameter("dim_on", 0.0)
		return
	var inner := _flame_dim_target.get_global_rect()
	var outer := inner.grow(FLAME_DIM_BORDER)
	mat.set_shader_parameter("dim_on", 1.0)
	mat.set_shader_parameter("dim_inner", _flame_local_box(inner))
	mat.set_shader_parameter("dim_outer", _flame_local_box(outer))


func _flame_local_box(global_rect: Rect2) -> Vector4:
	var inv := _flame_crown.get_global_transform().affine_inverse()
	var a := inv * global_rect.position
	var b := inv * (global_rect.position + Vector2(global_rect.size.x, 0.0))
	var c := inv * (global_rect.position + Vector2(0.0, global_rect.size.y))
	var d := inv * global_rect.end
	return Vector4(
		minf(minf(a.x, b.x), minf(c.x, d.x)),
		minf(minf(a.y, b.y), minf(c.y, d.y)),
		maxf(maxf(a.x, b.x), maxf(c.x, d.x)),
		maxf(maxf(a.y, b.y), maxf(c.y, d.y))
	)


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
	var before := _shown_sections()
	_fill = clampf(f, 0.0, 1.0)
	_apply_stage_visibility()
	if not _full_face_locked:
		_apply_fill_feel()
	var after := _shown_sections()
	if _feel_started and after > before:
		play_gulp(after)


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
	var glow_alpha := 0.0
	var shake_amp := 0.0
	var shake_count := 0
	var shown := 1.0 if _full_face_locked else _fill

	if shown >= STAGE_THRESHOLDS[3] - 0.0001:
		target_scale = _base_scale * FILL_SCALE_FULL
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 6.0
		shake_count = 8
	elif shown >= STAGE_THRESHOLDS[2]:
		target_scale = _base_scale * FILL_SCALE_2_3
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 4.0
		shake_count = 5
	elif shown >= STAGE_THRESHOLDS[1]:
		target_scale = _base_scale * FILL_SCALE_1_3
		glow_alpha = GLOW_FILL_ALPHA * 0.85

	if _first_spin_hint and not _reduce_flashing():
		glow_alpha = maxf(glow_alpha, GLOW_HOVER_ALPHA)

	scale = target_scale
	_remember_rest()
	_fill_glow_alpha = glow_alpha

	if shake_amp > 0.0 and not _pressing:
		if not _reduce_flashing():
			shake_amp *= SHAKE_BOOST
		_play_shake(shake_amp, shake_count)


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
			_press_point = mb.position
			set_pressed(true)
			_play_press_jitter()
			accept_event()
		else:
			if _pressing:
				set_pressed(false)
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
	set_hovered(true)


func _on_mouse_exited() -> void:
	_press_point = Vector2.INF
	set_pressed(false)
	set_hovered(false)
