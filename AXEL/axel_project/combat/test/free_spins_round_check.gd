extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const GridManagerScript := preload("res://combat/scripts/grid_manager.gd")

const POWER_TOTALS := {
	&"bloody_hand": 4,
	&"alcohol": 5,
	&"cigarette": 8,
}


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await _assert_choice_counters()
	await _assert_dead_board_fires_power()
	await _assert_winning_board_respects_chance()
	await _assert_meter_bonus_updates_counter()
	await _assert_winnings_wait_for_round_end()
	await _assert_vice_winnings_wait()
	await _assert_free_spin_round_plays_itself()
	await _assert_later_free_spin_opens_a_new_grid()
	await _assert_bonus_skull_stays_held()
	print("Free spins round check OK.")
	quit(0)


func _spawn() -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	return cr


func _symbol(cr: CombatRoot, id_name: StringName) -> SymbolDefScript:
	for entry in cr.symbol_resources:
		var sym := entry as SymbolDefScript
		if sym != null and sym.id == id_name:
			return sym
	return null


func _fill(cr: CombatRoot, sym: SymbolDefScript) -> void:
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), sym)


func _checkerboard(cr: CombatRoot) -> void:
	var a := _symbol(cr, &"sym_green_circle")
	var b := _symbol(cr, &"sym_yellow_triangle")
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), a if (x + y) % 2 == 0 else b)


func _snapshot(cr: CombatRoot) -> PackedStringArray:
	var ids := PackedStringArray()
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			ids.append("." if sym == null else String(sym.id))
	return ids


func _open_choice(cr: CombatRoot, seed_value: int) -> void:
	cr.debug_set_guarantee_trinity(false)
	cr.debug_set_guarantee_fs_clear(true)
	cr.debug_set_guarantee_payout_1000x(false)
	cr.set_goal_base_target_cents(1000000)
	cr.setup_new_grid(seed_value)
	cr.spin_sync()
	if cr.get_state() != CombatRoot.State.FREE_SPINS_CHOOSE:
		push_error("Guarantee Free Spins did not open the choice, state %s." % str(cr.get_state()))
		quit(1)


func _assert_choice_counters() -> void:
	var seed_value := 7100
	for power_id in POWER_TOTALS.keys():
		var cr := await _spawn()
		_open_choice(cr, seed_value)
		seed_value += 1
		for y in GridManagerScript.ROWS:
			for x in GridManagerScript.COLS:
				cr.grid.set_cell(Vector2i(x, y), null)
		var before := _snapshot(cr)
		cr.choose_free_spins_power(power_id)
		var after := _snapshot(cr)
		if before == after:
			push_error("%s choice did not build a new grid." % String(power_id))
			quit(1)
			return
		var filled := 0
		for id in after:
			if id != ".":
				filled += 1
		if filled < GridManagerScript.COLS * GridManagerScript.ROWS:
			push_error("%s entry grid was not full." % String(power_id))
			quit(1)
			return
		var want := int(POWER_TOTALS[power_id])
		var counter := cr.get_free_spin_counter()
		if counter != Vector2i(1, want):
			push_error("%s counter is %s, want 1/%d." % [String(power_id), str(counter), want])
			quit(1)
			return
		cr.queue_free()
		await process_frame


