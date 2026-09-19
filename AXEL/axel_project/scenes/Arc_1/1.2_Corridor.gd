extends ExplorationRoom

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const BASEMENT_DOOR_SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const EXTERIOR_SCENE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const HINT_WAIT_SEC := 10.0
const HINT_SCREEN_SCALE := 1.67
const HINT_RIGHT_INSET_PX := 48.0
const HINT_Y_FRAC := 0.64
const LOCKER_LINE := "This was your locker."
const BASEMENT_PEEK_MARGIN_PX := 12.0
const EXIT_TRIGGER_GRACE_SEC := 0.15
const _OLD_BG_SCALE := Vector2(0.546, 0.546)

var _locker_interact_area: Area2D
var _exterior_interact_area: Area2D
var _exit_trigger: Area2D
var _spawn_line_active := false
var _locker_zone_active := false
var _exterior_zone_active := false
var _exterior_zone_armed := true
var _arrival_latched_exterior := false
var _locker_line_running := false
var _locker_enter_token := 0
var _pending_basement_peek := false
var _pending_exterior_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _exit_trigger_armed := true
var _direction_hint: Node2D
var _direction_hint_tex := Vector2.ZERO
var _hint_elapsed := 0.0
var _hint_hidden_this_visit := false
var _arrival_spawn_side := ""


func _ready() -> void:
	_use_default_interact_loop = false
	_player_cover_sync.authored_bg_baseline = _OLD_BG_SCALE.x
	_direction_hint = get_node_or_null("PlayerLayer/DirectionHint") as Node2D
	if is_instance_valid(_direction_hint):
		_direction_hint_tex = _direction_hint.position
		_direction_hint.visible = false
	bind_player_cover(null, null)
	_locker_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/LockerInteractArea"
	) as Area2D
	if is_instance_valid(_locker_interact_area):
		_locker_interact_area.body_entered.connect(_on_locker_body_entered)
		_locker_interact_area.body_exited.connect(_on_locker_body_exited)
	_exterior_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExteriorInteractArea"
	) as Area2D
	if is_instance_valid(_exterior_interact_area):
		_exterior_interact_area.body_entered.connect(_on_exterior_body_entered)
		_exterior_interact_area.body_exited.connect(_on_exterior_body_exited)
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	set_process(true)
	set_process_unhandled_input(true)
	_latch_corridor_arrival()
	call_deferred("_restore_player_position_if_needed")
	_arm_exterior_zone_grace()
	if not GameManager.corridor_spawn_line_seen:
		_enter_dialogue_pending = true
	_show_spawn_line()


func _process(delta: float) -> void:
	if _arrival_latched_exterior and InteractZoneGate.movement_pressed():
		_arrival_latched_exterior = false
	_refresh_interact_zones()
	_update_direction_hint(delta)


func _refresh_interact_zones() -> void:
	if _is_transitioning:
		return
	_locker_zone_active = _is_player_near_locker()
	if _arrival_latched_exterior:
		_exterior_zone_active = true
	else:
		_exterior_zone_active = _is_player_near_exterior()
	if _exterior_zone_active:
		_try_show_exterior_interact_prompt()
	elif _locker_zone_active:
		_try_show_locker_interact_prompt()
	elif is_instance_valid(_interact_prompt):
		_interact_prompt.hide_prompt()


func _locker_dialogue_busy() -> bool:
	if _locker_line_running:
		return true
	return InteractZoneGate.dialogue_busy(_top_dialogue)


func _latch_corridor_arrival() -> void:
	var spawn_side := GameManager.take_corridor_spawn_side()
	_arrival_spawn_side = spawn_side
	if spawn_side == "basement_right":
		_pending_basement_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if GameManager.has_corridor_return_pos():
			GameManager.take_corridor_return_pos()
		return
	if spawn_side == "exterior_door":
		_pending_exterior_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if GameManager.has_corridor_return_pos():
			GameManager.take_corridor_return_pos()


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.has_pause_map_return_for(scene_file_path):
		return
	if _pending_basement_peek:
		call_deferred("_apply_basement_peek_if_pending")
		return
	if _pending_exterior_peek:

		if _cover_layout_ready:
			call_deferred("_apply_exterior_peek_after_wake")
		return
	if not GameManager.has_corridor_return_pos():
		return
	_player.global_position = GameManager.take_corridor_return_pos()
	call_deferred("_refresh_locker_zone_state")


func _apply_basement_peek_if_pending() -> void:
	if not _pending_basement_peek or not is_instance_valid(_player):
		return
	_pending_basement_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_exit_trigger,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.LEFT,
		-BASEMENT_PEEK_MARGIN_PX
	)
	call_deferred("_clamp_arrived_player")
	_arm_exit_trigger_grace()


