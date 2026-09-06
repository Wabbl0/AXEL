extends Node2D

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const DESK_SCENE := "res://scenes/Arc_5/5.2_ClassroomDesk.tscn"
const BOARD_SCENE := "res://scenes/Arc_5/5.3_ClassroomBoard.tscn"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const _BEHIND_ZONE_NAMES: PackedStringArray = [
	"FurnitureBlock6_Behind",
	"FurnitureBlock7_Behind",
	"FurnitureBlock8_Behind",
	"FurnitureBlock9_Behind",
]
const _BEHIND_GATE_BODIES: PackedStringArray = [
	"FurnitureBlock6",
	"FurnitureBlock7",
	"FurnitureBlock8",
	"FurnitureBlock9",
]
const ENTER_LINES := [
	"This is where the shit went down.",
	"If shit going down is you, highly caffinated, ignoring your teachers and usually skipping class to go for a smoke.",
	"How did you ever get anywhere in life?",
]
const BOARD_LINES := [
	"On the board there are weird ass symbols and equations.",
	"You can only make out one question:",
	"\"[something relevant that is only learned through playing the slots]\"",
]
const DOOR_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _memory_indicator: Node2D = get_node_or_null("PlayerLayer/MemoryIndicator")

var _door_interact_area: Area2D
var _desk_interact_area: Area2D
var _board_interact_area: Area2D
var _board_glow: Node2D
var _board_glow_tween: Tween
var _active_zone: String = ""
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _board_line_running := false
var _is_transitioning := false
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _cover_layout_ready := false
var _door_zone_armed := true
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
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_desk_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DeskInteractArea"
	) as Area2D
	_board_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/BoardInteractArea"
	) as Area2D
	_board_glow = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/BoardGlow"
	) as Node2D
	_ensure_desk_area_live()
	_apply_desk_seen_state()
	_start_board_glow()
	set_process(true)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.classroom_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_classroom_spawn_side() == "corridor_door":
		_pending_door_peek = true
		# Consume leftover t, then pin to dest-box center (same as 2.1→2.4).
		# Sliding t on Y parked Front in DoorWall at the top-right.
		InteractArrival.take_arrival_t_or_default()
		_arrival_t = InteractArrival.DEFAULT_T
		if _cover_layout_ready:
			call_deferred("_apply_door_peek_after_wake")
		return
	if GameManager.has_classroom_desk_return_pos():
		call_deferred("_apply_desk_return_if_pending")
		return


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	_top_dialogue.visible = true
	if GameManager.classroom_enter_line_seen:
		_enter_dialogue_pending = false
		return
	GameManager.set_classroom_enter_line_seen(true)
	_enter_dialogue_pending = false
	await _top_dialogue.show_lines(ENTER_LINES)


func _process(_delta: float) -> void:
	if not _arrival_latched_zone.is_empty() and InteractZoneGate.movement_pressed():
		_arrival_latched_zone = ""
	_refresh_active_zone()


func _refresh_active_zone() -> void:
	if _is_transitioning:
		return
	var prev := _active_zone
	if (
		_enter_dialogue_pending
		or _board_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		_active_zone = ""
		if not prev.is_empty():
			_hide_interact_prompt()
		return
	if not _arrival_latched_zone.is_empty():
		_active_zone = _arrival_latched_zone
	else:
		_active_zone = ""
		if InteractZoneGate.body_in_area(_door_interact_area, _player):
			_active_zone = "door"
		elif (
			InteractZoneGate.body_in_area(_desk_interact_area, _player)
			and not GameManager.classroom_desk_seen
		):
			_active_zone = "desk"
		elif InteractZoneGate.body_in_area(_board_interact_area, _player):
			_active_zone = "board"
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
		or _board_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	if _active_zone == "door":
		_begin_return_to_corridor()
	elif _active_zone == "desk":
		_begin_go_to_desk()
	elif _active_zone == "board":
		_begin_look_at_board()


func _is_interaction_event(event: InputEvent) -> bool:
	# Named InputMap action (E/Space/Enter + gamepad A). Excludes echo presses.
	return event.is_action_pressed("interact")


func _zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"door":
			return _door_interact_area
		"desk":
			return _desk_interact_area
		"board":
			return _board_interact_area
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


func _show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
		return
	if (
		_enter_dialogue_pending
		or _board_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
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


func _begin_return_to_corridor() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_Y
			)
		)
	GameManager.set_classrooms_corridor_spawn_side("classroom_door")
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CORRIDOR_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CORRIDOR_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _save_desk_return_pos() -> void:
	if not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	GameManager.set_classroom_desk_return_pos(env.to_local(_player.global_position))


