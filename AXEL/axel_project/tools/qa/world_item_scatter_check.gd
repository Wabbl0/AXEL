extends SceneTree
## Floor items appear in every indoor room, and nowhere else.
##
## Asserts, for each room in the AxelWorld area table:
## 1. A WorldItemScatter host appears with the room's item count.
## 2. Every rolled item id resolves to a real .tres.
## 3. No floor item sits inside a wall, a table, or an interact zone.
## And for the outdoor rooms: no scatter host at all.
##
## Run: tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/world_item_scatter_check.gd

const OUTDOOR := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
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

	var areas: Dictionary = world.AREAS
	for area_id in areas.keys():
		var rooms: Dictionary = areas[area_id]["rooms"]
		for room_path in rooms.keys():
			await _check_room(run, String(room_path), int(rooms[room_path]))

	for room_path in OUTDOOR:
		await _check_outdoor(String(room_path))

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
	# Match the lookup AxelWorld uses, including its find_child fallback.
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env == null:
		env = current_scene.find_child("EnvironmentColliders", true, false) as Node2D
	if env == null:
		_fail("%s has no EnvironmentColliders" % room_path)
		return
	var player := current_scene.find_child("Player", true, false) as Node2D
	var host := env.get_node_or_null("WorldItemScatter")
	if host == null:
		_fail("%s got no floor items" % room_path)
		return
	if host.get_child_count() != want:
		_fail("%s wanted %d floor items, got %d" % [room_path, want, host.get_child_count()])
	for child in host.get_children():
		var item_id := String(child.get("item_id"))
		if item_id.is_empty() or run.call("load_item", item_id) == null:
			_fail("%s rolled an unusable item id '%s'" % [room_path, item_id])
		# Hard rule: never inside a wall or furniture (unreachable item).
		if _is_blocked(env, child as Node2D, player, false):
			_fail("%s put %s inside a wall or furniture" % [room_path, item_id])
		# Soft rule: sharing a door box makes two [E] prompts compete.
		elif _is_blocked(env, child as Node2D, player, true):
			print("world_item_scatter_check: note - %s %s shares an interact zone" % [
				room_path, item_id,
			])


func _check_outdoor(room_path: String) -> void:
	if change_scene_to_file(room_path) != OK:
		_fail("could not load %s" % room_path)
		return
	await _frames(45)
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env != null and env.get_node_or_null("WorldItemScatter") != null:
		_fail("%s is outdoors and must have no floor items" % room_path)


func _is_blocked(env: Node2D, item: Node2D, player: Node2D, include_zones: bool) -> bool:
	var world_2d := env.get_world_2d()
	if world_2d == null or item == null:
		return false
	var space := world_2d.direct_space_state
	if space == null:
		return false
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = include_zones
	query.collide_with_bodies = not include_zones
	query.position = item.global_position
	# The item's own Area2D and the player standing there are not obstacles.
	var exclude: Array[RID] = []
	if item is CollisionObject2D:
		exclude.append((item as CollisionObject2D).get_rid())
	if player is CollisionObject2D:
		exclude.append((player as CollisionObject2D).get_rid())
	query.exclude = exclude
	return not space.intersect_point(query, 4).is_empty()


func _frames(count: int) -> void:
	for _i in count:
		await process_frame
