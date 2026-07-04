extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

const LOCKER_HUB_SCENE := "res://scenes/Arc_2/2.1_LockerHub.tscn"
const LOCKER_LINE := "This was your locker."

var _locker_interact_area: Area2D
var _spawn_line_active := false
var _is_transitioning := false
var _locker_zone_active := false
var _locker_line_running := false
var _locker_enter_token := 0


func _ready() -> void:
	_locker_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/LockerInteractArea"
	) as Area2D
	if is_instance_valid(_locker_interact_area):
		_locker_interact_area.body_entered.connect(_on_locker_body_entered)
		_locker_interact_area.body_exited.connect(_on_locker_body_exited)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	_show_spawn_line()


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if not GameManager.has_corridor_return_pos():
		return
	_player.global_position = GameManager.take_corridor_return_pos()
	call_deferred("_refresh_locker_zone_state")


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
	if event.is_action_pressed(&"interact"):
		return true
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return false
		if TouchControls.is_point_in_stick_zone(touch_event.position):
			return false
		if is_instance_valid(_interact_prompt) and _interact_prompt.is_point_on_chip(touch_event.position):
			return true
		return TouchInteract.touch_hits_area(get_viewport(), touch_event.position, _locker_interact_area)
	return false


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
	_is_transitioning = true
	GameManager.set_corridor_return_pos(_player.global_position)
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	var err := get_tree().change_scene_to_file(LOCKER_HUB_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [LOCKER_HUB_SCENE, err])
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


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
