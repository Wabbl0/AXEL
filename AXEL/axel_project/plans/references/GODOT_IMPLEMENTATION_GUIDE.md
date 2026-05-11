# GUILT Game - Godot GDScript Implementation Guide

## Overview

This document explains the exported game data structure (`game_data.json`) and provides guidance on implementing the game in Godot 4.x with GDScript.

## File Structure

### `game_data.json`
Contains all game logic, narrative content, and state management data in a structured JSON format.

---

## Data Structure Breakdown

### 1. **gameMetadata**
Basic information about the game.

```json
{
  "title": "GUILT",
  "version": "1.0",
  "description": "A choice-based narrative adventure game exploring memory, guilt, and redemption",
  "startScene": "start",
  "language": "en"
}
```

### 2. **gameState**
Defines all game state variables and their initial values. Initialize these at game start.

```json
{
  "inventory": [],                    // List of collected items
  "memories": 0,                      // Count of memories unlocked (max 5)
  "memoryScenes": {},                 // Tracks visited memory scenes (keys as scene IDs)
  "flags": {
	"hasFlashlight": false,           // Required to explore kitchen
	"hasName": false,                 // Required for true ending
	"hasKey": false,                  // Required to unlock basement
	"hasShovel": false,               // Required to dig in basement
	"deskSequencePlayed": false,      // Tracks desk animation
	"knowsName": false,               // Internal: knows name is "Axel"
	"isDead": false                   // Unused in current version
  }
}
```

### 3. **scenes**
The main game content. Each scene is a self-contained narrative moment with associated logic.

#### Scene Object Structure:

```json
{
  "id": "unique_scene_id",
  "name": "LOCATION NAME",            // Displayed in status bar
  "text": "Narrative text...",         // Main story text
  "image": "filename.png",             // Background image (optional, in pictures/)
  "type": "normal|input|ending|conditionalJump|epilogue",
  "choices": [],                       // Navigation options (see below)
  "onEnter": {},                       // Actions executed on scene load
  "imageOverride": {},                 // Conditional image changes
  "sequenceLogic": {},                 // Complex interaction sequences
  "interactiveElements": []            // Clickable hotspots
}
```

#### Choice Object:

```json
{
  "id": "unique_choice_id",
  "text": "Button text",
  "target": "target_scene_id",
  "condition": "!hasKey",              // Optional: conditional rendering
  "specialClass": "text-red-600"       // Optional: styling (Tailwind classes)
}
```

#### onEnter Actions:

Single action:
```json
{
  "action": "addMemoryOnce",
  "sceneKey": "scene_id"
}
```

Multiple actions:
```json
{
  "actions": [
	{
	  "action": "setFlag",
	  "flag": "hasFlashlight",
	  "value": true
	},
	{
	  "action": "addInventoryItem",
	  "item": "itemKey",
	  "displayName": "Flashlight"
	}
  ]
}
```

### 4. **Scene Types**

#### **normal**
Standard narrative scene with choices that navigate to other scenes.

#### **input**
Puzzle scene requiring text input. Player must match `correctAnswer`.

```json
{
  "type": "input",
  "correctAnswer": "AXEL",
  "successTarget": "success_scene",
  "failTarget": "fail_scene",
  "failText": "Incorrect answer message"
}
```

#### **conditionalJump**
Logic scene that checks a condition and jumps to different scenes.

```json
{
  "type": "conditionalJump",
  "condition": "hasFlashlight",
  "successTarget": "basement_main",
  "failTarget": "ending_2"
}
```

#### **ending** / **epilogue**
Final scenes that typically offer restart option.

---

## Key Game Mechanics

### 1. **Memory System**
- Players collect 5 memories throughout the game
- Each unique memory scene awards one memory point
- Memories are tracked via `memoryScenes` object
- Use `addMemoryOnce(sceneKey)` to ensure memories are only collected once

### 2. **Inventory System**
- Dynamic item collection
- Items have both internal keys (`hasFlashlight`) and display names (`Flashlight`)
- Inventory is checked via `flags` object

### 3. **Conditional Scenes (Locked Scenes)**
Three scenes have location-based locks:

| Scene | Condition | Requirement |
|-------|-----------|-------------|
| `loc_kitchen` | `!hasFlashlight` | Find flashlight in kitchen |
| `loc_yard` | `!memoryScenes.loc_yard_memory` | Experience yard memory |
| `loc_teachers` | `!hasKey` | Find basement key |

When locked, choice buttons should be disabled/grayed out.

### 4. **Complex Sequences**

