extends SceneTree
## Headless lock: InteractArrival maps t along door boxes; 1.4 cafeteria peek Y
## must change with t. Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://scenes/core/test/interact_arrival_check.gd

const EPS := 0.02
const MIN_Y_GAP := 40.0
## Camera layout + deferred restore + deferred peek + 2 physics frames need settle.
const ARRIVAL_SETTLE_FRAMES := 10


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame
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
	if not await _test_kitchen_return_at_door():
		quit(1)
		return
	if not await _test_cafeteria_to_classrooms_inside_box():
		quit(1)
		return
	if not await _test_classrooms_to_cafeteria_inside_box():
		quit(1)
		return
	if not await _test_exterior_door_fraction():
		quit(1)
		return
	if not await _test_exterior_to_corridor_inside_box():
		quit(1)
		return
	if not await _test_exterior_to_corridor_handoff():
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


## 2.3 → 2.1: Player node lands on KitchenInteractArea X at texture Y 150 (~2040×150).
func _test_kitchen_return_at_door() -> bool:
	# Let any leftover deferred restore from earlier 2.1 loads finish first.
	await _await_frames(2)
	for t in [0.0, 0.5, 1.0]:
		if not await _assert_kitchen_return_at_door(t):
			return false
	return true


func _assert_kitchen_return_at_door(t: float) -> bool:
	_gm().call("set_kitchen_spawn_side", "kitchen_door")
	_gm().call("set_interact_arrival_t", t)
	var ps: PackedScene = load("res://scenes/Arc_2/2.1_Cafeteria.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 2.1 for kitchen return")
		return false
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env := scene.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var area := scene.get_node(
		"WalkableWorld/EnvironmentColliders/KitchenInteractArea"
	) as Area2D
	var tex: Vector2 = env.to_local(player.global_position)
	print("2.3→2.1 t=%s player_tex=%s" % [t, tex])
	var expected_x := 1905.0 + 278.0 * t
	if absf(tex.x - expected_x) > 40.0:
		push_error(
			"InteractArrival FAIL: 2.3→2.1 X off kitchen door (t=%s tex=%s expected_x=%s)"
			% [t, tex, expected_x]
		)
		scene.queue_free()
		await process_frame
		return false
	if absf(tex.y - 150.0) > 8.0:
		push_error(
			"InteractArrival FAIL: 2.3→2.1 Y off kitchen stand (t=%s tex=%s want y=150)"
			% [t, tex]
		)
		scene.queue_free()
		await process_frame
		return false
	var front := player.get_node("CollisionFront") as CollisionShape2D
	var front_tex := env.to_local(player.to_global(front.position))
	var box := InteractArrival._area_rect_in_env(area, env)
	var front_in_box := (
		front_tex.x >= box.position.x
		and front_tex.x <= box.end.x
		and front_tex.y >= box.position.y
		and front_tex.y <= box.end.y
	)
	print("2.3→2.1 t=%s front_tex=%s in_box=%s box=%s" % [t, front_tex, front_in_box, box])
	if not front_in_box:
		push_error(
			"InteractArrival FAIL: 2.3→2.1 Front not inside KitchenInteractArea (t=%s front=%s box=%s)"
			% [t, front_tex, box]
		)
		scene.queue_free()
		await process_frame
		return false
	scene.queue_free()
	await process_frame
	return true


## 2.1 → 2.4: Front stays on/near live CafeteriaInteractArea (Option B may sit
## just into-room of the box when the tall drawing must clear TopWall); t slides X.
func _test_cafeteria_to_classrooms_inside_box() -> bool:
	var xs: Array[float] = []
	for t in [0.1, 0.5, 0.9]:
		var result := await _spawn_24_from_cafeteria(t)
		if result.is_empty():
			return false
		xs.append(float(result["front_tex_x"]))
		print(
			"2.1→2.4 t=%s front_tex=%s in_or_just_in=%s sprite_clear=%s"
			% [t, result["front_tex"], result["in_or_just_in"], result["sprite_clear"]]
		)
		if not bool(result["in_or_just_in"]):
			push_error(
				"InteractArrival FAIL: 2.1→2.4 Front not in/just-into CafeteriaInteractArea (t=%s tex=%s)"
				% [t, result["front_tex"]]
			)
			return false
		if not bool(result["sprite_clear"]):
			push_error(
				"InteractArrival FAIL: 2.1→2.4 walk drawing overlaps TopWall (t=%s)"
				% t
			)
			return false
	if not (xs[0] < xs[1] and xs[1] < xs[2]):
		push_error(
			"InteractArrival FAIL: 2.1→2.4 X did not follow t (x0=%s x0.5=%s x0.9=%s)"
			% [xs[0], xs[1], xs[2]]
		)
		return false
	return true


