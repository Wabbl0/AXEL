extends RefCounted
class_name InteractArrival
## Map standing position along the source leave box onto the dest box (t in 0..1),
## keep into-room peek on the short axis, then nudge so the Front hitbox stays
## outside walls. Do not copy world Y or floor-line offsets.
## Approved example: 1.2↔1.4 ExitTrigger. Same helper for [E] InteractAreas.
##
## Receive contract (match 1.2_Corridor — do not invent a new system):
## 1. Cache t once (take_arrival_t_or_default). Missing t → 0.5.
## 2. Every layout_applied: always PlayerSpawnSync + PlayerCoverSync.apply.
## 3. If a door peek is pending: call_deferred place — do NOT place inside
##    _sync_world_space, and do NOT clear pending before that defer.
## 4. place_on_area (Front hitbox, dest box, cached t, into-room peek), then
##    deferred clamp_hitbox_to_walls.
## 5. Fresh Play / F6 uses the Player node. Memory stills keep exact restore.

enum PeekEdge {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	## Keep the area's horizontal center (margin ignored).
	CENTER_X,
	## Keep the area's vertical center (margin ignored).
	CENTER_Y,
}

const DEFAULT_T := 0.5
const _CLAMP_STEP_PX := 8.0
const _CLAMP_MAX_PX := 480.0


