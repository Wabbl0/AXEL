
extends Node

signal memory_collected(count: int)
signal inventory_changed(items: Array)
signal state_changed()

var game_state: Dictionary = {}

const SAVE_PATH := "user://axel_game_state.json"
const INVALID_RETURN_POS := Vector2(1.0e20, 1.0e20)
var pause_map_return_path: String = ""
var pause_map_return_tex: Vector2 = INVALID_RETURN_POS

var corridor_locker_line_seen: bool = false
var corridor_spawn_line_seen: bool = false
var basement_door_line_seen: bool = false
var corridor_return_pos: Vector2 = INVALID_RETURN_POS
var cafeteria_table_return_pos: Vector2 = INVALID_RETURN_POS
var classroom_desk_return_pos: Vector2 = INVALID_RETURN_POS
var backyard_memory_return_pos: Vector2 = INVALID_RETURN_POS
var teachers_lounge_memory_return_pos: Vector2 = INVALID_RETURN_POS
var corridor_spawn_side: String = ""
var exterior_spawn_side: String = ""
var basement_spawn_side: String = ""
var cafeteria_spawn_side: String = ""
var kitchen_spawn_side: String = ""
var backyard_spawn_side: String = ""
var classrooms_corridor_spawn_side: String = ""
var teachers_lounge_spawn_side: String = ""
var classroom_spawn_side: String = ""
var walkoff_floor_offset_y: float = NAN
var interact_arrival_t: float = NAN
var cafeteria_enter_line_seen: bool = false
var kitchen_enter_line_seen: bool = false
var backyard_enter_line_seen: bool = false
var teachers_lounge_enter_line_seen: bool = false
var classroom_enter_line_seen: bool = false
var classroom_desk_seen: bool = false
var cafeteria_memory_line_seen: bool = false
var backyard_memory_line_seen: bool = false
var backyard_cigarette_line_seen: bool = false
var teachers_key_line_seen: bool = false
var teachers_memory_line_seen: bool = false
var teachers_liar_line_seen: bool = false
var corridor_from_locker: bool = false
var corridor_right_hint_done: bool = false
var cafeteria_down_hint_done: bool = false
var basement_right_hint_done: bool = false
var basement_hint_soon: bool = false
var visited_rooms: Dictionary = {}


func _ready() -> void:
	_load_persistent_state()

func _default_game_state() -> Dictionary:
	return {
		"inventory": [],
		"memories": 0,
		"memoryScenes": {},
		"flags": {
			"hasFlashlight": false,
			"hasName": false,
			"hasKey": false,
			"hasShovel": false,
			"deskSequencePlayed": false,
			"knowsName": false,
			"isDead": false,
			"fightIntroSeen": false,
			"dreadIntroSeen": false,
		},
	}

func _persistence_enabled() -> bool:

	var saves := get_node_or_null("/root/AxelSaves")
	return saves != null and bool(saves.call("is_active"))

func _load_persistent_state() -> void:
	game_state = _default_game_state()
	corridor_locker_line_seen = false
	corridor_spawn_line_seen = false
	basement_door_line_seen = false
	cafeteria_enter_line_seen = false
	kitchen_enter_line_seen = false
	backyard_enter_line_seen = false
	teachers_lounge_enter_line_seen = false
	classroom_enter_line_seen = false
	classroom_desk_seen = false
	cafeteria_memory_line_seen = false
	backyard_memory_line_seen = false
	backyard_cigarette_line_seen = false
	teachers_key_line_seen = false
	teachers_memory_line_seen = false
	teachers_liar_line_seen = false
	corridor_from_locker = false
	corridor_right_hint_done = false
	cafeteria_down_hint_done = false
	basement_right_hint_done = false
	basement_hint_soon = false
	visited_rooms = {}
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("reset_world"):
		world.call("reset_world")


