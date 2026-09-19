extends SceneTree

const PlayerSpawnSyncScript := preload("res://scenes/core/player_spawn_sync.gd")

const ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MAP := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const TRAVEL := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const EPS := 2.0

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		push_error("pause_map_restore_check: GameManager missing")
		quit(1)
		return

	if change_scene_to_file(ROOM) != OK:
		_fail("could not load 1.2")
	else:
		for _i in 20:
			await process_frame
		var scene := current_scene
		_interrupt_dialogue(scene)
		for _i in 4:
			await process_frame
		var env := _env_of(scene)
		var player := scene.find_child("Player", true, false) as Node2D
		if env == null or player == null:
			_fail("1.2 missing env or player")
		else:
			var want: Vector2 = PlayerSpawnSyncScript.capture_tex(env, player) + Vector2(72.0, 0.0)
			gm.call("set_pause_map_return", ROOM, want)
			if change_scene_to_file(ROOM) != OK:
				_fail("could not reload 1.2 for pause-map restore")
			else:
				for _i in 28:
					await process_frame
				scene = current_scene
				_interrupt_dialogue(scene)
				env = _env_of(scene)
				player = scene.find_child("Player", true, false) as Node2D
				if env == null or player == null:
					_fail("reloaded 1.2 missing env or player")
				else:
					var got: Vector2 = PlayerSpawnSyncScript.capture_tex(env, player)
					if got.distance_to(want) > EPS:
						_fail("pause-map X did not restore tex %s (got %s)" % [want, got])
				if bool(gm.call("has_pause_map_return_for", ROOM)):
					_fail("pause-map tex was left pending after restore")

	gm.call("set_pause_map_return", ROOM, Vector2(40.0, 40.0))
	if change_scene_to_file(MAP) != OK:
		_fail("could not load school map")
	else:
		for _i in 12:
			await process_frame
		var map := current_scene
		if map != null and map.has_method("_go_to_scene"):
			map.call("_go_to_scene", TRAVEL)
			for _i in 16:
				await process_frame
			if not String(gm.pause_map_return_path).is_empty():
				_fail("travel click left pause_map_return_path set")
			if bool(gm.call("has_pause_map_return_for", ROOM)):
				_fail("travel click left pause-map tex pending")
		else:
			_fail("school map missing _go_to_scene")

	if _failures.is_empty():
		print("Pause map restore check OK.")
		quit(0)
	else:
		for msg in _failures:
			push_error("pause_map_restore_check: %s" % msg)
		quit(1)


func _env_of(scene: Node) -> Node2D:
	if scene == null:
		return null
	if scene.has_method("env_colliders"):
		return scene.call("env_colliders") as Node2D
	return scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D


func _interrupt_dialogue(scene: Node) -> void:
	if scene == null:
		return
	var overlay := scene.get_node_or_null("TopDialogueOverlay")
	if overlay != null and overlay.has_method("interrupt_line"):
		overlay.call("interrupt_line")
