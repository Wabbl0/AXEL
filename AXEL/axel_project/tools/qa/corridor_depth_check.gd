extends SceneTree

const ROOM := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const EXPECT := {
	"CafeteriaInteractArea": 1.0,
	"LoungeInteractArea": 1.5,
	"ClassroomInteractArea": 1.5,
}

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	if change_scene_to_file(ROOM) != OK:
		_failures.append("could not load 2.4")
		_finish()
		return
	for i in 45:
		await physics_frame
	var room := current_scene
	var env := room.get_node("WalkableWorld/EnvironmentColliders")
	for area_name in EXPECT.keys():
		var area := env.get_node_or_null(String(area_name)) as Area2D
		if area == null:
			_failures.append("%s missing" % area_name)
			continue
		var shape := area.get_node("CollisionShape2D") as CollisionShape2D
		var depth := float(room.call("depth_for_position", shape.global_position))
		if absf(depth - float(EXPECT[area_name])) > 0.05:
			_failures.append("%s depth %.2f, want %.2f" % [area_name, depth, float(EXPECT[area_name])])
	var player := room.find_child("Player", true, false) as Node2D
	var classroom := env.get_node("ClassroomInteractArea/CollisionShape2D") as Node2D
	room.set("_depth_factor", 1.0)
	var small_scale := player.scale.x
	player.global_position = classroom.global_position + Vector2(0.0, 40.0)
	for i in 6:
		await physics_frame
	var depth_now := float(room.get("_depth_factor"))
	if absf(depth_now - 1.5) > 0.01:
		_failures.append("after a jump to the classroom door depth is %.2f, want 1.50" % depth_now)
	if player.scale.x <= small_scale * 1.2:
		_failures.append("Mike stayed small at the classroom door (scale %.3f)" % player.scale.x)
	await _check_classroom_exit()
	_finish()


func _check_classroom_exit() -> void:
	root.get_node("GameManager").call("set_classrooms_corridor_spawn_side", "classroom_door")
	if change_scene_to_file(ROOM) != OK:
		_failures.append("could not reload 2.4")
		return
	for i in 60:
		await physics_frame
	var room := current_scene
	var player := room.find_child("Player", true, false) as CharacterBody2D
	var wall := room.get_node("WalkableWorld/EnvironmentColliders/BottomWall/CollisionShape2D") as CollisionShape2D
	var wall_size := (wall.shape as RectangleShape2D).size * wall.global_scale
	var wall_bottom := wall.global_position.y + wall_size.y * 0.5
	var feet: Vector2 = player.call("_get_collision_feet_anchor")
	if feet.y <= wall_bottom:
		_failures.append("leaving a classroom puts Mike's feet at y %.1f, above the corridor wall bottom %.1f" % [feet.y, wall_bottom])
	var area := room.get_node("WalkableWorld/EnvironmentColliders/ClassroomInteractArea/CollisionShape2D") as CollisionShape2D
	var area_size := (area.shape as RectangleShape2D).size * area.global_scale
	var area_rect := Rect2(area.global_position - area_size * 0.5, area_size)
	if not area_rect.grow(4.0).has_point(feet):
		_failures.append("classroom arrival should stay inside the live door box, feet %s box %s" % [feet, area_rect])
	if absf(float(room.get("_depth_factor")) - 1.5) > 0.01:
		_failures.append("classroom arrival depth %.2f, want 1.50" % float(room.get("_depth_factor")))


func _finish() -> void:
	if _failures.is_empty():
		print("Corridor depth check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("corridor_depth_check: %s" % msg)
	quit(1)
