extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	if not OS.is_debug_build():
		print("Dev tools check skipped (not a debug build).")
		quit(0)
		return
	var cr := await _spawn()
	_check_economy(cr)
	_check_switches(cr)
	_check_skip_gate(cr)
	_check_free_spins(cr)
	var payout := await _spawn()
	_check_payout(payout)
	if _failures.is_empty():
		print("Dev tools check OK.")
		quit(0)
	else:
		for msg in _failures:
			push_error("dev_tools_check: %s" % msg)
		quit(1)


func _spawn() -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	return cr


func _check_economy(cr: CombatRoot) -> void:
	cr.set_bankroll_cents(4321)
	if int(cr.get_bankroll()) != 4321:
		_fail("bankroll setter did not stick, got %s" % str(cr.get_bankroll()))
	cr.set_goal_base_target_cents(2500)
	if cr.get_goal_base_target_cents() != 2500:
		_fail("goal base setter did not stick")
	cr.set_goal_progress_cents(400)
	if cr.get_chip_bar_goal_progress_cents() != 400:
		_fail("goal progress setter did not stick")


func _check_switches(cr: CombatRoot) -> void:
	cr.debug_set_guarantee_trinity(true)
	cr.debug_set_guarantee_fs_clear(false)
	if not cr.debug_get_guarantee_trinity() or cr.debug_get_guarantee_fs_clear():
		_fail("Vice Round switch did not stay separate from Free Spins")
	cr.debug_set_guarantee_trinity(false)
	cr.debug_set_guarantee_fs_clear(true)
	if cr.debug_get_guarantee_trinity() or not cr.debug_get_guarantee_fs_clear():
		_fail("Free Spins switch flipped the Vice Round switch")
	cr.debug_set_guarantee_payout_1000x(true)
	if not cr.debug_get_guarantee_payout_1000x():
		_fail("1000x payout switch did not stick")
	cr.debug_set_guarantee_payout_1000x(false)


func _check_skip_gate(cr: CombatRoot) -> void:
	cr._state = CombatRoot.State.IDLE
	cr._dev_skip_visuals = false
	cr.debug_skip_current_loop()
	if cr._dev_skip_visuals:
		_fail("skip ran while no spin was in progress")
	cr._state = CombatRoot.State.SPINNING
	cr.debug_skip_current_loop()
	if not cr._dev_skip_visuals:
		_fail("skip did nothing during a spin")
	cr._dev_skip_visuals = false
	cr._state = CombatRoot.State.IDLE


func _check_free_spins(cr: CombatRoot) -> void:
	cr.debug_set_guarantee_trinity(false)
	cr.debug_set_guarantee_fs_clear(true)
	cr.debug_set_guarantee_payout_1000x(false)
	cr.setup_new_grid(4242)
	cr.spin_sync()
	if cr.debug_get_guarantee_trinity():
		_fail("Free Spins guarantee turned on the Vice Round switch")
	if cr._state != CombatRoot.State.FREE_SPINS_CHOOSE:
		_fail("next spin did not open Free Spins, state %s" % str(cr._state))


func _check_payout(cr: CombatRoot) -> void:
	cr.debug_set_guarantee_fs_clear(false)
	cr.debug_set_guarantee_trinity(false)
	cr.debug_set_guarantee_payout_1000x(true)
	cr.setup_new_grid(5150)
	var before := int(cr.get_bankroll())
	cr.spin_sync()
	var stake := int(round(cr.total_bet))
	var forced := int(round(1000.0 * cr.total_bet))
	var got := int(cr.get_bankroll())
	if got != before - stake + forced:
		_fail("1000x payout landed on %d, want %d" % [got, before - stake + forced])
