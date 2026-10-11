extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const GridManagerScript := preload("res://combat/scripts/grid_manager.gd")
const LineDetectorScript := preload("res://combat/scripts/line_detector.gd")


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_assert_line_detector_finds_row_and_column()
	await _assert_default_girl_power_chance_is_one_percent()
	await _assert_rotation_only_advances_on_activation()
	await _assert_regular_start_girl_power_advances_rotation()
	await _assert_bloody_hand_changes_full_symbol_set()
	await _assert_alcohol_adds_one_or_two_wilds()
	await _assert_wild_spawn_only_on_3_line()
	await _assert_premium_meter_signal_timing_and_sections()
	await _assert_premium_meter_updates_on_wild_assisted_booze_line()
	await _assert_paid_spin_resets_meter_before_next_spin()
	await _assert_trinity_transition_completes_without_freeze()
	await _assert_paid_spin_cascade_has_gravity_but_no_spawned_symbols()
	await _assert_trinity_round_has_gravity_but_no_spawned_symbols()
	await _assert_trinity_cascade_settles_floating_without_wins()
	await _assert_begin_next_encounter_applies_seed()
	await _assert_free_spins_does_not_refill_from_top()
	await _assert_trinity_entry_repopulates_grid()
	await _assert_uc_grants_extra_trinity_spin_only_on_first_miss()
	await _assert_super_fs_entry_repopulates_grid()
	await _assert_super_fs_spin_does_not_repopulate_at_start()
	await _assert_free_spins_non_wild_clear_counts_as_grid_clear()
	await _assert_free_spins_forces_all_three_powers_once()
	await _assert_bankroll_empty_encounter_fail()
	await _assert_bankroll_is_not_capped()
	await _assert_live_spin_budget_does_not_end_fight()
	await _assert_trinity_with_chips_does_not_end()
	await _assert_free_spin_choice_does_not_end()
	await _assert_tutorial_last_spin_lock_pays_goal()
	await _assert_goal_credits_full_round_winnings()
	print("Powers check OK.")
	quit(0)


func _spawn_root() -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	return cr


func _await_combat_ready(cr: Node) -> void:
	if not cr.is_node_ready():
		await cr.ready


func _symbol_by_id(cr: CombatRoot, id_name: StringName) -> SymbolDefScript:
	for r in cr.symbol_resources:
		var sym := r as SymbolDefScript
		if sym != null and sym.id == id_name:
			return sym
	return null


func _set_checkerboard_no_clusters(cr: CombatRoot) -> void:
	var a := _symbol_by_id(cr, &"sym_green_circle")
	var b := _symbol_by_id(cr, &"sym_yellow_triangle")
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), a if (x + y) % 2 == 0 else b)


func _count_wilds(cr: CombatRoot) -> int:
	var count := 0
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			if sym != null and sym.tier == SymbolDefScript.Tier.WILD:
				count += 1
	return count


func _snapshot_ids(cr: CombatRoot) -> PackedStringArray:
	var ids := PackedStringArray()
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			ids.append("." if sym == null else String(sym.id))
	return ids


