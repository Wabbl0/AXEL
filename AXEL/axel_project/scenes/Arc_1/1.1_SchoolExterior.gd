extends Node2D

enum IntroState {
	FORCED_SEQUENCE,
	PLAYER_FREE,
}

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _rocks_left: StaticBody2D = $EnvironmentColliders/Rocks_Left
@onready var _left_wall_collision: CollisionShape2D = $EnvironmentColliders/LeftWall/CollisionShape2D
@onready var _leaf_areas: Array[Area2D] = [
	get_node("EnvironmentColliders/TreeLine_Bottom_Leaves"),
	get_node("EnvironmentColliders/TreeLine_Top_Leaves"),
]
@onready var _trunk_lines: Array[StaticBody2D] = [
	get_node("EnvironmentColliders/TreeLine_Bottom") as StaticBody2D,
	get_node("EnvironmentColliders/TreeLine_Top") as StaticBody2D,
]
@onready var _behind_areas: Array[Area2D] = [
	get_node("EnvironmentColliders/TreeLine_Bottom_Behind") as Area2D,
	get_node("EnvironmentColliders/TreeLine_Top_Behind") as Area2D,
]

var _door_interact_area: Area2D
var _intro_state: IntroState = IntroState.FORCED_SEQUENCE

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_EDGE_SOFTNESS := 34.0
const _LEAF_MASK_PADDING := Vector2(22.0, 28.0)
const _BEHIND_MASK_PADDING := Vector2(6.0, 8.0)
const _BEHIND_EDGE_SOFTNESS := 20.0
const _LEAF_Y_CUTOFF_MARGIN := 4.0

const _GLITCH_BURST_SEC := 0.85
const _STONES_ARRIVE_DISTANCE := 36.0
const _SCRIPTED_WALK_SPEED_SCALE := 0.5
const _SCRIPTED_WALK_MAX_FRAMES := 600
const _SECOND_DIALOGUE_DISTANCE := 50.0
const _FIRST_DIALOGUE_LINE := "You promised, you'd never come back."
const _SECOND_DIALOGUE_LINE := "Yet, here we are..."
const _THIRD_DIALOGUE_LINE := "Pathetic."
const _PATHETIC_BEAT_SEC := 2.0
const _SECOND_LINE_TAIL_HOLD_SEC := 2.0

var _is_transitioning := false
var _unlock_position: Vector2 = Vector2.ZERO
var _second_dialogue_fired := false
var _watching_movement := false


func _ready() -> void:
	_door_interact_area = get_node_or_null(
		"EnvironmentColliders/Doors/DoorInteractArea"
	) as Area2D
	if is_instance_valid(_door_interact_area):
		_door_interact_area.body_entered.connect(_on_door_interact_body_entered)
		_door_interact_area.body_exited.connect(_on_door_interact_body_exited)
	set_process_unhandled_input(true)
	_configure_leaf_occlusion_masks()
	if _should_skip_intro():
		_intro_state = IntroState.PLAYER_FREE
		if is_instance_valid(_player):
			_player.global_position = _left_stones_stand_target()
		_enable_player_control()
		_refresh_door_interact_prompt()
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
	_play_second_then_pathetic()


func _play_second_then_pathetic() -> void:
	if not _top_dialogue.has_method("type_line"):
		return
	await _top_dialogue.type_line(_SECOND_DIALOGUE_LINE)
	await get_tree().create_timer(_PATHETIC_BEAT_SEC).timeout
	await _top_dialogue.type_line(_THIRD_DIALOGUE_LINE)
	await get_tree().create_timer(_SECOND_LINE_TAIL_HOLD_SEC).timeout
	await _top_dialogue.hide_line()


func _run_forced_intro_sequence() -> void:
	_intro_state = IntroState.FORCED_SEQUENCE
	_disable_player_control()
	AxelEventFx.set_cadence_enabled(false)

	if is_instance_valid(_left_wall_collision):
		_left_wall_collision.set_deferred("disabled", true)

	AxelEventFx.start_interface_distortion()

	_run_intro_glitch_burst(_GLITCH_BURST_SEC)
	await _scripted_walk_to_left_stones()

	if is_instance_valid(_left_wall_collision):
		_left_wall_collision.set_deferred("disabled", false)

	await AxelEventFx.stop_interface_distortion()

	if _top_dialogue.has_method("type_line"):
		await _top_dialogue.type_line(_FIRST_DIALOGUE_LINE)

	_unlock_position = _player.global_position
	_enable_player_control()
	_intro_state = IntroState.PLAYER_FREE
	_watching_movement = true
	AxelEventFx.set_cadence_enabled(true)
	_refresh_door_interact_prompt()


