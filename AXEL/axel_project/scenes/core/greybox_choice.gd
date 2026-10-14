class_name GreyboxChoice
extends Control

@export var room_id: String = ""

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const BASEMENT_DOOR_ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const ENDING_4 := "res://scenes/Endings/7.4_Ending4.tscn"
const ENDING_TRUE := "res://scenes/Endings/7.5_EndingTrue.tscn"
const SYMBOL_COLUMNS := 5

var _busy := false
var _dialogue: Node
var _choices: VBoxContainer
var _input: LineEdit


func _ready() -> void:
	_build_look()
	call_deferred("_play_and_offer")


func _build_look() -> void:
	var fill := ColorRect.new()
	fill.color = Color(1, 1, 1, 1)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	var frame := ReferenceRect.new()
	frame.border_color = Color(0, 0, 0, 1)
	frame.border_width = 6.0
	frame.editor_only = false
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	var stamp := Label.new()
	stamp.text = "GREY-BOX  ·  %s  ·  art later" % _def().get("label", room_id)
	stamp.add_theme_font_override("font", FONT)
	stamp.add_theme_font_size_override("font_size", 28)
	stamp.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	stamp.position = Vector2(32, 28)
	add_child(stamp)
	_draw_floorplan()
	var overlay := load("res://scenes/ui/TopDialogueOverlay.tscn") as PackedScene
	if overlay != null:
		_dialogue = overlay.instantiate()
		add_child(_dialogue)
	var layer := CanvasLayer.new()
	layer.layer = 110
	add_child(layer)
	_choices = VBoxContainer.new()
	_choices.position = Vector2(48, 120)
	_choices.add_theme_constant_override("separation", 10)
	layer.add_child(_choices)
	if bool(_def().get("input", false)):
		_input = LineEdit.new()
		_input.custom_minimum_size = Vector2(420, 48)
		_input.placeholder_text = "Type the name"
		_input.add_theme_font_override("font", FONT)
		_input.add_theme_font_size_override("font_size", 28)
		_input.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_input.add_theme_color_override("font_placeholder_color", Color(0.7, 0.7, 0.7, 1))
		_choices.add_child(_input)
	var x := Button.new()
	x.text = "X"
	x.add_theme_font_override("font", FONT)
	x.add_theme_font_size_override("font_size", 36)
	x.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	x.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
	x.anchor_left = 1.0
	x.anchor_top = 1.0
	x.anchor_right = 1.0
	x.anchor_bottom = 1.0
	x.offset_left = -82
	x.offset_top = -82
	x.offset_right = -24
	x.offset_bottom = -24
	x.pressed.connect(_on_x)
	layer.add_child(x)
	set_process_unhandled_input(true)


func _play_and_offer() -> void:
	var def: Dictionary = _def()
	_apply_enter_effects(def)
	var lines: PackedStringArray = def.get("lines", PackedStringArray())
	if _dialogue != null and lines.size() > 0 and _dialogue.has_method("show_lines"):
		await _dialogue.show_lines(Array(lines))
	if _start_lore_fight_if_needed(def):
		return
	_offer_choices(def)


func _start_lore_fight_if_needed(def: Dictionary) -> bool:
	var flag := String(def.get("set_flag", ""))
	if flag != "hasShovel" and flag != "hasName":
		return false
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("start_lore_fight"):
		return false
	if not bool(world.call("start_lore_fight", flag, scene_file_path, false)):
		return false
	if _dialogue != null and _dialogue.has_method("interrupt_line"):
		_dialogue.interrupt_line()
	return true


func _offer_choices(def: Dictionary) -> void:
	for child in _choices.get_children():
		if child == _input:
			continue
		child.queue_free()
	if bool(def.get("input", false)):
		var submit := Button.new()
		submit.text = "Submit"
		_style_choice(submit)
		submit.pressed.connect(_on_submit)
		_choices.add_child(submit)
	if bool(def.get("symbols", false)):
		_offer_symbols()
	for choice in def.get("choices", []):
		if not _choice_visible(choice):
			continue
		var button := Button.new()
		button.text = String(choice.get("label", "Continue"))
		_style_choice(button)
		var dest := String(choice.get("to", ""))
		button.pressed.connect(func() -> void: _go(dest, choice))
		_choices.add_child(button)