func _merge_game_state(defaults: Dictionary, saved: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in saved.keys():
		if key == "flags" and saved["flags"] is Dictionary and defaults.has("flags"):
			var flags: Dictionary = (defaults["flags"] as Dictionary).duplicate(true)
			for flag_key in (saved["flags"] as Dictionary).keys():
				flags[flag_key] = saved["flags"][flag_key]
			merged["flags"] = flags
		elif defaults.has(key):
			merged[key] = saved[key]
	return merged

func reset_state() -> void:
	_load_persistent_state()
	corridor_return_pos = INVALID_RETURN_POS
	cafeteria_table_return_pos = INVALID_RETURN_POS
	classroom_desk_return_pos = INVALID_RETURN_POS
	backyard_memory_return_pos = INVALID_RETURN_POS
	teachers_lounge_memory_return_pos = INVALID_RETURN_POS
	corridor_spawn_side = ""
	exterior_spawn_side = ""
	basement_spawn_side = ""
	cafeteria_spawn_side = ""
	kitchen_spawn_side = ""
	backyard_spawn_side = ""
	classrooms_corridor_spawn_side = ""
	teachers_lounge_spawn_side = ""
	classroom_spawn_side = ""
	walkoff_floor_offset_y = NAN
	interact_arrival_t = NAN
	pause_map_return_path = ""
	pause_map_return_tex = INVALID_RETURN_POS
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("reset_run"):
		run.call("reset_run")
	state_changed.emit()


func export_save_body() -> Dictionary:
	var body := {
		"game_state": game_state.duplicate(true),
		"corridor_locker_line_seen": corridor_locker_line_seen,
		"corridor_spawn_line_seen": corridor_spawn_line_seen,
		"basement_door_line_seen": basement_door_line_seen,
		"cafeteria_enter_line_seen": cafeteria_enter_line_seen,
		"kitchen_enter_line_seen": kitchen_enter_line_seen,
		"backyard_enter_line_seen": backyard_enter_line_seen,
		"teachers_lounge_enter_line_seen": teachers_lounge_enter_line_seen,
		"classroom_enter_line_seen": classroom_enter_line_seen,
		"classroom_desk_seen": classroom_desk_seen,
		"cafeteria_memory_line_seen": cafeteria_memory_line_seen,
		"backyard_memory_line_seen": backyard_memory_line_seen,
		"backyard_cigarette_line_seen": backyard_cigarette_line_seen,
		"teachers_key_line_seen": teachers_key_line_seen,
		"teachers_memory_line_seen": teachers_memory_line_seen,
		"teachers_liar_line_seen": teachers_liar_line_seen,
		"corridor_from_locker": corridor_from_locker,
		"corridor_right_hint_done": corridor_right_hint_done,
		"cafeteria_down_hint_done": cafeteria_down_hint_done,
		"basement_right_hint_done": basement_right_hint_done,
		"pause_map_return_path": pause_map_return_path,
		"visited_rooms": visited_rooms.keys(),
	}
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("to_dict"):
		body["run_state"] = run.call("to_dict")
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("to_dict"):
		body["world_state"] = world.call("to_dict")
	return body


func import_save_body(data: Dictionary) -> void:
	game_state = _merge_game_state(_default_game_state(), data.get("game_state", {}))
	corridor_locker_line_seen = bool(data.get("corridor_locker_line_seen", false))
	corridor_spawn_line_seen = bool(data.get("corridor_spawn_line_seen", false))
	basement_door_line_seen = bool(data.get("basement_door_line_seen", false))
	cafeteria_enter_line_seen = bool(data.get("cafeteria_enter_line_seen", false))
	kitchen_enter_line_seen = bool(data.get("kitchen_enter_line_seen", false))
	backyard_enter_line_seen = bool(data.get("backyard_enter_line_seen", false))
	teachers_lounge_enter_line_seen = bool(data.get("teachers_lounge_enter_line_seen", false))
	classroom_enter_line_seen = bool(data.get("classroom_enter_line_seen", false))
	classroom_desk_seen = bool(data.get("classroom_desk_seen", false))
	cafeteria_memory_line_seen = bool(data.get("cafeteria_memory_line_seen", false))
	backyard_memory_line_seen = bool(data.get("backyard_memory_line_seen", false))
	backyard_cigarette_line_seen = bool(data.get("backyard_cigarette_line_seen", false))
	teachers_key_line_seen = bool(data.get("teachers_key_line_seen", false))
	teachers_memory_line_seen = bool(data.get("teachers_memory_line_seen", false))
	teachers_liar_line_seen = bool(data.get("teachers_liar_line_seen", false))
	corridor_from_locker = bool(data.get("corridor_from_locker", false))
	corridor_right_hint_done = bool(data.get("corridor_right_hint_done", false))
	cafeteria_down_hint_done = bool(data.get("cafeteria_down_hint_done", false))
	basement_right_hint_done = bool(data.get("basement_right_hint_done", false))
	pause_map_return_path = String(data.get("pause_map_return_path", ""))
	pause_map_return_tex = INVALID_RETURN_POS
	visited_rooms = {}
	for room_path in data.get("visited_rooms", []):
		visited_rooms[String(room_path)] = true
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("from_dict"):
		run.call("from_dict", data.get("run_state", {}))
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("from_dict"):
		world.call("from_dict", data.get("world_state", {}))
	state_changed.emit()


func _save_persistent_state() -> void:
	if not _persistence_enabled():
		return
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and saves.has_method("save_active"):
		saves.call("save_active")
		return
	var data := {
		"game_state": game_state,
		"corridor_locker_line_seen": corridor_locker_line_seen,
		"corridor_spawn_line_seen": corridor_spawn_line_seen,
		"basement_door_line_seen": basement_door_line_seen,
		"cafeteria_enter_line_seen": cafeteria_enter_line_seen,
		"kitchen_enter_line_seen": kitchen_enter_line_seen,
		"backyard_enter_line_seen": backyard_enter_line_seen,
		"teachers_lounge_enter_line_seen": teachers_lounge_enter_line_seen,
		"classroom_enter_line_seen": classroom_enter_line_seen,
		"classroom_desk_seen": classroom_desk_seen,
		"cafeteria_memory_line_seen": cafeteria_memory_line_seen,
		"backyard_memory_line_seen": backyard_memory_line_seen,
		"backyard_cigarette_line_seen": backyard_cigarette_line_seen,
		"teachers_key_line_seen": teachers_key_line_seen,
		"teachers_memory_line_seen": teachers_memory_line_seen,
		"teachers_liar_line_seen": teachers_liar_line_seen,
		"corridor_from_locker": corridor_from_locker,
		"corridor_right_hint_done": corridor_right_hint_done,
		"cafeteria_down_hint_done": cafeteria_down_hint_done,
		"basement_right_hint_done": basement_right_hint_done,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameManager: could not write save file at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func has_memory_scene(scene_key: String) -> bool:
	return game_state.get("memoryScenes", {}).has(scene_key)

func mark_room_visited(scene_path: String) -> void:
	if scene_path.is_empty() or visited_rooms.has(scene_path):
		return
	visited_rooms[scene_path] = true
	_save_persistent_state()

func has_visited(scene_path: String) -> bool:
	return visited_rooms.has(scene_path)

func set_corridor_locker_line_seen(value: bool = true) -> void:
	corridor_locker_line_seen = value
	_save_persistent_state()


func set_corridor_from_locker(value: bool = true) -> void:
	corridor_from_locker = value
	_save_persistent_state()


func set_corridor_right_hint_done(value: bool = true) -> void:
	corridor_right_hint_done = value
	_save_persistent_state()


func set_cafeteria_down_hint_done(value: bool = true) -> void:
	cafeteria_down_hint_done = value
	_save_persistent_state()


func set_basement_right_hint_done(value: bool = true) -> void:
	basement_right_hint_done = value
	_save_persistent_state()


func set_basement_hint_soon(value: bool = true) -> void:
	basement_hint_soon = value


func take_basement_hint_soon() -> bool:
	var soon := basement_hint_soon
	basement_hint_soon = false
	return soon

func set_corridor_spawn_line_seen(value: bool = true) -> void:
	corridor_spawn_line_seen = value
	_save_persistent_state()

func set_basement_door_line_seen(value: bool = true) -> void:
	basement_door_line_seen = value
	_save_persistent_state()

func set_cafeteria_enter_line_seen(value: bool = true) -> void:
	cafeteria_enter_line_seen = value
	_save_persistent_state()

func set_kitchen_enter_line_seen(value: bool = true) -> void:
	kitchen_enter_line_seen = value
	_save_persistent_state()

func set_backyard_enter_line_seen(value: bool = true) -> void:
	backyard_enter_line_seen = value
	_save_persistent_state()

func set_teachers_lounge_enter_line_seen(value: bool = true) -> void:
	teachers_lounge_enter_line_seen = value
	_save_persistent_state()

func set_classroom_enter_line_seen(value: bool = true) -> void:
	classroom_enter_line_seen = value
	_save_persistent_state()

func set_classroom_desk_seen(value: bool = true) -> void:
	classroom_desk_seen = value
	_save_persistent_state()

func set_cafeteria_memory_line_seen(value: bool = true) -> void:
	cafeteria_memory_line_seen = value
	_save_persistent_state()

func set_backyard_memory_line_seen(value: bool = true) -> void:
	backyard_memory_line_seen = value
	_save_persistent_state()

func set_backyard_cigarette_line_seen(value: bool = true) -> void:
	backyard_cigarette_line_seen = value
	_save_persistent_state()

func set_teachers_key_line_seen(value: bool = true) -> void:
	teachers_key_line_seen = value
	_save_persistent_state()

func set_teachers_memory_line_seen(value: bool = true) -> void:
	teachers_memory_line_seen = value
	_save_persistent_state()

func set_teachers_liar_line_seen(value: bool = true) -> void:
	teachers_liar_line_seen = value
	_save_persistent_state()

func set_corridor_return_pos(pos: Vector2) -> void:
	corridor_return_pos = pos

func has_corridor_return_pos() -> bool:
	return corridor_return_pos != INVALID_RETURN_POS

func take_corridor_return_pos() -> Vector2:
	var pos := corridor_return_pos
	corridor_return_pos = INVALID_RETURN_POS
	return pos

func set_cafeteria_table_return_pos(pos: Vector2) -> void:
	cafeteria_table_return_pos = pos

func has_cafeteria_table_return_pos() -> bool:
	return cafeteria_table_return_pos != INVALID_RETURN_POS

func take_cafeteria_table_return_pos() -> Vector2:
	var pos := cafeteria_table_return_pos
	cafeteria_table_return_pos = INVALID_RETURN_POS
	return pos

func set_classroom_desk_return_pos(pos: Vector2) -> void:
	classroom_desk_return_pos = pos

func has_classroom_desk_return_pos() -> bool:
	return classroom_desk_return_pos != INVALID_RETURN_POS

func take_classroom_desk_return_pos() -> Vector2:
	var pos := classroom_desk_return_pos
	classroom_desk_return_pos = INVALID_RETURN_POS
	return pos

func set_backyard_memory_return_pos(pos: Vector2) -> void:
	backyard_memory_return_pos = pos

func has_backyard_memory_return_pos() -> bool:
	return backyard_memory_return_pos != INVALID_RETURN_POS

func take_backyard_memory_return_pos() -> Vector2:
	var pos := backyard_memory_return_pos
	backyard_memory_return_pos = INVALID_RETURN_POS
	return pos

func set_teachers_lounge_memory_return_pos(pos: Vector2) -> void:
	teachers_lounge_memory_return_pos = pos

func has_teachers_lounge_memory_return_pos() -> bool:
	return teachers_lounge_memory_return_pos != INVALID_RETURN_POS

func take_teachers_lounge_memory_return_pos() -> Vector2:
	var pos := teachers_lounge_memory_return_pos
	teachers_lounge_memory_return_pos = INVALID_RETURN_POS
	return pos

func set_pause_map_return(path: String, tex: Vector2) -> void:
	pause_map_return_path = path
	pause_map_return_tex = tex


func has_pause_map_return_for(path: String) -> bool:
	return pause_map_return_path == path and pause_map_return_tex != INVALID_RETURN_POS


func clear_pause_map_return() -> void:
	pause_map_return_path = ""
	pause_map_return_tex = INVALID_RETURN_POS


func take_pause_map_return_tex() -> Vector2:
	var tex := pause_map_return_tex
	clear_pause_map_return()
	return tex


func set_corridor_spawn_side(side: String) -> void:
	corridor_spawn_side = side

func take_corridor_spawn_side() -> String:
	var side := corridor_spawn_side
	corridor_spawn_side = ""
	return side

func set_exterior_spawn_side(side: String) -> void:
	exterior_spawn_side = side

func take_exterior_spawn_side() -> String:
	var side := exterior_spawn_side
	exterior_spawn_side = ""
	return side

func set_walkoff_floor_offset_y(offset_y: float) -> void:
	walkoff_floor_offset_y = offset_y

func has_walkoff_floor_offset_y() -> bool:
	return not is_nan(walkoff_floor_offset_y)

func take_walkoff_floor_offset_y() -> float:
	var offset_y := walkoff_floor_offset_y
	walkoff_floor_offset_y = NAN
	return offset_y

func set_interact_arrival_t(t: float) -> void:
	interact_arrival_t = t

func has_interact_arrival_t() -> bool:
	return not is_nan(interact_arrival_t)

func take_interact_arrival_t() -> float:
	var t := interact_arrival_t
	interact_arrival_t = NAN
	return t

func set_basement_spawn_side(side: String) -> void:
	basement_spawn_side = side

func take_basement_spawn_side() -> String:
	var side := basement_spawn_side
	basement_spawn_side = ""
	return side

func set_cafeteria_spawn_side(side: String) -> void:
	cafeteria_spawn_side = side

func take_cafeteria_spawn_side() -> String:
	var side := cafeteria_spawn_side
	cafeteria_spawn_side = ""
	return side

func set_kitchen_spawn_side(side: String) -> void:
	kitchen_spawn_side = side

func take_kitchen_spawn_side() -> String:
	var side := kitchen_spawn_side
	kitchen_spawn_side = ""
	return side

func set_backyard_spawn_side(side: String) -> void:
	backyard_spawn_side = side

func take_backyard_spawn_side() -> String:
	var side := backyard_spawn_side
	backyard_spawn_side = ""
	return side

func set_classrooms_corridor_spawn_side(side: String) -> void:
	classrooms_corridor_spawn_side = side

func take_classrooms_corridor_spawn_side() -> String:
	var side := classrooms_corridor_spawn_side
	classrooms_corridor_spawn_side = ""
	return side

func set_teachers_lounge_spawn_side(side: String) -> void:
	teachers_lounge_spawn_side = side

func take_teachers_lounge_spawn_side() -> String:
	var side := teachers_lounge_spawn_side
	teachers_lounge_spawn_side = ""
	return side

func set_classroom_spawn_side(side: String) -> void:
	classroom_spawn_side = side

func take_classroom_spawn_side() -> String:
	var side := classroom_spawn_side
	classroom_spawn_side = ""
	return side

func set_flag(flag_name: String, value: bool):
	"""Set a game flag"""
	if game_state["flags"].has(flag_name):
		game_state["flags"][flag_name] = value
		_save_persistent_state()
		state_changed.emit()
		print("→ Flag '%s' = %s" % [flag_name, value])

func get_flag(flag_name: String) -> bool:
	"""Get a game flag value"""
	if game_state["flags"].has(flag_name):
		return game_state["flags"][flag_name]
	return false

func add_inventory_item(_item_key: String, display_name: String):
	"""Add item to inventory"""
	if not display_name in game_state["inventory"]:
		game_state["inventory"].append(display_name)
		_save_persistent_state()
		inventory_changed.emit(game_state["inventory"])
		print("→ Added to inventory: " + display_name)

func add_memory_once(scene_key: String):
	"""Add a memory (only once per scene)"""
	if not game_state["memoryScenes"].has(scene_key):
		game_state["memoryScenes"][scene_key] = true
		add_memory()
		_save_persistent_state()

func add_memory():
	"""Increment memory counter"""
	game_state["memories"] += 1
	memory_collected.emit(game_state["memories"])
	print("→ Memory collected! (%d/5)" % game_state["memories"])


func debug_show_state():
	"""Print current game state to console"""
	print("\n=== GAME STATE ===")
	print("Memories: %d/5" % game_state["memories"])
	print("Inventory: " + str(game_state["inventory"]))
	print("Flags: ")
	for flag in game_state["flags"]:
		print("  - %s: %s" % [flag, game_state["flags"][flag]])
