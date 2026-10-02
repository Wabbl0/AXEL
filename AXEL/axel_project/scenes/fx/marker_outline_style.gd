extends RefCounted

const MEMORY_SPREAD := 0.96
const ITEM_SPREAD := 1.92
const OUTLINE_ALPHA := 0.75
const ITEM_COLOR := Color(0.9, 0.0, 0.0, OUTLINE_ALPHA)
const MEMORY_HALO_COLOR := Color(1.0, 1.0, 1.0, OUTLINE_ALPHA)
const MEMORY_SPRITE_COLOR := Color(0.9, 0.0, 0.0, 1.0)


static func apply_item_halo(halo: CanvasItem) -> void:
	_apply(halo, ITEM_SPREAD, ITEM_COLOR)


static func apply_memory(sprite: CanvasItem, halo: CanvasItem) -> void:
	if sprite != null:
		sprite.modulate = MEMORY_SPRITE_COLOR
	_apply(halo, MEMORY_SPREAD, MEMORY_HALO_COLOR)


static func sync_frame(halo: AnimatedSprite2D) -> void:
	if halo == null:
		return
	var mat := halo.material as ShaderMaterial
	if mat == null:
		return
	var frames := halo.sprite_frames
	if frames == null or halo.animation == &"" or not frames.has_animation(halo.animation):
		return
	var count := frames.get_frame_count(halo.animation)
	if count <= 0:
		return
	var tex := frames.get_frame_texture(halo.animation, clampi(halo.frame, 0, count - 1))
	var atlas := tex as AtlasTexture
	if atlas == null or atlas.atlas == null:
		return
	var region := atlas.region
	mat.set_shader_parameter("region_pos", region.position)
	mat.set_shader_parameter("frame_px", region.size)
	mat.set_shader_parameter("sheet_px", Vector2(atlas.atlas.get_width(), atlas.atlas.get_height()))


static func _apply(node: CanvasItem, spread: float, glow: Color) -> void:
	if node == null:
		return
	var mat := node.material as ShaderMaterial
	if mat == null:
		return
	mat = mat.duplicate() as ShaderMaterial
	node.material = mat
	mat.set_shader_parameter("spread", spread)
	mat.set_shader_parameter("glow_color", glow)
