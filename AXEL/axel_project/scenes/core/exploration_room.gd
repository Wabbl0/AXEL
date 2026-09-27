extends Node2D
class_name ExplorationRoom

const IndicatorFitScript := preload("res://scenes/core/indicator_fit.gd")
const ZONE_GRACE_SEC := 0.15

@onready var _top_dialogue: Node = get_node_or_null("TopDialogueOverlay")
@onready var _interact_prompt: CanvasLayer = get_node_or_null("InteractPromptOverlay")
@onready var _player: CharacterBody2D = get_node_or_null("PlayerLayer/Player")

var _active_zone: String = ""
var _arrival_latched_zone: String = ""
var _enter_dialogue_pending := false
var _is_transitioning := false
var _cover_layout_ready := false
var _line_running := false
var _wake_include_areas := false
var _use_default_interact_loop := true
var _player_cover_sync := PlayerCoverSync.new()
var _zone_armed: Dictionary = {}


func env_colliders() -> Node2D:
	var env := get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env != null:
		return env
	return get_node_or_null("EnvironmentColliders") as Node2D


func memory_indicator() -> Node2D:
	return get_node_or_null("PlayerLayer/MemoryIndicator") as Node2D


func floor_item_marker_px() -> float:
	return IndicatorFitScript.item_marker_px(
		_player_cover_sync.authored_scale.x,
		_player_cover_sync.authored_bg_baseline
	)


func _fit_memory_indicator(glow: Node2D) -> void:
	if not is_instance_valid(_player):
		return
	var fitted := IndicatorFitScript.memory_from_player(_player_cover_sync.authored_scale.x)
	if fitted <= 0.0:
		return
	glow.set("indicator_scale", fitted)
	glow.scale = Vector2(fitted, fitted)


func bind_player_cover(
	background: Sprite2D = null,
	extra: Node2D = null,
	connect_layout: bool = true,
) -> void:
	if not is_instance_valid(_player):
		_player = get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	_player_cover_sync.bind_from_player(_player)
	if background == null:
		background = get_node_or_null("WalkableWorld/Background") as Sprite2D
	var cam := get_node_or_null("Camera2D")
	if cam != null:
		_player_cover_sync.bind_design_from_background(
			background, cam.fit_mode, cam.background_y
		)
		if connect_layout and cam.has_signal("layout_applied"):
			if not cam.layout_applied.is_connected(_on_background_layout_applied):
				cam.layout_applied.connect(_on_background_layout_applied)
	if extra != null:
		_player_cover_sync.bind_extra_node(extra)
	var glow := memory_indicator()
	if glow != null:
		_fit_memory_indicator(glow)
		if glow.has_method("capture_editor_tex"):
			glow.call("capture_editor_tex")
		_player_cover_sync.bind_extra_node(glow)
		if glow.has_method("apply_collected"):
			glow.call("apply_collected")


func _on_background_layout_applied(
	scale_factor: float, bg_position: Vector2, _world_rect: Rect2
) -> void:
	sync_world_space(scale_factor, bg_position)


func sync_world_space(cover_scale: float, bg_position: Vector2) -> void:
	var env := env_colliders()
	var player_node := _player
	if player_node == null:
		player_node = get_node_or_null("PlayerLayer/Player") as CharacterBody2D
		_player = player_node
	if env == null or not is_instance_valid(player_node):
		return
	var tex_pos := PlayerSpawnSync.capture_tex(env, player_node)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	PlayerSpawnSync.apply_tex(env, player_node, tex_pos)
	apply_player_cover(player_node, cover_scale, bg_position)
	var glow := memory_indicator()
	if glow != null and glow.has_method("remap_to_env"):
		glow.call("remap_to_env", env)
	_cover_layout_ready = true
	on_world_space_synced(cover_scale, bg_position)
	_queue_pause_map_restore()


func apply_player_cover(
	player_node: CharacterBody2D, cover_scale: float, bg_position: Vector2
) -> void:
	_player_cover_sync.apply(player_node, cover_scale, bg_position)


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")


func _queue_pause_map_restore() -> void:
	if not GameManager.has_pause_map_return_for(scene_file_path):
		return
	_apply_pause_map_restore()


func _apply_pause_map_restore() -> void:
	await await_two_physics_frames()
	for _i in 6:
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
	if not is_inside_tree():
		return
	if not GameManager.has_pause_map_return_for(scene_file_path):
		return
	var env := env_colliders()
	if env == null or not is_instance_valid(_player):
		return
	PlayerSpawnSync.apply_tex(env, _player, GameManager.take_pause_map_return_tex())


func wake_static_colliders() -> void:
	var env := env_colliders()
	if env == null:
		return
	for child in env.get_children():
		if child is StaticBody2D or (_wake_include_areas and child is Area2D):
			child.position = child.position


func begin_scene_change(
	scene_path: String, interrupt_dialogue: bool = true
) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if not ExplorationTransition.go(
		self, scene_path, _interact_prompt, _top_dialogue, interrupt_dialogue
	):
		_is_transitioning = false


