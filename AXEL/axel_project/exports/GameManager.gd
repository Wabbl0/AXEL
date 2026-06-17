# Game Manager - GDScript Template for GUILT Game in Godot 4.x
# This is a basic implementation example to help you get started

extends Node

func _debug_log(hypothesis_id: String, location: String, message: String, data: Dictionary = {}) -> void:
	var file := FileAccess.open("C:/Users/valtt/OneDrive/Godot/logs/debug/debug-7980eb.log", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("C:/Users/valtt/OneDrive/Godot/logs/debug/debug-7980eb.log", FileAccess.WRITE_READ)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": "7980eb",
		"runId": "run1",
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000
	}
	file.store_line(JSON.stringify(payload))
	file.close()

# Signals
signal scene_changed(scene_id: String, scene_data: Dictionary)
signal memory_collected(count: int)
signal inventory_changed(items: Array)
signal state_changed()

# Data
var game_data: Dictionary = {}
var game_state: Dictionary = {}
var current_scene_id: String = ""

const SAVE_PATH := "user://axel_game_state.json"
const INVALID_RETURN_POS := Vector2(1.0e20, 1.0e20)

var corridor_locker_line_seen: bool = false
var corridor_spawn_line_seen: bool = false
var corridor_return_pos: Vector2 = INVALID_RETURN_POS

# References to UI elements in Arc_1/1.1_SchoolExterior.tscn
@onready var location_label: Label = get_node_or_null("%LocationName") as Label
@onready var story_text: Label = get_node_or_null("%StoryContent") as Label
@onready var background_image: TextureRect = get_node_or_null("%SceneBG") as TextureRect
@onready var choices_container: VBoxContainer = get_node_or_null("%ChoicesPanel") as VBoxContainer
@onready var memory_label: Label = get_node_or_null("%MemoryCount") as Label
@onready var inventory_label: Label = get_node_or_null("%InventoryList") as Label
@onready var home_button: Button = get_node_or_null("%HomeButton") as Button

# ============================================================
# INITIALIZATION
# ============================================================

func _ready():
	#region agent log
	_debug_log("H1", "GameManager.gd:_ready", "GameManager _ready entered", {
		"node_name": name,
		"node_type": get_class()
	})
	#endregion
	_load_persistent_state()
	if not _legacy_ui_ready():
		return
	home_button.pressed.connect(_on_home_pressed)
	load_game_data()
	if game_data.is_empty():
		return
	if game_state.is_empty():
		initialize_game_state()
	load_scene(game_data["gameMetadata"]["startScene"])


func _legacy_ui_ready() -> bool:
	if home_button == null or location_label == null or story_text == null or background_image == null or choices_container == null or memory_label == null or inventory_label == null:
		#region agent log
		_debug_log("H2", "GameManager.gd:_ready", "Legacy HTML UI nodes missing; running state-only autoload", {
			"home_button_null": home_button == null,
			"location_label_null": location_label == null,
			"story_text_null": story_text == null,
			"background_image_null": background_image == null,
			"choices_container_null": choices_container == null,
			"memory_label_null": memory_label == null,
			"inventory_label_null": inventory_label == null
		})
		#endregion
		return false
	return true


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


func set_corridor_return_pos(pos: Vector2) -> void:
	corridor_return_pos = pos


func has_corridor_return_pos() -> bool:
	return corridor_return_pos != INVALID_RETURN_POS


func take_corridor_return_pos() -> Vector2:
	var pos := corridor_return_pos
	corridor_return_pos = INVALID_RETURN_POS
	return pos

func load_game_data():
	"""Load game data from JSON file"""
	var json_path = "res://exports/game_data.json"
	#region agent log
	_debug_log("H4", "GameManager.gd:load_game_data", "Checking game data resource", {
		"json_path": json_path,
		"resource_exists": ResourceLoader.exists(json_path)
	})
	#endregion
	if not ResourceLoader.exists(json_path):
		push_error("Game data file not found: " + json_path)
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Could not open game data file")
		return
	
	var json_string = file.get_as_text()
	var json = JSON.parse_string(json_string)
	
	if json == null:
		push_error("Failed to parse JSON")
		return
	
	game_data = json
	#region agent log
	_debug_log("H4", "GameManager.gd:load_game_data", "Game data loaded", {
		"title": game_data.get("gameMetadata", {}).get("title", ""),
		"scene_count": game_data.get("scenes", {}).size()
	})
	#endregion
	print("✓ Loaded game data: %s" % game_data["gameMetadata"]["title"])
	print("✓ Total scenes: %d" % game_data["scenes"].size())

func initialize_game_state():
	"""Initialize game state from template"""
	if not game_data.is_empty() and game_data.has("gameState"):
		game_state = game_data["gameState"].duplicate(true)
	else:
		game_state = _default_game_state()
	print("✓ Game state initialized")

# ============================================================
# SCENE LOADING & TRANSITIONS
# ============================================================

