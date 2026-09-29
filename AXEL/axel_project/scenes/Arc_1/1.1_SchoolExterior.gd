extends ExplorationRoom

@export var skip_intro: bool = false

enum IntroState {
	FORCED_SEQUENCE,
	PLAYER_FREE,
}

@onready var _left_wall_collision: CollisionShape2D = $EnvironmentColliders/LeftWall/CollisionShape2D

var _door_interact_area: Area2D
var _intro_state: IntroState = IntroState.FORCED_SEQUENCE

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _ENDING_1_SCENE_PATH := "res://scenes/Endings/7.1_Ending1.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const _LEAF_Y_CUTOFF_MARGIN := 0.0
const _BEHIND_ZONE_NAMES: PackedStringArray = [
	"TreeLine_Bottom_Behind",
	"TreeLine_Top_Behind",
	"RightWall_Behind",
	"Stump_Left_Behind",
	"Rocks_Left_Behind",
	"Rocks_Right_Behind",
]
const _BEHIND_GATE_BODIES: PackedStringArray = [
	"TreeLine_Bottom",
	"TreeLine_Top",
	"",
	"Stump_Left",
	"Rocks_Left",
	"Rocks_Right",
]
const _POLYGON_FRONT_ZONES: PackedStringArray = [
	"Stump_Left_Behind",
	"Rocks_Left_Behind",
	"Rocks_Right_Behind",
]

const _STONES_ARRIVE_DISTANCE := 36.0
const _SCRIPTED_WALK_SPEED_SCALE := 0.5
const _SCRIPTED_WALK_MAX_FRAMES := 600
const _SECOND_DIALOGUE_DISTANCE := 50.0
const _FIRST_DIALOGUE_LINE := "You promised, you'd never come back."
const _SECOND_DIALOGUE_LINE := "Yet, here we are."
const _THIRD_DIALOGUE_LINE := "Pathetic."
const INTRO_START_WAIT_SEC := 1.0
const INTRO_CAMERA_START_LIFT_PX := 320.0
const INTRO_CAMERA_TILT_DURATION_SEC := 3.4
const INTRO_OFFSCREEN_PAD_PX := 96.0
const EXIT_TRIGGER_GRACE_SEC := 0.15

var _unlock_position: Vector2 = Vector2.ZERO
var _second_dialogue_fired := false
var _watching_movement := false
var _first_line_playing := false
var _exit_trigger: Area2D
var _exit_trigger_armed := true
var _pending_corridor_door_spawn := false
var _arrival_t := InteractArrival.DEFAULT_T
var _arrival_latched_door := false

const _OLD_BG_POSITION := Vector2(32.0, -297.0)
const _OLD_BG_SCALE := Vector2(0.33494318, 0.32130682)

