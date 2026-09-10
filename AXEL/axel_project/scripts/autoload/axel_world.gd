extends Node
## School side of the fight loop: which rooms belong to which area, what rank
## their floor items roll at, when a walk step turns into a fight, and which
## rooms the map is allowed to travel to.
##
## Layer rule (AI_DOCS): this is narrative state. Combat never reads it, and
## AxelRun stays the only thing that actually starts an encounter.

const PickupScript := preload("res://scenes/world/world_item_pickup.gd")
const InfoCardScript := preload("res://scenes/ui/world_item_info_card.gd")
const ItemLinesScript := preload("res://combat/scripts/item_lines.gd")
const PROMPT_SCENE := "res://scenes/ui/InteractPromptOverlay.tscn"
const PROMPT_NODE_NAME := "WorldItemPromptOverlay"
const INFO_CARD_NODE_NAME := "WorldItemInfoCard"
const PICKUP_HOST_NAME := "WorldItemScatter"

## Common -> Legendary. Item ids are `TIER-FAMILY` (`C-G`) or baseline lines (`C1`).
const RANK_PREFIXES: PackedStringArray = ["C", "U", "R", "E", "L"]
const RANK_NAMES: PackedStringArray = [
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
]
const MAX_RANK := 4

## Walk-fight tuning. Step = 8 px (Player._STEP_DISTANCE_PX).
const STEP_CHANCE_BASE := 0.001
const STEP_CHANCE_PER_CLEARED_AREA := 0.0015
const STEP_CHANCE_MAX := 0.01
## No step fight for this many steps after any fight.
const STEP_GRACE_AFTER_FIGHT := 200
## Farm cap: at most this many step fights per room visit.
const MAX_STEP_FIGHTS_PER_VISIT := 2

## Six written areas mapped onto the live rooms. `items` is how many floor
## pickups that room gets; outdoor rooms are simply absent from this table.
const AREAS := {
	"halls": {
		"label": "HALLS",
		"families": ["F", "H", "M"],
		"rooms": {
			# The corridor is a gated walk-fight room and gets no floor items,
			# so `halls` is cleared by 2.4's single item.
			"res://scenes/Arc_1/1.2_Corridor.tscn": 0,
			"res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn": 1,
		},
	},
	"cafeteria": {
		"label": "CAFETERIA",
		"families": ["A", "D", "M"],
		"rooms": {
			"res://scenes/Arc_2/2.1_Cafeteria.tscn": 3,
		},
	},
	"kitchen": {
		"label": "KITCHEN",
		"families": ["B", "E", "H"],
		"rooms": {
			"res://scenes/Arc_2/2.3_Kitchen.tscn": 2,
		},
	},
	"lounge": {
		"label": "TEACHERS LOUNGE",
		"families": ["C", "H", "M"],
		"rooms": {
			"res://scenes/Arc_4/4.1_TeachersLounge.tscn": 2,
		},
	},
	"classroom": {
		"label": "CLASSROOM",
		"families": ["D", "E", "A"],
		"rooms": {
			"res://scenes/Arc_5/5.1_Classroom.tscn": 2,
		},
	},
	"basement": {
		"label": "BASEMENT",
		"families": ["G", "B", "F"],
		"rooms": {
			"res://scenes/Arc_1/1.4_BasementDoor.tscn": 1,
		},
	},
}

## Reasons passed to AxelRun.enter_world_encounter (debug / future ambush split).
const REASON_WALK := "walk"
const REASON_ITEM := "item_pickup"
const REASON_LORE := "lore_pickup"
const REASON_MEMORY := "memory"
## The tutorial needs its own reason so AxelRun can hand combat a low goal, an
## empty loadout, and the last-spin assist without combat reading a story flag.
const REASON_LOCKER_TUTORIAL := "locker_tutorial"

## Where the locker tutorial fight happens: you open the locker, look around,
## then leave the hub yourself and the corridor takes you.
const TUTORIAL_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"

## 1.1 and 1.2 get no floor items, ever, and stay completely quiet until the
## locker tutorial is done AND some other room has hosted a fight. After that
## they only ever fight from the random walk roll. 3.1 is in neither table, so
## it never fights at all.
const GATED_WALK_SCENES: PackedStringArray = [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
]

