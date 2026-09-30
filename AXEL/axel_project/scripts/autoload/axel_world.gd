extends Node

signal map_spots_updated

const PickupScript := preload("res://scenes/world/world_item_pickup.gd")
const LayoutScript := preload("res://scenes/core/background_layout.gd")
const InfoCardScript := preload("res://scenes/ui/world_item_info_card.gd")
const WheelScript := preload("res://scenes/ui/item_wheel.gd")
const ItemLinesScript := preload("res://combat/scripts/item_lines.gd")
const INFO_CARD_NODE_NAME := "WorldItemInfoCard"
const ITEMS_INDICATOR_GAP_PX := 10.0
const PICKUP_HOST_NAME := "WorldItemScatter"
const INTERACT_PAD_PX := 8.0
const ITEM_SEPARATION_PX := 220.0
const SPOT_SCAN_STEP_PX := 128.0
const WALK_CELL_PX := 64.0
const UNPLACED_EPS := 0.5

const RANK_PREFIXES: PackedStringArray = ["C", "U", "R", "E", "L"]
const RANK_NAMES: PackedStringArray = [
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
]
const MAX_RANK := 4

const STEP_CHANCE_BASE := 0.001
const STEP_CHANCE_PER_CLEARED_AREA := 0.0015
const STEP_CHANCE_MAX := 0.01
const STEP_GRACE_AFTER_FIGHT := 200
const MAX_STEP_FIGHTS_PER_VISIT := 2

const AREAS := {
	"halls": {
		"label": "HALLS",
		"families": ["F", "H", "M"],
		"rooms": {


			"res://scenes/Arc_1/1.2_Corridor.tscn": 0,
			"res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn": 1,
		},
	},
	"cafeteria": {
		"label": "CAFETERIA",
		"families": ["A", "D", "M"],
		"rooms": {
			"res://scenes/Arc_2/2.1_Cafeteria.tscn": 3,
		},
	},
	"kitchen": {
		"label": "KITCHEN",
		"families": ["B", "E", "H"],
		"rooms": {
			"res://scenes/Arc_2/2.3_Kitchen.tscn": 2,
		},
	},
	"lounge": {
		"label": "TEACHERS LOUNGE",
		"families": ["C", "H", "M"],
		"rooms": {
			"res://scenes/Arc_4/4.1_TeachersLounge.tscn": 2,
		},
	},
	"classroom": {
		"label": "CLASSROOM",
		"families": ["D", "E", "A"],
		"rooms": {
			"res://scenes/Arc_5/5.1_Classroom.tscn": 2,
		},
	},
	"basement": {
		"label": "BASEMENT",
		"families": ["G", "B", "F"],
		"rooms": {
			"res://scenes/Arc_1/1.4_BasementDoor.tscn": 1,
		},
	},
	"backyard": {
		"label": "BACKYARD",
		"families": ["C", "F", "G"],
		"walk": false,
		"rooms": {
			"res://scenes/Arc_3/3.1_Backyard.tscn": 2,
		},
	},
}

const AREA_ROLL_ORDER: PackedStringArray = [
	"basement", "cafeteria", "classroom", "halls", "kitchen", "lounge", "backyard",
]

const ROOM_ANSWER_ALIASES := {
	"res://scenes/Arc_2/2.1_Cafeteria.tscn": ["cafeteria"],
	"res://scenes/Arc_2/2.3_Kitchen.tscn": ["kitchen"],
	"res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn": [
		"hallway", "hall", "halls", "classrooms corridor",
	],
	"res://scenes/Arc_4/4.1_TeachersLounge.tscn": ["teachers lounge", "lounge"],
	"res://scenes/Arc_5/5.1_Classroom.tscn": ["classroom"],
	"res://scenes/Arc_1/1.4_BasementDoor.tscn": ["basement", "basement door"],
	"res://scenes/Arc_3/3.1_Backyard.tscn": ["backyard"],
}

const REASON_WALK := "walk"
const REASON_ITEM := "item_pickup"
const REASON_LORE := "lore_pickup"
const REASON_MEMORY := "memory"
const REASON_LOCKER_TUTORIAL := "locker_tutorial"

const TUTORIAL_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"

const GATED_WALK_SCENES: PackedStringArray = [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
]

var _rank: Dictionary = {}
var _engaged: Dictionary = {}
var _cleared: Dictionary = {}
var _upgrade_spent: Dictionary = {}
var _room_items: Dictionary = {}
var _lore_fights: Dictionary = {}
var _item_seed: int = 0
const ITEM_ROLL_SALT := 0xA5A511
const PLACE_SALT := 0x5A5A22

var _steps_since_fight: int = STEP_GRACE_AFTER_FIGHT
var _step_fights_this_visit: int = 0
var _rng := RandomNumberGenerator.new()
var _pending_return_scene: String = ""
var _pending_return_tex := Vector2.ZERO
var _pending_return_valid := false
var _starting_fight := false
var _populate_token: Dictionary = {}
var _encounters_suppressed := false
var _spot_pass := 0
var _spot_job_running := false


func _ready() -> void:
	_rng.randomize()
	reset_world()
	var wheel := WheelScript.new()
	wheel.name = "ItemWheel"
	add_child(wheel)
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	_ensure_opening_room()


func is_enabled() -> bool:
	if OS.has_environment("AXEL_WORLD_COMBAT"):
		return OS.get_environment("AXEL_WORLD_COMBAT") != "0"
	return true


func encounters_suppressed() -> bool:
	return OS.is_debug_build() and _encounters_suppressed


func set_encounters_suppressed(on: bool) -> void:
	if not OS.is_debug_build():
		return
	_encounters_suppressed = on


func reset_world() -> void:
	_spot_pass += 1
	_rank.clear()
	_engaged.clear()
	_cleared.clear()
	_upgrade_spent.clear()
	_room_items.clear()
	_lore_fights.clear()
	_item_seed = 0
	for area_id in AREAS.keys():
		_rank[area_id] = 0
		_engaged[area_id] = false
		_cleared[area_id] = false
		_upgrade_spent[area_id] = false
	_steps_since_fight = STEP_GRACE_AFTER_FIGHT
	_step_fights_this_visit = 0
	_pending_return_scene = ""
	_pending_return_valid = false
	_starting_fight = false


func area_for_scene(scene_path: String) -> String:
	if scene_path.is_empty():
		return ""
	for area_id in AREAS.keys():
		if (AREAS[area_id]["rooms"] as Dictionary).has(scene_path):
			return String(area_id)
	return ""


func items_indicator_reaches_player(scene: Node, tex_pos: Vector2) -> bool:
	var env := _env_of(scene)
	if env == null:
		return false
	return _cell_on_floor(_player_floor(scene, env), tex_pos)


func is_indoor_scene(scene_path: String) -> bool:
	return not area_for_scene(scene_path).is_empty()


func can_walk_fight(scene_path: String) -> bool:
	if GATED_WALK_SCENES.has(scene_path):
		return walk_fights_unlocked()
	var area_id := area_for_scene(scene_path)
	if area_id.is_empty():
		return false
	return bool((AREAS[area_id] as Dictionary).get("walk", true))


func floor_slot_count(scene_path: String) -> int:
	var area_id := area_for_scene(scene_path)
	if area_id.is_empty():
		return 0
	return int((AREAS[area_id]["rooms"] as Dictionary).get(scene_path, 0))


