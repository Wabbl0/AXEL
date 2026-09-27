extends ExplorationRoom

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const DOOR_LINE := "Not yet."
const CAFETERIA_PEEK_MARGIN_PX := 12.0
const CORRIDOR_PEEK_MARGIN_PX := 12.0
const EXIT_TRIGGER_GRACE_SEC := 0.15
# 3508×2480 plate. Room baseline stays 0.352. Mike matches 1.2: scale 0.198, speed 185.3.
const _OLD_BG_SCALE := Vector2(0.352, 0.352)

var _door_interact_area: Area2D
var _cafeteria_interact_area: Area2D
var _exit_trigger: Area2D
var _pending_cafeteria_peek := false
var _pending_corridor_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _exit_trigger_armed := true


func _ready() -> void:
	_player_cover_sync.authored_bg_baseline = _OLD_BG_SCALE.x
	bind_player_cover()
	GameManager.set_corridor_right_hint_done(true)
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_cafeteria_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/CafeteriaInteractArea"
	) as Area2D
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_body_entered)
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["cafeteria", "door"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"cafeteria":
			return _cafeteria_interact_area
		"door":
			return _door_interact_area
		_:
			return null


func extra_blocks_interact() -> bool:
	return _line_running


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"cafeteria":
			leave_through(
				_cafeteria_interact_area,
				Vector2.AXIS_Y,
				"set_cafeteria_spawn_side",
				"basement_left",
				CAFETERIA_SCENE,
			)
		"door":
			_play_door_line()


func _play_door_line() -> void:
	if extra_blocks_interact() or InteractZoneGate.dialogue_busy(_top_dialogue):
		return
	_play_door_line_async()


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.has_pause_map_return_for(scene_file_path):
		return
	var basement_side := GameManager.take_basement_spawn_side()
	if basement_side == "cafeteria_right":
		_pending_cafeteria_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_cafeteria_peek_after_wake")
		return
	if basement_side == "corridor_left":
		_pending_corridor_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_corridor_peek_after_wake")


func _play_door_line_async() -> void:
	_line_running = true
	await _top_dialogue.show_line(DOOR_LINE, 3.0)
	_line_running = false
	GameManager.set_basement_door_line_seen(true)
	show_interact_prompt()


func _on_exit_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning or not _exit_trigger_armed:
		return
	call_deferred("_begin_corridor_return")


func _begin_corridor_return() -> void:
	if is_instance_valid(_player) and is_instance_valid(_exit_trigger):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _exit_trigger, Vector2.AXIS_Y)
		)
	GameManager.set_corridor_spawn_side("basement_right")
	begin_scene_change(CORRIDOR_SCENE)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_after_wake")
	elif _pending_corridor_peek:
		call_deferred("_apply_corridor_peek_after_wake")


func _apply_cafeteria_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_cafeteria_peek_if_pending()


func _apply_corridor_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_corridor_peek_if_pending()


func _apply_cafeteria_peek_if_pending() -> void:
	if not _pending_cafeteria_peek or not is_instance_valid(_player):
		return
	_pending_cafeteria_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_cafeteria_interact_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.LEFT,
		-CAFETERIA_PEEK_MARGIN_PX
	)
	latch_zone("cafeteria")
	call_deferred("_clamp_arrived_player")
	arm_zone_grace("cafeteria")


func _apply_corridor_peek_if_pending() -> void:
	if not _pending_corridor_peek or not is_instance_valid(_player):
		return
	_pending_corridor_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_exit_trigger,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		CORRIDOR_PEEK_MARGIN_PX
	)
	call_deferred("_clamp_arrived_player")
	_arm_exit_trigger_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	var tree := get_tree()
	if tree == null:
		_exit_trigger_armed = true
		return
	await tree.create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true
