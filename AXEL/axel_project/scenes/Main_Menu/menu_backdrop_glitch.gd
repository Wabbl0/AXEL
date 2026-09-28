extends TextureRect

const QUIET_MIN_SEC := 10.0
const QUIET_MAX_SEC := 30.0
const BURST_SEC := 0.85

const _SHADER := preload("res://scenes/Main_Menu/menu_backdrop_glitch.gdshader")

var _mat: ShaderMaterial
var _wait_left := 0.0
var _burst_left := 0.0
var _seed := 0.0


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = _SHADER
	material = _mat
	_set_quiet()
	_schedule()


func _process(delta: float) -> void:
	if _burst_left > 0.0:
		if _fx_blocked():
			_burst_left = 0.0
			_set_quiet()
			_schedule()
			return
		_burst_left = maxf(_burst_left - delta, 0.0)
		if _burst_left <= 0.0:
			_set_quiet()
			_schedule()
			return
		_paint_burst()
		return
	if _fx_blocked():
		return
	_wait_left -= delta
	if _wait_left <= 0.0:
		_begin_burst()
		_paint_burst()


func _schedule() -> void:
	_wait_left = randf_range(QUIET_MIN_SEC, QUIET_MAX_SEC)


func _begin_burst() -> void:
	_burst_left = BURST_SEC
	_seed = randf() * 997.0
	_mat.set_shader_parameter("seed", _seed)


func _paint_burst() -> void:
	var t := clampf(1.0 - (_burst_left / BURST_SEC), 0.0, 1.0)
	var tick := int(t * 24.0)
	var flicker := 0.5 if tick % 3 == 0 else 1.0
	var tail := 1.0
	if t > 0.82:
		tail = clampf((1.0 - t) / 0.18, 0.0, 1.0)
	_mat.set_shader_parameter("amount", flicker * tail * _intensity())
	_mat.set_shader_parameter("roll", lerpf(1.15, -0.15, t))


func _set_quiet() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("amount", 0.0)
	_mat.set_shader_parameter("roll", 1.5)


func _intensity() -> float:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null:
		return 1.0
	return clampf(float(settings.call("get_value", "access", "glitch_intensity", 1.0)), 0.0, 1.0)


func _fx_blocked() -> bool:
	if OS.has_environment("AXEL_DISABLE_EVENT_FX") and OS.get_environment("AXEL_DISABLE_EVENT_FX") == "1":
		return true
	if OS.has_environment("AXEL_DISABLE_POST_FX") and OS.get_environment("AXEL_DISABLE_POST_FX") == "1":
		return true
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null:
		return false
	if bool(settings.call("get_value", "access", "reduce_flashing", false)):
		return true
	return _intensity() <= 0.05