func placed_floor_items(scene_path: String) -> Array:
	var out: Array = []
	for entry in (_room_items.get(scene_path, []) as Array):
		var placed: Dictionary = entry
		if bool(placed.get("taken", false)):
			continue
		var spot := Vector2(float(placed.get("x", 0.0)), float(placed.get("y", 0.0)))
		if _is_unplaced_spot(spot):
			continue
		out.append({
			"id": String(placed.get("id", "")),
			"x": spot.x,
			"y": spot.y,
		})
	return out


func map_can_travel(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("has_visited"):
		return false
	if not bool(gm.call("has_visited", scene_path)):
		return false
	if floor_slot_count(scene_path) <= 0:
		return true
	return _scene_took_floor_item(scene_path)


func _scene_took_floor_item(scene_path: String) -> bool:
	for entry in (_room_items.get(scene_path, []) as Array):
		if bool((entry as Dictionary).get("taken", false)):
			return true
	return false


func walk_fights_unlocked() -> bool:
	var run := _run()
	if run == null:
		return false
	if not bool(run.state.tutorial_fight_done):
		return false
	return run.state.fought_rooms.size() > 0


func area_rank(area_id: String) -> int:
	return int(_rank.get(area_id, 0))


func area_rank_name(area_id: String) -> String:
	return String(RANK_NAMES[clampi(area_rank(area_id), 0, MAX_RANK)])


func cleared_area_count() -> int:
	var n := 0
	for area_id in AREAS.keys():
		if bool(_cleared.get(area_id, false)):
			n += 1
	return n


func step_chance() -> float:
	var chance := STEP_CHANCE_BASE + STEP_CHANCE_PER_CLEARED_AREA * float(cleared_area_count())
	return clampf(chance, STEP_CHANCE_BASE, STEP_CHANCE_MAX)


func register_walk_step() -> void:
	if not is_enabled() or _starting_fight or encounters_suppressed():
		return
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return
	var scene := _current_scene()
	if scene == null:
		return
	var path := scene.scene_file_path
	if not can_walk_fight(path):
		return
	_steps_since_fight += 1
	if _steps_since_fight < STEP_GRACE_AFTER_FIGHT:
		return
	if _step_fights_this_visit >= MAX_STEP_FIGHTS_PER_VISIT:
		return
	if _rng.randf() >= step_chance():
		return
	_step_fights_this_visit += 1
	start_fight_here(REASON_WALK)


func start_fight_here(reason: String) -> bool:
	if not is_enabled() or _starting_fight or encounters_suppressed():
		return false
	var scene := _current_scene()
	if scene == null:
		return false
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return false
	_starting_fight = true
	_steps_since_fight = 0
	var tex := Vector2.ZERO
	var has_tex := false
	var env := _env_of(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	if env != null and player != null:
		tex = PlayerSpawnSync.capture_tex(env, player)
		has_tex = true
	if player != null and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)
	_record_fight_room(scene.scene_file_path)
	AxelRun.enter_world_encounter(reason, scene.scene_file_path, tex, has_tex)
	return true


func start_fight_to_scene(reason: String, return_scene: String) -> bool:
	if not is_enabled() or _starting_fight or encounters_suppressed():
		return false
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return false
	_starting_fight = true
	_steps_since_fight = 0
	_record_fight_room(return_scene)
	AxelRun.enter_world_encounter(reason, return_scene, Vector2.ZERO, false)
	return true


func start_memory_fight(return_scene: String) -> bool:
	if not is_enabled():
		return false
	return start_fight_to_scene(REASON_MEMORY, return_scene)


func start_lore_fight(flag_name: String, return_scene: String, use_player_spot: bool) -> bool:
	if not is_enabled():
		return false
	if bool(_lore_fights.get(flag_name, false)):
		return false
	var started := false
	if use_player_spot:
		started = start_fight_here(REASON_LORE)
	if not started:
		started = start_fight_to_scene(REASON_LORE, return_scene)
	if not started:
		return false
	_lore_fights[flag_name] = true
	_save()
	return true


func has_lore_fight_happened(flag_name: String) -> bool:
	return bool(_lore_fights.get(flag_name, false))


func queue_locker_tutorial_fight() -> bool:
	if not is_enabled():
		return false
	var run := _run()
	if run == null:
		return false
	if bool(run.state.tutorial_fight_done) or bool(run.state.tutorial_fight_pending):
		return false
	run.state.tutorial_fight_pending = true
	_save()
	return true


func is_locker_tutorial_pending() -> bool:
	var run := _run()
	return run != null and bool(run.state.tutorial_fight_pending)


func _start_locker_tutorial(scene: Node) -> void:
	await _settle_frames(scene, 12)
	if scene != _current_scene():
		return
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return
	if not bool(run.state.tutorial_fight_pending):
		return
	if not start_fight_here(REASON_LOCKER_TUTORIAL):
		return
	run.state.tutorial_fight_pending = false
	if bool(run.call("is_in_encounter")):
		run.state.tutorial_fight_done = true
	else:
		run.state.tutorial_fight_pending = true
	_save()


func _record_fight_room(scene_path: String) -> void:
	if scene_path.is_empty() or GATED_WALK_SCENES.has(scene_path):
		return
	var run := _run()
	if run == null:
		return
	var rooms: Array = Array(run.state.fought_rooms)
	if rooms.has(scene_path):
		return
	rooms.append(scene_path)
	run.state.fought_rooms = PackedStringArray(rooms)


func notify_fight_won(_reason: String, dest_scene: String, tex: Vector2, has_tex: bool) -> void:
	notify_fight_ended()
	_pending_return_scene = dest_scene
	_pending_return_tex = tex
	_pending_return_valid = has_tex


func notify_fight_ended() -> void:
	_starting_fight = false
	_steps_since_fight = 0


func item_rank_for_scene(scene_path: String) -> int:
	return area_rank(area_for_scene(scene_path))


func item_rank_of_id(item_id: String) -> int:
	if item_id.is_empty():
		return -1
	return RANK_PREFIXES.find(item_id.left(1))


func take_item(scene_path: String, index: int) -> void:
	var entries: Array = _room_items.get(scene_path, [])
	if index < 0 or index >= entries.size():
		return
	var entry: Dictionary = entries[index]
	if bool(entry.get("taken", false)):
		return
	entry["taken"] = true
	var run := _run()
	if run != null:
		var owned: Array = Array(run.state.owned_item_ids)
		var item_id := String(entry.get("id", ""))
		if not item_id.is_empty() and not owned.has(item_id):
			owned.append(item_id)
			run.state.owned_item_ids = PackedStringArray(owned)
		if not item_id.is_empty() and run.has_method("equip_owned_if_free"):
			run.call("equip_owned_if_free", item_id)
	var area_id := area_for_scene(scene_path)
	var first_in_area := not bool(_cleared.get(area_id, false))
	_engage_area(area_id)
	_refresh_cleared(area_id)
	if first_in_area and bool(_cleared.get(area_id, false)):
		_retier_open_areas()
	_save()
	map_spots_updated.emit()


func _engage_area(area_id: String) -> void:
	if area_id.is_empty() or bool(_engaged.get(area_id, false)):
		return
	_engaged[area_id] = true
	_upgrade_untouched_areas(area_id)


func _upgrade_untouched_areas(source_area: String) -> void:
	if source_area.is_empty() or bool(_upgrade_spent.get(source_area, false)):
		return
	_upgrade_spent[source_area] = true
	for area_id in AREAS.keys():
		if area_id == source_area:
			continue
		if _area_is_frozen(area_id):
			continue
		_rank[area_id] = mini(int(_rank.get(area_id, 0)) + 1, MAX_RANK)


func _refresh_cleared(area_id: String) -> void:
	if area_id.is_empty() or bool(_cleared.get(area_id, false)):
		return
	if not _area_has_taken_item(area_id):
		return
	_cleared[area_id] = true
	_upgrade_untouched_areas(area_id)


func _area_is_frozen(area_id: String) -> bool:
	return bool(_engaged.get(area_id, false)) or bool(_cleared.get(area_id, false))


func _area_has_taken_item(area_id: String) -> bool:
	if area_id.is_empty() or not AREAS.has(area_id):
		return false
	var rooms: Dictionary = AREAS[area_id]["rooms"]
	for room_path in rooms.keys():
		for entry in (_room_items.get(String(room_path), []) as Array):
			if bool((entry as Dictionary).get("taken", false)):
				return true
	return false


func _sync_cleared_from_taken() -> void:
	for area_id in AREAS.keys():
		if _area_has_taken_item(String(area_id)):
			_cleared[area_id] = true
			_engaged[area_id] = true


func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"item_seed": _item_seed,
		"rank": _rank.duplicate(true),
		"engaged": _engaged.duplicate(true),
		"cleared": _cleared.duplicate(true),
		"upgrade_spent": _upgrade_spent.duplicate(true),
		"room_items": _room_items.duplicate(true),
		"lore_fights": _lore_fights.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	reset_world()
	if data.is_empty():
		return
	_item_seed = int(data.get("item_seed", 0))
	for area_id in AREAS.keys():
		_rank[area_id] = clampi(int((data.get("rank", {}) as Dictionary).get(area_id, 0)), 0, MAX_RANK)
		_engaged[area_id] = bool((data.get("engaged", {}) as Dictionary).get(area_id, false))
		_cleared[area_id] = bool((data.get("cleared", {}) as Dictionary).get(area_id, false))
		_upgrade_spent[area_id] = bool((data.get("upgrade_spent", {}) as Dictionary).get(area_id, false))
	var saved_rooms: Dictionary = data.get("room_items", {})
	for room_path in saved_rooms.keys():
		var out: Array = []
		for entry in (saved_rooms[room_path] as Array):
			var d: Dictionary = entry
			out.append({
				"id": String(d.get("id", "")),
				"x": float(d.get("x", 0.0)),
				"y": float(d.get("y", 0.0)),
				"taken": bool(d.get("taken", false)),
			})
		_room_items[String(room_path)] = out
	_lore_fights = (data.get("lore_fights", {}) as Dictionary).duplicate(true)
	_sync_cleared_from_taken()
	_fill_missing_room_lists()
	if _any_area_frozen():
		_retier_open_areas()
	_queue_map_spots()


func _save() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and bool(saves.call("is_active")):
		saves.call("save_active")


func _on_scene_changed() -> void:
	_step_fights_this_visit = 0
	_starting_fight = false
	var scene := _current_scene()
	if scene == null:
		return
	var path := scene.scene_file_path
	if path.begins_with("res://combat/"):
		return
	_mark_visited_if_walkable(scene)
	if _pending_return_valid and _pending_return_scene == path:
		_apply_return_placement(scene)
	elif _pending_return_scene == path:
		_pending_return_scene = ""
	if is_enabled() and is_indoor_scene(path):
		_populate_room(scene)
	if is_enabled() and path == TUTORIAL_SCENE and is_locker_tutorial_pending():
		_start_locker_tutorial(scene)
	_request_items_wheel_lesson(scene)


func _request_items_wheel_lesson(scene: Node) -> void:
	if scene.find_child("Player", true, false) == null:
		return
	if _owned_item_ids().is_empty():
		return
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("request"):
		tutorial.call("request", "items_wheel")


func _mark_visited_if_walkable(scene: Node) -> void:
	if scene.find_child("Player", true, false) == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("mark_room_visited"):
		gm.call("mark_room_visited", scene.scene_file_path)


func _apply_return_placement(scene: Node) -> void:
	var tex := _pending_return_tex
	_pending_return_scene = ""
	_pending_return_valid = false
	await _settle_frames(scene, 10)
	if scene != _current_scene():
		return
	var env := _env_of(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	if env == null or player == null:
		return
	PlayerSpawnSync.apply_tex(env, player, tex)


func _ensure_opening_room() -> void:
	for _i in 60:
		if get_tree() == null:
			return
		var scene := _current_scene()
		if scene != null:
			var path := scene.scene_file_path
			if is_indoor_scene(path):
				var area_id := area_for_scene(path)
				var want: int = int((AREAS[area_id]["rooms"] as Dictionary).get(path, 0))
				if want > 0:
					_populate_room(scene)
			return
		await get_tree().process_frame


func _populate_room(scene: Node) -> void:
	var path := scene.scene_file_path
	var area_id := area_for_scene(path)
	if area_id.is_empty():
		return
	var want: int = int((AREAS[area_id]["rooms"] as Dictionary).get(path, 0))
	if want <= 0:
		return
	var token := int(_populate_token.get(path, 0)) + 1
	_populate_token[path] = token
	await _wait_for_item_physics(scene)
	if not _populate_still(scene, path, token):
		return
	var env := _env_of(scene)
	if env == null:
		return
	_apply_room_placements(scene, env, area_id, want, path)
	_spawn_pickups(scene, env, path)
	if not _room_has_unplaced(path):
		return
	for _i in 20:
		if get_tree() == null or not is_instance_valid(scene):
			return
		await get_tree().physics_frame
	if not _populate_still(scene, path, token):
		return
	env = _env_of(scene)
	if env == null:
		return
	_apply_room_placements(scene, env, area_id, want, path)
	_spawn_pickups(scene, env, path)


func _apply_room_placements(
	scene: Node, env: Node2D, area_id: String, want: int, path: String
) -> void:
	if not _room_items.has(path):
		_room_items[path] = _decide_placements(scene, env, area_id, want, path)
		_save()
	else:
		_fill_unplaced_spots(scene, env, path)
		_repair_illegal_spots(scene, env, path)


func _populate_still(scene: Node, path: String, token: int) -> bool:
	return (
		is_instance_valid(scene)
		and scene == _current_scene()
		and scene.scene_file_path == path
		and int(_populate_token.get(path, 0)) == token
	)


func _wait_for_item_physics(scene: Node) -> void:
	for _i in 40:
		if get_tree() == null or not is_instance_valid(scene):
			return
		var env := _env_of(scene)
		var world := env.get_world_2d() if env != null else null
		if world != null and world.direct_space_state != null:
			await get_tree().physics_frame
			await get_tree().physics_frame
			return
		await get_tree().physics_frame


func _room_has_unplaced(path: String) -> bool:
	for entry in _room_items.get(path, []):
		var placed: Dictionary = entry
		if bool(placed.get("taken", false)):
			continue
		var spot := Vector2(float(placed.get("x", 0.0)), float(placed.get("y", 0.0)))
		if _is_unplaced_spot(spot):
			return true
	return false


func _is_unplaced_spot(spot: Vector2) -> bool:
	return absf(spot.x) < UNPLACED_EPS and absf(spot.y) < UNPLACED_EPS


func plan_floor_items(run_seed: int) -> void:
	_item_seed = run_seed if run_seed != 0 else 1
	_room_items.clear()
	_roll_open_area_ids()
	_queue_map_spots()


func map_spots_settled() -> bool:
	return not _spot_job_running and not _any_unplaced_floor_spots()


func _queue_map_spots() -> void:
	_spot_pass += 1
	if _spot_job_running:
		return
	_spot_job_running = true
	_run_spot_job()


func _run_spot_job() -> void:
	if get_tree() != null:
		await get_tree().process_frame
	while is_inside_tree():
		var pass_id := _spot_pass
		await _place_unplaced_rooms(pass_id)
		if not is_inside_tree():
			break
		if pass_id != _spot_pass and _any_unplaced_floor_spots():
			continue
		break
	_spot_job_running = false
	if is_inside_tree():
		map_spots_updated.emit()


func _any_unplaced_floor_spots() -> bool:
	return not _unplaced_room_paths().is_empty()


func _unplaced_room_paths() -> Array[String]:
	var paths: Array[String] = []
	for area_id in AREA_ROLL_ORDER:
		var rooms: Dictionary = AREAS[area_id]["rooms"]
		var keys: Array = rooms.keys()
		keys.sort()
		for key in keys:
			var path := String(key)
			if int(rooms[key]) <= 0:
				continue
			if _room_has_unplaced(path):
				paths.append(path)
	return paths


func _place_unplaced_rooms(pass_id: int) -> void:
	for path in _unplaced_room_paths():
		if pass_id != _spot_pass or not is_inside_tree():
			return
		if not _room_has_unplaced(path):
			continue
		var current := _current_scene()
		if current != null and current.scene_file_path == path:
			continue
		await _probe_place_room(path, pass_id)
		if pass_id != _spot_pass:
			return
		map_spots_updated.emit()


func _probe_place_room(path: String, pass_id: int) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("AxelWorld: map spots could not load %s" % path)
		return
	var scene := packed.instantiate()
	var player := scene.find_child("Player", true, false) as Node
	var args := _camera_layout_args(scene)
	args["view"] = _game_view_size()
	# Room scripts would play enter lines and steal the camera. Collision stays.
	_silence_probe(scene, player)
	var vp := SubViewport.new()
	vp.name = "MapSpotProbe"
	var view: Vector2 = args["view"]
	vp.size = Vector2i(maxi(int(view.x), 2), maxi(int(view.y), 2))
	vp.world_2d = World2D.new()
	vp.disable_3d = true
	vp.gui_disable_input = true
	vp.handle_input_locally = false
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	vp.add_child(scene)
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	_layout_probe(scene, args)
	var probe_ready := await _await_probe_space(scene, pass_id)
	if probe_ready and pass_id == _spot_pass and _room_has_unplaced(path):
		var env := _env_of(scene)
		var area_id := area_for_scene(path)
		var want := floor_slot_count(path)
		if env != null and not area_id.is_empty() and want > 0:
			_apply_room_placements(scene, env, area_id, want, path)
	if is_instance_valid(vp):
		vp.queue_free()


func _camera_layout_args(scene: Node) -> Dictionary:
	var cam := scene.find_child("Camera2D", true, false) as Camera2D
	var fit: LayoutScript.FitMode = LayoutScript.FitMode.COVER
	var background_y := 0.0
	var edge := -1.0
	if cam != null:
		fit = cam.fit_mode as LayoutScript.FitMode
		background_y = cam.background_y
		edge = cam.edge_reveal
	if edge < 0.0 and fit == LayoutScript.FitMode.COVER:
		edge = LayoutScript.MAX_EDGE_REVEAL
	else:
		edge = clampf(edge, 0.0, 0.5)
	return {"fit": fit, "y": background_y, "edge": edge}


func _layout_probe(scene: Node, args: Dictionary) -> void:
	var bg := scene.get_node_or_null("WalkableWorld/Background") as Sprite2D
	if bg == null:
		bg = scene.find_child("Background", true, false) as Sprite2D
	var env := _env_of(scene)
	var player := scene.find_child("Player", true, false) as CharacterBody2D
	if bg == null or env == null or player == null:
		return
	var view: Vector2 = args["view"]
	var fit: LayoutScript.FitMode = args["fit"]
	var background_y: float = args["y"]
	var edge: float = args["edge"]
	var sync := PlayerCoverSync.new()
	sync.bind_from_player(player)
	sync.bind_design_from_background(bg, fit, background_y)
	var layout := LayoutScript.apply(bg, view, fit, background_y, edge)
	if layout.is_empty():
		return
	LayoutScript.apply_to_sprite(bg, layout)
	var cover := float(layout["scale_factor"])
	var pos: Vector2 = layout["position"]
	var tex_pos := PlayerSpawnSync.capture_tex(env, player)
	env.position = pos
	env.scale = Vector2.ONE * cover
	PlayerSpawnSync.apply_tex(env, player, tex_pos)
	sync.apply(player, cover, pos)
	for child in env.get_children():
		if child is StaticBody2D or child is Area2D:
			child.position = child.position


func _await_probe_space(scene: Node, pass_id: int) -> bool:
	for _i in 30:
		if pass_id != _spot_pass or not is_instance_valid(scene):
			return false
		var env := _env_of(scene)
		var world := env.get_world_2d() if env != null else null
		if world != null and world.direct_space_state != null:
			if get_tree() == null:
				return false
			await get_tree().physics_frame
			await get_tree().physics_frame
			return pass_id == _spot_pass and is_instance_valid(scene)
		if get_tree() == null:
			return false
		await get_tree().physics_frame
	return false


func _game_view_size() -> Vector2:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return Vector2(1920, 1280)
	var size := tree.root.get_visible_rect().size
	if size.x < 320.0 or size.y < 240.0:
		return Vector2(1920, 1280)
	return size


func _silence_probe(node: Node, player: Node) -> void:
	var drop: Array[Node] = []
	_silence_probe_walk(node, player, drop)
	for extra in drop:
		if is_instance_valid(extra):
			extra.free()


func _silence_probe_walk(node: Node, player: Node, drop: Array[Node]) -> void:
	if node is CanvasLayer and node.name != "PlayerLayer":
		drop.append(node)
		return
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).autoplay = false
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).autoplay = false
	if node != player:
		node.set_script(null)
	for child in node.get_children():
		_silence_probe_walk(child, player, drop)


