extends SceneTree
## Capture each PNG-backed exploration scene with Mike walking at view center
## and dialogue / interact chrome hidden.
##
## Run from repo root (needs a display — do NOT pass --headless):
##   DISPLAY=:1 godot --path AXEL/axel_project -s res://tools/capture_drawn_scenes.gd
##
## Optional env:
##   AXEL_CAPTURE_OUTPUT=/abs/or/user://dir
##
## Exit 0 when requested PNGs are written (missing drawings are skipped, not failed).
## Exit 1 if a scene with a drawing fails to capture.

const WINDOW := Vector2i(1920, 1280)
const LAYOUT_FRAMES := 16
const WALK_FRAMES := 24
const SETTLE_FRAMES := 2
const CAMERA_MODE_FOLLOW := 1
const WALK_ANIM := &"walk_right"
const WALK_FREEZE_FRAME := 2
const INJECTED_PLAYER_SCALE := Vector2(0.198, 0.198)

const _WALKABLE_SCENES: PackedStringArray = [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_1/1.4_BasementDoor.tscn",
	"res://scenes/Arc_2/2.1_Cafeteria.tscn",
	"res://scenes/Arc_2/2.3_Kitchen.tscn",
	"res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn",
	"res://scenes/Arc_3/3.1_Backyard.tscn",
	"res://scenes/Arc_4/4.1_TeachersLounge.tscn",
	"res://scenes/Arc_5/5.1_Classroom.tscn",
]

const _STATIC_SCENES: PackedStringArray = [
	"res://scenes/Arc_1/1.3_LockerHub.tscn",
	"res://scenes/Arc_2/2.2_CafeteriaMemory.tscn",
	"res://scenes/Arc_3/3.2_BackyardMemory.tscn",
	"res://scenes/Arc_4/4.2_TeachersMemory.tscn",
	"res://scenes/Arc_5/5.2_ClassroomDesk.tscn",
]

var _output_dir := ""


