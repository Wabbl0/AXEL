extends SceneTree

const PlayerSpawnSyncScript := preload("res://scenes/core/player_spawn_sync.gd")

const EPS := 0.05


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var env := Node2D.new()
	env.position = Vector2.ZERO
	env.scale = Vector2(0.546, 0.546)
	root.add_child(env)

	var player := Node2D.new()
	player.position = Vector2(96.0, 527.0)
	root.add_child(player)

	var tex: Vector2 = PlayerSpawnSyncScript.capture_tex(env, player)
	env.position = Vector2(10.0, 20.0)
	env.scale = Vector2(0.853, 0.853)
	PlayerSpawnSyncScript.apply_tex(env, player, tex)

	var expected := env.to_global(tex)
	if player.global_position.distance_to(expected) > EPS:
		push_error(
			"PlayerSpawnSync FAIL: got %s expected %s"
			% [player.global_position, expected]
		)
		quit(1)
		return


	var forbidden := [
		"res://scenes/Arc_1/1.2_Corridor.gd",
		"res://scenes/Arc_1/1.4_BasementDoor.gd",
		"res://scenes/Arc_1/1.1_SchoolExterior.gd",
		"res://scenes/Arc_2/2.1_Cafeteria.gd",
		"res://scenes/Arc_2/2.3_Kitchen.gd",
		"res://scenes/Arc_2/2.4_ClassroomsCorridor.gd",
		"res://scenes/Arc_3/3.1_Backyard.gd",
		"res://scenes/Arc_4/4.1_TeachersLounge.gd",
		"res://scenes/Arc_5/5.1_Classroom.gd",
	]
	for path in forbidden:
		var src := FileAccess.get_file_as_string(path)
		if src.contains("env.to_global(Vector2("):
			push_error(
				"PlayerSpawnSync FAIL: %s hardcodes env.to_global(Vector2(...)) spawn"
				% path
			)
			quit(1)
			return

	print("PlayerSpawnSync check OK.")
	quit(0)
