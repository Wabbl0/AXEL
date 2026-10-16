extends SceneTree

const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const BASEMENT := "res://scenes/Arc_6/6.1_BasementDoor.tscn"
const SETTLE_FRAMES := 12

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		push_error("basement_route_check: GameManager missing")
		quit(1)
		return
	var src := FileAccess.get_file_as_string("res://scenes/Arc_1/1.4_BasementDoor.gd")
	if src.find("Not yet.") < 0:
		_failures.append("1.4 door should say Not yet. before the Flashlight or Key")
	if src.find("is_owned(\"hasFlashlight\")") < 0 or src.find("is_owned(\"hasKey\")") < 0:
		_failures.append("1.4 Not yet. gate should check the Flashlight and the Key")
	if src.find(BASEMENT) < 0:
		_failures.append("1.4 door does not lead to 6.1")
	await _check_door_return(gm)
	if _failures.is_empty():
		print("Basement route check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("basement_route_check: %s" % msg)
	quit(1)


func _check_door_return(gm: Node) -> void:
	gm.call("set_basement_spawn_side", "basement_door")
	var packed: PackedScene = load(ROOM)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	for _i in SETTLE_FRAMES:
		await physics_frame
		await process_frame
	var player := scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	var door := scene.get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	var env := scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if player == null or door == null or env == null:
		_failures.append("1.4 is missing Player, DoorInteractArea or colliders")
	else:
		var spawn_tex := env.to_local(player.global_position)
		print("1.4 door return tex=%s" % spawn_tex)
		if not door.overlaps_body(player):
			_failures.append("player returning from 6.1 is not on the door area (tex %s)" % spawn_tex)
	if String(gm.get("basement_spawn_side")) != "":
		_failures.append("basement_door spawn side was not consumed")
	scene.queue_free()
	await process_frame