func _spawn_24_from_cafeteria(t: float) -> Dictionary:
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_classrooms_corridor_spawn_side", "cafeteria_door")
	var ps: PackedScene = load("res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 2.4")
		return {}
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES + 4)
	var env := scene.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var area := scene.get_node(
		"WalkableWorld/EnvironmentColliders/CafeteriaInteractArea"
	) as Area2D
	var top_wall := scene.get_node(
		"WalkableWorld/EnvironmentColliders/TopWall"
	) as StaticBody2D
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var front := player.get_node("CollisionFront") as CollisionShape2D
	var front_global := player.to_global(front.position)
	var front_tex := env.to_local(front_global)
	var box := InteractArrival._area_rect_in_env(area, env)
	# X must stay on the box; Y may sit a little into-room past the bottom (Option B)
	# when the walk drawing needs to clear TopWall.
	var x_ok := front_tex.x >= box.position.x and front_tex.x <= box.end.x
	var y_ok := (
		front_tex.y >= box.position.y
		and front_tex.y <= box.end.y + 480.0
	)
	var in_or_just_in := x_ok and y_ok
	var sprite_clear := not _sprite_overlaps_static(player, top_wall)
	var out := {
		"front_tex": front_tex,
		"front_tex_x": front_tex.x,
		"in_or_just_in": in_or_just_in,
		"sprite_clear": sprite_clear,
	}
	scene.queue_free()
	await process_frame
	return out


## 2.4 → 2.1: Front on/near live ClassroomsInteractArea (Option B may sit
## just into-room past the top when BottomWall overlaps the box); t slides X.
func _test_classrooms_to_cafeteria_inside_box() -> bool:
	var xs: Array[float] = []
	for t in [0.1, 0.5, 0.9]:
		var result := await _spawn_21_from_classrooms(t)
		if result.is_empty():
			return false
		xs.append(float(result["front_tex_x"]))
		print(
			"2.4→2.1 t=%s front_tex=%s in_or_just_in=%s"
			% [t, result["front_tex"], result["in_or_just_in"]]
		)
		if not bool(result["in_or_just_in"]):
			push_error(
				"InteractArrival FAIL: 2.4→2.1 Front not in/just-into ClassroomsInteractArea (t=%s tex=%s)"
				% [t, result["front_tex"]]
			)
			return false
	if not (xs[0] < xs[1] and xs[1] < xs[2]):
		push_error(
			"InteractArrival FAIL: 2.4→2.1 X did not follow t (x0=%s x0.5=%s x0.9=%s)"
			% [xs[0], xs[1], xs[2]]
		)
		return false
	return true


func _spawn_21_from_classrooms(t: float) -> Dictionary:
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_cafeteria_spawn_side", "classrooms_bottom")
	var ps: PackedScene = load("res://scenes/Arc_2/2.1_Cafeteria.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 2.1 for classrooms return")
		return {}
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES + 4)
	var env := scene.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var area := scene.get_node(
		"WalkableWorld/EnvironmentColliders/ClassroomsInteractArea"
	) as Area2D
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var front := player.get_node("CollisionFront") as CollisionShape2D
	var front_global := player.to_global(front.position)
	var front_tex := env.to_local(front_global)
	var box := InteractArrival._area_rect_in_env(area, env)
	var x_ok := front_tex.x >= box.position.x and front_tex.x <= box.end.x
	# Into-room from this bottom door is -Y (above the box).
	var y_ok := (
		front_tex.y <= box.end.y
		and front_tex.y >= box.position.y - 480.0
	)
	var out := {
		"front_tex": front_tex,
		"front_tex_x": front_tex.x,
		"in_or_just_in": x_ok and y_ok,
	}
	scene.queue_free()
	await process_frame
	return out


