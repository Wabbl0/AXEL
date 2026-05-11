# GUILT Game - Godot Port Files

This folder contains all the exported data and implementation guides for porting the GUILT narrative adventure game from HTML/JavaScript to Godot 4.x with GDScript.

## Files

### 1. **game_data.json**
Complete game data export containing:
- All 28 scenes with narrative text, images, and choices
- Game state template (inventory, memories, flags)
- Conditional logic and scene locking rules
- Puzzle answers and ending conditions
- Hint system data

**Usage**: Load this in Godot to populate your game without hardcoding content.

### 2. **GODOT_IMPLEMENTATION_GUIDE.md**
Comprehensive documentation including:
- Data structure breakdown
- Game mechanics explanation
- Scene types and their behavior
- Multiple ending logic
- GDScript implementation examples
- Asset requirements checklist
- Testing checklist

**Start here** if you're new to porting this project.

### 3. **GameManager.gd**
Production-ready GDScript template featuring:
- Complete game state management
- Scene loading and transitions
- Conditional evaluation system
- Action execution framework
- UI update functions
- Input puzzle handling
- Debug/cheat commands

**Copy this** into your Godot project as the foundation for your game manager.

---

## Quick Start for Godot

### Step 1: Project Setup
1. Create new Godot 4.x project
2. Create folder structure:
   ```
   res://
   ├── exports/
   │   ├── game_data.json
   │   ├── GameManager.gd
   │   └── GODOT_IMPLEMENTATION_GUIDE.md
   ├── pictures/
   │   └── (all image assets)
   ├── scenes/
   │   ├── MainGame.tscn
   │   └── (your UI scene)
   └── scripts/
   ```

### Step 2: Load Game Data
```gdscript
extends Node

var game_manager: GameManager

func _ready():
    game_manager = GameManager.new()
    add_child(game_manager)
    game_manager.load_game_data()
```

### Step 3: Create UI Nodes
Your main scene needs:
- **StatusBar**: Display location, memory count, inventory
- **StoryBox**: Large text label for narrative
- **BackgroundImage**: TextureRect for scene images
- **ChoicesPanel**: VBoxContainer for choice buttons
- **InputBox**: LineEdit for puzzle answers

### Step 4: Connect Signals
```gdscript
game_manager.scene_changed.connect(_on_scene_changed)
game_manager.memory_collected.connect(_on_memory_collected)
game_manager.inventory_changed.connect(_on_inventory_changed)
```

---

## Game Overview

**Title**: GUILT  
**Type**: Choice-based narrative adventure (CYOA)  
**Themes**: Memory, guilt, redemption, psychological horror  
**Length**: 6-8 endings, ~20 scenes per playthrough  
**Gameplay**: Collection of 5 memories, inventory management, multiple endings

### Core Mechanics
- **Memory System**: Collect 5 memories to unlock true ending
- **Inventory**: Find 3 key items (flashlight, key, name)
- **Branching Narrative**: 5+ distinct endings based on choices
- **Conditional Progression**: Some locations locked until conditions met

### The Story
You return to your old school building to face your guilt over your best friend Axel. Through exploration and collected memories, you piece together what happened. The ultimate truth, and how you handle it, determines your ending.

---

## Visual Style

The game maintains a **retro computer aesthetic**:
- VT323 monospace font (terminal style)
- CRT scanlines overlay
- Glitch effects for dramatic moments
- Red accent colors for important choices
- Dark, atmospheric color schemes
- Pixelated/digital art style

**Preserve this feeling in Godot** by:
- Using pixel-perfect camera settings
- Adding CRT shader effects
- Using glitch/distortion shaders for memory moments
- Maintaining the VT323 font throughout
- Using red accents for critical choices

---

## Content Summary

### Scenes (28 total)
- **Intro/Hub**: start, scene_2, scene_3 (locker)
- **Explorable Locations**: 
  - Cafeteria (memory scene available)
  - Kitchen (hidden flashlight)
  - Classroom (desk interaction, name puzzle)
  - Backyard (lighter memory, smoking hint)
  - Teachers Lounge (basement key)
- **Basement Arc**: Entry, stairs, main chamber, digging, revelation
- **Endings**: 5 bad endings + 1 true ending + 1 epilogue

### Flags (7 total)
- `hasFlashlight` - Required for basement
- `hasKey` - Required to unlock basement door
- `hasName` - Required for true ending (knowing "AXEL")
- `hasShovel` - Required to dig in basement
- `deskSequencePlayed` - Prevents replay of desk animation
- `knowsName` - Internal flag for story logic
- `isDead` - Unused (reserved)

### Memories (5 total)
1. Your locker (hub scene)
2. Cafeteria incident (abandoning friend)
3. Backyard lighter (learning friend's name)
4. Teachers lounge (lying to police)
5. Basement digging (final confrontation)

---

## Customization Ideas

Once you have the basic port working:

1. **Enhanced Visuals**
   - Add parallax backgrounds
   - Implement CRT shader effects
   - Create animated UI elements
   - Add visual transitions between scenes

2. **Audio Design**
   - Atmospheric ambient music
   - Sound effects for interactions
   - Glitch sounds for memory moments
   - Voice acting (optional)

3. **Extended Mechanics**
   - Inventory interaction system
   - Hotspot-based exploration
   - Dialogue/conversation trees
   - Save/load system with multiple slots

4. **Expanded Story**
   - Additional memory scenes
   - New endings based on specific choices
   - Post-game commentary
   - Alternative routes through locations

---

## Troubleshooting

### Error: "Game data file not found"
- Ensure `game_data.json` is in `res://exports/`
- Check file path in `load_game_data()` matches actual location

### Images not loading
- Place all images in `res://pictures/` folder
- Check filenames match exactly (case-sensitive on Linux/Mac)
- Ensure image formats are supported (PNG, JPG, WebP)

### Scenes not loading
- Verify scene IDs in choices match actual scene IDs in JSON
- Check for typos in `target` properties
- Use `debug_show_state()` to verify game state

### Conditions not evaluating correctly
- Review the `evaluate_condition()` function for complex expressions
- Test with simple flag checks first
- Add debug output to see what's being evaluated

---

## Technical Notes

- **JSON Format**: Preserves all game logic without requiring separate code
- **Scene Management**: Stateless scene loading (entire state in `game_state` dict)
- **Conditions**: Simple boolean expressions (extensible to full expression parser)
- **Platform Ready**: This structure works on Windows, Mac, Linux, Web, Mobile

---

## Resources

- Godot 4.x Documentation: https://docs.godotengine.org/
- GDScript Guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- Narrative Game Design: Check out other CYOA games (80 Days, Sorcery!, etc.)

---

## License & Attribution

Original game created in HTML/JavaScript.  
This Godot port structure preserves all original content and game design.

Remember: The power of your game is in its story and atmosphere. Focus on capturing the psychological weight and emotional impact of the narrative above all else.

---

**Happy coding! May your port preserve the GUILT.**
