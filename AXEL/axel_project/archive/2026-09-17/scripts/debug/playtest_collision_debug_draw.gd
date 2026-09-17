extends Node2D
## Renders outlines for `CollisionShape2D` / `CollisionPolygon2D` under the parent
## [PlaytestCollisionDebug] CanvasLayer. Coordinate space matches the default viewport
## (parent transform is identity).

const _CAP_SEGMENTS := 10

func _process(_delta: float) -> void:
	var layer := get_parent()
	if layer == null or not layer.is_active():
		return
	queue_redraw()


func _draw() -> void:
	var layer := get_parent()
	if layer == null or not layer.is_active():
		return

	var outline: Color = layer.outline_color
	var width: float = layer.line_width
	var shapes: Array = layer.get_shape_nodes()

	for n in shapes:
		if not is_instance_valid(n):
			continue
		if not n.is_inside_tree():
			continue

		if n is CollisionShape2D:
			_draw_collision_shape_2d(n as CollisionShape2D, outline, width)
		elif n is CollisionPolygon2D:
			_draw_collision_polygon_2d(n as CollisionPolygon2D, outline, width)


func _draw_collision_polygon_2d(poly: CollisionPolygon2D, color: Color, width: float) -> void:
	var gt: Transform2D = poly.global_transform
	var pts: PackedVector2Array = poly.polygon
	if pts.is_empty():
		return
	var world: PackedVector2Array = PackedVector2Array()
	world.resize(pts.size())
	for i in pts.size():
		world[i] = gt * pts[i]
	_stroke_polyline_closed(world, color, width)


func _draw_collision_shape_2d(cs: CollisionShape2D, color: Color, width: float) -> void:
	var shp: Shape2D = cs.shape
	if shp == null:
		return
	var gt: Transform2D = cs.global_transform

	if shp is RectangleShape2D:
		var rect_shape := shp as RectangleShape2D
		var half: Vector2 = rect_shape.size * 0.5
		var corners: PackedVector2Array = PackedVector2Array([
			gt * Vector2(-half.x, -half.y),
			gt * Vector2(half.x, -half.y),
			gt * Vector2(half.x, half.y),
			gt * Vector2(-half.x, half.y),
		])
		_stroke_polyline_closed(corners, color, width)
	elif shp is CircleShape2D:
		var circ := shp as CircleShape2D
		var center: Vector2 = gt * Vector2.ZERO
		var basis_scale: Vector2 = gt.get_scale()
		var r_scale: float = maxf(absf(basis_scale.x), absf(basis_scale.y))
		var radius: float = circ.radius * r_scale
		draw_arc(center, radius, 0.0, TAU, maxi(24, int(radius * 0.35)), color, width, false)
	elif shp is CapsuleShape2D:
		var capsule := shp as CapsuleShape2D
		var outline_pts := _capsule_outline_points_local(capsule.radius, capsule.height)
		var world: PackedVector2Array = PackedVector2Array()
		world.resize(outline_pts.size())
		for i in outline_pts.size():
			world[i] = gt * outline_pts[i]
		_stroke_polyline_closed(world, color, width)
	elif shp is ConvexPolygonShape2D:
		var convex := shp as ConvexPolygonShape2D
		var pts: PackedVector2Array = convex.points
		if pts.is_empty():
			return
		var world: PackedVector2Array = PackedVector2Array()
		world.resize(pts.size())
		for i in pts.size():
			world[i] = gt * pts[i]
		_stroke_polyline_closed(world, color, width)
	elif shp is SegmentShape2D:
		var seg := shp as SegmentShape2D
		var a: Vector2 = gt * seg.a
		var b: Vector2 = gt * seg.b
		draw_line(a, b, color, width)
	elif shp is WorldBoundaryShape2D:
		_draw_world_boundary(gt, shp as WorldBoundaryShape2D, color, width)
	else:
		# SeparationRayShape2D / ConcavePolygonShape2D / future shapes: faint marker.
		var c: Vector2 = gt * Vector2.ZERO
		draw_arc(c, 6.0, 0.0, TAU, 12, color, width * 0.75, false)


func _capsule_outline_points_local(radius: float, height: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var mid: float = maxf(height - 2.0 * radius, 0.0)
	var top_center := Vector2(0.0, -mid * 0.5)
	var bottom_center := Vector2(0.0, mid * 0.5)
	for i in _CAP_SEGMENTS + 1:
		var t := float(i) / float(_CAP_SEGMENTS)
		var ang := lerpf(PI, TAU, t)
		pts.append(top_center + Vector2(cos(ang), sin(ang)) * radius)
	for i in _CAP_SEGMENTS + 1:
		var t2 := float(i) / float(_CAP_SEGMENTS)
		var ang2 := lerpf(0.0, PI, t2)
		pts.append(bottom_center + Vector2(cos(ang2), sin(ang2)) * radius)
	return pts


func _draw_world_boundary(gt: Transform2D, boundary: WorldBoundaryShape2D, color: Color, width: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var diag: float = vp.get_visible_rect().size.length() * 2.0
	var n_world := gt.basis_xform(boundary.normal).normalized()
	if n_world.length_squared() < 0.0001:
		return
	var tangent := Vector2(-n_world.y, n_world.x)
	var origin_world: Vector2 = gt.origin
	var p0: Vector2 = origin_world - tangent * diag
	var p1: Vector2 = origin_world + tangent * diag
	draw_line(p0, p1, color, width)


func _stroke_polyline_closed(points: PackedVector2Array, color: Color, width: float) -> void:
	var n := points.size()
	if n < 2:
		return
	for i in n:
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % n]
		draw_line(a, b, color, width)