**Desk Sequence** (`loc_desk`):
- Triggered on first visit: `!deskSequencePlayed`
- Shows timed visual effects (image changes with shake animation)
- Updates text after animations complete
- Sets `deskSequencePlayed` flag to prevent replay

**Yard Memory Sequence** (`loc_yard`):
- Triggered on first visit to backyard
- Multi-step progression on repeated clicks:
  1. Show memory text with glitch effect
  2. Show reveal text with lighter discovery
  3. Set flags and inventory

**Teachers Memory Sequence** (`loc_teachers`):
- Similar multi-step progression for teacher's lounge scene

### 5. **Smoking Hint System**
In `loc_yard_hint` scene, display a random hint from `hints.smoking_hints` based on:
- Missing `hasFlashlight` → hint about darkness
- Missing `hasName` → hint about forgotten name
- Missing `hasKey` → hint about locked basement
- Memories < 5 → hint about exploring more

If all conditions met, display: `"I'm ready."`

### 6. **Multiple Endings**

| Ending | Trigger | Outcome |
|--------|---------|---------|
| #1 | Turn away from school | Walk away, never learn truth |
| #2 | Enter basement without flashlight | Fall down stairs, death |
| #3 | Answer wrong at corpse | Fire/hell ending |
| #4 | Answer correct but missing name | Convicted of murder |
| TRUE | Answer correct + have name | Redemption, forgive Axel |
| Epilogue | True ending choice | Free, at peace |

---

## Implementation in GDScript

### 1. **Load Game Data**

```gdscript
extends Node

var game_data: Dictionary = {}
var game_state: Dictionary = {}
var current_scene_id: String = ""

func _ready():
    load_game_data()
    initialize_game_state()

func load_game_data():
	var file = FileAccess.open("res://game_data.json", FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    game_data = json
	print("Loaded %d scenes" % game_data["scenes"].size())

func initialize_game_state():
	game_state = game_data["gameState"].duplicate(true)
	load_scene(game_data["gameMetadata"]["startScene"])
```

### 2. **Scene Loading**

```gdscript
func load_scene(scene_id: String):
    current_scene_id = scene_id
	var scene = game_data["scenes"][scene_id]
    
    if not scene:
		push_error("Scene not found: " + scene_id)
        return
    
    # Display location name
	update_ui(scene["name"])
    
    # Handle different scene types
	match scene.get("type", "normal"):
		"conditionalJump":
            handle_conditional_jump(scene)
		"input":
            display_input_puzzle(scene)
		"normal", "ending", "epilogue":
            display_narrative_scene(scene)
    
    # Execute onEnter actions
	if scene.has("onEnter"):
		execute_on_enter(scene["onEnter"])
```

### 3. **Conditional Scene Locking**

```gdscript
func is_scene_locked(scene_id: String) -> bool:
	if not game_data["lockedScenes"].has(scene_id):
        return false
    
	var lock_info = game_data["lockedScenes"][scene_id]
	return not evaluate_condition(lock_info["condition"])

func evaluate_condition(condition: String) -> bool:
    # Parse and evaluate GDScript-like conditions
	# Examples: "!hasFlashlight", "hasKey", "memories >= 3"
    # Handle: !flag, flag, flag1 && flag2, flag1 || flag2
    
    # Simple implementation for your game:
	if condition.begins_with("!"):
		var flag = condition.trim_prefix("!")
        return not get_flag(flag)
    else:
        return get_flag(condition)

func get_flag(flag_name: String) -> bool:
	if game_state["flags"].has(flag_name):
		return game_state["flags"][flag_name]
    return false

func set_flag(flag_name: String, value: bool):
	game_state["flags"][flag_name] = value
	emit_signal("state_changed")
```

### 4. **Handle Actions**

```gdscript
func execute_on_enter(on_enter: Dictionary):
	if on_enter.has("action"):
        execute_action(on_enter)
	elif on_enter.has("actions"):
		for action in on_enter["actions"]:
            execute_action(action)

func execute_action(action: Dictionary):
	match action["action"]:
		"setFlag":
			set_flag(action["flag"], action["value"])
		"addInventoryItem":
			add_inventory_item(action["item"], action["displayName"])
		"addMemoryOnce":
			add_memory_once(action["sceneKey"])
		"resetGameState":
            initialize_game_state()
		"displaySmokingHint":
            display_smoking_hint()
		"addMemory":
            add_memory()

func add_memory_once(scene_key: String):
	if not game_state["memoryScenes"].has(scene_key):
		game_state["memoryScenes"][scene_key] = true
        add_memory()

func add_memory():
	game_state["memories"] += 1
	emit_signal("memory_collected", game_state["memories"])

func add_inventory_item(item_key: String, display_name: String):
	if not item_key in game_state["inventory"]:
		game_state["inventory"].append(display_name)
		emit_signal("inventory_changed", game_state["inventory"])
```

