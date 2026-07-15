extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const DOOR_LINE := "Not yet."

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _door_interact_area: Area2D
var _exit_trigger: Area2D
var _door_zone_active := false
var _is_transitioning := false
var _door_line_running := false
var _player_spawn_applied := false


func _ready() -> void:
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_door_interact_area):
		_door_interact_area.body_entered.connect(_on_door_body_entered)
		_door_interact_area.body_exited.connect(_on_door_body_exited)
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_body_entered)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _door_line_running:
		return
	if not _is_interaction_event(event):
		return
	if not _door_zone_active:
		return
	if GameManager.basement_door_line_seen:
		return
	_play_door_line_async()


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
	_show_door_interact_prompt()


func _on_door_body_exited(body: Node) -> void:
	if body != _player:
		return
	_door_zone_active = false
	_hide_door_interact_prompt()


func _on_exit_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning:
		return
	call_deferred("_begin_corridor_return")


func _play_door_line_async() -> void:
	_door_line_running = true
	_hide_door_interact_prompt()
	await _top_dialogue.show_line(DOOR_LINE, 3.0)
	_door_line_running = false
	GameManager.set_basement_door_line_seen(true)
	if _door_zone_active:
		_show_door_interact_prompt()


func _door_interact_anchor() -> Vector2:
	if not is_instance_valid(_door_interact_area):
		return Vector2.ZERO
	var shape := _door_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return _door_interact_area.global_position


func _show_door_interact_prompt() -> void:
	if _is_transitioning or not _door_zone_active:
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


func _begin_corridor_return() -> void:
	_is_transitioning = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
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
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	var player_node := $PlayerLayer/Player
	if not _player_spawn_applied:
		player_node.global_position = env.to_global(Vector2(250.0, 550.0))
		_player_spawn_applied = true
	call_deferred("_wake_static_colliders")


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