func _begin_look_at_board() -> void:
	if _is_transitioning or _board_line_running:
		return
	if not is_instance_valid(_top_dialogue):
		return
	_board_line_running = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	await _top_dialogue.show_lines(BOARD_LINES)
	_board_line_running = false
	if GameManager.get_flag("hasName"):
		return
	_is_transitioning = true
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	if get_tree().change_scene_to_file(BOARD_SCENE) != OK:
		_is_transitioning = false


func _begin_go_to_desk() -> void:
	if _is_transitioning:
		return
	if GameManager.classroom_desk_seen:
		return
	_is_transitioning = true
	_save_desk_return_pos()
	if is_instance_valid(_interact_prompt) and _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.hide_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(DESK_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [DESK_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)


func _ensure_desk_area_live() -> void:
	if not is_instance_valid(_desk_interact_area):
		return
	if GameManager.classroom_desk_seen:
		return
	_desk_interact_area.monitoring = true
	var shape := _desk_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = false


func _apply_desk_seen_state() -> void:
	if not GameManager.classroom_desk_seen:
		_ensure_desk_area_live()
		return
	if is_instance_valid(_memory_indicator):
		_memory_indicator.visible = false
	if not is_instance_valid(_desk_interact_area):
		return
	_desk_interact_area.monitoring = false
	_desk_interact_area.monitorable = false
	var shape := _desk_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true


## MemoryIndicator's editor position is texture-pixel space (same as colliders
## and the player spawn); re-derive its world position from that captured
## offset each time the background layout (re)applies, so dragging the node
## in the editor is what actually moves it, not a hardcoded/computed anchor.
func _sync_memory_indicator() -> void:
	if not is_instance_valid(_memory_indicator) or not _memory_indicator.visible:
		return
	var env := $WalkableWorld/EnvironmentColliders
	_memory_indicator.global_position = env.to_global(_memory_indicator_tex)


func _start_board_glow() -> void:
	_stop_board_glow()
	if not is_instance_valid(_board_glow) or not _board_glow.visible:
		return
	var glow := _board_glow.get_node_or_null("Outline") as CanvasItem
	if glow == null:
		return
	_board_glow_tween = create_tween()
	_board_glow_tween.set_loops()
	_board_glow_tween.tween_property(glow, "modulate:a", 0.22, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_board_glow_tween.tween_property(glow, "modulate:a", 0.08, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _stop_board_glow() -> void:
	if _board_glow_tween != null and _board_glow_tween.is_valid():
		_board_glow_tween.kill()
	_board_glow_tween = null


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
	if GameManager.has_classroom_desk_return_pos():
		call_deferred("_apply_desk_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_door_peek_if_pending()


func _apply_desk_return_if_pending() -> void:
	if not GameManager.has_classroom_desk_return_pos() or not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	_player.global_position = env.to_global(GameManager.take_classroom_desk_return_pos())


func _apply_door_peek_if_pending() -> void:
	if not _pending_door_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_door_peek = false
	# Live DoorInteractArea center this Play. Stand the Player node (the model)
	# on that box — t-slide + clearance put Front in DoorWall (top-right).
	_player.global_position = InteractArrival.place_node_on_area_center(
		_player, _door_interact_area
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
	for i in _BEHIND_ZONE_NAMES.size():
		var zone := get_node_or_null(
			"WalkableWorld/EnvironmentColliders/%s" % _BEHIND_ZONE_NAMES[i]
		) as Area2D
		var poly := PackedVector2Array()
		var feather := 0.0
		if is_instance_valid(zone) and zone.has_method("get_shader_polygon"):
			poly = zone.call("get_shader_polygon")
			feather = float(zone.get("feather_px"))
		polys.append(poly)
		feathers.append(feather)
		cutoffs.append(_occlusion_y_cutoff(_BEHIND_GATE_BODIES[i]))
	while polys.size() < 4:
		polys.append(PackedVector2Array())
		feathers.append(0.0)
		cutoffs.append(1e9)
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
		false,
		polys[3],
		feathers[3],
		cutoffs[3],
	)


func _occlusion_y_cutoff(block_name: String) -> float:
	var body := get_node_or_null(
		"WalkableWorld/EnvironmentColliders/%s" % block_name
	) as StaticBody2D
	if not is_instance_valid(body):
		return 1e9
	var max_y := -INF
	for child in body.get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.is_empty():
			continue
		for local_point in polygon_node.polygon:
			max_y = maxf(max_y, polygon_node.to_global(local_point).y)
	if max_y == -INF:
		return 1e9
	return max_y
