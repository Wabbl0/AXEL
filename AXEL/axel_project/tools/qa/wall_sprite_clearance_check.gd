extends SceneTree

const PoseNudge := preload("res://scenes/player/pose_nudge.tres")
const HitboxFront := preload("res://scenes/player/hitbox_front.tres")

const CELL := Vector2(439.0, 971.0)
const HITBOX_POS := Vector2(-37.812428, 126.04143)
const SHADOW_POS := Vector2(-5.0416956, -5.041732)
const SHADOW_SCALE := Vector2(1.0335996, 0.9969109)

const SCENES: Array[Dictionary] = [
	{
		"path": "res://scenes/Arc_1/1.1_SchoolExterior.tscn",
		"env": "EnvironmentColliders",
		"bg": "Background_1_1",
		"player": "PlayerLayer/Player",
		"skip": ["LeftWall"],
	},
	{
		"path": "res://scenes/Arc_1/1.2_Corridor.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": ["RightWall"],
	},
	{
		"path": "res://scenes/Arc_1/1.4_BasementDoor.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": ["LeftWall"],
	},
	{
		"path": "res://scenes/Arc_2/2.1_Cafeteria.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": [],
	},
	{
		"path": "res://scenes/Arc_2/2.3_Kitchen.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": [],
	},
	{
		"path": "res://scenes/Arc_3/3.1_Backyard.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": [],
	},
	{
		"path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": [],
	},
	{
		"path": "res://scenes/Arc_5/5.1_Classroom.tscn",
		"env": "WalkableWorld/EnvironmentColliders",
		"bg": "WalkableWorld/Background",
		"player": "PlayerLayer/Player",
		"skip": [],
	},
]

const WALL_NAMES: Array[String] = ["LeftWall", "RightWall", "TopWall", "BottomWall"]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame

	var local_overhang := _local_overhangs()
	print(
		"LOCAL_OVERHANG left=%.1f right=%.1f top=%.1f bottom=%.1f"
		% [
			local_overhang["left"],
			local_overhang["right"],
			local_overhang["top"],
			local_overhang["bottom"],
		]
	)

	var fail_count := 0
	for entry in SCENES:
		fail_count += await _check_scene(entry, local_overhang)

	if fail_count > 0:
		push_error("WALL_SPRITE_CLEARANCE FAIL count=%d" % fail_count)
		quit(1)
		return
	print("WALL_SPRITE_CLEARANCE OK")
	quit(0)


func _local_overhangs() -> Dictionary:
	var radius: float = (HitboxFront as CircleShape2D).radius
	var front: Vector2 = PoseNudge.front
	var back: Vector2 = PoseNudge.back
	var side: Vector2 = PoseNudge.side


	var left_nudge := Vector2(-side.x, side.y)
	var circle_left_edge := -HITBOX_POS.x - radius
	var left_over := minf(_sprite_left(left_nudge), _shadow_left(left_nudge))
	var left_px := circle_left_edge - left_over


	var circle_right_edge := HITBOX_POS.x + radius
	var right_over := maxf(_sprite_right(side), _shadow_right(side))
	var right_px := right_over - circle_right_edge


	var circle_top_edge := HITBOX_POS.y - radius
	var top_over := minf(_sprite_top(back), _shadow_top(back))
	var top_px := circle_top_edge - top_over


	var circle_bot_edge := HITBOX_POS.y + radius
	var bot_over := maxf(_sprite_bottom(front), _shadow_bottom(front))
	var bottom_px := bot_over - circle_bot_edge

	return {
		"left": left_px,
		"right": right_px,
		"top": top_px,
		"bottom": bottom_px,
	}


func _sprite_left(nudge: Vector2) -> float:
	return nudge.x - CELL.x * 0.5


func _sprite_right(nudge: Vector2) -> float:
	return nudge.x + CELL.x * 0.5


func _sprite_top(nudge: Vector2) -> float:
	return nudge.y - CELL.y * 0.5


func _sprite_bottom(nudge: Vector2) -> float:
	return nudge.y + CELL.y * 0.5


func _shadow_left(nudge: Vector2) -> float:
	return SHADOW_POS.x + nudge.x - CELL.x * 0.5 * SHADOW_SCALE.x


func _shadow_right(nudge: Vector2) -> float:
	return SHADOW_POS.x + nudge.x + CELL.x * 0.5 * SHADOW_SCALE.x


func _shadow_top(nudge: Vector2) -> float:
	return SHADOW_POS.y + nudge.y - CELL.y * 0.5 * SHADOW_SCALE.y


func _shadow_bottom(nudge: Vector2) -> float:
	return SHADOW_POS.y + nudge.y + CELL.y * 0.5 * SHADOW_SCALE.y


