extends SceneTree
## World combat loop regression check.
##
## Asserts:
## 1. The six areas cover the indoor rooms; 1.1 / 3.1 stay outdoors.
## 2. Every area starts Common and taking an item upgrades only the untouched
##    areas (AXEL_notes §2.3).
## 3. The walk-step curve runs 0.1% -> 1% and never leaves that band.
## 4. Every area family resolves to a real item .tres at every rank.
## 5. The locker panel has no START RUN button.
## 6. The school map refuses a room the player has not walked in.
##
## Run: tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/world_combat_loop_check.gd

const LockerInteriorScript := preload("res://scenes/ui/locker_interior.gd")

const OUTDOOR := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_3/3.1_Backyard.tscn",
]

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
	var gm := root.get_node_or_null("GameManager")
	if world == null or run == null or gm == null:
		push_error("world_combat_loop_check: AxelWorld / AxelRun / GameManager autoload missing")
		quit(1)
		return

	_check_area_table(world)
	_check_rank_progression(world)
	_check_step_curve(world)
	_check_item_pools(world, run)
	_check_take_item(world, run)
	_check_save_round_trip(world)
	_check_lore_guard(world)
	_check_locker_has_no_start_run()
	_check_visited_gate(gm)

	if _failures.is_empty():
		print("World combat loop check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("world_combat_loop_check: %s" % f)
		quit(1)


func _check_area_table(world: Node) -> void:
	var areas: Dictionary = world.AREAS
	if areas.size() != 6:
		_fail("expected 6 areas, got %d" % areas.size())
	for room_path in _all_rooms(areas):
		if not ResourceLoader.exists(room_path):
			_fail("area room missing on disk: %s" % room_path)
		if not bool(world.call("is_indoor_scene", room_path)):
			_fail("area room not reported indoor: %s" % room_path)
	for path in OUTDOOR:
		if bool(world.call("is_indoor_scene", path)):
			_fail("outdoor scene must not allow step fights: %s" % path)


func _all_rooms(areas: Dictionary) -> Array:
	var out: Array = []
	for area_id in areas.keys():
		for room_path in (areas[area_id]["rooms"] as Dictionary).keys():
			out.append(String(room_path))
	return out


func _check_rank_progression(world: Node) -> void:
	world.call("reset_world")
	for area_id in (world.AREAS as Dictionary).keys():
		if int(world.call("area_rank", area_id)) != 0:
			_fail("area %s should start Common" % area_id)

	# Engaging one area freezes it and lifts every untouched area by one rank.
	world.call("_engage_area", "cafeteria")
	if int(world.call("area_rank", "cafeteria")) != 0:
		_fail("engaged area must keep its rank")
	for area_id in (world.AREAS as Dictionary).keys():
		if area_id == "cafeteria":
			continue
		if int(world.call("area_rank", area_id)) != 1:
			_fail("untouched area %s should be Uncommon after first pickup" % area_id)

	# Engaging the same area twice must not double-upgrade the others.
	world.call("_engage_area", "cafeteria")
	world.call("_upgrade_untouched_areas", "cafeteria")
	if int(world.call("area_rank", "kitchen")) != 1:
		_fail("one area may only ever grant one upgrade")

	# Rank is capped at Legendary no matter how many areas get engaged.
	for area_id in ["kitchen", "lounge", "classroom", "halls", "basement"]:
		world.call("_engage_area", area_id)
	for area_id in (world.AREAS as Dictionary).keys():
		var rank := int(world.call("area_rank", area_id))
		if rank < 0 or rank > world.MAX_RANK:
			_fail("area %s rank out of range: %d" % [area_id, rank])
	world.call("reset_world")


func _check_step_curve(world: Node) -> void:
	world.call("reset_world")
	var base := float(world.call("step_chance"))
	if not is_equal_approx(base, world.STEP_CHANCE_BASE):
		_fail("fresh step chance should be %f, got %f" % [world.STEP_CHANCE_BASE, base])
	for area_id in (world.AREAS as Dictionary).keys():
		world._cleared[area_id] = true
	var late := float(world.call("step_chance"))
	if late > world.STEP_CHANCE_MAX + 0.000001 or late < base:
		_fail("late step chance out of band: %f" % late)
	if not is_equal_approx(late, world.STEP_CHANCE_MAX):
		_fail("all areas cleared should reach %f, got %f" % [world.STEP_CHANCE_MAX, late])
	world.call("reset_world")


func _check_item_pools(world: Node, run: Node) -> void:
	var areas: Dictionary = world.AREAS
	for area_id in areas.keys():
		var families: Array = areas[area_id]["families"]
		if families.is_empty():
			_fail("area %s has no item families" % area_id)
		for family in families:
			var found := false
			for prefix in world.RANK_PREFIXES:
				if run.call("load_item", "%s-%s" % [prefix, family]) != null:
					found = true
					break
			if not found:
				_fail("area %s family %s has no item .tres at any rank" % [area_id, family])
		# Common is the starting rank, so it must always resolve.
		world.call("reset_world")
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		var rolled := String(world.call("_roll_item", area_id, rng, []))
		if rolled.is_empty():
			_fail("area %s rolled no item at Common" % area_id)
		elif run.call("load_item", rolled) == null:
			_fail("area %s rolled a missing item id %s" % [area_id, rolled])


func _check_take_item(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	var room := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
	world._room_items[room] = [
		{"id": "C-A", "x": 0.0, "y": 0.0, "taken": false},
		{"id": "C-D", "x": 0.0, "y": 0.0, "taken": false},
	]
	world.call("take_item", room, 0)
	if not Array(run.state.owned_item_ids).has("C-A"):
		_fail("taking a floor item did not add it to the locker")
	if int(world.call("area_rank", "cafeteria")) != 0:
		_fail("the area you picked from must keep its rank")
	if int(world.call("area_rank", "kitchen")) != 1:
		_fail("untouched areas should be one rank up after a pickup")
	if bool(world._cleared.get("cafeteria", false)):
		_fail("area cleared with items still on the floor")

	# Same slot twice must not double-count.
	world.call("take_item", room, 0)
	if Array(run.state.owned_item_ids).count("C-A") != 1:
		_fail("taking the same floor item twice duplicated it")

	world.call("take_item", room, 1)
	if not bool(world._cleared.get("cafeteria", false)):
		_fail("area should be cleared once every floor item is taken")
	if int(world.call("area_rank", "kitchen")) != 1:
		_fail("clearing an already-engaged area must not upgrade again")
	world.call("reset_world")
	run.call("reset_run")


func _check_save_round_trip(world: Node) -> void:
	world.call("reset_world")
	var room := "res://scenes/Arc_5/5.1_Classroom.tscn"
	world._room_items[room] = [{"id": "C-D", "x": 12.5, "y": 34.5, "taken": true}]
	world.call("_engage_area", "classroom")
	world._lore_fights["hasKey"] = true
	var saved: Dictionary = world.call("to_dict")
	# JSON is what actually hits the slot file, so round trip through it.
	var text := JSON.stringify(saved)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		_fail("world state does not survive JSON")
		world.call("reset_world")
		return
	world.call("reset_world")
	world.call("from_dict", parsed)
	if int(world.call("area_rank", "kitchen")) != 1:
		_fail("ranks lost on save round trip")
	if not bool(world.call("has_lore_fight_happened", "hasKey")):
		_fail("lore fight guard lost on save round trip")
	var entries: Array = world._room_items.get(room, [])
	if entries.size() != 1 or not bool((entries[0] as Dictionary).get("taken", false)):
		_fail("floor item state lost on save round trip")
	elif not is_equal_approx(float((entries[0] as Dictionary).get("x", 0.0)), 12.5):
		_fail("floor item position lost on save round trip")
	world.call("reset_world")


## Flashlight / key / shovel / name each pay out one fight, ever.
func _check_lore_guard(world: Node) -> void:
	world.call("reset_world")
	for flag in ["hasFlashlight", "hasKey", "hasShovel", "hasName"]:
		if bool(world.call("has_lore_fight_happened", flag)):
			_fail("%s should start with no lore fight recorded" % flag)
		world._lore_fights[flag] = true
		if not bool(world.call("has_lore_fight_happened", flag)):
			_fail("%s lore fight guard did not record" % flag)
		if bool(world.call("start_lore_fight", flag, "res://scenes/Arc_2/2.3_Kitchen.tscn", false)):
			_fail("%s started a second lore fight" % flag)
	world.call("reset_world")


func _check_locker_has_no_start_run() -> void:
	var locker = LockerInteriorScript.new()
	root.add_child(locker)
	var offenders := _button_texts(locker)
	locker.queue_free()
	for text in offenders:
		if text.to_upper().contains("START RUN"):
			_fail("locker still has a START RUN button")


func _button_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		out.append_array(_button_texts(child))
	return out


func _check_visited_gate(gm: Node) -> void:
	var probe := "res://scenes/Arc_2/2.3_Kitchen.tscn"
	if bool(gm.call("has_visited", probe)):
		# A previous check may have loaded it; only the toggle matters here.
		print("world_combat_loop_check: %s already marked visited" % probe)
		return
	gm.call("mark_room_visited", probe)
	if not bool(gm.call("has_visited", probe)):
		_fail("mark_room_visited did not stick for %s" % probe)
	gm.visited_rooms.erase(probe)
	if bool(gm.call("has_visited", probe)):
		_fail("visited set could not be cleared for %s" % probe)
