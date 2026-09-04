extends SceneTree
## Phase 6: every grey-box room and ending has a route in and a route out.

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

	if failures.is_empty():
		print("Greybox flow check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("greybox_flow_check: %s" % f)
		quit(1)
