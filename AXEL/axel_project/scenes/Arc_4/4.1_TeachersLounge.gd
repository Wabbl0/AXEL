extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const LOUNGE_SELF_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const MEMORY_SCENE := "res://scenes/Arc_4/4.2_TeachersMemory.tscn"
const MEMORY_KEY := "teachers_memory"
const ENTER_LINES := [
	"You always wondered what the teachers were doing behind closed doors.",
	"Pervert.",
]
const KEY_NEAR_LINES := [
	"There's a key.",
	"Why hasn't anyone nicked it yet?",
]
const KEY_PICKUP_LINES := [
	"You take the key.",
	"Like a good little boy.",
]
const LIAR_LINES := [
	"Liar. You knew exactly where he was.",
]
const DOOR_ZONE_GRACE_SEC := 0.15
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const _BEHIND_ZONE_NAMES: PackedStringArray = [
	"TableBlock_Behind",
	"ChairBlock_Behind",
]

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _memory_indicator: Node2D = get_node_or_null("PlayerLayer/MemoryIndicator")

var _door_interact_area: Area2D
var _key_near_area: Area2D
var _key_interact_area: Area2D
var _memory_area: Area2D
var _active_zone: String = ""
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _is_transitioning := false
var _key_line_running := false
var _key_near_pending := false
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _cover_layout_ready := false
var _door_zone_armed := true
var _memory_zone_armed := true
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
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_key_near_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KeyNearArea"
	) as Area2D
	_key_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/KeyInteractArea"
	) as Area2D
	_memory_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/MemoryInteractArea"
	) as Area2D
	_apply_collected_memory()
	_apply_key_visibility()
	set_process(true)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	_enter_dialogue_pending = _will_play_enter_dialogue()
	call_deferred("_play_enter_dialogue")


func _will_play_enter_dialogue() -> bool:
	if not GameManager.teachers_lounge_enter_line_seen:
		return true
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.teachers_liar_line_seen:
		return true
	return false


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_teachers_lounge_spawn_side() == "corridor_door":
		_pending_door_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		if _cover_layout_ready:
			call_deferred("_apply_door_peek_after_wake")
		return
	if GameManager.has_teachers_lounge_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")
		return


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if not GameManager.teachers_lounge_enter_line_seen:
		GameManager.set_teachers_lounge_enter_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(ENTER_LINES)
		await _try_play_pending_key_near()
		return
	if GameManager.has_memory_scene(MEMORY_KEY) and not GameManager.teachers_liar_line_seen:
		GameManager.set_teachers_liar_line_seen(true)
		_enter_dialogue_pending = false
		await _top_dialogue.show_lines(LIAR_LINES)
		await _try_play_pending_key_near()
		return
	_enter_dialogue_pending = false


func _process(_delta: float) -> void:
	if not _arrival_latched_zone.is_empty() and InteractZoneGate.movement_pressed():
		_arrival_latched_zone = ""
	_refresh_active_zone()
	_check_key_near()


func _check_key_near() -> void:
	if GameManager.teachers_key_line_seen or _key_line_running or _is_transitioning:
		return
	if not InteractZoneGate.body_in_area(_key_near_area, _player):
		_key_near_pending = false
		return
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
		_key_near_pending = true
		return
	_key_line_running = true
	call_deferred("_play_key_near_async")


func _try_play_pending_key_near() -> void:
	if not _key_near_pending:
		return
	if not InteractZoneGate.body_in_area(_key_near_area, _player):
		_key_near_pending = false
		return
	if GameManager.teachers_key_line_seen or _key_line_running:
		_key_near_pending = false
		return
	_key_line_running = true
	await _play_key_near_async()


func _play_key_near_async() -> void:
	if GameManager.teachers_key_line_seen:
		_key_line_running = false
		return
	if not is_instance_valid(_top_dialogue):
		_key_line_running = false
		return
	_key_near_pending = false
	_key_line_running = true
	GameManager.set_teachers_key_line_seen(true)
	await _top_dialogue.show_lines(KEY_NEAR_LINES)
	_key_line_running = false


