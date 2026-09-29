extends SceneTree

const SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const KITCHEN := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const BACKYARD := "res://scenes/Arc_3/3.1_Backyard.tscn"
const CLASSROOMS := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		push_error("cafeteria_down_hint_check: GameManager missing")
		quit(1)
		return
	if not await _check_thirty_second_path(gm):
		_finish()
		return
	if not await _check_one_room_waits(gm):
		_finish()
		return
	if not await _check_both_rooms_show(gm):
		_finish()
		return
	if not await _check_move_down_keeps_hint(gm):
		_finish()
		return
	if not await _check_overlap_hides(gm):
		_finish()
		return
	await _check_classrooms_hides(gm)
	_finish()


func _check_thirty_second_path(gm: Node) -> bool:
	_reset(gm)
	var scene := await _open_cafeteria()
	if scene == null:
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing in 2.1")
		return false
	if hint.visible:
		_fail("arrow should start hidden")
	var elapsed_before: float = float(scene.get("_hint_elapsed"))
	scene.set("_enter_dialogue_pending", true)
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 5.0)
	if float(scene.get("_hint_elapsed")) > elapsed_before + 0.01:
		_fail("arrow clock ticked during the enter line")
	scene.set("_enter_dialogue_pending", false)
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 10.0)
	var elapsed_mid: float = float(scene.get("_hint_elapsed"))
	paused = true
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 5.0)
	paused = false
	if float(scene.get("_hint_elapsed")) > elapsed_mid + 0.01:
		_fail("arrow clock ticked while paused")
	var remain: float = 30.0 - float(scene.get("_hint_elapsed"))
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", maxf(remain - 0.05, 0.0))
	await process_frame
	if hint.visible:
		_fail("arrow should stay hidden before 30s")
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.1)
	await process_frame
	if not hint.visible:
		_fail("arrow should show after 30s in 2.1")
	else:
		_assert_down_arrow(scene, hint, "30s path")
	_free_scene(scene)
	await process_frame
	return true


func _check_one_room_waits(gm: Node) -> bool:
	_reset(gm)
	gm.visited_rooms[KITCHEN] = true
	var scene := await _open_cafeteria()
	if scene == null:
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing for one-room check")
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if hint.visible:
		_fail("kitchen alone must not show the arrow")
	_free_scene(scene)
	await process_frame
	return true


func _check_both_rooms_show(gm: Node) -> bool:
	_reset(gm)
	gm.visited_rooms[KITCHEN] = true
	gm.visited_rooms[BACKYARD] = true
	var scene := await _open_cafeteria()
	if scene == null:
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing for both-rooms check")
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if not hint.visible:
		_fail("arrow should show once kitchen and backyard are both visited")
	else:
		_assert_down_arrow(scene, hint, "both rooms")
	_free_scene(scene)
	await process_frame
	return true


func _check_move_down_keeps_hint(gm: Node) -> bool:
	_reset(gm)
	gm.visited_rooms[KITCHEN] = true
	gm.visited_rooms[BACKYARD] = true
	var scene := await _open_cafeteria()
	if scene == null:
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing for move_down check")
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if not hint.visible:
		_fail("arrow should be visible before move_down")
		_free_scene(scene)
		return false
	Input.action_press("move_down")
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	Input.action_release("move_down")
	if not hint.visible:
		_fail("holding move_down must not hide the arrow")
	if bool(gm.cafeteria_down_hint_done):
		_fail("move_down must not mark the arrow done")
	_free_scene(scene)
	await process_frame
	return true


