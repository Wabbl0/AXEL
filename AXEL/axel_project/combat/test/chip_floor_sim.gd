extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const FS_PICK: StringName = &"cigarette"
const STARTING_WALLET := 1000
const MIN_BET := 100
const ENGINE_CAP := 1000
const MAX_FIGHTS := 20
const RUNS_PER_SETUP := 16
const MAX_SPINS_PER_FIGHT := 8000
const LORE_STEP := 0.15
const GOAL_LADDER: Array[int] = [100, 150, 225]
const GOAL_GROWTH := 1.5
const GOAL_ROUNDING := 25
const FLOORS: Array[float] = [0.0, 0.10, 0.15, 0.20]
const BET_STYLES: Array[String] = ["min", "fifth", "max"]
const STRONG_PATHS: PackedStringArray = [
	"res://combat/data/items/C1_ash_spin_token.tres",
	"res://combat/data/items/U1_filtered_spinner.tres",
	"res://combat/data/items/R1_fractured_reel.tres",
	"res://combat/data/items/E4_overflow_ledger.tres",
]

var _strong_items: Array = []
var _strong_first_free: bool = false


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	_load_strong_items()
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.set_limit_spins(false)
	if OS.get_environment("CHIP_FLOOR_TRACE") == "1":
		_trace_empty_runs(cr)
		cr.queue_free()
		quit(0)
		return
	if OS.get_environment("CHIP_FLOOR_SEARCH") == "1":
		_search_higher_floors(cr)
		cr.queue_free()
		quit(0)
		return
	var reports: Array[Dictionary] = []
	var setup_i := 0
	var setup_count := 2 * BET_STYLES.size() * FLOORS.size()
	for loadout_name in ["empty", "strong"]:
		var items: Array = [] if loadout_name == "empty" else _strong_items
		var first_free := false if loadout_name == "empty" else _strong_first_free
		for bet_style in BET_STYLES:
			for floor_pct in FLOORS:
				setup_i += 1
				print("CHIP_FLOOR_PROGRESS %d/%d loadout=%s bet=%s floor=%.2f" % [
					setup_i, setup_count, loadout_name, bet_style, floor_pct,
				])
				var report := _run_setup(cr, loadout_name, items, first_free, bet_style, floor_pct)
				reports.append(report)
				print("CHIP_FLOOR_SETUP %s" % JSON.stringify(report))
	var pick := _pick_floor(reports)
	print("CHIP_FLOOR_PICK %s" % JSON.stringify(pick))
	cr.queue_free()
	quit(0)


func _trace_empty_runs(cr: CombatRoot) -> void:
	for run_i in 4:
		var wallet := STARTING_WALLET
		var spins := 0
		for fight_i in 6:
			var lore := _lore_for_fight(fight_i)
			var before := wallet
			var result := _play_fight(cr, [], false, "min", 0.0, fight_i, run_i, lore, wallet, spins)
			wallet = int(result["wallet"])
			spins = int(result["spins"])
			print("CHIP_FLOOR_TRACE run=%d fight=%d goal=%d start=%d end=%d won=%s progress=%d" % [
				run_i,
				fight_i + 1,
				cr.get_chip_bar_goal_target_cents(),
				before,
				wallet,
				str(bool(result["won"])),
				cr.get_chip_bar_goal_progress_cents(),
			])
			if not bool(result["won"]):
				break


func _search_higher_floors(cr: CombatRoot) -> void:
	var floors: Array[float] = [7.0, 8.0, 9.0]
	for floor_pct in floors:
		print("CHIP_FLOOR_SEARCH loadout=empty floor=%.1f" % floor_pct)
		var report := _run_setup(cr, "empty", [], false, "min", floor_pct, 16)
		print("CHIP_FLOOR_SETUP %s" % JSON.stringify(report))
	print("CHIP_FLOOR_SEARCH loadout=strong floor=8.0")
	var strong := _run_setup(cr, "strong", _strong_items, _strong_first_free, "min", 8.0, 16)
	print("CHIP_FLOOR_SETUP %s" % JSON.stringify(strong))


func _load_strong_items() -> void:
	for path in STRONG_PATHS:
		var item := load(path)
		if item == null:
			push_error("CHIP_FLOOR missing item %s" % path)
			continue
		_strong_items.append(item)
		var params = item.get("effect_params")
		if params is Dictionary and bool(params.get("first_free", false)):
			_strong_first_free = true