func _refresh_active_zone() -> void:
	if _is_transitioning:
		return
	var prev := _active_zone
	if not _arrival_latched_zone.is_empty():
		_active_zone = _arrival_latched_zone
	else:
		_active_zone = ""
		if (
			InteractZoneGate.body_in_area(_key_interact_area, _player)
			and not GameManager.get_flag("hasKey")
		):
			_active_zone = "key"
		elif InteractZoneGate.body_in_area(_memory_area, _player):
			_active_zone = "memory"
		elif InteractZoneGate.body_in_area(_door_interact_area, _player):
			_active_zone = "door"
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
	if (
		_enter_dialogue_pending
		or _key_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	if _active_zone == "memory" and not _memory_zone_armed:
		return
	match _active_zone:
		"key":
			_key_line_running = true
			call_deferred("_pickup_key_async")
		"memory":
			_save_memory_return_pos()
			_begin_scene_change(MEMORY_SCENE)
		"door":
			_begin_return_to_corridor()


func _is_interaction_event(event: InputEvent) -> bool:

	return event.is_action_pressed("interact")


func _zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"key":
			return _key_interact_area
		"memory":
			return _memory_area
		"door":
			return _door_interact_area
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


func _sync_memory_indicator() -> void:
	if not is_instance_valid(_memory_indicator) or not _memory_indicator.visible:
		return
	var env := $WalkableWorld/EnvironmentColliders
	_memory_indicator.global_position = env.to_global(_memory_indicator_tex)


func _show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
		return
	if _active_zone == "key" and GameManager.get_flag("hasKey"):
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


func _apply_key_visibility() -> void:
	if not is_instance_valid(_key_interact_area):
		return
	if not GameManager.get_flag("hasKey"):
		return
	_key_interact_area.visible = false
	_key_interact_area.monitoring = false
	_key_interact_area.monitorable = false
	var shape := _key_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true


func _pickup_key_async() -> void:
	if GameManager.get_flag("hasKey"):
		_key_line_running = false
		return
	_key_line_running = true
	_hide_interact_prompt_immediate()
	GameManager.set_flag("hasKey", true)
	GameManager.add_inventory_item("hasKey", "Teacher Key")
	_apply_key_visibility()
	await _top_dialogue.show_lines(KEY_PICKUP_LINES)
	_key_line_running = false
	if _active_zone == "key":
		_active_zone = ""

	var world := get_node_or_null("/root/AxelWorld")
	if world != null and bool(
		world.call("start_lore_fight", "hasKey", LOUNGE_SELF_SCENE, true)
	):
		_hide_interact_prompt_immediate()


func _save_memory_return_pos() -> void:
	if not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	GameManager.set_teachers_lounge_memory_return_pos(env.to_local(_player.global_position))


func _apply_collected_memory() -> void:
	if not GameManager.has_memory_scene(MEMORY_KEY):
		return
	if is_instance_valid(_memory_indicator):
		_memory_indicator.visible = false
	if not is_instance_valid(_memory_area):
		return
	_memory_area.monitoring = false
	_memory_area.monitorable = false
	var shape := _memory_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true


func _begin_return_to_corridor() -> void:
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_X
			)
		)
	GameManager.set_classrooms_corridor_spawn_side("lounge_door")
	_begin_scene_change(CORRIDOR_SCENE)


func _begin_scene_change(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_hide_interact_prompt_immediate()
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
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	_sync_memory_indicator()
	_cover_layout_ready = true
	call_deferred("_wake_static_colliders")
	call_deferred("_configure_behind_occlusion_masks")
	if GameManager.has_teachers_lounge_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_door_peek_if_pending()


func _apply_memory_return_if_pending() -> void:
	if not GameManager.has_teachers_lounge_memory_return_pos() or not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	_player.global_position = env.to_global(GameManager.take_teachers_lounge_memory_return_pos())


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
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.BOTTOM,
		0.5
	)
	_arrival_latched_zone = "door"
	_arm_door_zone_grace()


func _arm_door_zone_grace() -> void:
	_door_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	_door_zone_armed = true


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D or child is Area2D:
			child.position = child.position


func _configure_behind_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	var cutoffs: Array[float] = []
	for zone_name in _BEHIND_ZONE_NAMES:
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
