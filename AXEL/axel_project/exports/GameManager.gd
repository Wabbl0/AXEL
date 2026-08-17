# Overworld narrative state autoload.

extends Node

# Signals
signal memory_collected(count: int)
signal inventory_changed(items: Array)
signal state_changed()

# Data
var game_state: Dictionary = {}

const SAVE_PATH := "user://axel_game_state.json"
const INVALID_RETURN_POS := Vector2(1.0e20, 1.0e20)

var corridor_locker_line_seen: bool = false
var corridor_spawn_line_seen: bool = false
var basement_door_line_seen: bool = false
var corridor_return_pos: Vector2 = INVALID_RETURN_POS
## Transient (not persisted). Texture-pixel standing spot when leaving 2.1 for 2.2.
var cafeteria_table_return_pos: Vector2 = INVALID_RETURN_POS
## Transient (not persisted). e.g. "basement_right" when leaving 1.4 for 1.2.
var corridor_spawn_side: String = ""
## Transient (not persisted). e.g. "cafeteria_right" when leaving 2.1 for 1.4.
var basement_spawn_side: String = ""
## Transient (not persisted). e.g. "basement_left" when leaving 1.4 for 2.1.
var cafeteria_spawn_side: String = ""
## Transient (not persisted). e.g. "kitchen_door" when leaving 2.3 for 2.1.
var kitchen_spawn_side: String = ""
## Transient (not persisted). e.g. "cafeteria_door" when leaving 2.1 for 3.1.
var backyard_spawn_side: String = ""
## Transient (not persisted). e.g. "cafeteria_door" / "lounge_door" / "classroom_door".
var classrooms_corridor_spawn_side: String = ""
## Transient (not persisted). e.g. "corridor_door" when leaving 2.4 for 4.1.
var teachers_lounge_spawn_side: String = ""
## Transient (not persisted). e.g. "corridor_door" when leaving 2.4 for 5.1.
var classroom_spawn_side: String = ""
## Once-ever kitchen enter line (2.3).
var kitchen_enter_line_seen: bool = false
## Once-ever backyard enter line (3.1).
var backyard_enter_line_seen: bool = false
## Once-ever teachers lounge enter line (4.1).
var teachers_lounge_enter_line_seen: bool = false
## Once-ever classroom enter line (5.1).
var classroom_enter_line_seen: bool = false
## Once-ever cafeteria memory lines (2.2).
var cafeteria_memory_line_seen: bool = false

# ============================================================
# INITIALIZATION
# ============================================================

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
		},
	}

func _persistence_enabled() -> bool:
	# Debug/editor playtests start fresh so once-ever dialogue can be re-tested.
	return not OS.is_debug_build()

func _load_persistent_state() -> void:
	game_state = _default_game_state()
	corridor_locker_line_seen = false
	corridor_spawn_line_seen = false
	basement_door_line_seen = false
	kitchen_enter_line_seen = false
	backyard_enter_line_seen = false
	teachers_lounge_enter_line_seen = false
	classroom_enter_line_seen = false
	cafeteria_memory_line_seen = false
	if not _persistence_enabled():
		print("GameManager: debug build — ignoring saved narrative state.")
		return
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("GameManager: could not read save file at %s" % SAVE_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Dictionary:
		push_warning("GameManager: save file is not valid JSON.")
		return
	var data: Dictionary = parsed
	if data.has("game_state") and data["game_state"] is Dictionary:
		game_state = _merge_game_state(_default_game_state(), data["game_state"])
	corridor_locker_line_seen = bool(data.get("corridor_locker_line_seen", false))
	corridor_spawn_line_seen = bool(data.get("corridor_spawn_line_seen", false))
	basement_door_line_seen = bool(data.get("basement_door_line_seen", false))
	kitchen_enter_line_seen = bool(data.get("kitchen_enter_line_seen", false))
	backyard_enter_line_seen = bool(data.get("backyard_enter_line_seen", false))
	teachers_lounge_enter_line_seen = bool(data.get("teachers_lounge_enter_line_seen", false))
	classroom_enter_line_seen = bool(data.get("classroom_enter_line_seen", false))
	cafeteria_memory_line_seen = bool(data.get("cafeteria_memory_line_seen", false))

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

func _save_persistent_state() -> void:
	if not _persistence_enabled():
		return
	var data := {
		"game_state": game_state,
		"corridor_locker_line_seen": corridor_locker_line_seen,
		"corridor_spawn_line_seen": corridor_spawn_line_seen,
		"basement_door_line_seen": basement_door_line_seen,
		"kitchen_enter_line_seen": kitchen_enter_line_seen,
		"backyard_enter_line_seen": backyard_enter_line_seen,
		"teachers_lounge_enter_line_seen": teachers_lounge_enter_line_seen,
		"classroom_enter_line_seen": classroom_enter_line_seen,
		"cafeteria_memory_line_seen": cafeteria_memory_line_seen,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameManager: could not write save file at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func has_memory_scene(scene_key: String) -> bool:
	return game_state.get("memoryScenes", {}).has(scene_key)

func set_corridor_locker_line_seen(value: bool = true) -> void:
	corridor_locker_line_seen = value
	_save_persistent_state()

func set_corridor_spawn_line_seen(value: bool = true) -> void:
	corridor_spawn_line_seen = value
	_save_persistent_state()

func set_basement_door_line_seen(value: bool = true) -> void:
	basement_door_line_seen = value
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

func set_cafeteria_memory_line_seen(value: bool = true) -> void:
	cafeteria_memory_line_seen = value
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

func set_corridor_spawn_side(side: String) -> void:
	corridor_spawn_side = side

func take_corridor_spawn_side() -> String:
	var side := corridor_spawn_side
	corridor_spawn_side = ""
	return side

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

# ============================================================
# DEBUG / CHEAT FUNCTIONS
# ============================================================

func debug_show_state():
	"""Print current game state to console"""
	print("\n=== GAME STATE ===")
	print("Memories: %d/5" % game_state["memories"])
	print("Inventory: " + str(game_state["inventory"]))
	print("Flags: ")
	for flag in game_state["flags"]:
		print("  - %s: %s" % [flag, game_state["flags"][flag]])
