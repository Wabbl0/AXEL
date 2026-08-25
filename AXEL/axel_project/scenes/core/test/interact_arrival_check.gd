extends SceneTree
## Headless lock: InteractArrival maps t along door boxes; 1.4 cafeteria peek Y
## must change with t. Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://scenes/core/test/interact_arrival_check.gd

const EPS := 0.02
const MIN_Y_GAP := 40.0
## Camera layout + deferred restore + deferred peek need several frames.
const ARRIVAL_SETTLE_FRAMES := 6


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	if not _test_synthetic_fraction_and_place():
		quit(1)
		return
	if not await _test_cafeteria_return_fraction():
		quit(1)
		return
	if not await _test_basement_arrival_y_varies():
		quit(1)
		return
	if not await _test_corridor_exit_arrival_y_varies():
		quit(1)
		return
	if not await _test_cafeteria_to_basement_handoff():
		quit(1)
		return
	if not await _test_basement_to_cafeteria_handoff():
		quit(1)
		return
	print("InteractArrival check OK.")
	quit(0)


func _test_synthetic_fraction_and_place() -> bool:
	var env := Node2D.new()
	env.name = "EnvironmentColliders"
	root.add_child(env)
	var area := Area2D.new()
	area.position = Vector2(180, 1900)
	env.add_child(area)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	shape_node.position = Vector2(-49.5, -466.5)
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(143, 751)
	shape_node.shape = rect_shape
	area.add_child(shape_node)

	var player := CharacterBody2D.new()
	player.scale = Vector2(0.2975205, 0.2975205)
	var front := CollisionShape2D.new()
	front.name = "CollisionFront"
	front.position = Vector2(-37.812428, 126.04143)
	front.shape = CircleShape2D.new()
	player.add_child(front)
	root.add_child(player)

	# Top vs bottom of the box in env/texture space (hitbox sample).
	var top_tex := Vector2(130.5, 1058.0 + 8.0)
	var bot_tex := Vector2(130.5, 1809.0 - 8.0)
	player.global_position = env.to_global(top_tex) - (front.global_position - player.global_position)
	# Recompute after first assign so offset is stable.
	player.global_position = env.to_global(top_tex) - (player.to_global(front.position) - player.global_position)
	var t_top := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	player.global_position = env.to_global(bot_tex) - (player.to_global(front.position) - player.global_position)
	var t_bot := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	if t_bot - t_top < 0.5:
		push_error(
			"InteractArrival FAIL: synthetic t did not span the box (top=%s bot=%s)"
			% [t_top, t_bot]
		)
		return false

	var dest := Area2D.new()
	dest.position = Vector2(2232, 701)
	env.add_child(dest)
	var dest_shape := CollisionShape2D.new()
	dest_shape.name = "CollisionShape2D"
	dest_shape.position = Vector2(-95.94873, 459.2566)
	var dest_rect := RectangleShape2D.new()
	dest_rect.size = Vector2(143.89746, 521.978)
	dest_shape.shape = dest_rect
	dest.add_child(dest_shape)

	var p0 := InteractArrival.place_on_area(
		player, dest, 0.0, Vector2.AXIS_Y, InteractArrival.PeekEdge.LEFT, -12.0
	)
	var p1 := InteractArrival.place_on_area(
		player, dest, 1.0, Vector2.AXIS_Y, InteractArrival.PeekEdge.LEFT, -12.0
	)
	if p1.y - p0.y < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: place_on_area t=0 vs t=1 too close (%s vs %s)"
			% [p0, p1]
		)
		return false

	env.queue_free()
	player.queue_free()
	return true


func _test_cafeteria_return_fraction() -> bool:
	var ps: PackedScene = load("res://scenes/Arc_2/2.1_Cafeteria.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 2.1")
		return false
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await process_frame
	await process_frame

	var env := scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var area := scene.get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ReturnInteractArea"
	) as Area2D
	var player := scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	if env == null or area == null or player == null:
		push_error("InteractArrival FAIL: 2.1 missing env/area/player")
		scene.queue_free()
		return false

	var shape := area.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	var half := rect.size * 0.5
	var top_local := Vector2(0.0, -half.y + 20.0)
	var bot_local := Vector2(0.0, half.y - 20.0)
	player.global_position = shape.to_global(top_local)
	var t_top := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	player.global_position = shape.to_global(bot_local)
	var t_bot := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	print("2.1 ReturnInteractArea t top=%s bot=%s" % [t_top, t_bot])
	if t_bot - t_top < 0.4:
		push_error(
			"InteractArrival FAIL: 2.1 fraction_along top/bot too close (top=%s bot=%s)"
			% [t_top, t_bot]
		)
		scene.queue_free()
		return false
	scene.queue_free()
	await process_frame
	return true


func _test_basement_arrival_y_varies() -> bool:
	var y0 := await _spawn_14_tex_y(0.0, "cafeteria_right")
	var y1 := await _spawn_14_tex_y(1.0, "cafeteria_right")
	print("1.4 cafeteria arrival tex.y t0=%s t1=%s" % [y0, y1])
	if y1 - y0 < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 1.4 cafeteria spawn Y did not follow t (t0=%s t1=%s)"
			% [y0, y1]
		)
		return false
	return true


