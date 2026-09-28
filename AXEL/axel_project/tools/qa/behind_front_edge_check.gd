extends SceneTree

const _MATCH_PX := 4.0
const _FRAME_TRIES := 30

const _ROOMS := [
	{
		"path": "res://scenes/Arc_5/5.1_Classroom.tscn",
		"colliders": "WalkableWorld/EnvironmentColliders",
		"anchor_y": 0,
		"slots": [
			{"kind": "polygon", "zone": "FurnitureBlock6_Behind"},
			{"kind": "polygon", "zone": "FurnitureBlock7_Behind"},
			{"kind": "polygon", "zone": "FurnitureBlock8_Behind"},
			{"kind": "polygon", "zone": "FurnitureBlock9_Behind"},
		],
	},
	{
		"path": "res://scenes/Arc_3/3.1_Backyard.tscn",
		"colliders": "WalkableWorld/EnvironmentColliders",
		"anchor_y": 1,
		"slots": [
			{"kind": "polygon", "zone": "Wall_Behind"},
			{"kind": "polygon", "zone": "Bush_Behind"},
			{"kind": "polygon", "zone": "Well_Behind"},
		],
	},
	{
		"path": "res://scenes/Arc_1/1.1_SchoolExterior.tscn",
		"colliders": "EnvironmentColliders",
		"anchor_y": 0,
		"slots": [
			{"kind": "trunk", "zone": "TreeLine_Bottom_Behind", "body": "TreeLine_Bottom"},
			{"kind": "trunk", "zone": "TreeLine_Top_Behind", "body": "TreeLine_Top"},
			{"kind": "open", "zone": "RightWall_Behind"},
			{"kind": "polygon", "zone": "Stump_Left_Behind"},
			{"kind": "polygon", "zone": "Rocks_Left_Behind"},
			{"kind": "polygon", "zone": "Rocks_Right_Behind"},
		],
	},
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	for room in _ROOMS:
		if not await _check_room(room):
			quit(1)
			return
	print("Behind front-edge check OK.")
	quit(0)


func _check_room(room: Dictionary) -> bool:
	var path: String = room["path"]
	var packed := load(path) as PackedScene
	if packed == null:
		_fail("could not load %s" % path)
		return false
	var node := packed.instantiate()
	root.add_child(node)
	if not node.is_node_ready():
		await node.ready
	var player := node.get_node_or_null("PlayerLayer/Player")
	var sprite: CanvasItem = null
	if player != null:
		sprite = player.get_node_or_null("AnimatedSprite") as CanvasItem
	var mat: ShaderMaterial = null
	for _i in _FRAME_TRIES:
		await process_frame
		if sprite != null:
			mat = sprite.material as ShaderMaterial
	if sprite != null:
		mat = sprite.material as ShaderMaterial
	if mat == null:
		_fail("%s Mike has no fade material" % path)
		node.queue_free()
		return false
	var anchor := int(mat.get_shader_parameter("leaf_mask_use_anchor_y"))
	if anchor != int(room["anchor_y"]):
		_fail("%s feet-sample flag=%d expected %d" % [path, anchor, int(room["anchor_y"])])
		node.queue_free()
		return false
	var colliders := node.get_node_or_null(room["colliders"])
	if colliders == null:
		_fail("%s missing colliders" % path)
		node.queue_free()
		return false
	var slots: Array = room["slots"]
	for slot in slots.size():
		var spec: Dictionary = slots[slot]
		var kind: String = spec["kind"]
		if kind == "polygon":
			if not _check_polygon_front(path, mat, colliders, spec["zone"], slot):
				node.queue_free()
				return false
		elif kind == "trunk":
			if not _check_trunk(path, mat, colliders, spec, slot):
				node.queue_free()
				return false
		elif kind == "open":
			var cutoff := float(mat.get_shader_parameter("leaf_y_cutoff_%d" % slot))
			if cutoff < 1.0e8:
				_fail("%s %s cutoff=%.2f should stay open" % [path, spec["zone"], cutoff])
				node.queue_free()
				return false
		else:
			_fail("%s unknown slot kind %s" % [path, kind])
			node.queue_free()
			return false
	node.queue_free()
	await process_frame
	return true


func _check_polygon_front(
	path: String,
	mat: ShaderMaterial,
	colliders: Node,
	zone_name: String,
	slot: int,
) -> bool:
	var want := _zone_front_y(colliders, zone_name)
	var cutoff := float(mat.get_shader_parameter("leaf_y_cutoff_%d" % slot))
	if want < 0.0 or absf(cutoff - want) > _MATCH_PX:
		_fail(
			"%s %s cutoff=%.2f polygon front=%.2f" % [path, zone_name, cutoff, want]
		)
		return false
	var parts: Vector4 = mat.get_shader_parameter("leaf_poly_%d_part_cutoffs" % slot)
	var zone := colliders.get_node_or_null(zone_name) as Area2D
	if zone != null and zone.has_method("get_shader_polygons"):
		var polys: Array = zone.call("get_shader_polygons")
		for part_i in mini(polys.size(), 4):
			var part_y := _packed_max_y(polys[part_i])
			var got := _part_at(parts, part_i)
			if got == 0.0:
				got = cutoff
			if absf(got - part_y) > _MATCH_PX:
				_fail(
					"%s %s part %d cutoff=%.2f polygon front=%.2f"
					% [path, zone_name, part_i, got, part_y]
				)
				return false
	return true


func _check_trunk(
	path: String,
	mat: ShaderMaterial,
	colliders: Node,
	trunk: Dictionary,
	slot: int,
) -> bool:
	var zone_name: String = trunk["zone"]
	var body_name: String = trunk["body"]
	var cutoff := float(mat.get_shader_parameter("leaf_y_cutoff_%d" % slot))
	var trunk_y := _body_front_y(colliders, body_name)
	var canopy_y := _zone_front_y(colliders, zone_name)
	if absf(cutoff - trunk_y) > _MATCH_PX:
		_fail("%s %s cutoff=%.2f trunk=%.2f" % [path, zone_name, cutoff, trunk_y])
		return false
	if absf(cutoff - canopy_y) <= _MATCH_PX:
		_fail(
			"%s %s cutoff=%.2f matches the canopy (%.2f), not only the trunk"
			% [path, zone_name, cutoff, canopy_y]
		)
		return false
	return true


func _zone_front_y(colliders: Node, zone_name: String) -> float:
	var zone := colliders.get_node_or_null(zone_name) as Area2D
	if zone == null or not zone.has_method("get_shader_polygons"):
		return -1.0
	var max_y := -INF
	for poly in zone.call("get_shader_polygons"):
		max_y = maxf(max_y, _packed_max_y(poly))
	return max_y


func _body_front_y(colliders: Node, body_name: String) -> float:
	var body := colliders.get_node_or_null(body_name) as StaticBody2D
	if body == null:
		return -1.0
	var max_y := -INF
	for child in body.get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.is_empty():
			continue
		for point in polygon_node.polygon:
			max_y = maxf(max_y, polygon_node.to_global(point).y)
	return max_y


func _packed_max_y(poly: PackedVector2Array) -> float:
	var max_y := -INF
	for point in poly:
		max_y = maxf(max_y, point.y)
	return max_y


func _part_at(parts: Vector4, part_i: int) -> float:
	match part_i:
		0:
			return parts.x
		1:
			return parts.y
		2:
			return parts.z
		_:
			return parts.w


func _fail(message: String) -> void:
	push_error("Behind front-edge FAIL: %s" % message)