## 1.1 DoorInteractArea: standing higher vs lower must change t (AXIS_Y).
func _test_exterior_door_fraction() -> bool:
	var ps: PackedScene = load("res://scenes/Arc_1/1.1_SchoolExterior.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 1.1")
		return false
	var scene: Node = ps.instantiate()
	if scene.get("skip_intro") != null:
		scene.set("skip_intro", true)
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env := scene.get_node_or_null("EnvironmentColliders") as Node2D
	var area := scene.get_node_or_null(
		"EnvironmentColliders/Doors/DoorInteractArea"
	) as Area2D
	var player := scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	if env == null or area == null or player == null:
		push_error("InteractArrival FAIL: 1.1 missing env/area/player")
		scene.queue_free()
		return false
	var box := InteractArrival._area_rect_in_env(area, env)
	print("1.1 DoorInteractArea box=%s" % box)
	if box.size.y < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 1.1 door box too short to map Y (box=%s)" % box
		)
		scene.queue_free()
		return false
	var top_tex := Vector2(box.get_center().x, box.position.y + 20.0)
	var bot_tex := Vector2(box.get_center().x, box.end.y - 20.0)
	var front := player.get_node("CollisionFront") as CollisionShape2D
	player.global_position = (
		env.to_global(top_tex) - (player.to_global(front.position) - player.global_position)
	)
	player.global_position = (
		env.to_global(top_tex) - (player.to_global(front.position) - player.global_position)
	)
	var t_top := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	player.global_position = (
		env.to_global(bot_tex) - (player.to_global(front.position) - player.global_position)
	)
	var t_bot := InteractArrival.fraction_along(player, area, Vector2.AXIS_Y)
	print("1.1 DoorInteractArea t top=%s bot=%s" % [t_top, t_bot])
	if t_bot - t_top < 0.4:
		push_error(
			"InteractArrival FAIL: 1.1 fraction_along top/bot too close (top=%s bot=%s)"
			% [t_top, t_bot]
		)
		scene.queue_free()
		return false
	scene.queue_free()
	await process_frame
	return true


## 1.1 → 1.2: Front on/near live ExteriorInteractArea; t slides Y.
func _test_exterior_to_corridor_inside_box() -> bool:
	var ys: Array[float] = []
	for t in [0.1, 0.5, 0.9]:
		var result := await _spawn_12_from_exterior(t)
		if result.is_empty():
			return false
		ys.append(float(result["front_tex_y"]))
		print(
			"1.1→1.2 t=%s front_tex=%s in_or_just_in=%s"
			% [t, result["front_tex"], result["in_or_just_in"]]
		)
		if not bool(result["in_or_just_in"]):
			push_error(
				"InteractArrival FAIL: 1.1→1.2 Front not in/just-into ExteriorInteractArea (t=%s tex=%s)"
				% [t, result["front_tex"]]
			)
			return false
	if not (ys[0] < ys[1] and ys[1] < ys[2]):
		push_error(
			"InteractArrival FAIL: 1.1→1.2 Y did not follow t (y0.1=%s y0.5=%s y0.9=%s)"
			% [ys[0], ys[1], ys[2]]
		)
		return false
	return true


func _spawn_12_from_exterior(t: float) -> Dictionary:
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_corridor_spawn_side", "exterior_door")
	var ps: PackedScene = load("res://scenes/Arc_1/1.2_Corridor.tscn")
	if ps == null:
		push_error("InteractArrival FAIL: could not load 1.2")
		return {}
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES + 4)
	var env := scene.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var area := scene.get_node(
		"WalkableWorld/EnvironmentColliders/ExteriorInteractArea"
	) as Area2D
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var front := player.get_node("CollisionFront") as CollisionShape2D
	var front_global := player.to_global(front.position)
	var front_tex := env.to_local(front_global)
	var box := InteractArrival._area_rect_in_env(area, env)
	# Y must stay on the box; X may sit a little into-room past the right
	# (Option B) when the walk drawing needs to clear LeftWall.
	var y_ok := front_tex.y >= box.position.y and front_tex.y <= box.end.y
	var x_ok := (
		front_tex.x >= box.position.x
		and front_tex.x <= box.end.x + 480.0
	)
	var out := {
		"front_tex": front_tex,
		"front_tex_y": front_tex.y,
		"in_or_just_in": x_ok and y_ok,
	}
	scene.queue_free()
	await process_frame
	return out


