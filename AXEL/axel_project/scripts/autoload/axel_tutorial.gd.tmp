extends RefCounted

const SHADER := preload("res://combat/shaders/piece_highlight_glow.gdshader")
const GLOW_NAME := "HighlightGlow"


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
		var glow := art.get_node_or_null(GLOW_NAME) as TextureRect
		if glow == null:
			continue
		glow.modulate = Color(1, 1, 1, alpha)


static func _collect_arts(node: Node, out: Array[TextureRect]) -> void:
	if node is TextureRect:
		var rect := node as TextureRect
		var n := str(rect.name)
		if not n.begins_with("DropShadow") and not n.begins_with("HighlightGlow"):
			out.append(rect)
	for child in node.get_children():
		_collect_arts(child, out)


static func _ensure_glow(art: TextureRect) -> void:
	if art == null or not is_instance_valid(art):
		return
	var existing := art.get_node_or_null(GLOW_NAME) as TextureRect
	if existing != null:
		return
	var glow := TextureRect.new()
	glow.name = GLOW_NAME
	glow.texture = art.texture
	glow.expand_mode = art.expand_mode
	glow.stretch_mode = art.stretch_mode
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.z_index = maxi(art.z_index + 1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	glow.material = mat
	glow.modulate = Color(1, 1, 1, 1)
	art.add_child(glow)


static func _remove_glow(art: TextureRect) -> void:
	if art == null or not is_instance_valid(art):
		return
	var existing := art.get_node_or_null(GLOW_NAME)
	if existing != null:
		existing.queue_free()
