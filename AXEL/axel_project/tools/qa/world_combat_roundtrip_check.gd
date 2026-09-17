extends SceneTree

const ROOM := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const COMBAT_PREFIX := "res://combat/"
const EXPECTED_ITEMS := 3
const SPOT_TOLERANCE_TEX := 4.0

var _failures: Array[String] = []


func _init() -> void:
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
		push_error("world_combat_roundtrip_check: autoloads missing")
		quit(1)
		return
	world.call("reset_world")

	if change_scene_to_file(ROOM) != OK:
		push_error("world_combat_roundtrip_check: could not load %s" % ROOM)
		quit(1)
		return
	await _frames(40)

	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var player := current_scene.get_node_or_null("PlayerLayer/Player") as Node2D
	if env == null or player == null:
		push_error("world_combat_roundtrip_check: room tree missing env/player")
		quit(1)
		return


	var host := env.get_node_or_null("WorldItemScatter")
	if host == null:
		_fail("no WorldItemScatter host under EnvironmentColliders")
	elif host.get_child_count() != EXPECTED_ITEMS:
		_fail("expected %d floor items, got %d" % [EXPECTED_ITEMS, host.get_child_count()])
	else:
		for child in host.get_children():
			var item_id := String(child.get("item_id"))
			if item_id.is_empty():
				_fail("floor item has no item id")
			elif not item_id.begins_with("C"):
				_fail("first area should roll Common, got %s" % item_id)

	var act_before := int(run.state.act)
	var index_before := int(run.state.encounter_index)
	var spot_before := env.to_local(player.global_position)


	if not bool(world.call("start_fight_here", "walk")):
		push_error("world_combat_roundtrip_check: start_fight_here refused")
		quit(1)
		return
	if not await _wait_for_scene_prefix(COMBAT_PREFIX, 400):
		push_error("world_combat_roundtrip_check: combat scene never loaded")
		quit(1)
		return
	if not bool(run.call("is_in_encounter")):
		_fail("run should be in an encounter inside combat")
	if not bool(run.state.world_encounter):
		_fail("world_encounter flag should be set")


	var fx := root.get_node_or_null("AxelEventFx")
	if not await _wait_for_wipe_open(fx, 3.0):
		_fail("combat wipe never opened on the combat board")


	run.call("on_encounter_finished", true)
	if not await _wait_for_scene_path(ROOM, 400):
		push_error("world_combat_roundtrip_check: never returned to %s" % ROOM)
		quit(1)
		return
	await _seconds(1.0)
	await _frames(30)

	var env_back := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var player_back := current_scene.get_node_or_null("PlayerLayer/Player") as Node2D
	if env_back == null or player_back == null:
		_fail("returned room is missing env/player")
	else:
		var spot_after := env_back.to_local(player_back.global_position)
		var drift := spot_before.distance_to(spot_after)
		if drift > SPOT_TOLERANCE_TEX:
			_fail("player drifted %.1f texture px on return (limit %.1f)" % [drift, SPOT_TOLERANCE_TEX])


	if int(run.state.act) != act_before or int(run.state.encounter_index) != index_before:
		_fail("world fight moved the act pointer (%d/%d -> %d/%d)" % [
			act_before, index_before, int(run.state.act), int(run.state.encounter_index),
		])
	if bool(run.state.world_encounter):
		_fail("world_encounter flag should be cleared after the win")


	if fx != null and fx.has_method("is_combat_wipe_covered"):
		if bool(fx.call("is_combat_wipe_covered")):
			_fail("combat wipe still covering the screen after the fight")

	await _check_floor_pickup(world, run, fx)

	if _failures.is_empty():
		print("World combat round trip check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("world_combat_roundtrip_check: %s" % f)
		quit(1)


func _check_floor_pickup(world: Node, run: Node, fx: Node) -> void:
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var player := current_scene.get_node_or_null("PlayerLayer/Player") as Node2D
	var host := env.get_node_or_null("WorldItemScatter") if env != null else null
	if host == null or host.get_child_count() == 0:
		_fail("no floor items left to test pickup")
		return
	var pickup := host.get_child(0)
	var item_id := String(pickup.get("item_id"))
	var count_before := host.get_child_count()


	player.global_position = (pickup as Node2D).global_position
	for _i in 20:
		await physics_frame
	if not bool(pickup.get("_player_inside")):
		_fail("standing on the floor item did not register the player")


	pickup.call("_take")
	if not Array(run.state.owned_item_ids).has(item_id):
		_fail("floor item %s did not reach the locker" % item_id)
	if not await _wait_for_scene_prefix(COMBAT_PREFIX, 400):
		_fail("floor item pickup did not start a fight")
		return
	if not await _wait_for_wipe_open(fx, 3.0):
		_fail("wipe never opened after a pickup fight")
	run.call("on_encounter_finished", true)
	if not await _wait_for_scene_path(ROOM, 400):
		_fail("pickup fight did not return to the room")
		return
	await _seconds(1.0)
	await _frames(30)


	var env_back := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var host_back := env_back.get_node_or_null("WorldItemScatter") if env_back != null else null
	if host_back == null:
		_fail("floor item host missing after the pickup fight")
	elif host_back.get_child_count() != count_before - 1:
		_fail("expected %d floor items left, got %d" % [
			count_before - 1, host_back.get_child_count(),
		])
	if not bool(world._engaged.get("cafeteria", false)):
		_fail("picking up in the cafeteria did not engage that area")
	if int(world.call("area_rank", "kitchen")) != 1:
		_fail("untouched area did not move up a rank after the pickup")


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _seconds(amount: float) -> void:
	await create_timer(amount, true, false, true).timeout


func _wait_for_wipe_open(fx: Node, timeout_sec: float) -> bool:
	if fx == null or not fx.has_method("is_combat_wipe_covered"):
		return true
	var waited := 0.0
	while waited < timeout_sec:
		if not bool(fx.call("is_combat_wipe_covered")):
			return true
		await _seconds(0.1)
		waited += 0.1
	return false


func _wait_for_scene_prefix(prefix: String, max_frames: int) -> bool:
	for _i in max_frames:
		await process_frame
		if current_scene != null and current_scene.scene_file_path.begins_with(prefix):
			return true
	return false


func _wait_for_scene_path(path: String, max_frames: int) -> bool:
	for _i in max_frames:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path:
			return true
	return false
