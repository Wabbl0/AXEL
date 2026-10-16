extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const AXEL_RUN_PATH := "res://scripts/autoload/axel_run.gd"
const ITEM_DIR := "res://combat/data/items/"
const RANK_LETTERS: PackedStringArray = ["C", "U", "R", "E", "L"]
const FS_POWERS: Array[StringName] = [&"cigarette", &"alcohol", &"bloody_hand"]
const MAX_SPINS_PER_FIGHT := 4000
const MAX_EQUIPPED := 7
const SCHEDULE: Array = [
	["tutorial", -1, 0],
	["1.4 item", 0, 0],
	["2.1 item", 1, 0],
	["2.1 item", 1, 0],
	["2.2 memory", -1, 0],
	["2.1 item", 1, 0],
	["2.3 flashlight", -1, 1],
	["2.3 item", 2, 1],
	["2.3 item", 2, 1],
	["2.4 item", 3, 1],
	["3.1 item", 4, 1],
	["3.2 memory", -1, 1],
	["3.1 item", 4, 1],
	["4.1 item", 4, 1],
	["4.1 key", -1, 2],
	["4.2 memory", -1, 2],
	["4.1 item", 4, 2],
	["5.1 item", 4, 2],
	["5.1 item", 4, 2],
	["5.1 name", -1, 3],
	["5.2 memory", -1, 3],
]

var _items_by_rank: Array = [[], [], [], [], []]
var _ladder: Array[int] = []
var _growth: float = 1.5
var _growth_step: float = 0.0
var _dread_item_scale: float = 1.0
var _dread_memory: float = 0.10
const DREAD_BY_RANK: Array[float] = [0.08, 0.10, 0.12, 0.16, 0.20]
const ROOM_DEPTH := {"1.2": 0, "1.4": 0, "2.4": 0, "2.1": 1, "2.2": 1, "2.3": 1, "3.1": 2, "3.2": 2, "4.1": 3, "4.2": 3, "5.1": 3, "5.2": 3}
var DEPTH_WEIGHTS: Array = [[100, 0, 0, 0, 0], [80, 20, 0, 0, 0], [55, 35, 10, 0, 0], [30, 40, 25, 5, 0]]
var DEPTH_GOAL: Array[float] = [1.0, 1.25, 1.5, 1.8]
var _depth_on: bool = true
var _hex_on: bool = true
var _hex_seed: int = 0
var _rounding: int = 25
var _lore_step: float = 0.15
var _bankroll: int = 1000
var _runs: int = 200
var _bet_style: String = "min"
var _real_seeds: bool = false
var _stalls: int = 0
var _fight_limit: int = 0
var _pick_style: String = "random"
var _choices: int = 3
var _lane: String = ""
var _run_offset: int = 0
var _run_log: bool = false
var _wager: Array[int] = []
var _payout: Array[int] = []
var _cost: Array[int] = []


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	_read_config()
	_load_items()
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.set_limit_spins(false)
	if not OS.get_environment("DIFF_SOLO").is_empty():
		_run_solo(cr, OS.get_environment("DIFF_SOLO"))
		cr.queue_free()
		quit(0)
		return
	var fights := SCHEDULE.size() if _fight_limit <= 0 else mini(_fight_limit, SCHEDULE.size())
	var entered: Array[int] = []
	var deaths: Array[int] = []
	var goals: Array = []
	var wallets: Array = []
	var spins: Array = []
	for _i in fights:
		_wager.append(0)
		_payout.append(0)
		_cost.append(0)
		entered.append(0)
		deaths.append(0)
		goals.append([])
		wallets.append([])
		spins.append([])
	for run_n in _runs:
		var run_i := run_n + _run_offset
		var picks: PackedStringArray = []
		var died_at := 0
		var pick_rng := RandomNumberGenerator.new()
		pick_rng.seed = 7001 + run_i * 7919
		_hex_seed = 90001 + run_i * 104729
		var wallet := _bankroll
		var owned: Array = []
		var dread := 0.0
		for fight_i in fights:
			var row: Array = SCHEDULE[fight_i]
			var rank := int(row[1])
			var depth := _row_depth(String(row[0]))
			if rank >= 0 and _depth_on:
				rank = _roll_depth_rank(depth, rank, pick_rng)
			if rank >= 0:
				var item = _pick_item(rank, pick_rng) if _pick_style == "random" else _pick_synergy(rank, owned, pick_rng)
				if item != null:
					owned.append(item)
					picks.append("%s@%d" % [item.resource_path.get_file().get_slice("_", 0), fight_i + 1])
					dread += DREAD_BY_RANK[clampi(rank, 0, 4)] * _dread_item_scale
			if String(row[0]).ends_with("memory"):
				dread += _dread_memory
			var equipped: Array = owned.slice(maxi(owned.size() - MAX_EQUIPPED, 0)) if _pick_style == "random" else _best_loadout(owned)
			var tutorial := String(row[0]) == "tutorial"
			var result := _play_fight(
				cr,
				_fight_seed(run_i, fight_i),
				[] if tutorial else equipped,
				0.0 if tutorial else _lore_step * float(int(row[2])) + dread,
				_goal_for(fight_i + 1, depth, String(row[0]) == "tutorial"),
				tutorial,
				wallet,
				pick_rng,
			)
			entered[fight_i] += 1
			_wager[fight_i] += int(result["wager"])
			_payout[fight_i] += int(result["payout"])
			_cost[fight_i] += wallet - int(result["wallet"])
			(goals[fight_i] as Array).append(int(result["goal"]))
			(spins[fight_i] as Array).append(int(result["spins"]))
			if not bool(result["won"]):
				deaths[fight_i] += 1
				died_at = fight_i + 1
				break
			wallet = int(result["wallet"])
			(wallets[fight_i] as Array).append(wallet)
		if _run_log:
			print("DIFF_RUN %d died=%d family=%s picks=%s" % [run_i, died_at, _main_family(owned), ",".join(picks)])
	_print_report(entered, deaths, goals, wallets, spins)
	cr.queue_free()
	quit(0)


