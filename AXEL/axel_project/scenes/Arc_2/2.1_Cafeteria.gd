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
## Kitchen return: Player node texture Y (door is ~2040×90). X still follows leave t.
const KITCHEN_STAND_TEX_Y := 90.0
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
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _is_transitioning := false
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
## 0..1 along the source [E] box. Taken once in restore so layout cannot drop it.
var _arrival_t := InteractArrival.DEFAULT_T
var _cover_layout_ready := false
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
	_apply_collected_table_memory()
	set_process(true)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.cafeteria_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	var cafeteria_side := GameManager.take_cafeteria_spawn_side()
	if cafeteria_side == "basement_left":
		_pending_basement_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_basement_peek_after_wake")
		return
	if cafeteria_side == "backyard_right":
		_pending_backyard_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_inside_arrival_after_wake")
		return
	if cafeteria_side == "classrooms_bottom":
		_pending_classrooms_peek = true
		# Consume leftover t, then pin to dest-box center (2.1↔2.4 exception).
		InteractArrival.take_arrival_t_or_default()
		_arrival_t = InteractArrival.DEFAULT_T
		if _cover_layout_ready:
			call_deferred("_apply_inside_arrival_after_wake")
		return
	if cafeteria_side == "table":
		_pending_table_peek = true
		call_deferred("_apply_table_peek_if_pending")
		return
	if GameManager.take_kitchen_spawn_side() == "kitchen_door":
		_pending_kitchen_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_kitchen_peek_after_wake")
		return
	if GameManager.has_cafeteria_table_return_pos():
		call_deferred("_apply_table_return_if_pending")
		return


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if GameManager.cafeteria_enter_line_seen:
		_enter_dialogue_pending = false
		return
	GameManager.set_cafeteria_enter_line_seen(true)
	_enter_dialogue_pending = false
	await _top_dialogue.show_line(ENTER_LINE, 3.0)


func _process(_delta: float) -> void:
	if not _arrival_latched_zone.is_empty() and InteractZoneGate.movement_pressed():
		_arrival_latched_zone = ""
	_refresh_active_zone()


func _refresh_active_zone() -> void:
	if _is_transitioning:
		return
	var prev := _active_zone
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
		_active_zone = ""
		if not prev.is_empty():
			_hide_interact_prompt()
		return
	if not _arrival_latched_zone.is_empty():
		_active_zone = _arrival_latched_zone
	else:
		_active_zone = ""
		for zone_id in ["table", "kitchen", "return", "backyard", "classrooms"]:
			if InteractZoneGate.body_in_area(_zone_area(zone_id), _player):
				_active_zone = zone_id
				break
	if _active_zone != prev:
		if _active_zone.is_empty():
			_hide_interact_prompt()
		else:
			_show_interact_prompt()
	elif not _active_zone.is_empty():
		_show_interact_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	_refresh_active_zone()
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
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
			_begin_go_to_kitchen()
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
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
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
	if is_instance_valid(_player) and is_instance_valid(_return_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _return_area, Vector2.AXIS_Y)
		)
	GameManager.set_basement_spawn_side("cafeteria_right")
	_begin_scene_change(BASEMENT_DOOR_SCENE)


func _begin_go_to_kitchen() -> void:
	if is_instance_valid(_player) and is_instance_valid(_kitchen_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _kitchen_area, Vector2.AXIS_X)
		)
	GameManager.set_kitchen_spawn_side("cafeteria_door")
	_begin_scene_change(KITCHEN_SCENE)


func _begin_go_to_backyard() -> void:
	if is_instance_valid(_player) and is_instance_valid(_backyard_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _backyard_area, Vector2.AXIS_Y)
		)
	GameManager.set_backyard_spawn_side("cafeteria_door")
	_begin_scene_change(BACKYARD_SCENE)