func _run_setup(
	cr: CombatRoot,
	loadout_name: String,
	items: Array,
	first_free: bool,
	bet_style: String,
	floor_pct: float,
	run_count: int = RUNS_PER_SETUP,
) -> Dictionary:
	var cleared: Array[int] = []
	var wallets_by_fight: Array = []
	for _fight_i in MAX_FIGHTS:
		wallets_by_fight.append([])
	var spins_total := 0
	for run_i in run_count:
		var run := _play_run(cr, items, first_free, bet_style, floor_pct, run_i)
		cleared.append(int(run["cleared"]))
		spins_total += int(run["spins"])
		var wallets: Array = run["wallets"]
		for fight_i in wallets.size():
			(wallets_by_fight[fight_i] as Array).append(int(wallets[fight_i]))
	return {
		"loadout": loadout_name,
		"bet": bet_style,
		"floor": floor_pct,
		"runs": run_count,
		"spins": spins_total,
		"median_fights": _median_int(cleared),
		"min_fights": _min_int(cleared),
		"max_fights": _max_int(cleared),
		"pass7": _pass_rate(cleared, 7),
		"pass12": _pass_rate(cleared, 12),
		"pass20": _pass_rate(cleared, 20),
		"cleared": cleared,
		"median_wallet_after_win": _median_wallets(wallets_by_fight),
	}


func _play_run(
	cr: CombatRoot,
	items: Array,
	first_free: bool,
	bet_style: String,
	floor_pct: float,
	run_i: int,
) -> Dictionary:
	var wallet := STARTING_WALLET
	var cleared := 0
	var spins := 0
	var wallets: Array[int] = []
	for fight_i in MAX_FIGHTS:
		var lore := _lore_for_fight(fight_i)
		var won := _play_fight(cr, items, first_free, bet_style, floor_pct, fight_i, run_i, lore, wallet, spins)
		wallet = int(won["wallet"])
		spins = int(won["spins"])
		if not bool(won["won"]):
			break
		cleared += 1
		wallets.append(wallet)
	return {"cleared": cleared, "spins": spins, "wallets": wallets}


func _play_fight(
	cr: CombatRoot,
	items: Array,
	first_free: bool,
	bet_style: String,
	floor_pct: float,
	fight_i: int,
	run_i: int,
	lore: float,
	wallet: int,
	spins: int,
) -> Dictionary:
	var fight_seed := 800000 + run_i * 104729 + fight_i * 10007
	cr.setup_new_grid(fight_seed)
	cr.set_bet_index(0)
	cr.set_equipped_items(items)
	cr.set_goal_base_target_cents(_goal_base(fight_i))
	cr.set_lore_goal_bonus(lore)
	var goal := cr.get_chip_bar_goal_target_cents()
	var floor_amt := int(round(float(goal) * floor_pct))
	if wallet < floor_amt:
		wallet = floor_amt
	if wallet < MIN_BET:
		return {"won": false, "wallet": wallet, "spins": spins}
	var stalls := 0
	for _spin_i in MAX_SPINS_PER_FIGHT:
		if cr.is_waiting_for_free_spin_choice():
			var goal_before := cr.get_chip_bar_goal_progress_cents()
			cr.choose_free_spins_power(FS_PICK)
			wallet += cr.get_chip_bar_goal_progress_cents() - goal_before
			stalls = 0
			continue
		if cr.is_encounter_complete():
			if cr.did_win_encounter():
				return {"won": true, "wallet": wallet, "spins": spins}
			if wallet >= MIN_BET:
				_reopen_false_bust(cr)
				stalls += 1
				if stalls > 8:
					return {"won": false, "wallet": wallet, "spins": spins}
				continue
			return {"won": false, "wallet": wallet, "spins": spins}
		var free_active := cr.free_spins.active
		var bet := MIN_BET
		if not free_active:
			bet = _choose_bet(bet_style, wallet)
			if bet < MIN_BET or wallet < bet:
				return {"won": false, "wallet": wallet, "spins": spins}
			cr.set_bet_index(_bet_index(cr, bet))
		_prime_engine_bankroll(cr, wallet, bet, free_active)
		var spins_before := cr.get_spins_used()
		cr.spin_sync()
		spins += 1
		var spun := cr.get_spins_used() != spins_before or free_active
		if not spun:
			stalls += 1
			if stalls > 8:
				return {"won": false, "wallet": wallet, "spins": spins}
			continue
		stalls = 0
		if not free_active:
			var opening_free := first_free and spins_before == 0
			if not opening_free:
				wallet -= bet
		wallet += int(cr.get_last_spin_summary().get("payout", 0))
		if wallet < 0:
			wallet = 0
		if cr.is_encounter_complete() and cr.did_win_encounter():
			return {"won": true, "wallet": wallet, "spins": spins}
	return {"won": false, "wallet": wallet, "spins": spins}


func _reopen_false_bust(cr: CombatRoot) -> void:
	cr._encounter_complete = false
	cr._encounter_won = false
	cr._state = CombatRoot.State.IDLE


func _prime_engine_bankroll(cr: CombatRoot, wallet: int, bet: int, free_active: bool) -> void:
	var engine := mini(wallet, ENGINE_CAP)
	if free_active and engine < bet:
		engine = bet
	cr._bankroll_cents = engine