func _ready() -> void:
	_use_default_interact_loop = false
	_player_cover_sync.authored_bg_baseline = _OLD_BG_SCALE.x
	_player_cover_sync.authored_bg_baseline_position = _OLD_BG_POSITION
	bind_player_cover(get_node_or_null("Background_1_1") as Sprite2D, null, false)
	_door_interact_area = get_node_or_null(
		"EnvironmentColliders/Doors/DoorInteractArea"
	) as Area2D
	if is_instance_valid(_door_interact_area):
		_door_interact_area.body_entered.connect(_on_door_interact_body_entered)
		_door_interact_area.body_exited.connect(_on_door_interact_body_exited)
	_exit_trigger = get_node_or_null(
		"EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	if GameManager.take_exterior_spawn_side() == "corridor_door":
		_pending_corridor_door_spawn = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
	set_process_unhandled_input(true)
	if $Camera2D.has_signal("layout_applied"):
		if not $Camera2D.layout_applied.is_connected(_on_background_layout_applied):
			$Camera2D.layout_applied.connect(_on_background_layout_applied)
	_sync_environment_colliders_from_current_background()
	_configure_leaf_occlusion_masks()
	if _pending_corridor_door_spawn or _should_skip_intro():
		_intro_state = IntroState.PLAYER_FREE
		_arm_exit_trigger_grace()

		if is_instance_valid(_left_wall_collision):
			_left_wall_collision.set_deferred("disabled", true)
		if _pending_corridor_door_spawn:

			call_deferred("_apply_corridor_door_peek_if_pending")
		_enable_player_control()
		_refresh_door_interact_prompt()
		return


	call_deferred("_begin_forced_intro_after_layout")


func _exit_tree() -> void:
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()


func _begin_forced_intro_after_layout() -> void:
	_sync_environment_colliders_from_current_background()
	_run_forced_intro_sequence()


func blocks_player_tex_save() -> bool:
	return _intro_state == IntroState.FORCED_SEQUENCE


func _should_skip_intro() -> bool:
	if skip_intro:
		return true
	if AxelSaves.consume_skip_intro():
		return true
	return OS.has_environment("AXEL_SKIP_INTRO") and OS.get_environment("AXEL_SKIP_INTRO") == "1"


func _process(_delta: float) -> void:
	if _arrival_latched_door and InteractZoneGate.movement_pressed():
		_arrival_latched_door = false
	if _intro_state == IntroState.PLAYER_FREE and not _is_transitioning:
		_refresh_door_interact_prompt()
	if not _watching_movement or _second_dialogue_fired:
		return
	if not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(_unlock_position) < _scaled_intro_distance(_SECOND_DIALOGUE_DISTANCE):
		return
	_second_dialogue_fired = true
	_watching_movement = false
	_play_second_then_pathetic()


func _play_second_then_pathetic() -> void:
	if not _top_dialogue.has_method("show_lines"):
		return
	await _top_dialogue.show_lines([_SECOND_DIALOGUE_LINE, _THIRD_DIALOGUE_LINE])


func _run_forced_intro_sequence() -> void:
	_intro_state = IntroState.FORCED_SEQUENCE
	_disable_player_control()
	AxelEventFx.set_cadence_enabled(false)

	if is_instance_valid(_left_wall_collision):
		_left_wall_collision.set_deferred("disabled", true)

	AxelEventFx.start_interface_distortion(true)


	var spawn_target_tex := _capture_intro_target_tex()
	var cam := $Camera2D as BackgroundCamera


	var saved_smoothing := false
	if cam != null:
		var spawn_target := _resolve_intro_target_from_tex(spawn_target_tex)
		saved_smoothing = cam.position_smoothing_enabled
		cam.position_smoothing_enabled = false
		cam.set_follow_enabled(false)
		cam.place_center_clamped(
			Vector2(
				spawn_target.x,
				spawn_target.y - _scaled_intro_distance(INTRO_CAMERA_START_LIFT_PX)
			)
		)
	if is_instance_valid(_player):
		_player.global_position = _intro_offscreen_left_spawn(
			_resolve_intro_target_from_tex(spawn_target_tex)
		)

	if AxelEventFx.is_load_cover_up():
		AxelEventFx.notify_intro_pose_ready()
		await AxelEventFx.wait_load_cover_clear()

	await get_tree().create_timer(INTRO_START_WAIT_SEC).timeout
	if cam != null:
		await _intro_camera_tilt_to(cam, spawn_target_tex)
	await _scripted_walk_horizontal_to(spawn_target_tex)
	if cam != null:
		cam.place_center_clamped(_resolve_intro_target_from_tex(spawn_target_tex))
		cam.position_smoothing_enabled = saved_smoothing
		cam.set_follow_enabled(true)


	if is_instance_valid(_left_wall_collision):
		_left_wall_collision.set_deferred("disabled", true)

	_unlock_position = _player.global_position
	_enable_player_control()
	_intro_state = IntroState.PLAYER_FREE
	_enter_dialogue_pending = true
	_refresh_door_interact_prompt()
	_arm_exit_trigger_grace()

	# Walk-away lines and the left-edge ending wait until this one finishes.
	_first_line_playing = true
	await _play_first_dialogue_line()
	_first_line_playing = false
	if is_inside_tree() and not _is_transitioning:
		if _player_in_exit_trigger():
			call_deferred("_begin_ending_1_transition")
		else:
			_watching_movement = true
	await AxelEventFx.stop_interface_distortion()
	AxelEventFx.set_cadence_enabled(true)


func _capture_intro_target_tex() -> Vector2:
	var env := get_node_or_null("EnvironmentColliders") as Node2D
	if env == null or not is_instance_valid(_player):
		return Vector2.ZERO
	return env.to_local(_player.global_position)


func _resolve_intro_target_from_tex(target_tex: Vector2) -> Vector2:
	var env := get_node_or_null("EnvironmentColliders") as Node2D
	if env == null:
		return target_tex
	return env.to_global(target_tex)


func _current_intro_cover_ratio() -> float:
	var background := get_node_or_null("Background_1_1") as Sprite2D
	if background == null or _OLD_BG_SCALE.x == 0.0:
		return 1.0
	return background.scale.x / _OLD_BG_SCALE.x


func _scaled_intro_distance(distance_px: float) -> float:
	return distance_px * _current_intro_cover_ratio()


func _intro_camera_tilt_to(cam: BackgroundCamera, target_tex: Vector2) -> void:
	if cam == null:
		return
	var start := cam.global_position
	var duration := INTRO_CAMERA_TILT_DURATION_SEC
	if duration <= 0.0:
		cam.place_center_clamped(_resolve_intro_target_from_tex(target_tex))
		return
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(cam):
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var end_center := _resolve_intro_target_from_tex(target_tex)

		var s := t * t * (3.0 - 2.0 * t)
		cam.place_center_clamped(start.lerp(end_center, s))
		await get_tree().process_frame
	if is_instance_valid(cam):
		cam.place_center_clamped(_resolve_intro_target_from_tex(target_tex))


func _intro_offscreen_left_spawn(stones_target: Vector2) -> Vector2:
	var cam := $Camera2D as Camera2D
	if cam == null:
		return Vector2(stones_target.x - 400.0, stones_target.y)
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		vp = Vector2(1920.0, 1280.0)
	var half := vp / (2.0 * cam.zoom)

	var spawn_x := cam.global_position.x - half.x - _scaled_intro_distance(INTRO_OFFSCREEN_PAD_PX)
	return Vector2(spawn_x, stones_target.y)


func _play_first_dialogue_line() -> void:
	if not _top_dialogue.has_method("type_line"):
		_enter_dialogue_pending = false
		return

	var has_token_guard := _top_dialogue.has_method("current_line_token") and \
		_top_dialogue.has_method("is_line_token_current")
	var token: int = _top_dialogue.call("current_line_token") if has_token_guard else -1

	_enter_dialogue_pending = false
	await _top_dialogue.type_line(_FIRST_DIALOGUE_LINE)
	if has_token_guard and not _top_dialogue.call("is_line_token_current", token):
		return

	if _top_dialogue.has_method("await_line_advance"):
		await _top_dialogue.await_line_advance()
	if has_token_guard and not _top_dialogue.call("is_line_token_current", token):
		return

	if _top_dialogue.has_method("hide_line"):
		await _top_dialogue.hide_line()


func _disable_player_control() -> void:
	if is_instance_valid(_player) and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(false)


func _enable_player_control() -> void:
	if not is_instance_valid(_player):
		return
	if _player.has_method("clear_scripted_velocity"):
		_player.clear_scripted_velocity()
	if _player.has_method("set_input_enabled"):
		_player.set_input_enabled(true)


func _scripted_walk_horizontal_to(target_tex: Vector2) -> void:
	if not is_instance_valid(_player):
		return

	var base_speed := float(_player.get("speed")) if _player.get("speed") != null else 120.0
	var move_speed := base_speed * _SCRIPTED_WALK_SPEED_SCALE
	var frames := 0

	while is_instance_valid(_player):
		frames += 1
		var target := _resolve_intro_target_from_tex(target_tex)

		var road_y := target.y
		_player.global_position.y = road_y
		var dx := target.x - _player.global_position.x
		if absf(dx) <= _scaled_intro_distance(_STONES_ARRIVE_DISTANCE) or frames >= _SCRIPTED_WALK_MAX_FRAMES:
			break
		var direction := Vector2(signf(dx), 0.0)
		if _player.has_method("set_scripted_velocity"):
			_player.set_scripted_velocity(direction * move_speed)
		await get_tree().physics_frame

	if is_instance_valid(_player):
		var target := _resolve_intro_target_from_tex(target_tex)
		var road_y := target.y
		_player.global_position.y = road_y
		if _player.has_method("clear_scripted_velocity"):
			_player.clear_scripted_velocity()
			_player.velocity = Vector2.ZERO


func _polygon_global_centroid(poly: CollisionPolygon2D) -> Vector2:
	if poly.polygon.is_empty():
		return poly.global_position
	var sum := Vector2.ZERO
	for local_point in poly.polygon:
		sum += poly.to_global(local_point)
	return sum / float(poly.polygon.size())


func _unhandled_input(event: InputEvent) -> void:
	if _intro_state != IntroState.PLAYER_FREE:
		return
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
		return
	if not _is_player_near_door():
		return
	_begin_door_transition()


func _is_interaction_event(event: InputEvent) -> bool:

	return event.is_action_pressed("interact")


func _is_player_near_door() -> bool:
	if _arrival_latched_door:
		return true
	return InteractZoneGate.body_in_area(_door_interact_area, _player)


func _door_interact_anchor() -> Vector2:
	if not is_instance_valid(_door_interact_area):
		return Vector2.ZERO
	var poly := _door_interact_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return _door_interact_area.global_position
	return _polygon_global_centroid(poly)


func _apply_corridor_door_peek_if_pending() -> void:
	if not _pending_corridor_door_spawn or not is_instance_valid(_player):
		return
	_pending_corridor_door_spawn = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.CENTER_X,
		0.0
	)
	_arrival_latched_door = true
	call_deferred("_clamp_arrived_player")


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


