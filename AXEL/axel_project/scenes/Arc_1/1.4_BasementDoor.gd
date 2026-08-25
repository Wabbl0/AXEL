extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const DOOR_LINE := "Not yet."
## Just left of CafeteriaInteractArea so only a sliver peeks on the right.
const CAFETERIA_PEEK_MARGIN_PX := 12.0
## Just right of ExitTrigger so only a sliver peeks on the left.
const CORRIDOR_PEEK_MARGIN_PX := 12.0
const CAFETERIA_ZONE_GRACE_SEC := 0.15
const EXIT_TRIGGER_GRACE_SEC := 0.15
## Same 2400×1500 plate as 1.2 — share the corridor's authored cover baseline
## so Mike is the same on-screen size (do not use 1920×1280 bind_design).
const _OLD_BG_SCALE := Vector2(0.546, 0.546)

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
var _pending_cafeteria_peek := false
var _pending_corridor_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _exit_trigger_armed := true
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	_player_cover_sync.authored_bg_baseline = _OLD_BG_SCALE.x
	_player_cover_sync.bind_from_player(_player)
	var _bg := $WalkableWorld/Background as Sprite2D
	var _cam := $Camera2D
	# Legacy 1.2 baseline already set; bind_design no-ops (do not switch to 1920x1280).
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
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	# Match 1.2: take spawn side + t after first layout settles, then re-queue peek.
	call_deferred("_restore_player_position_if_needed")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	var basement_side := GameManager.take_basement_spawn_side()
	if basement_side == "cafeteria_right":
		_pending_cafeteria_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_cafeteria_peek_if_pending")
		return
	if basement_side == "corridor_left":
		_pending_corridor_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_corridor_peek_if_pending")
		return


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
	if body != _player or _is_transitioning or not _exit_trigger_armed:
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
	if is_instance_valid(_player) and is_instance_valid(_exit_trigger):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _exit_trigger, Vector2.AXIS_Y)
		)
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
	if is_instance_valid(_player) and is_instance_valid(_cafeteria_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _cafeteria_interact_area, Vector2.AXIS_Y
			)
		)
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
	var tex_pos := PlayerSpawnSync.capture_tex(env, player_node)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	# Always remap Player node (1.2 style). Peek overwrite runs deferred after.
	PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	call_deferred("_wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_if_pending")
	elif _pending_corridor_peek:
		call_deferred("_apply_corridor_peek_if_pending")


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
	call_deferred("_clamp_arrived_player")
	_arm_cafeteria_zone_grace()


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


func _arm_cafeteria_zone_grace() -> void:
	_cafeteria_zone_armed = false
	await get_tree().create_timer(CAFETERIA_ZONE_GRACE_SEC).timeout
	_cafeteria_zone_armed = true
	if _cafeteria_zone_active:
		_show_active_interact_prompt()


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	await get_tree().create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