func _run_intro_glitch_burst(duration_sec: float) -> void:
	await AxelEventFx.play_glitch_burst(duration_sec)


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
	var base_speed := float(_player.get("speed")) if _player.get("speed") != null else 180.0
	var move_speed := base_speed * _SCRIPTED_WALK_SPEED_SCALE
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
	var poly2 := _rocks_left.get_node_or_null("CollisionPolygon2D2") as CollisionPolygon2D
	var poly3 := _rocks_left.get_node_or_null("CollisionPolygon2D3") as CollisionPolygon2D
	if poly2 == null or poly3 == null or poly2.polygon.is_empty() or poly3.polygon.is_empty():
		if is_instance_valid(_player):
			return _player.global_position + Vector2(80.0, 40.0)
		return Vector2(249.0, 402.0)
	var centroid2 := _polygon_global_centroid(poly2)
	var centroid3 := _polygon_global_centroid(poly3)
	return (centroid2 + centroid3) * 0.5


func _polygon_global_centroid(poly: CollisionPolygon2D) -> Vector2:
	if poly.polygon.is_empty():
		return poly.global_position
	var sum := Vector2.ZERO
	for local_point in poly.polygon:
		sum += poly.to_global(local_point)
	return sum / float(poly.polygon.size())


func _unhandled_input(event: InputEvent) -> void:
	if _intro_state != IntroState.PLAYER_FREE:
		return
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if not _is_player_near_door():
		return
	_begin_door_transition()


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


func _door_interact_anchor() -> Vector2:
	if not is_instance_valid(_door_interact_area):
		return Vector2.ZERO
	var poly := _door_interact_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly == null:
		return _door_interact_area.global_position
	return _polygon_global_centroid(poly)


func _on_door_interact_body_entered(body: Node) -> void:
	if body != _player:
		return
	_try_show_door_interact_prompt()


func _on_door_interact_body_exited(body: Node) -> void:
	if body != _player:
		return
	if _is_transitioning:
		return
	_hide_door_interact_prompt()


func _try_show_door_interact_prompt() -> void:
	if _intro_state != IntroState.PLAYER_FREE or _is_transitioning:
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


func _refresh_door_interact_prompt() -> void:
	if _is_player_near_door():
		_try_show_door_interact_prompt()
	else:
		_hide_door_interact_prompt()


func _begin_door_transition() -> void:
	_is_transitioning = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	var err := get_tree().change_scene_to_file(_NEXT_SCENE_PATH)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [_NEXT_SCENE_PATH, err])
		_is_transitioning = false
		AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _configure_leaf_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_masks"):
		return
	var masks: Array[Vector4] = []
	for leaf_area in _leaf_areas:
		masks.append(_leaf_area_to_mask_rect(leaf_area, _LEAF_MASK_PADDING))
	while masks.size() < 2:
		masks.append(Vector4(0.0, 0.0, 1.0, 1.0))
	var behind_masks: Array[Vector4] = []
	for behind_area in _behind_areas:
		behind_masks.append(_leaf_area_to_mask_rect(behind_area, _BEHIND_MASK_PADDING))
	while behind_masks.size() < 2:
		behind_masks.append(Vector4.ZERO)
	var y_cutoffs: Array[float] = []
	for trunk_body in _trunk_lines:
		y_cutoffs.append(_trunk_line_y_cutoff(trunk_body))
	while y_cutoffs.size() < 2:
		y_cutoffs.append(1e9)
	_player.call(
		"configure_leaf_occlusion_masks",
		masks[0],
		masks[1],
		_LEAF_FADE_ALPHA,
		_LEAF_EDGE_SOFTNESS,
		y_cutoffs[0],
		y_cutoffs[1],
		behind_masks[0],
		behind_masks[1],
		_BEHIND_EDGE_SOFTNESS,
	)


func _trunk_line_y_cutoff(trunk_body: StaticBody2D) -> float:
	if not is_instance_valid(trunk_body):
		return 1e9
	var polygon_node := trunk_body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return trunk_body.global_position.y - _LEAF_Y_CUTOFF_MARGIN
	var max_y := -INF
	for local_point in polygon_node.polygon:
		var world_point := polygon_node.to_global(local_point)
		max_y = maxf(max_y, world_point.y)
	if max_y == -INF:
		return 1e9
	return max_y - _LEAF_Y_CUTOFF_MARGIN


func _leaf_area_to_mask_rect(leaf_area: Area2D, padding: Vector2 = _LEAF_MASK_PADDING) -> Vector4:
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
	var radius := (max_point - min_point) * 0.5 + padding
	return Vector4(center.x, center.y, maxf(radius.x, 1.0), maxf(radius.y, 1.0))
