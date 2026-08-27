extends Node2D

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
const DOOR_ZONE_GRACE_SEC := 0.15
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _memory_indicator: Node2D = get_node_or_null("PlayerLayer/MemoryIndicator")

var _door_interact_area: Area2D
var _memory_area: Area2D
var _active_zone: String = ""
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _is_transitioning := false
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _cover_layout_ready := false
var _door_zone_armed := true
var _memory_zone_armed := true
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
	_memory_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/MemoryInteractArea"
	) as Area2D
	_apply_collected_memory()
	set_process(true)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	_enter_dialogue_pending = _will_play_enter_dialogue()
	call_deferred("_play_enter_dialogue")


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
		return


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
		if InteractZoneGate.body_in_area(_memory_area, _player):
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
	if _enter_dialogue_pending or InteractZoneGate.dialogue_busy(_top_dialogue):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	if _active_zone == "memory" and not _memory_zone_armed:
		return
	match _active_zone:
		"memory":
			_save_memory_return_pos()
			_begin_scene_change(MEMORY_SCENE)
		"door":
			_begin_return_to_cafeteria()


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _zone_area(zone_id: String) -> Area2D:
	match zone_id:
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


func _save_memory_return_pos() -> void:
	if not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	GameManager.set_backyard_memory_return_pos(env.to_local(_player.global_position))


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


func _begin_return_to_cafeteria() -> void:
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_Y
			)
		)
	GameManager.set_cafeteria_spawn_side("backyard_right")
	_begin_scene_change(CAFETERIA_SCENE)


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
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	_sync_memory_indicator()
	_cover_layout_ready = true
	call_deferred("_wake_static_colliders")
	call_deferred("_configure_behind_occlusion_masks")
	if GameManager.has_backyard_memory_return_pos():
		call_deferred("_apply_memory_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_door_peek_if_pending()


func _apply_memory_return_if_pending() -> void:
	if not GameManager.has_backyard_memory_return_pos() or not is_instance_valid(_player):
		return
	var env := $WalkableWorld/EnvironmentColliders
	_player.global_position = env.to_global(GameManager.take_backyard_memory_return_pos())


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
	_arrival_latched_zone = "door"
	_arm_door_zone_grace()


func _arm_door_zone_grace() -> void:
	_door_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	_door_zone_armed = true


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position


func _configure_behind_occlusion_masks() -> void:
	if not is_instance_valid(_player):
		return
	if not _player.has_method("configure_leaf_occlusion_polygons"):
		return
	var polys: Array[PackedVector2Array] = []
	var feathers: Array[float] = []
	## Slot 0 = wall (feet-Y so fade can cross TopWall). Slots 1–2 = bush/well (per-pixel).
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
