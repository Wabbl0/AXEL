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
var _is_transitioning := false
var _flashlight_line_running := false
var _player_spawn_applied := false
var _door_zone_armed := true
## Texture-pixel spawn captured from the Player node's editor position.
var _player_spawn_tex := Vector2.ZERO
var _player_cover_sync := PlayerCoverSync.new()


func _ready() -> void:
	_player_spawn_tex = _player.position
	_player_cover_sync.bind_from_player(_player)
	_door_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/DoorInteractArea"
	) as Area2D
	_flashlight_interact_area = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FlashlightInteractArea"
	) as Area2D
	_flashlight_visual = get_node_or_null(
		"WalkableWorld/EnvironmentColliders/FlashlightVisual"
	) as Node2D
	_connect_zone(_door_interact_area, "door")
	_connect_zone(_flashlight_interact_area, "flashlight")
	_apply_flashlight_visibility()
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
		return
	if GameManager.kitchen_enter_line_seen:
		return
	GameManager.set_kitchen_enter_line_seen(true)
	await _top_dialogue.show_lines(ENTER_LINES)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
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
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _on_zone_body_entered(body: Node, zone_id: String) -> void:
	if body != _player or _is_transitioning:
		return
	if zone_id == "flashlight" and GameManager.get_flag("hasFlashlight"):
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
	if _active_zone == "door" and not _door_zone_armed:
		return
	if _active_zone == "flashlight" and (
		_flashlight_line_running or GameManager.get_flag("hasFlashlight")
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
	var tex_pos := Vector2.ZERO
	var remap_pos := _player_spawn_applied and _player_cover_sync.has_reference()
	if remap_pos:
		tex_pos = env.to_local(player_node.global_position)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	if not _player_spawn_applied:
		player_node.global_position = env.to_global(_player_spawn_tex)
		_player_spawn_applied = true
		_arm_door_zone_grace()
	elif remap_pos:
		player_node.global_position = env.to_global(tex_pos)
	_player_cover_sync.apply(player_node, cover_scale, bg_position)
	call_deferred("_wake_static_colliders")


func _arm_door_zone_grace() -> void:
	_door_zone_armed = false
	await get_tree().create_timer(DOOR_ZONE_GRACE_SEC).timeout
	_door_zone_armed = true
	if _active_zone == "door":
		_show_interact_prompt()


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
