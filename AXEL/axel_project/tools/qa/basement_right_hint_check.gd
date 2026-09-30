extends SceneTree

const SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const CAFETERIA := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
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
		push_error("basement_right_hint_check: GameManager missing")
		quit(1)
		return
	gm.basement_right_hint_done = false
	gm.basement_hint_soon = false
	if gm.visited_rooms.has(CAFETERIA):
		gm.visited_rooms.erase(CAFETERIA)

	if not await _check_starts_hidden(gm):
		_finish()
		return
	if not await _check_hint_soon(gm):
		_finish()
		return
	await _check_visited_hides(gm)
	_finish()


func _check_starts_hidden(gm: Node) -> bool:
	gm.basement_right_hint_done = false
	gm.basement_hint_soon = false
	var scene := await _instance_scene()
	if scene == null:
		_fail("could not instance 1.4")
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing in 1.4")
		scene.queue_free()
		await process_frame
		return false
	for _i in 4:
		if scene.has_method("_update_direction_hint"):
			scene.call("_update_direction_hint", 0.0)
		await process_frame
	if hint.visible:
		_fail("arrow should start hidden")
	scene.queue_free()
	await process_frame
	return true


func _check_hint_soon(gm: Node) -> bool:
	gm.basement_right_hint_done = false
	if gm.visited_rooms.has(CAFETERIA):
		gm.visited_rooms.erase(CAFETERIA)
	gm.set_basement_hint_soon(true)
	var scene := await _instance_scene()
	if scene == null:
		_fail("could not instance 1.4 for hint_soon")
		return false
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing for hint_soon")
		scene.queue_free()
		await process_frame
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.1)
	await process_frame
	if hint.visible:
		_fail("arrow must stay hidden at 0.1s with basement_hint_soon")
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.55)
	await process_frame
	if not hint.visible:
		_fail("arrow should show within ~1s when basement_hint_soon was set")
	scene.queue_free()
	await process_frame
	return true


func _check_visited_hides(gm: Node) -> void:
	gm.basement_right_hint_done = false
	gm.set_basement_hint_soon(true)
	gm.mark_room_visited(CAFETERIA)
	var scene := await _instance_scene()
	if scene == null:
		_fail("could not instance 1.4 for visited check")
		return
	var hint := _hint_of(scene)
	if hint != null:
		if scene.has_method("_update_direction_hint"):
			scene.call("_update_direction_hint", 1.0)
		await process_frame
		if hint.visible:
			_fail("arrow must stay hidden after 2.1 has been visited")
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame


func _instance_scene() -> Node:
	var ps: PackedScene = load(SCENE)
	if ps == null:
		return null
	var scene: Node = ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	for _i in 12:
		await process_frame
	return scene


func _hint_of(scene: Node) -> Node2D:
	if scene == null:
		return null
	return scene.get_node_or_null("PlayerLayer/DirectionHint") as Node2D


func _finish() -> void:
	if _failures.is_empty():
		print("Basement right hint check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("basement_right_hint_check: %s" % msg)
	quit(1)