func _begin_go_to_classrooms() -> void:
	# Always land at 2.4 CafeteriaInteractArea center — do not save leave t.
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
	# Always remap Player node (1.2 style). Door / memory overwrite runs deferred.
	PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	_sync_memory_indicator()
	_cover_layout_ready = true
	call_deferred("_wake_static_colliders")
	call_deferred("_configure_table_occlusion_masks")
	if GameManager.has_cafeteria_table_return_pos():
		call_deferred("_apply_table_return_if_pending")
	elif _pending_basement_peek:
		call_deferred("_apply_basement_peek_after_wake")
	elif _pending_kitchen_peek:
		call_deferred("_apply_kitchen_peek_after_wake")
	elif _pending_backyard_peek or _pending_classrooms_peek:
		call_deferred("_apply_inside_arrival_after_wake")
	elif _pending_table_peek:
		call_deferred("_apply_table_peek_if_pending")


func _apply_inside_arrival_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _pending_backyard_peek:
		_apply_backyard_peek_if_pending()
	elif _pending_classrooms_peek:
		_apply_classrooms_peek_if_pending()


func _apply_basement_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_basement_peek_if_pending()


func _apply_kitchen_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_kitchen_peek_if_pending()


func _apply_table_return_if_pending() -> void:
	if not GameManager.has_cafeteria_table_return_pos() or not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	_player.global_position = env.to_global(GameManager.take_cafeteria_table_return_pos())


func _apply_basement_peek_if_pending() -> void:
	if not _pending_basement_peek or not is_instance_valid(_player):
		return
	_pending_basement_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_return_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		BASEMENT_PEEK_MARGIN_PX
	)
	_arrival_latched_zone = "return"
	call_deferred("_clamp_arrived_player")
	_arm_return_zone_grace()


func _apply_kitchen_peek_if_pending() -> void:
	if not _pending_kitchen_peek or not is_instance_valid(_player):
		return
	_pending_kitchen_peek = false
	# Kitchen door: Player node at texture Y 90, X from leave t (~2040).
	# Stand the node there (not the feet circle). Skip wall clamp.
	var feet_landed := InteractArrival.place_on_area(
		_player,
		_kitchen_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.CENTER_Y,
		0.0
	)
	var front := _player.get_node_or_null("CollisionFront") as CollisionShape2D
	if front != null:
		var offset := _player.to_global(front.position) - _player.global_position
		_player.global_position = feet_landed + offset
	else:
		_player.global_position = feet_landed
	var env := $WalkableWorld/EnvironmentColliders as Node2D
	var tex := env.to_local(_player.global_position)
	tex.y = KITCHEN_STAND_TEX_Y
	_player.global_position = env.to_global(tex)
	_arrival_latched_zone = "kitchen"
	_arm_kitchen_zone_grace()


func _apply_backyard_peek_if_pending() -> void:
	if not _pending_backyard_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_backyard_peek = false
	InteractArrival.apply_arrival_inside(
		_player,
		_backyard_area,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.LEFT,
		0.5
	)
	_arrival_latched_zone = "backyard"
	_arm_backyard_zone_grace()


func _apply_classrooms_peek_if_pending() -> void:
	if not _pending_classrooms_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_classrooms_peek = false
	# Live ClassroomsInteractArea center. Skip wall clearance so Y stays on the box.
	_player.global_position = InteractArrival.place_in_area(
		_player,
		_classrooms_area,
		InteractArrival.DEFAULT_T,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.CENTER_Y,
		0.5
	)
	_arrival_latched_zone = "classrooms"
	_arm_classrooms_zone_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


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


func _arm_kitchen_zone_grace() -> void:
	_kitchen_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_kitchen_zone_armed = true


func _arm_backyard_zone_grace() -> void:
	_backyard_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_backyard_zone_armed = true


func _arm_classrooms_zone_grace() -> void:
	_classrooms_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_classrooms_zone_armed = true


func _arm_table_zone_grace() -> void:
	_table_zone_armed = false
	await get_tree().create_timer(RETURN_ZONE_GRACE_SEC).timeout
	_table_zone_armed = true


func _table_peek_global() -> Vector2:
	if not is_instance_valid(_table_area):
		return _player.global_position
	var shape := _table_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		return shape.global_position
	return _table_area.global_position


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
