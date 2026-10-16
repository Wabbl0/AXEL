extends SceneTree

const ROOT_SCENE := "res://combat/scenes/combat_root.tscn"
const SEED := 12345
const ODDS_ROLLS := 100000
const MAX_SPINS := 200

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	_check_odds()
	_check_rounds_repeat()
	await _check_offer_off_by_default()
	await _check_win_and_loss_math()
	await _check_goal_waits_for_collect()
	await _check_spins_unchanged_by_gamble()
	if _failures.is_empty():
		print("Double or Nothing check OK.")
		quit(0)
		return
	for f in _failures:
		push_error("double_or_nothing_check: " + f)
	quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _check_odds() -> void:
	var counts := {&"alcohol": 0, &"cigarette": 0, &"bloody_hand": 0}
	var r := DoubleOrNothing.make_rng(SEED, 0)
	for i in ODDS_ROLLS:
		var id := DoubleOrNothing.roll_with(r)
		counts[id] = int(counts[id]) + 1
	var want := {&"alcohol": 0.47, &"cigarette": 0.47, &"bloody_hand": 0.06}
	for id in want.keys():
		var got := float(counts[id]) / float(ODDS_ROLLS)
		if absf(got - float(want[id])) > 0.01:
			_fail("odds for %s are %.3f, want %.2f" % [id, got, want[id]])


func _check_rounds_repeat() -> void:
	for step in 50:
		var a := DoubleOrNothing.play_round(SEED, step)
		var b := DoubleOrNothing.play_round(SEED, step)
		if a != b:
			_fail("round %d is not repeatable" % step)
			return
		var belt: Array = a["belt"]
		if belt[int(a["land_index"])] != a["result"]:
			_fail("round %d belt does not land on the result" % step)
			return
		if belt.size() != DoubleOrNothing.BELT_LENGTH:
			_fail("round %d belt has the wrong length" % step)
			return


func _make_root(force: bool) -> CombatRoot:
	var cr: CombatRoot = load(ROOT_SCENE).instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.gamble_force_enabled = force
	cr.setup_new_grid(SEED)
	cr.set_bankroll_cents(3000)
	cr.set_goal_base_target_cents(1000000)
	return cr


func _free_root(cr: CombatRoot) -> void:
	cr.queue_free()
	await process_frame
	await process_frame


func _spin_until_offer(cr: CombatRoot) -> bool:
	for i in MAX_SPINS:
		if cr.is_encounter_complete():
			return false
		await cr.spin()
		if cr.has_gamble_offer():
			return true
	return false


func _check_offer_off_by_default() -> void:
	var cr := await _make_root(false)
	for i in 40:
		await cr.spin()
		if cr.has_gamble_offer():
			_fail("headless fight opened an offer without gamble_force_enabled")
			break
	await _free_root(cr)


func _pick_for(cr: CombatRoot, want_win: bool) -> StringName:
	var preview := DoubleOrNothing.play_round(cr.get_current_seed(), int(cr.get("_gamble_step")))
	var result: StringName = preview["result"]
	if want_win:
		return result
	return &"cigarette" if result == &"alcohol" else &"alcohol"


func _check_win_and_loss_math() -> void:
	var cr := await _make_root(true)
	if not await _spin_until_offer(cr):
		_fail("no gamble offer after %d spins" % MAX_SPINS)
		await _free_root(cr)
		return
	var pot := cr.get_gamble_pot()
	var bank := int(cr.get_bankroll())
	var goal := cr.get_chip_bar_goal_progress_cents()
	var pick := _pick_for(cr, true)
	var round_data := cr.gamble(pick)
	if round_data.is_empty() or not bool(round_data["won"]):
		_fail("winning pick did not win")
	var used_before := cr.get_spins_used()
	await cr.spin()
	if cr.get_spins_used() != used_before or cr.get_state() != CombatRoot.State.GAMBLE:
		_fail("a spin ran while the gamble was pending")
	if int(cr.get_bankroll()) != bank:
		_fail("balance moved before settle")
	cr.settle_gamble()
	var mult := DoubleOrNothing.multiplier_for(pick)
	var gain := pot * (mult - 1)
	if cr.get_gamble_pot() != pot * mult:
		_fail("pot after win is %d, want %d" % [cr.get_gamble_pot(), pot * mult])
	if int(cr.get_bankroll()) != bank + gain:
		_fail("balance after win is %d, want %d" % [int(cr.get_bankroll()), bank + gain])
	if cr.get_chip_bar_goal_progress_cents() != goal + gain:
		_fail("goal after win is %d, want %d" % [cr.get_chip_bar_goal_progress_cents(), goal + gain])
	if not cr.has_gamble_offer():
		_fail("offer closed after a win")
	pot = cr.get_gamble_pot()
	bank = int(cr.get_bankroll())
	goal = cr.get_chip_bar_goal_progress_cents()
	cr.gamble(_pick_for(cr, false))
	cr.settle_gamble()
	if cr.has_gamble_offer() or cr.get_gamble_pot() != 0:
		_fail("offer still open after a loss")
	if int(cr.get_bankroll()) != bank - pot:
		_fail("balance after loss is %d, want %d" % [int(cr.get_bankroll()), bank - pot])
	if cr.get_chip_bar_goal_progress_cents() != goal - pot:
		_fail("goal after loss is %d, want %d" % [cr.get_chip_bar_goal_progress_cents(), goal - pot])
	if cr.get_state() != CombatRoot.State.IDLE:
		_fail("state is not IDLE after settle")
	await _free_root(cr)


func _check_goal_waits_for_collect() -> void:
	var cr := await _make_root(true)
	cr.set_goal_base_target_cents(5)
	if not await _spin_until_offer(cr):
		_fail("no offer for the goal test")
		await _free_root(cr)
		return
	if not cr.is_chip_bar_goal_complete():
		_fail("goal test spin did not reach GOAL")
	if cr.is_encounter_complete():
		_fail("fight ended while the offer was open")
	cr.collect_gamble()
	if not cr.is_encounter_complete():
		_fail("fight did not end after collect at GOAL")
	await _free_root(cr)
	cr = await _make_root(true)
	cr.set_goal_base_target_cents(5)
	if await _spin_until_offer(cr):
		var before := cr.get_chip_bar_goal_progress_cents() - cr.get_gamble_pot()
		cr.gamble(_pick_for(cr, false))
		cr.settle_gamble()
		if before < cr.get_chip_bar_goal_target_cents() and cr.is_encounter_complete() and int(cr.get_bankroll()) >= 100:
			_fail("fight ended after losing the gamble below GOAL")
	await _free_root(cr)


func _check_spins_unchanged_by_gamble() -> void:
	var a := await _make_root(true)
	var b := await _make_root(true)
	var got_a := await _spin_until_offer(a)
	var got_b := await _spin_until_offer(b)
	if not got_a or not got_b:
		_fail("no offer for the replay test")
		await _free_root(a)
		await _free_root(b)
		return
	a.gamble(_pick_for(a, false))
	a.settle_gamble()
	b.collect_gamble()
	a.set_bankroll_cents(3000)
	b.set_bankroll_cents(3000)
	await a.spin()
	await b.spin()
	if a.serialize_spin_result() != b.serialize_spin_result():
		_fail("gambling changed the next spin")
	await _free_root(a)
	await _free_root(b)
