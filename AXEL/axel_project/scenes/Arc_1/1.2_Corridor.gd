extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const BASEMENT_DOOR_SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const LOCKER_LINE := "This was your locker."
## Just left of ExitTrigger so only a sliver of the scale-3 player peeks on the right.
const BASEMENT_PEEK_MARGIN_PX := 12.0
const EXIT_TRIGGER_GRACE_SEC := 0.15

var _locker_interact_area: Area2D
var _exit_trigger: Area2D
var _spawn_line_active := false
var _is_transitioning := false
var _locker_zone_active := false
var _locker_line_running := false
var _locker_enter_token := 0
var _pending_basement_peek := false
var _exit_trigger_armed := true


func _ready() -> void:
	_locker_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/LockerInteractArea"
	) as Area2D
	if is_instance_valid(_locker_interact_area):
		_locker_interact_area.body_entered.connect(_on_locker_body_entered)
		_locker_interact_area.body_exited.connect(_on_locker_body_exited)
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	_show_spawn_line()


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_corridor_spawn_side() == "basement_right":
		_pending_basement_peek = true
		# Discard any stale saved return pos; peek wins.
		if GameManager.has_corridor_return_pos():
			GameManager.take_corridor_return_pos()
		call_deferred("_apply_basement_peek_if_pending")
		return
	if not GameManager.has_corridor_return_pos():
		return
	_player.global_position = GameManager.take_corridor_return_pos()
	call_deferred("_refresh_locker_zone_state")


func _apply_basement_peek_if_pending() -> void:
	if not _pending_basement_peek or not is_instance_valid(_player):
		return
	_pending_basement_peek = false
	_player.global_position = _basement_right_peek_global()
	_arm_exit_trigger_grace()


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	await get_tree().create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true


func _basement_right_peek_global() -> Vector2:
	var pos := _player.global_position
	var left_edge := _exit_trigger_left_edge_x()
	if left_edge > -INF:
		pos.x = left_edge - BASEMENT_PEEK_MARGIN_PX
	if is_instance_valid(_exit_trigger):
		pos.y = _exit_trigger.global_position.y
	return pos


func _refresh_locker_zone_state() -> void:
	if not _is_player_near_locker():
		return
	_locker_zone_active = true
	_handle_locker_zone_entered()


func _show_spawn_line() -> void:
	if GameManager.corridor_spawn_line_seen:
		return
	_spawn_line_active = true
	await _top_dialogue.show_line("Even after all these years the smell is the same.", 3.5)
	_spawn_line_active = false
	if not GameManager.corridor_spawn_line_seen:
		GameManager.set_corridor_spawn_line_seen(true)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if not _is_player_near_locker():
		return
	_begin_locker_transition()


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _is_player_near_locker() -> bool:
	if not is_instance_valid(_locker_interact_area) or not is_instance_valid(_player):
		return false
	for body in _locker_interact_area.get_overlapping_bodies():
		if body == _player:
			return true
	return false


func _locker_interact_anchor() -> Vector2:
	if not is_instance_valid(_locker_interact_area):
		return Vector2.ZERO
	var poly := _locker_interact_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return _locker_interact_area.global_position
	return _polygon_global_centroid(poly)


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


func _handle_locker_zone_entered() -> void:
	_locker_enter_token += 1
	_try_show_locker_interact_prompt()
	if not GameManager.corridor_locker_line_seen and not _locker_line_running:
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
				_locker_line_running = false
				return
			await _top_dialogue.await_line_advance()
			if token == _locker_enter_token and _locker_zone_active:
				await _top_dialogue.hide_line()
	else:
		if _spawn_line_active and _top_dialogue.has_method("cancel_pending_line"):
			_top_dialogue.cancel_pending_line()
			GameManager.set_corridor_spawn_line_seen(true)
			_spawn_line_active = false
		await _top_dialogue.show_line(LOCKER_LINE, 3.0)
	_locker_line_running = false
	if token != _locker_enter_token or not _locker_zone_active:
		return
	GameManager.set_corridor_locker_line_seen(true)


func _try_show_locker_interact_prompt() -> void:
	if _is_transitioning or not _locker_zone_active:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(_locker_interact_anchor())


func _hide_locker_interact_prompt() -> void:
	if _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func _begin_locker_transition() -> void:
	if not is_instance_valid(_player):
		return
	_begin_scene_transition(LOCKER_HUB_SCENE, _player.global_position)


func _on_exit_trigger_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning or not _exit_trigger_armed:
		return
	call_deferred("_begin_basement_transition")


func _begin_basement_transition() -> void:
	if not is_instance_valid(_player):
		return
	_begin_scene_transition(BASEMENT_DOOR_SCENE, _safe_basement_return_pos())


func _safe_basement_return_pos() -> Vector2:
	return _basement_right_peek_global()


func _exit_trigger_left_edge_x() -> float:
	if not is_instance_valid(_exit_trigger):
		return -INF
	var shape := _exit_trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return -INF
	var half_width: float = (shape.shape as RectangleShape2D).size.x * 0.5
	return _exit_trigger.to_global(Vector2(shape.position.x - half_width, shape.position.y)).x


func _begin_scene_transition(scene_path: String, return_pos: Vector2) -> void:
	if not is_instance_valid(_player):
		return
	_is_transitioning = true
	GameManager.set_corridor_return_pos(return_pos)
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _on_background_layout_applied(
	scale_factor: float, bg_position: Vector2, _world_rect: Rect2
) -> void:
	_sync_environment_colliders(scale_factor, bg_position)


func _sync_environment_colliders(cover_scale: float, bg_position: Vector2) -> void:
	var env := $WalkableWorld/EnvironmentColliders
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	call_deferred("_wake_static_colliders")
	if _pending_basement_peek:
		call_deferred("_apply_basement_peek_if_pending")


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