static func fraction_along(player: Node2D, area: Area2D, along_axis: int) -> float:
	if not is_instance_valid(player) or not is_instance_valid(area):
		return DEFAULT_T
	var env := _colliders_of(area)
	var rect := _area_rect_in_env(area, env)
	if rect.size.x <= 0.001 or rect.size.y <= 0.001:
		return DEFAULT_T
	# Hitbox center is what overlaps the [E] box — not the Player node origin
	# (Front circle sits below the node). Env-local matches PlayerSpawnSync.
	var sample := _hitbox_point(player)
	var tex := env.to_local(sample) if is_instance_valid(env) else sample
	if along_axis == Vector2.AXIS_X:
		return clampf((tex.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	return clampf((tex.y - rect.position.y) / rect.size.y, 0.0, 1.0)


static func take_arrival_t_or_default() -> float:
	var gm := _game_manager()
	if gm != null and bool(gm.call("has_interact_arrival_t")):
		return clampf(float(gm.call("take_interact_arrival_t")), 0.0, 1.0)
	return DEFAULT_T


static func _game_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameManager")


static func place_on_area(
	player: Node2D,
	dest_area: Area2D,
	t: float,
	along_axis: int,
	peek_edge: PeekEdge,
	peek_margin: float
) -> Vector2:
	var pos := player.global_position if is_instance_valid(player) else Vector2.ZERO
	if not is_instance_valid(dest_area):
		return pos
	var env := _colliders_of(dest_area)
	var rect := _area_rect_in_env(dest_area, env)
	if rect.size.x <= 0.001 or rect.size.y <= 0.001:
		return dest_area.global_position
	var t_clamped := clampf(t, 0.0, 1.0)
	var tex := rect.get_center()
	# Peek margin is authored in texture pixels (same space as collider nodes).
	match peek_edge:
		PeekEdge.LEFT:
			tex.x = rect.position.x + peek_margin
		PeekEdge.RIGHT:
			tex.x = rect.end.x + peek_margin
		PeekEdge.TOP:
			tex.y = rect.position.y + peek_margin
		PeekEdge.BOTTOM:
			tex.y = rect.end.y + peek_margin
		PeekEdge.CENTER_X:
			tex.x = rect.get_center().x
		PeekEdge.CENTER_Y:
			tex.y = rect.get_center().y
	if along_axis == Vector2.AXIS_X:
		tex.x = rect.position.x + rect.size.x * t_clamped
	else:
		tex.y = rect.position.y + rect.size.y * t_clamped
	var dest_global := env.to_global(tex) if is_instance_valid(env) else tex
	# Land the Front hitbox on the mapped point, not the Player node origin.
	return dest_global - _hitbox_offset_global(player)


static func apply_arrival(
	player: CharacterBody2D,
	dest_area: Area2D,
	t: float,
	along_axis: int,
	peek_edge: PeekEdge,
	peek_margin: float
) -> void:
	if not is_instance_valid(player):
		return
	player.global_position = place_on_area(
		player, dest_area, t, along_axis, peek_edge, peek_margin
	)
	clamp_hitbox_to_walls(player, along_axis)


static func clamp_hitbox_to_walls(
	player: CharacterBody2D, prefer_axis: int = Vector2.AXIS_Y
) -> void:
	if not is_instance_valid(player):
		return
	if not _hitbox_blocked(player):
		return
	var origin := player.global_position
	var other_axis := (
		Vector2.AXIS_X if prefer_axis == Vector2.AXIS_Y else Vector2.AXIS_Y
	)
	if _try_nudge_axis(player, origin, prefer_axis):
		return
	player.global_position = origin
	if _try_nudge_axis(player, origin, other_axis):
		return
	player.global_position = origin
	# Combined: nudge prefer axis in steps, then other axis from each candidate.
	var d := _CLAMP_STEP_PX
	while d <= _CLAMP_MAX_PX:
		for dir in [-1.0, 1.0]:
			var candidate := origin
			if prefer_axis == Vector2.AXIS_X:
				candidate.x = origin.x + dir * d
			else:
				candidate.y = origin.y + dir * d
			player.global_position = candidate
			if not _hitbox_blocked(player):
				return
			if _try_nudge_axis(player, candidate, other_axis):
				return
		d += _CLAMP_STEP_PX
	player.global_position = origin


static func _try_nudge_axis(
	player: CharacterBody2D, origin: Vector2, axis: int
) -> bool:
	var d := _CLAMP_STEP_PX
	while d <= _CLAMP_MAX_PX:
		for dir in [-1.0, 1.0]:
			var candidate := origin
			if axis == Vector2.AXIS_X:
				candidate.x = origin.x + dir * d
			else:
				candidate.y = origin.y + dir * d
			player.global_position = candidate
			if not _hitbox_blocked(player):
				return true
		d += _CLAMP_STEP_PX
	return false


static func _hitbox_blocked(player: CharacterBody2D) -> bool:
	var collision := _front_collision(player)
	if collision == null or collision.disabled:
		return false
	var shape := collision.shape
	if shape == null:
		return false
	var space := player.get_world_2d()
	if space == null:
		return false
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = collision.global_transform
	params.collision_mask = player.collision_mask
	params.exclude = [player.get_rid()]
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hits := space.direct_space_state.intersect_shape(params, 8)
	return not hits.is_empty()


static func _front_collision(player: CharacterBody2D) -> CollisionShape2D:
	var front := player.get_node_or_null("CollisionFront") as CollisionShape2D
	if front != null:
		return front
	return player.get_node_or_null("CollisionShape2D") as CollisionShape2D


static func _hitbox_point(player: Node2D) -> Vector2:
	if player is CharacterBody2D:
		var front := _front_collision(player as CharacterBody2D)
		if front != null:
			# Body transform, not CollisionShape2D.global_position (CanvasLayer).
			return player.to_global(front.position)
	return player.global_position


static func _hitbox_offset_global(player: Node2D) -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	return _hitbox_point(player) - player.global_position


static func _colliders_of(area: Area2D) -> Node2D:
	var node: Node = area
	while node != null:
		if node.name == "EnvironmentColliders":
			return node as Node2D
		node = node.get_parent()
	return area.get_parent() as Node2D


static func _area_rect_in_env(area: Area2D, env: Node2D) -> Rect2:
	if not is_instance_valid(env):
		return _area_global_rect(area)
	var shape_node := _first_rect_or_any_shape(area)
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var rect_shape := shape_node.shape as RectangleShape2D
		var half := rect_shape.size * 0.5
		var corners: Array[Vector2] = [
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(-half.x, half.y),
			Vector2(half.x, half.y),
		]
		var min_v := Vector2(INF, INF)
		var max_v := Vector2(-INF, -INF)
		for local_pt in corners:
			var tex := env.to_local(shape_node.to_global(local_pt))
			min_v = min_v.min(tex)
			max_v = max_v.max(tex)
		if min_v.x == INF:
			return Rect2()
		return Rect2(min_v, max_v - min_v)
	var poly_node := _first_polygon(area)
	if poly_node != null and not poly_node.polygon.is_empty():
		var min_v := Vector2(INF, INF)
		var max_v := Vector2(-INF, -INF)
		for local_pt in poly_node.polygon:
			var tex := env.to_local(poly_node.to_global(local_pt))
			min_v = min_v.min(tex)
			max_v = max_v.max(tex)
		if min_v.x == INF:
			return Rect2()
		return Rect2(min_v, max_v - min_v)
	return _area_global_rect(area)


static func _first_rect_or_any_shape(area: Area2D) -> CollisionShape2D:
	var named := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if named != null:
		return named
	for child in area.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


static func _first_polygon(area: Area2D) -> CollisionPolygon2D:
	var named := area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if named != null:
		return named
	for child in area.get_children():
		if child is CollisionPolygon2D:
			return child as CollisionPolygon2D
	return null


static func _area_global_rect(area: Area2D) -> Rect2:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape != null:
		return _shape_global_rect(shape_node)
	var poly_node := area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly_node != null and not poly_node.polygon.is_empty():
		return _polygon_global_rect(poly_node)
	# Fallback: tiny rect at the Area2D origin.
	return Rect2(area.global_position, Vector2(1.0, 1.0))


static func _shape_global_rect(shape_node: CollisionShape2D) -> Rect2:
	var shape := shape_node.shape
	var xf := shape_node.global_transform
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var half := rect_shape.size * 0.5
		var corners: Array[Vector2] = [
			xf * Vector2(-half.x, -half.y),
			xf * Vector2(half.x, -half.y),
			xf * Vector2(-half.x, half.y),
			xf * Vector2(half.x, half.y),
		]
		return _corners_to_rect(corners)
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var r := circle.radius
		var center := xf.origin
		# Uniform-scale approximation from transform basis.
		var scale_x := xf.basis_xform(Vector2.RIGHT).length()
		var scale_y := xf.basis_xform(Vector2.DOWN).length()
		var rx := r * scale_x
		var ry := r * scale_y
		return Rect2(center - Vector2(rx, ry), Vector2(rx * 2.0, ry * 2.0))
	return Rect2(xf.origin, Vector2(1.0, 1.0))


static func _corners_to_rect(corners: Array[Vector2]) -> Rect2:
	var min_v := corners[0]
	var max_v := corners[0]
	for i in range(1, corners.size()):
		min_v = min_v.min(corners[i])
		max_v = max_v.max(corners[i])
	return Rect2(min_v, max_v - min_v)


static func _polygon_global_rect(poly_node: CollisionPolygon2D) -> Rect2:
	var min_v := Vector2(INF, INF)
	var max_v := Vector2(-INF, -INF)
	for local_point in poly_node.polygon:
		var g := poly_node.to_global(local_point)
		min_v = min_v.min(g)
		max_v = max_v.max(g)
	if min_v.x == INF:
		return Rect2(poly_node.global_position, Vector2(1.0, 1.0))
	return Rect2(min_v, max_v - min_v)
