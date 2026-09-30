extends TextureRect

# Screen pixels. The free-spin bars use this same shift and softness.
const COLOR := Color(0.15, 0.15, 0.15, 1.0)
const OFFSET := Vector2(2.0, 3.0)
const SHADER := preload("res://combat/shaders/piece_drop_shadow.gdshader")
const SELF_PATH := "res://combat/scripts/hud_drop_shadow.gd"
const SHADOW_LAYER := 92

var _art: TextureRect
var _locked := false
var _locked_xform := Transform2D.IDENTITY
var _screen_offset := OFFSET
var _color := COLOR


static func softness_px(art_scale: float) -> int:
	return maxi(2, int(round(4.0 * art_scale)))


static func attach_beside(art: TextureRect) -> TextureRect:
	if art == null:
		return null
	var host := _shadow_host(art)
	if host == null:
		return null
	var shadow_name := "DropShadow_" + _piece_key(art)
	var existing := host.get_node_or_null(shadow_name) as TextureRect
	if existing != null and existing.has_method("set_art"):
		existing.call("set_art", art)
		return existing
	if not host.is_node_ready():
		host.ready.connect(func() -> void: attach_beside(art), CONNECT_ONE_SHOT)
		return null
	var shadow := _make()
	shadow.name = shadow_name
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	host.add_child(shadow)
	if shadow.get_parent() != host:
		shadow.free()
		return null
	shadow.call("setup", art)
	return shadow


static func _make() -> TextureRect:
	return (load(SELF_PATH) as GDScript).new() as TextureRect


static func _shadow_host(art: Node) -> Control:
	var root := _scene_root(art)
	if root == null:
		return null
	var layer := root.get_node_or_null("HudShadowLayer") as CanvasLayer
	if layer == null:
		if not root.is_node_ready():
			if not root.ready.is_connected(_attach_when_ready.bind(art)):
				root.ready.connect(_attach_when_ready.bind(art), CONNECT_ONE_SHOT)
			return null
		layer = CanvasLayer.new()
		layer.name = "HudShadowLayer"
		layer.layer = SHADOW_LAYER
		root.add_child(layer)
	var host := layer.get_node_or_null("ShadowRoot") as Control
	if host == null:
		host = Control.new()
		host.name = "ShadowRoot"
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return host


static func _attach_when_ready(art: TextureRect) -> void:
	if is_instance_valid(art):
		attach_beside(art)


static func _scene_root(node: Node) -> Node:
	var tree := node.get_tree()
	if tree == null:
		return null
	var current := node
	while current.get_parent() != null and current.get_parent() != tree.root:
		current = current.get_parent()
	return current


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
	mat.set_shader_parameter("shadow_color", _color)
	material = mat
	set_process(true)
	_sync()


func set_locked_global(xform: Transform2D, offset: Vector2) -> void:
	_locked = true
	_locked_xform = xform
	_screen_offset = offset
	_sync()


func set_color(c: Color) -> void:
	_color = c
	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("shadow_color", _color)


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
	var xform := _art.get_global_transform()
	if _locked:
		xform = _locked_xform
	var host := get_parent() as Control
	if host == null:
		visible = false
		return
	visible = true
	var host_xform := host.get_global_transform()
	var origin := host_xform.affine_inverse() * xform.origin
	var turn := xform.get_rotation() - host_xform.get_rotation()
	var scale_now := xform.get_scale()
	var local_size := Vector2(_art.size.x * absf(scale_now.x), _art.size.y * absf(scale_now.y))
	var screen_soft := float(softness_px(maxf(absf(scale_now.x), 0.01)))
	var pad := Vector2(screen_soft, screen_soft)
	var off := _screen_offset
	_place(origin + off - pad.rotated(turn), local_size + pad * 2.0)
	pivot_offset = Vector2.ZERO
	rotation = turn
	texture = _art.texture
	var mat := material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("art_size_px", local_size)
	mat.set_shader_parameter("pad_px", pad)
	mat.set_shader_parameter("blur_px", maxf(pad.x, pad.y))
	mat.set_shader_parameter("shift_px", off.rotated(-turn))
	mat.set_shader_parameter("shadow_color", _color)


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
