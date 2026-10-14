extends ExplorationRoom

const CORRIDOR_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const DESK_SCENE := "res://scenes/Arc_5/5.2_ClassroomDesk.tscn"
const BOARD_FAIL_LINE := "Nah."
const BOARD_SUCCESS_LINE := "You know the name now. You wish you didn't."
const BOARD_SYMBOL_LINE := "Something's scratched under it: %s"
const _LEAF_FADE_ALPHA := 0.2
const _LEAF_GATE_SOFTNESS := 12.0
const _BEHIND_ZONE_NAMES: PackedStringArray = [
	"FurnitureBlock6_Behind",
	"FurnitureBlock7_Behind",
	"FurnitureBlock8_Behind",
	"FurnitureBlock9_Behind",
]
const ENTER_LINES := [
	"This is where the shit went down.",
	"If shit going down is you, highly caffinated, ignoring your teachers and usually skipping class to go for a smoke.",
	"How did you ever get anywhere in life?",
]
const BOARD_INTRO := [
	"On the board there are weird ass symbols and equations.",
	"You can only make out one question:",
]

var _door_interact_area: Area2D
var _desk_interact_area: Area2D
var _board_interact_area: Area2D
var _board_glow: Node2D
var _board_glow_tween: Tween
var _pending_door_peek := false
var _arrival_t := InteractArrival.DEFAULT_T


func _ready() -> void:
	bind_player_cover()
	_wake_include_areas = true
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
	_start_board_glow()
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_restore_player_position_if_needed")
	if not GameManager.classroom_enter_line_seen:
		_enter_dialogue_pending = true
	call_deferred("_play_enter_dialogue")


func zone_ids() -> PackedStringArray:
	return PackedStringArray(["door", "desk", "board"])


func zone_area(zone_id: String) -> Area2D:
	match zone_id:
		"door":
			return _door_interact_area
		"desk":
			return _desk_interact_area
		"board":
			return _board_interact_area
		_:
			return null


func zone_is_available(zone_id: String) -> bool:
	if zone_id == "desk":
		return not GameManager.classroom_desk_seen
	return true


func extra_blocks_interact() -> bool:
	return _line_running


func on_zone_interact(zone_id: String) -> void:
	match zone_id:
		"door":
			leave_through(
				_door_interact_area,
				Vector2.AXIS_Y,
				"set_classrooms_corridor_spawn_side",
				"classroom_door",
				CORRIDOR_SCENE,
			)
		"desk":
			if GameManager.classroom_desk_seen:
				return
			save_player_tex("set_classroom_desk_return_pos")
			begin_scene_change(DESK_SCENE)
		"board":
			_look_at_board()


func _restore_player_position_if_needed() -> void:
	if not is_instance_valid(_player):
		return
	if GameManager.take_classroom_spawn_side() == "corridor_door":
		_pending_door_peek = true
		InteractArrival.take_arrival_t_or_default()
		_arrival_t = InteractArrival.DEFAULT_T
		if _cover_layout_ready:
			call_deferred("_apply_door_peek_after_wake")
		return
	if GameManager.has_classroom_desk_return_pos():
		call_deferred("_apply_desk_return_if_pending")


func _play_enter_dialogue() -> void:
	if not is_instance_valid(_top_dialogue):
		_enter_dialogue_pending = false
		return
	_top_dialogue.visible = true
	await play_enter_once("classroom_enter_line_seen", ENTER_LINES)


func _look_at_board() -> void:
	if _is_transitioning or _line_running:
		return
	if not is_instance_valid(_top_dialogue):
		return
	_line_running = true
	hide_interact_prompt_immediate()
	var question := _board_question()
	var lines := _board_lines(question)
	var can_guess := (
		bool(question.get("ready", false))
		and not bool(question.get("guess_spent", false))
		and not GameManager.get_flag("hasName")
	)
	if not can_guess:
		await _top_dialogue.show_lines(lines)
		if is_instance_valid(self):
			_line_running = false
		return
	await _top_dialogue.show_lines_keep_bar(lines)
	if not is_instance_valid(self) or not is_instance_valid(_top_dialogue):
		return
	if not _top_dialogue.is_bar_visible():
		_line_running = false
		return
	_set_player_typing(false)
	var result: Dictionary = await _top_dialogue.await_text_entry()
	_set_player_typing(true)
	if not is_instance_valid(self):
		return
	if bool(result.get("cancelled", true)):
		_line_running = false
		return
	await _resolve_board_answer(String(result.get("text", "")))
	if is_instance_valid(self):
		_line_running = false


func _set_player_typing(enabled: bool) -> void:
	if is_instance_valid(_player) and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(enabled)


func _board_question() -> Dictionary:
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("ensure_board_question"):
		return world.call("ensure_board_question")
	return {"ready": false}


func _board_lines(question: Dictionary) -> Array:
	var lines: Array = BOARD_INTRO.duplicate()
	if bool(question.get("ready", false)):
		lines.append("\"%s\"" % String(question.get("line", "")))
	if GameManager.get_flag("hasName"):
		var symbol := _board_symbol()
		if not symbol.is_empty():
			lines.append(BOARD_SYMBOL_LINE % symbol)
	return lines


func _board_symbol() -> String:
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("ensure_board_symbol"):
		return String(world.call("ensure_board_symbol"))
	return ""


func _resolve_board_answer(typed: String) -> void:
	var world := get_node_or_null("/root/AxelWorld")
	var correct := false
	if world != null and world.has_method("board_answer_matches"):
		correct = bool(world.call("board_answer_matches", typed))
	if world != null and world.has_method("spend_board_guess"):
		world.call("spend_board_guess")
	if correct:
		GameManager.set_flag("hasName", true)
		GameManager.set_flag("knowsName", true)
		GameManager.add_inventory_item("hasName", "Name")
		var symbol := _board_symbol()
		if is_instance_valid(_top_dialogue):
			var success_lines: Array = [BOARD_SUCCESS_LINE]
			if not symbol.is_empty():
				success_lines.append(BOARD_SYMBOL_LINE % symbol)
			await _top_dialogue.show_lines(success_lines)
		if not is_instance_valid(self):
			return
		if world != null and world.has_method("start_lore_fight"):
			world.call("start_lore_fight", "hasName", scene_file_path, true)
		return
	if is_instance_valid(_top_dialogue):
		await _top_dialogue.show_line(BOARD_FAIL_LINE)


func _ensure_desk_area_live() -> void:
	if not is_instance_valid(_desk_interact_area):
		return
	if GameManager.classroom_desk_seen:
		return
	_desk_interact_area.monitoring = true
	var shape := _desk_interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = false


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


func on_world_space_synced(_cover_scale: float, _bg_position: Vector2) -> void:
	call_deferred("wake_static_colliders")
	call_deferred("_configure_behind_occlusion_masks")
	if GameManager.has_classroom_desk_return_pos():
		call_deferred("_apply_desk_return_if_pending")
	elif _pending_door_peek:
		call_deferred("_apply_door_peek_after_wake")


func _apply_door_peek_after_wake() -> void:
	wake_static_colliders()
	await await_two_physics_frames()
	_apply_door_peek_if_pending()


func _apply_desk_return_if_pending() -> void:
	restore_player_tex("has_classroom_desk_return_pos", "take_classroom_desk_return_pos")


func _apply_door_peek_if_pending() -> void:
	if not _pending_door_peek or not is_instance_valid(_player):
		return
	if not _cover_layout_ready:
		return
	_pending_door_peek = false
	_player.global_position = InteractArrival.place_node_on_area_center(
		_player, _door_interact_area
	)
	latch_zone("door")
	arm_zone_grace("door")


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