func load_scene(scene_id: String):
	"""Load a scene and handle all associated logic"""
	if not game_data["scenes"].has(scene_id):
		push_error("Scene not found: " + scene_id)
		return
	
	current_scene_id = scene_id
	var scene = game_data["scenes"][scene_id]
	
	# Display location name in UI
	update_location_display(scene.get("name", ""))
	
	# Handle scene type
	var scene_type = scene.get("type", "normal")
	match scene_type:
		"conditionalJump":
			handle_conditional_jump(scene)
			return
		"input":
			display_input_puzzle(scene)
		"normal", "ending", "epilogue":
			display_narrative_scene(scene)
	
	# Execute onEnter actions
	if scene.has("onEnter"):
		execute_on_enter(scene["onEnter"])
	
	# Emit signal
	scene_changed.emit(scene_id, scene)

func handle_conditional_jump(scene: Dictionary):
	"""Evaluate condition and jump to appropriate scene"""
	var condition = scene.get("condition", "")
	
	if evaluate_condition(condition):
		load_scene(scene["successTarget"])
	else:
		load_scene(scene["failTarget"])

func display_narrative_scene(scene: Dictionary):
	"""Display a normal narrative scene with choices"""
	# Update story text
	update_story_text(scene.get("text", ""))
	
	# Update background image if present
	if scene.has("image") and scene["image"] != "":
		var image_path = resolve_image_path(scene["image"])
		update_background(image_path)
	else:
		update_background("")
	
	# Check if scene is locked
	var is_locked = is_scene_locked(current_scene_id)
	
	# Display choices
	display_choices(scene.get("choices", []), is_locked)

func display_input_puzzle(scene: Dictionary):
	"""Display an input puzzle that requires player answer"""
	update_story_text(scene.get("text", ""))
	display_choices(scene.get("choices", []), false)
	
	# Create input field
	var input_box = create_input_box()
	input_box.text_submitted.connect(func(text):
		handle_puzzle_input(text, scene)
	)

func handle_puzzle_input(player_answer: String, puzzle_scene: Dictionary):
	"""Check if puzzle answer is correct"""
	var correct_answer = puzzle_scene.get("correctAnswer", "")
	
	if player_answer.to_upper().strip_edges() == correct_answer:
		# Correct answer
		load_scene(puzzle_scene["successTarget"])
	else:
		# Wrong answer
		var fail_text = puzzle_scene.get("failText", "Wrong answer...")
		update_story_text(fail_text)
		
		if puzzle_scene.has("failTarget"):
			# Auto-advance after delay
			await get_tree().create_timer(2.0).timeout
			load_scene(puzzle_scene["failTarget"])

# ============================================================
# UI UPDATES
# ============================================================

func display_choices(choices: Array, is_locked: bool = false):
	"""Render choice buttons"""
	if choices_container == null:
		return
	# Clear existing choices
	for child in choices_container.get_children():
		child.queue_free()
	
	for choice in choices:
		# Check if choice has a condition
		if choice.has("condition") and not evaluate_condition(choice["condition"]):
			continue  # Skip this choice
		
		var button = Button.new()
		button.text = choice.get("text", "???")
		button.custom_minimum_size = Vector2(300, 40)
		
		# Apply styling
		if choice.has("specialClass"):
			# Apply red styling for special choices
			if "red" in choice["specialClass"]:
				button.modulate = Color.RED
		
		# Disable if scene is locked
		if is_locked:
			button.disabled = true
		
		# Connect button press
		button.pressed.connect(func():
			load_scene(choice["target"])
		)
		
		choices_container.add_child(button)

func update_location_display(location_name: String):
	"""Update location name in status bar"""
	if location_label == null:
		return
	if location_name.is_empty():
		location_label.text = "LOCATION: ..."
	else:
		location_label.text = "LOCATION: " + location_name

func update_story_text(text: String):
	"""Update main story text"""
	if story_text == null:
		return
	story_text.text = text
	
	# Add glitch effect if needed (memory unlock)
	# animate_glitch_text()

func update_background(image_path: String):
	"""Load and display background image"""
	if background_image == null:
		return
	if image_path.is_empty():
		background_image.texture = null
		background_image.hide()
		return

	if ResourceLoader.exists(image_path):
		var texture = load(image_path)
		background_image.texture = texture
		background_image.show()
	else:
		print("Warning: Image not found: " + image_path)
		background_image.texture = null
		background_image.hide()

func update_ui_state():
	"""Update inventory and memory display"""
	if memory_label == null or inventory_label == null:
		return
	memory_label.text = "%d/5" % [game_state["memories"]]
	
	var inv_text = ""
	if game_state["inventory"].size() > 0:
		inv_text = ", ".join(game_state["inventory"])
	else:
		inv_text = "Empty"
	
	inventory_label.text = "INV: " + inv_text

# ============================================================
# GAME STATE MANAGEMENT
# ============================================================

func execute_on_enter(on_enter):
	"""Execute actions when scene is entered"""
	if on_enter is String:
		# Simple action name
		execute_single_action({"action": on_enter})
	elif on_enter.has("action"):
		# Single action
		execute_single_action(on_enter)
	elif on_enter.has("actions"):
		# Multiple actions
		for action in on_enter["actions"]:
			execute_single_action(action)

