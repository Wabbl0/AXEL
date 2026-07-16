extends Node2D

const ENTER_LINE := "Even through all the chaos you can hear the chattering students of the past."
const TABLE_SCENE := "res://scenes/Arc_2/2.2_CafeteriaMemory.tscn"
const KITCHEN_SCENE := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const PLAYER_SPAWN_TEX := Vector2(1754.0, 1900.0)

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $WalkableWorld/Player

var _table_area: Area2D
var _kitchen_area: Area2D
var _return_area: Area2D
var _active_zone: String = ""
var _is_transitioning := false
var _player_spawn_applied := false


func _ready() -> void:
	_table_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/TableInteractArea"
	) as Area2D
	_kitchen_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KitchenInteractArea"
	) as Area2D
	_return_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ReturnInteractArea"
	) as Area2D
	_connect_zone(_table_area, "table")
	_connect_zone(_kitchen_area, "kitchen")
	_connect_zone(_return_area, "return")
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_play_enter_dialogue")


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
	await _top_dialogue.show_line(ENTER_LINE, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _active_zone.is_empty():
		return
	match _active_zone:
		"table":
			_begin_scene_change(TABLE_SCENE)
		"kitchen":
			_begin_scene_change(KITCHEN_SCENE)
		"return":
			_begin_scene_change(LOCKER_HUB_SCENE)


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


func _zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"table":
			return _table_area
		"kitchen":
			return _kitchen_area
		"return":
			return _return_area
		_:
			return null


func _interact_anchor() -> Vector2:
	var area := _zone_area(_active_zone)
	if not is_instance_valid(area):
		return Vector2.ZERO
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	return area.global_position


func _show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
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


func _begin_scene_change(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
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
	if not _player_spawn_applied:
		_player.global_position = env.to_global(PLAYER_SPAWN_TEX)
		_player_spawn_applied = true
	call_deferred("_wake_static_colliders")


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
