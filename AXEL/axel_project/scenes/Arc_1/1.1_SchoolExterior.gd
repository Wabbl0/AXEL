extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _leaf_areas: Array[Area2D] = [
	get_node("EnvironmentColliders/TreeLine_Bottom_Leaves"),
	get_node("EnvironmentColliders/TreeLine_Top_Leaves"),
]

var _door_interact_area: Area2D

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_EDGE_SOFTNESS := 34.0
const _LEAF_MASK_PADDING := Vector2(22.0, 28.0)

var _is_transitioning := false


func _ready() -> void:
	_door_interact_area = get_node_or_null(
		"1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea"
	) as Area2D
	set_process_unhandled_input(true)
	_configure_leaf_occlusion_masks()
	if _should_skip_intro():
		return
	_run_intro_dialogue()


func _should_skip_intro() -> bool:
	return OS.has_environment("AXEL_SKIP_INTRO") and OS.get_environment("AXEL_SKIP_INTRO") == "1"


func _run_intro_dialogue() -> void:
	await _top_dialogue.show_line("You promised, you'd never come back.", 2.0)
	await get_tree().create_timer(0.8).timeout
	await _top_dialogue.show_line("Yet, here we are...", 2.5)
	await get_tree().create_timer(0.55).timeout
	await _top_dialogue.show_line("Pathetic.", 1.6)


func _unhandled_input(event: InputEvent) -> void:
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
