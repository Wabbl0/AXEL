extends Node2D

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const TEACHERS_LOUNGE_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"
const STUB_DOOR_LINES := {
	"future": "Not yet.",
	"extra_1": "Try the next one.",
	"extra_2": "No, the next one.",
	"extra_3": "You missed it.",
}
const DOOR_ZONE_GRACE_SEC := 0.15

## Extra size at the bottom of the vertical-leg ramp (1.5 = 150%).
@export var vertical_far_scale: float = 1.5

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _cafeteria_area: Area2D
var _lounge_area: Area2D
var _classroom_area: Area2D
var _future_area: Area2D
var _extra_1_area: Area2D
var _extra_2_area: Area2D
var _extra_3_area: Area2D
var _size_ramp_area: Area2D
var _active_zone: String = ""
var _is_transitioning := false
var _stub_line_running := false
var _pending_spawn_side := ""
var _arrival_t := InteractArrival.DEFAULT_T
var _cafeteria_zone_armed := true
var _lounge_zone_armed := true
var _classroom_zone_armed := true
var _player_cover_sync := PlayerCoverSync.new()
## Walk-Y size multiplier on top of PlayerCoverSync (1.0 at cafeteria, far at corner).
var _depth_factor: float = 1.0
var _last_cover_scale: float = 0.0
var _last_bg_position: Vector2 = Vector2.ZERO
var _cover_layout_ready := false


func _ready() -> void:
	_player_cover_sync.bind_from_player(_player)
	var _bg := $WalkableWorld/Background as Sprite2D
	var _cam := $Camera2D
	_player_cover_sync.bind_design_from_background(
		_bg, _cam.fit_mode, _cam.background_y
	)
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
	_connect_zone(_cafeteria_area, "cafeteria")
	_connect_zone(_lounge_area, "lounge")
	_connect_zone(_classroom_area, "classroom")
	_connect_zone(_future_area, "future")
	_connect_zone(_extra_1_area, "extra_1")
	_connect_zone(_extra_2_area, "extra_2")
	_connect_zone(_extra_3_area, "extra_3")
	set_process_unhandled_input(true)
	set_physics_process(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	_pending_spawn_side = GameManager.take_classrooms_corridor_spawn_side()
	_seed_depth_from_spawn_side(_pending_spawn_side)
	if _pending_spawn_side in ["cafeteria_door", "lounge_door", "classroom_door"]:
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_spawn_peek_if_pending")


func _seed_depth_from_spawn_side(spawn_side: String) -> void:
	match spawn_side:
		"lounge_door", "classroom_door":
			_depth_factor = vertical_far_scale
		_:
			# Fresh Play, cafeteria_door, or empty → 100%.
			_depth_factor = 1.0


func _connect_zone(area: Area2D, zone_id: String) -> void:
	if not is_instance_valid(area):
		return
	area.body_entered.connect(func(body: Node) -> void:
		_on_zone_body_entered(body, zone_id)
	)
	area.body_exited.connect(func(body: Node) -> void:
		_on_zone_body_exited(body, zone_id)
	)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "cafeteria" and not _cafeteria_zone_armed:
		return
	if _active_zone == "lounge" and not _lounge_zone_armed:
		return
	if _active_zone == "classroom" and not _classroom_zone_armed:
		return
	match _active_zone:
		"cafeteria":
			_begin_go_to_cafeteria()
		"lounge":
			_begin_go_to_lounge()
		"classroom":
			_begin_go_to_classroom()
		"future", "extra_1", "extra_2", "extra_3":
			_begin_stub_door(_active_zone)


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


func _zone_armed(zone_id: String) -> bool:
	match zone_id:
		"cafeteria":
			return _cafeteria_zone_armed
		"lounge":
			return _lounge_zone_armed
		"classroom":
			return _classroom_zone_armed
		"future", "extra_1", "extra_2", "extra_3":
			return not _stub_line_running
		_:
			return true


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
	if not _zone_armed(_active_zone):
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


func _hide_interact_prompt_immediate() -> void:
	if not is_instance_valid(_interact_prompt):
		return
	if _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	else:
		_interact_prompt.hide_prompt()


func _stub_dialogue_busy() -> bool:
	if _stub_line_running:
		return true
	if not is_instance_valid(_top_dialogue):
		return false
	if _top_dialogue.has_method("is_sequence_busy") and _top_dialogue.is_sequence_busy():
		return true
	if _top_dialogue.has_method("is_bar_visible") and _top_dialogue.is_bar_visible():
		return true
	return false


func _begin_stub_door(zone_id: String) -> void:
	# Line-only doors. Future_1_2 stays stub until a legacy corridor link is approved.
	if not STUB_DOOR_LINES.has(zone_id):
		return
	if _stub_dialogue_busy():
		_hide_interact_prompt_immediate()
		return
	_stub_line_running = true
	_hide_interact_prompt_immediate()
	await _top_dialogue.show_line(str(STUB_DOOR_LINES[zone_id]), 3.0)
	_stub_line_running = false
	if _active_zone == zone_id:
		_show_interact_prompt()


func _begin_go_to_cafeteria() -> void:
	if is_instance_valid(_player) and is_instance_valid(_cafeteria_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _cafeteria_area, Vector2.AXIS_X)
		)
	GameManager.set_cafeteria_spawn_side("classrooms_bottom")
	_begin_scene_change(CAFETERIA_SCENE)