func execute_single_action(action: Dictionary):
	"""Execute a single action"""
	var action_type = action.get("action", "")
	
	match action_type:
		"setFlag":
			set_flag(action["flag"], action.get("value", true))
		
		"addInventoryItem":
			add_inventory_item(action["item"], action.get("displayName", action["item"]))
		
		"addMemoryOnce":
			add_memory_once(action["sceneKey"])
		
		"addMemory":
			add_memory()
		
		"resetGameState":
			initialize_game_state()
		
		"displaySmokingHint":
			display_smoking_hint()
		
		_:
			print("Unknown action: " + action_type)

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
		update_ui_state()
		inventory_changed.emit(game_state["inventory"])
		print("→ Added to inventory: " + display_name)

func add_memory_once(scene_key: String):
	"""Add a memory (only once per scene)"""
	if not game_state["memoryScenes"].has(scene_key):
		game_state["memoryScenes"][scene_key] = true
		_save_persistent_state()
		add_memory()

func add_memory():
	"""Increment memory counter"""
	game_state["memories"] += 1
	update_ui_state()
	memory_collected.emit(game_state["memories"])
	print("→ Memory collected! (%d/5)" % game_state["memories"])
	# Play glitch animation effect

# ============================================================
# CONDITIONS & LOGIC
# ============================================================

func evaluate_condition(condition: String) -> bool:
	"""Evaluate a conditional expression"""
	if condition == "":
		return true
	
	# Handle simple negation
	if condition.begins_with("!"):
		var flag = condition.trim_prefix("!")
		return not get_flag(flag)
	
	# Handle simple flag check
	return get_flag(condition)

func is_scene_locked(scene_id: String) -> bool:
	"""Check if a scene is locked based on conditions"""
	if not game_data.has("lockedScenes"):
		return false

	if not game_data["lockedScenes"].has(scene_id):
		return false
	
	var lock = game_data["lockedScenes"][scene_id]
	var condition = lock.get("condition", "")
	
	# Scene is locked if condition is FALSE
	return not evaluate_condition(condition)

func display_smoking_hint():
	"""Show appropriate hint while smoking"""
	if not game_data.has("hints") or not game_data["hints"].has("smoking_hints"):
		update_story_text("I need to keep looking.")
		return

	var hints = game_data["hints"]["smoking_hints"]
	var pending_hints = []
	
	if not get_flag("hasFlashlight"):
		pending_hints.append(hints[0])
	if not get_flag("hasName"):
		pending_hints.append(hints[1])
	if not get_flag("hasKey"):
		pending_hints.append(hints[2])
	if game_state["memories"] < 5:
		pending_hints.append(hints[3])
	
	var hint_text = ""
	if pending_hints.size() == 0:
		hint_text = "I'm ready."
	else:
		hint_text = pending_hints[randi() % pending_hints.size()]
	
	update_story_text(hint_text)

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main_Menu/0.1_MainMenu.tscn")

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

func resolve_image_path(image_name: String) -> String:
	"""Resolve image path from name"""
	if image_name.is_empty():
		return ""
	
	# If already a full path
	if image_name.contains("://") or image_name.begins_with("pictures/"):
		return "res://" + image_name
	
	# Add pictures/ prefix
	return "res://pictures/" + image_name

func create_input_box() -> LineEdit:
	"""Create input field for puzzle"""
	var input = LineEdit.new()
	input.placeholder_text = "TYPE ANSWER..."
	input.custom_minimum_size = Vector2(300, 40)
	choices_container.add_child(input)
	input.grab_focus()
	return input

# ============================================================
# DEBUG / CHEAT FUNCTIONS
# ============================================================

func debug_show_state():
	"""Print current game state to console"""
	print("\n=== GAME STATE ===")
	print("Current Scene: " + current_scene_id)
	print("Memories: %d/5" % game_state["memories"])
	print("Inventory: " + str(game_state["inventory"]))
	print("Flags: ")
	for flag in game_state["flags"]:
		print("  - %s: %s" % [flag, game_state["flags"][flag]])

func cheat_collect_all_memories():
	"""Debug: Unlock all memories"""
	for scene_key in ["scene_3", "loc_cafeteria_memory", "loc_yard_memory", "loc_teachers_memory", "loc_desk", "basement_digging"]:
		game_state["memoryScenes"][scene_key] = true
	game_state["memories"] = 5
	update_ui_state()

func cheat_get_all_items():
	"""Debug: Get all items"""
	set_flag("hasFlashlight", true)
	set_flag("hasName", true)
	set_flag("hasKey", true)
	set_flag("hasShovel", true)
	add_inventory_item("hasFlashlight", "Flashlight")
	add_inventory_item("hasName", "Name")
	add_inventory_item("hasKey", "Key")
	add_inventory_item("hasShovel", "Shovel")
	update_ui_state()
