extends SceneTree
## Prints the corridor locker interact zone bounds and player position in
## world coordinates at portrait size, after camera layout sync.

func _init() -> void:
	OS.set_environment("AXEL_FORCE_TOUCH", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(720, 1560)
	change_scene_to_file("res://scenes/Arc_1/1.2_Corridor.tscn")
	for i in range(90):
		await process_frame
	var scene := current_scene
	var area := scene.get_node("WalkableWorld/EnvironmentColliders/LockerInteractArea") as Area2D
	var poly := area.get_node("CollisionPolygon2D") as CollisionPolygon2D
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for p in poly.polygon:
		var g := poly.to_global(p)
		min_p = min_p.min(g)
		max_p = max_p.max(g)
	var player := scene.get_node("PlayerLayer/Player") as CharacterBody2D
	var bg := scene.get_node("WalkableWorld/Background") as Sprite2D
	var bg_rect := Rect2(bg.global_position, bg.texture.get_size() * bg.global_scale)
	print("zone_min=", min_p, " zone_max=", max_p, " zone_center=", (min_p + max_p) / 2.0)
	print("player_pos=", player.global_position)
	print("bg_rect=", bg_rect)
	var cam := scene.get_node("Camera2D") as Camera2D
	print("cam_pos=", cam.global_position, " zoom=", cam.zoom)
	quit(0)
