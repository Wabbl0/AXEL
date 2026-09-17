extends SceneTree

const SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const BASEMENT := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
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
		push_error("corridor_right_hint_check: GameManager missing")
		quit(1)
		return
	gm.corridor_spawn_line_seen = true
	gm.corridor_right_hint_done = false
	gm.corridor_from_locker = false
	if gm.visited_rooms.has(BASEMENT):
		gm.visited_rooms.erase(BASEMENT)

	if not await _check_ten_second_path(gm):
		_finish()
		return
	if not await _check_locker_path(gm):
		_finish()
		return
	await _check_visited_hides(gm)
	_finish()


func _check_ten_second_path(gm: Node) -> bool:
	gm.corridor_from_locker = false
	gm.corridor_right_hint_done = false
	change_scene_to_file(SCENE)
	await _settle(20)
	var scene := current_scene
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing in 1.2")
		return false
	if hint.visible:
		_fail("arrow should start hidden")
	scene.set("corridor_spawn_line_seen_skip", true)
	scene.set("_enter_dialogue_pending", false)
	if scene.has_method("_update_direction_hint"):
		for _i in 12:
			scene.call("_update_direction_hint", 1.0)
			await process_frame
	if not hint.visible:
		_fail("arrow should show after 10s in 1.2")
	var elapsed_before: float = float(scene.get("_hint_elapsed"))
	paused = true
	await process_frame
	await process_frame
	paused = false
	var elapsed_after: float = float(scene.get("_hint_elapsed"))
	if elapsed_after > elapsed_before + 0.05:
		_fail("10s arrow clock ticked while paused")
	scene.queue_free()
	await process_frame
	return true


func _check_locker_path(gm: Node) -> bool:
	gm.corridor_from_locker = true
	gm.corridor_right_hint_done = false
	var run := root.get_node_or_null("AxelRun")
	if run != null:
		run.state.tutorial_fight_done = true
		run.state.tutorial_fight_pending = false
	change_scene_to_file(SCENE)
	await _settle(16)
	var scene := current_scene
	scene.set("_enter_dialogue_pending", false)
	var hint := _hint_of(scene)
	if hint == null:
		_fail("DirectionHint missing after locker return")
		return false
	if scene.has_method("_update_direction_hint"):
		scene.call("_update_direction_hint", 0.0)
	await process_frame
	if not hint.visible:
		_fail("arrow should show immediately after locker when tutorial is done")
	scene.queue_free()
	await process_frame
	return true


func _check_visited_hides(gm: Node) -> void:
	gm.corridor_from_locker = true
	gm.corridor_right_hint_done = true
	change_scene_to_file(SCENE)
	await _settle(12)
	var scene := current_scene
	var hint := _hint_of(scene)
	if hint != null:
		if scene.has_method("_update_direction_hint"):
			scene.call("_update_direction_hint", 20.0)
		await process_frame
		if hint.visible:
			_fail("arrow must stay hidden after 1.4 is done")
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame


func _hint_of(scene: Node) -> Node2D:
	if scene == null:
		return null
	return scene.get_node_or_null("PlayerLayer/DirectionHint") as Node2D


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _finish() -> void:
	if _failures.is_empty():
		print("Corridor right hint check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("corridor_right_hint_check: %s" % msg)
	quit(1)
