extends SceneTree

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"

var _failed := false


func _init() -> void:
	root.size = Vector2i(1920, 1280)
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	for t in [0.0, 0.5, 1.0]:
		await _check_arrival(t)
	if _failed:
		quit(1)
		return
	print("lounge_arrival_check: OK")
	quit(0)


func _check_arrival(t: float) -> void:
	var gm := root.get_node("GameManager")
	gm.call("set_classrooms_corridor_spawn_side", "lounge_door")
	gm.call("set_interact_arrival_t", t)
	change_scene_to_file(CORRIDOR_SCENE)
	for _i in 60:
		await process_frame
	var scene := current_scene
	if scene == null:
		_fail("corridor did not load (t=%.1f)" % t)
		return
	var player := scene.find_child("Player", true, false) as CharacterBody2D
	if player == null:
		_fail("player missing (t=%.1f)" % t)
		return
	var wall := scene.find_child("RightWall", true, false)
	var wall_poly := wall.find_child("*", true, false) as CollisionPolygon2D if wall != null else null
	var floor_fill := scene.find_child("BottomLeftFill", true, false)
	var floor_shape := floor_fill.find_child("*", true, false) as CollisionShape2D if floor_fill != null else null
	if wall_poly == null or floor_shape == null:
		_fail("corridor colliders missing")
		return
	var env := wall.get_parent() as Node2D
	var hitbox := player.find_child("*", false, false) as CollisionShape2D
	for child in player.get_children():
		if child is CollisionShape2D:
			hitbox = child
			break
	if env == null or hitbox == null:
		_fail("env or hitbox missing")
		return
	var top := env.to_local(wall_poly.global_transform * wall_poly.polygon[0])
	var bottom := env.to_local(wall_poly.global_transform * wall_poly.polygon[3])
	var floor_rect := floor_shape.shape.get_rect()
	var floor_top := env.to_local(floor_shape.global_transform * floor_rect.position).y
	var pos := env.to_local(hitbox.global_position)
	var wall_x := lerpf(top.x, bottom.x, clampf((pos.y - top.y) / maxf(bottom.y - top.y, 1.0), 0.0, 1.0))
	print("lounge arrival t=%.1f at %s (wall x %.0f, floor %.0f)" % [t, str(pos), wall_x, floor_top])
	if pos.x >= wall_x:
		_fail("t=%.1f player x %.0f is inside the right wall (%.0f)" % [t, pos.x, wall_x])
	if pos.y <= top.y or pos.y >= floor_top:
		_fail("t=%.1f player y %.0f is off the floor" % [t, pos.y])
	if player.test_move(player.global_transform, Vector2.ZERO):
		_fail("t=%.1f player overlaps a collider" % t)


func _fail(msg: String) -> void:
	_failed = true
	push_error("lounge_arrival_check FAIL: " + msg)
