extends ExplorationRoom

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const BASEMENT_SCENE := "res://scenes/Arc_6/6.1_BasementDoor.tscn"
const BASEMENT_RETURN_T := 1.0
const CAFETERIA_PEEK_MARGIN_PX := 12.0
const CORRIDOR_PEEK_MARGIN_PX := 12.0
const EXIT_TRIGGER_GRACE_SEC := 0.15
const HINT_WAIT_SEC := 10.0
const HINT_SOON_WAIT_SEC := 0.6
const HINT_SCREEN_SCALE := 1.67
const HINT_RIGHT_INSET_PX := 48.0
const HINT_Y_FRAC := 0.64
const _OLD_BG_SCALE := Vector2(0.352, 0.352)

var _door_interact_area: Area2D
var _cafeteria_exit_trigger: Area2D
var _exit_trigger: Area2D
var _pending_cafeteria_peek := false
var _pending_corridor_peek := false
var _pending_door_return := false
var _arrival_t := InteractArrival.DEFAULT_T
var _exit_trigger_armed := true
var _cafeteria_exit_armed := true
var _direction_hint: Node2D
var _hint_elapsed := 0.0
var _hint_wait_sec := HINT_WAIT_SEC
var _hint_hidden_this_visit := false


func _ready() -> void:
	_player_cover_sync.authored_bg_baseline = _OLD_BG_SCALE.x
	_direction_hint = get_node_or_null("PlayerLayer/DirectionHint") as Node2D
	if is_instance_valid(_direction_hint):
		_direction_hint.visible = false
	if GameManager.take_basement_hint_soon():
		_hint_wait_sec = HINT_SOON_WAIT_SEC
	else:
		_hint_wait_sec = HINT_WAIT_SEC
	bind_player_cover()
	GameManager.set_corridor_right_hint_done(true)
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_cafeteria_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/CafeteriaExitTrigger"
	) as Area2D
	if is_instance_valid(_cafeteria_exit_trigger):
		_cafeteria_exit_trigger.body_entered.connect(_on_cafeteria_exit_body_entered)
	_exit_trigger = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/ExitTrigger"
	) as Area2D
	if is_instance_valid(_exit_trigger):
		_exit_trigger.body_entered.connect(_on_exit_body_entered)
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")


func _process(delta: float) -> void:
	super._process(delta)
	_update_direction_hint(delta)


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["door"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"door":
			return _door_interact_area
		_:
			return null


func extra_blocks_interact() -> bool:
	return _line_running


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"door":
			_enter_basement()


func _enter_basement() -> void:
	if extra_blocks_interact() or InteractZoneGate.dialogue_busy(_top_dialogue):
		return
	GameManager.set_basement_door_line_seen(true)
	begin_scene_change(BASEMENT_SCENE)


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.has_pause_map_return_for(scene_file_path):
		return
	var basement_side := GameManager.take_basement_spawn_side()
	if basement_side == "basement_door":
		_pending_door_return = true
		call_deferred("_apply_door_return_after_wake")
		return
	if basement_side == "cafeteria_right":
		_pending_cafeteria_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_cafeteria_peek_after_wake")
		return
	if basement_side == "corridor_left":
		_pending_corridor_peek = true
		_arrival_t = InteractArrival.take_arrival_t_or_default()
		call_deferred("_apply_corridor_peek_after_wake")


func _on_exit_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning or not _exit_trigger_armed or fight_is_starting():
		return
	call_deferred("_begin_corridor_return")


func _on_cafeteria_exit_body_entered(body: Node) -> void:
	if body != _player or _is_transitioning or not _cafeteria_exit_armed or fight_is_starting():
		return
	call_deferred("_begin_cafeteria_exit")


func _begin_corridor_return() -> void:
	if is_instance_valid(_player) and is_instance_valid(_exit_trigger):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _exit_trigger, Vector2.AXIS_Y)
		)
	GameManager.set_corridor_spawn_side("basement_right")
	begin_scene_change(CORRIDOR_SCENE)


func _begin_cafeteria_exit() -> void:
	if is_instance_valid(_player) and is_instance_valid(_cafeteria_exit_trigger):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, _cafeteria_exit_trigger, Vector2.AXIS_Y)
		)
	GameManager.set_cafeteria_spawn_side("basement_left")
	begin_scene_change(CAFETERIA_SCENE)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	_sync_direction_hint()
	call_deferred("wake_static_colliders")
	if _pending_cafeteria_peek:
		call_deferred("_apply_cafeteria_peek_after_wake")
	elif _pending_corridor_peek:
		call_deferred("_apply_corridor_peek_after_wake")
	elif _pending_door_return:
		call_deferred("_apply_door_return_after_wake")


func _apply_cafeteria_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_cafeteria_peek_if_pending()


func _apply_corridor_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_corridor_peek_if_pending()


func _apply_door_return_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_door_return_if_pending()


func _apply_door_return_if_pending() -> void:
	if not _pending_door_return or not is_instance_valid(_player):
		return
	_pending_door_return = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_door_interact_area,
		BASEMENT_RETURN_T,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.CENTER_X,
		0.0
	)
	call_deferred("_clamp_arrived_player")


func _apply_cafeteria_peek_if_pending() -> void:
	if not _pending_cafeteria_peek or not is_instance_valid(_player):
		return
	_pending_cafeteria_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_cafeteria_exit_trigger,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.LEFT,
		-CAFETERIA_PEEK_MARGIN_PX
	)
	call_deferred("_clamp_arrived_player")
	_arm_cafeteria_exit_grace()


