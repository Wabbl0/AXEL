extends Node2D

const ENTER_LINE := "Even through all the chaos you can hear the chattering students of the past."
const TABLE_SCENE := "res://scenes/Arc_2/2.2_CafeteriaMemory.tscn"
const TABLE_MEMORY_KEY := "cafeteria_memory"
const KITCHEN_SCENE := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const BASEMENT_DOOR_SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const BACKYARD_SCENE := "res://scenes/Arc_3/3.1_Backyard.tscn"
const CLASSROOMS_CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
## Just right of ReturnInteractArea so Mike peeks inside the room from the left door.
const BASEMENT_PEEK_MARGIN_PX := 12.0
## Just below KitchenInteractArea so Mike peeks next to the kitchen doorway.
## Shifted up 100px from the doorway edge per design tweak.
const KITCHEN_PEEK_MARGIN_PX := -88.0
## Just left of BackyardInteractArea so Mike peeks inside from the right door.
const BACKYARD_PEEK_MARGIN_PX := -12.0
## Just above ClassroomsInteractArea so Mike peeks inside from the bottom door.
const CLASSROOMS_PEEK_MARGIN_PX := -12.0
const RETURN_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _memory_indicator: Node2D = get_node_or_null("PlayerLayer/MemoryIndicator")

var _table_area: Area2D
var _kitchen_area: Area2D
var _return_area: Area2D
var _backyard_area: Area2D
var _classrooms_area: Area2D
var _active_zone: String = ""
var _is_transitioning := false
var _player_spawn_applied := false
var _pending_basement_peek := false
var _pending_kitchen_peek := false
var _pending_backyard_peek := false
var _pending_classrooms_peek := false
var _pending_table_peek := false
var _return_zone_armed := true
var _kitchen_zone_armed := true
var _backyard_zone_armed := true
var _classrooms_zone_armed := true
var _table_zone_armed := true
## Texture-pixel position captured from the MemoryIndicator node's editor position.
var _memory_indicator_tex := Vector2.ZERO
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	if is_instance_valid(_memory_indicator):
		_memory_indicator_tex = _memory_indicator.position
	_player_cover_sync.bind_from_player(_player)
	var _bg := $WalkableWorld/Background as Sprite2D
	var _cam := $Camera2D
	_player_cover_sync.bind_design_from_background(
		_bg, _cam.fit_mode, _cam.background_y
	)
	if is_instance_valid(_memory_indicator):
		_player_cover_sync.bind_extra_node(_memory_indicator)
	_table_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/TableInteractArea"
	) as Area2D
	_kitchen_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KitchenInteractArea"
	) as Area2D
	_return_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ReturnInteractArea"
	) as Area2D
	_backyard_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/BackyardInteractArea"
	) as Area2D
	_classrooms_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ClassroomsInteractArea"
	) as Area2D
	_connect_zone(_table_area, "table")
	_connect_zone(_kitchen_area, "kitchen")
	_connect_zone(_return_area, "return")
	_connect_zone(_backyard_area, "backyard")
	_connect_zone(_classrooms_area, "classrooms")
	_apply_collected_table_memory()
	var cafeteria_side := GameManager.take_cafeteria_spawn_side()
	if cafeteria_side == "basement_left":
		_pending_basement_peek = true
	elif cafeteria_side == "backyard_right":
		_pending_backyard_peek = true
	elif cafeteria_side == "classrooms_bottom":
		_pending_classrooms_peek = true
	elif cafeteria_side == "table":
		_pending_table_peek = true
	elif GameManager.take_kitchen_spawn_side() == "kitchen_door":
		_pending_kitchen_peek = true
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
	if GameManager.cafeteria_enter_line_seen:
		return
	GameManager.set_cafeteria_enter_line_seen(true)
	await _top_dialogue.show_line(ENTER_LINE, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "return" and not _return_zone_armed:
		return
	if _active_zone == "kitchen" and not _kitchen_zone_armed:
		return
	if _active_zone == "backyard" and not _backyard_zone_armed:
		return
	if _active_zone == "classrooms" and not _classrooms_zone_armed:
		return
	if _active_zone == "table" and not _table_zone_armed:
		return
	match _active_zone:
		"table":
			_save_table_return_pos()
			_begin_scene_change(TABLE_SCENE)
		"kitchen":
			_begin_scene_change(KITCHEN_SCENE)
		"return":
			_begin_return_to_basement()
		"backyard":
			_begin_go_to_backyard()
		"classrooms":
			_begin_go_to_classrooms()


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
		"backyard":
			return _backyard_area
		"classrooms":
			return _classrooms_area
		_:
			return null


func _interact_anchor() -> Vector2:
	var area := _zone_area(_active_zone)
	if not is_instance_valid(area):
		return Vector2.ZERO
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var anchor := area.global_position
	if shape != null and shape.shape is RectangleShape2D:
		anchor = shape.global_position
	return anchor


## MemoryIndicator's editor position is texture-pixel space (same as colliders
## and the player spawn); re-derive its world position from that captured
## offset each time the background layout (re)applies, so dragging the node
## in the editor is what actually moves it, not a hardcoded/computed anchor.
func _sync_memory_indicator() -> void:
	if not is_instance_valid(_memory_indicator) or not _memory_indicator.visible:
		return
	var env := $WalkableWorld/EnvironmentColliders
	_memory_indicator.global_position = env.to_global(_memory_indicator_tex)


func _show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
		return
	if _active_zone == "return" and not _return_zone_armed:
		return
	if _active_zone == "kitchen" and not _kitchen_zone_armed:
		return
	if _active_zone == "backyard" and not _backyard_zone_armed:
		return
	if _active_zone == "classrooms" and not _classrooms_zone_armed:
		return
	if _active_zone == "table" and not _table_zone_armed:
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


func _begin_return_to_basement() -> void:
	GameManager.set_basement_spawn_side("cafeteria_right")
	_begin_scene_change(BASEMENT_DOOR_SCENE)


func _begin_go_to_backyard() -> void:
	GameManager.set_backyard_spawn_side("cafeteria_door")
	_begin_scene_change(BACKYARD_SCENE)


func _begin_go_to_classrooms() -> void:
	GameManager.set_classrooms_corridor_spawn_side("cafeteria_door")
	_begin_scene_change(CLASSROOMS_CORRIDOR_SCENE)


func _save_table_return_pos() -> void:
	if not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	GameManager.set_cafeteria_table_return_pos(env.to_local(_player.global_position))


func _apply_collected_table_memory() -> void:
	if not GameManager.has_memory_scene(TABLE_MEMORY_KEY):
		return
	if is_instance_valid(_memory_indicator):
		_memory_indicator.visible = false
	if not is_instance_valid(_table_area):
		return
	_table_area.monitoring = false
	_table_area.monitorable = false
	var shape := _table_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true


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
	if not _player_spawn_applied:
		if GameManager.has_cafeteria_table_return_pos():
			player_node.global_position = env.to_global(
				GameManager.take_cafeteria_table_return_pos()
			)
		elif _pending_basement_peek:
			player_node.global_position = _basement_left_peek_global()
			_pending_basement_peek = false
			_arm_return_zone_grace()
		elif _pending_kitchen_peek:
			player_node.global_position = _kitchen_door_peek_global()
			_pending_kitchen_peek = false
			_arm_kitchen_zone_grace()
		elif _pending_backyard_peek:
			player_node.global_position = _backyard_door_peek_global()
			_pending_backyard_peek = false
			_arm_backyard_zone_grace()
		elif _pending_classrooms_peek:
			player_node.global_position = _classrooms_door_peek_global()
			_pending_classrooms_peek = false
			_arm_classrooms_zone_grace()
		elif _pending_table_peek:
			player_node.global_position = _table_peek_global()
			_pending_table_peek = false
			_arm_table_zone_grace()
		else:
			PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
		_player_spawn_applied = true
	else:
		PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	_sync_memory_indicator()
	call_deferred("_wake_static_colliders")
	call_deferred("_configure_table_occlusion_masks")
	if GameManager.has_cafeteria_table_return_pos():
		call_deferred("_apply_table_return_if_pending")
	elif _pending_basement_peek:
		call_deferred("_apply_basement_peek_if_pending")
	elif _pending_kitchen_peek:
		call_deferred("_apply_kitchen_peek_if_pending")
	elif _pending_backyard_peek:
		call_deferred("_apply_backyard_peek_if_pending")
	elif _pending_classrooms_peek:
		call_deferred("_apply_classrooms_peek_if_pending")
	elif _pending_table_peek:
		call_deferred("_apply_table_peek_if_pending")


func _apply_table_return_if_pending() -> void:
	if not GameManager.has_cafeteria_table_return_pos() or not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	_player.global_position = env.to_global(GameManager.take_cafeteria_table_return_pos())


func _apply_basement_peek_if_pending() -> void:
	if not _pending_basement_peek or not is_instance_valid(_player):
		return
	_pending_basement_peek = false
	_player.global_position = _basement_left_peek_global()
	_arm_return_zone_grace()


func _apply_kitchen_peek_if_pending() -> void:
	if not _pending_kitchen_peek or not is_instance_valid(_player):
		return
	_pending_kitchen_peek = false
	_player.global_position = _kitchen_door_peek_global()
	_arm_kitchen_zone_grace()


func _apply_backyard_peek_if_pending() -> void:
	if not _pending_backyard_peek or not is_instance_valid(_player):
		return
	_pending_backyard_peek = false
	_player.global_position = _backyard_door_peek_global()
	_arm_backyard_zone_grace()


func _apply_classrooms_peek_if_pending() -> void:
	if not _pending_classrooms_peek or not is_instance_valid(_player):
		return
	_pending_classrooms_peek = false
	_player.global_position = _classrooms_door_peek_global()
	_arm_classrooms_zone_grace()


func _apply_table_peek_if_pending() -> void:
	if not _pending_table_peek or not is_instance_valid(_player):
		return
	_pending_table_peek = false
	_player.global_position = _table_peek_global()
	_arm_table_zone_grace()


func _arm_return_zone_grace() -> void:
	_return_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_return_zone_armed = true
	if _active_zone == "return":
		_show_interact_prompt()


func _arm_kitchen_zone_grace() -> void:
	_kitchen_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_kitchen_zone_armed = true
	if _active_zone == "kitchen":
		_show_interact_prompt()


func _arm_backyard_zone_grace() -> void:
	_backyard_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_backyard_zone_armed = true
	if _active_zone == "backyard":
		_show_interact_prompt()


func _arm_classrooms_zone_grace() -> void:
	_classrooms_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_classrooms_zone_armed = true
	if _active_zone == "classrooms":
		_show_interact_prompt()


func _arm_table_zone_grace() -> void:
	_table_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_table_zone_armed = true
	if _active_zone == "table":
		_show_interact_prompt()


func _basement_left_peek_global() -> Vector2:
	var pos := _player.global_position
	var right_edge := _return_interact_right_edge_x()
	if right_edge > -INF:
		pos.x = right_edge + BASEMENT_PEEK_MARGIN_PX
	if is_instance_valid(_return_area):
		var shape := _return_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			pos.y = shape.global_position.y
		else:
			pos.y = _return_area.global_position.y
	return pos


func _kitchen_door_peek_global() -> Vector2:
	var pos := _player.global_position
	var bottom_edge := _kitchen_interact_bottom_edge_y()
	if bottom_edge > -INF:
		pos.y = bottom_edge + KITCHEN_PEEK_MARGIN_PX
	if is_instance_valid(_kitchen_area):
		var shape := _kitchen_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			pos.x = shape.global_position.x
		else:
			pos.x = _kitchen_area.global_position.x
	return pos


func _backyard_door_peek_global() -> Vector2:
	var pos := _player.global_position
	var left_edge := _backyard_interact_left_edge_x()
	if left_edge < INF:
		pos.x = left_edge + BACKYARD_PEEK_MARGIN_PX
	if is_instance_valid(_backyard_area):
		var shape := _backyard_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			pos.y = shape.global_position.y
		else:
			pos.y = _backyard_area.global_position.y
	return pos


func _classrooms_door_peek_global() -> Vector2:
	var pos := _player.global_position
	var top_edge := _classrooms_interact_top_edge_y()
	if top_edge < INF:
		pos.y = top_edge + CLASSROOMS_PEEK_MARGIN_PX
	if is_instance_valid(_classrooms_area):
		var shape := _classrooms_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			pos.x = shape.global_position.x
		else:
			pos.x = _classrooms_area.global_position.x
	return pos


func _table_peek_global() -> Vector2:
	if not is_instance_valid(_table_area):
		return _player.global_position
	var shape := _table_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		return shape.global_position
	return _table_area.global_position


func _return_interact_right_edge_x() -> float:
	if not is_instance_valid(_return_area):
		return -INF
	var shape := _return_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return -INF
	var half_width: float = (shape.shape as RectangleShape2D).size.x * 0.5
	return _return_area.to_global(
		Vector2(shape.position.x + half_width, shape.position.y)
	).x


func _kitchen_interact_bottom_edge_y() -> float:
	if not is_instance_valid(_kitchen_area):
		return -INF
	var shape := _kitchen_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return -INF
	var half_height: float = (shape.shape as RectangleShape2D).size.y * 0.5
	return _kitchen_area.to_global(
		Vector2(shape.position.x, shape.position.y + half_height)
	).y


func _backyard_interact_left_edge_x() -> float:
	if not is_instance_valid(_backyard_area):
		return INF
	var shape := _backyard_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return INF
	var half_width: float = (shape.shape as RectangleShape2D).size.x * 0.5
	return _backyard_area.to_global(
		Vector2(shape.position.x - half_width, shape.position.y)
	).x


func _classrooms_interact_top_edge_y() -> float:
	if not is_instance_valid(_classrooms_area):
		return INF
	var shape := _classrooms_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		return INF
	var half_height: float = (shape.shape as RectangleShape2D).size.y * 0.5
	return _classrooms_area.to_global(
		Vector2(shape.position.x, shape.position.y - half_height)
	).y


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position


func _configure_table_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var zones: Array[Area2D] = []
	for zone_name in [
		"TableBlockLeft_Behind",
		"ChairBlockBottom_Behind",
		"ChairBlockTop_Behind",
	]:
		var zone := get_node_or_null(
			"WalkableWorld/EnvironmentColliders/%s" % zone_name
		) as Area2D
		zones.append(zone)
	while zones.size() < 3:
		zones.append(null)
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	var cutoffs: Array[float] = []
	for zone in zones:
		var poly := PackedVector2Array()
		var feather := 0.0
		if is_instance_valid(zone) and zone.has_method("get_shader_polygon"):
			poly = zone.call("get_shader_polygon")
			feather = float(zone.get("feather_px"))
		polys.append(poly)
		feathers.append(feather)
		cutoffs.append(_occlusion_y_cutoff(zone))
	_player.call(
		"configure_leaf_occlusion_polygons",
		polys[0],
		polys[1],
		feathers[0],
		feathers[1],
		_LEAF_FADE_ALPHA,
		cutoffs[0],
		cutoffs[1],
		_LEAF_GATE_SOFTNESS,
		polys[2],
		feathers[2],
		cutoffs[2],
	)


func _occlusion_y_cutoff(behind: Area2D) -> float:
	if not is_instance_valid(behind):
		return 1e9
	var polygon_node := behind.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return 1e9
	var max_y := -INF
	for local_point in polygon_node.polygon:
		max_y = maxf(max_y, polygon_node.to_global(local_point).y)
	if max_y == -INF:
		return 1e9
	return max_y