var _rank: Dictionary = {}
var _engaged: Dictionary = {}
var _cleared: Dictionary = {}
## Each area lifts the untouched areas once, whichever comes first: the first
## pickup there or clearing it. Keeps the curve at +1 per area touched.
var _upgrade_spent: Dictionary = {}
## scene_path -> Array of {"id": String, "x": float, "y": float, "taken": bool}
var _room_items: Dictionary = {}
## Lore flags that already paid out their one guaranteed fight.
var _lore_fights: Dictionary = {}

var _steps_since_fight: int = STEP_GRACE_AFTER_FIGHT
var _step_fights_this_visit: int = 0
var _rng := RandomNumberGenerator.new()
var _pending_return_scene: String = ""
var _pending_return_tex := Vector2.ZERO
var _pending_return_valid := false
var _starting_fight := false


func _ready() -> void:
	_rng.randomize()
	reset_world()
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)


## --- Enable / reset ---


func is_enabled() -> bool:
	if OS.has_environment("AXEL_WORLD_COMBAT"):
		return OS.get_environment("AXEL_WORLD_COMBAT") != "0"
	return true


func reset_world() -> void:
	_rank.clear()
	_engaged.clear()
	_cleared.clear()
	_upgrade_spent.clear()
	_room_items.clear()
	_lore_fights.clear()
	for area_id in AREAS.keys():
		_rank[area_id] = 0
		_engaged[area_id] = false
		_cleared[area_id] = false
		_upgrade_spent[area_id] = false
	_steps_since_fight = STEP_GRACE_AFTER_FIGHT
	_step_fights_this_visit = 0
	_pending_return_scene = ""
	_pending_return_valid = false
	_starting_fight = false


## --- Area lookup ---


func area_for_scene(scene_path: String) -> String:
	if scene_path.is_empty():
		return ""
	for area_id in AREAS.keys():
		if (AREAS[area_id]["rooms"] as Dictionary).has(scene_path):
			return String(area_id)
	return ""


func is_indoor_scene(scene_path: String) -> bool:
	return not area_for_scene(scene_path).is_empty()


## Whether the walk-step roll is allowed to fire in this room at all. Indoor
## rooms qualify by being in the area table; 1.1 and 1.2 have to earn it.
func can_walk_fight(scene_path: String) -> bool:
	if GATED_WALK_SCENES.has(scene_path):
		return walk_fights_unlocked()
	return is_indoor_scene(scene_path)


## The 1.1 / 1.2 gate: the locker tutorial has happened and at least one other
## room has already hosted a fight.
func walk_fights_unlocked() -> bool:
	var run := _run()
	if run == null:
		return false
	if not bool(run.state.tutorial_fight_done):
		return false
	return run.state.fought_rooms.size() > 0


func area_rank(area_id: String) -> int:
	return int(_rank.get(area_id, 0))


func area_rank_name(area_id: String) -> String:
	return String(RANK_NAMES[clampi(area_rank(area_id), 0, MAX_RANK)])


func cleared_area_count() -> int:
	var n := 0
	for area_id in AREAS.keys():
		if bool(_cleared.get(area_id, false)):
			n += 1
	return n


func step_chance() -> float:
	var chance := STEP_CHANCE_BASE + STEP_CHANCE_PER_CLEARED_AREA * float(cleared_area_count())
	return clampf(chance, STEP_CHANCE_BASE, STEP_CHANCE_MAX)


## --- Walk fights ---


## Called by Player.gd once per 8 px walked. Rolls a rare fight in any room
## that `can_walk_fight` allows.
func register_walk_step() -> void:
	if not is_enabled() or _starting_fight:
		return
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return
	var scene := _current_scene()
	if scene == null:
		return
	var path := scene.scene_file_path
	if not can_walk_fight(path):
		return
	_steps_since_fight += 1
	if _steps_since_fight < STEP_GRACE_AFTER_FIGHT:
		return
	if _step_fights_this_visit >= MAX_STEP_FIGHTS_PER_VISIT:
		return
	if _rng.randf() >= step_chance():
		return
	_step_fights_this_visit += 1
	start_fight_here(REASON_WALK)


## --- Fight entry points ---


## Fight from inside a walkable room; returns to this room and this spot.
func start_fight_here(reason: String) -> bool:
	if not is_enabled() or _starting_fight:
		return false
	var scene := _current_scene()
	if scene == null:
		return false
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return false
	_starting_fight = true
	_steps_since_fight = 0
	var tex := Vector2.ZERO
	var has_tex := false
	var env := _env_of(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	if env != null and player != null:
		tex = PlayerSpawnSync.capture_tex(env, player)
		has_tex = true
	if player != null and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)
	_record_fight_room(scene.scene_file_path)
	AxelRun.enter_world_encounter(reason, scene.scene_file_path, tex, has_tex)
	return true