func _retier_open_areas() -> void:
	_roll_open_area_ids()


func _any_area_frozen() -> bool:
	for area_id in AREAS.keys():
		if _area_is_frozen(String(area_id)):
			return true
	return false


func _fill_missing_room_lists() -> void:
	var missing := false
	for area_id in AREA_ROLL_ORDER:
		var rooms: Dictionary = AREAS[area_id]["rooms"]
		for path in rooms.keys():
			if int(rooms[path]) > 0 and not _room_items.has(String(path)):
				missing = true
				break
		if missing:
			break
	if not missing:
		return
	var blocked := _blocked_item_ids()
	var used_lanes: Array = []
	for item_id in blocked:
		var lane := _lane_of(String(item_id))
		if not lane.is_empty() and not used_lanes.has(lane):
			used_lanes.append(lane)
	for area_id in AREA_ROLL_ORDER:
		var rooms: Dictionary = AREAS[area_id]["rooms"]
		var paths: Array = rooms.keys()
		paths.sort()
		for path in paths:
			var room_path := String(path)
			var want: int = int(rooms[path])
			if want <= 0 or _room_items.has(room_path):
				continue
			var rng := _room_rng(room_path, ITEM_ROLL_SALT)
			var entries: Array = []
			for _i in want:
				var item_id := _roll_item(String(area_id), rng, used_lanes, blocked)
				if item_id.is_empty():
					continue
				used_lanes.append(_lane_of(item_id))
				_append_unique(blocked, item_id)
				entries.append({
					"id": item_id,
					"x": 0.0,
					"y": 0.0,
					"taken": false,
				})
			_room_items[room_path] = entries


