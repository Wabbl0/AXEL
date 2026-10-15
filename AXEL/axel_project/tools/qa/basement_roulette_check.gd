extends SceneTree

const CHAMBER := "res://scenes/Arc_6/6.4_BasementMain.tscn"
const DOOR := "res://scenes/Arc_6/6.1_BasementDoor.tscn"
const DIG := "res://scenes/Arc_6/6.7_BasementDigging.tscn"
const CORPSE := "res://scenes/Arc_6/6.8_BasementCorpse.tscn"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_SFX", "1")
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
		push_error("basement_roulette_check: autoloads missing")
		quit(1)
		return
	_check_depth(world)
	_check_rolls(world, run)
	_check_flow(world, run)
	_check_decline(world, run)
	_check_room_defs()
	await _check_ui(world, run)
	world.call("reset_world")
	run.call("reset_run")
	if _failures.is_empty():
		print("basement_roulette_check: OK")
		quit(0)
		return
	for msg in _failures:
		push_error("basement_roulette_check: " + msg)
	quit(1)


func _fresh(world: Node, run: Node, run_seed: int) -> void:
	world.call("reset_world")
	run.call("reset_run")
	run.state.seed = run_seed
	world.call("plan_floor_items", run_seed)


func _check_depth(world: Node) -> void:
	for path in [CHAMBER, DOOR, DIG, CORPSE]:
		var mult := float(world.call("depth_goal_mult_for_scene", path))
		if not is_equal_approx(mult, 2.1):
			_fail("%s goal mult %.2f, want 2.1" % [path, mult])


func _check_rolls(world: Node, run: Node) -> void:
	var counts := [0, 0, 0, 0, 0]
	for run_seed in range(1, 41):
		_fresh(world, run, run_seed)
		var a := String(world.call("roulette_roll_id", 0))
		var b := String(world.call("roulette_roll_id", 0))
		if a.is_empty():
			_fail("seed %d rolled nothing" % run_seed)
			continue
		if a != b:
			_fail("seed %d gave %s then %s" % [run_seed, a, b])
		if run.call("load_item", a) == null:
			_fail("seed %d rolled missing item %s" % [run_seed, a])
		if Array(run.state.owned_item_ids).has(a):
			_fail("seed %d rolled an owned item %s" % [run_seed, a])
		var rank := int(world.call("item_rank_of_id", a))
		if rank >= 0 and rank < counts.size():
			counts[rank] += 1
		if (world.call("roulette_reel_ids") as Array).size() != 8:
			_fail("seed %d reel is not 8 items" % run_seed)
	if int(counts[0]) > 0:
		_fail("wheel rolled a Common: %s" % [counts])
	if int(counts[2]) + int(counts[3]) + int(counts[4]) == 0:
		_fail("wheel never rolled Rare or higher: %s" % [counts])


func _check_flow(world: Node, run: Node) -> void:
	_fresh(world, run, 777)
	if not bool(world.call("roulette_open")):
		_fail("wheel not open on a new save")
	if not String(world.call("roulette_respin")).is_empty():
		_fail("respin worked before the first spin")
	var first := String(world.call("roulette_spin"))
	if first.is_empty() or String(world.call("roulette_state")) != "pending":
		_fail("first spin did not leave a pending result")
	if not String(world.call("roulette_spin")).is_empty():
		_fail("second free spin was allowed")
	if bool(world.call("roulette_decline")):
		_fail("could leave after spinning")
	if not String(world.call("roulette_respin")).is_empty():
		_fail("respin worked without a ticket")
	run.state.tickets = 1
	var second := String(world.call("roulette_respin"))
	if second.is_empty() or second == first:
		_fail("respin with a ticket did not change the item (%s -> %s)" % [first, second])
	if int(run.call("ticket_count")) != 0:
		_fail("respin did not spend the ticket")
	var saved: Dictionary = world.call("to_dict")
	world.call("from_dict", saved)
	if String(world.call("roulette_item")) != second or String(world.call("roulette_state")) != "pending":
		_fail("save/load lost the pending wheel result")
	var dread_before := float(run.call("dread_pct"))
	if not bool(world.call("roulette_take")):
		_fail("take failed")
	if not Array(run.state.owned_item_ids).has(second):
		_fail("taken item not owned")
	if float(run.call("dread_pct")) <= dread_before:
		_fail("taking the wheel item added no Dread")
	if bool(world.call("roulette_open")) or bool(world.call("roulette_take")):
		_fail("wheel still open after take")


func _check_decline(world: Node, run: Node) -> void:
	_fresh(world, run, 778)
	if not bool(world.call("roulette_decline")):
		_fail("could not leave the wheel before spinning")
	if bool(world.call("roulette_open")) or not String(world.call("roulette_spin")).is_empty():
		_fail("wheel still spins after leaving")
	if not Array(run.state.owned_item_ids).is_empty() or float(run.call("dread_pct")) > 0.0:
		_fail("leaving the wheel gave an item or Dread")


func _check_room_defs() -> void:
	var want := {CHAMBER: "chamber", DIG: "dig", CORPSE: "final"}
	for path in want.keys():
		var node: Node = (load(String(path)) as PackedScene).instantiate()
		var def: Dictionary = node.call("_def")
		if String(def.get("fight", "")) != String(want[path]):
			_fail("%s fight id %s, want %s" % [path, def.get("fight", ""), want[path]])
		if String(path) == CHAMBER and not bool(def.get("roulette", false)):
			_fail("6.4 has no wheel")
		node.free()
	var door: Node = (load(DOOR) as PackedScene).instantiate()
	var found := false
	for choice in (door.call("_def") as Dictionary).get("choices", []):
		if String(choice.get("fight", "")) == "door":
			found = true
	if not found:
		_fail("6.1 unlock choice has no door fight")
	door.free()


func _check_ui(world: Node, run: Node) -> void:
	_fresh(world, run, 779)
	var roulette: Node = (load("res://scenes/ui/basement_roulette.gd") as GDScript).new()
	root.add_child(roulette)
	await process_frame
	var spin := _button(roulette, "Spin")
	if spin == null or not spin.visible:
		_fail("wheel UI has no Spin button")
		roulette.queue_free()
		return
	spin.emit_signal("pressed")
	var waited := 0
	while bool(roulette.call("is_spinning")) and waited < 600:
		await process_frame
		waited += 1
	var take := _button(roulette, "Take")
	if take == null or not take.visible:
		_fail("wheel UI shows no Take after the spin")
	if _button(roulette, "Leave it").visible:
		_fail("wheel UI still offers Leave it after the spin")
	take.emit_signal("pressed")
	await process_frame
	if String(world.call("roulette_state")) != "taken":
		_fail("Take button did not take the item")
	if is_instance_valid(roulette):
		roulette.queue_free()
	await process_frame


func _button(node: Node, text: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			return child as Button
	return null