func _on_door_interact_body_entered(body: Node) -> void:
	if body != _player:
		return
	_try_show_door_interact_prompt()


func _on_door_interact_body_exited(body: Node) -> void:
	if body != _player:
		return
	if _is_transitioning:
		return
	_hide_door_interact_prompt()


func _try_show_door_interact_prompt() -> void:
	if _intro_state != IntroState.PLAYER_FREE or _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(_door_interact_anchor())


func _hide_door_interact_prompt() -> void:
	if _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func _refresh_door_interact_prompt() -> void:
	if _is_player_near_door():
		_try_show_door_interact_prompt()
	else:
		_hide_door_interact_prompt()


func _begin_door_transition() -> void:
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_Y
			)
		)
	GameManager.set_corridor_spawn_side("exterior_door")
	begin_scene_change(_NEXT_SCENE_PATH, false)


func _on_exit_trigger_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning:
		return
	if _first_line_playing:
		return
	if _intro_state != IntroState.PLAYER_FREE or not _exit_trigger_armed:
		return
	call_deferred("_begin_ending_1_transition")


func _player_in_exit_trigger() -> bool:
	return InteractZoneGate.body_in_area(_exit_trigger, _player)


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	await get_tree().create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true


func _begin_ending_1_transition() -> void:
	begin_scene_change(_ENDING_1_SCENE_PATH)