func _run_solo(cr: CombatRoot, spec: String) -> void:
	var spins_per_seed := int(_env_float("DIFF_SOLO_SPINS", 400))
	var seeds := int(_env_float("DIFF_SOLO_SEEDS", 6))
	var bands: Array[int] = [0, 50, 150, 400, 100000]
	for entry in spec.split(";"):
		var items: Array = []
		var label := "none"
		if entry != "none":
			label = entry
			for part in entry.split(","):
				var item: Resource = null
				if part.ends_with(".tres") and ResourceLoader.exists(part):
					item = load(part)
				if item == null:
					for file in DirAccess.get_files_at(ITEM_DIR):
						if file.begins_with(part.strip_edges() + "_"):
							item = load(ITEM_DIR + file)
				if item != null:
					items.append(item)
		var wager: Array[int] = [0, 0, 0, 0]
		var payout: Array[int] = [0, 0, 0, 0]
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for seed_i in seeds:
			cr.set_lore_goal_bonus(0.0)
			cr.set_equipped_items(items)
			cr.set_goal_base_target_cents(100000000)
			cr.set_tutorial_script_seeds([])
			cr.set_tutorial_last_spin_lock(false)
			cr.setup_new_grid(31337 + seed_i * 7919)
			cr.restore_run_bankroll(100000000)
			cr.set_bet_index(0)
			var paid := 0
			var guard := 0
			while paid < spins_per_seed and guard < spins_per_seed * 20:
				guard += 1
				if cr.is_encounter_complete():
					break
				if cr.is_waiting_for_free_spin_choice():
					cr.choose_free_spins_power(FS_POWERS[rng.randi_range(0, FS_POWERS.size() - 1)])
					continue
				var was_free: bool = cr.free_spins.active
				var before_wager := int(cr._bets_used_cents)
				var before_bank := int(cr.get_bankroll())
				cr.spin_sync()
				var spent := int(cr._bets_used_cents) - before_wager
				var band := 0
				while band < 3 and paid >= bands[band + 1]:
					band += 1
				wager[band] += spent
				payout[band] += int(cr.get_bankroll()) - before_bank + spent
				if not was_free:
					paid += 1
		var parts: PackedStringArray = []
		for band in 4:
			var r := 0.0
			if wager[band] > 0:
				r = 100.0 * float(payout[band]) / float(wager[band])
			parts.append("%d-%d:%6.1f%%" % [bands[band], mini(bands[band + 1], spins_per_seed), r])
		print("DIFF_SOLO %-28s %s" % [label, " ".join(parts)])