func _check_scene(entry: Dictionary, local_overhang: Dictionary) -> int:
	var path: String = entry["path"]
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("WALL_CLEARANCE missing scene %s" % path)
		return 1
	var scene := ps.instantiate() as Node
	root.add_child(scene)
	await process_frame
	if not scene.is_node_ready():
		await scene.ready
	for _i in 50:
		await physics_frame

	var env := scene.get_node_or_null(entry["env"]) as Node2D
	var bg := scene.get_node_or_null(entry["bg"]) as Sprite2D
	var player := scene.get_node_or_null(entry["player"]) as CharacterBody2D
	if env == null or bg == null or player == null or bg.texture == null:
		push_error("WALL_CLEARANCE missing nodes in %s" % path)
		scene.queue_free()
		await process_frame
		return 1


	var live_scale: float = player.scale.x
	var required_world := {
		"left": local_overhang["left"] * live_scale,
		"right": local_overhang["right"] * live_scale,
		"top": local_overhang["top"] * live_scale,
		"bottom": local_overhang["bottom"] * live_scale,
	}

	var tex_size := bg.texture.get_size()
	var bg_origin := bg.global_position

	var bg_scale := bg.scale.x
	var png_left := bg_origin.x
	var png_right := bg_origin.x + tex_size.x * bg_scale
	var png_top := bg_origin.y
	var png_bottom := bg_origin.y + tex_size.y * bg_scale


	var authored_scale := live_scale
	if player.has_meta("axel_authored_scale"):
		var meta_scale: Variant = player.get_meta("axel_authored_scale")
		if meta_scale is Vector2:
			authored_scale = (meta_scale as Vector2).x


	var required_tex := {
		"left": ceili(required_world["left"] / bg_scale),
		"right": ceili(required_world["right"] / bg_scale),
		"top": ceili(required_world["top"] / bg_scale),
		"bottom": ceili(required_world["bottom"] / bg_scale),
	}

	print(
		"SCENE %s live_scale=%.4f authored=%.3f bg_scale=%.4f required_tex L=%d R=%d T=%d B=%d"
		% [
			path.get_file(),
			live_scale,
			authored_scale,
			bg_scale,
			required_tex["left"],
			required_tex["right"],
			required_tex["top"],
			required_tex["bottom"],
		]
	)

	var skip: Array = entry["skip"]
	var fails := 0
	for wall_name in WALL_NAMES:
		var wall := env.get_node_or_null(wall_name) as StaticBody2D
		if wall == null:
			print("  %s MISSING" % wall_name)
			continue
		var skipped := skip.has(wall_name)
		var aabb := _wall_aabb_global(wall)
		if aabb.size.x <= 0.0 or aabb.size.y <= 0.0:
			var empty_status := "SKIP" if skipped else "FAIL"
			if not skipped:
				fails += 1
			print("  %s EMPTY_AABB status=%s" % [wall_name, empty_status])
			continue

		var side_key := ""
		var inset_world := 0.0
		match wall_name:
			"LeftWall":
				side_key = "left"
				inset_world = (aabb.position.x + aabb.size.x) - png_left
			"RightWall":
				side_key = "right"
				inset_world = png_right - aabb.position.x
			"TopWall":
				side_key = "top"
				inset_world = (aabb.position.y + aabb.size.y) - png_top
			"BottomWall":
				side_key = "bottom"
				inset_world = png_bottom - aabb.position.y

		var need_world: float = float(required_world[side_key])
		var inset_tex := inset_world / bg_scale
		var need_tex: int = int(required_tex[side_key])
		var ok := inset_world + 0.5 >= need_world
		var status := "PASS"
		if skipped:
			status = "SKIP"
		elif not ok:
			status = "FAIL"
			fails += 1
		print(
			"  %s inset_tex=%.1f required_tex=%d inset_world=%.1f required_world=%.1f status=%s"
			% [wall_name, inset_tex, need_tex, inset_world, need_world, status]
		)

	scene.queue_free()
	await process_frame
	await process_frame
	return fails


func _wall_aabb_global(wall: StaticBody2D) -> Rect2:
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	var found := false
	for child in wall.get_children():
		if child is CollisionShape2D:
			var cs := child as CollisionShape2D
			if cs.disabled or cs.shape == null:
				continue
			var shape_aabb := _shape_aabb_local(cs)
			var corners := [
				shape_aabb.position,
				shape_aabb.position + Vector2(shape_aabb.size.x, 0.0),
				shape_aabb.position + Vector2(0.0, shape_aabb.size.y),
				shape_aabb.position + shape_aabb.size,
			]
			for corner in corners:
				var gp: Vector2 = cs.to_global(corner)
				min_p = min_p.min(gp)
				max_p = max_p.max(gp)
				found = true
		elif child is CollisionPolygon2D:
			var poly := child as CollisionPolygon2D
			for pt in poly.polygon:
				var gp2: Vector2 = poly.to_global(pt)
				min_p = min_p.min(gp2)
				max_p = max_p.max(gp2)
				found = true
	if not found:
		return Rect2()
	return Rect2(min_p, max_p - min_p)


func _shape_aabb_local(cs: CollisionShape2D) -> Rect2:
	var shape := cs.shape
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		return Rect2(-rect.size * 0.5, rect.size)
	if shape is CircleShape2D:
		var circ := shape as CircleShape2D
		var r := circ.radius
		return Rect2(Vector2(-r, -r), Vector2(r * 2.0, r * 2.0))
	return Rect2(Vector2(-1.0, -1.0), Vector2(2.0, 2.0))