func _test_corridor_exit_arrival_y_varies() -> bool:
	var y0 := await _spawn_14_tex_y(0.0, "corridor_left")
	var y1 := await _spawn_14_tex_y(1.0, "corridor_left")
	print("1.4 corridor ExitTrigger arrival tex.y t0=%s t1=%s" % [y0, y1])
	if y1 - y0 < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 1.4 corridor spawn Y did not follow t (t0=%s t1=%s)"
			% [y0, y1]
		)
		return false
	return true


func _gm() -> Node:
	return root.get_node("GameManager")


func _await_frames(n: int) -> void:
	for _i in n:
		await process_frame


func _spawn_14_tex_y(t: float, spawn_side: String) -> float:
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_basement_spawn_side", spawn_side)
	var ps: PackedScene = load("res://scenes/Arc_1/1.4_BasementDoor.tscn")
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env := scene.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var tex := env.to_local(player.global_position)
	scene.queue_free()
	await process_frame
	return tex.y


## Real leave→arrive: measure t on 2.1 ReturnInteractArea, then load 1.4.
func _test_cafeteria_to_basement_handoff() -> bool:
	var y_top := await _handoff_21_to_14_tex_y(true)
	var y_bot := await _handoff_21_to_14_tex_y(false)
	print("2.1→1.4 handoff tex.y top=%s bot=%s" % [y_top, y_bot])
	if y_bot - y_top < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 2.1→1.4 handoff Y did not follow leave height (top=%s bot=%s)"
			% [y_top, y_bot]
		)
		return false
	return true


func _handoff_21_to_14_tex_y(stand_near_top: bool) -> float:
	var ps21: PackedScene = load("res://scenes/Arc_2/2.1_Cafeteria.tscn")
	var scene21: Node = ps21.instantiate()
	root.add_child(scene21)
	if not scene21.is_node_ready():
		await scene21.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var area := scene21.get_node(
		"WalkableWorld/EnvironmentColliders/ReturnInteractArea"
	) as Area2D
	var player21 := scene21.get_node("PlayerLayer/Player") as CharacterBody2D
	var shape := area.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	var half := rect.size * 0.5
	var local := Vector2(0.0, -half.y + 20.0) if stand_near_top else Vector2(0.0, half.y - 20.0)
	player21.global_position = shape.to_global(local)
	var t := InteractArrival.fraction_along(player21, area, Vector2.AXIS_Y)
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_basement_spawn_side", "cafeteria_right")
	scene21.queue_free()
	await process_frame

	var ps14: PackedScene = load("res://scenes/Arc_1/1.4_BasementDoor.tscn")
	var scene14: Node = ps14.instantiate()
	root.add_child(scene14)
	if not scene14.is_node_ready():
		await scene14.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env := scene14.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var player14 := scene14.get_node("PlayerLayer/Player") as CharacterBody2D
	var tex := env.to_local(player14.global_position)
	scene14.queue_free()
	await process_frame
	return tex.y


## Reverse [E]: measure t on 1.4 CafeteriaInteractArea, then load 2.1.
func _test_basement_to_cafeteria_handoff() -> bool:
	var y_top := await _handoff_14_to_21_tex_y(true)
	var y_bot := await _handoff_14_to_21_tex_y(false)
	print("1.4→2.1 handoff tex.y top=%s bot=%s" % [y_top, y_bot])
	if y_bot - y_top < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 1.4→2.1 handoff Y did not follow leave height (top=%s bot=%s)"
			% [y_top, y_bot]
		)
		return false
	return true


func _handoff_14_to_21_tex_y(stand_near_top: bool) -> float:
	var ps14: PackedScene = load("res://scenes/Arc_1/1.4_BasementDoor.tscn")
	var scene14: Node = ps14.instantiate()
	root.add_child(scene14)
	if not scene14.is_node_ready():
		await scene14.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var area := scene14.get_node(
		"WalkableWorld/EnvironmentColliders/CafeteriaInteractArea"
	) as Area2D
	var player14 := scene14.get_node("PlayerLayer/Player") as CharacterBody2D
	var shape := area.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	var half := rect.size * 0.5
	var local := Vector2(0.0, -half.y + 20.0) if stand_near_top else Vector2(0.0, half.y - 20.0)
	player14.global_position = shape.to_global(local)
	var t := InteractArrival.fraction_along(player14, area, Vector2.AXIS_Y)
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_cafeteria_spawn_side", "basement_left")
	scene14.queue_free()
	await process_frame

	var ps21: PackedScene = load("res://scenes/Arc_2/2.1_Cafeteria.tscn")
	var scene21: Node = ps21.instantiate()
	root.add_child(scene21)
	if not scene21.is_node_ready():
		await scene21.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env := scene21.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var player21 := scene21.get_node("PlayerLayer/Player") as CharacterBody2D
	var tex := env.to_local(player21.global_position)
	scene21.queue_free()
	await process_frame
	return tex.y
