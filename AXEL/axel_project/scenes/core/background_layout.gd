extends RefCounted
class_name BackgroundLayout
## Shared cover/contain math for PNG exploration backgrounds.
## Returns scale, position, and world_rect so camera limits can be derived from art size.

enum FitMode {
	COVER,
	CONTAIN,
}

const DEFAULT_BACKGROUND_Y := 0.0


static func get_viewport_size(from_node: Node) -> Vector2:
	var vp := from_node.get_viewport()
	if vp == null:
		return Vector2(1280.0, 720.0)
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(1280.0, 720.0)
	return size


static func apply(
	sprite: Sprite2D,
	viewport_size: Vector2,
	fit_mode: FitMode = FitMode.COVER,
	background_y: float = DEFAULT_BACKGROUND_Y,
) -> Dictionary:
	var empty: Dictionary = {}
	var tex := sprite.texture
	if tex == null:
		return empty
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return empty

	var scale_factor: float
	match fit_mode:
		FitMode.CONTAIN:
			scale_factor = minf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
		_:
			scale_factor = maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)

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


static func apply_to_sprite(sprite: Sprite2D, layout: Dictionary) -> void:
	if layout.is_empty():
		return
	sprite.scale = layout["scale"]
	sprite.position = layout["position"]