## Fight from a still / greybox screen: no player spot, the room places itself.
func start_fight_to_scene(reason: String, return_scene: String) -> bool:
	if not is_enabled() or _starting_fight:
		return false
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return false
	_starting_fight = true
	_steps_since_fight = 0
	_record_fight_room(return_scene)
	AxelRun.enter_world_encounter(reason, return_scene, Vector2.ZERO, false)
	return true


## Memory stills (2.2 / 3.2 / 4.2 / 5.2) leave through here instead of a plain
## scene change. Falls back to a plain change when the loop is disabled.
func start_memory_fight(return_scene: String) -> bool:
	if not is_enabled():
		return false
	return start_fight_to_scene(REASON_MEMORY, return_scene)


## Flashlight / key / shovel / name. Once per flag, ever.
func start_lore_fight(flag_name: String, return_scene: String, use_player_spot: bool) -> bool:
	if not is_enabled():
		return false
	if bool(_lore_fights.get(flag_name, false)):
		return false
	var started := false
	if use_player_spot:
		started = start_fight_here(REASON_LORE)
	if not started:
		started = start_fight_to_scene(REASON_LORE, return_scene)
	if not started:
		return false
	_lore_fights[flag_name] = true
	_save()
	return true


func has_lore_fight_happened(flag_name: String) -> bool:
	return bool(_lore_fights.get(flag_name, false))


## The locker hub asks for the tutorial when the player leaves it on their own
## after opening the locker. AxelWorld still owns *when* it happens: nothing
## fires until the corridor is actually loaded and the player is standing.
func queue_locker_tutorial_fight() -> bool:
	if not is_enabled():
		return false
	var run := _run()
	if run == null:
		return false
	if not bool(run.state.locker_stash_granted):
		return false
	if bool(run.state.tutorial_fight_done) or bool(run.state.tutorial_fight_pending):
		return false
	run.state.tutorial_fight_pending = true
	_save()
	return true


func is_locker_tutorial_pending() -> bool:
	var run := _run()
	return run != null and bool(run.state.tutorial_fight_pending)


func _start_locker_tutorial(scene: Node) -> void:
	await _settle_frames(scene, 12)
	if scene != _current_scene():
		return
	var run := _run()
	if run == null or bool(run.call("is_in_encounter")):
		return
	if not bool(run.state.tutorial_fight_pending):
		return
	run.state.tutorial_fight_pending = false
	run.state.tutorial_fight_done = true
	if not start_fight_here(REASON_LOCKER_TUTORIAL):
		# Nothing to fight from (loop off, no Player node): stay owed instead of
		# quietly eating the tutorial.
		run.state.tutorial_fight_pending = true
		run.state.tutorial_fight_done = false
		return
	_save()


## Gate bookkeeping for 1.1 / 1.2: which rooms have already hosted a fight. The
## two gated rooms never count toward their own unlock.
func _record_fight_room(scene_path: String) -> void:
	if scene_path.is_empty() or GATED_WALK_SCENES.has(scene_path):
		return
	var run := _run()
	if run == null:
		return
	var rooms: Array = Array(run.state.fought_rooms)
	if rooms.has(scene_path):
		return
	rooms.append(scene_path)
	run.state.fought_rooms = PackedStringArray(rooms)


## Called by AxelRun after a world fight is won.
func notify_fight_won(_reason: String, dest_scene: String, tex: Vector2, has_tex: bool) -> void:
	_starting_fight = false
	_steps_since_fight = 0
	_pending_return_scene = dest_scene
	_pending_return_tex = tex
	_pending_return_valid = has_tex


## --- Floor items ---


func item_rank_for_scene(scene_path: String) -> int:
	return area_rank(area_for_scene(scene_path))


## A floor pickup was taken: bank it, engage the area, upgrade untouched areas.
func take_item(scene_path: String, index: int) -> void:
	var entries: Array = _room_items.get(scene_path, [])
	if index < 0 or index >= entries.size():
		return
	var entry: Dictionary = entries[index]
	if bool(entry.get("taken", false)):
		return
	entry["taken"] = true
	var run := _run()
	if run != null:
		var owned: Array = Array(run.state.owned_item_ids)
		var item_id := String(entry.get("id", ""))
		if not item_id.is_empty() and not owned.has(item_id):
			owned.append(item_id)
			run.state.owned_item_ids = PackedStringArray(owned)
	var area_id := area_for_scene(scene_path)
	_engage_area(area_id)
	_refresh_cleared(area_id)
	_save()