func _get_leaf_occlusion_zones() -> Array[Area2D]:
	var colliders := get_node_or_null("EnvironmentColliders")
	if colliders == null:
		return []
	var zones: Array[Area2D] = []
	for zone_name in _BEHIND_ZONE_NAMES:
		zones.append(colliders.get_node_or_null(zone_name) as Area2D)
	var found := false
	for zone in zones:
		if zone != null:
			found = true
			break
	if not found:
		zones.clear()
		for legacy_name in ["TreeLine_Bottom_Leaves", "TreeLine_Top_Leaves"]:
			var zone := colliders.get_node_or_null(legacy_name) as Area2D
			if zone != null:
				zones.append(zone)
				found = true
	if not found:
		push_warning("1.1_SchoolExterior: no leaf occlusion zones found under EnvironmentColliders.")
	return zones


func _configure_leaf_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var polygons: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	var slot_parts: Array = []
	var slot_part_cutoffs: Array = []
	var zone_cutoffs := _behind_zone_y_cutoffs()
	var zone_i := 0
	for leaf_zone in _get_leaf_occlusion_zones():
		var packed_points := PackedVector2Array()
		var packed_parts := Vector4i.ZERO
		var feather := 0.0
		var shader_polys: Array = []
		if is_instance_valid(leaf_zone) and leaf_zone.has_method("get_packed_shader_points"):
			packed_points = leaf_zone.call("get_packed_shader_points")
			packed_parts = leaf_zone.call("get_packed_part_counts")
			feather = float(leaf_zone.get("feather_px"))
			if leaf_zone.has_method("get_shader_polygons"):
				shader_polys = leaf_zone.call("get_shader_polygons")
		elif is_instance_valid(leaf_zone) and leaf_zone.has_method("get_shader_polygon"):
			packed_points = leaf_zone.call("get_shader_polygon")
			feather = float(leaf_zone.get("feather_px"))
		polygons.append(packed_points)
		feathers.append(feather)
		slot_parts.append(packed_parts)
		var slot_cutoff: float = zone_cutoffs[zone_i] if zone_i < zone_cutoffs.size() else 1e9
		slot_part_cutoffs.append(
			_part_y_cutoffs_for_zone(zone_i, shader_polys, slot_cutoff)
		)
		zone_i += 1
	while polygons.size() < 6:
		polygons.append(PackedVector2Array())
		feathers.append(0.0)
		slot_parts.append(Vector4i.ZERO)
		slot_part_cutoffs.append(Vector4.ZERO)
	_player.call(
		"configure_leaf_occlusion_polygons",
		polygons[0],
		polygons[1],
		feathers[0],
		feathers[1],
		_LEAF_FADE_ALPHA,
		zone_cutoffs[0],
		zone_cutoffs[1],
		_LEAF_GATE_SOFTNESS,
		polygons[2],
		feathers[2],
		zone_cutoffs[2],
		false,
		polygons[3],
		feathers[3],
		zone_cutoffs[3],
		polygons[4],
		feathers[4],
		zone_cutoffs[4],
		polygons[5],
		feathers[5],
		zone_cutoffs[5],
		slot_parts,
		slot_part_cutoffs,
	)