func hide_interact_prompt_immediate() -> void:
	if not is_instance_valid(_interact_prompt):
		return
	if _interact_prompt.has_method("hide_prompt_immediate"):
		_interact_prompt.call("hide_prompt_immediate")
	elif _interact_prompt.has_method("hide_prompt"):
		_interact_prompt.call("hide_prompt")


func show_interact_prompt() -> void:
	if _is_transitioning or _active_zone.is_empty():
		return
	if not zone_is_available(_active_zone):
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.show_prompt(interact_anchor())


func hide_interact_prompt() -> void:
	if _is_transitioning:
		return
	if not is_instance_valid(_interact_prompt):
		return
	_interact_prompt.hide_prompt()


func interact_anchor() -> Vector2:
	return InteractSpot.anchor_from_area(zone_area(_active_zone))


func zone_ids() -> PackedStringArray:
	return PackedStringArray()


func zone_area(_zone_id: String) -> Area2D:
	return null


func zone_is_available(_zone_id: String) -> bool:
	return true


func extra_blocks_interact() -> bool:
	return _line_running


func on_zone_interact(_zone_id: String) -> void:
	pass


func is_zone_armed(zone_id: String) -> bool:
	return bool(_zone_armed.get(zone_id, true))


func arm_zone_grace(zone_id: String) -> void:
	_zone_armed[zone_id] = false
	var tree := get_tree()
	if tree == null:
		_zone_armed[zone_id] = true
		return
	await tree.create_timer(ZONE_GRACE_SEC).timeout
	_zone_armed[zone_id] = true


func latch_zone(zone_id: String) -> void:
	_arrival_latched_zone = zone_id


func refresh_active_zone() -> void:
	if _is_transitioning:
		return
	var prev := _active_zone
	if not _arrival_latched_zone.is_empty():
		_active_zone = _arrival_latched_zone
	else:
		_active_zone = ""
		for zone_id in zone_ids():
			if not zone_is_available(zone_id):
				continue
			if InteractZoneGate.body_in_area(zone_area(zone_id), _player):
				_active_zone = zone_id
				break
	if _active_zone != prev:
		if _active_zone.is_empty():
			hide_interact_prompt()
		else:
			show_interact_prompt()
	elif not _active_zone.is_empty():
		show_interact_prompt()


func play_enter_once(seen_property: String, lines) -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	if not seen_property.is_empty() and bool(GameManager.get(seen_property)):
		_enter_dialogue_pending = false
		return
	if not seen_property.is_empty():
		var setter := "set_%s" % seen_property
		if GameManager.has_method(setter):
			GameManager.call(setter, true)
	_enter_dialogue_pending = false
	if lines is String and not String(lines).is_empty():
		await _top_dialogue.show_line(String(lines), 3.0)
	elif lines is PackedStringArray and (lines as PackedStringArray).size() > 0:
		await _top_dialogue.show_lines(lines)
	elif lines is Array and (lines as Array).size() > 0:
		await _top_dialogue.show_lines(lines)


func save_player_tex(setter_name: String) -> void:
	var env := env_colliders()
	if setter_name.is_empty() or env == null or not is_instance_valid(_player):
		return
	if GameManager.has_method(setter_name):
		GameManager.call(setter_name, env.to_local(_player.global_position))


func restore_player_tex(has_name: String, take_name: String) -> bool:
	if has_name.is_empty() or take_name.is_empty():
		return false
	if not GameManager.has_method(has_name) or not bool(GameManager.call(has_name)):
		return false
	var env := env_colliders()
	if env == null or not is_instance_valid(_player):
		return false
	_player.global_position = env.to_global(GameManager.call(take_name))
	return true


func await_two_physics_frames() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	await tree.physics_frame


func leave_through(
	area: Area2D,
	axis: int,
	spawn_setter: String,
	spawn_value: String,
	dest_scene: String,
	save_t: bool = true,
) -> void:
	if save_t and is_instance_valid(_player) and is_instance_valid(area):
		GameManager.set_interact_arrival_t(
			InteractArrival.fraction_along(_player, area, axis)
		)
	if not spawn_setter.is_empty() and GameManager.has_method(spawn_setter):
		GameManager.call(spawn_setter, spawn_value)
	begin_scene_change(dest_scene)


func _process(_delta: float) -> void:
	if not _use_default_interact_loop:
		return
	if not _arrival_latched_zone.is_empty() and InteractZoneGate.movement_pressed():
		_arrival_latched_zone = ""
	refresh_active_zone()


func _unhandled_input(event: InputEvent) -> void:
	if not _use_default_interact_loop:
		return
	if _is_transitioning:
		return
	if not event.is_action_pressed("interact"):
		return
	refresh_active_zone()
	if (
		_enter_dialogue_pending
		or extra_blocks_interact()
		or InteractZoneGate.dialogue_busy(_top_dialogue)
	):
		return
	if _active_zone.is_empty():
		return
	if not is_zone_armed(_active_zone):
		return
	on_zone_interact(_active_zone)
