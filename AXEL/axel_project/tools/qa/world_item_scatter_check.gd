extends SceneTree

const NO_FLOOR_ITEMS := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_3/3.1_Backyard.tscn",
]

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame

	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		push_error("world_item_scatter_check: autoloads missing")
		quit(1)
		return
	world.call("reset_world")
	_check_item_seed_differs(world)

	var areas: Dictionary = world.AREAS
	for area_id in areas.keys():
		var rooms: Dictionary = areas[area_id]["rooms"]
		for room_path in rooms.keys():
			await _check_room(run, String(room_path), int(rooms[room_path]))

	for room_path in NO_FLOOR_ITEMS:
		await _check_no_floor_items(String(room_path))

	if _failures.is_empty():
		print("World item scatter check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("world_item_scatter_check: %s" % f)
		quit(1)


func _check_room(run: Node, room_path: String, want: int) -> void:
	if change_scene_to_file(room_path) != OK:
		_fail("could not load %s" % room_path)
		return
	await _frames(45)
	if current_scene == null or current_scene.scene_file_path != room_path:
		_fail("%s did not become the current scene (got %s)" % [
			room_path,
			"null" if current_scene == null else current_scene.scene_file_path,
		])
		return

	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env == null:
		env = current_scene.find_child("EnvironmentColliders", true, false) as Node2D
	if env == null:
		_fail("%s has no EnvironmentColliders" % room_path)
		return
	var player := current_scene.find_child("Player", true, false) as Node2D
	var host := env.get_node_or_null("WorldItemScatter")
	if want <= 0:
		if host != null:
			_fail("%s is a zero-item room but got a scatter host" % room_path)
		return
	if host == null:
		_fail("%s got no floor items" % room_path)
		return
	if host.get_child_count() != want:
		_fail("%s wanted %d floor items, got %d" % [room_path, want, host.get_child_count()])
	var player_layer := current_scene.get_node_or_null("PlayerLayer")
	for child in host.get_children():
		var item_id := String(child.get("item_id"))
		if item_id.is_empty() or run.call("load_item", item_id) == null:
			_fail("%s rolled an unusable item id '%s'" % [room_path, item_id])
		var marker: Node2D = null
		if child.has_method("floor_marker"):
			marker = child.call("floor_marker") as Node2D
		if marker == null:
			marker = child.get_node_or_null("ItemMarker") as Node2D
		if marker == null:
			_fail("%s %s is missing the shared item marker" % [room_path, item_id])
		elif player_layer != null and marker.get_parent() != player_layer:
			_fail("%s %s marker is not on PlayerLayer" % [room_path, item_id])
		if child.get_node_or_null("Icon") != null or child.get_node_or_null("Blob") != null:
			_fail("%s %s still draws its own catalog icon" % [room_path, item_id])

		if _circle_blocked(env, child as Node2D, player, host, false):
			_fail("%s put %s so its interact circle hits a wall or furniture" % [
				room_path, item_id,
			])

		elif _circle_blocked(env, child as Node2D, player, host, true):
			print("world_item_scatter_check: note - %s %s shares an interact zone" % [
				room_path, item_id,
			])


func _check_no_floor_items(room_path: String) -> void:
	if change_scene_to_file(room_path) != OK:
		_fail("could not load %s" % room_path)
		return
	await _frames(45)
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env != null and env.get_node_or_null("WorldItemScatter") != null:
		_fail("%s must have no floor items" % room_path)


func _circle_blocked(
	env: Node2D, item: Node2D, player: Node2D, host: Node, include_zones: bool
) -> bool:
	var world_2d := env.get_world_2d()
	if world_2d == null or item == null:
		return false
	var space := world_2d.direct_space_state
	if space == null:
		return false
	var shape_node := _first_collision_shape(item)
	if shape_node == null or shape_node.shape == null:
		return false
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = shape_node.global_transform
	params.collision_mask = 0xFFFFFFFF
	params.collide_with_areas = include_zones
	params.collide_with_bodies = not include_zones
	var exclude: Array[RID] = []
	if item is CollisionObject2D:
		exclude.append((item as CollisionObject2D).get_rid())
	if player is CollisionObject2D:
		exclude.append((player as CollisionObject2D).get_rid())
	if host != null:
		for sibling in host.get_children():
			if sibling is CollisionObject2D:
				exclude.append((sibling as CollisionObject2D).get_rid())
	params.exclude = exclude
	return not space.intersect_shape(params, 8).is_empty()


func _first_collision_shape(item: Node) -> CollisionShape2D:
	for child in item.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _check_item_seed_differs(world: Node) -> void:
	world.call("reset_world")
	world.call("plan_floor_items", 111)
	var a: Dictionary = world.call("to_dict")
	world.call("reset_world")
	world.call("plan_floor_items", 111)
	var same: Dictionary = world.call("to_dict")
	if _planned_ids(a) != _planned_ids(same):
		_fail("the same item seed must plan the same Common board")
	world.call("reset_world")
	world.call("plan_floor_items", 99991)
	var b: Dictionary = world.call("to_dict")
	if int(a.get("item_seed", 0)) == int(b.get("item_seed", 0)):
		_fail("plan_floor_items did not keep distinct item seeds")
	if _planned_ids(a) == _planned_ids(b):
		_fail("two item seeds planned the same floor item ids")
	world.call("reset_world")


func _planned_ids(data: Dictionary) -> PackedStringArray:
	var ids := PackedStringArray()
	var rooms: Dictionary = data.get("room_items", {})
	var paths: Array = rooms.keys()
	paths.sort()
	for path in paths:
		for entry in (rooms[path] as Array):
			ids.append(String((entry as Dictionary).get("id", "")))
	return ids
