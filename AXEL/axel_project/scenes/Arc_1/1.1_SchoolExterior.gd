extends Node2D

enum IntroState {
	FORCED_SEQUENCE,
	PLAYER_FREE,
}

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _rocks_left: StaticBody2D = $EnvironmentColliders/Rocks_Left
@onready var _leaf_areas: Array[Area2D] = [
	get_node("EnvironmentColliders/TreeLine_Bottom_Leaves"),
	get_node("EnvironmentColliders/TreeLine_Top_Leaves"),
]

var _door_interact_area: Area2D
var _intro_state: IntroState = IntroState.FORCED_SEQUENCE

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_EDGE_SOFTNESS := 34.0
const _LEAF_MASK_PADDING := Vector2(22.0, 28.0)

const _GLITCH_BURST_SEC := 0.85
const _POST_GLITCH_WAIT_SEC := 1.0
const _STONES_ARRIVE_DISTANCE := 36.0
const _STONES_STAND_OFFSET := Vector2(-28.0, 6.0)
const _SCRIPTED_WALK_MAX_FRAMES := 96
const _SECOND_DIALOGUE_DISTANCE := 50.0
const _FIRST_DIALOGUE_LINE := "You promised, you'd never come back."
const _SECOND_DIALOGUE_LINE := "Yet, here we are..."

var _is_transitioning := false
var _unlock_position: Vector2 = Vector2.ZERO
var _second_dialogue_fired := false
var _watching_movement := false


func _ready() -> void:
	_door_interact_area = get_node_or_null(
		"1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea"
	) as Area2D
	set_process_unhandled_input(true)
	_configure_leaf_occlusion_masks()
	if _should_skip_intro():
		_intro_state = IntroState.PLAYER_FREE
		_enable_player_control()
		return
	_run_forced_intro_sequence()


func _should_skip_intro() -> bool:
	return OS.has_environment("AXEL_SKIP_INTRO") and OS.get_environment("AXEL_SKIP_INTRO") == "1"


func _process(_delta: float) -> void:
	if not _watching_movement or _second_dialogue_fired:
		return
	if not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(_unlock_position) < _SECOND_DIALOGUE_DISTANCE:
		return
	_second_dialogue_fired = true
	_watching_movement = false
	if _top_dialogue.has_method("show_line_nonblocking"):
		_top_dialogue.show_line_nonblocking(_SECOND_DIALOGUE_LINE, 2.5)


func _run_forced_intro_sequence() -> void:
	_intro_state = IntroState.FORCED_SEQUENCE
	_disable_player_control()
	AxelEventFx.set_cadence_enabled(false)

	await AxelEventFx.play_glitch_burst(_GLITCH_BURST_SEC)

	await get_tree().create_timer(_POST_GLITCH_WAIT_SEC).timeout

	AxelEventFx.start_interface_distortion()

	await _scripted_walk_to_left_stones()

	await AxelEventFx.stop_interface_distortion()

	if _top_dialogue.has_method("show_line"):
		await _top_dialogue.show_line(_FIRST_DIALOGUE_LINE, 2.0)

	_unlock_position = _player.global_position
	_enable_player_control()
	_intro_state = IntroState.PLAYER_FREE
	_watching_movement = true
	AxelEventFx.set_cadence_enabled(true)


func _disable_player_control() -> void:
	if is_instance_valid(_player) and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(false)


func _enable_player_control() -> void:
	if not is_instance_valid(_player):
		return
	if _player.has_method("clear_scripted_velocity"):
		_player.clear_scripted_velocity()
	if _player.has_method("set_input_enabled"):
		_player.set_input_enabled(true)


func _scripted_walk_to_left_stones() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_rocks_left):
		return

	var target := _left_stones_stand_target()
	var move_speed := float(_player.get("speed")) if _player.get("speed") != null else 180.0
	var frames := 0

	while is_instance_valid(_player):
		frames += 1
		var to_target := target - _player.global_position
		if to_target.length() <= _STONES_ARRIVE_DISTANCE or frames >= _SCRIPTED_WALK_MAX_FRAMES:
			break
		var direction := to_target.normalized()
		if _player.has_method("set_scripted_velocity"):
			_player.set_scripted_velocity(direction * move_speed)
		await get_tree().physics_frame

	if is_instance_valid(_player) and _player.has_method("clear_scripted_velocity"):
		_player.clear_scripted_velocity()
		_player.velocity = Vector2.ZERO


func _left_stones_stand_target() -> Vector2:
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for child in _rocks_left.get_children():
		if child is CollisionPolygon2D:
			var poly := child as CollisionPolygon2D
			for local_point in poly.polygon:
				var world_point := poly.to_global(local_point)
				min_point.x = minf(min_point.x, world_point.x)
				min_point.y = minf(min_point.y, world_point.y)
				max_point.x = maxf(max_point.x, world_point.x)
				max_point.y = maxf(max_point.y, world_point.y)
	if max_point.x < min_point.x:
		return _player.global_position + Vector2(80.0, 40.0)
	var center := (min_point + max_point) * 0.5
	return center + _STONES_STAND_OFFSET


func _unhandled_input(event: InputEvent) -> void:
	if _intro_state != IntroState.PLAYER_FREE:
		return
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if not _is_player_near_door():
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(_NEXT_SCENE_PATH)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [_NEXT_SCENE_PATH, err])
		_is_transitioning = false


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _is_player_near_door() -> bool:
	if not is_instance_valid(_door_interact_area) or not is_instance_valid(_player):
		return false
	for body in _door_interact_area.get_overlapping_bodies():
		if body == _player:
			return true
	return false


func _configure_leaf_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_masks"):
		return
	var masks: Array[Vector4] = []
	for leaf_area in _leaf_areas:
		masks.append(_leaf_area_to_mask_rect(leaf_area))
	while masks.size() < 2:
		masks.append(Vector4(0.0, 0.0, 1.0, 1.0))
	_player.call("configure_leaf_occlusion_masks", masks[0], masks[1], _LEAF_FADE_ALPHA, _LEAF_EDGE_SOFTNESS)


func _leaf_area_to_mask_rect(leaf_area: Area2D) -> Vector4:
	if not is_instance_valid(leaf_area):
		return Vector4(0.0, 0.0, 1.0, 1.0)
	var polygon_node := leaf_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return Vector4(leaf_area.global_position.x, leaf_area.global_position.y, 1.0, 1.0)
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for local_point in polygon_node.polygon:
		var world_point := polygon_node.to_global(local_point)
		min_point.x = minf(min_point.x, world_point.x)
		min_point.y = minf(min_point.y, world_point.y)
		max_point.x = maxf(max_point.x, world_point.x)
		max_point.y = maxf(max_point.y, world_point.y)
	var center := (min_point + max_point) * 0.5
	var radius := (max_point - min_point) * 0.5 + _LEAF_MASK_PADDING
	return Vector4(center.x, center.y, maxf(radius.x, 1.0), maxf(radius.y, 1.0))
