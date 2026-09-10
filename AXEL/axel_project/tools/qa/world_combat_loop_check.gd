extends SceneTree
## World combat loop regression check.
##
## Asserts:
## 1. The six areas cover the indoor rooms; 3.1 never fights.
## 2. Every area starts Common and taking an item upgrades only the untouched
##    areas (AXEL_notes §2.3).
## 3. The walk-step curve runs 0.1% -> 1% and never leaves that band.
## 4. Every area family resolves to a real item .tres at every rank.
## 5. The locker panel has no START RUN button.
## 6. The school map refuses a room the player has not walked in.
## 7. 1.1 / 1.2 walk fights stay locked until the locker tutorial is done and
##    some other room has hosted a fight.
## 8. The world goal ladder starts at 3x the chip bar and keeps climbing.
##
## Run: tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/world_combat_loop_check.gd

const LockerInteriorScript := preload("res://scenes/ui/locker_interior.gd")

## Outdoors and never in any area table: no floor items and no step fights, at
## any point in the run. 1.1 used to be on this list and is now gated instead.
const NEVER_FIGHTS := [
	"res://scenes/Arc_3/3.1_Backyard.tscn",
]

## Allowed to walk-fight, but only after the tutorial gate opens.
const GATED := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
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
	_check_walk_gate(world, run)
	_check_goal_ladder(run)

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
	for path in NEVER_FIGHTS:
		if bool(world.call("is_indoor_scene", path)):
			_fail("outdoor scene must not allow step fights: %s" % path)
		if bool(world.call("can_walk_fight", path)):
			_fail("outdoor scene must never walk-fight: %s" % path)
	# 1.1 stays out of the area table on purpose: that is what keeps floor
	# items off it while `can_walk_fight` can still open up later.
	if bool(world.call("is_indoor_scene", GATED[0])):
		_fail("1.1 must stay out of the area table so it never scatters items")
	var halls_rooms: Dictionary = areas["halls"]["rooms"]
	if int(halls_rooms.get(GATED[1], -1)) != 0:
		_fail("1.2 must be in halls with zero floor items")


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
		# With area families marked used, Common must land on C1–C10.
		var used_families: Array = []
		for family in families:
			used_families.append(String(family))
		var baseline := String(world.call("_roll_item", area_id, rng, used_families))
		if not _is_c1_to_c10(baseline):
			_fail("area %s should roll a C1–C10 when families are used, got %s" % [area_id, baseline])
		elif run.call("load_item", baseline) == null:
			_fail("area %s rolled a missing baseline id %s" % [area_id, baseline])
	_check_owned_ids_are_skipped(world, run)


func _is_c1_to_c10(item_id: String) -> bool:
	if item_id == "C10":
		return true
	if item_id.length() != 2 or item_id[0] != "C":
		return false
	var digit := item_id.substr(1)
	return digit.is_valid_int() and digit.to_int() >= 1 and digit.to_int() <= 9


func _check_owned_ids_are_skipped(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	run.state.owned_item_ids = PackedStringArray([
		"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10",
	])
	var families: Array = []
	for family in (world.AREAS as Dictionary)["cafeteria"]["families"]:
		families.append(String(family))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var blocked := String(world.call("_roll_item", "cafeteria", rng, families))
	if _is_c1_to_c10(blocked):
		_fail("owned C1–C10 must not drop when area families are used, got %s" % blocked)
	for _i in 24:
		var mixed := String(world.call("_roll_item", "cafeteria", rng, []))
		if _is_c1_to_c10(mixed):
			_fail("owned Common baseline id leaked onto the floor: %s" % mixed)
			break
		if mixed == "C1":
			_fail("owned C1 leaked onto the floor")
			break
	if String(world.call("_resolve_lane", "A", 0, [])) != "C-A":
		_fail("family A at Common should resolve to C-A")
	if not String(world.call("_resolve_lane", "A", 0, ["C-A"])).is_empty():
		_fail("placed or owned C-A must not resolve family A at Common")
	world._room_items["res://scenes/Arc_2/2.1_Cafeteria.tscn"] = [
		{"id": "C-A", "x": 0.0, "y": 0.0, "taken": false},
	]
	if String(world.call("_resolve_lane", "A", 0, world.call("_blocked_item_ids"))) == "C-A":
		_fail("an id already on a floor must not be rolled again")
	world.call("reset_world")
	run.call("reset_run")


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


## 1.1 and 1.2 are silent on a fresh save, and only the walk roll ever wakes
## them — never floor items.
func _check_walk_gate(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	for path in GATED:
		if bool(world.call("can_walk_fight", path)):
			_fail("%s must not walk-fight on a fresh save" % path)

	# Tutorial alone is not enough: another room still has to fight first.
	run.state.tutorial_fight_done = true
	for path in GATED:
		if bool(world.call("can_walk_fight", path)):
			_fail("%s must stay locked until another room has fought" % path)

	# A fight in a gated room must not unlock the gated rooms.
	world.call("_record_fight_room", GATED[1])
	for path in GATED:
		if bool(world.call("can_walk_fight", path)):
			_fail("%s unlocked itself from its own fight" % path)

	world.call("_record_fight_room", "res://scenes/Arc_1/1.4_BasementDoor.tscn")
	for path in GATED:
		if not bool(world.call("can_walk_fight", path)):
			_fail("%s should walk-fight once the gate is open" % path)

	# The gate must survive a save round trip.
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.call("to_dict")))
	var round_tripped := RunState.from_dict(parsed as Dictionary)
	if not bool(round_tripped.tutorial_fight_done):
		_fail("tutorial_fight_done lost on save round trip")
	if round_tripped.fought_rooms.size() != 1:
		_fail("fought_rooms lost on save round trip")

	world.call("reset_world")
	run.call("reset_run")


## 3x, 5x, 7.5x, 10x, 15x, 20x, 30x of the 1000-cent chip bar, then it keeps
## climbing. Fight 1 (the locker tutorial) must land on the 3x rung.
func _check_goal_ladder(run: Node) -> void:
	run.call("reset_run")
	var want := [3000, 5000, 7500, 10000, 15000, 20000, 30000]
	for i in want.size():
		run.state.world_fight_count = i + 1
		var got := int(run.call("world_goal_base_cents"))
		if got != int(want[i]):
			_fail("world fight %d should need %d cents, got %d" % [i + 1, want[i], got])
	# Past the table the curve must keep rising, never flatten or wrap.
	var previous := int(want[want.size() - 1])
	for extra in range(want.size() + 1, want.size() + 5):
		run.state.world_fight_count = extra
		var got := int(run.call("world_goal_base_cents"))
		if got <= previous:
			_fail("world fight %d goal did not grow past %d (got %d)" % [extra, previous, got])
		previous = got
	run.call("reset_run")


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