func _assert_dead_board_fires_power() -> void:
	var cr := await _spawn()
	_open_choice(cr, 7201)
	cr.choose_free_spins_power(&"bloody_hand")
	cr.girl_power_chance = 0.0
	_checkerboard(cr)
	cr.spin_sync()
	if not bool(cr.get_last_spin_summary().get("power_triggered", false)):
		push_error("A free spin with no winning lines should fire the chosen power.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_winning_board_respects_chance() -> void:
	var quiet := await _spawn()
	_open_choice(quiet, 7301)
	quiet.choose_free_spins_power(&"alcohol")
	quiet.girl_power_chance = 0.0
	_fill(quiet, _symbol(quiet, &"sym_yellow_triangle"))
	quiet.spin_sync()
	if bool(quiet.get_last_spin_summary().get("power_triggered", false)):
		push_error("A winning free spin should not fire the power when the small chance misses.")
		quit(1)
		return
	quiet.queue_free()
	await process_frame

	var lucky := await _spawn()
	_open_choice(lucky, 7302)
	lucky.choose_free_spins_power(&"alcohol")
	lucky.girl_power_chance = 1.0
	_fill(lucky, _symbol(lucky, &"sym_yellow_triangle"))
	lucky.spin_sync()
	if not bool(lucky.get_last_spin_summary().get("power_triggered", false)):
		push_error("A winning free spin should fire the power when the small chance hits.")
		quit(1)
		return
	lucky.queue_free()
	await process_frame


func _assert_meter_bonus_updates_counter() -> void:
	var cr := await _spawn()
	_open_choice(cr, 7401)
	cr.choose_free_spins_power(&"bloody_hand")
	cr.girl_power_chance = 0.0
	_checkerboard(cr)
	var cigarette := _symbol(cr, &"cigarette")
	if cigarette == null:
		push_error("Missing cigarette symbol for the meter bonus.")
		quit(1)
		return
	for x in GridManagerScript.COLS:
		cr.grid.set_cell(Vector2i(x, 0), cigarette)
	cr.spin_sync()
	var counter := cr.get_free_spin_counter()
	if counter != Vector2i(2, 8):
		push_error("Meter fill should make the next spin 2/8, got %s." % str(counter))
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_winnings_wait_for_round_end() -> void:
	var cr := await _spawn()
	_open_choice(cr, 7501)
	cr.choose_free_spins_power(&"cigarette")
	cr.free_spins.spins_remaining = 2
	cr.free_spins.spins_awarded_total = 2
	cr.free_spins.total_spin_cap = 2
	cr.girl_power_chance = 0.0
	cr.set_goal_progress_cents(0)
	var green := _symbol(cr, &"sym_green_circle")
	var yellow := _symbol(cr, &"sym_yellow_triangle")
	_fill(cr, yellow)
	cr.grid.set_cell(Vector2i(0, 2), green)
	cr.grid.set_cell(Vector2i(1, 2), green)
	cr.grid.set_cell(Vector2i(2, 2), green)
	var goal_before := cr.get_chip_bar_goal_progress_cents()
	var bank_before := int(cr.get_bankroll())
	cr.spin_sync()
	var first := int(cr.get_last_spin_summary().get("payout", 0))
	if first <= 0:
		push_error("First free spin paid nothing, so the bar test is empty.")
		quit(1)
		return
	if cr.get_chip_bar_goal_progress_cents() != goal_before:
		push_error("GOAL moved during Free Spins, before the round ended.")
		quit(1)
		return
	if int(cr.get_round_winnings()) != first:
		push_error("Winnings bar %d did not keep the first free spin %d." % [int(cr.get_round_winnings()), first])
		quit(1)
		return
	if int(cr.get_bankroll()) != bank_before + first:
		push_error("Balance should still rise on each free spin.")
		quit(1)
		return
	cr.spin_sync()
	var second := int(cr.get_last_spin_summary().get("payout", 0))
	var bar := int(cr.get_round_winnings())
	if cr.free_spins.active:
		push_error("Free Spins should end after the last counted spin.")
		quit(1)
		return
	if bar != first + second:
		push_error("Winnings bar %d should be both free spins %d." % [bar, first + second])
		quit(1)
		return
	if cr.get_chip_bar_goal_progress_cents() != goal_before + bar:
		push_error("GOAL should receive the whole Free Spin bar when the round ends.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_bonus_skull_stays_held() -> void:
	var cr := await _spawn()
	cr.setup_new_grid(7801)
	if cr.is_bonus_skull_held():
		push_error("The full skull should not be locked before Vice Round.")
		quit(1)
		return
	cr._in_trinity_round = true
	if not cr.is_bonus_skull_held():
		push_error("The full skull should stay locked during Vice Round.")
		quit(1)
		return
	cr._in_trinity_round = false
	cr._awaiting_free_spin_choice = true
	if not cr.is_bonus_skull_held():
		push_error("The full skull should stay locked on the power choice.")
		quit(1)
		return
	cr._awaiting_free_spin_choice = false
	cr.free_spins.start_with_power(&"alcohol")
	if not cr.is_bonus_skull_held():
		push_error("The full skull should stay locked during Free Spins.")
		quit(1)
		return
	cr.free_spins.reset()
	if cr.is_bonus_skull_held():
		push_error("The skull should follow the meter again after Free Spins.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spin_round_plays_itself() -> void:
	var cr := await _spawn()
	_open_choice(cr, 7701)
	cr.choose_free_spins_power(&"bloody_hand")
	cr.free_spins.spins_remaining = 2
	cr.free_spins.spins_awarded_total = 2
	cr.free_spins.total_spin_cap = 2
	cr.girl_power_chance = 0.0
	cr.set_bankroll_cents(0)
	cr.set_goal_progress_cents(0)
	var green := _symbol(cr, &"sym_green_circle")
	var yellow := _symbol(cr, &"sym_yellow_triangle")
	_fill(cr, yellow)
	cr.grid.set_cell(Vector2i(0, 0), green)
	cr.grid.set_cell(Vector2i(1, 0), green)
	cr.grid.set_cell(Vector2i(2, 0), green)
	cr.run_free_spin_round_sync()
	if cr.free_spins.active:
		push_error("Free Spins should finish without another Execute press.")
		quit(1)
		return
	if cr.free_spins.spins_remaining != 0:
		push_error("Both free spins should have played, %d left." % cr.free_spins.spins_remaining)
		quit(1)
		return
	var bar := int(cr.get_round_winnings())
	if bar <= 0:
		push_error("Automatic Free Spins paid nothing.")
		quit(1)
		return
	if cr.get_chip_bar_goal_progress_cents() != bar:
		push_error("Automatic Free Spins should add the bar to GOAL at the end.")
		quit(1)
		return
	if int(cr.get_bankroll()) != bar:
		push_error("Automatic Free Spins should pay the balance even with no chips left to bet.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_later_free_spin_opens_a_new_grid() -> void:
	var cr := await _spawn()
	_open_choice(cr, 7901)
	cr.choose_free_spins_power(&"bloody_hand")
	cr.free_spins.spins_remaining = 2
	cr.free_spins.spins_awarded_total = 2
	cr.girl_power_chance = 0.0
	_fill(cr, _symbol(cr, &"sym_yellow_triangle"))
	var before_spin := _snapshot(cr)
	cr.spin_sync()
	var first := cr.get_last_spin_summary()
	if bool(first.get("free_spin_opened_fresh", false)):
		push_error("The first free spin should use the board from the power choice.")
		quit(1)
		return
	if bool(first.get("power_triggered", false)):
		push_error("A winning first free spin should not fire when the small chance misses.")
		quit(1)
		return
	var after_first := _snapshot(cr)
	if after_first == before_spin:
		push_error("Spin 1 should change the board so the leftover is visible.")
		quit(1)
		return
	var holes := 0
	for id in after_first:
		if id == ".":
			holes += 1
	if holes <= 0:
		push_error("Spin 1 should leave empty cells.")
		quit(1)
		return
	cr.spin_sync()
	var second := cr.get_last_spin_summary()
	if not bool(second.get("free_spin_opened_fresh", false)):
		push_error("The second free spin should open a new grid.")
		quit(1)
		return
	var open_ids := str(second.get("free_spin_open_ids", ""))
	var open_parts := open_ids.split("|")
	if open_parts.size() != GridManagerScript.COLS * GridManagerScript.ROWS:
		push_error("Second free spin open snapshot is the wrong size.")
		quit(1)
		return
	for id in open_parts:
		if id == "." or id.is_empty():
			push_error("Second free spin should open on a full grid.")
			quit(1)
			return
	if open_ids == "|".join(after_first):
		push_error("Second free spin reused the leftover grid.")
		quit(1)
		return
	var had_lines := bool(second.get("free_spin_open_had_lines", false))
	var fired := bool(second.get("power_triggered", false))
	if had_lines and fired:
		push_error("A winning later free spin should not fire the power when the small chance misses.")
		quit(1)
		return
	if not had_lines and not fired:
		push_error("A later free spin with no winning lines should fire the chosen power.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_vice_winnings_wait() -> void:
	var cr := await _spawn()
	cr.setup_new_grid(7601)
	cr.set_goal_base_target_cents(1000000)
	cr.set_goal_progress_cents(0)
	var green := _symbol(cr, &"sym_green_circle")
	var yellow := _symbol(cr, &"sym_yellow_triangle")
	_fill(cr, yellow)
	cr.grid.set_cell(Vector2i(0, 1), green)
	cr.grid.set_cell(Vector2i(1, 1), green)
	cr.grid.set_cell(Vector2i(2, 1), green)
	cr._begin_vice_winnings_hold()
	cr._resolve_cascade_loop_sync()
	var bar := int(cr.get_round_winnings())
	if bar <= 0:
		push_error("Vice Round test line paid nothing.")
		quit(1)
		return
	if cr.get_chip_bar_goal_progress_cents() != 0:
		push_error("GOAL moved before the Vice Round ended.")
		quit(1)
		return
	cr._finish_trinity_round()
	if cr.get_chip_bar_goal_progress_cents() != bar:
		push_error("GOAL should receive the Vice Round bar when Vice ends.")
		quit(1)
		return
	cr.queue_free()
	await process_frame