func _assert_line_detector_finds_row_and_column() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(999)
	_set_checkerboard_no_clusters(cr)
	var a := _symbol_by_id(cr, &"sym_green_circle")
	cr.grid.set_cell(Vector2i(0, 0), a)
	cr.grid.set_cell(Vector2i(1, 0), a)
	cr.grid.set_cell(Vector2i(2, 0), a)
	cr.grid.set_cell(Vector2i(0, 1), a)
	cr.grid.set_cell(Vector2i(0, 2), a)
	var lines: Array = LineDetectorScript.find_lines(cr.grid.cells)
	if lines.size() < 2:
		push_error("Expected horizontal + vertical lines from run-length scan.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_default_girl_power_chance_is_one_percent() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	if not is_equal_approx(cr.girl_power_chance, 0.01):
		push_error("Default girl_power_chance should be 0.01 (1%%).")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_regular_start_girl_power_advances_rotation() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.encounter_def = null
	cr.setup_new_grid(1011)
	_set_checkerboard_no_clusters(cr)
	cr.powers.set_current_id(&"bloody_hand")
	cr.girl_power_chance = 1.0
	cr.spin_sync()
	if cr.get_power_current_id() != &"alcohol":
		push_error("Start-of-spin Girl Power at 100%% should advance bloody hand -> alcohol.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_rotation_only_advances_on_activation() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1001)
	cr.powers.set_current_id(&"bloody_hand")

	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if cr.get_power_current_id() != &"bloody_hand":
		push_error("Power advanced despite failed girl power roll.")
		quit(1)
		return
	cr.powers.advance_rotation()
	if cr.get_power_current_id() != &"alcohol":
		push_error("Power advance_rotation() should move bloody_hand -> alcohol.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_bloody_hand_changes_full_symbol_set() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1003)
	_set_checkerboard_no_clusters(cr)
	cr.powers.set_current_id(&"bloody_hand")
	var counts_before: Dictionary = {}
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			if sym == null:
				continue
			if sym.tier == SymbolDefScript.Tier.WILD or sym.tier == SymbolDefScript.Tier.HAZARD:
				continue
			var sid: StringName = sym.id
			counts_before[sid] = int(counts_before.get(sid, 0)) + 1
	cr.debug_trigger_power()
	var counts_after: Dictionary = {}
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym2: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			if sym2 == null:
				continue
			if sym2.tier == SymbolDefScript.Tier.WILD or sym2.tier == SymbolDefScript.Tier.HAZARD:
				continue
			var sid2: StringName = sym2.id
			counts_after[sid2] = int(counts_after.get(sid2, 0)) + 1

	var cleared_a_type := false
	for sid in counts_before.keys():
		var before_n: int = int(counts_before[sid])
		if before_n <= 0:
			continue
		var after_n: int = int(counts_after.get(sid, 0))
		if after_n == 0:
			cleared_a_type = true
			break
	if not cleared_a_type:
		push_error("Bloody hand should fully remove one present symbol type from the grid (full-set conversion).")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_wild_spawn_only_on_3_line() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1005)
	_set_checkerboard_no_clusters(cr)
	var a := _symbol_by_id(cr, &"sym_green_circle")

	cr.grid.set_cell(Vector2i(0, 0), a)
	cr.grid.set_cell(Vector2i(1, 0), a)
	cr.grid.set_cell(Vector2i(2, 0), a)
	cr._resolve_cascade_loop_sync()
	var line_wilds := _count_wilds(cr)
	if line_wilds < 1:
		push_error("Expected at least one wild spawn from a length-3 line.")
		quit(1)
		return
	var cr2 := _spawn_root()
	await _await_combat_ready(cr2)
	cr2.setup_new_grid(1006)
	_set_checkerboard_no_clusters(cr2)
	cr2.grid.set_cell(Vector2i(0, 0), a)
	cr2.grid.set_cell(Vector2i(1, 0), a)
	cr2.grid.set_cell(Vector2i(2, 0), a)
	cr2.grid.set_cell(Vector2i(3, 0), a)
	cr2.grid.set_cell(Vector2i(4, 0), a)
	cr2._resolve_cascade_loop_sync()
	var line5_wilds := _count_wilds(cr2)
	if line5_wilds > line_wilds:
		push_error("5-line should not create additional wild spawn behavior.")
		quit(1)
		return
	cr.queue_free()
	cr2.queue_free()
	await process_frame


func _assert_alcohol_adds_one_or_two_wilds() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1004)
	_set_checkerboard_no_clusters(cr)
	cr.powers.set_current_id(&"alcohol")
	var before := _count_wilds(cr)
	cr.debug_trigger_power()
	var after := _count_wilds(cr)
	var gained := after - before
	if gained < 1 or gained > 2:
		push_error("Alcohol expected wild gain in [1,2], got %d." % gained)
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_premium_meter_signal_timing_and_sections() -> void:
	var booze_id := &"booze"


	var cr3 := _spawn_root()
	await _await_combat_ready(cr3)
	cr3.setup_new_grid(2100)
	_set_checkerboard_no_clusters(cr3)
	var booze3 := _symbol_by_id(cr3, booze_id)
	if booze3 == null:
		push_error("Missing booze symbol for premium meter signal test.")
		quit(1)
		return
	cr3.grid.set_cell(Vector2i(0, 0), booze3)
	cr3.grid.set_cell(Vector2i(1, 0), booze3)
	cr3.grid.set_cell(Vector2i(2, 0), booze3)
	var x3_event := {
		"prev": -1,
		"next": -1,
		"clear": false,
	}
	cr3.premium_meter_changed.connect(func(previous_sections: int, next_sections: int) -> void:
		x3_event["prev"] = previous_sections
		x3_event["next"] = next_sections
		x3_event["clear"] = cr3.grid.get_cell(Vector2i(0, 0)) == null
	)
	var lines3: Array = LineDetectorScript.find_lines(cr3.grid.cells)
	cr3._resolve_lines_sync(lines3)
	var x3_prev: int = int(x3_event["prev"])
	var x3_next: int = int(x3_event["next"])
	if x3_prev != 0 or x3_next != 1:
		push_error("Expected premium_meter_changed 0->1 for x3 premium line, got %d->%d." % [x3_prev, x3_next])
		quit(1)
		return
	if not bool(x3_event["clear"]):
		push_error("Expected premium meter signal to fire at symbol-clear timing.")
		quit(1)
		return
	if cr3.get_meter_sections_filled() != 1:
		push_error("Expected x3 premium line to fill exactly 1 meter section.")
		quit(1)
		return


	var cr4 := _spawn_root()
	await _await_combat_ready(cr4)
	cr4.setup_new_grid(2101)
	_set_checkerboard_no_clusters(cr4)
	var booze4 := _symbol_by_id(cr4, booze_id)
	cr4.grid.set_cell(Vector2i(0, 0), booze4)
	cr4.grid.set_cell(Vector2i(1, 0), booze4)
	cr4.grid.set_cell(Vector2i(2, 0), booze4)
	cr4.grid.set_cell(Vector2i(3, 0), booze4)
	var lines4: Array = LineDetectorScript.find_lines(cr4.grid.cells)
	cr4._resolve_lines_sync(lines4)
	if cr4.get_meter_sections_filled() != 2:
		push_error("Expected x4 premium line to fill exactly 2 meter sections.")
		quit(1)
		return


	var cr5 := _spawn_root()
	await _await_combat_ready(cr5)
	cr5.setup_new_grid(2102)
	_set_checkerboard_no_clusters(cr5)
	var booze5 := _symbol_by_id(cr5, booze_id)
	cr5.grid.set_cell(Vector2i(0, 0), booze5)
	cr5.grid.set_cell(Vector2i(1, 0), booze5)
	cr5.grid.set_cell(Vector2i(2, 0), booze5)
	cr5.grid.set_cell(Vector2i(3, 0), booze5)
	cr5.grid.set_cell(Vector2i(4, 0), booze5)
	var lines5: Array = LineDetectorScript.find_lines(cr5.grid.cells)
	cr5._resolve_lines_sync(lines5)
	if cr5.get_meter_sections_filled() != 3:
		push_error("Expected x5 premium line to fill exactly 3 meter sections.")
		quit(1)
		return

	cr3.queue_free()
	cr4.queue_free()
	cr5.queue_free()
	await process_frame


func _assert_premium_meter_updates_on_wild_assisted_booze_line() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1542)
	_set_checkerboard_no_clusters(cr)
	var wild := _symbol_by_id(cr, &"sym_satanic")
	var booze := _symbol_by_id(cr, &"booze")
	if wild == null or booze == null:
		push_error("Missing wild or booze symbol for premium meter test.")
		quit(1)
		return
	cr.grid.set_cell(Vector2i(0, 0), wild)
	cr.grid.set_cell(Vector2i(1, 0), wild)
	cr.grid.set_cell(Vector2i(2, 0), booze)
	var readout_events := {"count": 0}
	cr.readouts_progressed.connect(func() -> void:
		readout_events["count"] = int(readout_events["count"]) + 1
	)
	cr._resolve_cascade_loop_sync()
	if cr.get_meter_sections_filled() < 1:
		push_error("Expected wild-assisted booze line to add at least one premium meter section.")
		quit(1)
		return
	if int(readout_events["count"]) <= 0:
		push_error("Expected readouts_progressed during premium meter update.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_paid_spin_resets_meter_before_next_spin() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1600)
	cr.meter.sections_filled = 2
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if cr.get_meter_sections_filled() != 0:
		push_error("Expected paid spin to reset premium meter before next execute.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_trinity_transition_completes_without_freeze() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3657)
	_set_checkerboard_no_clusters(cr)
	cr.girl_power_chance = 0.0
	cr.meter.sections_filled = 3
	cr._pending_free_spins = true
	cr.pause_at_spin_start_sec = 0.01
	cr.pause_after_cluster_resolve_sec = 0.01
	cr.pause_after_gravity_refill_sec = 0.01
	cr.pause_after_power_sec = 0.01
	cr.grid_flash_duration_sec = 0.05
	cr.grid_flash_count = 2
	cr.grid_border_pulse_duration_sec = 0.03
	cr.meter_handoff_pause_sec = 0.01
	cr.free_spin_handoff_pause_sec = 0.01
	cr._dev_skip_visuals = true
	var spin_done := {"value": false}
	cr.spin_finished.connect(func() -> void:
		spin_done["value"] = true
	)
	cr.spin()
	var max_frames := 600
	while not bool(spin_done["value"]) and max_frames > 0:
		max_frames -= 1
		await process_frame
	if not bool(spin_done["value"]):
		push_error("Vice Round transition appears frozen: spin did not complete in allotted frames.")
		quit(1)
		return
	if not cr.is_waiting_for_free_spin_choice():
		push_error("Expected FREE_SPINS_CHOOSE state after pending free-spin handoff.")
		quit(1)
		return
	cr.choose_free_spins_power(&"cigarette")
	if not cr.free_spins.active:
		push_error("Expected free spins to activate after choosing a power.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_paid_spin_cascade_has_gravity_but_no_spawned_symbols() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(2488)
	_set_checkerboard_no_clusters(cr)
	var a := _symbol_by_id(cr, &"sym_green_circle")
	if a == null:
		push_error("Missing symbol for paid-spin gravity/no-spawn test.")
		quit(1)
		return

	cr.grid.set_cell(Vector2i(0, 2), a)
	cr.grid.set_cell(Vector2i(1, 2), a)
	cr.grid.set_cell(Vector2i(2, 2), a)
	for y in range(3, GridManagerScript.ROWS):
		cr.grid.set_cell(Vector2i(0, y), null)
		cr.grid.set_cell(Vector2i(1, y), null)
		cr.grid.set_cell(Vector2i(2, y), null)
	var fell_events := {"count": 0}
	var spawn_events := {"count": 0}
	cr.grid.symbols_fell.connect(func(_moves: Array) -> void:
		fell_events["count"] = int(fell_events["count"]) + 1
	)
	cr.grid.symbols_spawned.connect(func(_spawns: Array) -> void:
		spawn_events["count"] = int(spawn_events["count"]) + 1
	)
	cr._resolve_cascade_loop_sync()
	if int(fell_events["count"]) <= 0:
		push_error("Paid spin cascade should allow symbols to fall via gravity.")
		quit(1)
		return
	if int(spawn_events["count"]) != 0:
		push_error("Paid spin cascade should not spawn new symbols from the top.")
		quit(1)
		return
	var empties_after := 0
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			if cr.grid.get_cell(Vector2i(x, y)) == null:
				empties_after += 1
	if empties_after <= 0:
		push_error("Paid spin cascade should leave empty cells after gravity-only settle.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_trinity_round_has_gravity_but_no_spawned_symbols() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(2491)
	_set_checkerboard_no_clusters(cr)
	cr.girl_power_chance = 0.0
	cr._in_trinity_round = true
	var a := _symbol_by_id(cr, &"sym_green_circle")
	if a == null:
		push_error("Missing symbol for trinity gravity/no-spawn test.")
		quit(1)
		return


	cr.grid.set_cell(Vector2i(0, 2), a)
	cr.grid.set_cell(Vector2i(1, 2), a)
	cr.grid.set_cell(Vector2i(2, 2), a)
	for y in range(3, GridManagerScript.ROWS):
		cr.grid.set_cell(Vector2i(0, y), null)
		cr.grid.set_cell(Vector2i(1, y), null)
		cr.grid.set_cell(Vector2i(2, y), null)
	var fell_events := {"count": 0}
	var spawn_events := {"count": 0}
	cr.grid.symbols_fell.connect(func(_moves: Array) -> void:
		fell_events["count"] = int(fell_events["count"]) + 1
	)
	cr.grid.symbols_spawned.connect(func(_spawns: Array) -> void:
		spawn_events["count"] = int(spawn_events["count"]) + 1
	)
	cr._resolve_trinity_cascade_loop_sync()
	if int(fell_events["count"]) <= 0:
		push_error("Vice Round should allow symbols to fall via gravity.")
		quit(1)
		return
	if int(spawn_events["count"]) != 0:
		push_error("Vice Round cascade should not spawn new symbols from the top.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_trinity_cascade_settles_floating_without_wins() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(7777)
	_set_checkerboard_no_clusters(cr)
	var lines: Array = LineDetectorScript.find_lines(cr.grid.cells)
	if not lines.is_empty():
		push_error("Vice Round floating-symbol test setup should not contain winning lines.")
		quit(1)
		return

	cr.grid.set_cell(Vector2i(0, 0), _symbol_by_id(cr, &"sym_green_circle"))
	for y in range(1, GridManagerScript.ROWS):
		cr.grid.set_cell(Vector2i(0, y), null)
	if not cr._grid_has_floating_symbols():
		push_error("Vice Round floating-symbol test setup should contain floating symbols.")
		quit(1)
		return
	var fell_events := {"count": 0}
	var spawn_events := {"count": 0}
	cr.grid.symbols_fell.connect(func(_moves: Array) -> void:
		fell_events["count"] = int(fell_events["count"]) + 1
	)
	cr.grid.symbols_spawned.connect(func(_spawns: Array) -> void:
		spawn_events["count"] = int(spawn_events["count"]) + 1
	)
	cr._resolve_trinity_cascade_loop_sync()
	if int(fell_events["count"]) <= 0:
		push_error("Vice Round cascade should settle floating symbols even without winning lines.")
		quit(1)
		return
	if int(spawn_events["count"]) != 0:
		push_error("Vice Round cascade gravity-only settle should not spawn symbols from the top.")
		quit(1)
		return
	if cr._grid_has_floating_symbols():
		push_error("Vice Round cascade should leave no floating symbols after gravity settle.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_begin_next_encounter_applies_seed() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(100)
	var grid_a := _snapshot_ids(cr)
	cr.end_encounter(true)
	cr.begin_next_playtest_encounter(200)
	if cr.get_current_seed() != 200:
		push_error("begin_next_playtest_encounter should apply the requested seed.")
		quit(1)
		return
	var grid_b := _snapshot_ids(cr)
	if grid_a == grid_b:
		push_error("Different encounter seeds should produce different starting grids.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_bankroll_empty_encounter_fail() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	var goal: Resource = load("res://combat/scripts/goal_payout_threshold.gd").new()
	goal.set("display_text", "Payout")
	goal.set("target_payout", 9999)
	var enc: Resource = load("res://combat/scripts/encounter.gd").new()
	enc.set("goal", goal)
	cr.encounter_def = enc
	cr.setup_new_grid(2001)
	cr._bankroll_cents = 0
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if not cr.is_encounter_complete():
		push_error("Encounter should complete when bankroll cannot afford another paid spin.")
		quit(1)
		return
	if cr.did_win_encounter():
		push_error("Encounter incorrectly marked as win.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_bankroll_is_not_capped() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.restore_run_bankroll(2500)
	if int(cr.get_bankroll()) != 2500:
		push_error("Balance must keep chips above 1000.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_live_spin_budget_does_not_end_fight() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(4101)
	cr.restore_run_bankroll(1000)
	cr.set_limit_spins(false)
	cr.set_spin_budget(10)
	cr.set_spins_used(10)
	cr.set_goal_base_target_cents(50000)
	cr.set_goal_progress_cents(0)
	if cr.is_encounter_complete():
		push_error("Live fight must not end at spin_budget when Limit spins is off.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_trinity_with_chips_does_not_end() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(4102)
	cr.restore_run_bankroll(500)
	cr._in_trinity_round = true
	cr.set_limit_spins(true)
	cr.set_spin_budget(10)
	cr.set_spins_used(10)
	cr.set_goal_base_target_cents(50000)
	cr._finalize_encounter_if_needed()
	if cr.is_encounter_complete():
		push_error("Vice Round with chips left must not dump the fight.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spin_choice_does_not_end() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(4103)
	cr.restore_run_bankroll(0)
	cr._awaiting_free_spin_choice = true
	cr._state = CombatRoot.State.FREE_SPINS_CHOOSE
	cr._finalize_encounter_if_needed()
	if cr.is_encounter_complete():
		push_error("Free Spins choice must not finalize the fight.")
		quit(1)
		return
	if cr.get_state() != CombatRoot.State.FREE_SPINS_CHOOSE:
		push_error("Free Spins choice state was lost.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spins_forces_all_three_powers_once() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3001)
	cr.free_spins.start_with_power(&"bloody_hand")
	cr.free_spins.spins_remaining = 0
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"bloody_hand")
	cr.free_spins.consume_spin()
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"alcohol")
	cr.free_spins.consume_spin()
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"cigarette")
	cr.free_spins.consume_spin()
	if cr.free_spins.active:
		push_error("Free Spins should end after all three one-time powers have been used and no spins remain.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spins_does_not_refill_from_top() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3010)
	_set_checkerboard_no_clusters(cr)
	var a := _symbol_by_id(cr, &"sym_green_circle")
	cr.grid.set_cell(Vector2i(0, 4), a)
	cr.grid.set_cell(Vector2i(1, 4), a)
	cr.grid.set_cell(Vector2i(2, 4), a)
	for y in GridManagerScript.ROWS - 1:
		cr.grid.set_cell(Vector2i(0, y), null)
		cr.grid.set_cell(Vector2i(1, y), null)
		cr.grid.set_cell(Vector2i(2, y), null)
	cr.free_spins.start_with_power(&"bloody_hand")
	cr._resolve_cascade_loop_sync()
	var empties_after := 0
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			if cr.grid.get_cell(Vector2i(x, y)) == null:
				empties_after += 1
	if empties_after <= 0:
		push_error("SUPER Free Spins cascade should not refill from top; expected empty cells after resolve.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_trinity_entry_repopulates_grid() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3658)
	_set_checkerboard_no_clusters(cr)
	cr.girl_power_chance = 0.0
	cr.meter.sections_filled = 3
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			if (x + y) % 3 == 0:
				cr.grid.set_cell(Vector2i(x, y), _symbol_by_id(cr, &"sym_green_circle"))
	var before_trinity := _snapshot_ids(cr)
	cr._run_trinity_round_sync()
	var after_trinity := _snapshot_ids(cr)
	if before_trinity == after_trinity:
		push_error("Vice Round entry should repopulate a fresh grid after meter-full handoff.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_uc_grants_extra_trinity_spin_only_on_first_miss() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1)
	var uc: Resource = load("res://combat/data/items/U-C_trinity_matchbook.tres")
	if uc == null:
		push_error("U-C_trinity_matchbook.tres missing.")
		quit(1)
		return
	if not cr.equip_item(uc):
		push_error("Failed to equip U-C.")
		quit(1)
		return
	_set_checkerboard_no_clusters(cr)
	if cr._trinity_first_miss_extra_spin_count() != 1:
		push_error("U-C should grant +1 extra Vice Round spin when the opening board has no matches.")
		quit(1)
		return
	var before_extra := _snapshot_ids(cr)
	var extra_out: Dictionary = cr._empty_spin_summary()
	cr._grant_trinity_first_miss_extra_spins_sync(extra_out)
	if before_extra == _snapshot_ids(cr):
		push_error("U-C extra Vice Round spin should fill a new board when the first spin misses.")
		quit(1)
		return
	var green := _symbol_by_id(cr, &"sym_green_circle")
	for x in GridManagerScript.COLS:
		cr.grid.set_cell(Vector2i(x, 0), green)
	if cr._trinity_first_miss_extra_spin_count() != 0:
		push_error("U-C should not grant an extra Vice Round spin when the opening board already matches.")
		quit(1)
		return
	cr.unequip_item(uc)
	_set_checkerboard_no_clusters(cr)
	if cr._trinity_first_miss_extra_spin_count() != 0:
		push_error("Opening Vice Round miss should not grant an extra spin without U-C.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_super_fs_entry_repopulates_grid() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3021)
	_set_checkerboard_no_clusters(cr)
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), null)
	var before_choice := _snapshot_ids(cr)
	cr._pending_free_spins = true
	cr._awaiting_free_spin_choice = true
	cr._state = cr.State.FREE_SPINS_CHOOSE
	cr.choose_free_spins_power(&"alcohol")
	var after_choice := _snapshot_ids(cr)
	if before_choice == after_choice:
		push_error("Super Free Spins entry should repopulate a fresh grid after power choice.")
		quit(1)
		return
	var filled := 0
	for id in after_choice:
		if id != ".":
			filled += 1
	if filled < GridManagerScript.COLS * GridManagerScript.ROWS:
		push_error("Super Free Spins entry repopulate should fill the full grid.")
		quit(1)
		return
	if not cr.free_spins.active:
		push_error("Super Free Spins should be active after power choice.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_super_fs_spin_does_not_repopulate_at_start() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3020)
	_set_checkerboard_no_clusters(cr)
	cr._pending_free_spins = true
	cr._awaiting_free_spin_choice = true
	cr._state = cr.State.FREE_SPINS_CHOOSE
	cr.choose_free_spins_power(&"bloody_hand")
	var before := _snapshot_ids(cr)
	cr._begin_spin_round()
	var after := _snapshot_ids(cr)
	if before != after:
		push_error("The first free spin should keep the grid from the power choice.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spins_non_wild_clear_counts_as_grid_clear() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3030)
	_set_checkerboard_no_clusters(cr)
	var wild := _symbol_by_id(cr, &"sym_satanic")
	if wild == null:
		push_error("Missing wild symbol for free-spin non-wild clear test.")
		quit(1)
		return
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), wild)
	cr.free_spins.start_with_power(&"bloody_hand")
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if not cr._is_grid_cleared_for_current_mode():
		push_error("Free Spins should mark grid_cleared when only wild symbols remain.")
		quit(1)
		return
	var summary := cr.get_last_spin_summary()
	if int(summary.get("clear_bonus_payout", 0)) != 0:
		push_error("Grid clear paid a bonus of %d." % int(summary.get("clear_bonus_payout", 0)))
		quit(1)
		return
	if int(summary.get("payout", 0)) != int(summary.get("line_payout", 0)):
		push_error(
			"Grid clear added extra winnings: payout %d, line wins %d."
			% [int(summary.get("payout", 0)), int(summary.get("line_payout", 0))]
		)
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_tutorial_last_spin_lock_pays_goal() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	var lock_seed := int(cr.get_tutorial_last_spin_seed())
	cr.set_tutorial_last_spin_lock(true)
	cr.set_equipped_items([])
	cr.set_limit_spins(false)
	cr.setup_new_grid(1)
	cr.set_goal_base_target_cents(100)
	cr.set_goal_progress_cents(0)
	cr.set_bet_index(0)
	cr.restore_run_bankroll(100)
	if not cr.is_last_affordable_paid_spin():
		push_error("Last 100-chip spin should count as last affordable paid spin.")
		quit(1)
		return
	cr.spin_sync()
	var p100 := int(cr.get_last_spin_summary().get("payout", 0))
	if p100 < 100:
		push_error("Tutorial last-spin seed %d paid %d at bet 100, need >= 100." % [lock_seed, p100])
		quit(1)
		return
	if not cr.did_win_encounter():
		push_error("Tutorial last-spin at bet 100 should win from real matches.")
		quit(1)
		return
	cr.setup_new_grid(1)
	cr.set_goal_base_target_cents(100)
	cr.set_goal_progress_cents(0)
	cr.set_bet_index(cr.get_bet_ladder().size() - 1)
	cr.restore_run_bankroll(1000)
	if not cr.is_last_affordable_paid_spin():
		push_error("All-in 1000/1000 should count as last affordable paid spin.")
		quit(1)
		return
	cr.spin_sync()
	var p_all := int(cr.get_last_spin_summary().get("payout", 0))
	if p_all < 100:
		push_error("Tutorial all-in seed %d paid %d, need >= 100." % [lock_seed, p_all])
		quit(1)
		return
	if not cr.did_win_encounter():
		push_error("Tutorial all-in should win from real matches.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_goal_credits_full_round_winnings() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.set_tutorial_last_spin_lock(true)
	cr.set_equipped_items([])
	cr.set_limit_spins(false)
	cr.setup_new_grid(1)
	cr.set_goal_base_target_cents(10000)
	cr.set_goal_progress_cents(89)
	cr.set_bet_index(0)
	cr.restore_run_bankroll(100)
	var bet := int(round(cr.total_bet))
	cr.spin_sync()
	var payout := int(cr.get_last_spin_summary().get("payout", 0))
	var bar := int(cr.get_round_winnings())
	var goal := int(cr.get_chip_bar_goal_progress_cents())
	if payout <= 0:
		push_error("Goal-credit spin paid 0; need a real payout.")
		quit(1)
		return
	if bar != payout:
		push_error("Spin bar %d should match payout %d." % [bar, payout])
		quit(1)
		return
	if goal != 89 + payout:
		push_error("GOAL should be 89 + full payout %d, got %d." % [payout, goal])
		quit(1)
		return
	if bet > 0 and goal == 89 + payout - bet:
		push_error("GOAL subtracted the bet (%d); it must add the full payout." % bet)
		quit(1)
		return
	if cr.did_win_encounter():
		push_error("High target should not win from the credit-only spin.")
		quit(1)
		return
	cr.setup_new_grid(1)
	cr.set_goal_base_target_cents(100)
	cr.set_goal_progress_cents(89)
	cr.set_bet_index(0)
	cr.restore_run_bankroll(100)
	cr.spin_sync()
	if not cr.did_win_encounter():
		push_error("89 plus a paying spin should meet a 100 GOAL.")
		quit(1)
		return
	cr.queue_free()
	await process_frame