func _roll_open_area_ids() -> void:
	var frozen_ids := _frozen_floor_ids()
	var owned_ids := _owned_item_ids()
	var blocked: Array = owned_ids.duplicate()
	for item_id in frozen_ids:
		_append_unique(blocked, item_id)
	var used_lanes: Array = []
	for item_id in frozen_ids:
		var frozen_lane := _lane_of(item_id)
		if not frozen_lane.is_empty() and not used_lanes.has(frozen_lane):
			used_lanes.append(frozen_lane)
	for item_id in owned_ids:
		var owned_lane := _lane_of(item_id)
		if not owned_lane.is_empty() and not used_lanes.has(owned_lane):
			used_lanes.append(owned_lane)
	for area_id in AREA_ROLL_ORDER:
		if _area_is_frozen(String(area_id)):
			continue
		var rooms: Dictionary = AREAS[area_id]["rooms"]
		var paths: Array = rooms.keys()
		paths.sort()
		for path in paths:
			var want: int = int(rooms[path])
			if want <= 0:
				continue
			var rng := _room_rng(String(path), ITEM_ROLL_SALT)
			var existing: Array = _room_items.get(String(path), [])
			var entries: Array = []
			for i in want:
				var prev: Dictionary = existing[i] if i < existing.size() else {}
				if bool(prev.get("taken", false)):
					entries.append(prev)
					continue
				var item_id := _roll_item(String(area_id), rng, used_lanes, blocked)
				if item_id.is_empty():
					continue
				used_lanes.append(_lane_of(item_id))
				_append_unique(blocked, item_id)
				entries.append({
					"id": item_id,
					"x": float(prev.get("x", 0.0)),
					"y": float(prev.get("y", 0.0)),
					"taken": false,
				})
			_room_items[String(path)] = entries