func _begin_go_to_lounge() -> void:
	if is_instance_valid(_player) and is_instance_valid(_lounge_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _lounge_area, Vector2.AXIS_X)
		)
	GameManager.set_teachers_lounge_spawn_side("corridor_door")
	_begin_scene_change(TEACHERS_LOUNGE_SCENE)


func _begin_go_to_classroom() -> void:
	if is_instance_valid(_player) and is_instance_valid(_classroom_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _classroom_area, Vector2.AXIS_X)
		)
	GameManager.set_classroom_spawn_side("corridor_door")
	_begin_scene_change(CLASSROOM_SCENE)


func _begin_scene_change(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
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
	var player_node := $PlayerLayer/Player
	var tex_pos := PlayerSpawnSync.capture_tex(env, player_node)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	_last_cover_scale = cover_scale
	_last_bg_position = bg_position
	_cover_layout_ready = true
	_apply_player_cover_and_depth(player_node)
	call_deferred("_wake_static_colliders")
	if _pending_spawn_side in ["cafeteria_door", "lounge_door", "classroom_door"]:
		call_deferred("_apply_spawn_peek_if_pending")


func _apply_spawn_peek_if_pending() -> void:
	if not is_instance_valid(_player):
		return
	var side := _pending_spawn_side
	if side not in ["cafeteria_door", "lounge_door", "classroom_door"]:
		return
	_pending_spawn_side = ""
	match side:
		"cafeteria_door":
			_apply_arrival_on_area(
				_player, _cafeteria_area, Vector2.AXIS_X,
				InteractArrival.PeekEdge.BOTTOM, 12.0
			)
			_arm_zone_grace("cafeteria")
		"lounge_door":
			_apply_arrival_on_area(
				_player, _lounge_area, Vector2.AXIS_X,
				InteractArrival.PeekEdge.TOP, -12.0
			)
			_arm_zone_grace("lounge")
		"classroom_door":
			_apply_arrival_on_area(
				_player, _classroom_area, Vector2.AXIS_X,
				InteractArrival.PeekEdge.TOP, -12.0
			)
			_arm_zone_grace("classroom")
	# After door place, size from Y if inside the ramp (cafeteria ~100%).
	_update_depth_factor_from_player()
	_apply_player_cover_and_depth(_player)

func _physics_process(_delta: float) -> void:
	if not _cover_layout_ready or _is_transitioning:
		return
	_update_depth_factor_from_player()
	_apply_player_cover_and_depth(_player)


func _apply_player_cover_and_depth(player_node: CharacterBody2D) -> void:
	if not is_instance_valid(player_node) or _last_cover_scale <= 0.0:
		return
	_player_cover_sync.apply(player_node, _last_cover_scale, _last_bg_position)
	# Extra walk-Y factor on top of cover-sync; do not touch authored_*.
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
		# Outside: keep last size (100% top exit / 150% bottom exit).
		return
	var t := clampf((local_pos.y + half.y) / rect_shape.size.y, 0.0, 1.0)
	_depth_factor = lerpf(1.0, vertical_far_scale, t)


func _peek_below_area(area: Area2D) -> Vector2:
	return InteractArrival.place_on_area(
		_player, area, InteractArrival.DEFAULT_T, Vector2.AXIS_X,
		InteractArrival.PeekEdge.BOTTOM, 12.0
	)


func _peek_above_area(area: Area2D) -> Vector2:
	return InteractArrival.place_on_area(
		_player, area, InteractArrival.DEFAULT_T, Vector2.AXIS_X,
		InteractArrival.PeekEdge.TOP, -12.0
	)


func _apply_arrival_on_area(
	player_node: CharacterBody2D,
	area: Area2D,
	along_axis: int,
	peek_edge: InteractArrival.PeekEdge,
	peek_margin: float
) -> void:
	player_node.global_position = InteractArrival.place_on_area(
		player_node, area, _arrival_t, along_axis, peek_edge, peek_margin
	)
	call_deferred("_clamp_arrived_player")


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_X)


func _arm_zone_grace(zone_id: String) -> void:
	match zone_id:
		"cafeteria":
			_cafeteria_zone_armed = false
		"lounge":
			_lounge_zone_armed = false
		"classroom":
			_classroom_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	match zone_id:
		"cafeteria":
			_cafeteria_zone_armed = true
		"lounge":
			_lounge_zone_armed = true
		"classroom":
			_classroom_zone_armed = true
	if _active_zone == zone_id:
		_show_interact_prompt()


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
