extends SceneTree

const ROOM_SCENES := {
	"6.1": "res://scenes/Arc_6/6.1_BasementDoor.tscn",
	"6.2": "res://scenes/Arc_6/6.2_BasementLocked.tscn",
	"6.3": "res://scenes/Arc_6/6.3_BasementStairs.tscn",
	"6.4": "res://scenes/Arc_6/6.4_BasementMain.tscn",
	"6.5": "res://scenes/Arc_6/6.5_BasementShovelPickup.tscn",
	"6.6": "res://scenes/Arc_6/6.6_BasementStuck.tscn",
	"6.7": "res://scenes/Arc_6/6.7_BasementDigging.tscn",
	"6.8": "res://scenes/Arc_6/6.8_BasementCorpse.tscn",
	"5.3": "res://scenes/Arc_5/5.3_ClassroomBoard.tscn",
	"5.4": "res://scenes/Arc_5/5.4_ClassroomBoardSuccess.tscn",
}

const BASEMENT_DOOR_ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const ENDING_4 := "res://scenes/Endings/7.4_Ending4.tscn"
const ENDING_TRUE := "res://scenes/Endings/7.5_EndingTrue.tscn"

const ENDINGS := [
	"res://scenes/Endings/7.2_Ending2.tscn",
	"res://scenes/Endings/7.3_Ending3.tscn",
	"res://scenes/Endings/7.4_Ending4.tscn",
	"res://scenes/Endings/7.5_EndingTrue.tscn",
	"res://scenes/Endings/7.6_Epilogue.tscn",
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		push_error("greybox_flow_check: GameManager missing")
		quit(1)
		return

	for path in ENDINGS:
		if not ResourceLoader.exists(path):
			failures.append("missing scene %s" % path)

	for room_id in ROOM_SCENES.keys():
		var path := String(ROOM_SCENES[room_id])
		if not ResourceLoader.exists(path):
			failures.append("missing scene %s" % path)
			continue
		var packed: PackedScene = load(path)
		var node: Node = packed.instantiate()
		root.add_child(node)
		var def: Dictionary = node.call("_def")
		if String(def.get("label", "")).is_empty():
			failures.append("%s missing label" % room_id)
		var back := String(def.get("back", ""))
		if back.is_empty() or not ResourceLoader.exists(back):
			failures.append("%s missing back path" % room_id)
		if bool(def.get("input", false)):
			for key in ["on_correct", "on_wrong"]:
				var dest := String(def.get(key, ""))
				if dest.is_empty() or not ResourceLoader.exists(dest):
					failures.append("%s missing %s" % [room_id, key])
		for choice in def.get("choices", []):
			var dest := String(choice.get("to", ""))
			if dest.is_empty() or not ResourceLoader.exists(dest):
				failures.append("%s choice missing dest" % room_id)
		node.queue_free()
		await process_frame

	gm.call("reset_state")
	var shovel_scene: PackedScene = load(String(ROOM_SCENES["6.5"]))
	var shovel: Node = shovel_scene.instantiate()
	root.add_child(shovel)
	shovel.call("_apply_enter_effects", shovel.call("_def"))
	if not bool(gm.call("get_flag", "hasShovel")):
		failures.append("6.5 should set hasShovel")
	shovel.queue_free()
	await process_frame

	gm.call("reset_state")
	var dig_scene: PackedScene = load(String(ROOM_SCENES["6.7"]))
	var dig: Node = dig_scene.instantiate()
	root.add_child(dig)
	dig.call("_apply_enter_effects", dig.call("_def"))
	if not bool(gm.call("has_memory_scene", "basement_memory")):
		failures.append("6.7 should grant basement_memory")
	dig.queue_free()
	await process_frame

	gm.call("reset_state")
	var board_scene: PackedScene = load(String(ROOM_SCENES["5.4"]))
	var board: Node = board_scene.instantiate()
	root.add_child(board)
	board.call("_apply_enter_effects", board.call("_def"))
	if not bool(gm.call("get_flag", "hasName")) or not bool(gm.call("get_flag", "knowsName")):
		failures.append("5.4 should set hasName and knowsName")
	board.queue_free()
	await process_frame

	for room_id in ["6.1", "6.2", "6.3"]:
		var back_scene: PackedScene = load(String(ROOM_SCENES[room_id]))
		var back_node: Node = back_scene.instantiate()
		root.add_child(back_node)
		var back_def: Dictionary = back_node.call("_def")
		for choice in back_def.get("choices", []):
			if String(choice.get("to", "")) != BASEMENT_DOOR_ROOM:
				continue
			if String(choice.get("spawn", "")) != "basement_door":
				failures.append("%s choice back to 1.4 has no basement_door spawn" % room_id)
			gm.set("basement_spawn_side", "")
			back_node.call("_apply_enter_effects", choice)
			if String(gm.call("take_basement_spawn_side")) != "basement_door":
				failures.append("%s choice did not set the basement_door spawn" % room_id)
		back_node.queue_free()
		await process_frame

	var corpse_scene: PackedScene = load(String(ROOM_SCENES["6.8"]))
	var corpse: Node = corpse_scene.instantiate()
	root.add_child(corpse)
	var corpse_def: Dictionary = corpse.call("_def")
	if not bool(corpse_def.get("symbols", false)):
		failures.append("6.8 should offer the symbol picker")
	var corpse_dests: Dictionary = corpse.call("symbol_choices")
	if corpse_dests.size() != 10:
		failures.append("6.8 should offer ten symbols, got %d" % corpse_dests.size())
	for symbol in corpse_dests.keys():
		var dest := String(corpse_dests[symbol])
		if dest != ENDING_4 and dest != ENDING_TRUE:
			failures.append("6.8 symbol %s goes to %s" % [symbol, dest])
	corpse.queue_free()

	if failures.is_empty():
		print("Greybox flow check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("greybox_flow_check: %s" % f)
		quit(1)
