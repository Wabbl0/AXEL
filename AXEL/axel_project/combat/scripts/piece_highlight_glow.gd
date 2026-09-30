extends TextureRect

const SHADER := preload("res://combat/shaders/piece_highlight_glow.gdshader")
const SELF_PATH := "res://combat/scripts/piece_highlight_glow.gd"
const GLOW_PREFIX := "HighlightGlow_"
const LAYER_NAME := "HudHighlightLayer"
const HOST_NAME := "HighlightRoot"
const HIGHLIGHT_LAYER := 93

var _art: TextureRect
var _alpha := 1.0


static func set_highlight(piece: Control, on: bool) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	var arts: Array[TextureRect] = []
	_collect_arts(piece, arts)
	for art in arts:
		if on:
			_ensure_glow(art)
		else:
			_remove_glow(art)


static func pulse_highlights(piece: Control, alpha: float) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	var arts: Array[TextureRect] = []
	_collect_arts(piece, arts)
	for art in arts:
		var glow := _find_glow(art)
		if glow == null:
			continue
		glow.call("set_alpha", alpha)


static func glow_for(art: TextureRect) -> TextureRect:
	return _find_glow(art)


static func _collect_arts(piece: Control, out: Array[TextureRect]) -> void:
	if piece is TextureRect:
		out.append(piece as TextureRect)
		return
	_collect_child_arts(piece, out)


static func _collect_child_arts(node: Node, out: Array[TextureRect]) -> void:
	if node is TextureRect:
		var n := str(node.name)
		if n != "Glow" and not n.begins_with("DropShadow") and not n.begins_with("HighlightGlow"):
			out.append(node as TextureRect)
	for child in node.get_children():
		_collect_child_arts(child, out)


static func _glow_name(art: TextureRect) -> String:
	return GLOW_PREFIX + str(art.get_instance_id())


static func _find_glow(art: TextureRect) -> TextureRect:
	if art == null or not is_instance_valid(art):
		return null
	var host := _host(art, false)
	if host == null:
		return null
	return host.get_node_or_null(_glow_name(art)) as TextureRect


static func _ensure_glow(art: TextureRect) -> void:
	if art == null or not is_instance_valid(art) or not art.is_inside_tree():
		return
	var host := _host(art, true)
	if host == null:
		return
	var glow_name := _glow_name(art)
	if host.get_node_or_null(glow_name) != null:
		return
	var glow := (load(SELF_PATH) as GDScript).new() as TextureRect
	glow.name = glow_name
	host.add_child(glow)
	glow.call("setup", art)


static func _remove_glow(art: TextureRect) -> void:
	var glow := _find_glow(art)
	if glow != null:
		glow.queue_free()


static func _host(art: Node, create: bool) -> Control:
	var root := _scene_root(art)
	if root == null:
		return null
	var layer := root.get_node_or_null(LAYER_NAME) as CanvasLayer
	if layer == null:
		if not create:
			return null
		layer = CanvasLayer.new()
		layer.name = LAYER_NAME
		layer.layer = HIGHLIGHT_LAYER
		root.add_child(layer)
	var host := layer.get_node_or_null(HOST_NAME) as Control
	if host == null:
		if not create:
			return null
		host = Control.new()
		host.name = HOST_NAME
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return host


static func _scene_root(node: Node) -> Node:
	var tree := node.get_tree()
	if tree == null:
		return null
	var current := node
	while current.get_parent() != null and current.get_parent() != tree.root:
		current = current.get_parent()
	return current


func setup(art: TextureRect) -> void:
	_art = art
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	material = mat
	set_process(true)
	_sync()


func set_alpha(alpha: float) -> void:
	_alpha = alpha
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	if _art == null or not is_instance_valid(_art):
		queue_free()
		return
	var host := get_parent() as Control
	if host == null or not _art.is_visible_in_tree() or _art.texture == null:
		visible = false
		return
	if _art.size.x < 2.0 or _art.size.y < 2.0:
		visible = false
		return
	var xform := _art.get_global_transform_with_canvas()
	var host_xform := host.get_global_transform_with_canvas()
	var origin := host_xform.affine_inverse() * xform.origin
	var turn := xform.get_rotation() - host_xform.get_rotation()
	var scale_now := xform.get_scale()
	var local_size := Vector2(_art.size.x * absf(scale_now.x), _art.size.y * absf(scale_now.y))
	visible = true
	@warning_ignore("int_as_enum_without_cast")
	@warning_ignore("int_as_enum_without_match")
	layout_mode = 0
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = origin
	size = local_size
	pivot_offset = Vector2.ZERO
	rotation = turn
	texture = _art.texture
	modulate = Color(1, 1, 1, _alpha)
