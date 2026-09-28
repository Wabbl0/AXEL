extends ExplorationRoom

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const LOUNGE_SELF_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const MEMORY_SCENE := "res://scenes/Arc_4/4.2_TeachersMemory.tscn"
const MEMORY_KEY := "teachers_memory"
const ENTER_LINES := [
	"You always wondered what the teachers were doing behind closed doors.",
	"Pervert.",
]
const KEY_NEAR_LINES := [
	"There's a key.",
	"Why hasn't anyone nicked it yet?",
]
const KEY_PICKUP_LINES := [
	"You take the key.",
	"Like a good little boy.",
]
const LIAR_LINES := [
	"Liar. You knew exactly where he was.",
]
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const _BEHIND_ZONE_NAMES: PackedStringArray = [
	"TableBlock_Behind",
	"ChairBlock_Behind",
	"LeftCabinetBlock_Behind",
]

var _door_interact_area: Area2D
var _key_near_area: Area2D
var _key_interact_area: Area2D
var _key_visual: Node2D
var _key_glow_tween: Tween
var _memory_area: Area2D
var _key_near_pending := false
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T


func _ready() -> void:
	bind_player_cover()
	_wake_include_areas = true
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_key_near_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KeyNearArea"
	) as Area2D
	_key_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KeyInteractArea"
	) as Area2D
	_key_visual = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KeyVisual"
	) as Node2D
	_memory_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/MemoryInteractArea"
	) as Area2D
	_apply_key_visibility()
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")
	_enter_dialogue_pending = _will_play_enter_dialogue()
	call_deferred("_play_enter_dialogue")


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["key", "memory", "door"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"key":
			return _key_interact_area
		"memory":
			return _memory_area
		"door":
			return _door_interact_area
		_:
			return null


func zone_is_available(zone_id: String) -> bool:
	if zone_id == "key":
		return not LorePickup.is_owned("hasKey")
	if zone_id == "memory":
		return not GameManager.has_memory_scene(MEMORY_KEY)
	return true


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"key":
			_line_running = true
			call_deferred("_pickup_key")
		"memory":
			save_player_tex("set_teachers_lounge_memory_return_pos")
			begin_scene_change(MEMORY_SCENE)
		"door":
			leave_through(
				_door_interact_area,
				Vector2.AXIS_X,
				"set_classrooms_corridor_spawn_side",
				"lounge_door",
				CORRIDOR_SCENE,
			)


func extra_blocks_interact() -> bool:
	return _line_running


func _will_play_enter_dialogue() -> bool:
	if not GameManager.teachers_lounge_enter_line_seen:
		return true
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.teachers_liar_line_seen:
		return true
	return false


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_teachers_lounge_spawn_side() == "corridor_door":
		_pending_door_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_door_peek_after_wake")
		return
	if GameManager.has_teachers_lounge_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")


func _apply_key_visibility() -> void:
	if LorePickup.is_owned("hasKey"):
		LorePickup.hide_owned(_key_interact_area, _key_visual)
		_stop_key_glow()
		return
	if is_instance_valid(_key_visual):
		_key_visual.visible = true
		_start_key_glow()


func _start_key_glow() -> void:
	_stop_key_glow()
	if not is_instance_valid(_key_visual) or not _key_visual.visible:
		return
	var glow := _key_visual.get_node_or_null("Glow") as CanvasItem
	if glow == null:
		return
	_key_glow_tween = create_tween()
	_key_glow_tween.set_loops()
	_key_glow_tween.tween_property(glow, "modulate:a", 0.22, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_key_glow_tween.tween_property(glow, "modulate:a", 0.08, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _stop_key_glow() -> void:
	if _key_glow_tween != null and _key_glow_tween.is_valid():
		_key_glow_tween.kill()
	_key_glow_tween = null


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if not GameManager.teachers_lounge_enter_line_seen:
		GameManager.set_teachers_lounge_enter_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(ENTER_LINES)
		await _try_play_pending_key_near()
		return
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.teachers_liar_line_seen:
		GameManager.set_teachers_liar_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(LIAR_LINES)
		await _try_play_pending_key_near()
		return
	_enter_dialogue_pending = false


func _process(delta: float) -> void:
	super._process(delta)
	_check_key_near()


func _check_key_near() -> void:
	if GameManager.teachers_key_line_seen or _line_running or _is_transitioning:
		return
	if not InteractZoneGate.body_in_area(_key_near_area, _player):
		_key_near_pending = false
		return
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
		_key_near_pending = true
		return
	_line_running = true
	call_deferred("_play_key_near")


func _try_play_pending_key_near() -> void:
	if not _key_near_pending:
		return
	if not InteractZoneGate.body_in_area(_key_near_area, _player):
		_key_near_pending = false
		return
	if GameManager.teachers_key_line_seen or _line_running:
		_key_near_pending = false
		return
	_line_running = true
	await _play_key_near()


func _play_key_near() -> void:
	if GameManager.teachers_key_line_seen:
		_line_running = false
		return
	if not is_instance_valid(_top_dialogue):
		_line_running = false
		return
	_key_near_pending = false
	_line_running = true
	GameManager.set_teachers_key_line_seen(true)
	await _top_dialogue.show_lines(KEY_NEAR_LINES)
	_line_running = false


func _pickup_key() -> void:
	if LorePickup.is_owned("hasKey"):
		_line_running = false
		return
	_line_running = true
	hide_interact_prompt_immediate()
	await LorePickup.take(
		self,
		"hasKey",
		"Teacher Key",
		_top_dialogue,
		KEY_PICKUP_LINES,
		LOUNGE_SELF_SCENE,
		_apply_key_visibility,
	)
	_line_running = false
	if _active_zone == "key":
		_active_zone = ""


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	call_deferred("_configure_behind_occlusion_masks")
	if GameManager.has_teachers_lounge_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_door_peek_if_pending()


func _apply_memory_return_if_pending() -> void:
	restore_player_tex(
		"has_teachers_lounge_memory_return_pos",
		"take_teachers_lounge_memory_return_pos",
	)


func _apply_door_peek_if_pending() -> void:
	if not _pending_door_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_door_peek = false
	InteractArrival.apply_arrival_inside(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.BOTTOM,
		0.5
	)
	latch_zone("door")
	arm_zone_grace("door")


func _configure_behind_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	var cutoffs: Array[float] = []
	for zone_name in _BEHIND_ZONE_NAMES:
		var zone := get_node_or_null(
			"WalkableWorld/EnvironmentColliders/%s" % zone_name
		) as Area2D
		var poly := PackedVector2Array()
		var feather := 0.0
		if is_instance_valid(zone) and zone.has_method("get_shader_polygon"):
			poly = zone.call("get_shader_polygon")
			feather = float(zone.get("feather_px"))
		polys.append(poly)
		feathers.append(feather)
		cutoffs.append(_occlusion_y_cutoff(zone))
	while polys.size() < 3:
		polys.append(PackedVector2Array())
		feathers.append(0.0)
		cutoffs.append(1e9)
	_player.call(
		"configure_leaf_occlusion_polygons",
		polys[0],
		polys[1],
		feathers[0],
		feathers[1],
		_LEAF_FADE_ALPHA,
		cutoffs[0],
		cutoffs[1],
		_LEAF_GATE_SOFTNESS,
		polys[2],
		feathers[2],
		cutoffs[2],
	)


func _occlusion_y_cutoff(behind: Area2D) -> float:
	if not is_instance_valid(behind):
		return 1e9
	var polygon_node := behind.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return 1e9
	var max_y := -INF
	for local_point in polygon_node.polygon:
		max_y = maxf(max_y, polygon_node.to_global(local_point).y)
	if max_y == -INF:
		return 1e9
	return max_y
