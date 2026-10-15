extends SceneTree

const CAFETERIA := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const HUB := "res://scenes/Arc_1/1.3_LockerHub.tscn"

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
		push_error("ticket_machine_check: autoloads missing")
		quit(1)
		return
	_check_prices(run)
	var first := _reroll_once(world, run)
	var second := _reroll_once(world, run)
	if first.is_empty():
		_fail("reroll did not change the item")
	elif first != second:
		_fail("same seed and state gave different rerolls: %s vs %s" % [first, second])
	_check_reroll_survives_rankup(world, run)
	await _check_hub(run)
	world.call("reset_world")
	run.call("reset_run")
	if _failures.is_empty():
		print("ticket_machine_check: OK")
		quit(0)
		return
	for msg in _failures:
		push_error("ticket_machine_check: " + msg)
	quit(1)


func _check_prices(run: Node) -> void:
	run.call("reset_run")
	run.state.bankroll_cents = 100000
	var want: Array[int] = [300, 450, 675, 1015]
	for price in want:
		if int(run.call("ticket_price")) != price:
			_fail("ticket price %d, want %d" % [int(run.call("ticket_price")), price])
		if not bool(run.call("buy_ticket")):
			_fail("could not buy a ticket at %d" % price)
	if int(run.call("ticket_count")) != want.size():
		_fail("ticket count %d, want %d" % [int(run.call("ticket_count")), want.size()])
	run.state.bankroll_cents = int(run.call("ticket_price")) + 99
	if bool(run.call("buy_ticket")):
		_fail("bought a ticket that left less than the lowest bet")
	run.call("reset_run")


func _reroll_once(world: Node, run: Node) -> String:
	world.call("reset_world")
	run.call("reset_run")
	run.state.seed = 4242
	world.call("plan_floor_items", 4242)
	var entries: Array = world.call("room_item_entries", CAFETERIA)
	if entries.is_empty():
		_fail("cafeteria has no floor items")
		return ""
	var before := String((entries[0] as Dictionary).get("id", ""))
	if bool(world.call("reroll_item", CAFETERIA, 0)):
		_fail("rerolled without a ticket")
	run.state.tickets = 1
	if not bool(world.call("reroll_item", CAFETERIA, 0)):
		_fail("reroll with a ticket failed")
		return ""
	var after := String((world.call("room_item_entries", CAFETERIA)[0] as Dictionary).get("id", ""))
	if after == before:
		return ""
	if int(world.call("item_rank_of_id", after)) != int(world.call("item_rank_of_id", before)):
		_fail("reroll changed rarity: %s -> %s" % [before, after])
	if int(run.call("ticket_count")) != 0 or int(run.state.tickets_used) != 1:
		_fail("reroll did not spend exactly one ticket")
	return after


func _check_reroll_survives_rankup(world: Node, run: Node) -> void:
	var after := _reroll_once(world, run)
	if after.is_empty():
		return
	var cafe_area := String(world.call("area_for_scene", CAFETERIA))
	var rank_before := int(world.call("area_rank", cafe_area))
	var other_path := ""
	for path in (world.get("_room_items") as Dictionary).keys():
		if String(world.call("area_for_scene", String(path))) == cafe_area:
			continue
		if not (world.call("room_item_entries", String(path)) as Array).is_empty():
			other_path = String(path)
			break
	if other_path.is_empty():
		_fail("no floor item outside the cafeteria area")
		return
	world.call("take_item", other_path, 0)
	if int(world.call("area_rank", cafe_area)) <= rank_before:
		_fail("taking an item elsewhere did not rank up the cafeteria area")
	var kept := String((world.call("room_item_entries", CAFETERIA)[0] as Dictionary).get("id", ""))
	if kept != after:
		_fail("area rank-up replaced the rerolled item: %s -> %s" % [after, kept])
	var saved: Dictionary = world.call("to_dict")
	world.call("from_dict", saved)
	var loaded := String((world.call("room_item_entries", CAFETERIA)[0] as Dictionary).get("id", ""))
	if loaded != after:
		_fail("save/load replaced the rerolled item: %s -> %s" % [after, loaded])
	var ids: Array = []
	for path in (world.get("_room_items") as Dictionary).keys():
		for entry in (world.call("room_item_entries", String(path)) as Array):
			var item_id := String((entry as Dictionary).get("id", ""))
			if ids.has(item_id):
				_fail("floor item %s appears twice after rank-up" % item_id)
			ids.append(item_id)


func _check_hub(run: Node) -> void:
	run.call("reset_run")
	var packed := load(HUB) as PackedScene
	if packed == null:
		_fail("hub scene missing")
		return
	var hub := packed.instantiate()
	root.add_child(hub)
	for _i in 3:
		await process_frame
	var machine := hub.find_child("TicketMachine", true, false) as Control
	if machine == null:
		_fail("hub has no ticket machine")
	else:
		var buy := machine.find_child("BuyButton", true, false) as Button
		if buy == null or not buy.text.contains("300"):
			_fail("buy button does not show the first price")
		var rect := machine.get_global_rect()
		if rect.position.x < 0.0 or rect.end.y > 1280.0 + 1.0:
			_fail("ticket machine is off screen: %s" % rect)
	hub.queue_free()
	await process_frame