func _sync_environment_colliders_from_current_background() -> void:
	var background := get_node_or_null("Background_1_1") as Sprite2D
	if background == null:
		return
	_sync_environment_colliders(background.scale.x, background.position)


func _on_background_layout_applied(
	scale_factor: float, bg_position: Vector2, _world_rect: Rect2
) -> void:
	_sync_environment_colliders(scale_factor, bg_position)


func _sync_environment_colliders(new_scale_factor: float, new_bg_position: Vector2) -> void:
	var env := get_node_or_null("EnvironmentColliders") as Node2D
	if env == null:
		return
	var tex_pos := PlayerSpawnSync.capture_tex(env, _player)
	var env_scale := Vector2(
		new_scale_factor / _OLD_BG_SCALE.x, new_scale_factor / _OLD_BG_SCALE.y
	)
	env.position = new_bg_position - env_scale * _OLD_BG_POSITION
	env.scale = env_scale
	PlayerSpawnSync.apply_tex(env, _player, tex_pos)
	if is_instance_valid(_player):
		_player_cover_sync.apply(_player, new_scale_factor, new_bg_position)
	call_deferred("_wake_static_colliders")
	call_deferred("_configure_leaf_occlusion_masks")
	if _pending_corridor_door_spawn:
		call_deferred("_apply_corridor_door_peek_if_pending")


func _wake_static_colliders() -> void:
	var env := get_node_or_null("EnvironmentColliders")
	if env == null:
		return
	for child in env.get_children():
		if child is StaticBody2D:
			child.position = child.position


func _behind_zone_y_cutoffs() -> Array[float]:
	var colliders := get_node_or_null("EnvironmentColliders")
	var cutoffs: Array[float] = []
	for i in _BEHIND_ZONE_NAMES.size():
		var zone_name: String = _BEHIND_ZONE_NAMES[i]
		if _polygon_front_zone(zone_name):
			cutoffs.append(_zone_polygon_front_y(colliders, zone_name))
			continue
		var body_name := _BEHIND_GATE_BODIES[i] if i < _BEHIND_GATE_BODIES.size() else ""
		if body_name.is_empty() or colliders == null:
			cutoffs.append(1e9)
			continue
		var body := colliders.get_node_or_null(body_name) as StaticBody2D
		cutoffs.append(_collision_front_y_cutoff(body))
	while cutoffs.size() < 6:
		cutoffs.append(1e9)
	return cutoffs


func _polygon_front_zone(zone_name: String) -> bool:
	return _POLYGON_FRONT_ZONES.has(zone_name)