func _apply_corridor_peek_if_pending() -> void:
	if not _pending_corridor_peek or not is_instance_valid(_player):
		return
	_pending_corridor_peek = false
	_player.global_position = InteractArrival.place_on_area(
		_player,
		_exit_trigger,
		_arrival_t,
		Vector2.AXIS_Y,
		InteractArrival.PeekEdge.RIGHT,
		CORRIDOR_PEEK_MARGIN_PX
	)
	call_deferred("_clamp_arrived_player")
	_arm_exit_trigger_grace()


func _clamp_arrived_player() -> void:
	if is_instance_valid(_player):
		InteractArrival.clamp_hitbox_to_walls(_player, Vector2.AXIS_Y)


func _arm_exit_trigger_grace() -> void:
	_exit_trigger_armed = false
	var tree := get_tree()
	if tree == null:
		_exit_trigger_armed = true
		return
	await tree.create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_exit_trigger_armed = true


func _arm_cafeteria_exit_grace() -> void:
	_cafeteria_exit_armed = false
	var tree := get_tree()
	if tree == null:
		_cafeteria_exit_armed = true
		return
	await tree.create_timer(EXIT_TRIGGER_GRACE_SEC).timeout
	_cafeteria_exit_armed = true


func _sync_direction_hint() -> void:
	if not is_instance_valid(_direction_hint):
		return
	var vp := get_viewport()
	if vp == null:
		return
	var rect := vp.get_visible_rect()
	_direction_hint.scale = Vector2(HINT_SCREEN_SCALE, HINT_SCREEN_SCALE)
	var half_w := HINT_RIGHT_INSET_PX
	var sprite := _direction_hint.get_node_or_null("Sprite") as Sprite2D
	if sprite != null and sprite.texture != null:
		half_w = sprite.texture.get_width() * HINT_SCREEN_SCALE * 0.5
	var screen := Vector2(rect.size.x - half_w - 8.0, rect.size.y * HINT_Y_FRAC)
	var canvas := _direction_hint.get_canvas_transform()
	_direction_hint.global_position = canvas.affine_inverse() * screen
	AxelRoomEdge.keep_inside(_direction_hint, Vector2(half_w, half_w))


func _update_direction_hint(delta: float) -> void:
	if not is_instance_valid(_direction_hint):
		return
	if _hint_should_stay_off():
		_direction_hint.visible = false
		return
	var dialogue_holds := InteractZoneGate.dialogue_busy(_top_dialogue)
	var pause_holds := get_tree() != null and get_tree().paused
	if not dialogue_holds and not pause_holds:
		_hint_elapsed += delta
	_direction_hint.visible = _hint_elapsed >= _hint_wait_sec
	if _direction_hint.visible:
		_sync_direction_hint()
		if _hint_overlaps_player():
			_hint_hidden_this_visit = true
			GameManager.set_basement_right_hint_done(true)
			_direction_hint.visible = false


func _hint_overlaps_player() -> bool:
	if not is_instance_valid(_player) or not is_instance_valid(_direction_hint):
		return false
	var arrow := _direction_hint.get_node_or_null("Sprite") as Sprite2D
	var mike := _player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if arrow == null or mike == null or not mike.visible:
		return false
	var arrow_rect := _centered_sprite_global_rect(arrow, _sprite2d_size(arrow), arrow.offset, arrow.centered)
	var mike_rect := _centered_sprite_global_rect(mike, _anim_frame_size(mike), mike.offset, mike.centered)
	if arrow_rect.size.x <= 0.0 or arrow_rect.size.y <= 0.0:
		return false
	if mike_rect.size.x <= 0.0 or mike_rect.size.y <= 0.0:
		return false
	return arrow_rect.intersects(mike_rect, true)


func _sprite2d_size(sprite: Sprite2D) -> Vector2:
	if sprite.texture == null:
		return Vector2.ZERO
	if sprite.region_enabled:
		return sprite.region_rect.size
	return sprite.texture.get_size()


func _anim_frame_size(sprite: AnimatedSprite2D) -> Vector2:
	if sprite.sprite_frames == null:
		return Vector2.ZERO
	var anim := sprite.animation
	if anim == StringName() or not sprite.sprite_frames.has_animation(anim):
		return Vector2.ZERO
	var tex := sprite.sprite_frames.get_frame_texture(anim, sprite.frame)
	if tex == null:
		return Vector2.ZERO
	return tex.get_size()


func _centered_sprite_global_rect(item: Node2D, tex_size: Vector2, sprite_offset: Vector2, centered: bool) -> Rect2:
	if tex_size == Vector2.ZERO:
		return Rect2()
	var origin := sprite_offset
	if centered:
		origin -= tex_size * 0.5
	var local := Rect2(origin, tex_size)
	var xf := item.get_global_transform()
	var rect := Rect2(xf * local.position, Vector2.ZERO)
	rect = rect.expand(xf * (local.position + Vector2(local.size.x, 0.0)))
	rect = rect.expand(xf * (local.position + local.size))
	rect = rect.expand(xf * (local.position + Vector2(0.0, local.size.y)))
	return rect


func _hint_should_stay_off() -> bool:
	if _hint_hidden_this_visit or _is_transitioning:
		return true
	if GameManager.basement_right_hint_done:
		return true
	if GameManager.has_visited(CAFETERIA_SCENE):
		return true
	return false