func _effective_item_seed() -> int:
	if _item_seed != 0:
		return _item_seed
	var run := _run()
	if run != null:
		var s := int(run.state.seed)
		if s != 0:
			_item_seed = s
			return s
	return 1


func _room_rng(path: String, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var mixed := int(_effective_item_seed()) ^ int(hash(path)) ^ salt
	if mixed == 0:
		mixed = 1
	rng.seed = mixed
	return rng


func _decide_placements(
	scene: Node, env: Node2D, area_id: String, want: int, path: String
) -> Array:
	var rng := _room_rng(path, ITEM_ROLL_SALT)
	var ids: Array = []
	var used_lanes: Array = []
	for _i in want:
		var item_id := _roll_item(area_id, rng, used_lanes)
		if item_id.is_empty():
			continue
		used_lanes.append(_lane_of(item_id))
		ids.append(item_id)
	return _spots_for_ids(scene, env, path, ids)


func _fill_unplaced_spots(scene: Node, env: Node2D, path: String) -> void:
	var entries: Array = _room_items.get(path, [])
	if entries.is_empty():
		return
	var ids: Array = []
	var need := false
	for entry in entries:
		var d: Dictionary = entry
		ids.append(String(d.get("id", "")))
		if bool(d.get("taken", false)):
			continue
		if _is_unplaced_spot(Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))):
			need = true
	if not need:
		return
	var placed := _spots_for_ids(scene, env, path, ids)
	for i in mini(placed.size(), entries.size()):
		var src: Dictionary = placed[i]
		var dst: Dictionary = entries[i]
		if bool(dst.get("taken", false)):
			continue
		dst["id"] = String(src.get("id", dst.get("id", "")))
		dst["x"] = float(src.get("x", 0.0))
		dst["y"] = float(src.get("y", 0.0))
		entries[i] = dst
	_room_items[path] = entries
	_save()


