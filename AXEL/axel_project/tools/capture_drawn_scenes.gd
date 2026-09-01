extends SceneTree
## Simulate each ready exploration scene and capture a PNG.
##
## Walkable rooms: load the real scene, skip intro/dialogue, then steer Mike
## from the authored spawn toward the framed view (or art) center with WASD.
## Collision, camera follow, cover-sync, and the walk cycle all run live.
## Capture happens while a movement key is still held.
##
## Still drawings (locker / memories / desk): load as-is. No player is injected.
##
## Run from repo root (needs a display — do NOT pass --headless):
##   DISPLAY=:1 godot --path AXEL/axel_project -s res://tools/capture_drawn_scenes.gd
##
## Optional env:
##   AXEL_CAPTURE_OUTPUT=/abs/or/user://dir

const WINDOW := Vector2i(1920, 1280)
const LAYOUT_FRAMES := 36
const MAX_WALK_FRAMES := 720
const ARRIVE_DISTANCE_PX := 90.0
const STUCK_FRAMES := 10
const STUCK_EPSILON_PX := 0.6
const SLIDE_FRAMES := 22
const WALK_POSE_FRAMES := 28
const CAMERA_MODE_FOLLOW := 1

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

const _STILL_SCENES: PackedStringArray = [
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
	OS.set_environment("AXEL_SKIP_DESK_SEQUENCE", "1")
	_output_dir = _resolve_output_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	DisplayServer.window_set_size(WINDOW)
	root.size = WINDOW
	call_deferred("_main")


func _resolve_output_dir() -> String:
	if OS.has_environment("AXEL_CAPTURE_OUTPUT") and not OS.get_environment("AXEL_CAPTURE_OUTPUT").is_empty():
		return OS.get_environment("AXEL_CAPTURE_OUTPUT")
	return "user://drawn_scene_captures"


func _mark_enter_lines_seen() -> void:
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		return
	for method_name in [
		"set_cafeteria_enter_line_seen",
		"set_kitchen_enter_line_seen",
		"set_backyard_enter_line_seen",
		"set_teachers_lounge_enter_line_seen",
		"set_classroom_enter_line_seen",
	]:
		if gm.has_method(method_name):
			gm.call(method_name, true)


func _main() -> void:
	_mark_enter_lines_seen()
	var failures: PackedStringArray = PackedStringArray()
	var wrote := 0
	for path in _WALKABLE_SCENES:
		if not await _capture_scene(path, true):
			failures.append(path)
		else:
			wrote += 1
	for path in _STILL_SCENES:
		if not await _capture_scene(path, false):
			failures.append(path)
		else:
			wrote += 1

	if failures.is_empty():
		print(
			"Drawn-scene capture OK: %d PNGs -> %s"
			% [wrote, ProjectSettings.globalize_path(_output_dir)]
		)
		quit(0)
	else:
		push_error("Drawn-scene capture FAILED: %s" % ", ".join(failures))
		quit(1)


func _capture_scene(scene_path: String, walk_player: bool) -> bool:
	print("--- Capturing %s ---" % scene_path)
	if not ResourceLoader.exists(scene_path):
		push_error("Missing scene: %s" % scene_path)
		return false
	if change_scene_to_file(scene_path) != OK:
		push_error("change_scene_to_file failed: %s" % scene_path)
		return false

	for _i in LAYOUT_FRAMES:
		await process_frame

	if current_scene == null:
		push_error("current_scene null after load: %s" % scene_path)
		return false

	_hide_capture_ui(current_scene)
	_prepare_html_standin(current_scene)
	for _j in 12:
		await process_frame
	_hide_capture_ui(current_scene)
	var driver := InputEventDriver.new(self, false)

	if walk_player:
		await _simulate_walk_toward_middle(current_scene, driver)
		_hide_capture_ui(current_scene)
		await RenderingServer.frame_post_draw
		_hide_capture_ui(current_scene)
		var png_name := scene_path.get_file().get_basename() + ".png"
		var out_path := "%s/%s" % [_output_dir, png_name]
		if not _save_viewport_png(out_path):
			push_error("PNG save failed: %s" % out_path)
			driver.release_all()
			return false
		print("Wrote %s" % ProjectSettings.globalize_path(out_path))
		driver.release_all()
		return true

	if scene_path.ends_with("5.2_ClassroomDesk.tscn"):
		var ok_desk := await _capture_desk_stages(current_scene)
		driver.release_all()
		return ok_desk

	await create_timer(0.45).timeout
	for _i in 8:
		_hide_capture_ui(current_scene)
		await process_frame
	_hide_capture_ui(current_scene)
	await RenderingServer.frame_post_draw
	_hide_capture_ui(current_scene)
	var still_name := scene_path.get_file().get_basename() + ".png"
	var still_path := "%s/%s" % [_output_dir, still_name]
	var ok := _save_viewport_png(still_path)
	driver.release_all()
	if not ok:
		push_error("PNG save failed: %s" % still_path)
		return false
	print("Wrote %s" % ProjectSettings.globalize_path(still_path))
	return true


func _capture_desk_stages(scene: Node) -> bool:
	const STAGES: Array[Array] = [
		["res://exports/Drawings/desk_empty.png", "5.2_ClassroomDesk_empty.png"],
		["res://exports/Drawings/desk_hand.png", "5.2_ClassroomDesk_hand.png"],
		["res://exports/Drawings/desk.png", "5.2_ClassroomDesk_message.png"],
	]
	if not scene.has_method("_set_plate"):
		push_error("Desk scene missing _set_plate")
		return false
	var dim := scene.get_node_or_null("DimLayer/DimRect") as ColorRect
	if dim != null:
		dim.color = Color(1, 1, 1, 0)
	if scene.has_method("_stop_local_shake"):
		scene.call("_stop_local_shake")
	for stage in STAGES:
		scene.call("_set_plate", stage[0])
		_relayout_camera(scene)
		for _i in 14:
			_hide_capture_ui(scene)
			await process_frame
		_hide_capture_ui(scene)
		await RenderingServer.frame_post_draw
		_hide_capture_ui(scene)
		var out_path := "%s/%s" % [_output_dir, stage[1]]
		if not _save_viewport_png(out_path):
			push_error("PNG save failed: %s" % out_path)
			return false
		print("Wrote %s" % ProjectSettings.globalize_path(out_path))
	return true


func _simulate_walk_toward_middle(scene: Node, driver: InputEventDriver) -> void:
	var player := _find_player(scene)
	if player == null:
		push_warning("No PlayerLayer/Player in %s — capturing spawn view." % scene.scene_file_path)
		return
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(true)

	var target := _walk_target(scene, player)
	var start := player.global_position
	print(
		"Walk start %s spawn=(%.0f, %.0f) target=(%.0f, %.0f)"
		% [scene.scene_file_path, start.x, start.y, target.x, target.y]
	)
	var last_pos := start
	var stuck_for := 0
	var held: Array[int] = []
	var slide_queue: Array[Array] = []
	var sliding := 0

	for _i in MAX_WALK_FRAMES:
		_hide_capture_ui(scene)
		if not is_instance_valid(player):
			break
		var delta: Vector2 = target - player.global_position
		if delta.length() <= ARRIVE_DISTANCE_PX:
			break
		var next_keys: Array[int] = []
		if sliding > 0:
			for keycode in slide_queue[0]:
				next_keys.append(int(keycode))
			sliding -= 1
			if sliding <= 0:
				slide_queue.pop_front()
		else:
			next_keys = _keys_for_delta(delta)
		if next_keys.is_empty():
			break
		_apply_keys(driver, held, next_keys)
		held = next_keys
		await physics_frame
		var moved := player.global_position.distance_to(last_pos)
		if moved < STUCK_EPSILON_PX:
			stuck_for += 1
		else:
			stuck_for = 0
			last_pos = player.global_position
			if sliding <= 0:
				slide_queue.clear()
		if stuck_for >= STUCK_FRAMES and sliding <= 0:
			if slide_queue.is_empty():
				slide_queue = _slide_options(delta, held)
			if slide_queue.is_empty():
				break
			sliding = SLIDE_FRAMES
			stuck_for = 0

	if held.is_empty():
		held = [KEY_D]
		driver.press(KEY_D)

	for _i in WALK_POSE_FRAMES:
		_hide_capture_ui(scene)
		await physics_frame

	if is_instance_valid(player):
		var anim := ""
		var sprite := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
		if sprite != null:
			anim = String(sprite.animation)
		print(
			"Walk end pos=(%.0f, %.0f) anim=%s keys=%s"
			% [player.global_position.x, player.global_position.y, anim, str(held)]
		)


func _apply_keys(driver: InputEventDriver, previous: Array[int], next_keys: Array[int]) -> void:
	for keycode in previous:
		if not next_keys.has(keycode):
			driver.release(keycode)
	for keycode in next_keys:
		if not previous.has(keycode):
			driver.press(keycode)


func _keys_for_delta(delta: Vector2) -> Array[int]:
	var keys: Array[int] = []
	if absf(delta.x) >= 8.0:
		keys.append(KEY_D if delta.x > 0.0 else KEY_A)
	if absf(delta.y) >= 8.0:
		keys.append(KEY_S if delta.y > 0.0 else KEY_W)
	return keys


func _slide_options(delta: Vector2, current: Array[int]) -> Array[Array]:
	var horiz := KEY_D if delta.x >= 0.0 else KEY_A
	var vert := KEY_S if delta.y >= 0.0 else KEY_W
	var other_vert := KEY_W if vert == KEY_S else KEY_S
	var other_horiz := KEY_A if horiz == KEY_D else KEY_D
	var raw: Array[Array] = [
		[vert],
		[other_vert],
		[horiz, vert],
		[horiz, other_vert],
		[other_horiz],
		_keys_for_delta(delta),
	]
	var options: Array[Array] = []
	var seen := {}
	for candidate in raw:
		if candidate.is_empty():
			continue
		var key := _keys_signature(candidate)
		if key == _keys_signature(current) or seen.has(key):
			continue
		seen[key] = true
		options.append(candidate)
	return options


func _keys_signature(keys: Array) -> String:
	var parts: PackedStringArray = []
	for keycode in keys:
		parts.append(str(int(keycode)))
	return ",".join(parts)


func _walk_target(scene: Node, player: CharacterBody2D) -> Vector2:
	var cam := scene.get_node_or_null("Camera2D") as Camera2D
	var bg := _find_background(scene)
	var art := _art_center(bg) if bg != null and bg.texture != null else Vector2.INF
	if cam == null:
		return art if art.is_finite() else player.global_position
	var mode = cam.get("camera_mode")
	if mode != null and int(mode) == CAMERA_MODE_FOLLOW:
		if art.is_finite():
			return art
		return player.global_position
	return cam.global_position


func _prepare_html_standin(scene: Node) -> void:
	# Gitignored production plates are missing in this checkout. Scenes that
	# still use HTML phone drawings (already red-on-black) must not run the
	# white-ink noir/CRT stack, and memory stills must not 1.85-crop a portrait.
	if not _is_html_standin(scene):
		return
	_hide_post_fx(scene)
	_hide_node(scene.get_node_or_null("WalkableWorld/EnvironmentColliders/FlashlightVisual"))
	var void_fill := scene.get_node_or_null("WalkableWorld/VoidFill")
	if void_fill is Polygon2D:
		(void_fill as Polygon2D).color = Color(0, 0, 0, 1)
	elif void_fill is CanvasItem:
		(void_fill as CanvasItem).visible = false
	var frame := scene.get_node_or_null("MemoryFrame")
	if frame != null:
		frame.set_script(null)
	var bg := _find_background(scene)
	if bg != null:
		bg.region_enabled = false
		bg.scale = Vector2.ONE
	_relayout_camera(scene)


func _is_html_standin(scene: Node) -> bool:
	var fname := scene.scene_file_path.get_file()
	return fname in [
		"2.3_Kitchen.tscn",
		"2.4_ClassroomsCorridor.tscn",
		"3.1_Backyard.tscn",
		"4.1_TeachersLounge.tscn",
		"5.1_Classroom.tscn",
		"2.2_CafeteriaMemory.tscn",
		"3.2_BackyardMemory.tscn",
		"4.2_TeachersMemory.tscn",
		"5.2_ClassroomDesk.tscn",
	]


func _relayout_camera(scene: Node) -> void:
	var cam := scene.get_node_or_null("Camera2D")
	if cam != null and cam.has_method("_run_pipeline"):
		cam.call("_run_pipeline")


func _hide_post_fx(scene: Node) -> void:
	for overlay_name in [
		"NoirPaletteOverlay",
		"NoirPaletteOverlayFx",
		"ScanlineOverlay",
		"CrtPluginOverlay",
		"CrtCombatOverlay",
	]:
		_hide_node(scene.get_node_or_null(overlay_name))
	for child in scene.get_children():
		var n := String(child.name)
		if n.begins_with("Noir") or n.begins_with("Crt") or n.begins_with("Scanline"):
			_hide_node(child)


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


func _art_center(bg: Sprite2D) -> Vector2:
	var tex_size := bg.texture.get_size() if bg.texture != null else Vector2.ZERO
	if bg.region_enabled:
		tex_size = bg.region_rect.size
	var size := tex_size * bg.scale
	if bg.centered:
		return bg.global_position
	return bg.global_position + size * 0.5


func _hide_capture_ui(scene: Node) -> void:
	_hide_named_ui(scene)
	var fade := scene.get_node_or_null("TopDialogueOverlay/ViewportRoot/RootMargin")
	if fade is CanvasItem:
		(fade as CanvasItem).visible = false
	_hide_noir_for_html_standin(scene)


func _hide_noir_for_html_standin(scene: Node) -> void:
	if _is_html_standin(scene):
		_hide_post_fx(scene)


func _hide_named_ui(node: Node) -> void:
	if node == null:
		return
	var n := node.name
	if n == "TopDialogueOverlay" or n == "InteractPromptOverlay" or n == "ExitLayer" or n == "MemoryIndicator":
		if node.has_method("hide_prompt"):
			node.call("hide_prompt")
		if node.has_method("set_process"):
			node.set_process(false)
		_hide_node(node)
	for child in node.get_children():
		_hide_named_ui(child)


func _hide_node(node: Node) -> void:
	if node == null:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	elif node is CanvasLayer:
		(node as CanvasLayer).visible = false


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
