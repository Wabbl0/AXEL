extends CanvasLayer

const SHADER := preload("res://combat/shaders/tutorial_cell_glow.gdshader")
const GLOW_LAYER := 108
const PAD_RATIO := 0.35
const PULSE_SEC := 1.6
const FADE_IN_SEC := 0.35
const FADE_OUT_SEC := 0.5
const STEADY_PULSE := 0.5

var _host: Control
var _glows: Array[TextureRect] = []
var _arts: Array[TextureRect] = []
var _alpha := 0.0
var _target := 0.0
var _clock := 0.0
var _steady := false


func _ready() -> void:
	layer = GLOW_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_host = Control.new()
	_host.name = "CellGlowHost"
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_cells(arts: Array[TextureRect], steady: bool) -> void:
	_clear()
	_steady = steady
	_clock = 0.0
	for art in arts:
		if art == null or not is_instance_valid(art) or art.texture == null:
			continue
		var glow := TextureRect.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.texture = art.texture
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		glow.material = mat
		_host.add_child(glow)
		_glows.append(glow)
		_arts.append(art)
	_target = 1.0
	_sync()


func hide_cells() -> void:
	_target = 0.0


func is_showing() -> bool:
	return _target > 0.0 and not _glows.is_empty()


func _clear() -> void:
	for glow in _glows:
		if is_instance_valid(glow):
			glow.queue_free()
	_glows.clear()
	_arts.clear()
	_alpha = 0.0


func _process(delta: float) -> void:
	if _glows.is_empty():
		return
	_clock += delta
	var step := delta / (FADE_IN_SEC if _target > _alpha else FADE_OUT_SEC)
	_alpha = move_toward(_alpha, _target, step)
	if _alpha <= 0.0 and _target <= 0.0:
		_clear()
		return
	_sync()


func _sync() -> void:
	var pulse := STEADY_PULSE if _steady else 0.5 - 0.5 * cos(_clock * TAU / PULSE_SEC)
	var shown := smoothstep(0.0, 1.0, _alpha)
	for i in _glows.size():
		var glow := _glows[i]
		var art := _arts[i]
		if not is_instance_valid(glow):
			continue
		if art == null or not is_instance_valid(art) or not art.is_visible_in_tree():
			glow.visible = false
			continue
		var drawn := _drawn_rect(art)
		var xform := art.get_global_transform_with_canvas()
		var scale_now := xform.get_scale()
		var origin := xform.origin + Vector2(drawn.position.x * absf(scale_now.x), drawn.position.y * absf(scale_now.y))
		var art_size := Vector2(drawn.size.x * absf(scale_now.x), drawn.size.y * absf(scale_now.y))
		if art_size.x < 2.0 or art_size.y < 2.0:
			glow.visible = false
			continue
		var pad := art_size * PAD_RATIO
		var full := art_size + pad * 2.0
		glow.visible = true
		glow.position = origin - pad
		glow.size = full
		glow.modulate = Color(1, 1, 1, shown)
		var mat := glow.material as ShaderMaterial
		mat.set_shader_parameter("pad_uv", pad / full)
		mat.set_shader_parameter("reach", pad * 0.9 / art_size)
		mat.set_shader_parameter("pulse", pulse)


func _drawn_rect(art: TextureRect) -> Rect2:
	var full := Rect2(Vector2.ZERO, art.size)
	var tex_size := art.texture.get_size() if art.texture != null else Vector2.ZERO
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return full
	if art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED or art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT:
		var fit := minf(art.size.x / tex_size.x, art.size.y / tex_size.y)
		var drawn := tex_size * fit
		if art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT:
			return Rect2(Vector2.ZERO, drawn)
		return Rect2((art.size - drawn) * 0.5, drawn)
	return full
