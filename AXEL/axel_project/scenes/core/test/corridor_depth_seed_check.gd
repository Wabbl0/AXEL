extends SceneTree

const SETTLE_FRAMES := 16
const EPS := 0.02


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	push_error("CorridorDepthSeed FAIL: %s" % msg)
	quit(1)


func _gm() -> Node:
	return root.get_node("GameManager")


func _await_frames(n: int) -> void:
	for _i in n:
		await process_frame


func _spawn_corridor(spawn_side: String, arrival_t: float = 0.5) -> Node:
	_gm().classrooms_corridor_spawn_side = spawn_side
	_gm().interact_arrival_t = arrival_t
	var ps: PackedScene = load("res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn")
	if ps == null:
		_fail("could not load 2.4_ClassroomsCorridor.tscn")
		return null
	var scene := ps.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	await _await_frames(SETTLE_FRAMES)
	return scene


func _assert_seeded_depth(spawn_side: String, expected: float) -> bool:
	var scene := await _spawn_corridor(spawn_side)
	if scene == null:
		return false
	var got := float(scene.get("_depth_factor"))
	var pending := bool(scene.get("_spawn_placement_pending"))
	scene.queue_free()
	await process_frame
	if pending:
		_fail("%s spawn never finished placement" % spawn_side)
		return false
	if absf(got - expected) > EPS:
		_fail("%s depth_factor=%.4f expected %.4f" % [spawn_side, got, expected])
		return false
	return true


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame

	_gm().classrooms_corridor_spawn_side = ""
	_gm().interact_arrival_t = NAN
	if not await _assert_seeded_depth("", 1.0):
		return

	if not await _assert_seeded_depth("lounge_door", 1.5):
		return

	if not await _assert_seeded_depth("classroom_door", 1.5):
		return

	print("CorridorDepthSeed check OK (fresh=1.0, lounge=1.5, classroom=1.5).")
	quit(0)