func _offer_symbols() -> void:
	var grid := GridContainer.new()
	grid.columns = SYMBOL_COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_choices.add_child(grid)
	for symbol in _symbol_order():
		var button := Button.new()
		button.text = symbol
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 56)
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
		button.custom_minimum_size = Vector2(72, 72)
		var dest := _symbol_dest(symbol)
		button.pressed.connect(func() -> void: _go(dest, {}))
		grid.add_child(button)


func _symbol_order() -> PackedStringArray:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("corpse_symbol_order"):
		return PackedStringArray()
	return world.call("corpse_symbol_order")


func symbol_choices() -> Dictionary:
	var out := {}
	for symbol in _symbol_order():
		out[symbol] = _symbol_dest(symbol)
	return out


func _symbol_dest(symbol: String) -> String:
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("corpse_symbol_correct"):
		if bool(world.call("corpse_symbol_correct", symbol)):
			return ENDING_TRUE
	return ENDING_4


func _style_choice(button: Button) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
	button.custom_minimum_size = Vector2(420, 44)
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _gm() -> Node:
	return get_node_or_null("/root/GameManager")


func _flag(flag_name: String) -> bool:
	var gm := _gm()
	return gm != null and bool(gm.call("get_flag", flag_name))


func _choice_visible(choice: Dictionary) -> bool:
	var need := String(choice.get("need", ""))
	if not need.is_empty() and not _flag(need):
		return false
	var need_not := String(choice.get("need_not", ""))
	if not need_not.is_empty() and _flag(need_not):
		return false
	return true


func _apply_enter_effects(def: Dictionary) -> void:
	var gm := _gm()
	if gm == null:
		return
	var flag := String(def.get("set_flag", ""))
	if not flag.is_empty():
		gm.call("set_flag", flag, true)
		if flag == "hasShovel":
			gm.call("add_inventory_item", "hasShovel", "Shovel")
		if flag == "hasName":
			gm.call("add_inventory_item", "hasName", "Name")
			gm.call("set_flag", "knowsName", true)
	var mem := String(def.get("memory", ""))
	if not mem.is_empty():
		gm.call("add_memory_once", mem)
	var spawn := String(def.get("spawn", ""))
	if not spawn.is_empty():
		gm.call("set_basement_spawn_side", spawn)


func _on_submit() -> void:
	if _busy or _input == null:
		return
	var typed := _input.text.strip_edges().to_upper()
	var ok := typed == "AXEL"
	var def: Dictionary = _def()
	if ok:
		_go(String(def.get("on_correct", "")), {})
	else:
		_go(String(def.get("on_wrong", "")), {})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_on_x()
		get_viewport().set_input_as_handled()


func _draw_floorplan() -> void:
	var plan := ColorRect.new()
	plan.color = Color(0, 0, 0, 1)
	plan.position = Vector2(48, 720)
	plan.size = Vector2(420, 8)
	add_child(plan)
	var upright := ColorRect.new()
	upright.color = Color(0, 0, 0, 1)
	upright.position = Vector2(48, 560)
	upright.size = Vector2(8, 168)
	add_child(upright)
	var room := ColorRect.new()
	room.color = Color(0, 0, 0, 0)
	room.position = Vector2(56, 568)
	room.size = Vector2(200, 144)
	add_child(room)
	var outline := ReferenceRect.new()
	outline.border_color = Color(0, 0, 0, 1)
	outline.border_width = 3.0
	outline.editor_only = false
	outline.position = Vector2(56, 568)
	outline.size = Vector2(200, 144)
	add_child(outline)


func _on_x() -> void:
	var def: Dictionary = _def()
	var back := String(def.get("back", TITLE_SCENE))
	var effects := {}
	if back == BASEMENT_DOOR_ROOM:
		effects["spawn"] = "basement_door"
	_go(back, effects)


func _go(path: String, choice: Dictionary) -> void:
	if _busy or path.is_empty():
		return
	_busy = true
	_apply_enter_effects(choice)
	if _dialogue != null and _dialogue.has_method("interrupt_line"):
		_dialogue.interrupt_line()
	if get_tree().change_scene_to_file(path) != OK:
		_busy = false


