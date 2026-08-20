extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const DOOR_LINE := "Not yet."
## Just left of CafeteriaInteractArea so only a sliver peeks on the right.
const CAFETERIA_PEEK_MARGIN_PX := 12.0
const CAFETERIA_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _door_interact_area: Area2D
var _cafeteria_interact_area: Area2D
var _exit_trigger: Area2D
var _door_zone_active := false
var _cafeteria_zone_active := false
var _cafeteria_zone_armed := true
var _is_transitioning := false
var _door_line_running := false
var _player_spawn_applied := false
var _pending_cafeteria_peek := false
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	_player_cover_sync.bind_from_player(_player)
	var _bg := $WalkableWorld/Background as Sprite2D
	var _cam := $Camera2D
	_player_cover_sync.bind_design_from_background(
		_bg, _cam.fit_mode, _cam.background_y
	)
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_cafeteria_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/CafeteriaInteractArea"
	) as Area2D
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_door_interact_area):
		_door_interact_area.body_entered.connect(_on_door_body_entered)
		_door_interact_area.body_exited.connect(_on_door_body_exited)
	if is_instance_valid(_cafeteria_interact_area):
		_cafeteria_interact_area.body_entered.connect(_on_cafeteria_body_entered)
		_cafeteria_interact_area.body_exited.connect(_on_cafeteria_body_exited)
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_body_entered)
	if GameManager.take_basement_spawn_side() == "cafeteria_right":
		_pending_cafeteria_peek = true
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _cafeteria_zone_active and _cafeteria_zone_armed:
		_begin_cafeteria_transition()
		return
	if not _door_zone_active:
		return
	# Busy (line / CRT / bar) → overlay skips/advances; snap chip off; never stack a new line.
	if _door_dialogue_busy():
		_hide_interact_prompt_immediate()
		return
	_play_door_line_async()


func _door_dialogue_busy() -> bool:
	if _door_line_running:
		return true
	if not is_instance_valid(_top_dialogue):
		return false
	if _top_dialogue.has_method("is_sequence_busy") and _top_dialogue.is_sequence_busy():
		return true
	if _top_dialogue.has_method("is_bar_visible") and _top_dialogue.is_bar_visible():
		return true
	return false


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _on_door_body_entered(body: Node) -> void:
	if body != _player:
		return
	_door_zone_active = true
	_show_active_interact_prompt()


func _on_door_body_exited(body: Node) -> void:
	if body != _player:
		return
	_door_zone_active = false
	_show_active_interact_prompt()


func _on_cafeteria_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning:
		return
	_cafeteria_zone_active = true
	_show_active_interact_prompt()


func _on_cafeteria_body_exited(body: Node) -> void:
	if body != _player:
		return
	_cafeteria_zone_active = false
	_show_active_interact_prompt()


func _on_exit_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning:
		return
	call_deferred("_begin_corridor_return")


func _play_door_line_async() -> void:
	_door_line_running = true
	# Snap chip away with dialogue start so spam cannot CRT-shrink/re-open mid-line.
	_hide_interact_prompt_immediate()
	await _top_dialogue.show_line(DOOR_LINE, 3.0)
	_door_line_running = false
	GameManager.set_basement_door_line_seen(true)
	_show_active_interact_prompt()


func _door_interact_anchor() -> Vector2:
	if not is_instance_valid(_door_interact_area):
		return Vector2.ZERO
	var shape := _door_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return _door_interact_area.global_position


func _cafeteria_interact_anchor() -> Vector2:
	if not is_instance_valid(_cafeteria_interact_area):
		return Vector2.ZERO
	var shape := _cafeteria_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return _cafeteria_interact_area.global_position


func _show_active_interact_prompt() -> void:
	if _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	if _cafeteria_zone_active and _cafeteria_zone_armed:
		_interact_prompt.show_prompt(_cafeteria_interact_anchor())
		return
	if _door_zone_active and not _door_dialogue_busy():
		_interact_prompt.show_prompt(_door_interact_anchor())
		return
	_interact_prompt.hide_prompt()


func _hide_interact_prompt_immediate() -> void:
	if not is_instance_valid(_interact_prompt):
		return
	if _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	else:
		_interact_prompt.hide_prompt()