func _check_overlap_hides(gm: Node) -> bool:
	_reset(gm)
	gm.visited_rooms[KITCHEN] = true
	gm.visited_rooms[BACKYARD] = true
	var scene := await _open_cafeteria()
	if scene == null:
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing for overlap check")
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if not hint.visible:
		_fail("arrow should be visible before overlap")
		_free_scene(scene)
		return false
	var player := scene.get_node_or_null("PlayerLayer/Player") as Node2D
	var mike := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D if player != null else null
	var arrow := hint.get_node_or_null("Sprite") as Sprite2D
	if mike == null or arrow == null:
		_fail("overlap check missing Mike or arrow sprite")
		_free_scene(scene)
		return false
	mike.offset = Vector2.ZERO
	var shift := arrow.global_position - mike.global_position
	player.global_position += shift
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if hint.visible:
		_fail("arrow must hide when Mike's sprite overlaps it")
	if not bool(gm.cafeteria_down_hint_done):
		_fail("overlapping the arrow must mark it done")
	_free_scene(scene)
	await process_frame
	return true


func _check_classrooms_hides(gm: Node) -> void:
	_reset(gm)
	gm.visited_rooms[KITCHEN] = true
	gm.visited_rooms[BACKYARD] = true
	change_scene_to_file(CLASSROOMS)
	await _settle(16)
	if not bool(gm.cafeteria_down_hint_done):
		_fail("entering 2.4 must mark the cafeteria arrow done")
	var scene := await _open_cafeteria()
	if scene == null:
		return
	var hint := _hint_of(scene)
	if hint != null:
		if scene.has_method("_update_direction_hint"):
			scene.call("_update_direction_hint", 40.0)
		await process_frame
		if hint.visible:
			_fail("arrow must stay hidden after the classrooms corridor")
	_free_scene(scene)
	await process_frame


func _open_cafeteria() -> Node:
	var gm := root.get_node_or_null("GameManager")
	if gm != null:
		gm.cafeteria_enter_line_seen = true
	change_scene_to_file(SCENE)
	await _settle(20)
	var scene := current_scene
	if scene == null:
		_fail("cafeteria scene did not load")
	return scene


func _reset(gm: Node) -> void:
	gm.cafeteria_down_hint_done = false
	gm.cafeteria_enter_line_seen = true
	for path in [KITCHEN, BACKYARD, CLASSROOMS]:
		if gm.visited_rooms.has(path):
			gm.visited_rooms.erase(path)


func _hint_of(scene: Node) -> Node2D:
	if scene == null:
		return null
	return scene.get_node_or_null("PlayerLayer/DirectionHint") as Node2D


func _assert_down_arrow(scene: Node, hint: Node2D, where: String) -> void:
	if absf(hint.scale.x - 1.67) > 0.08 or absf(hint.scale.y - 1.67) > 0.08:
		_fail("%s: arrow scale %.2f should be ~1.67" % [where, hint.scale.x])
	if absf(hint.rotation - PI * 0.5) > 0.05:
		_fail("%s: arrow rotation %.2f should point down" % [where, hint.rotation])
	var sprite := hint.get_node_or_null("Sprite") as Sprite2D
	if sprite != null:
		var origin: Vector2 = sprite.global_position
		var tip: Vector2 = sprite.to_global(Vector2(20.0, 0.0))
		if tip.y <= origin.y + 4.0:
			_fail("%s: arrow tip should sit below its center" % where)
		if absf(tip.x - origin.x) > 6.0:
			_fail("%s: arrow should point straight down" % where)
	if not scene.has_method("_classrooms_top_center"):
		_fail("%s: cafeteria missing top-center helper" % where)
		return
	var top: Vector2 = scene.call("_classrooms_top_center")
	if absf(hint.global_position.x - top.x) > 4.0:
		_fail("%s: arrow x %.1f is not centered on the classrooms box %.1f" % [where, hint.global_position.x, top.x])
	var lift := 16.0 * 1.67 + 8.0
	var want_y := top.y - lift
	if absf(hint.global_position.y - want_y) > 6.0:
		_fail("%s: arrow y %.1f should sit just above the classrooms box (%.1f)" % [where, hint.global_position.y, want_y])


func _free_scene(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _finish() -> void:
	if _failures.is_empty():
		print("Cafeteria down hint check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("cafeteria_down_hint_check: %s" % msg)
	quit(1)
