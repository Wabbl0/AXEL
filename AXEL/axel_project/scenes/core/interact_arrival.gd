extends RefCounted
class_name InteractArrival
## Map standing position along the source leave box onto the dest box (t in 0..1).
## LIVE DEST BOX (mandatory): place_on_area / place_in_area read the dest
## InteractArea / ExitTrigger after cover-fit this Play. Never land on a Vector2
## copied from chat, changelog, or an earlier .tscn grep. Do not replace a
## live-box land with BOTTOM/TOP + resolve_inside_clearance unless the user asked.
## Applies to 1.x, 2.1→2.3, 2.1↔2.4, 2.1→3.1, and every other door pair.
## Hard spawns only: F6 Player node; hub/map Player node; memory restore;
## 2.3→2.1 kitchen Y 90. See SCENE_BUILDING.md.
## Frozen trips (1.2→1.4, 1.4→2.1, 2.1→2.3): place_on_area into-room peek past the
## short edge of the LIVE dest box, then clamp_hitbox_to_walls. Approved peek:
## 1.2↔1.4 ExitTrigger.
## 2.1→2.4: Player node on live CafeteriaInteractArea center
## (place_node_on_area_center); skip resolve_inside_clearance. Front-on-center
## pushes the walk drawing out the top of the PNG.
## 2.4→2.1: place_in_area at dest center; skip resolve_inside_clearance.
## 2.4→5.1: Player node on live DoorInteractArea center; skip clearance.
## Other non-frozen [E]: place_in_area + resolve_inside_clearance. Do not copy
## world Y or floor-line offsets.
##
## Receive contract (match 1.2_Corridor — do not invent a new system):
## 1. Cache t once (take_arrival_t_or_default). Missing t → 0.5.
## 2. Every layout_applied: always PlayerSpawnSync + PlayerCoverSync.apply.
## 3. If a door peek is pending: call_deferred place — do NOT place inside
##    _sync_world_space, and do NOT clear pending before that defer.
## 4. Frozen: place_on_area + clamp. 2.1→2.4: place_node_on_area_center last.
##    2.4→2.1: place_in_area center last.
##    Other non-frozen: apply_arrival_inside last (do not re-scale after place).
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
const _OUTWARD_MAX_PX := 480.0
## Extra padding so clearance stops a little past a bare touch.
const _SPRITE_AABB_PAD_PX := 8.0
const _DEFAULT_FRONT_RADIUS := 40.647236


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


## Non-frozen [E]: land Front inside the live dest box (inset by Front radius),
## slide t on the long axis, depth_frac inward from enter_edge on the short axis.
static func place_in_area(
	player: Node2D,
	dest_area: Area2D,
	t: float,
	along_axis: int,
	enter_edge: PeekEdge,
	depth_frac: float = 0.5
) -> Vector2:
	var pos := player.global_position if is_instance_valid(player) else Vector2.ZERO
	if not is_instance_valid(dest_area):
		return pos
	var env := _colliders_of(dest_area)
	var rect := _area_rect_in_env(dest_area, env)
	if rect.size.x <= 0.001 or rect.size.y <= 0.001:
		return dest_area.global_position
	var inset := _front_radius_in_env(player, env)
	var inner := _inset_rect(rect, inset)
	var t_clamped := clampf(t, 0.0, 1.0)
	var d := clampf(depth_frac, 0.0, 1.0)
	var tex := inner.get_center()
	# Short axis: measured inward from enter_edge (never past the box).
	match enter_edge:
		PeekEdge.LEFT:
			tex.x = lerpf(inner.position.x, inner.end.x, d)
		PeekEdge.RIGHT:
			tex.x = lerpf(inner.end.x, inner.position.x, d)
		PeekEdge.TOP:
			tex.y = lerpf(inner.position.y, inner.end.y, d)
		PeekEdge.BOTTOM:
			tex.y = lerpf(inner.end.y, inner.position.y, d)
		PeekEdge.CENTER_X:
			tex.x = inner.get_center().x
		PeekEdge.CENTER_Y:
			tex.y = inner.get_center().y
	# Long axis: slide with t (center if the box is thinner than 2*inset).
	if along_axis == Vector2.AXIS_X:
		if rect.size.x <= 2.0 * inset:
			tex.x = rect.get_center().x
		else:
			tex.x = lerpf(inner.position.x, inner.end.x, t_clamped)
	else:
		if rect.size.y <= 2.0 * inset:
			tex.y = rect.get_center().y
		else:
			tex.y = lerpf(inner.position.y, inner.end.y, t_clamped)
	var dest_global := env.to_global(tex) if is_instance_valid(env) else tex
	return dest_global - _hitbox_offset_global(player)