func _engage_area(area_id: String) -> void:
	if area_id.is_empty() or bool(_engaged.get(area_id, false)):
		return
	_engaged[area_id] = true
	_upgrade_untouched_areas(area_id)


## AXEL_notes §2.3: areas you have not entered or cleared move up one rank.
## An area is only ever the source of one upgrade.
func _upgrade_untouched_areas(source_area: String) -> void:
	if source_area.is_empty() or bool(_upgrade_spent.get(source_area, false)):
		return
	_upgrade_spent[source_area] = true
	for area_id in AREAS.keys():
		if area_id == source_area:
			continue
		if bool(_engaged.get(area_id, false)) or bool(_cleared.get(area_id, false)):
			continue
		_rank[area_id] = mini(int(_rank.get(area_id, 0)) + 1, MAX_RANK)


func _refresh_cleared(area_id: String) -> void:
	if area_id.is_empty() or bool(_cleared.get(area_id, false)):
		return
	var rooms: Dictionary = AREAS[area_id]["rooms"]
	for room_path in rooms.keys():
		var entries: Array = _room_items.get(room_path, [])
		if entries.is_empty():
			return
		for entry in entries:
			if not bool((entry as Dictionary).get("taken", false)):
				return
	_cleared[area_id] = true
	_upgrade_untouched_areas(area_id)


## --- Save ---


func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"rank": _rank.duplicate(true),
		"engaged": _engaged.duplicate(true),
		"cleared": _cleared.duplicate(true),
		"upgrade_spent": _upgrade_spent.duplicate(true),
		"room_items": _room_items.duplicate(true),
		"lore_fights": _lore_fights.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	reset_world()
	if data.is_empty():
		return
	for area_id in AREAS.keys():
		_rank[area_id] = clampi(int((data.get("rank", {}) as Dictionary).get(area_id, 0)), 0, MAX_RANK)
		_engaged[area_id] = bool((data.get("engaged", {}) as Dictionary).get(area_id, false))
		_cleared[area_id] = bool((data.get("cleared", {}) as Dictionary).get(area_id, false))
		_upgrade_spent[area_id] = bool((data.get("upgrade_spent", {}) as Dictionary).get(area_id, false))
	var saved_rooms: Dictionary = data.get("room_items", {})
	for room_path in saved_rooms.keys():
		var out: Array = []
		for entry in (saved_rooms[room_path] as Array):
			var d: Dictionary = entry
			out.append({
				"id": String(d.get("id", "")),
				"x": float(d.get("x", 0.0)),
				"y": float(d.get("y", 0.0)),
				"taken": bool(d.get("taken", false)),
			})
		_room_items[String(room_path)] = out
	_lore_fights = (data.get("lore_fights", {}) as Dictionary).duplicate(true)


func _save() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and bool(saves.call("is_active")):
		saves.call("save_active")


## --- Scene lifecycle ---


func _on_scene_changed() -> void:
	_step_fights_this_visit = 0
	_starting_fight = false
	var scene := _current_scene()
	if scene == null:
		return
	var path := scene.scene_file_path
	if path.begins_with("res://combat/"):
		return
	_mark_visited_if_walkable(scene)
	if _pending_return_valid and _pending_return_scene == path:
		_apply_return_placement(scene)
	elif _pending_return_scene == path:
		_pending_return_scene = ""
	if is_enabled() and is_indoor_scene(path):
		_populate_room(scene)
	if is_enabled() and path == TUTORIAL_SCENE and is_locker_tutorial_pending():
		_start_locker_tutorial(scene)


func _mark_visited_if_walkable(scene: Node) -> void:
	if scene.find_child("Player", true, false) == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("mark_room_visited"):
		gm.call("mark_room_visited", scene.scene_file_path)