func _read_config() -> void:
	var source := FileAccess.get_file_as_string(AXEL_RUN_PATH)
	var ladder_env := OS.get_environment("DIFF_LADDER")
	if ladder_env.is_empty():
		ladder_env = _source_const(source, "WORLD_GOAL_LADDER_CENTS", "100, 150, 225")
	for part in ladder_env.split(","):
		if not part.strip_edges().is_empty():
			_ladder.append(int(part.strip_edges()))
	_growth = _env_float("DIFF_GROWTH", float(_source_const(source, "WORLD_GOAL_LADDER_GROWTH", "1.5")))
	_growth_step = _env_float("DIFF_GROWTH_STEP", float(_source_const(source, "WORLD_GOAL_GROWTH_STEP", "0.0")))
	_dread_item_scale = _env_float("DIFF_DREAD_ITEM", 1.0)
	_depth_on = OS.get_environment("DIFF_DEPTH") != "0"
	_hex_on = OS.get_environment("DIFF_HEX") != "0"
	var weights_env := OS.get_environment("DIFF_DEPTH_WEIGHTS")
	if not weights_env.is_empty():
		DEPTH_WEIGHTS.clear()
		for row in weights_env.split(";"):
			var tiers: Array = []
			for part in row.split("/"):
				tiers.append(int(part))
			DEPTH_WEIGHTS.append(tiers)
	var depth_goal_env := OS.get_environment("DIFF_DEPTH_GOAL")
	if not depth_goal_env.is_empty():
		DEPTH_GOAL.clear()
		for part in depth_goal_env.split(","):
			DEPTH_GOAL.append(float(part))
	_dread_memory = _env_float("DIFF_DREAD_MEMORY", float(_source_const(source, "DREAD_PER_MEMORY", "0.10")))
	_rounding = int(_env_float("DIFF_ROUNDING", float(_source_const(source, "WORLD_GOAL_LADDER_ROUNDING", "25"))))
	_lore_step = _env_float("DIFF_LORE", float(_source_const(source, "LORE_GOAL_BONUS", "0.15")))
	_bankroll = int(_env_float("DIFF_BANKROLL", float(_source_const(source, "STARTING_BANKROLL_CENTS", "1000"))))
	_runs = int(_env_float("DIFF_RUNS", 200))
	_bet_style = OS.get_environment("DIFF_BET") if not OS.get_environment("DIFF_BET").is_empty() else "min"
	_real_seeds = OS.get_environment("DIFF_REAL_SEEDS") == "1"
	_fight_limit = int(_env_float("DIFF_FIGHTS", 0))
	if not OS.get_environment("DIFF_PICK").is_empty():
		_pick_style = OS.get_environment("DIFF_PICK")
	_choices = maxi(int(_env_float("DIFF_CHOICES", 3)), 1)
	_lane = OS.get_environment("DIFF_LANE")
	_run_offset = int(_env_float("DIFF_RUN_OFFSET", 0))
	_run_log = OS.get_environment("DIFF_RUN_LOG") == "1"


func _source_const(source: String, name: String, fallback: String) -> String:
	var re := RegEx.new()
	re.compile("const " + name + "[^=]*=\\s*(\\[[^\\]]*\\]|[0-9.]+)")
	var m := re.search(source)
	if m == null:
		return fallback
	return m.get_string(1).replace("[", "").replace("]", "").replace("\n", "").replace("\t", "")


func _env_float(key: String, fallback: float) -> float:
	var raw := OS.get_environment(key)
	if raw.is_empty():
		return fallback
	return float(raw)


func _load_items() -> void:
	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		push_error("DIFF missing item dir")
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		if not file.ends_with(".tres"):
			continue
		var rank := RANK_LETTERS.find(file.substr(0, 1))
		if rank < 0:
			continue
		var item := load(ITEM_DIR + file)
		if item != null:
			(_items_by_rank[rank] as Array).append(item)


func _pick_item(rank: int, rng: RandomNumberGenerator) -> Resource:
	var r := clampi(rank, 0, RANK_LETTERS.size() - 1)
	while r >= 0:
		var pool: Array = _items_by_rank[r]
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
		r -= 1
	return null


func _family_of(item: Resource) -> String:
	return str(item.get("family")).strip_edges()


