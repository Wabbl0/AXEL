extends ExplorationRoom

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const KITCHEN_SELF_SCENE := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const ENTER_LINES := [
	"Everything is rotten here. Everything.",
	"This includes you.",
]
const FLASHLIGHT_LINE := "Let there be light!"

var _door_interact_area: Area2D
var _flashlight_interact_area: Area2D
var _flashlight_visual: Node2D
var _flashlight_glow_tween: Tween
var _pending_cafeteria_peek := false
var _arrival_t := InteractArrival.DEFAULT_T


func _ready() -> void:
	bind_player_cover()
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
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.kitchen_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["door", "flashlight"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"door":
			return _door_interact_area
		"flashlight":
			return _flashlight_interact_area
		_:
			return null


func zone_is_available(zone_id: String) -> bool:
	if zone_id == "flashlight":
		return not LorePickup.is_owned("hasFlashlight")
	return true


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"door":
			leave_through(
				_door_interact_area,
				Vector2.AXIS_X,
				"set_kitchen_spawn_side",
				"kitchen_door",
				CAFETERIA_SCENE,
			)
		"flashlight":
			_pickup_flashlight()


func extra_blocks_interact() -> bool:
	return _line_running


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_kitchen_spawn_side() == "cafeteria_door":
		_pending_cafeteria_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_cafeteria_peek_after_wake")


func _apply_flashlight_visibility() -> void:
	var owned := LorePickup.is_owned("hasFlashlight")
	if owned:
		LorePickup.hide_owned(_flashlight_interact_area, _flashlight_visual)
		_stop_flashlight_glow()
		return
	if is_instance_valid(_flashlight_visual):
		_flashlight_visual.visible = true
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
	await play_enter_once("kitchen_enter_line_seen", ENTER_LINES)


func _pickup_flashlight() -> void:
	if _line_running or LorePickup.is_owned("hasFlashlight"):
		return
	_line_running = true
	hide_interact_prompt_immediate()
	await LorePickup.take(
		self,
		"hasFlashlight",
		"Flashlight",
		_top_dialogue,
		FLASHLIGHT_LINE,
		KITCHEN_SELF_SCENE,
		_apply_flashlight_visibility,
	)
	_line_running = false
	if _active_zone == "flashlight":
		_active_zone = ""
	hide_interact_prompt()
	hide_interact_prompt_immediate()


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_after_wake")


func _apply_cafeteria_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_cafeteria_peek_if_pending()


func _apply_cafeteria_peek_if_pending() -> void:
	if not _pending_cafeteria_peek or not is_instance_valid(_player):
		return
	_pending_cafeteria_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_door_interact_area,
		_arrival_t,
		Vector2.AXIS_X,
		InteractArrival.PeekEdge.TOP,
		-12.0
	)
	latch_zone("door")
	call_deferred("_clamp_arrived_player")
	arm_zone_grace("door")


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_X)
