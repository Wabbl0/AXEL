class_name TouchInteract
extends RefCounted
## Shared helper for tap-to-interact: converts a screen touch position to world
## space and tests it against an interact Area2D's collision polygons.


## True when `screen_pos` lands inside any CollisionPolygon2D of `area`.
## `pad_px` grows the hit test outward (finger-friendly) in world pixels.
static func touch_hits_area(viewport: Viewport, screen_pos: Vector2, area: Area2D, pad_px: float = 14.0) -> bool:
	if viewport == null or not is_instance_valid(area):
		return false
	var world_pos: Vector2 = viewport.get_canvas_transform().affine_inverse() * screen_pos
	for child in area.get_children():
		if child is not CollisionPolygon2D:
			continue
		var poly := child as CollisionPolygon2D
		if poly.polygon.size() < 3:
			continue
		var world_points := PackedVector2Array()
		world_points.resize(poly.polygon.size())
		for i in poly.polygon.size():
			world_points[i] = poly.to_global(poly.polygon[i])
		if Geometry2D.is_point_in_polygon(world_pos, world_points):
			return true
		if pad_px > 0.0 and _distance_to_polygon(world_pos, world_points) <= pad_px:
			return true
	return false


static func _distance_to_polygon(point: Vector2, points: PackedVector2Array) -> float:
	var best := INF
	var count := points.size()
	for i in count:
		var seg_dist := point.distance_to(
			Geometry2D.get_closest_point_to_segment(point, points[i], points[(i + 1) % count])
		)
		best = minf(best, seg_dist)
	return best