func _zone_polygon_front_y(colliders: Node, zone_name: String) -> float:
	if colliders == null:
		return 1e9
	var zone := colliders.get_node_or_null(zone_name) as Area2D
	if not is_instance_valid(zone) or not zone.has_method("get_shader_polygons"):
		return 1e9
	var max_y := -INF
	for poly in zone.call("get_shader_polygons"):
		max_y = maxf(max_y, _packed_max_y(poly))
	if max_y == -INF:
		return 1e9
	return max_y


func _collision_front_y_cutoff(body: StaticBody2D) -> float:
	if not is_instance_valid(body):
		return 1e9
	var max_y := -INF
	for child in body.get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.is_empty():
			continue
		max_y = maxf(max_y, _polygon_node_front_y(polygon_node))
	if max_y == -INF:
		return body.global_position.y - _LEAF_Y_CUTOFF_MARGIN
	return max_y


func _part_y_cutoffs_for_zone(
	zone_index: int, shader_polys: Array, slot_cutoff: float
) -> Vector4:
	if (
		zone_index >= 0
		and zone_index < _BEHIND_ZONE_NAMES.size()
		and _polygon_front_zone(_BEHIND_ZONE_NAMES[zone_index])
	):
		return _part_fronts_from_shader_polys(shader_polys, slot_cutoff)
	var cutoffs := Vector4(slot_cutoff, slot_cutoff, slot_cutoff, slot_cutoff)
	var colliders := get_node_or_null("EnvironmentColliders")
	if colliders == null or zone_index < 0 or zone_index >= _BEHIND_GATE_BODIES.size():
		return cutoffs
	var body_name := _BEHIND_GATE_BODIES[zone_index]
	if body_name.is_empty():
		return Vector4(1e9, 1e9, 1e9, 1e9)
	var body := colliders.get_node_or_null(body_name) as StaticBody2D
	if not is_instance_valid(body):
		return cutoffs
	var fronts: Array = []
	for child in body.get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.is_empty():
			continue
		fronts.append({
			"centroid": _polygon_node_centroid_world(polygon_node),
			"y": _polygon_node_front_y(polygon_node),
		})
	if fronts.is_empty() or shader_polys.is_empty():
		return cutoffs
	for part_i in mini(shader_polys.size(), 4):
		var poly: PackedVector2Array = shader_polys[part_i]
		var centroid := _packed_centroid(poly)
		var best_y := slot_cutoff
		var best_d := INF
		for item in fronts:
			var d: float = centroid.distance_squared_to(item.centroid)
			if d < best_d:
				best_d = d
				best_y = item.y
		match part_i:
			0:
				cutoffs.x = best_y
			1:
				cutoffs.y = best_y
			2:
				cutoffs.z = best_y
			3:
				cutoffs.w = best_y
	return cutoffs


func _part_fronts_from_shader_polys(shader_polys: Array, slot_cutoff: float) -> Vector4:
	var cutoffs := Vector4(slot_cutoff, slot_cutoff, slot_cutoff, slot_cutoff)
	for part_i in mini(shader_polys.size(), 4):
		var poly: PackedVector2Array = shader_polys[part_i]
		var front_y := _packed_max_y(poly)
		if front_y == -INF:
			continue
		match part_i:
			0:
				cutoffs.x = front_y
			1:
				cutoffs.y = front_y
			2:
				cutoffs.z = front_y
			3:
				cutoffs.w = front_y
	return cutoffs


func _packed_max_y(poly: PackedVector2Array) -> float:
	var max_y := -INF
	for point in poly:
		max_y = maxf(max_y, point.y)
	return max_y


func _polygon_node_front_y(polygon_node: CollisionPolygon2D) -> float:
	var max_y := -INF
	for local_point in polygon_node.polygon:
		max_y = maxf(max_y, polygon_node.to_global(local_point).y)
	if max_y == -INF:
		return 1e9
	return max_y - _LEAF_Y_CUTOFF_MARGIN


func _polygon_node_centroid_world(polygon_node: CollisionPolygon2D) -> Vector2:
	return _packed_centroid(_world_points_of_polygon(polygon_node))


func _world_points_of_polygon(polygon_node: CollisionPolygon2D) -> PackedVector2Array:
	var world_points := PackedVector2Array()
	world_points.resize(polygon_node.polygon.size())
	for i in polygon_node.polygon.size():
		world_points[i] = polygon_node.to_global(polygon_node.polygon[i])
	return world_points


func _packed_centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())
