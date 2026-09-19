extends ExplorationRoom

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const TEACHERS_LOUNGE_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"
const STUB_DOOR_LINES := {
	"future": "Not yet.",
	"extra_1": "Try the next one.",
	"extra_2": "No, the next one.",
	"extra_3": "You missed it.",
}

@export var vertical_far_scale: float = 1.5

var _cafeteria_area: Area2D
var _lounge_area: Area2D
var _classroom_area: Area2D
var _future_area: Area2D
var _extra_1_area: Area2D
var _extra_2_area: Area2D
var _extra_3_area: Area2D
var _size_ramp_area: Area2D
var _pending_spawn_side := ""
var _arrival_t := InteractArrival.DEFAULT_T
var _depth_factor: float = 1.0
var _last_cover_scale: float = 0.0
var _last_bg_position: Vector2 = Vector2.ZERO
var _spawn_placement_pending := false


func _ready() -> void:
	bind_player_cover()
	_cafeteria_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/CafeteriaInteractArea"
	) as Area2D
	_lounge_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/LoungeInteractArea"
	) as Area2D
	_classroom_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ClassroomInteractArea"
	) as Area2D
	_future_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FutureDoorInteractArea"
	) as Area2D
	_extra_1_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExtraDoor1InteractArea"
	) as Area2D
	_extra_2_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExtraDoor2InteractArea"
	) as Area2D
	_extra_3_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExtraDoor3InteractArea"
	) as Area2D
	_size_ramp_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/VerticalSizeRampArea"
	) as Area2D
	set_process(true)
	set_process_unhandled_input(true)
	set_physics_process(true)
	call_deferred("_restore_player_position_if_needed")


func zone_ids() -> PackedStringArray:
	return PackedStringArray([
		"cafeteria", "lounge", "classroom", "future", "extra_1", "extra_2", "extra_3"
	])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"cafeteria":
			return _cafeteria_area
		"lounge":
			return _lounge_area
		"classroom":
			return _classroom_area
		"future":
			return _future_area
		"extra_1":
			return _extra_1_area
		"extra_2":
			return _extra_2_area
		"extra_3":
			return _extra_3_area
		_:
			return null


func extra_blocks_interact() -> bool:
	return _line_running


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"cafeteria":
			GameManager.set_cafeteria_spawn_side("classrooms_bottom")
			begin_scene_change(CAFETERIA_SCENE)
		"lounge":
			leave_through(
				_lounge_area,
				Vector2.AXIS_X,
				"set_teachers_lounge_spawn_side",
				"corridor_door",
				TEACHERS_LOUNGE_SCENE,
			)
		"classroom":
			GameManager.set_classroom_spawn_side("corridor_door")
			begin_scene_change(CLASSROOM_SCENE)
		"future", "extra_1", "extra_2", "extra_3":
			_begin_stub_door(zone_id)


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.has_pause_map_return_for(scene_file_path):
		return
	_pending_spawn_side = GameManager.take_classrooms_corridor_spawn_side()
	_seed_depth_from_spawn_side(_pending_spawn_side)
	if _pending_spawn_side in ["cafeteria_door", "lounge_door", "classroom_door"]:
		_spawn_placement_pending = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _pending_spawn_side == "cafeteria_door":
			_arrival_t = InteractArrival.DEFAULT_T
		if _cover_layout_ready:
			call_deferred("_apply_spawn_peek_after_wake")


func _seed_depth_from_spawn_side(spawn_side: String) -> void:
	match spawn_side:
		"lounge_door", "classroom_door":
			_depth_factor = vertical_far_scale
		_:
			_depth_factor = 1.0


func _reassert_seeded_depth_if_pending() -> void:
	if not _spawn_placement_pending:
		return
	_seed_depth_from_spawn_side(_pending_spawn_side)
	_apply_player_cover_and_depth(_player)


func _begin_stub_door(zone_id: String) -> void:
	if not STUB_DOOR_LINES.has(zone_id):
		return
	if extra_blocks_interact() or InteractZoneGate.dialogue_busy(_top_dialogue):
		return
	_line_running = true
	await _top_dialogue.show_line(str(STUB_DOOR_LINES[zone_id]), 3.0)
	_line_running = false
	if _active_zone == zone_id:
		show_interact_prompt()


func apply_player_cover(
	player_node: CharacterBody2D, cover_scale: float, bg_position: Vector2
) -> void:
	_last_cover_scale = cover_scale
	_last_bg_position = bg_position
	_apply_player_cover_and_depth(player_node)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	if _pending_spawn_side in ["cafeteria_door", "lounge_door", "classroom_door"]:
		call_deferred("_apply_spawn_peek_after_wake")


func _apply_spawn_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_reassert_seeded_depth_if_pending()
	_apply_spawn_peek_if_pending()


func _apply_spawn_peek_if_pending() -> void:
	if not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	var side := _pending_spawn_side
	if side not in ["cafeteria_door", "lounge_door", "classroom_door"]:
		return
	match side:
		"cafeteria_door":
			_player.global_position = InteractArrival.place_node_on_area_center(
				_player, _cafeteria_area
			)
			latch_zone("cafeteria")
			arm_zone_grace("cafeteria")
		"lounge_door":
			InteractArrival.apply_arrival_inside(
				_player, _lounge_area, _arrival_t, Vector2.AXIS_X,
				InteractArrival.PeekEdge.TOP, 0.5
			)
			latch_zone("lounge")
			arm_zone_grace("lounge")
		"classroom_door":
			InteractArrival.apply_arrival_inside(
				_player, _classroom_area, _arrival_t, Vector2.AXIS_X,
				InteractArrival.PeekEdge.TOP, 0.5
			)
			latch_zone("classroom")
			arm_zone_grace("classroom")
	_pending_spawn_side = ""
	_spawn_placement_pending = false


func _physics_process(_delta: float) -> void:
	if not _cover_layout_ready or _is_transitioning:
		return
	if not _spawn_placement_pending:
		_update_depth_factor_from_player()
	_apply_player_cover_and_depth(_player)


func _apply_player_cover_and_depth(player_node: CharacterBody2D) -> void:
	if not is_instance_valid(player_node) or _last_cover_scale <= 0.0:
		return
	_player_cover_sync.apply(player_node, _last_cover_scale, _last_bg_position)
	player_node.scale *= _depth_factor
	player_node.speed *= _depth_factor


func _update_depth_factor_from_player() -> void:
	if not is_instance_valid(_size_ramp_area) or not is_instance_valid(_player):
		return
	var shape := _size_ramp_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return
	var rect_shape := shape.shape as RectangleShape2D
	var local_pos := _size_ramp_area.to_local(_player.global_position) - shape.position
	var half := rect_shape.size * 0.5
	if absf(local_pos.x) > half.x or absf(local_pos.y) > half.y:
		return
	var t := clampf((local_pos.y + half.y) / rect_shape.size.y, 0.0, 1.0)
	_depth_factor = lerpf(1.0, vertical_far_scale, t)