func _spots_for_ids(scene: Node, env: Node2D, path: String, ids: Array) -> Array:
	var rng := _room_rng(path, PLACE_SALT)
	var tex_size := _texture_size(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	var exclude: Array[RID] = []
	if player is CollisionObject2D:
		exclude.append((player as CollisionObject2D).get_rid())
	var want: int = ids.size()
	var candidates := _candidate_spots(scene, env, tex_size, exclude, want)
	var picked := _pick_spots(candidates, want, rng)
	var out: Array = []
	for i in want:
		var spot := picked[i] if i < picked.size() else Vector2.INF
		if not _is_finite_spot(spot) or _is_unplaced_spot(spot):
			push_warning("AxelWorld: no wall-clear floor for an item in %s" % path)
			out.append({
				"id": String(ids[i]),
				"x": 0.0,
				"y": 0.0,
				"taken": false,
			})
			continue
		out.append({
			"id": String(ids[i]),
			"x": spot.x,
			"y": spot.y,
			"taken": false,
		})
	return out


func _candidate_spots(
	scene: Node, env: Node2D, tex_size: Vector2, exclude: Array[RID], want: int
) -> Array[Vector2]:
	var floor_cells := _player_floor(scene, env)
	var authored := _authored_marker_spots(scene, env)
	if not authored.is_empty():
		var clear_marks := _filter_clear_spots(env, authored, exclude, true, floor_cells)
		if clear_marks.is_empty():
			clear_marks = _filter_clear_spots(env, authored, exclude, false, floor_cells)
		if not clear_marks.is_empty():
			return _thin_spots(clear_marks)
	var strict := _scan_clear_spots(env, tex_size, exclude, true, floor_cells)
	if strict.size() >= want:
		return strict
	var loose := _scan_clear_spots(env, tex_size, exclude, false, floor_cells)
	if loose.size() > strict.size():
		return loose
	return strict


func _authored_marker_spots(scene: Node, env: Node2D) -> Array[Vector2]:
	var root := scene.find_child("ItemSpawnPoints", true, false)
	if root == null:
		return []
	var spots: Array[Vector2] = []
	for child in root.get_children():
		if child is Marker2D:
			spots.append(env.to_local((child as Node2D).global_position))
	return spots


func _filter_clear_spots(
	env: Node2D,
	spots: Array[Vector2],
	exclude: Array[RID],
	avoid_zones: bool,
	floor_cells: Dictionary,
) -> Array[Vector2]:
	var clear: Array[Vector2] = []
	for spot in spots:
		if not _spot_rejected(env, spot, exclude, avoid_zones, clear, floor_cells):
			clear.append(spot)
	return clear


func _scan_clear_spots(
	env: Node2D,
	tex_size: Vector2,
	exclude: Array[RID],
	avoid_zones: bool,
	floor_cells: Dictionary,
) -> Array[Vector2]:
	var bounds := _search_bounds(tex_size)
	var raw: Array[Vector2] = []
	var y := bounds.position.y
	while y <= bounds.end.y + 0.01:
		var x := bounds.position.x
		while x <= bounds.end.x + 0.01:
			var candidate := Vector2(x, y)
			if not _spot_rejected(env, candidate, exclude, avoid_zones, [], floor_cells):
				raw.append(candidate)
			x += SPOT_SCAN_STEP_PX
		y += SPOT_SCAN_STEP_PX
	return _thin_spots(raw)


func _thin_spots(raw: Array[Vector2]) -> Array[Vector2]:
	var kept: Array[Vector2] = []
	for spot in raw:
		var too_close := false
		for other in kept:
			if spot.distance_to(other) < ITEM_SEPARATION_PX:
				too_close = true
				break
		if not too_close:
			kept.append(spot)
	return kept


func _pick_spots(
	candidates: Array[Vector2], count: int, rng: RandomNumberGenerator
) -> Array[Vector2]:
	var order: Array[Vector2] = []
	for spot in candidates:
		order.append(spot)
	for i in range(order.size() - 1, 0, -1):
		var j := posmod(rng.randi(), i + 1)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	var picked: Array[Vector2] = []
	for spot in order:
		if picked.size() >= count:
			break
		var too_close := false
		for other in picked:
			if spot.distance_to(other) < ITEM_SEPARATION_PX:
				too_close = true
				break
		if not too_close:
			picked.append(spot)
	return picked


func _texture_size(scene: Node) -> Vector2:
	var bg := scene.get_node_or_null("WalkableWorld/Background") as Sprite2D
	if bg == null:
		bg = scene.find_child("Background", true, false) as Sprite2D
	if bg != null and bg.texture != null:
		return Vector2(bg.texture.get_width(), bg.texture.get_height())
	return Vector2(1920.0, 1280.0)


func _find_free_spot(
	env: Node2D,
	wanted: Vector2,
	tex_size: Vector2,
	fallback: Vector2,
	exclude: Array[RID],
	occupied: Array = [],
	floor_cells: Dictionary = {},
) -> Vector2:
	for avoid_zones in [true, false]:
		for use_occupied in [true, false]:
			var sep: Array = occupied if use_occupied else []
			var near := _search_near(
				env, wanted, tex_size, exclude, avoid_zones, sep, floor_cells
			)
			if _is_finite_spot(near):
				return near
			var fallback_spot := _clamp_spot(fallback, tex_size)
			if not _spot_rejected(env, fallback_spot, exclude, avoid_zones, sep, floor_cells):
				return fallback_spot
			var grid := _search_grid(
				env, wanted, tex_size, exclude, avoid_zones, sep, floor_cells
			)
			if _is_finite_spot(grid):
				return grid
	return Vector2.INF


func _repair_illegal_spots(scene: Node, env: Node2D, path: String) -> void:
	var entries: Array = _room_items.get(path, [])
	if entries.is_empty():
		return
	var tex_size := _texture_size(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	var player_tex := PlayerSpawnSync.capture_tex(env, player) if player != null else Vector2.ZERO
	var exclude: Array[RID] = []
	if player is CollisionObject2D:
		exclude.append((player as CollisionObject2D).get_rid())
	var floor_cells := _player_floor(scene, env)
	var occupied: Array = []
	var changed := false
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if bool(entry.get("taken", false)):
			continue
		var spot := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))

		if _spot_rejected(env, spot, exclude, false, [], floor_cells):
			var away := 260.0 * (1.0 if i % 2 == 0 else -1.0) * float(i + 1)
			var fallback := Vector2(
				clampf(player_tex.x + away, tex_size.x * 0.08, tex_size.x * 0.92), player_tex.y
			)
			var neu := _find_free_spot(
				env, spot, tex_size, fallback, exclude, occupied, floor_cells
			)
			if _is_finite_spot(neu):
				entry["x"] = neu.x
				entry["y"] = neu.y
				spot = neu
				changed = true
			else:
				push_warning("AxelWorld: saved item %s in %s still overlaps a wall" % [
					String(entry.get("id", "")), path,
				])
		occupied.append(spot)
		entries[i] = entry
	if changed:
		_room_items[path] = entries
		_save()


func _search_near(
	env: Node2D,
	wanted: Vector2,
	tex_size: Vector2,
	exclude: Array[RID],
	avoid_zones: bool,
	occupied: Array,
	floor_cells: Dictionary,
) -> Vector2:
	var step := 40.0
	for ring in 25:
		if ring == 0:
			var origin := _clamp_spot(wanted, tex_size)
			if not _spot_rejected(env, origin, exclude, avoid_zones, occupied, floor_cells):
				return origin
			continue
		var reach := float(ring) * step
		for i in range(-ring, ring + 1):
			var along := float(i) * step
			var ring_spots: Array[Vector2] = [
				Vector2(wanted.x + along, wanted.y - reach),
				Vector2(wanted.x + along, wanted.y + reach),
				Vector2(wanted.x - reach, wanted.y + along),
				Vector2(wanted.x + reach, wanted.y + along),
			]
			for raw in ring_spots:
				var candidate := _clamp_spot(raw, tex_size)
				if not _spot_rejected(
					env, candidate, exclude, avoid_zones, occupied, floor_cells
				):
					return candidate
	return Vector2.INF


func _search_grid(
	env: Node2D,
	wanted: Vector2,
	tex_size: Vector2,
	exclude: Array[RID],
	avoid_zones: bool,
	occupied: Array,
	floor_cells: Dictionary,
) -> Vector2:
	var bounds := _search_bounds(tex_size)
	var step := 64.0
	var y := bounds.position.y
	var rows: Array[float] = []
	while y <= bounds.end.y + 0.01:
		rows.append(y)
		y += step
	rows.sort_custom(func(a: float, b: float) -> bool: return absf(a - wanted.y) < absf(b - wanted.y))
	for row_y in rows:
		var x := bounds.position.x
		while x <= bounds.end.x + 0.01:
			var candidate := Vector2(x, row_y)
			if not _spot_rejected(env, candidate, exclude, avoid_zones, occupied, floor_cells):
				return candidate
			x += step
	return Vector2.INF


func _circle_blocked(
	env: Node2D,
	tex_pos: Vector2,
	exclude: Array[RID],
	avoid_zones: bool,
	occupied: Array,
) -> bool:
	if not _is_finite_spot(tex_pos):
		return true
	for other in occupied:
		if other is Vector2 and tex_pos.distance_to(other) < ITEM_SEPARATION_PX:
			return true
	var world := env.get_world_2d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var circle := CircleShape2D.new()
	circle.radius = PickupScript.RADIUS + INTERACT_PAD_PX
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = env.global_transform * Transform2D(0.0, tex_pos)
	params.collision_mask = 0xFFFFFFFF
	params.exclude = exclude
	params.collide_with_bodies = true
	params.collide_with_areas = avoid_zones
	return not space.intersect_shape(params, 8).is_empty()


func _search_bounds(tex_size: Vector2) -> Rect2:
	var min_x := tex_size.x * 0.08
	var max_x := tex_size.x * 0.92
	var min_y := tex_size.y * 0.10
	var max_y := tex_size.y * 0.92
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _clamp_spot(spot: Vector2, tex_size: Vector2) -> Vector2:
	var bounds := _search_bounds(tex_size)
	return Vector2(
		clampf(spot.x, bounds.position.x, bounds.end.x),
		clampf(spot.y, bounds.position.y, bounds.end.y),
	)


func _is_finite_spot(spot: Vector2) -> bool:
	return is_finite(spot.x) and is_finite(spot.y)


