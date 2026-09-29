extends TextureRect

# Screen pixels. The free-spin bars use this same shift and softness.
const COLOR := Color(0.22, 0.22, 0.22, 1.0)
const OFFSET := Vector2(2.0, 3.0)
const SHADER := preload("res://combat/shaders/piece_drop_shadow.gdshader")
const SELF_PATH := "res://combat/scripts/hud_drop_shadow.gd"

var _art: TextureRect


static func softness_px(art_scale: float) -> int:
	return maxi(2, int(round(4.0 * art_scale)))


static func attach_beside(art: TextureRect) -> TextureRect:
	if art == null:
		return null
	var canvas := _canvas_of(art)
	if canvas == null:
		return null
	var shadow_name := "DropShadow_" + _piece_key(art)
	var existing := canvas.get_node_or_null(shadow_name) as TextureRect
	if existing != null and existing.has_method("set_art"):
		existing.call("set_art", art)
		return existing
	if not canvas.is_node_ready():
		canvas.ready.connect(func() -> void: attach_beside(art), CONNECT_ONE_SHOT)
		return null
	var shadow := _make()
	shadow.name = shadow_name
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	canvas.add_child(shadow)
	if shadow.get_parent() != canvas:
		shadow.free()
		return null
	var plate := canvas.get_node_or_null("HudArt")
	if plate != null:
		canvas.move_child(shadow, plate.get_index() + 1)
	shadow.call("setup", art)
	return shadow


static func _make() -> TextureRect:
	return (load(SELF_PATH) as GDScript).new() as TextureRect


static func _canvas_of(node: Node) -> Control:
	var current := node
	while current != null:
		if current.name == "HudCanvas" and current is Control:
			return current as Control
		current = current.get_parent()
	return null


static func _piece_key(art: Node) -> String:
	var current := art
	while current != null:
		if str(current.name).begins_with("NEW_"):
			return str(current.name)
		current = current.get_parent()
	return str(art.name)


func setup(art: TextureRect) -> void:
	_art = art
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	modulate = Color(1, 1, 1, 1)
	show_behind_parent = false
	z_index = 0
	clip_contents = false
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("shadow_color", COLOR)
	material = mat
	set_process(true)
	_sync()


func set_art(art: TextureRect) -> void:
	_art = art
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	if _art == null or not is_instance_valid(_art):
		visible = false
		return
	if _art.size.x < 2.0 or _art.size.y < 2.0:
		visible = false
		return
	var canvas := _canvas_of(self)
	if canvas == null:
		visible = false
		return
	visible = true
	var rel := canvas.get_global_transform().affine_inverse() * _art.get_global_transform()
	var origin := rel * Vector2.ZERO
	var scale_now := rel.get_scale()
	var local_size := Vector2(_art.size.x * absf(scale_now.x), _art.size.y * absf(scale_now.y))
	var canvas_scale := _parent_scale()
	var screen_soft := float(softness_px(maxf(canvas_scale.x, 0.01)))
	var pad := Vector2(screen_soft / canvas_scale.x, screen_soft / canvas_scale.y)
	var off := Vector2(OFFSET.x / canvas_scale.x, OFFSET.y / canvas_scale.y)
	_place(origin + off - pad, local_size + pad * 2.0)
	texture = _art.texture
	var mat := material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("art_size_px", local_size)
	mat.set_shader_parameter("pad_px", pad)
	mat.set_shader_parameter("blur_px", maxf(pad.x, pad.y))
	mat.set_shader_parameter("shadow_color", COLOR)


func _place(rect_pos: Vector2, rect_size: Vector2) -> void:
	@warning_ignore("int_as_enum_without_cast")
	@warning_ignore("int_as_enum_without_match")
	layout_mode = 0
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = rect_pos
	size = rect_size


func _parent_scale() -> Vector2:
	var parent := get_parent() as CanvasItem
	if parent == null:
		return Vector2.ONE
	var scale_now := parent.get_global_transform().get_scale()
	return Vector2(maxf(absf(scale_now.x), 0.01), maxf(absf(scale_now.y), 0.01))