## Put the Player node (the walk drawing) on the live dest box center.
## Re-reads the dest InteractArea after cover-fit this Play — no stored Vector2.
static func place_node_on_area_center(player: Node2D, dest_area: Area2D) -> Vector2:
	if not is_instance_valid(dest_area):
		return player.global_position if is_instance_valid(player) else Vector2.ZERO
	var env := _colliders_of(dest_area)
	var rect := _area_rect_in_env(dest_area, env)
	if rect.size.x <= 0.001 or rect.size.y <= 0.001:
		return dest_area.global_position
	if is_instance_valid(env):
		return env.to_global(rect.get_center())
	return rect.get_center()


static func apply_arrival_inside(
	player: CharacterBody2D,
	dest_area: Area2D,
	t: float,
	along_axis: int,
	enter_edge: PeekEdge,
	depth_frac: float = 0.5
) -> void:
	if not is_instance_valid(player):
		return
	player.global_position = place_in_area(
		player, dest_area, t, along_axis, enter_edge, depth_frac
	)
	var short_axis := (
		Vector2.AXIS_Y if along_axis == Vector2.AXIS_X else Vector2.AXIS_X
	)
	resolve_inside_clearance(player, dest_area, short_axis, enter_edge)


## Option B: keep Front + walk drawing clear of walls; prefer staying inside the
## live [E] box, then allow a short outward nudge, then fall back to hitbox clamp.
static func resolve_inside_clearance(
	player: CharacterBody2D,
	dest_area: Area2D,
	short_axis: int,
	enter_edge: PeekEdge = PeekEdge.CENTER_Y
) -> void:
	if not is_instance_valid(player) or not is_instance_valid(dest_area):
		return
	if not _hitbox_blocked(player) and not _sprite_blocked(player):
		return
	var origin := player.global_position
	var env := _colliders_of(dest_area)
	var rect := _area_rect_in_env(dest_area, env)
	var inset := _front_radius_in_env(player, env)
	var inner := _inset_rect(rect, inset)
	var pref := _into_room_sign(enter_edge, short_axis)
	# 1) Scan along short axis, stay inside inner.
	if _scan_clearance(player, origin, short_axis, pref, inner, env, true, false):
		return
	player.global_position = origin
	# 2) Outward past the box — into-room direction only (never escape the
	# opposite way into empty space above/beside the room).
	if _scan_clearance(player, origin, short_axis, pref, inner, env, false, true):
		return
	player.global_position = origin
	# 3) Into-room nudge that clears BOTH hitbox and walk drawing.
	if _try_nudge_axis_dir_clear(player, origin, short_axis, pref):
		return
	player.global_position = origin


static func _try_nudge_axis_dir_clear(
	player: CharacterBody2D, origin: Vector2, axis: int, dir: float
) -> bool:
	if absf(dir) < 0.001:
		dir = 1.0
	var d := _CLAMP_STEP_PX
	while d <= _CLAMP_MAX_PX:
		var candidate := origin
		if axis == Vector2.AXIS_X:
			candidate.x = origin.x + dir * d
		else:
			candidate.y = origin.y + dir * d
		player.global_position = candidate
		if not _hitbox_blocked(player) and not _sprite_blocked(player):
			return true
		d += _CLAMP_STEP_PX
	return false


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


## Arrival-only: walk drawing AABB vs StaticBody2D walls (not per-frame).
static func _sprite_blocked(player: CharacterBody2D) -> bool:
	var aabb := _sprite_aabb_global(player)
	if aabb.size.x <= 0.001 or aabb.size.y <= 0.001:
		return false
	var space := player.get_world_2d()
	if space == null:
		return false
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = aabb.size
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = rect_shape
	params.transform = Transform2D(0.0, aabb.get_center())
	params.collision_mask = player.collision_mask
	params.exclude = [player.get_rid()]
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hits := space.direct_space_state.intersect_shape(params, 8)
	return not hits.is_empty()


static func _sprite_aabb_global(player: CharacterBody2D) -> Rect2:
	var spr := _find_animated_sprite(player)
	if spr == null or spr.sprite_frames == null:
		return Rect2()
	var anim := spr.animation
	if not spr.sprite_frames.has_animation(anim):
		return Rect2()
	var frame_count := spr.sprite_frames.get_frame_count(anim)
	if frame_count <= 0:
		return Rect2()
	var frame_idx := clampi(spr.frame, 0, frame_count - 1)
	var tex := spr.sprite_frames.get_frame_texture(anim, frame_idx)
	if tex == null:
		return Rect2()
	var size := Vector2(tex.get_width(), tex.get_height())
	var half := size * 0.5
	var local_min := -half + spr.offset
	var local_max := half + spr.offset
	if not spr.centered:
		local_min = spr.offset
		local_max = size + spr.offset
	var corners: Array[Vector2] = [
		spr.to_global(Vector2(local_min.x, local_min.y)),
		spr.to_global(Vector2(local_max.x, local_min.y)),
		spr.to_global(Vector2(local_min.x, local_max.y)),
		spr.to_global(Vector2(local_max.x, local_max.y)),
	]
	var min_v := corners[0]
	var max_v := corners[0]
	for i in range(1, corners.size()):
		min_v = min_v.min(corners[i])
		max_v = max_v.max(corners[i])
	var aabb := Rect2(min_v, max_v - min_v)
	# Pad so we do not stop on a bare 1-px touch with TopWall.
	return aabb.grow(_SPRITE_AABB_PAD_PX)


