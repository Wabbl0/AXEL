extends SceneTree

const NO_FLOOR_ITEMS := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_3/3.1_Backyard.tscn",
]
const BASEMENT := "res://scenes/Arc_1/1.4_BasementDoor.tscn"

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
	await _check_basement_spots(world, run)

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
		elif not _hand_on_floor(env, child as Node2D):
			_fail("%s put %s off the floor Mike can walk" % [room_path, item_id])

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


func _hand_on_floor(env: Node2D, item: Node2D) -> bool:
	var world := root.get_node_or_null("AxelWorld")
	var scene := current_scene
	if world == null or scene == null or item == null or not world.has_method("hand_reaches_player"):
		return false
	return bool(world.call("hand_reaches_player", scene, env.to_local(item.global_position)))


func _first_collision_shape(item: Node) -> CollisionShape2D:
	for child in item.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _check_basement_spots(world: Node, run: Node) -> void:
	var first := await _basement_hand(world, run, 111)
	var again := await _basement_hand(world, run, 111)
	if first == Vector2.INF or again == Vector2.INF:
		_fail("1.4 did not place a floor hand on the first load")
		return
	if absf(first.x) < 0.5 and absf(first.y) < 0.5:
		_fail("1.4 placed its hand at 0,0")
	if first.distance_to(again) > 1.0:
		_fail("the same item seed moved the 1.4 hand")
	var found_other := false
	for seed in [2, 3, 5, 8, 13, 21, 34, 55]:
		var other := await _basement_hand(world, run, seed)
		if other == Vector2.INF:
			return
		if first.distance_to(other) >= 32.0:
			found_other = true
			break
	if not found_other:
		_fail("different item seeds all placed the 1.4 hand in the same spot")


func _basement_hand(world: Node, run: Node, seed: int) -> Vector2:
	world.call("reset_world")
	world.call("plan_floor_items", seed)
	if change_scene_to_file(BASEMENT) != OK:
		_fail("could not load 1.4 for seed %d" % seed)
		return Vector2.INF
	await _frames(45)
	if current_scene == null or current_scene.scene_file_path != BASEMENT:
		_fail("1.4 did not become current for seed %d" % seed)
		return Vector2.INF
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env == null:
		_fail("1.4 has no EnvironmentColliders")
		return Vector2.INF
	var host := env.get_node_or_null("WorldItemScatter")
	if host == null or host.get_child_count() != 1:
		_fail("1.4 seed %d wanted 1 floor hand, got %d" % [
			seed, 0 if host == null else host.get_child_count(),
		])
		return Vector2.INF
	var hand := host.get_child(0) as Node2D
	var player := current_scene.find_child("Player", true, false) as Node2D
	if _circle_blocked(env, hand, player, host, false):
		_fail("1.4 seed %d hand circle hits a wall" % seed)
	elif not _hand_on_floor(env, hand):
		_fail("1.4 seed %d hand is off the floor Mike can walk" % seed)
	if run.call("load_item", String(hand.get("item_id"))) == null:
		_fail("1.4 seed %d rolled an unusable item" % seed)
	return hand.position


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