func _spot_rejected(
	env: Node2D,
	tex_pos: Vector2,
	exclude: Array[RID],
	avoid_zones: bool,
	occupied: Array,
	floor_cells: Dictionary,
) -> bool:
	if not _cell_on_floor(floor_cells, tex_pos):
		return true
	return _circle_blocked(env, tex_pos, exclude, avoid_zones, occupied)


func _cell_on_floor(floor_cells: Dictionary, tex_pos: Vector2) -> bool:
	if not _is_finite_spot(tex_pos):
		return false
	return floor_cells.has(_cell_key(tex_pos))


func _player_floor(scene: Node, env: Node2D) -> Dictionary:
	var player := scene.find_child("Player", true, false) as CharacterBody2D
	if player == null:
		return {}
	var front := player.get_node_or_null("CollisionFront") as CollisionShape2D
	if front == null or front.shape == null:
		return {}
	var tex_size := _texture_size(scene)
	var exclude: Array[RID] = [player.get_rid()]
	var seed_cell := _open_seed_cell(env, player, PlayerSpawnSync.capture_tex(env, player), exclude, tex_size)
	if seed_cell.x == 0x7FFFFFFF:
		return {}
	return _flood_floor(env, player, seed_cell, exclude, tex_size)


func _open_seed_cell(
	env: Node2D,
	player: CharacterBody2D,
	tex: Vector2,
	exclude: Array[RID],
	tex_size: Vector2,
) -> Vector2i:
	var origin := _cell_key(tex)
	for ring in 8:
		for y in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if ring != 0 and absi(x) != ring and absi(y) != ring:
					continue
				var cell := origin + Vector2i(x, y)
				if not _cell_inside(cell, tex_size):
					continue
				if not _stand_blocked(env, player, _cell_center(cell), exclude):
					return cell
	return Vector2i(0x7FFFFFFF, 0)


func _flood_floor(
	env: Node2D,
	player: CharacterBody2D,
	seed_cell: Vector2i,
	exclude: Array[RID],
	tex_size: Vector2,
) -> Dictionary:
	var open := {}
	var seen := {}
	var queue: Array[Vector2i] = [seed_cell]
	seen[seed_cell] = true
	open[seed_cell] = true
	var head := 0
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]
	while head < queue.size():
		var here: Vector2i = queue[head]
		head += 1
		for dir in dirs:
			var nxt: Vector2i = here + dir
			if seen.has(nxt):
				continue
			seen[nxt] = true
			if not _cell_inside(nxt, tex_size):
				continue
			if not _cells_connect(env, player, here, nxt, exclude):
				continue
			open[nxt] = true
			queue.append(nxt)
	return open


func _cells_connect(
	env: Node2D,
	player: CharacterBody2D,
	a: Vector2i,
	b: Vector2i,
	exclude: Array[RID],
) -> bool:
	var center_b := _cell_center(b)
	if _stand_blocked(env, player, center_b, exclude):
		return false
	var mid := (_cell_center(a) + center_b) * 0.5
	if _stand_blocked(env, player, mid, exclude):
		return false
	return not _stand_ray_blocked(env, player, _cell_center(a), center_b, exclude)


func _cell_key(tex_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(tex_pos.x / WALK_CELL_PX)),
		int(floor(tex_pos.y / WALK_CELL_PX)),
	)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * WALK_CELL_PX,
		(float(cell.y) + 0.5) * WALK_CELL_PX,
	)


func _cell_inside(cell: Vector2i, tex_size: Vector2) -> bool:
	var center := _cell_center(cell)
	return (
		center.x >= -WALK_CELL_PX
		and center.y >= -WALK_CELL_PX
		and center.x <= tex_size.x + WALK_CELL_PX
		and center.y <= tex_size.y + WALK_CELL_PX
	)


func _stand_blocked(
	env: Node2D,
	player: CharacterBody2D,
	tex_pos: Vector2,
	exclude: Array[RID],
) -> bool:
	var collision := player.get_node_or_null("CollisionFront") as CollisionShape2D
	if collision == null or collision.shape == null or collision.disabled:
		return true
	var world := env.get_world_2d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = collision.shape
	params.transform = _stand_transform(env, player, collision, tex_pos)
	params.collision_mask = player.collision_mask
	params.exclude = exclude
	params.collide_with_bodies = true
	params.collide_with_areas = false
	return not space.intersect_shape(params, 8).is_empty()


func _stand_ray_blocked(
	env: Node2D,
	player: CharacterBody2D,
	from_tex: Vector2,
	to_tex: Vector2,
	exclude: Array[RID],
) -> bool:
	var collision := player.get_node_or_null("CollisionFront") as CollisionShape2D
	if collision == null:
		return true
	var world := env.get_world_2d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var from := _stand_transform(env, player, collision, from_tex).origin
	var to := _stand_transform(env, player, collision, to_tex).origin
	if from.distance_squared_to(to) < 0.01:
		return false
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = player.collision_mask
	query.exclude = exclude
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return not space.intersect_ray(query).is_empty()


func _stand_transform(
	env: Node2D,
	player: CharacterBody2D,
	collision: CollisionShape2D,
	tex_pos: Vector2,
) -> Transform2D:
	var basis := player.global_transform
	basis.origin = env.to_global(tex_pos)
	return basis * collision.transform


func _roll_item(
	area_id: String,
	rng: RandomNumberGenerator,
	used_lanes: Array,
	blocked_override: Variant = null,
) -> String:
	var ordered := _candidate_lanes(area_id, used_lanes)
	if ordered.is_empty():
		return ""
	var start := rng.randi() % ordered.size()
	var rank := area_rank(area_id)
	var blocked: Array = blocked_override if blocked_override is Array else _blocked_item_ids()
	for i in ordered.size():
		var lane := String(ordered[(start + i) % ordered.size()])
		var item_id := _resolve_lane_exact(lane, rank, blocked)
		if not item_id.is_empty():
			return item_id
	for i in ordered.size():
		var lane := String(ordered[(start + i) % ordered.size()])
		var item_id := _resolve_lane(lane, rank, blocked)
		if not item_id.is_empty():
			return item_id
	return ""


func _candidate_lanes(area_id: String, used_lanes: Array) -> Array:
	var families: Array = (AREAS[area_id]["families"] as Array).duplicate()
	var baselines: Array = []
	for lane in ItemLinesScript.scatter_lane_keys():
		baselines.append(String(lane))
	var unused: Array = []
	var used_fallback: Array = []
	for lane in families + baselines:
		var key := String(lane)
		if used_lanes.has(key):
			if not used_fallback.has(key):
				used_fallback.append(key)
		elif not unused.has(key):
			unused.append(key)
	return unused + used_fallback


func _resolve_lane_exact(lane: String, rank: int, blocked: Array) -> String:
	var item_id := ""
	if ItemLinesScript.is_baseline_lane(lane):
		item_id = ItemLinesScript.rung_id(lane, rank)
	elif rank >= 0 and rank < RANK_PREFIXES.size():
		item_id = "%s-%s" % [RANK_PREFIXES[rank], lane]
	if item_id.is_empty() or blocked.has(item_id):
		return ""
	if _item_exists(item_id):
		return item_id
	return ""