func _main_family(owned: Array) -> String:
	if not _lane.is_empty():
		return _lane
	var counts := {}
	var best := ""
	var best_score := -1
	for item in owned:
		var fam := _family_of(item)
		if fam.is_empty():
			continue
		counts[fam] = int(counts.get(fam, 0)) + 10 + int(item.get("rarity"))
		if int(counts[fam]) > best_score:
			best_score = int(counts[fam])
			best = fam
	return best


func _pick_synergy(rank: int, owned: Array, rng: RandomNumberGenerator) -> Resource:
	var r := clampi(rank, 0, RANK_LETTERS.size() - 1)
	var pool: Array = []
	while r >= 0:
		for item in _items_by_rank[r]:
			if not owned.has(item):
				pool.append(item)
		if not pool.is_empty():
			break
		r -= 1
	if pool.is_empty():
		return null
	var offered: Array = []
	for _i in mini(_choices, pool.size()):
		var pick = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(pick)
		offered.append(pick)
	var fam := _main_family(owned)
	if not fam.is_empty():
		for item in offered:
			if _family_of(item) == fam:
				return item
	if not _lane.is_empty() or owned.is_empty():
		return offered[0]
	for item in offered:
		if not _family_of(item).is_empty():
			return item
	return offered[0]


func _best_loadout(owned: Array) -> Array:
	if owned.size() <= MAX_EQUIPPED:
		return owned.duplicate()
	var fam := _main_family(owned)
	var ranked := owned.duplicate()
	ranked.sort_custom(func(a, b):
		var sa := int(a.get("rarity")) + (5 if _family_of(a) == fam else 0)
		var sb := int(b.get("rarity")) + (5 if _family_of(b) == fam else 0)
		return sa > sb)
	return ranked.slice(0, MAX_EQUIPPED)


func _fight_seed(run_i: int, fight_i: int) -> int:
	var run_seed := 424243 + run_i * 104729
	if _real_seeds:
		return run_seed + 500009 + ((fight_i + 1) % 3) * 10007
	return run_seed + 500009 + fight_i * 10007


func _row_depth(label: String) -> int:
	return int(ROOM_DEPTH.get(label.get_slice(" ", 0), 0))


func _roll_depth_rank(depth: int, shifts: int, rng: RandomNumberGenerator) -> int:
	var weights: Array = (DEPTH_WEIGHTS[clampi(depth, 0, 3)] as Array).duplicate()
	for _i in shifts:
		var moved: Array = [0, 0, 0, 0, 0]
		for tier in 5:
			moved[mini(tier + 1, 4)] = int(moved[mini(tier + 1, 4)]) + int(weights[tier])
		weights = moved
	var total := 0
	for w in weights:
		total += int(w)
	var pick := rng.randi() % maxi(total, 1)
	for tier in 5:
		pick -= int(weights[tier])
		if pick < 0:
			return tier
	return 0


func _goal_for(fight_count: int, depth: int, tutorial: bool) -> int:
	var base := _goal_base(fight_count)
	if tutorial or not _depth_on:
		return base
	return maxi(int(ceil(float(base) * DEPTH_GOAL[clampi(depth, 0, 3)] / 5.0)) * 5, 1)


func _goal_base(fight_count: int) -> int:
	var rung := maxi(fight_count - 1, 0)
	var last := _ladder.size() - 1
	if rung <= last:
		return _ladder[rung]
	var value := float(_ladder[last])
	for i in rung - last:
		value *= _growth + _growth_step * float(i)
	return maxi(int(round(value / float(_rounding))) * _rounding, 1)


func _apply_hexes(cr: CombatRoot, items: Array) -> void:
	var run := root.get_node_or_null("AxelRun")
	if not _hex_on or run == null or not run.has_method("hex_masks"):
		cr.set_item_hexes({})
		cr.set_fight_curses([])
		return
	run.state.seed = _hex_seed
	var ids: Array = []
	for item in items:
		ids.append(str(item.get("id")))
	cr.set_item_hexes(run.call("hex_masks", ids))
	var curses: Array = []
	for curse_id in run.call("legendary_fight_curses", ids):
		curses.append({"id": curse_id, "params": {}})
	cr.set_fight_curses(curses)