func _apply_exterior_peek_after_wake() -> void:
	wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_exterior_peek_if_pending()


func _apply_exterior_peek_if_pending() -> void:
	if not _pending_exterior_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_exterior_peek = false


	InteractArrival.apply_arrival_inside(
		_player,
		_exterior_interact_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		0.5
	)
	_arrival_latched_exterior = true
	_arm_exterior_zone_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	await get_tree().create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true


func _refresh_locker_zone_state() -> void:
	if not _is_player_near_locker():
		return
	_locker_zone_active = true
	_handle_locker_zone_entered()


func _show_spawn_line() -> void:
	if GameManager.corridor_spawn_line_seen:
		_enter_dialogue_pending = false
		return
	_spawn_line_active = true
	_enter_dialogue_pending = false
	await _top_dialogue.show_line(
		"Even after all these years the smell is the same.|beat:1.5| They must've used some really toxic paint.",
		3.5
	)
	_spawn_line_active = false
	if not GameManager.corridor_spawn_line_seen:
		GameManager.set_corridor_spawn_line_seen(true)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return

	if _enter_dialogue_pending or _locker_dialogue_busy():
		return
	_refresh_interact_zones()
	if _is_player_near_exterior() and _exterior_zone_armed:
		_begin_exterior_transition()
		return
	if not _is_player_near_locker():
		return
	_begin_locker_transition()


func _is_interaction_event(event: InputEvent) -> bool:

	return event.is_action_pressed("interact")


func _is_player_near_locker() -> bool:
	return InteractZoneGate.body_in_area(_locker_interact_area, _player)


func _is_player_near_exterior() -> bool:
	if _arrival_latched_exterior:
		return true
	return InteractZoneGate.body_in_area(_exterior_interact_area, _player)


func _locker_interact_anchor() -> Vector2:
	if not is_instance_valid(_locker_interact_area):
		return Vector2.ZERO
	var poly := _locker_interact_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return _locker_interact_area.global_position
	return _polygon_global_centroid(poly)


func _exterior_interact_anchor() -> Vector2:
	if not is_instance_valid(_exterior_interact_area):
		return Vector2.ZERO
	var shape := _exterior_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return _exterior_interact_area.global_position


func _polygon_global_centroid(poly: CollisionPolygon2D) -> Vector2:
	if poly.polygon.is_empty():
		return poly.global_position
	var sum := Vector2.ZERO
	for local_point in poly.polygon:
		sum += poly.to_global(local_point)
	return sum / float(poly.polygon.size())


func _on_locker_body_entered(body: Node) -> void:
	if body != _player:
		return
	_locker_zone_active = true
	_handle_locker_zone_entered()


func _on_locker_body_exited(body: Node) -> void:
	if body != _player:
		return
	_locker_zone_active = false
	_locker_enter_token += 1
	if _is_transitioning:
		return
	_hide_locker_interact_prompt()


func _on_exterior_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning:
		return
	_exterior_zone_active = true
	_try_show_exterior_interact_prompt()


func _on_exterior_body_exited(body: Node) -> void:
	if body != _player:
		return
	_exterior_zone_active = false
	if _is_transitioning:
		return
	_hide_exterior_interact_prompt()


func _handle_locker_zone_entered() -> void:
	_locker_enter_token += 1
	_try_show_locker_interact_prompt()
	if not GameManager.corridor_locker_line_seen and not _locker_line_running:

		GameManager.set_corridor_locker_line_seen(true)
		_play_locker_line_async(_locker_enter_token)


func _play_locker_line_async(token: int) -> void:
	_locker_line_running = true
	if _top_dialogue.has_method("is_bar_visible") and _top_dialogue.is_bar_visible():
		if _top_dialogue.has_method("cancel_pending_line"):
			_top_dialogue.cancel_pending_line()
		if _spawn_line_active:
			GameManager.set_corridor_spawn_line_seen(true)
			_spawn_line_active = false
		if _top_dialogue.has_method("type_line"):
			await _top_dialogue.type_line(LOCKER_LINE)
			if token != _locker_enter_token or not _locker_zone_active:
				_close_locker_line_bar()
				_locker_line_running = false
				return
			await _top_dialogue.await_line_advance()
			if token != _locker_enter_token or not _locker_zone_active:
				_close_locker_line_bar()
				_locker_line_running = false
				return
			await _top_dialogue.hide_line()
	else:
		if _spawn_line_active and _top_dialogue.has_method("cancel_pending_line"):
			_top_dialogue.cancel_pending_line()
			GameManager.set_corridor_spawn_line_seen(true)
			_spawn_line_active = false
		await _top_dialogue.show_line(LOCKER_LINE, 3.0)
	_locker_line_running = false