static func _find_animated_sprite(player: Node2D) -> AnimatedSprite2D:
	var named := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if named != null:
		return named
	for child in player.get_children():
		if child is AnimatedSprite2D and child.name != "ShadowOutline":
			return child as AnimatedSprite2D
	return null


static func _scan_clearance(
	player: CharacterBody2D,
	origin: Vector2,
	short_axis: int,
	pref_sign: float,
	inner: Rect2,
	env: Node2D,
	restrict_to_inner: bool,
	into_room_only: bool = false
) -> bool:
	var max_d := _OUTWARD_MAX_PX if not restrict_to_inner else maxf(inner.size.x, inner.size.y) + _CLAMP_STEP_PX
	if max_d < _CLAMP_STEP_PX:
		max_d = _CLAMP_STEP_PX
	var dirs: Array[float] = []
	if into_room_only:
		if absf(pref_sign) < 0.001:
			dirs = [1.0]
		else:
			dirs = [pref_sign]
	else:
		dirs = [pref_sign, -pref_sign]
		if absf(pref_sign) < 0.001:
			dirs = [-1.0, 1.0]
	var d := _CLAMP_STEP_PX
	while d <= max_d:
		for dir in dirs:
			var candidate := origin
			if short_axis == Vector2.AXIS_X:
				candidate.x = origin.x + dir * d
			else:
				candidate.y = origin.y + dir * d
			player.global_position = candidate
			if restrict_to_inner:
				var front_tex := (
					env.to_local(_hitbox_point(player))
					if is_instance_valid(env)
					else _hitbox_point(player)
				)
				if not _rect_contains_point(inner, front_tex):
					continue
			if not _hitbox_blocked(player) and not _sprite_blocked(player):
				return true
		d += _CLAMP_STEP_PX
	return false


static func _rect_contains_point(rect: Rect2, point: Vector2) -> bool:
	# Inclusive on both ends so a zero-thin inset axis still accepts the center.
	return (
		point.x >= rect.position.x
		and point.y >= rect.position.y
		and point.x <= rect.end.x
		and point.y <= rect.end.y
	)


static func _inset_rect(rect: Rect2, inset: float) -> Rect2:
	var pos := rect.position
	var size := rect.size
	if size.x > 2.0 * inset:
		pos.x += inset
		size.x -= 2.0 * inset
	else:
		# Too thin to inset — pin to center with a 1px band for has-point checks.
		pos.x = rect.get_center().x - 0.5
		size.x = 1.0
	if size.y > 2.0 * inset:
		pos.y += inset
		size.y -= 2.0 * inset
	else:
		pos.y = rect.get_center().y - 0.5
		size.y = 1.0
	return Rect2(pos, size)


static func _front_radius_in_env(player: Node2D, env: Node2D) -> float:
	var r := _DEFAULT_FRONT_RADIUS
	if player is CharacterBody2D:
		var collision := _front_collision(player as CharacterBody2D)
		if collision != null and collision.shape is CircleShape2D:
			r = (collision.shape as CircleShape2D).radius
	var global_r := r * absf(player.global_scale.x)
	if is_instance_valid(env) and absf(env.global_scale.x) > 0.0001:
		return global_r / absf(env.global_scale.x)
	return global_r


static func _into_room_sign(enter_edge: PeekEdge, short_axis: int) -> float:
	# Match place_on_area: positive peek past BOTTOM/RIGHT goes +axis; TOP/LEFT go -axis.
	match enter_edge:
		PeekEdge.TOP:
			return -1.0 if short_axis == Vector2.AXIS_Y else 0.0
		PeekEdge.BOTTOM:
			return 1.0 if short_axis == Vector2.AXIS_Y else 0.0
		PeekEdge.LEFT:
			return -1.0 if short_axis == Vector2.AXIS_X else 0.0
		PeekEdge.RIGHT:
			return 1.0 if short_axis == Vector2.AXIS_X else 0.0
		_:
			return 1.0


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
