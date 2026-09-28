extends SceneTree

const KITCHEN := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const HALL := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const LOUNGE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const BASEMENT := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const CORPSE := "res://scenes/Arc_6/6.8_BasementCorpse.tscn"
const ENDING_TRUE := "res://scenes/Endings/7.5_EndingTrue.tscn"
const ENDING_NONE := "res://scenes/Endings/7.4_Ending4.tscn"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	var gm := root.get_node_or_null("GameManager")
	if world == null or run == null or gm == null:
		push_error("board_room_question_check: autoloads missing")
		quit(1)
		return
	if load("res://scenes/Arc_5/5.1_Classroom.gd") == null:
		_fail("classroom script did not parse")
	_check_pick_and_room(world, run)
	_check_one_guess(world, run)
	_check_corpse(world, run, gm)
	_check_nametag_icon(run, gm)
	_check_round_trip(run)
	if _failures.is_empty():
		print("Board room question check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("board_room_question_check: %s" % msg)
	quit(1)


func _check_pick_and_room(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	run.state.seed = 111
	world.call("plan_floor_items", 111)
	var first: Dictionary = world.call("ensure_board_question")
	if not bool(first.get("ready", false)):
		_fail("board question was not ready")
		return
	var item_id := String(first.get("item_id", ""))
	var room := String(first.get("room_scene", ""))
	if item_id.is_empty() or room.is_empty():
		_fail("board question did not name an item and a room")
		return
	if run.call("load_item", item_id) == null:
		_fail("picked item %s is not in the catalog" % item_id)
	if not String(first.get("line", "")).begins_with("In which room is "):
		_fail("fresh item used the wrong question: %s" % str(first.get("line", "")))
	var again: Dictionary = world.call("ensure_board_question")
	if String(again.get("item_id", "")) != item_id or String(again.get("room_scene", "")) != room:
		_fail("opening the board again changed the question")
	var entries: Array = world._room_items.get(room, [])
	var marked := false
	for entry in entries:
		var placed: Dictionary = entry
		if String(placed.get("id", "")) != item_id:
			continue
		placed["taken"] = true
		marked = true
	if not marked:
		_fail("picked item was not in its saved room")
	else:
		var after: Dictionary = world.call("ensure_board_question")
		if not String(after.get("line", "")).begins_with("In which room was "):
			_fail("picked-up item stayed on 'is': %s" % str(after.get("line", "")))
		if String(after.get("item_id", "")) != item_id:
			_fail("picking the item up changed which item the board asks about")
	run.state.board_item_id = "C1"
	run.state.board_room_scene = KITCHEN
	if not bool(world.call("board_answer_matches", "kitchen")):
		_fail("kitchen did not count")
	if not bool(world.call("board_answer_matches", "  KiTcHeN  ")):
		_fail("kitchen spacing and case did not count")
	if not bool(world.call("board_answer_matches", "in kitchen")):
		_fail("in kitchen did not count")
	if not bool(world.call("board_answer_matches", "inside kitchen")):
		_fail("inside kitchen did not count")
	if not bool(world.call("board_answer_matches", "on kitchen")):
		_fail("on kitchen did not count")
	if bool(world.call("board_answer_matches", "in")):
		_fail("in alone counted")
	if bool(world.call("board_answer_matches", "hallway")):
		_fail("hallway counted for the kitchen")
	if bool(world.call("board_answer_matches", "corridor")):
		_fail("corridor alone counted")
	if bool(world.call("board_answer_matches", "")):
		_fail("a blank answer counted")
	run.state.board_room_scene = HALL
	if not bool(world.call("board_answer_matches", "classrooms corridor")):
		_fail("classrooms corridor did not count")
	if not bool(world.call("board_answer_matches", "hallway")):
		_fail("hallway did not count")
	if not bool(world.call("board_answer_matches", "inside classrooms corridor")):
		_fail("inside classrooms corridor did not count")
	if bool(world.call("board_answer_matches", "on corridor")):
		_fail("on corridor counted")
	if bool(world.call("board_answer_matches", "corridor")):
		_fail("corridor alone counted for the classrooms corridor")
	run.state.board_room_scene = LOUNGE
	if not bool(world.call("board_answer_matches", "teachers' lounge")):
		_fail("teachers' lounge did not count")
	if not bool(world.call("board_answer_matches", "lounge")):
		_fail("lounge did not count")
	run.state.board_room_scene = BASEMENT
	if not bool(world.call("board_answer_matches", "basement door")):
		_fail("basement door did not count")
	if not bool(world.call("board_answer_matches", "on basement door")):
		_fail("on basement door did not count")


func _check_one_guess(world: Node, run: Node) -> void:
	run.state.board_item_id = "C1"
	run.state.board_room_scene = KITCHEN
	run.state.board_guess_spent = false
	world.call("spend_board_guess")
	var question: Dictionary = world.call("ensure_board_question")
	if not bool(question.get("guess_spent", false)):
		_fail("the first guess did not lock the board")
	if String(question.get("item_id", "")) != "C1":
		_fail("spending the guess changed the item")
	if not bool(world.call("board_answer_matches", "kitchen")):
		_fail("the saved room stopped matching after the guess was spent")
	world.call("spend_board_guess")
	if not bool(run.state.board_guess_spent):
		_fail("a second guess was still open")


func _check_corpse(world: Node, run: Node, gm: Node) -> void:
	run.state.board_item_id = "C1"
	run.state.board_room_scene = KITCHEN
	run.state.equipped_item_ids = PackedStringArray()
	gm.call("set_flag", "hasName", false)
	if bool(world.call("answered_item_equipped")):
		_fail("corpse passed before the board was answered")
	if _corpse_dest() != ENDING_NONE:
		_fail("corpse scene did not send a missed answer to ending 4")
	gm.call("set_flag", "hasName", true)
	if bool(world.call("answered_item_equipped")):
		_fail("corpse passed when the item was not equipped")
	if _corpse_dest() != ENDING_NONE:
		_fail("corpse scene passed without the item equipped")
	run.state.equipped_item_ids = PackedStringArray(["C2"])
	if bool(world.call("answered_item_equipped")):
		_fail("a different equipped item passed the corpse")
	if _corpse_dest() != ENDING_NONE:
		_fail("corpse scene accepted a different item")
	run.state.equipped_item_ids = PackedStringArray(["C1"])
	if not bool(world.call("answered_item_equipped")):
		_fail("the answered item did not pass when equipped")
	if _corpse_dest() != ENDING_TRUE:
		_fail("corpse scene did not open the true ending")
	gm.call("set_flag", "hasName", false)
	run.state.equipped_item_ids = PackedStringArray()


func _corpse_dest() -> String:
	var packed: PackedScene = load(CORPSE)
	if packed == null:
		_fail("could not load the corpse scene")
		return ""
	var node := packed.instantiate()
	root.add_child(node)
	var def: Dictionary = node.call("_def")
	if bool(def.get("input", false)):
		_fail("corpse still asks for typed text")
	var choices: Array = def.get("choices", [])
	var dest := ""
	if choices.size() == 1:
		dest = String((choices[0] as Dictionary).get("to", ""))
	else:
		_fail("corpse should offer one face-it choice, got %d" % choices.size())
	node.free()
	return dest


func _check_nametag_icon(run: Node, gm: Node) -> void:
	var shelves: Node = load("res://scenes/ui/locker_shelves.gd").new()
	root.add_child(shelves)
	gm.call("set_flag", "hasName", false)
	run.state.board_item_id = "C1"
	if shelves.call("_answered_item_icon") != null:
		_fail("name tag icon appeared before the board was answered")
	gm.call("set_flag", "hasName", true)
	var item = run.call("load_item", "C1")
	var icon = shelves.call("_answered_item_icon")
	if item == null or icon == null or icon != item.get("icon"):
		_fail("name tag did not use the answered item icon")
	gm.call("set_flag", "hasName", false)
	shelves.queue_free()


func _check_round_trip(run: Node) -> void:
	run.state.board_item_id = "C1"
	run.state.board_room_scene = KITCHEN
	run.state.board_guess_spent = true
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.call("to_dict")))
	var restored = RunState.from_dict(parsed as Dictionary)
	if restored.board_item_id != "C1" or restored.board_room_scene != KITCHEN:
		_fail("board question was lost on save")
	if not restored.board_guess_spent:
		_fail("spent guess was lost on save")