func _close_locker_line_bar() -> void:
	if not is_instance_valid(_top_dialogue):
		return
	if _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()


func _try_show_locker_interact_prompt() -> void:
	if _is_transitioning or not _locker_zone_active:
		return
	if _exterior_zone_active:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(_locker_interact_anchor())


func _hide_locker_interact_prompt() -> void:
	if _is_transitioning:
		return
	if _exterior_zone_active:
		_try_show_exterior_interact_prompt()
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func _try_show_exterior_interact_prompt() -> void:
	if _is_transitioning or not _exterior_zone_active:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(_exterior_interact_anchor())


func _hide_exterior_interact_prompt() -> void:
	if _is_transitioning:
		return
	if _locker_zone_active:
		_try_show_locker_interact_prompt()
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func _arm_exterior_zone_grace() -> void:
	_exterior_zone_armed = false
	await get_tree().create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exterior_zone_armed = true


func _begin_locker_transition() -> void:
	if not is_instance_valid(_player):
		return
	_begin_scene_transition(LOCKER_HUB_SCENE, _player.global_position)


func _begin_exterior_transition() -> void:
	if is_instance_valid(_player) and is_instance_valid(_exterior_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _exterior_interact_area, Vector2.AXIS_Y
			)
		)
	GameManager.set_exterior_spawn_side("corridor_door")
	begin_scene_change(EXTERIOR_SCENE)


func _on_exit_trigger_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning or not _exit_trigger_armed:
		return
	_hint_hidden_this_visit = true
	if is_instance_valid(_direction_hint):
		_direction_hint.visible = false
	call_deferred("_begin_basement_transition")


func _begin_basement_transition() -> void:
	if not is_instance_valid(_player):
		return
	if is_instance_valid(_exit_trigger):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _exit_trigger, Vector2.AXIS_Y)
		)
	GameManager.set_basement_spawn_side("corridor_left")
	_begin_scene_transition(BASEMENT_DOOR_SCENE, _player.global_position)


func _begin_scene_transition(scene_path: String, return_pos: Vector2) -> void:
	if not is_instance_valid(_player):
		return
	GameManager.set_corridor_return_pos(return_pos)
	begin_scene_change(scene_path)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	_sync_direction_hint()
	call_deferred("wake_static_colliders")
	if _pending_basement_peek:
		call_deferred("_apply_basement_peek_if_pending")
	elif _pending_exterior_peek:
		call_deferred("_apply_exterior_peek_after_wake")


func _sync_direction_hint() -> void:
	if not is_instance_valid(_direction_hint):
		return
	var vp := get_viewport()
	if vp == null:
		return
	var rect := vp.get_visible_rect()
	_direction_hint.scale = Vector2(HINT_SCREEN_SCALE, HINT_SCREEN_SCALE)
	var half_w := HINT_RIGHT_INSET_PX
	var sprite := _direction_hint.get_node_or_null("Sprite") as Sprite2D
	if sprite != null and sprite.texture != null:
		half_w = sprite.texture.get_width() * HINT_SCREEN_SCALE * 0.5
	var screen := Vector2(rect.size.x - half_w - 8.0, rect.size.y * HINT_Y_FRAC)
	var canvas := _direction_hint.get_canvas_transform()
	_direction_hint.global_position = canvas.affine_inverse() * screen


func _update_direction_hint(delta: float) -> void:
	if not is_instance_valid(_direction_hint):
		return
	if _hint_should_stay_off():
		_direction_hint.visible = false
		return
	if Input.is_action_pressed("move_right"):
		_hint_hidden_this_visit = true
		_direction_hint.visible = false
		return
	var dialogue_holds := _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue)
	var pause_holds := get_tree() != null and get_tree().paused
	if not dialogue_holds and not pause_holds:
		_hint_elapsed += delta
	_direction_hint.visible = bool(GameManager.corridor_from_locker) or _hint_elapsed >= HINT_WAIT_SEC
	if _direction_hint.visible:
		_sync_direction_hint()


func _hint_should_stay_off() -> bool:
	if _hint_hidden_this_visit or _is_transitioning:
		return true
	if GameManager.corridor_right_hint_done:
		return true
	if GameManager.has_visited(BASEMENT_DOOR_SCENE):
		return true
	if _arrival_spawn_side == "basement_right":
		return true
	return false
