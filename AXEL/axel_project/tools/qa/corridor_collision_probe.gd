extends SceneTree

const SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1400, 900)
	await process_frame
	await process_frame

	var ps := load(SCENE) as PackedScene
	var scene := ps.instantiate() as Node2D
	root.add_child(scene)
	await process_frame
	if not scene.is_node_ready():
		await scene.ready
	for _i in 20:
		await physics_frame
	await process_frame
	scene.call_deferred("_apply_background_layout")
	await physics_frame

	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var left_wall := scene.get_node("WalkableWorld/EnvironmentColliders/LeftWall") as StaticBody2D
	var right_wall := scene.get_node("WalkableWorld/EnvironmentColliders/RightWall") as StaticBody2D

	scene.get_node("PlayerLayer").follow_viewport_enabled = false
	await physics_frame

	var space := player.get_world_2d().direct_space_state
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.collide_with_bodies = true
	var point_hit_names: PackedStringArray = PackedStringArray()
	var point_hits: Array = []
	for probe_pos in [Vector2(40.0, 420.0), Vector2(3.0, 456.0), Vector2(321.0, 420.0), left_wall.global_position]:
		point_query.position = probe_pos
		point_hits = space.intersect_point(point_query, 8)
		point_hit_names.clear()
		for hit in point_hits:
			if hit.has("collider") and hit.collider:
				point_hit_names.append(String(hit.collider.name))
		print("PROBE_POINT pos=%s hits=%s" % [probe_pos, point_hit_names])

	player.set_input_enabled(false)
	player.global_position = Vector2(100.0, 420.0)
	for _i in 40:
		player.set_scripted_velocity(Vector2(-540.0, 0.0))
		await physics_frame
	print("PROBE_LEFT_Y420 x=%.1f hit=%s" % [player.global_position.x, _last_hit_name(player)])

	player.global_position = Vector2(500.0, 420.0)
	await physics_frame

	var start_x := player.global_position.x
	for _i in 40:
		player.set_scripted_velocity(Vector2(-540.0, 0.0))
		await physics_frame
	var left_x := player.global_position.x
	var left_hit := _last_hit_name(player)

	player.global_position = Vector2(500.0, 420.0)
	for _i in 40:
		player.set_scripted_velocity(Vector2(540.0, 0.0))
		await physics_frame
	var right_x := player.global_position.x
	var right_hit := _last_hit_name(player)

	print(
		"CORRIDOR_COLLISION_PROBE walls left=%s right=%s start=%.1f left_x=%.1f right_x=%.1f left_hit=%s right_hit=%s"
		% [left_wall.global_position, right_wall.global_position, start_x, left_x, right_x, left_hit, right_hit]
	)

	var left_blocked := left_x > left_wall.global_position.x + 30.0
	var right_blocked := right_x < right_wall.global_position.x - 30.0
	if not left_blocked or not right_blocked:
		push_error("PROBE_FAIL expected horizontal wall blocks")
		quit(1)
		return
	print("CORRIDOR_COLLISION_PROBE OK")
	quit(0)


func _last_hit_name(player: CharacterBody2D) -> String:
	if player.get_slide_collision_count() == 0:
		return ""
	var col := player.get_slide_collision(player.get_slide_collision_count() - 1)
	var body := col.get_collider()
	return String(body.name) if body else ""
