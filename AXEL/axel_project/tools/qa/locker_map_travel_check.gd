extends SceneTree

const OverlayScript := preload("res://scenes/ui/locker_map_overlay.gd")

const ENTRANCE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"
const CAFETERIA := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const HALLWAY := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const BACKYARD := "res://scenes/Arc_3/3.1_Backyard.tscn"
const PLATE := "res://exports/Drawings/2.1_Cafeteria.png"

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
	var gm := root.get_node_or_null("GameManager")
	if world == null or run == null or gm == null:
		push_error("locker_map_travel_check: autoloads missing")
		quit(1)
		return

	_check_unlock(world, run, gm)
	_check_fill_keeps_existing(world, run)
	await _check_pins_and_cards(world, run)

	if _failures.is_empty():
		print("Locker map travel check OK.")
		quit(0)
	else:
		for msg in _failures:
			push_error("locker_map_travel_check: %s" % msg)
		quit(1)


func _check_unlock(world: Node, run: Node, gm: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	gm.visited_rooms.clear()
	if bool(world.call("can_walk_fight", BACKYARD)):
		_fail("backyard must not walk-fight")
	if int(world.call("floor_slot_count", BACKYARD)) != 2:
		_fail("backyard should have 2 floor slots")
	if bool(world.call("map_can_travel", ENTRANCE)):
		_fail("entrance traveled before a visit")
	gm.visited_rooms[ENTRANCE] = true
	if not bool(world.call("map_can_travel", ENTRANCE)):
		_fail("entrance should travel after a visit")
	gm.visited_rooms[CORRIDOR] = true
	if bool(world.call("map_can_travel", HALLWAY)):
		_fail("hallway unlocked from the 1.2 visit")
	gm.visited_rooms[HALLWAY] = true
	world._room_items[HALLWAY] = [{"id": "C-F", "x": 40.0, "y": 40.0, "taken": false}]
	if bool(world.call("map_can_travel", HALLWAY)):
		_fail("hallway traveled before a pickup")
	(world._room_items[HALLWAY] as Array)[0]["taken"] = true
	if not bool(world.call("map_can_travel", HALLWAY)):
		_fail("hallway should travel after one pickup")
	gm.visited_rooms[CAFETERIA] = true
	world._room_items[CAFETERIA] = [
		{"id": "C-A", "x": 80.0, "y": 80.0, "taken": false},
		{"id": "C-D", "x": 200.0, "y": 200.0, "taken": false},
	]
	if bool(world.call("map_can_travel", CAFETERIA)):
		_fail("cafeteria traveled before a pickup")
	(world._room_items[CAFETERIA] as Array)[0]["taken"] = true
	if not bool(world.call("map_can_travel", CAFETERIA)):
		_fail("cafeteria should travel after one pickup")
	var shown: Array = world.call("placed_floor_items", CAFETERIA)
	if shown.size() != 1 or String((shown[0] as Dictionary).get("id", "")) != "C-D":
		_fail("picked-up cafeteria item should leave the map list")
	world.call("reset_world")
	run.call("reset_run")
	gm.visited_rooms.clear()


func _check_fill_keeps_existing(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	world.call("plan_floor_items", 77)
	var before: Array = (world._room_items.get(CAFETERIA, []) as Array).duplicate(true)
	if before.is_empty():
		_fail("cafeteria had no planned items")
		return
	var saved: Dictionary = world.call("to_dict")
	(saved.get("room_items", {}) as Dictionary).erase(BACKYARD)
	world.call("reset_world")
	world.call("from_dict", saved)
	var after: Array = world._room_items.get(CAFETERIA, [])
	if after.size() != before.size():
		_fail("filling backyard rerolled cafeteria")
	else:
		for i in before.size():
			var old: Dictionary = before[i]
			var neu: Dictionary = after[i]
			if String(old.get("id", "")) != String(neu.get("id", "")):
				_fail("filling backyard changed cafeteria id %s" % String(old.get("id", "")))
				break
			if not is_equal_approx(float(old.get("x", 0.0)), float(neu.get("x", 0.0))):
				_fail("filling backyard moved a cafeteria item")
				break
	var yard: Array = world._room_items.get(BACKYARD, [])
	if yard.size() != 2:
		_fail("old save did not gain 2 backyard items, got %d" % yard.size())
	world.call("reset_world")
	run.call("reset_run")


func _check_pins_and_cards(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	world.call("plan_floor_items", 4242)
	var plate_tex := load(PLATE) as Texture2D
	if plate_tex == null:
		_fail("cafeteria plate missing")
		return
	var plate := plate_tex.get_size()
	var entries: Array = world._room_items.get(CAFETERIA, [])
	if entries.is_empty():
		_fail("cafeteria items missing for the pin check")
		return
	for entry in entries:
		(entry as Dictionary)["x"] = plate.x * 0.5
		(entry as Dictionary)["y"] = plate.y * 0.5
	var overlay := OverlayScript.new()
	root.add_child(overlay)
	if overlay.has_method("open"):
		overlay.call("open")
	for _i in 3:
		await process_frame
	var index := _area_index(overlay, "Cafeteria")
	var hallway := _area_index(overlay, "Hallway")
	if index < 0 or hallway < 0:
		_fail("map areas missing")
		overlay.queue_free()
		return
	var measure: Rect2 = overlay.call("_measure_rect", index)
	var center := OverlayScript.pin_tex_point(plate * 0.5, plate, measure)
	if center.distance_to(measure.get_center()) > 0.01:
		_fail("center of the drawing did not land on the center of the highlight")
	var hall_measure: Rect2 = overlay.call("_measure_rect", hallway)
	var hall_expect := Rect2(856, 881, 708, 566)
	if hall_measure.position.distance_to(hall_expect.position) > 0.01 or hall_measure.size.distance_to(hall_expect.size) > 0.01:
		_fail("hallway measure is not the box around both pieces: %s" % hall_measure)
	overlay.call("_on_part_enter", index, 0)
	for _i in 3:
		await process_frame
	var screen: Vector2 = overlay.call("_screen_point", center)
	var pin := overlay.find_child("ItemPin", true, false) as Control
	if pin == null:
		_fail("map did not place an item hand")
	else:
		var pin_center: Vector2 = pin.position + pin.size * 0.5
		if pin_center.distance_to(screen) > 1.5:
			_fail("hand pin missed the highlight center (pin %s, want %s)" % [pin_center, screen])
	_check_card_text(overlay)
	overlay.queue_free()
	world.call("reset_world")
	run.call("reset_run")


func _check_card_text(overlay: Node) -> void:
	var name_label := overlay.find_child("ItemName", true, false) as Label
	var desc_label := overlay.find_child("ItemDescription", true, false) as Label
	var card := overlay.find_child("ItemCard", true, false) as Control
	if name_label == null or desc_label == null or card == null:
		_fail("hover did not show an item card")
		return
	if name_label.text.is_empty() or desc_label.text.is_empty():
		_fail("item card is missing a name or description")
	if name_label.get_visible_line_count() < 1 or desc_label.get_visible_line_count() < 1:
		_fail("item card text did not wrap into a visible line")
	if name_label.get_character_bounds(0).size == Vector2.ZERO:
		_fail("item name has no drawn characters")
	if desc_label.get_character_bounds(0).size == Vector2.ZERO:
		_fail("item description has no drawn characters")
	var host := card.get_global_rect()
	if not host.encloses(name_label.get_global_rect()):
		_fail("item name sits outside its card")
	if not host.encloses(desc_label.get_global_rect()):
		_fail("item description sits outside its card")


func _area_index(_overlay: Node, area_name: String) -> int:
	var areas: Array = OverlayScript.AREAS
	for i in areas.size():
		if String((areas[i] as Dictionary).get("name", "")) == area_name:
			return i
	return -1