### 5. **Input Puzzle Handling**

```gdscript
func handle_input_puzzle(scene: Dictionary, player_input: String):
	if player_input.to_upper() == scene["correctAnswer"]:
		load_scene(scene["successTarget"])
    else:
		display_message(scene.get("failText", "Wrong answer..."))
		if scene.has("failTarget"):
            await get_tree().create_timer(2.0).timeout
			load_scene(scene["failTarget"])
```

### 6. **Visual Effects**

```gdscript
func apply_sequence_logic(scene_id: String, scene: Dictionary):
	if not scene.has("sequenceLogic"):
        return
    
	var seq = scene["sequenceLogic"]
	if seq["type"] == "deskSequence":
        handle_desk_sequence(seq)
	elif seq["type"] == "yardMemorySequence":
        handle_yard_sequence(seq)

func handle_desk_sequence(seq: Dictionary):
	for fx in seq.get("visualEffects", []):
		await get_tree().create_timer(fx["delay"] / 1000.0).timeout
        
		match fx["effect"]:
			"imageSwitch":
				update_background_image(fx["newImage"])
				apply_visual_classes(fx.get("applyClass", ""))
			"revealText":
				update_text(fx["text"])
				remove_visual_classes(fx.get("removeClass", ""))
```

---

## Asset Requirements

All image files should be placed in `pictures/` directory:

- `school.png` - Starting scene
- `corridor.png` - Main hallway
- `hub.png` - Your locker (hub)
- `cafeteria.png` - Dining hall
- `cafeteria_table.png` - Your table with friend
- `kitchen.png` - School kitchen (dark)
- `kitchen_no_flash.png` - Kitchen with flashlight
- `backyard.png` - School backyard
- `cigarette.png` - Intermission image
- `classroom.png` - Main classroom
- `desk_empty.jpg` - Friend's desk (empty)
- `desk_hand.png` - Desk during sequence
- `desk.png` - Desk after interaction
- `board.png` - Chalkboard with code
- `teacher_key.png` - Teachers lounge with key
- `teacher_no_key.png` - Teachers lounge (key taken)
- `map.png` - School map

---

## GDScript Tips for Implementation

1. **Use enums for scene IDs** to avoid string typos:
   ```gdscript
   enum SCENES { START, SCENE_2, SCENE_3, ... }
   ```

2. **Create signals for state changes**:
   ```gdscript
   signal memory_collected(count)
   signal inventory_changed(items)
   signal scene_loaded(scene_id)
   signal state_changed()
   ```

3. **Modularize UI components**:
   - StatusBar: Show location, memory count, inventory
   - NarrativeBox: Display story text
   - ChoicesPanel: Render choice buttons
   - InputPuzzle: Handle text input scenes

4. **Use tweens for visual effects**:
   ```gdscript
   var tween = create_tween()
   tween.tween_callback(func(): update_image())
   tween.tween_property(image, "modulate:a", 0.0, 0.3)
   ```

5. **Handle scene transitions smoothly**:
   ```gdscript
   func transition_to_scene(scene_id: String):
       var tween = create_tween()
	   tween.tween_property(ui_container, "modulate:a", 0.0, 0.2)
       tween.tween_callback(func(): load_scene(scene_id))
	   tween.tween_property(ui_container, "modulate:a", 1.0, 0.2)
   ```

---

## Testing Checklist

- [ ] All 7 endings are reachable
- [ ] All 5 memories can be collected
- [ ] Inventory items persist correctly
- [ ] Locked scenes prevent progression until conditions are met
- [ ] Input puzzles validate "AXEL" correctly
- [ ] Smoking hints display appropriate messages
- [ ] Visual effects (desk sequence) play correctly
- [ ] State resets properly on game restart
- [ ] All images load from correct paths

---

## Notes

- The JSON structure is game-independent and focuses on narrative flow
- Conditions use simple flag checks (can be extended with proper expression parser)
- The "feel" of the game is preserved through:
  - Atmospheric text and scene descriptions
  - Sequential memory unlocking mechanic
  - Multiple ending branches based on player choices
  - Visual/audio feedback systems (adapt from retro CRT/glitch theme)
- Consider adding sound design to enhance the psychological horror atmosphere