func _play_fight(
	cr: CombatRoot,
	seed_value: int,
	items: Array,
	lore: float,
	goal_base: int,
	tutorial: bool,
	wallet: int,
	rng: RandomNumberGenerator,
) -> Dictionary:
	cr.set_lore_goal_bonus(lore)
	cr.set_equipped_items(items)
	_apply_hexes(cr, [] if tutorial else items)
	cr.set_goal_base_target_cents(goal_base)
	cr.set_tutorial_script_seeds(CombatRoot.TUTORIAL_SCRIPT_SEEDS if tutorial else [])
	cr.set_tutorial_last_spin_lock(tutorial)
	cr.setup_new_grid(seed_value)
	cr.restore_run_bankroll(wallet)
	var goal := cr.get_chip_bar_goal_target_cents()
	var spins := 0
	for _i in MAX_SPINS_PER_FIGHT:
		if cr.is_encounter_complete():
			break
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_power(FS_POWERS[rng.randi_range(0, FS_POWERS.size() - 1)])
			continue
		if not cr.free_spins.active:
			cr.set_bet_index(_bet_index(cr, _choose_bet(int(cr.get_bankroll()))))
		cr.spin_sync()
		spins += 1
	if not cr.is_encounter_complete():
		_stalls += 1
	var won := cr.is_encounter_complete() and cr.did_win_encounter()
	var wager := int(cr._bets_used_cents)
	var after := int(cr.get_bankroll())
	return {
		"won": won,
		"wallet": after,
		"goal": goal,
		"spins": spins,
		"wager": wager,
		"payout": after - wallet + wager,
	}


func _choose_bet(wallet: int) -> int:
	var ladder := [100, 200, 300, 400, 500, 1000]
	if _bet_style != "fifth":
		return 100
	@warning_ignore("integer_division")
	var target := wallet / 5
	var best := 100
	for step in ladder:
		if step <= target:
			best = step
	return best


func _bet_index(cr: CombatRoot, bet: int) -> int:
	var ladder: Array = cr.get_bet_ladder()
	for i in ladder.size():
		if int(round(float(ladder[i]))) == bet:
			return i
	return 0


func _median(values: Array) -> int:
	if values.is_empty():
		return -1
	var sorted := values.duplicate()
	sorted.sort()
	@warning_ignore("integer_division")
	return int(sorted[sorted.size() / 2])


func _print_report(entered: Array[int], deaths: Array[int], goals: Array, wallets: Array, spins: Array) -> void:
	print("DIFF_CONFIG hex=%s depth=%s weights=%s depth_goal=%s step=%.3f dread_item=%.2f dread_mem=%.2f ladder=%s growth=%.2f lore=%.2f bankroll=%d bet=%s runs=%d real_seeds=%s pick=%s choices=%d lane=%s" % [
		str(_hex_on), str(_depth_on), str(DEPTH_WEIGHTS), str(DEPTH_GOAL), _growth_step, _dread_item_scale, _dread_memory, str(_ladder), _growth, _lore_step, _bankroll, _bet_style, _runs, str(_real_seeds), _pick_style, _choices, _lane,
	])
	var items := 0
	var dead := 0
	for fight_i in entered.size():
		var row: Array = SCHEDULE[fight_i]
		if int(row[1]) >= 0:
			items += 1
		dead += deaths[fight_i]
		var here := 0.0
		if entered[fight_i] > 0:
			here = 100.0 * float(deaths[fight_i]) / float(entered[fight_i])
		var rtp := 0.0
		var cost := 0.0
		if entered[fight_i] > 0:
			cost = float(_cost[fight_i]) / float(entered[fight_i])
		if _wager[fight_i] > 0:
			rtp = 100.0 * float(_payout[fight_i]) / float(_wager[fight_i])
		print("DIFF_FIGHT %2d %-15s items=%2d goal=%6d die_here=%5.1f%% dead_total=%5.1f%% wallet_med=%7d spins_med=%4d rtp=%5.1f%% cost_avg=%7.0f" % [
			fight_i + 1,
			String(row[0]),
			items,
			_median(goals[fight_i]),
			here,
			100.0 * float(dead) / float(_runs),
			_median(wallets[fight_i]),
			_median(spins[fight_i]),
			rtp,
			cost,
		])
	print("DIFF_STALLS %d" % _stalls)
