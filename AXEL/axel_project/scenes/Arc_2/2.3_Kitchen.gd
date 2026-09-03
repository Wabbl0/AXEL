extends Node2D

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const ENTER_LINES := [
	"Everything is rotten here. Everything.",
	"This includes you.",
]
const FLASHLIGHT_LINE := "Let there be light!"
const DOOR_ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _interact_prompt: CanvasLayer = $InteractPromptOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player

var _door_interact_area: Area2D
var _flashlight_interact_area: Area2D
var _flashlight_visual: Node2D
var _flashlight_glow_tween: Tween
var _active_zone: String = ""
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _is_transitioning := false
var _flashlight_line_running := false
var _pending_cafeteria_peek := false
var _arrival_t := InteractArrival.DEFAULT_T
var _door_zone_armed := true
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	_player_cover_sync.bind_from_player(_player)
	var _bg := $WalkableWorld/Background as Sprite2D
	var _cam := $Camera2D
	_player_cover_sync.bind_design_from_background(
		_bg, _cam.fit_mode, _cam.background_y
	)
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_flashlight_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FlashlightInteractArea"
	) as Area2D
	_flashlight_visual = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FlashlightVisual"
	) as Node2D
	_apply_flashlight_visibility()
	set_process(true)
	set_process_unhandled_input(true)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.kitchen_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_kitchen_spawn_side() == "cafeteria_door":
		_pending_cafeteria_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_cafeteria_peek_after_wake")


func _apply_flashlight_visibility() -> void:
	var owned := GameManager.get_flag("hasFlashlight")
	if is_instance_valid(_flashlight_interact_area) and owned:
		_flashlight_interact_area.visible = false
		_flashlight_interact_area.monitoring = false
		_flashlight_interact_area.monitorable = false
	if is_instance_valid(_flashlight_visual):
		_flashlight_visual.visible = not owned
		if owned:
			_stop_flashlight_glow()
		else:
			_start_flashlight_glow()


func _start_flashlight_glow() -> void:
	_stop_flashlight_glow()
	if not is_instance_valid(_flashlight_visual) or not _flashlight_visual.visible:
		return
	var glow := _flashlight_visual.get_node_or_null("Glow") as CanvasItem
	if glow == null:
		return
	_flashlight_glow_tween = create_tween()
	_flashlight_glow_tween.set_loops()
	_flashlight_glow_tween.tween_property(glow, "modulate:a", 0.22, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flashlight_glow_tween.tween_property(glow, "modulate:a", 0.08, 1.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _stop_flashlight_glow() -> void:
	if _flashlight_glow_tween != null and _flashlight_glow_tween.is_valid():
		_flashlight_glow_tween.kill()
	_flashlight_glow_tween = null


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if GameManager.kitchen_enter_line_seen:
		_enter_dialogue_pending = false
		return
	GameManager.set_kitchen_enter_line_seen(true)
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
		or _flashlight_line_running
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
			InteractZoneGate.body_in_area(_flashlight_interact_area, _player)
			and not GameManager.get_flag("hasFlashlight")
		):
			_active_zone = "flashlight"
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
		or _flashlight_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		return
	if _active_zone.is_empty():
		return
	if _active_zone == "door" and not _door_zone_armed:
		return
	match _active_zone:
		"door":
			_begin_return_to_cafeteria()
		"flashlight":
			_pickup_flashlight_async()


func _is_interaction_event(event: InputEvent) -> bool:
	# Named InputMap action (E/Space/Enter + gamepad A). Excludes echo presses.
	return event.is_action_pressed("interact")


func _zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"door":
			return _door_interact_area
		"flashlight":
			return _flashlight_interact_area
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
		or _flashlight_line_running
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		return
	if _active_zone == "flashlight" and GameManager.get_flag("hasFlashlight"):
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


func _pickup_flashlight_async() -> void:
	if _flashlight_line_running or GameManager.get_flag("hasFlashlight"):
		return
	_flashlight_line_running = true
	_hide_interact_prompt_immediate()
	GameManager.set_flag("hasFlashlight", true)
	GameManager.add_inventory_item("hasFlashlight", "Flashlight")
	_apply_flashlight_visibility()
	await _top_dialogue.show_line(FLASHLIGHT_LINE, 3.0)
	_flashlight_line_running = false
	if _active_zone == "flashlight":
		_active_zone = ""
	_hide_interact_prompt()


func _begin_return_to_cafeteria() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if is_instance_valid(_player) and is_instance_valid(_door_interact_area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(
				_player, _door_interact_area, Vector2.AXIS_X
			)
		)
	GameManager.set_kitchen_spawn_side("kitchen_door")
	_hide_interact_prompt_immediate()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CAFETERIA_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CAFETERIA_SCENE, err])
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
	call_deferred("_wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_after_wake")


func _apply_cafeteria_peek_after_wake() -> void:
	_wake_static_colliders()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_cafeteria_peek_if_pending()


func _apply_cafeteria_peek_if_pending() -> void:
	if not _pending_cafeteria_peek or not is_instance_valid(_player):
		return
	_pending_cafeteria_peek = false
	# Door sits on the kitchen bottom — peek just above the interact top.
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.TOP,
		-12.0
	)
	_arrival_latched_zone = "door"
	call_deferred("_clamp_arrived_player")
	_arm_door_zone_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_X)


func _arm_door_zone_grace() -> void:
	_door_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	_door_zone_armed = true


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
