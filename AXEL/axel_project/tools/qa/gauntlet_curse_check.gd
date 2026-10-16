extends SceneTree

const ENDING_3 := "res://scenes/Endings/7.3_Ending3.tscn"
const ENDING_4 := "res://scenes/Endings/7.4_Ending4.tscn"
const EndingScript := preload("res://scenes/Endings/ending_still.gd")

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		push_error("gauntlet_curse_check: autoloads missing")
		quit(1)
		return
	_check_picks(world, run)
	_check_loss_routing(world, run)
	_check_ending_lines(world)
	await _check_card(world, run)
	_check_state_round_trip(run)
	world.call("reset_world")
	run.call("reset_run")
	if _failures.is_empty():
		print("gauntlet_curse_check: OK")
		quit(0)
		return
	for msg in _failures:
		push_error("gauntlet_curse_check: " + msg)
	quit(1)


func _check_picks(world: Node, run: Node) -> void:
	var want := {"door": 1, "chamber": 1, "dig": 2, "final": 2}
	for seed_value in [11, 4242, 987654]:
		run.call("reset_run")
		run.state.seed = seed_value
		for fight_id in want.keys():
			var ids: Array = world.call("gauntlet_curse_ids", fight_id)
			if ids.size() != int(want[fight_id]):
				_fail("%s should carry %d curses, got %d" % [fight_id, int(want[fight_id]), ids.size()])
			var seen: Array = []
			for curse_id in ids:
				if seen.has(curse_id):
					_fail("%s picked %s twice" % [fight_id, curse_id])
				seen.append(curse_id)
				if not ResourceLoader.exists("res://combat/data/curses/%s.tres" % curse_id):
					_fail("%s picked unknown curse %s" % [fight_id, curse_id])
			var again: Array = world.call("gauntlet_curse_ids", fight_id)
			if again != ids:
				_fail("%s curses differ for the same seed" % fight_id)
	var any_diff := false
	run.state.seed = 11
	var first: Array = world.call("gauntlet_curse_ids", "dig")
	for seed_value in range(12, 40):
		run.state.seed = seed_value
		if (world.call("gauntlet_curse_ids", "dig") as Array) != first:
			any_diff = true
			break
	if not any_diff:
		_fail("dig curses never change between seeds")
	if not (world.call("gauntlet_curse_ids", "shovel") as Array).is_empty():
		_fail("non-gauntlet fights must not get curses")
	run.call("reset_run")


func _check_loss_routing(world: Node, run: Node) -> void:
	world.call("reset_world")
	if String(world.call("gauntlet_loss_ending", "door")) != "":
		_fail("losing the door fight should be a normal loss")
	if String(world.call("gauntlet_loss_ending", "chamber")) != ENDING_3:
		_fail("losing the chamber fight should open Ending 3")
	if String(world.call("gauntlet_lost_fight")) != "chamber":
		_fail("chamber loss was not remembered")
	if String(world.call("gauntlet_loss_ending", "dig")) != ENDING_3:
		_fail("losing the dig fight should open Ending 3")
	if String(world.call("gauntlet_loss_ending", "final")) != ENDING_4:
		_fail("losing the final fight should open Ending 4")
	world.call("gauntlet_loss_ending", "dig")
	var saved: Dictionary = world.call("to_dict")
	world.call("reset_world")
	world.call("from_dict", saved)
	if String(world.call("gauntlet_lost_fight")) != "dig":
		_fail("lost gauntlet fight did not survive save/load")
	world.call("reset_world")


func _check_ending_lines(world: Node) -> void:
	var chamber: Array = EndingScript.ending_3_lines_for("chamber")
	if chamber.is_empty() or String(chamber[chamber.size() - 1]) != "Together again.":
		_fail("chamber Ending 3 lines are wrong: %s" % str(chamber))
	var dig: Array = EndingScript.ending_3_lines_for("dig")
	if dig.is_empty() or String(dig[dig.size() - 1]) != "Now you're buried too.":
		_fail("dig Ending 3 lines are wrong: %s" % str(dig))
	world.call("reset_world")


func _check_card(world: Node, run: Node) -> void:
	run.call("reset_run")
	run.state.seed = 4242
	var ids: Array = world.call("gauntlet_curse_ids", "final")
	var card := CurseCard.new()
	card.curse_ids = ids
	root.add_child(card)
	await process_frame
	var names := card.find_children("CurseName*", "Label", true, false)
	if names.size() != ids.size():
		_fail("curse card shows %d names, want %d" % [names.size(), ids.size()])
	for node in card.find_children("CurseDescription*", "Label", true, false):
		var text := (node as Label).text
		if text.is_empty() or text.contains("{"):
			_fail("curse card description not filled: %s" % text)
	var info := CurseCard.curse_text("short_fuse")
	if String(info["description"]).contains("{"):
		_fail("Short Fuse text has a raw placeholder")
	card.queue_free()
	await process_frame


func _check_state_round_trip(run: Node) -> void:
	run.call("reset_run")
	run.state.fight_curses = [{"id": "ash", "params": {}}]
	run.state.gauntlet_id = "dig"
	var data: Dictionary = run.call("to_dict")
	run.call("from_dict", data)
	if (run.state.fight_curses as Array).size() != 1 or String(run.state.gauntlet_id) != "dig":
		_fail("fight curses did not survive save/load")
	run.call("reset_run")