func _resolve_lane(lane: String, rank: int, blocked: Array) -> String:
	if ItemLinesScript.is_baseline_lane(lane):
		for tier in range(rank, -1, -1):
			var item_id := ItemLinesScript.rung_id(lane, tier)
			if item_id.is_empty() or blocked.has(item_id):
				continue
			if _item_exists(item_id):
				return item_id
		return ""
	for tier in range(rank, -1, -1):
		var item_id := "%s-%s" % [RANK_PREFIXES[tier], lane]
		if blocked.has(item_id):
			continue
		if _item_exists(item_id):
			return item_id
	return ""


func _owned_item_ids() -> Array:
	var blocked: Array = []
	var run := _run()
	if run != null:
		for item_id in Array(run.state.owned_item_ids):
			_append_unique(blocked, String(item_id))
	return blocked


func _frozen_floor_ids() -> Array:
	var out: Array = []
	for room_path in _room_items.keys():
		if not _area_is_frozen(area_for_scene(String(room_path))):
			continue
		for entry in (_room_items[room_path] as Array):
			_append_unique(out, String((entry as Dictionary).get("id", "")))
	return out


func _append_unique(arr: Array, value: String) -> void:
	if value.is_empty() or arr.has(value):
		return
	arr.append(value)


func _blocked_item_ids() -> Array:
	var blocked := _owned_item_ids()
	for room_path in _room_items.keys():
		for entry in (_room_items[room_path] as Array):
			_append_unique(blocked, String((entry as Dictionary).get("id", "")))
	return blocked


func _lane_of(item_id: String) -> String:
	var baseline := ItemLinesScript.lane_of_id(item_id)
	if not baseline.is_empty():
		return baseline
	return _family_of(item_id)


func _family_of(item_id: String) -> String:
	var parts := item_id.split("-")
	return String(parts[1]) if parts.size() > 1 else ""


func _item_exists(item_id: String) -> bool:
	var run := _run()
	if run == null or not run.has_method("load_item"):
		return false
	return run.call("load_item", item_id) != null


func _spawn_pickups(scene: Node, env: Node2D, path: String) -> void:
	var entries: Array = _room_items.get(path, [])
	if entries.is_empty():
		return
	var host := env.get_node_or_null(PICKUP_HOST_NAME) as Node2D
	if host == null:
		host = Node2D.new()
		host.name = PICKUP_HOST_NAME
		env.add_child(host)
	for child in host.get_children():
		child.queue_free()
	var info_card := _ensure_info_card(scene)
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if bool(entry.get("taken", false)):
			continue
		var spot := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		if _is_unplaced_spot(spot):
			continue
		var pickup := PickupScript.new()
		pickup.name = "WorldItem%d" % i
		pickup.position = spot
		pickup.setup(String(entry.get("id", "")), path, i, info_card)
		host.add_child(pickup)


func _ensure_info_card(scene: Node) -> Node:
	var existing := scene.get_node_or_null(INFO_CARD_NODE_NAME)
	if existing != null:
		return existing
	var card := InfoCardScript.new()
	card.name = INFO_CARD_NODE_NAME
	scene.add_child(card)
	return card


func _settle_frames(scene: Node, frames: int) -> void:
	for _i in frames:
		if get_tree() == null:
			return
		await get_tree().process_frame
		if not is_instance_valid(scene):
			return


func _current_scene() -> Node:
	var tree := get_tree()
	return tree.current_scene if tree != null else null


func _env_of(scene: Node) -> Node2D:
	var env := scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env == null:
		env = scene.find_child("EnvironmentColliders", true, false) as Node2D
	return env


func ensure_board_question() -> Dictionary:
	var run := _run()
	if run == null:
		return {"ready": false}
	var item_id := String(run.state.board_item_id)
	var room := String(run.state.board_room_scene)
	if item_id.is_empty() or room.is_empty():
		_ensure_floor_plan()
		var pick := _pick_board_item()
		if pick.is_empty():
			return {"ready": false}
		item_id = String(pick.get("id", ""))
		room = String(pick.get("room", ""))
		run.state.board_item_id = item_id
		run.state.board_room_scene = room
		_save()
	var taken := _board_item_was_taken(item_id, room)
	var item_name := _item_plain_name(item_id)
	var verb := "was" if taken else "is"
	return {
		"ready": true,
		"item_id": item_id,
		"room_scene": room,
		"item_name": item_name,
		"taken": taken,
		"line": "In which room %s %s?" % [verb, item_name],
		"guess_spent": bool(run.state.board_guess_spent),
	}


func board_answer_matches(typed: String) -> bool:
	var run := _run()
	if run == null:
		return false
	return _room_answer_matches(typed, String(run.state.board_room_scene))


func spend_board_guess() -> void:
	var run := _run()
	if run == null:
		return
	run.state.board_guess_spent = true
	_save()


func answered_item_equipped() -> bool:
	var run := _run()
	if run == null:
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("get_flag"):
		return false
	if not bool(gm.call("get_flag", "hasName")):
		return false
	var item_id := String(run.state.board_item_id)
	if item_id.is_empty():
		return false
	return Array(run.state.equipped_item_ids).has(item_id)


func _ensure_floor_plan() -> void:
	if not _room_items.is_empty():
		return
	var run := _run()
	if run == null:
		return
	var run_seed := int(run.state.seed)
	if run_seed == 0:
		run_seed = 1
	plan_floor_items(run_seed)


func _pick_board_item() -> Dictionary:
	var candidates: Array = []
	var rooms: Array = _room_items.keys()
	rooms.sort()
	for room_path in rooms:
		var entries: Array = _room_items[room_path]
		for i in entries.size():
			var entry: Dictionary = entries[i]
			var item_id := String(entry.get("id", ""))
			if item_id.is_empty():
				continue
			candidates.append({
				"id": item_id,
				"room": String(room_path),
				"index": i,
			})
	if candidates.is_empty():
		return {}
	var run := _run()
	var rng := RandomNumberGenerator.new()
	var run_seed := int(run.state.seed) if run != null else 1
	rng.seed = run_seed if run_seed != 0 else 1
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _board_item_was_taken(item_id: String, room_scene: String) -> bool:
	for entry in (_room_items.get(room_scene, []) as Array):
		var placed: Dictionary = entry
		if String(placed.get("id", "")) != item_id:
			continue
		return bool(placed.get("taken", false))
	var run := _run()
	if run == null:
		return false
	return Array(run.state.owned_item_ids).has(item_id)


func _item_plain_name(item_id: String) -> String:
	var run := _run()
	if run != null and run.has_method("load_item"):
		var item = run.call("load_item", item_id)
		if item != null:
			var item_name := str(item.get("display_name")).strip_edges()
			if not item_name.is_empty():
				return item_name
	return item_id


func _room_answer_matches(typed: String, scene_path: String) -> bool:
	var norm := _normalize_room_answer(typed)
	if norm.is_empty() or norm == "corridor":
		return false
	var aliases: Array = ROOM_ANSWER_ALIASES.get(scene_path, [])
	return aliases.has(norm)


func _normalize_room_answer(typed: String) -> String:
	var text := typed.strip_edges().to_lower()
	text = text.replace("'", "")
	text = text.replace("’", "")
	text = text.replace(".", "")
	var words := text.split(" ", false)
	# "in kitchen" / "inside hallway" / "on basement door" still name the room.
	if words.size() >= 2 and words[0] in ["in", "inside", "on"]:
		words.remove_at(0)
	return " ".join(words)


func _run() -> Node:
	return get_node_or_null("/root/AxelRun")
