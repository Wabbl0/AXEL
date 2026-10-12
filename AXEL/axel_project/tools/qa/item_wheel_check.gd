extends SceneTree

const ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		push_error("item_wheel_check: autoloads missing")
		quit(1)
		return
	if change_scene_to_file(ROOM) != OK:
		_fail("could not load 1.2")
	else:
		for _i in 8:
			await process_frame
		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay != null and overlay.has_method("interrupt_line"):
			overlay.call("interrupt_line")
		for _i in 4:
			await process_frame
		var wheel := world.get_node_or_null("ItemWheel")
		if wheel == null:
			_fail("ItemWheel missing")
		else:
			await _check_box(wheel, run)
			await _check_pay(wheel, run)
			await _check_areas(wheel, world)
			await _check_anim(wheel)
	if _failures.is_empty():
		print("Item wheel check OK.")
		quit(0)
	else:
		for msg in _failures:
			push_error("item_wheel_check: %s" % msg)
		quit(1)


func _check_box(wheel: Node, run: Node) -> void:
	var tabs: PackedStringArray = wheel.call("tab_names")
	if tabs != PackedStringArray(["ITEMS", "STATS", "PAY", "AREAS"]):
		_fail("tabs should be ITEMS/STATS/PAY/AREAS, got %s" % str(tabs))
	run.call("reset_run")
	if not bool(wheel.call("open_wheel")):
		_fail("box did not open with no items")
		return
	await process_frame
	if bool(wheel.call("cap_is_visible")):
		_fail("cap should stay hidden until the player owns an item")
	var listed: PackedStringArray = wheel.call("listed_ids")
	if not listed.is_empty():
		_fail("empty inventory listed %s" % str(listed))
	if str(wheel.call("balance_text")) != "BALANCE: %d" % int(run.state.bankroll_cents):
		_fail("balance text %s does not match bankroll %d" % [str(wheel.call("balance_text")), int(run.state.bankroll_cents)])

	run.state.owned_item_ids = PackedStringArray(["E1", "C2", "L1", "U1", "C1"])
	run.state.equipped_item_ids = PackedStringArray(["C1", "L1"])
	await process_frame
	wheel.call("set_sort", 0)
	listed = wheel.call("listed_ids")
	_expect_ids(listed, ["C2", "C1", "U1", "E1", "L1"], "rarity sort")
	wheel.call("set_sort", 1)
	_expect_ids(wheel.call("listed_ids"), ["C1", "U1", "L1", "C2", "E1"], "newest sort")
	wheel.call("set_sort", 2)
	_expect_ids(wheel.call("listed_ids"), ["E1", "C1", "C2", "U1", "L1"], "name sort")
	wheel.call("set_sort", 0)
	wheel.call("set_rank_filter", 0)
	_expect_ids(wheel.call("listed_ids"), ["C2", "C1"], "common filter")
	wheel.call("set_rank_filter", 4)
	_expect_ids(wheel.call("listed_ids"), ["L1"], "legendary filter")
	wheel.call("set_rank_filter", -1)
	var fam := ItemDef.family_name(run.call("load_item", "C1"))
	wheel.call("set_family_filter", fam)
	_expect_ids(wheel.call("listed_ids"), ["C1", "U1"], "family filter %s" % fam)
	wheel.call("set_family_filter", "")
	if not bool(wheel.call("cap_is_visible")):
		_fail("cap should show after the first owned item")
	if str(wheel.call("cap_text")) != "2/7":
		_fail("cap text should be 2/7, got %s" % str(wheel.call("cap_text")))
	wheel.call("toggle_item", "C2")
	await process_frame
	if not run.state.equipped_item_ids.has("C2"):
		_fail("toggle_item did not equip C2")
	if str(wheel.call("cap_text")) != "3/7":
		_fail("cap text should be 3/7 after equipping, got %s" % str(wheel.call("cap_text")))
	wheel.call("toggle_item", "C2")
	await process_frame
	if run.state.equipped_item_ids.has("C2"):
		_fail("toggle_item did not unequip C2")
	for tab in 4:
		wheel.call("set_tab", tab)
		await process_frame
		if int(wheel.call("current_tab")) != tab:
			_fail("set_tab %d did not stick" % tab)
	wheel.call("set_tab", 0)


func _check_pay(wheel: Node, run: Node) -> void:
	run.state.owned_item_ids = PackedStringArray(["C2"])
	run.state.equipped_item_ids = PackedStringArray()
	await process_frame
	_expect_pay(wheel, "sym_satanic", [15.0, 25.0, 280.0], "wild base")
	_expect_pay(wheel, "sym_red_heart", [3.0, 5.0, 20.0], "heart base")
	run.state.equipped_item_ids = PackedStringArray(["C2"])
	await process_frame
	_expect_pay(wheel, "sym_red_heart", [3.3, 5.5, 22.0], "heart with Chalk Dust")
	_expect_pay(wheel, "sym_satanic", [15.0, 25.0, 280.0], "wild with Chalk Dust")
	wheel.call("set_tab", 2)
	await process_frame
	wheel.call("set_tab", 0)


func _check_areas(wheel: Node, world: Node) -> void:
	var rows: Array = wheel.call("area_rows")
	if rows.size() != 7:
		_fail("areas tab should list 7 areas, got %d" % rows.size())
	var has_placed := false
	for row in rows:
		if int(row["placed"]) > 0:
			has_placed = true
	if not has_placed:
		world.call("plan_floor_items", 4242)
		rows = wheel.call("area_rows")
	var room_items: Dictionary = world.get("_room_items")
	var target := ""
	for row in rows:
		if int(row["placed"]) > 0 and int(row["taken"]) == 0:
			target = String(row["id"])
			break
	if target.is_empty():
		_fail("no area with placed items to check")
		return
	var areas: Dictionary = world.get_script().get_script_constant_map()["AREAS"]
	for path in (areas[target]["rooms"] as Dictionary).keys():
		for entry in (room_items.get(path, []) as Array):
			(entry as Dictionary)["taken"] = true
	rows = wheel.call("area_rows")
	for row in rows:
		if String(row["id"]) != target:
			continue
		if int(row["taken"]) != int(row["placed"]) or not bool(row["cleared"]):
			_fail("area %s should be cleared after taking all, got %s" % [target, str(row)])
	wheel.call("set_tab", 3)
	await process_frame
	wheel.call("set_tab", 0)


func _check_anim(wheel: Node) -> void:
	wheel.call("close_wheel")
	if bool(wheel.call("is_wheel_open")):
		_fail("box stayed open after close")
	await create_timer(0.3).timeout
	if not bool(wheel.call("open_wheel")):
		_fail("box did not reopen for the open check")
		return
	await create_timer(0.4).timeout
	if not bool(wheel.call("is_wheel_open")):
		_fail("box closed during the open check")
	elif float(wheel.call("open_progress")) < 1.0:
		_fail("open animation should finish, progress %s" % str(wheel.call("open_progress")))
	wheel.call("close_wheel")


func _expect_ids(got: PackedStringArray, want: Array, label: String) -> void:
	if got != PackedStringArray(want):
		_fail("%s should be %s, got %s" % [label, str(want), str(got)])


func _expect_pay(wheel: Node, symbol_id: String, want: Array, label: String) -> void:
	var got: Array = wheel.call("pay_values", symbol_id)
	if got.size() != want.size():
		_fail("%s pay should have %d values, got %s" % [label, want.size(), str(got)])
		return
	for i in want.size():
		if absf(float(got[i]) - float(want[i])) > 0.001:
			_fail("%s pay should be %s, got %s" % [label, str(want), str(got)])
			return