## Real leave→arrive: measure t on 1.1 DoorInteractArea, then load 1.2.
func _test_exterior_to_corridor_handoff() -> bool:
	var y_top := await _handoff_11_to_12_tex_y(true)
	var y_bot := await _handoff_11_to_12_tex_y(false)
	print("1.1→1.2 handoff tex.y top=%s bot=%s" % [y_top, y_bot])
	if y_bot - y_top < MIN_Y_GAP:
		push_error(
			"InteractArrival FAIL: 1.1→1.2 handoff Y did not follow leave height (top=%s bot=%s)"
			% [y_top, y_bot]
		)
		return false
	return true


func _handoff_11_to_12_tex_y(stand_near_top: bool) -> float:
	var ps11: PackedScene = load("res://scenes/Arc_1/1.1_SchoolExterior.tscn")
	var scene11: Node = ps11.instantiate()
	if scene11.get("skip_intro") != null:
		scene11.set("skip_intro", true)
	root.add_child(scene11)
	if not scene11.is_node_ready():
		await scene11.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES)
	var env11 := scene11.get_node("EnvironmentColliders") as Node2D
	var area := scene11.get_node(
		"EnvironmentColliders/Doors/DoorInteractArea"
	) as Area2D
	var player11 := scene11.get_node("PlayerLayer/Player") as CharacterBody2D
	var box := InteractArrival._area_rect_in_env(area, env11)
	var local_y := box.position.y + 20.0 if stand_near_top else box.end.y - 20.0
	var tex := Vector2(box.get_center().x, local_y)
	var front := player11.get_node("CollisionFront") as CollisionShape2D
	player11.global_position = (
		env11.to_global(tex) - (player11.to_global(front.position) - player11.global_position)
	)
	player11.global_position = (
		env11.to_global(tex) - (player11.to_global(front.position) - player11.global_position)
	)
	var t := InteractArrival.fraction_along(player11, area, Vector2.AXIS_Y)
	_gm().call("set_interact_arrival_t", t)
	_gm().call("set_corridor_spawn_side", "exterior_door")
	scene11.queue_free()
	await process_frame

	var ps12: PackedScene = load("res://scenes/Arc_1/1.2_Corridor.tscn")
	var scene12: Node = ps12.instantiate()
	root.add_child(scene12)
	if not scene12.is_node_ready():
		await scene12.ready
	await _await_frames(ARRIVAL_SETTLE_FRAMES + 4)
	var env12 := scene12.get_node("WalkableWorld/EnvironmentColliders") as Node2D
	var player12 := scene12.get_node("PlayerLayer/Player") as CharacterBody2D
	var tex12 := env12.to_local(player12.global_position)
	scene12.queue_free()
	await process_frame
	return tex12.y


func _sprite_overlaps_static(player: CharacterBody2D, body: StaticBody2D) -> bool:
	var spr := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null or body == null:
		return false
	var anim := spr.animation
	if not spr.sprite_frames.has_animation(anim):
		return false
	var frame_count := spr.sprite_frames.get_frame_count(anim)
	if frame_count <= 0:
		return false
	var tex := spr.sprite_frames.get_frame_texture(anim, clampi(spr.frame, 0, frame_count - 1))
	if tex == null:
		return false
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
	var aabb := Rect2(min_v, max_v - min_v).grow(8.0)
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return false
	var rect_shape := shape_node.shape as RectangleShape2D
	var half_w := rect_shape.size * 0.5
	var wall_corners: Array[Vector2] = [
		shape_node.to_global(Vector2(-half_w.x, -half_w.y)),
		shape_node.to_global(Vector2(half_w.x, -half_w.y)),
		shape_node.to_global(Vector2(-half_w.x, half_w.y)),
		shape_node.to_global(Vector2(half_w.x, half_w.y)),
	]
	var wmin := wall_corners[0]
	var wmax := wall_corners[0]
	for i in range(1, wall_corners.size()):
		wmin = wmin.min(wall_corners[i])
		wmax = wmax.max(wall_corners[i])
	var wall_rect := Rect2(wmin, wmax - wmin)
	return aabb.intersects(wall_rect)
