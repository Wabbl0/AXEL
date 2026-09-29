extends ExplorationRoom

const ENTER_LINE := "Even through all the chaos you can hear the chattering students of the past."
const TABLE_SCENE := "res://scenes/Arc_2/2.2_CafeteriaMemory.tscn"
const TABLE_MEMORY_KEY := "cafeteria_memory"
const KITCHEN_SCENE := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const BASEMENT_DOOR_SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const BACKYARD_SCENE := "res://scenes/Arc_3/3.1_Backyard.tscn"
const CLASSROOMS_CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const BASEMENT_PEEK_MARGIN_PX := 12.0
const KITCHEN_STAND_TEX_Y := 90.0
const HINT_WAIT_SEC := 30.0
const HINT_SCREEN_SCALE := 1.67
const HINT_GAP_PX := 8.0
const HINT_TIP_PX := 16.0

var _table_area: Area2D
var _kitchen_area: Area2D
var _return_area: Area2D
var _backyard_area: Area2D
var _classrooms_area: Area2D
var _pending_basement_peek := false
var _pending_kitchen_peek := false
var _pending_backyard_peek := false
var _pending_classrooms_peek := false
var _pending_table_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _direction_hint: Node2D
var _hint_elapsed := 0.0
var _hint_hidden_this_visit := false


func _ready() -> void:
	_direction_hint = get_node_or_null("PlayerLayer/DirectionHint") as Node2D
	if is_instance_valid(_direction_hint):
		_direction_hint.visible = false
	bind_player_cover()
	_table_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/TableInteractArea"
	) as Area2D
	_kitchen_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KitchenInteractArea"
	) as Area2D
	_return_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ReturnInteractArea"
	) as Area2D
	_backyard_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/BackyardInteractArea"
	) as Area2D
	_classrooms_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ClassroomsInteractArea"
	) as Area2D
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.cafeteria_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func _process(delta: float) -> void:
	super._process(delta)
	_update_direction_hint(delta)


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["table", "kitchen", "return", "backyard", "classrooms"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"table":
			return _table_area
		"kitchen":
			return _kitchen_area
		"return":
			return _return_area
		"backyard":
			return _backyard_area
		"classrooms":
			return _classrooms_area
		_:
			return null


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"table":
			save_player_tex("set_cafeteria_table_return_pos")
			begin_scene_change(TABLE_SCENE)
		"kitchen":
			leave_through(
				_kitchen_area,
				Vector2.AXIS_X,
				"set_kitchen_spawn_side",
				"cafeteria_door",
				KITCHEN_SCENE,
			)
		"return":
			leave_through(
				_return_area,
				Vector2.AXIS_Y,
				"set_basement_spawn_side",
				"cafeteria_right",
				BASEMENT_DOOR_SCENE,
			)
		"backyard":
			leave_through(
				_backyard_area,
				Vector2.AXIS_Y,
				"set_backyard_spawn_side",
				"cafeteria_door",
				BACKYARD_SCENE,
			)
		"classrooms":
			leave_through(
				_classrooms_area,
				Vector2.AXIS_X,
				"set_classrooms_corridor_spawn_side",
				"cafeteria_door",
				CLASSROOMS_CORRIDOR_SCENE,
				false,
			)


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	var cafeteria_side := GameManager.take_cafeteria_spawn_side()
	if cafeteria_side == "basement_left":
		_pending_basement_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_basement_peek_after_wake")
		return
	if cafeteria_side == "backyard_right":
		_pending_backyard_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_inside_arrival_after_wake")
		return
	if cafeteria_side == "classrooms_bottom":
		_pending_classrooms_peek = true
		InteractArrival.take_arrival_t_or_default()
		_arrival_t = InteractArrival.DEFAULT_T
		if _cover_layout_ready:
			call_deferred("_apply_inside_arrival_after_wake")
		return
	if cafeteria_side == "table":
		_pending_table_peek = true
		call_deferred("_apply_table_peek_if_pending")
		return
	if GameManager.take_kitchen_spawn_side() == "kitchen_door":
		_pending_kitchen_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_kitchen_peek_after_wake")
		return
	if GameManager.has_cafeteria_table_return_pos():
		call_deferred("_apply_table_return_if_pending")


func _play_enter_dialogue() -> void:
	await play_enter_once("cafeteria_enter_line_seen", ENTER_LINE)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	call_deferred("_configure_table_occlusion_masks")
	if GameManager.has_cafeteria_table_return_pos():
		call_deferred("_apply_table_return_if_pending")
	elif _pending_basement_peek:
		call_deferred("_apply_basement_peek_after_wake")
	elif _pending_kitchen_peek:
		call_deferred("_apply_kitchen_peek_after_wake")
	elif _pending_backyard_peek or _pending_classrooms_peek:
		call_deferred("_apply_inside_arrival_after_wake")
	elif _pending_table_peek:
		call_deferred("_apply_table_peek_if_pending")
	_sync_direction_hint()


func _apply_inside_arrival_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	if _pending_backyard_peek:
		_apply_backyard_peek_if_pending()
	elif _pending_classrooms_peek:
		_apply_classrooms_peek_if_pending()


func _apply_basement_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_basement_peek_if_pending()


func _apply_kitchen_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_kitchen_peek_if_pending()


func _apply_table_return_if_pending() -> void:
	restore_player_tex("has_cafeteria_table_return_pos", "take_cafeteria_table_return_pos")


func _apply_basement_peek_if_pending() -> void:
	if not _pending_basement_peek or not is_instance_valid(_player):
		return
	_pending_basement_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_return_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		BASEMENT_PEEK_MARGIN_PX
	)
	latch_zone("return")
	call_deferred("_clamp_arrived_player")
	arm_zone_grace("return")