func _apply_return_placement(scene: Node) -> void:
	var tex := _pending_return_tex
	_pending_return_scene = ""
	_pending_return_valid = false
	await _settle_frames(scene, 10)
	if scene != _current_scene():
		return
	var env := _env_of(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	if env == null or player == null:
		return
	PlayerSpawnSync.apply_tex(env, player, tex)


func _populate_room(scene: Node) -> void:
	var path := scene.scene_file_path
	var area_id := area_for_scene(path)
	if area_id.is_empty():
		return
	var want: int = int((AREAS[area_id]["rooms"] as Dictionary).get(path, 0))
	if want <= 0:
		return
	await _settle_frames(scene, 10)
	if scene != _current_scene():
		return
	var env := _env_of(scene)
	if env == null:
		return
	if not _room_items.has(path):
		_room_items[path] = _decide_placements(scene, env, area_id, want, path)
		_save()
	_spawn_pickups(scene, env, path)


func _decide_placements(
	scene: Node, env: Node2D, area_id: String, want: int, path: String
) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(path)
	var tex_size := _texture_size(scene)
	var player := scene.find_child("Player", true, false) as Node2D
	# The player is standing on walkable floor, so that spot is the safe fallback.
	var player_tex := PlayerSpawnSync.capture_tex(env, player) if player != null else Vector2.ZERO
	var floor_y: float = player_tex.y if player != null else tex_size.y * 0.72
	var exclude: Array[RID] = []
	if player is CollisionObject2D:
		exclude.append((player as CollisionObject2D).get_rid())
	var out: Array = []
	var used_lanes: Array = []
	for i in want:
		var frac := (float(i) + 1.0) / (float(want) + 1.0)
		frac = clampf(frac + rng.randf_range(-0.07, 0.07), 0.14, 0.86)
		var wanted := Vector2(tex_size.x * frac, floor_y + rng.randf_range(-50.0, 50.0))
		var away := 260.0 * (1.0 if i % 2 == 0 else -1.0) * float(i + 1)
		var fallback := Vector2(
			clampf(player_tex.x + away, tex_size.x * 0.08, tex_size.x * 0.92), player_tex.y
		)
		var spot := _find_free_spot(env, wanted, tex_size, fallback, exclude)
		var item_id := _roll_item(area_id, rng, used_lanes)
		if item_id.is_empty():
			continue
		used_lanes.append(_lane_of(item_id))
		out.append({"id": item_id, "x": spot.x, "y": spot.y, "taken": false})
	return out


func _texture_size(scene: Node) -> Vector2:
	var bg := scene.get_node_or_null("WalkableWorld/Background") as Sprite2D
	if bg == null:
		bg = scene.find_child("Background", true, false) as Sprite2D
	if bg != null and bg.texture != null:
		return Vector2(bg.texture.get_width(), bg.texture.get_height())
	return Vector2(1920.0, 1280.0)


## Slide around until the spot is clear of walls, furniture, and interact
## zones — an item sitting on a door box would steal that door's [E].
func _find_free_spot(
	env: Node2D,
	wanted: Vector2,
	tex_size: Vector2,
	fallback: Vector2,
	exclude: Array[RID],
) -> Vector2:
	var world := env.get_world_2d()
	if world == null:
		return wanted
	var space := world.direct_space_state
	if space == null:
		return wanted
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_bodies = true
	query.exclude = exclude
	var min_x := tex_size.x * 0.08
	var max_x := tex_size.x * 0.92
	var x_offsets: Array[float] = [0.0]
	for i in 12:
		var step := float(i + 1) * 90.0
		x_offsets.append(step)
		x_offsets.append(-step)
	var y_offsets: Array[float] = [0.0, -70.0, 70.0, -150.0, 150.0, -230.0, 230.0]
	# Pass 1 also dodges interact zones; pass 2 only insists on open floor, so a
	# corridor whose floor is all door boxes still gets a reachable item.
	for avoid_zones in [true, false]:
		query.collide_with_areas = avoid_zones
		for dy in y_offsets:
			for dx in x_offsets:
				var candidate := Vector2(clampf(wanted.x + dx, min_x, max_x), wanted.y + dy)
				query.position = env.to_global(candidate)
				if space.intersect_point(query, 1).is_empty():
					return candidate
		# Nothing clear nearby: try beside the player, which is walkable floor.
		query.position = env.to_global(fallback)
		if space.intersect_point(query, 1).is_empty():
			return fallback
	return wanted


func _roll_item(area_id: String, rng: RandomNumberGenerator, used_lanes: Array) -> String:
	var ordered := _candidate_lanes(area_id, used_lanes)
	if ordered.is_empty():
		return ""
	var start := rng.randi() % ordered.size()
	var rank := area_rank(area_id)
	var blocked := _blocked_item_ids()
	for i in ordered.size():
		var lane := String(ordered[(start + i) % ordered.size()])
		var item_id := _resolve_lane(lane, rank, blocked)
		if not item_id.is_empty():
			return item_id
	return ""


func _candidate_lanes(area_id: String, used_lanes: Array) -> Array:
	var families: Array = (AREAS[area_id]["families"] as Array).duplicate()
	var baselines: Array = []
	for lane in ItemLinesScript.scatter_lane_keys():
		baselines.append(String(lane))
	var unused: Array = []
	var used_fallback: Array = []
	for lane in families + baselines:
		var key := String(lane)
		if used_lanes.has(key):
			if not used_fallback.has(key):
				used_fallback.append(key)
		elif not unused.has(key):
			unused.append(key)
	return unused + used_fallback


func _resolve_lane(lane: String, rank: int, blocked: Array) -> String:
	if ItemLinesScript.is_baseline_lane(lane):
		for tier in range(rank, -1, -1):
			var item_id := ItemLinesScript.rung_id(lane, tier)
			if item_id.is_empty() or blocked.has(item_id):
				continue
			if _item_exists(item_id):
				return item_id
		return ""
	for tier in range(rank, -1, -1):
		var item_id := "%s-%s" % [RANK_PREFIXES[tier], lane]
		if blocked.has(item_id):
			continue
		if _item_exists(item_id):
			return item_id
	return ""


func _blocked_item_ids() -> Array:
	var blocked: Array = []
	var run := _run()
	if run != null:
		for item_id in Array(run.state.owned_item_ids):
			var owned := String(item_id)
			if not owned.is_empty() and not blocked.has(owned):
				blocked.append(owned)
	for room_path in _room_items.keys():
		for entry in (_room_items[room_path] as Array):
			var placed := String((entry as Dictionary).get("id", ""))
			if not placed.is_empty() and not blocked.has(placed):
				blocked.append(placed)
	return blocked


func _lane_of(item_id: String) -> String:
	var baseline := ItemLinesScript.lane_of_id(item_id)
	if not baseline.is_empty():
		return baseline
	return _family_of(item_id)


func _family_of(item_id: String) -> String:
	var parts := item_id.split("-")
	return String(parts[1]) if parts.size() > 1 else ""


func _item_exists(item_id: String) -> bool:
	var run := _run()
	if run == null or not run.has_method("load_item"):
		return false
	return run.call("load_item", item_id) != null


func _spawn_pickups(scene: Node, env: Node2D, path: String) -> void:
	var entries: Array = _room_items.get(path, [])
	if entries.is_empty():
		return
	var host := env.get_node_or_null(PICKUP_HOST_NAME) as Node2D
	if host == null:
		host = Node2D.new()
		host.name = PICKUP_HOST_NAME
		env.add_child(host)
	for child in host.get_children():
		child.queue_free()
	var prompt := _ensure_prompt_overlay(scene)
	var info_card := _ensure_info_card(scene)
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if bool(entry.get("taken", false)):
			continue
		var pickup := PickupScript.new()
		pickup.name = "WorldItem%d" % i
		pickup.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		pickup.setup(String(entry.get("id", "")), path, i, prompt, info_card)
		host.add_child(pickup)


func _ensure_prompt_overlay(scene: Node) -> Node:
	var existing := scene.get_node_or_null(PROMPT_NODE_NAME)
	if existing != null:
		return existing
	if not ResourceLoader.exists(PROMPT_SCENE):
		return null
	var packed := load(PROMPT_SCENE) as PackedScene
	if packed == null:
		return null
	var overlay := packed.instantiate()
	overlay.name = PROMPT_NODE_NAME
	scene.add_child(overlay)
	return overlay


## One card per room, shared by every pickup in it — only one item can be
## within reach at a time.
func _ensure_info_card(scene: Node) -> Node:
	var existing := scene.get_node_or_null(INFO_CARD_NODE_NAME)
	if existing != null:
		return existing
	var card := InfoCardScript.new()
	card.name = INFO_CARD_NODE_NAME
	scene.add_child(card)
	return card


## --- Small helpers ---


func _settle_frames(scene: Node, frames: int) -> void:
	for _i in frames:
		if get_tree() == null:
			return
		await get_tree().process_frame
		if not is_instance_valid(scene):
			return


func _current_scene() -> Node:
	var tree := get_tree()
	return tree.current_scene if tree != null else null


func _env_of(scene: Node) -> Node2D:
	var env := scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	if env == null:
		env = scene.find_child("EnvironmentColliders", true, false) as Node2D
	return env


func _run() -> Node:
	return get_node_or_null("/root/AxelRun")
