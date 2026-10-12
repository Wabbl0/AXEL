extends SceneTree

const ROOM := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const SPOTS := [
	Vector2(-90.0, 10.0),
	Vector2(-40.0, 10.0),
	Vector2(-40.0, -30.0),
	Vector2(30.0, 30.0),
	Vector2(-40.0, -80.0),
	Vector2(80.0, -140.0),
]

var _out_dir := "user://"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	root.size = Vector2i(1920, 1280)
	root.get_node("AxelProfile").call("debug_use_memory_only")
	change_scene_to_file(ROOM)
	_run()


func _run() -> void:
	for i in 40:
		await process_frame
	var scene := current_scene
	var player := scene.find_child("Player", true, false) as Node2D
	var poly_node := scene.get_node("WalkableWorld/EnvironmentColliders/TableBlock_Behind/CollisionPolygon2D") as CollisionPolygon2D
	if player == null or poly_node == null:
		print("MISSING")
		quit(1)
		return
	var leg := poly_node.to_global(Vector2(848.0, 1469.0))
	var corner := poly_node.to_global(Vector2(752.0, 1293.0))
	print("LEG_BOTTOM ", leg, " LEFT_CORNER ", corner)
	player.set_physics_process(false)
	player.set_process(false)
	var idx := 0
	for spot in SPOTS:
		var target: Vector2 = leg + spot
		var feet: Vector2 = player.call("_get_collision_feet_anchor")
		player.global_position += target - feet
		player.call("_update_leaf_occlusion_anchor")
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var screen := scene.get_viewport().get_canvas_transform() * target
		var box := Rect2i(Vector2i(screen) - Vector2i(260, 420), Vector2i(520, 520)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		img.get_region(box).save_png(_out_dir.path_join("lounge_%d.png" % idx))
		print("SPOT ", idx, " offset ", spot, " feet ", target)
		idx += 1
	quit(0)