func _apply_kitchen_peek_if_pending() -> void:
	if not _pending_kitchen_peek or not is_instance_valid(_player):
		return
	_pending_kitchen_peek = false
	var feet_landed := InteractArrival.place_on_area(
		_player,
		_kitchen_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.CENTER_Y,
		0.0
	)
	var front := _player.get_node_or_null("CollisionFront") as CollisionShape2D
	if front != null:
		var offset := _player.to_global(front.position) - _player.global_position
		_player.global_position = feet_landed + offset
	else:
		_player.global_position = feet_landed
	var env := env_colliders()
	var tex := env.to_local(_player.global_position)
	tex.y = KITCHEN_STAND_TEX_Y
	_player.global_position = env.to_global(tex)
	latch_zone("kitchen")
	arm_zone_grace("kitchen")


func _apply_backyard_peek_if_pending() -> void:
	if not _pending_backyard_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_backyard_peek = false
	InteractArrival.apply_arrival_inside(
		_player,
		_backyard_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.LEFT,
		0.5
	)
	latch_zone("backyard")
	arm_zone_grace("backyard")


func _apply_classrooms_peek_if_pending() -> void:
	if not _pending_classrooms_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_classrooms_peek = false
	_player.global_position = InteractArrival.place_in_area(
		_player,
		_classrooms_area,
		InteractArrival.DEFAULT_T,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.CENTER_Y,
		0.5
	)
	latch_zone("classrooms")
	arm_zone_grace("classrooms")


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


func _apply_table_peek_if_pending() -> void:
	if not _pending_table_peek or not is_instance_valid(_player):
		return
	_pending_table_peek = false
	_player.global_position = _table_peek_global()
	arm_zone_grace("table")


func _table_peek_global() -> Vector2:
	if not is_instance_valid(_table_area):
		return _player.global_position
	var shape := _table_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		return shape.global_position
	return _table_area.global_position


func _configure_table_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var zones: Array[Area2D] = []
	for zone_name in [
		"TableBlockLeft_Behind",
		"ChairBlockBottom_Behind",
		"ChairBlockTop_Behind",
	]:
		var zone := get_node_or_null(
			"WalkableWorld/EnvironmentColliders/%s" % zone_name
		) as Area2D
		zones.append(zone)
	while zones.size() < 3:
		zones.append(null)
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	var cutoffs: Array[float] = []
	for zone in zones:
		var poly := PackedVector2Array()
		var feather := 0.0
		if is_instance_valid(zone) and zone.has_method("get_shader_polygon"):
			poly = zone.call("get_shader_polygon")
			feather = float(zone.get("feather_px"))
		polys.append(poly)
		feathers.append(feather)
		cutoffs.append(_occlusion_y_cutoff(zone))
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


func _update_direction_hint(delta: float) -> void:
	if not is_instance_valid(_direction_hint):
		return
	if _hint_should_stay_off():
		_direction_hint.visible = false
		return
	var dialogue_holds := _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue)
	var pause_holds := get_tree() != null and get_tree().paused
	if not dialogue_holds and not pause_holds:
		_hint_elapsed += delta
	var hint_on := _cover_layout_ready and (
		_hint_elapsed >= HINT_WAIT_SEC or _both_side_rooms_visited()
	)
	_direction_hint.visible = hint_on
	if not hint_on:
		return
	_sync_direction_hint()
	if _direction_hint.has_method("overlaps_player") and bool(_direction_hint.call("overlaps_player", _player)):
		_hint_hidden_this_visit = true
		GameManager.set_cafeteria_down_hint_done(true)
		_direction_hint.visible = false


func _sync_direction_hint() -> void:
	if not is_instance_valid(_direction_hint) or not is_instance_valid(_classrooms_area):
		return
	_direction_hint.scale = Vector2(HINT_SCREEN_SCALE, HINT_SCREEN_SCALE)
	_direction_hint.rotation = PI * 0.5
	var top := _classrooms_top_center()
	var lift := HINT_TIP_PX * HINT_SCREEN_SCALE + HINT_GAP_PX
	_direction_hint.global_position = Vector2(top.x, top.y - lift)


func _classrooms_top_center() -> Vector2:
	var shape := _classrooms_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		return _classrooms_area.global_position
	var center := shape.global_position
	var rect := shape.shape as RectangleShape2D
	if rect == null:
		return center
	var half_h := rect.size.y * 0.5 * absf(shape.global_transform.get_scale().y)
	return Vector2(center.x, center.y - half_h)


func _both_side_rooms_visited() -> bool:
	return (
		GameManager.has_visited(KITCHEN_SCENE)
		and GameManager.has_visited(BACKYARD_SCENE)
	)


func _hint_should_stay_off() -> bool:
	if _hint_hidden_this_visit or _is_transitioning:
		return true
	if GameManager.cafeteria_down_hint_done:
		return true
	if GameManager.has_visited(CLASSROOMS_CORRIDOR_SCENE):
		return true
	return false