func _begin_corridor_return() -> void:
	_is_transitioning = true
	_save_walkoff_floor_offset()
	GameManager.set_corridor_spawn_side("basement_right")
	_hide_interact_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CORRIDOR_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CORRIDOR_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _begin_cafeteria_transition() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameManager.set_cafeteria_spawn_side("basement_left")
	_hide_interact_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CAFETERIA_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CAFETERIA_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _on_background_layout_applied(
	scale_factor: float, bg_position: Vector2, _world_rect: Rect2
) -> void:
	_sync_world_space(scale_factor, bg_position)


func _sync_world_space(cover_scale: float, bg_position: Vector2) -> void:
	var env := $WalkableWorld/EnvironmentColliders
	var player_node := $PlayerLayer/Player
	var tex_pos := Vector2.ZERO
	var remap_pos := _player_spawn_applied and _player_cover_sync.has_reference()
	if remap_pos:
		tex_pos = env.to_local(player_node.global_position)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	if not _player_spawn_applied:
		if _pending_cafeteria_peek:
			player_node.global_position = _cafeteria_right_peek_global()
			_pending_cafeteria_peek = false
			_arm_cafeteria_zone_grace()
		else:
			player_node.global_position = env.to_global(Vector2(250.0, 950.0))
			_apply_walkoff_y_if_pending(player_node)
		_player_spawn_applied = true
	elif remap_pos:
		player_node.global_position = env.to_global(tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	call_deferred("_wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_if_pending")


func _apply_walkoff_y_if_pending(player_node: CharacterBody2D) -> void:
	if not GameManager.has_walkoff_floor_offset_y():
		return
	var offset_y := GameManager.take_walkoff_floor_offset_y()
	var pos := player_node.global_position
	pos.y = _floor_marker_global_y() + offset_y
	pos.y = _clamp_walkable_y(pos.y)
	player_node.global_position = pos


func _floor_marker_global_y() -> float:
	var line := get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FloorDividerLine"
	) as Line2D
	if is_instance_valid(line):
		return line.global_position.y
	return _player.global_position.y if is_instance_valid(_player) else 0.0


func _clamp_walkable_y(y: float) -> float:
	var min_y := _floor_marker_global_y() + 8.0
	var max_y := y
	var bottom := get_node_or_null(
		"WalkableWorld/EnvironmentColliders/BottomWall"
	) as StaticBody2D
	if is_instance_valid(bottom):
		var shape := bottom.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null and shape.shape is RectangleShape2D:
			var half_height: float = (shape.shape as RectangleShape2D).size.y * 0.5
			max_y = bottom.to_global(
				Vector2(shape.position.x, shape.position.y - half_height)
			).y - 8.0
		else:
			max_y = bottom.global_position.y - 8.0
	if max_y < min_y:
		return y
	return clampf(y, min_y, max_y)


func _save_walkoff_floor_offset() -> void:
	if not is_instance_valid(_player):
		return
	GameManager.set_walkoff_floor_offset_y(
		_player.global_position.y - _floor_marker_global_y()
	)


func _apply_cafeteria_peek_if_pending() -> void:
	if not _pending_cafeteria_peek or not is_instance_valid(_player):
		return
	_pending_cafeteria_peek = false
	_player.global_position = _cafeteria_right_peek_global()
	_arm_cafeteria_zone_grace()


func _arm_cafeteria_zone_grace() -> void:
	_cafeteria_zone_armed = false
	await get_tree().create_timer(CAFETERIA_ZONE_GRACE_SEC).timeout
	_cafeteria_zone_armed = true
	if _cafeteria_zone_active:
		_show_active_interact_prompt()


func _cafeteria_right_peek_global() -> Vector2:
	var pos := _player.global_position
	var left_edge := _cafeteria_interact_left_edge_x()
	if left_edge > -INF:
		pos.x = left_edge - CAFETERIA_PEEK_MARGIN_PX
	if is_instance_valid(_cafeteria_interact_area):
		pos.y = _cafeteria_interact_area.global_position.y
	return pos


func _cafeteria_interact_left_edge_x() -> float:
	if not is_instance_valid(_cafeteria_interact_area):
		return -INF
	var shape := _cafeteria_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return -INF
	var half_width: float = (shape.shape as RectangleShape2D).size.x * 0.5
	return _cafeteria_interact_area.to_global(
		Vector2(shape.position.x - half_width, shape.position.y)
	).x


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
