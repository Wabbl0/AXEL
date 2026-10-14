extends RefCounted
class_name BackgroundLayout

enum FitMode {
	COVER,
	CONTAIN,
}

const DEFAULT_BACKGROUND_Y := 0.0
const EDIT_LOCK_META := "_edit_lock_"
const MAX_EDGE_REVEAL := 0.05
const DESIGN_VIEWPORT := Vector2(1920.0, 1280.0)


static func ensure_editor_locked(sprite: Sprite2D) -> void:
	if sprite == null or not Engine.is_editor_hint():
		return
	if not sprite.has_meta(EDIT_LOCK_META):
		sprite.set_meta(EDIT_LOCK_META, true)


static func get_viewport_size(from_node: Node) -> Vector2:
	var vp := from_node.get_viewport()
	if vp == null:
		return DESIGN_VIEWPORT
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return DESIGN_VIEWPORT
	return size


static func apply(
	sprite: Sprite2D,
	viewport_size: Vector2,
	fit_mode: FitMode = FitMode.COVER,
	background_y: float = DEFAULT_BACKGROUND_Y,
	edge_reveal: float = 0.0,
	keep_height: bool = false,
) -> Dictionary:
	var empty: Dictionary = {}
	var tex := sprite.texture
	if tex == null:
		return empty
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return empty

	var contain_scale := minf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var cover_scale := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var scale_factor: float
	match fit_mode:
		FitMode.CONTAIN:
			scale_factor = contain_scale
			if keep_height:
				var baseline := minf(DESIGN_VIEWPORT.x / tex_size.x, DESIGN_VIEWPORT.y / tex_size.y)
				scale_factor = maxf(contain_scale, baseline * viewport_size.y / DESIGN_VIEWPORT.y)
		_:
			scale_factor = cover_scale
			if edge_reveal > 0.0:
				var reveal := clampf(edge_reveal, 0.0, 0.5)
				scale_factor = maxf(contain_scale, cover_scale * (1.0 - 2.0 * reveal))

	var fit_scale := Vector2.ONE * scale_factor
	var position := Vector2(
		(viewport_size.x - tex_size.x * scale_factor) * 0.5,
		background_y,
	)
	var world_rect := compute_world_rect(sprite, position, fit_scale)

	return {
		"scale": fit_scale,
		"position": position,
		"world_rect": world_rect,
		"scale_factor": scale_factor,
	}


static func compute_world_rect(sprite: Sprite2D, position: Vector2, scale: Vector2) -> Rect2:
	var tex := sprite.texture
	if tex == null:
		return Rect2()
	var scaled_size := tex.get_size() * scale
	if sprite.centered:
		return Rect2(position - scaled_size * 0.5, scaled_size)
	return Rect2(position, scaled_size)


static func compute_global_world_rect(sprite: Sprite2D) -> Rect2:
	var tex := sprite.texture
	if tex == null:
		return Rect2()
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2()
	var local_tl := Vector2.ZERO
	var local_br := tex_size
	if sprite.centered:
		local_tl = -tex_size * 0.5
		local_br = tex_size * 0.5
	var p0 := sprite.to_global(local_tl)
	var p1 := sprite.to_global(Vector2(local_br.x, local_tl.y))
	var p2 := sprite.to_global(local_br)
	var p3 := sprite.to_global(Vector2(local_tl.x, local_br.y))
	var min_x := minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
	var min_y := minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
	var max_x := maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
	var max_y := maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


static func apply_to_sprite(sprite: Sprite2D, layout: Dictionary) -> void:
	if layout.is_empty():
		return
	sprite.scale = layout["scale"]
	sprite.position = layout["position"]
	ensure_editor_locked(sprite)
