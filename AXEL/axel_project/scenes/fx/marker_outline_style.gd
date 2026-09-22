extends RefCounted

const SPREAD := 12.0
const ITEM_INTENSITY := 0.42
const MEMORY_INTENSITY := 0.42
const ITEM_COLOR := Color(0.9, 0.0, 0.0, 1.0)
const MEMORY_HALO_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const MEMORY_SPRITE_COLOR := Color(0.9, 0.0, 0.0, 1.0)


static func apply_item_halo(halo: CanvasItem) -> void:
	_apply(halo, SPREAD, ITEM_INTENSITY, ITEM_COLOR)


static func apply_memory(sprite: CanvasItem, halo: CanvasItem) -> void:
	if sprite != null:
		sprite.modulate = MEMORY_SPRITE_COLOR
	_apply(halo, SPREAD, MEMORY_INTENSITY, MEMORY_HALO_COLOR)


static func _apply(node: CanvasItem, spread: float, intensity: float, glow: Color) -> void:
	if node == null:
		return
	var mat := node.material as ShaderMaterial
	if mat == null:
		return
	mat = mat.duplicate() as ShaderMaterial
	node.material = mat
	mat.set_shader_parameter("spread", spread)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("glow_color", glow)
