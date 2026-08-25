extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const ENTER_LINES := [
	"You always wondered what the teachers were doing behind closed doors.",
	"Pervert.",
]
const DOOR_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _door_interact_area: Area2D
var _active_zone: String = ""
var _is_transitioning := false
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _door_zone_armed := true
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
	_connect_zone(_door_interact_area, "door")
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	call_deferred("_play_enter_dialogue")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_teachers_lounge_spawn_side() == "corridor_door":
		_pending_door_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_door_peek_if_pending")


func _connect_zone(area: Area2D, zone_id: String) -> void:
	if not is_instance_valid(area):
		return
	area.body_entered.connect(func(body: Node) -> void:
		_on_zone_body_entered(body, zone_id)
	)
	area.body_exited.connect(func(body: Node) -> void:
		_on_zone_body_exited(body, zone_id)
	)


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		return
	if GameManager.teachers_lounge_enter_line_seen:
		return
	GameManager.set_teachers_lounge_enter_line_seen(true)
	await _top_dialogue.show_lines(ENTER_LINES)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	if _active_zone == "door":
		_begin_return_to_corridor()


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _on_zone_body_entered(body: Node, zone_id: String) -> void:
	if body != _player or _is_transitioning:
		return
	_active_zone = zone_id
	_show_interact_prompt()


func _on_zone_body_exited(body: Node, zone_id: String) -> void:
	if body != _player:
		return
	if _active_zone == zone_id:
		_active_zone = ""
		_hide_interact_prompt()


func _interact_anchor() -> Vector2:
	if not is_instance_valid(_door_interact_area):
		return Vector2.ZERO
	var shape := _door_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return _door_interact_area.global_position


func _show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(_interact_anchor())


func _hide_interact_prompt() -> void:
	if _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func _begin_return_to_corridor() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_X
			)
		)
	GameManager.set_classrooms_corridor_spawn_side("lounge_door")
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CORRIDOR_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CORRIDOR_SCENE, err])
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
	PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	call_deferred("_wake_static_colliders")
	if _pending_door_peek:
		call_deferred("_apply_door_peek_if_pending")


func _apply_door_peek_if_pending() -> void:
	if not _pending_door_peek or not is_instance_valid(_player):
		return
	_pending_door_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.BOTTOM,
		12.0
	)
	call_deferred("_clamp_arrived_player")
	_arm_door_zone_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_X)


func _arm_door_zone_grace() -> void:
	_door_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	_door_zone_armed = true
	if _active_zone == "door":
		_show_interact_prompt()


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
