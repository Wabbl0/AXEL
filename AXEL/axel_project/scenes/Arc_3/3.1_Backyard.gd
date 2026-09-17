extends ExplorationRoom

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const MEMORY_SCENE := "res://scenes/Arc_3/3.2_BackyardMemory.tscn"
const MEMORY_KEY := "backyard_memory"
const ENTER_LINES := [
	"The spirit of rebellion is still present here.|beat:1.5| Nice graffiti.",
	"You could never be this talented.",
]
const CIGARETTE_LINES := [
	"You light up your cigarette.",
	"Tastes of tar and regret.",
	"Yum.",
]
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0

var _door_interact_area: Area2D
var _memory_area: Area2D
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T


func _ready() -> void:
	bind_player_cover()
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_memory_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/MemoryInteractArea"
	) as Area2D
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")
	_enter_dialogue_pending = _will_play_enter_dialogue()
	call_deferred("_play_enter_dialogue")


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["memory", "door"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"memory":
			return _memory_area
		"door":
			return _door_interact_area
		_:
			return null


func zone_is_available(zone_id: String) -> bool:
	if zone_id == "memory":
		return not GameManager.has_memory_scene(MEMORY_KEY)
	return true


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"memory":
			save_player_tex("set_backyard_memory_return_pos")
			begin_scene_change(MEMORY_SCENE)
		"door":
			leave_through(
				_door_interact_area,
				Vector2.AXIS_Y,
				"set_cafeteria_spawn_side",
				"backyard_right",
				CAFETERIA_SCENE,
			)


func _will_play_enter_dialogue() -> bool:
	if not GameManager.backyard_enter_line_seen:
		return true
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.backyard_cigarette_line_seen:
		return true
	return false


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_backyard_spawn_side() == "cafeteria_door":
		_pending_door_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_door_peek_after_wake")
		return
	if GameManager.has_backyard_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if not GameManager.backyard_enter_line_seen:
		GameManager.set_backyard_enter_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(ENTER_LINES)
		return
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.backyard_cigarette_line_seen:
		GameManager.set_backyard_cigarette_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(CIGARETTE_LINES)
		return
	_enter_dialogue_pending = false


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	call_deferred("_configure_behind_occlusion_masks")
	if GameManager.has_backyard_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_door_peek_if_pending()


func _apply_memory_return_if_pending() -> void:
	restore_player_tex("has_backyard_memory_return_pos", "take_backyard_memory_return_pos")


func _apply_door_peek_if_pending() -> void:
	if not _pending_door_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_door_peek = false
	InteractArrival.apply_arrival_inside(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		0.5
	)
	latch_zone("door")
	arm_zone_grace("door")


func _configure_behind_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	for zone_name in ["Wall_Behind", "Bush_Behind", "Well_Behind"]:
		var zone := get_node_or_null(
			"WalkableWorld/EnvironmentColliders/%s" % zone_name
		) as Area2D
		var poly := PackedVector2Array()
		var feather := 0.0
		if is_instance_valid(zone) and zone.has_method("get_shader_polygon"):
			poly = zone.call("get_shader_polygon")
			feather = float(zone.get("feather_px"))
		polys.append(poly)
		feathers.append(feather)
	_player.call(
		"configure_leaf_occlusion_polygons",
		polys[0],
		polys[1],
		feathers[0],
		feathers[1],
		_LEAF_FADE_ALPHA,
		1e9,
		1e9,
		_LEAF_GATE_SOFTNESS,
		polys[2],
		feathers[2],
		1e9,
		true,
	)
