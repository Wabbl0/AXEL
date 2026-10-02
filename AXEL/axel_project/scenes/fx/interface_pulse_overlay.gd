extends CanvasLayer

@onready var _filter_rect: ColorRect = $FilterRect

const LAYER := 112
const BASELINE_ALPHA := 0.20
const SURGE_ALPHA := 0.536
const _DEFAULT_DURATION := 1.1
const _FADE_IN := 0.12
const _FADE_OUT := 0.16

const _ROLL_CENTER_START := 1.25
const _ROLL_CENTER_END := -0.25
const _ROLL_TRAVEL_SPEED := 0.384

var _ambient_active := false
var _distortion_active := false
var _fade_tween: Tween
var _roll_tween: Tween
var _wave_roll := 0.42
var _wave_glitch_shift := 0.0045


func _ready() -> void:
	layer = LAYER
	_ensure_back_buffer_copy()
	_capture_wave_uniforms()
	_apply_rest_uniforms()
	visible = false
	_filter_rect.modulate.a = 0.0
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_wave_active() -> bool:
	return _distortion_active or wave_roll_amount() > 0.001


func wave_roll_amount() -> float:
	var mat := _wave_material()
	if mat == null:
		return 0.0
	return float(mat.get_shader_parameter("roll_amount"))


func _ensure_back_buffer_copy() -> void:


	var copy := get_node_or_null("BackBufferCopy") as BackBufferCopy
	if copy == null:
		copy = BackBufferCopy.new()
		copy.name = "BackBufferCopy"
		add_child(copy)
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	move_child(copy, 0)


func _rest_alpha() -> float:
	if _ambient_active:
		return BASELINE_ALPHA
	return 0.0


func start_ambient() -> void:
	_kill_fade_tween()
	_ambient_active = true
	if _distortion_active:
		return
	_apply_rest_uniforms()
	_filter_rect.modulate.a = BASELINE_ALPHA
	visible = true


func stop_ambient() -> void:
	_kill_fade_tween()
	_kill_roll_tween()
	_ambient_active = false
	_distortion_active = false
	_apply_rest_uniforms()
	_filter_rect.modulate.a = 0.0
	visible = false


func start_distortion(once: bool = false) -> void:
	_kill_fade_tween()
	_kill_roll_tween()
	_distortion_active = true
	_apply_wave_uniforms()
	if once:
		_play_roll_once()
	else:
		_set_roll_manual(false, _ROLL_CENTER_START)
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", SURGE_ALPHA, _FADE_IN)


func stop_distortion() -> void:
	_kill_fade_tween()
	_kill_roll_tween()
	_distortion_active = false
	_set_roll_manual(false, _ROLL_CENTER_START)
	_apply_rest_uniforms()
	var rest := _rest_alpha()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", rest, _FADE_OUT)
	await _fade_tween.finished
	visible = rest > 0.0


func play_pulse(duration_sec: float = _DEFAULT_DURATION) -> void:
	start_distortion(true)
	var hold := maxf(duration_sec, _roll_once_duration() + 0.05)
	await get_tree().create_timer(hold).timeout
	await stop_distortion()


func _capture_wave_uniforms() -> void:
	var mat := _wave_material()
	if mat == null:
		return
	_wave_roll = float(mat.get_shader_parameter("roll_amount"))
	_wave_glitch_shift = float(mat.get_shader_parameter("glitch_shift"))


func _apply_rest_uniforms() -> void:
	_set_roll_manual(false, _ROLL_CENTER_START)
	_set_wave_uniforms(0.0, 0.0)


func _play_roll_once() -> void:
	_set_roll_manual(true, _ROLL_CENTER_START)
	var duration := _roll_once_duration()
	_roll_tween = create_tween()
	_roll_tween.tween_method(_set_roll_center, _ROLL_CENTER_START, _ROLL_CENTER_END, duration)
	_roll_tween.tween_callback(_finish_roll_once)


func _roll_once_duration() -> float:
	return absf(_ROLL_CENTER_END - _ROLL_CENTER_START) / _ROLL_TRAVEL_SPEED


func _finish_roll_once() -> void:
	if not _distortion_active:
		return
	var mat := _wave_material()
	if mat == null:
		return
	mat.set_shader_parameter("roll_amount", 0.0)
	mat.set_shader_parameter("glitch_shift", 0.0)


func _set_roll_center(center: float) -> void:
	var mat := _wave_material()
	if mat == null:
		return
	mat.set_shader_parameter("roll_center", center)


func _set_roll_manual(enabled: bool, center: float) -> void:
	var mat := _wave_material()
	if mat == null:
		return
	mat.set_shader_parameter("roll_manual", 1.0 if enabled else 0.0)
	mat.set_shader_parameter("roll_center", center)


func _apply_wave_uniforms() -> void:
	_set_wave_uniforms(_wave_roll, _wave_glitch_shift)


func _set_wave_uniforms(roll: float, glitch_shift: float) -> void:
	var mat := _wave_material()
	if mat == null:
		return
	mat.set_shader_parameter("roll_amount", roll)
	mat.set_shader_parameter("glitch_shift", glitch_shift)


func _wave_material() -> ShaderMaterial:
	if _filter_rect == null or not is_instance_valid(_filter_rect):
		return null
	return _filter_rect.material as ShaderMaterial


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _kill_roll_tween() -> void:
	if _roll_tween != null and _roll_tween.is_valid():
		_roll_tween.kill()
	_roll_tween = null