func _init() -> void:
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	OS.set_environment("AXEL_SKIP_DIALOGUE", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	_output_dir = _resolve_output_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	DisplayServer.window_set_size(WINDOW)
	root.size = WINDOW
	call_deferred("_main")


func _resolve_output_dir() -> String:
	if OS.has_environment("AXEL_CAPTURE_OUTPUT") and not OS.get_environment("AXEL_CAPTURE_OUTPUT").is_empty():
		return OS.get_environment("AXEL_CAPTURE_OUTPUT")
	return "user://drawn_scene_captures"


func _main() -> void:
	var failures: PackedStringArray = PackedStringArray()
	var skipped: PackedStringArray = PackedStringArray()
	var wrote := 0
	for path in _WALKABLE_SCENES:
		var result := await _capture_scene(path, true)
		if result == "fail":
			failures.append(path)
		elif result == "skip":
			skipped.append(path)
		else:
			wrote += 1
	for path in _STATIC_SCENES:
		var result := await _capture_scene(path, false)
		if result == "fail":
			failures.append(path)
		elif result == "skip":
			skipped.append(path)
		else:
			wrote += 1

	if not skipped.is_empty():
		print("Skipped (missing drawing): %s" % ", ".join(skipped))
	if failures.is_empty():
		print(
			"Drawn-scene capture OK: %d PNGs -> %s"
			% [wrote, ProjectSettings.globalize_path(_output_dir)]
		)
		quit(0)
	else:
		push_error("Drawn-scene capture FAILED: %s" % ", ".join(failures))
		quit(1)


func _capture_scene(scene_path: String, walk_player: bool) -> String:
	print("--- Capturing %s ---" % scene_path)
	if not ResourceLoader.exists(scene_path):
		push_error("Missing scene: %s" % scene_path)
		return "fail"
	if change_scene_to_file(scene_path) != OK:
		push_error("change_scene_to_file failed: %s" % scene_path)
		return "fail"

	for _i in LAYOUT_FRAMES:
		await process_frame

	if current_scene == null:
		push_error("current_scene null after load: %s" % scene_path)
		return "fail"

	_hide_capture_ui(current_scene)
	if not _has_drawn_background(current_scene):
		push_warning("Skipping %s (background drawing missing from this checkout)." % scene_path)
		return "skip"

	var pin := Vector2.INF
	if walk_player:
		pin = _place_player_walking_at_center(current_scene)
	else:
		_inject_walking_sprite_if_needed(current_scene)

	for _i in WALK_FRAMES:
		_hide_capture_ui(current_scene)
		if walk_player and pin.is_finite():
			_pin_player(current_scene, pin)
		await physics_frame

	if walk_player:
		_freeze_player_mid_stride(current_scene)
	_freeze_injected_sprite(current_scene)

	for _i in SETTLE_FRAMES:
		_hide_capture_ui(current_scene)
		if walk_player and pin.is_finite():
			_pin_player(current_scene, pin)
		await process_frame

	await RenderingServer.frame_post_draw
	_hide_capture_ui(current_scene)

	var png_name := _png_name_for(scene_path)
	var out_path := "%s/%s" % [_output_dir, png_name]
	if not _save_viewport_png(out_path):
		push_error("PNG save failed: %s" % out_path)
		return "fail"
	print("Wrote %s" % ProjectSettings.globalize_path(out_path))
	return "ok"


func _png_name_for(scene_path: String) -> String:
	return scene_path.get_file().get_basename() + ".png"


func _hide_capture_ui(scene: Node) -> void:
	_hide_node(scene.get_node_or_null("TopDialogueOverlay"))
	_hide_node(scene.get_node_or_null("InteractPromptOverlay"))
	_hide_node(scene.get_node_or_null("ExitLayer"))
	var fade := scene.get_node_or_null("TopDialogueOverlay/ViewportRoot/RootMargin")
	if fade is CanvasItem:
		(fade as CanvasItem).visible = false


func _hide_node(node: Node) -> void:
	if node == null:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	elif node is CanvasLayer:
		(node as CanvasLayer).visible = false


func _find_player(scene: Node) -> CharacterBody2D:
	return scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D


func _find_background(scene: Node) -> Sprite2D:
	var walkable := scene.get_node_or_null("WalkableWorld/Background") as Sprite2D
	if walkable != null:
		return walkable
	var named := scene.get_node_or_null("Background_1_1") as Sprite2D
	if named != null:
		return named
	return scene.get_node_or_null("Background") as Sprite2D


func _has_drawn_background(scene: Node) -> bool:
	var sprite := _find_background(scene)
	if sprite != null:
		return sprite.texture != null
	var rect := scene.get_node_or_null("Background") as TextureRect
	if rect != null:
		return rect.texture != null
	return false


func _art_center(bg: Sprite2D) -> Vector2:
	var tex_size := bg.texture.get_size() if bg.texture != null else Vector2.ZERO
	if bg.region_enabled:
		tex_size = bg.region_rect.size
	var size := tex_size * bg.scale
	if bg.centered:
		return bg.global_position
	return bg.global_position + size * 0.5


func _view_center(scene: Node) -> Vector2:
	var cam := scene.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return Vector2.ZERO
	var mode = cam.get("camera_mode")
	if mode != null and int(mode) == CAMERA_MODE_FOLLOW:
		var bg := _find_background(scene)
		if bg != null:
			return _art_center(bg)
	return cam.global_position


func _place_player_walking_at_center(scene: Node) -> Vector2:
	var player := _find_player(scene)
	if player == null:
		push_warning("No PlayerLayer/Player in %s" % scene.scene_file_path)
		return Vector2.INF
	var center := _view_center(scene)
	player.locked_feet_y = -1.0
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_input_enabled(false)
	var fallback := player.get_node_or_null("FallbackBody") as CanvasItem
	if fallback != null:
		fallback.visible = false
	var walk_speed: float = maxf(float(player.speed), 80.0)
	player.set_scripted_velocity(Vector2(walk_speed, 0.0))
	player.global_position = center
	var cam := scene.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.position_smoothing_enabled = false
		if cam.has_method("set_follow_enabled"):
			cam.call("set_follow_enabled", false)
		if cam.has_method("place_center_clamped"):
			cam.call("place_center_clamped", center)
		else:
			cam.global_position = center
	return center


func _pin_player(scene: Node, center: Vector2) -> void:
	var player := _find_player(scene)
	if player == null:
		return
	player.global_position = center


func _freeze_player_mid_stride(scene: Node) -> void:
	var player := _find_player(scene)
	if player == null:
		return
	var sprite := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	var shadow := player.get_node_or_null("ShadowOutline") as AnimatedSprite2D
	_freeze_walk_sprite(sprite)
	_freeze_walk_sprite(shadow)
	player.set_scripted_velocity(Vector2.ZERO)
	player.set_physics_process(false)


func _freeze_walk_sprite(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	sprite.visible = true
	if sprite.sprite_frames.has_animation(WALK_ANIM):
		sprite.play(WALK_ANIM)
		var last := maxi(sprite.sprite_frames.get_frame_count(WALK_ANIM) - 1, 0)
		sprite.frame = mini(WALK_FREEZE_FRAME, last)
	sprite.pause()


func _inject_walking_sprite_if_needed(scene: Node) -> void:
	if _find_player(scene) != null:
		return
	var frames := load("res://assets/sprites/mike_sprite_frames.tres") as SpriteFrames
	if frames == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "CapturePlayerLayer"
	layer.layer = 100
	scene.add_child(layer)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "CaptureWalkSprite"
	sprite.sprite_frames = frames
	sprite.scale = INJECTED_PLAYER_SCALE
	sprite.z_index = 20
	sprite.centered = true
	var vp_size := Vector2(WINDOW)
	if scene.get_viewport() != null:
		vp_size = scene.get_viewport().get_visible_rect().size
	sprite.position = vp_size * 0.5
	layer.add_child(sprite)
	_freeze_walk_sprite(sprite)


func _freeze_injected_sprite(scene: Node) -> void:
	var sprite := scene.get_node_or_null("CapturePlayerLayer/CaptureWalkSprite") as AnimatedSprite2D
	_freeze_walk_sprite(sprite)


func _save_viewport_png(user_path: String) -> bool:
	var vp := root.get_viewport()
	if vp == null:
		return false
	var tex := vp.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.is_empty():
		return false
	var abs_path := ProjectSettings.globalize_path(user_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	return img.save_png(abs_path) == OK