func _choose_bet(style: String, wallet: int) -> int:
	if wallet < MIN_BET:
		return 0
	var ladder := _ladder()
	if style == "min":
		return MIN_BET
	if style == "max":
		var best := MIN_BET
		for step in ladder:
			if step <= wallet:
				best = step
		return best
	@warning_ignore("integer_division")
	var target := int(wallet / 5)
	if target < MIN_BET:
		return MIN_BET
	var closest := MIN_BET
	var closest_gap := absi(MIN_BET - target)
	for step in ladder:
		if step > wallet:
			continue
		var gap := absi(step - target)
		if gap < closest_gap or (gap == closest_gap and step > closest):
			closest = step
			closest_gap = gap
	return closest


func _ladder() -> Array[int]:
	return [100, 200, 300, 400, 500, 1000]


func _bet_index(cr: CombatRoot, bet: int) -> int:
	var ladder: Array = cr.get_bet_ladder()
	for i in ladder.size():
		if int(round(float(ladder[i]))) == bet:
			return i
	return 0


func _goal_base(fight_i: int) -> int:
	var last := GOAL_LADDER.size() - 1
	if fight_i <= last:
		return GOAL_LADDER[fight_i]
	var value := float(GOAL_LADDER[last])
	for _step in fight_i - last:
		value *= GOAL_GROWTH
	var rounding := float(GOAL_ROUNDING)
	return maxi(int(round(value / rounding)) * GOAL_ROUNDING, 1)


func _lore_for_fight(fight_i: int) -> float:
	var steps := 0
	if fight_i >= 4:
		steps += 1
	if fight_i >= 8:
		steps += 1
	if fight_i >= 12:
		steps += 1
	if fight_i >= 16:
		steps += 1
	return LORE_STEP * float(steps)


func _median_wallets(wallets_by_fight: Array) -> Array:
	var out: Array = []
	for fight_wallets in wallets_by_fight:
		var row: Array = fight_wallets
		if row.is_empty():
			out.append(-1)
		else:
			out.append(_median_int(row))
	return out


func _median_int(values: Array) -> float:
	if values.is_empty():
		return -1.0
	var sorted: Array = values.duplicate()
	sorted.sort()
	var n := sorted.size()
	if n % 2 == 1:
		@warning_ignore("integer_division")
		return float(sorted[n / 2])
	@warning_ignore("integer_division")
	return (float(sorted[n / 2 - 1]) + float(sorted[n / 2])) * 0.5


func _min_int(values: Array) -> int:
	var best := 999999
	for v in values:
		best = mini(best, int(v))
	return best


func _max_int(values: Array) -> int:
	var best := 0
	for v in values:
		best = maxi(best, int(v))
	return best


func _pass_rate(cleared: Array, fight_n: int) -> float:
	if cleared.is_empty():
		return 0.0
	var wins := 0
	for v in cleared:
		if int(v) >= fight_n:
			wins += 1
	return float(wins) / float(cleared.size())


func _find_report(reports: Array[Dictionary], loadout: String, bet: String, floor_pct: float) -> Dictionary:
	for report in reports:
		if String(report["loadout"]) != loadout:
			continue
		if String(report["bet"]) != bet:
			continue
		if abs(float(report["floor"]) - floor_pct) > 0.001:
			continue
		return report
	return {}


func _pick_floor(reports: Array[Dictionary]) -> Dictionary:
	var empty0 := _find_report(reports, "empty", "min", 0.0)
	var empty10 := _find_report(reports, "empty", "min", 0.10)
	var empty15 := _find_report(reports, "empty", "min", 0.15)
	var empty20 := _find_report(reports, "empty", "min", 0.20)
	var strong0 := _find_report(reports, "strong", "min", 0.0)
	var medians: Array[float] = [
		float(empty0.get("median_fights", -1)),
		float(empty10.get("median_fights", -1)),
		float(empty15.get("median_fights", -1)),
		float(empty20.get("median_fights", -1)),
	]
	var same := true
	for median in medians:
		if absf(median - medians[0]) > 0.51:
			same = false
	var chosen := 0.0
	var reason := "10%, 15%, and 20% of the goal match no gift at all. An empty min-bet run dies in the opening fights while it still holds more chips than that share of the goal, so the top-up never pays. A strong payout loadout already clears most of the ladder with no gift."
	if not same:
		chosen = 0.15
		reason = "The tested top-ups no longer match. Re-check the setup lines before keeping a gift."
	return {
		"floor": chosen,
		"reason": reason,
		"floors_match_zero": same,
		"empty_min_0_median": medians[0],
		"empty_min_10_median": medians[1],
		"empty_min_15_median": medians[2],
		"empty_min_20_median": medians[3],
		"strong_min_0_median": float(strong0.get("median_fights", -1)),
		"strong_min_0_pass7": float(strong0.get("pass7", -1)),
		"strong_min_0_pass12": float(strong0.get("pass12", -1)),
		"strong_min_0_pass20": float(strong0.get("pass20", -1)),
	}
