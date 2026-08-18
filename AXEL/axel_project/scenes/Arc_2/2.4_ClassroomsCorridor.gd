extends Node2D

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const TEACHERS_LOUNGE_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"
const FUTURE_DOOR_LINE := "Not yet."
const DOOR_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _cafeteria_area: Area2D
var _lounge_area: Area2D
var _classroom_area: Area2D
var _future_area: Area2D
var _active_zone: String = ""
var _is_transitioning := false
var _future_line_running := false
var _player_spawn_applied := false
var _pending_spawn_side := ""
var _cafeteria_zone_armed := true
var _lounge_zone_armed := true
var _classroom_zone_armed := true
var _player_spawn_tex := Vector2.ZERO
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	_player_spawn_tex = _player.position
	_player_cover_sync.bind_from_player(_player)
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
	_connect_zone(_cafeteria_area, "cafeteria")
	_connect_zone(_lounge_area, "lounge")
	_connect_zone(_classroom_area, "classroom")
	_connect_zone(_future_area, "future")
	_pending_spawn_side = GameManager.take_classrooms_corridor_spawn_side()
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)


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
		"future":
			_begin_future_door_stub()


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
		"future":
			return not _future_line_running
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


func _future_dialogue_busy() -> bool:
	if _future_line_running:
		return true
	if not is_instance_valid(_top_dialogue):
		return false
	if _top_dialogue.has_method("is_sequence_busy") and _top_dialogue.is_sequence_busy():
		return true
	if _top_dialogue.has_method("is_bar_visible") and _top_dialogue.is_bar_visible():
		return true
	return false


func _begin_future_door_stub() -> void:
	# Canon: Future_1_2_Door stays stub-only until legacy corridor link is approved.
	if _future_dialogue_busy():
		_hide_interact_prompt_immediate()
		return
	_future_line_running = true
	_hide_interact_prompt_immediate()
	await _top_dialogue.show_line(FUTURE_DOOR_LINE, 3.0)
	_future_line_running = false
	if _active_zone == "future":
		_show_interact_prompt()


func _begin_go_to_cafeteria() -> void:
	GameManager.set_cafeteria_spawn_side("classrooms_bottom")
	_begin_scene_change(CAFETERIA_SCENE)


func _begin_go_to_lounge() -> void:
	GameManager.set_teachers_lounge_spawn_side("corridor_door")
	_begin_scene_change(TEACHERS_LOUNGE_SCENE)


func _begin_go_to_classroom() -> void:
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
	var tex_pos := Vector2.ZERO
	var remap_pos := _player_spawn_applied and _player_cover_sync.has_reference()
	if remap_pos:
		tex_pos = env.to_local(player_node.global_position)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	if not _player_spawn_applied:
		match _pending_spawn_side:
			"cafeteria_door":
				player_node.global_position = _peek_below_area(_cafeteria_area)
				_arm_zone_grace("cafeteria")
			"lounge_door":
				player_node.global_position = _peek_above_area(_lounge_area)
				_arm_zone_grace("lounge")
			"classroom_door":
				player_node.global_position = _peek_above_area(_classroom_area)
				_arm_zone_grace("classroom")
			_:
				player_node.global_position = env.to_global(_player_spawn_tex)
		_pending_spawn_side = ""
		_player_spawn_applied = true
	elif remap_pos:
		player_node.global_position = env.to_global(tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	call_deferred("_wake_static_colliders")


func _peek_below_area(area: Area2D) -> Vector2:
	var pos := _player.global_position
	if not is_instance_valid(area):
		return pos
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return area.global_position
	var half_height: float = (shape.shape as RectangleShape2D).size.y * 0.5
	pos.y = area.to_global(Vector2(shape.position.x, shape.position.y + half_height + 12.0)).y
	pos.x = shape.global_position.x
	return pos


func _peek_above_area(area: Area2D) -> Vector2:
	var pos := _player.global_position
	if not is_instance_valid(area):
		return pos
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return area.global_position
	var half_height: float = (shape.shape as RectangleShape2D).size.y * 0.5
	pos.y = area.to_global(Vector2(shape.position.x, shape.position.y - half_height - 12.0)).y
	pos.x = shape.global_position.x
	return pos


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