func _def() -> Dictionary:
	match room_id:
		"6.1":
			return {
				"label": "BASEMENT DOOR",
				"lines": PackedStringArray(["The basement door. It still knows you."]),
				"back": BASEMENT_DOOR_ROOM,
				"choices": [
					{"label": "Unlock with key", "need": "hasKey", "to": "res://scenes/Arc_6/6.3_BasementStairs.tscn"},
					{"label": "Try the handle (Locked)", "need_not": "hasKey", "to": "res://scenes/Arc_6/6.2_BasementLocked.tscn"},
					{"label": "Go back", "to": BASEMENT_DOOR_ROOM, "spawn": "basement_door"},
				],
			}
		"6.2":
			return {
				"label": "LOCKED",
				"lines": PackedStringArray(["You need a key, dumbass."]),
				"back": BASEMENT_DOOR_ROOM,
				"choices": [{"label": "Go back", "to": BASEMENT_DOOR_ROOM, "spawn": "basement_door"}],
			}
		"6.3":
			return {
				"label": "STAIRCASE",
				"lines": PackedStringArray([
					"The door opens to a terrible screetch.",
					"In front of you stairs descending into pitch-blackness.",
					"Are you ready?",
				]),
				"back": "res://scenes/Arc_6/6.1_BasementDoor.tscn",
				"choices": [
					{"label": "Go down", "need": "hasFlashlight", "to": "res://scenes/Arc_6/6.4_BasementMain.tscn"},
					{"label": "Go down", "need_not": "hasFlashlight", "to": "res://scenes/Endings/7.2_Ending2.tscn"},
					{"label": "I'm not ready", "to": BASEMENT_DOOR_ROOM, "spawn": "basement_door"},
				],
			}
		"6.4":
			return {
				"label": "MAIN CHAMBER",
				"lines": PackedStringArray(["The air down here is older than the school."]),
				"back": "res://scenes/Arc_6/6.6_BasementStuck.tscn",
				"choices": [
					{"label": "Pick up the shovel", "need_not": "hasShovel", "to": "res://scenes/Arc_6/6.5_BasementShovelPickup.tscn"},
					{"label": "Dig (Requires shovel)", "need": "hasShovel", "to": "res://scenes/Arc_6/6.7_BasementDigging.tscn"},
					{"label": "Turn back", "to": "res://scenes/Arc_6/6.6_BasementStuck.tscn"},
				],
			}
		"6.5":
			return {
				"label": "FOUND",
				"lines": PackedStringArray(["The same old shovel still here."]),
				"set_flag": "hasShovel",
				"back": "res://scenes/Arc_6/6.4_BasementMain.tscn",
				"choices": [{"label": "Continue", "to": "res://scenes/Arc_6/6.4_BasementMain.tscn"}],
			}
		"6.6":
			return {
				"label": "NO RETURN",
				"lines": PackedStringArray(["I'm not letting you."]),
				"back": "res://scenes/Arc_6/6.4_BasementMain.tscn",
				"choices": [{"label": "Back", "to": "res://scenes/Arc_6/6.4_BasementMain.tscn"}],
			}
		"6.7":
			return {
				"label": "DIGGING",
				"lines": PackedStringArray(["As you keep digging.", "A memory surfaces."]),
				"memory": "basement_memory",
				"back": "res://scenes/Arc_6/6.8_BasementCorpse.tscn",
				"choices": [{"label": "FACE THE TRUTH", "to": "res://scenes/Arc_6/6.8_BasementCorpse.tscn"}],
			}
		"6.8":
			return {
				"label": "CORPSE",
				"lines": PackedStringArray(["The body is waiting for a name."]),
				"back": "res://scenes/Arc_6/6.4_BasementMain.tscn",
				"symbols": true,
				"choices": [],
			}
		"5.3":
			return {
				"label": "BOARD",
				"lines": PackedStringArray(["The symbols settle into one word. Write it."]),
				"input": true,
				"on_correct": "res://scenes/Arc_5/5.4_ClassroomBoardSuccess.tscn",
				"on_wrong": "res://scenes/Arc_5/5.1_Classroom.tscn",
				"back": "res://scenes/Arc_5/5.1_Classroom.tscn",
				"choices": [],
			}
		"5.4":
			return {
				"label": "BOARD",
				"lines": PackedStringArray(["You know the name now. You wish you didn't."]),
				"set_flag": "hasName",
				"back": "res://scenes/Arc_5/5.1_Classroom.tscn",
				"choices": [{"label": "Leave the board", "to": "res://scenes/Arc_5/5.1_Classroom.tscn"}],
			}
		_:
			return {"label": room_id, "lines": PackedStringArray(), "choices": [], "back": TITLE_SCENE}
