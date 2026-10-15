extends SceneTree

const OverlayScript := preload("res://scenes/ui/locker_map_overlay.gd")
const KITCHEN := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const CAFETERIA := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const CLASSROOM := "res://scenes/Arc_5/5.1_Classroom.tscn"
const CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"

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
		push_error("routing_check: autoloads missing")
		quit(1)
		return
	_check_depths(world)
	_check_rarity_rolls(world, run)
	_check_travel(run)
	_check_goal_mult(world, run)
	await _check_glimmers(world, run, gm)
	world.call("reset_world")
	run.call("reset_run")
	if _failures.is_empty():
		print("routing_check: OK")
		quit(0)
		return
	for msg in _failures:
		push_error("routing_check: " + msg)
	quit(1)


func _check_depths(world: Node) -> void:
	var want := {"halls": 0, "basement": 0, "cafeteria": 1, "kitchen": 1, "backyard": 2, "lounge": 3, "classroom": 3}
	for area_id in want.keys():
		if int(world.call("area_depth", area_id)) != int(want[area_id]):
			_fail("area %s depth %d, want %d" % [area_id, int(world.call("area_depth", area_id)), int(want[area_id])])


func _check_rarity_rolls(world: Node, run: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	var shallow := 0
	var deep := 0
	var tries := 400
	for i in tries:
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + i
		shallow += int(world.call("_roll_rarity", "halls", rng))
		rng.seed = 900 + i
		deep += int(world.call("_roll_rarity", "classroom", rng))
		rng.seed = 900 + i
		var again_rng := RandomNumberGenerator.new()
		again_rng.seed = 900 + i
		if int(world.call("_roll_rarity", "lounge", rng)) != int(world.call("_roll_rarity", "lounge", again_rng)):
			_fail("rarity roll is not the same for the same seed")
			break
	if deep <= shallow * 2:
		_fail("deep areas should roll much rarer items (halls %d vs classroom %d)" % [shallow, deep])
	world._rank["halls"] = 1
	var shifted: Array = world.call("rarity_weights", "halls")
	if int(shifted[0]) != 0:
		_fail("a rank-up should shift Common weight up one tier")
	world.call("reset_world")


func _check_travel(run: Node) -> void:
	run.call("reset_run")
	run.state.bankroll_cents = 3000
	if int(run.call("travel_price")) != 300:
		_fail("travel at 3000 should cost 300, got %d" % int(run.call("travel_price")))
	run.state.bankroll_cents = 200
	if int(run.call("travel_price")) != 50:
		_fail("travel should never cost under 50")
	if not bool(run.call("pay_travel")):
		_fail("200 balance should afford a 50 trip")
	if int(run.state.bankroll_cents) != 150 or int(run.state.travel_uses) != 1:
		_fail("travel did not charge 50 once")
	if not bool(run.call("pay_travel")):
		_fail("travel leaving exactly 100 should be allowed")
	if bool(run.call("pay_travel")):
		_fail("travel must not leave less than 100")
	run.call("reset_run")


func _check_goal_mult(world: Node, run: Node) -> void:
	run.call("reset_run")
	run.state.world_encounter = true
	run.state.world_reason = "walk"
	run.state.world_fight_count = 5
	var base := int(run.call("world_goal_base_cents"))
	run.state.world_return_scene = CORRIDOR
	if int(run.call("world_goal_cents_for_fight")) != base:
		_fail("a depth 0 room should keep the base goal")
	run.state.world_return_scene = CLASSROOM
	var deep := int(run.call("world_goal_cents_for_fight"))
	var want := int(ceil(float(base) * 1.8 / 5.0)) * 5
	if deep != want:
		_fail("a depth 3 room goal should be %d, got %d" % [want, deep])
	run.call("reset_run")


func _check_glimmers(world: Node, run: Node, gm: Node) -> void:
	world.call("reset_world")
	run.call("reset_run")
	world.call("plan_floor_items", 4242)
	gm.call("set_flag", "hasFlashlight", false)
	if not bool(world.call("room_glimmers", KITCHEN)):
		_fail("kitchen should glimmer while the flashlight is still there")
	gm.call("set_flag", "hasFlashlight", true)
	var kitchen_items: Array = world.call("room_item_entries", KITCHEN)
	for entry in kitchen_items:
		(entry as Dictionary)["id"] = "C-B"
	if bool(world.call("room_glimmers", KITCHEN)):
		_fail("kitchen should not glimmer once the flashlight is taken and no Legendary is left")
	(kitchen_items[0] as Dictionary)["id"] = "L-E"
	if not bool(world.call("room_glimmers", KITCHEN)):
		_fail("a Legendary floor item should make its room glimmer")
	var pause_map := OverlayScript.new()
	root.add_child(pause_map)
	pause_map.call("open")
	await process_frame
	if not (pause_map.call("glimmer_area_names") as Array).is_empty():
		_fail("the pause map must never show glimmers")
	pause_map.queue_free()
	var locker_map := OverlayScript.new()
	locker_map.set("show_glimmers", true)
	root.add_child(locker_map)
	locker_map.call("open")
	await process_frame
	if not (locker_map.call("glimmer_area_names") as Array).has("Kitchen"):
		_fail("the locker map should glimmer on the kitchen")
	locker_map.queue_free()
	gm.call("set_flag", "hasFlashlight", false)
	await process_frame
