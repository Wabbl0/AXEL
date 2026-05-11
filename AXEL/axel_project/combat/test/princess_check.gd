extends SceneTree
## Run: godot --path AXEL/axel_project --headless -s res://combat/test/princess_check.gd

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
	await _assert_love_changes_full_symbol_set()
	await _assert_star_adds_one_or_two_wilds()
	await _assert_wild_spawn_only_on_3_line()
	await _assert_premium_meter_signal_timing_and_sections()
	await _assert_premium_meter_updates_on_wild_assisted_booze_line()
	await _assert_paid_spin_resets_meter_before_next_spin()
	await _assert_trinity_transition_completes_without_freeze()
	await _assert_trinity_round_has_gravity_but_no_spawned_symbols()
	await _assert_free_spins_does_not_refill_from_top()
	await _assert_free_spins_spin_preserves_existing_grid()
	await _assert_free_spins_non_wild_clear_counts_as_grid_clear()
	await _assert_free_spins_forces_all_three_powers_once()
	await _assert_goal_budget_win_or_fail()
	print("Princess check OK.")
	quit(0)


func _spawn_root() -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	return cr


## Godot 4: awaiting `ready` after the node is already ready never resumes.
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
	cr.princesses.set_current_id(&"love")
	cr.girl_power_chance = 1.0
	cr.spin_sync()
	if cr.get_princess_current_id() != &"star":
		push_error("Start-of-spin Girl Power at 100%% should advance love -> star.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_rotation_only_advances_on_activation() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1001)
	cr.princesses.set_current_id(&"love")
	# Rotation should be stable unless explicitly advanced by gameplay.
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if cr.get_princess_current_id() != &"love":
		push_error("Princess advanced despite failed girl power roll.")
		quit(1)
		return
	cr.princesses.advance_rotation()
	if cr.get_princess_current_id() != &"star":
		push_error("Princess advance_rotation() should move love -> star.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_love_changes_full_symbol_set() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1003)
	_set_checkerboard_no_clusters(cr)
	cr.princesses.set_current_id(&"love")
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
	# Love picks a random present symbol id and replaces every cell of that id (full-set conversion).
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
		push_error("Love should fully remove one present symbol type from the grid (full-set conversion).")
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
	# Exactly three in a row => one line of length 3 => wild at middle cell.
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


func _assert_star_adds_one_or_two_wilds() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1004)
	_set_checkerboard_no_clusters(cr)
	cr.princesses.set_current_id(&"star")
	var before := _count_wilds(cr)
	cr.debug_trigger_power()
	var after := _count_wilds(cr)
	var gained := after - before
	if gained < 1 or gained > 2:
		push_error("Star expected wild gain in [1,2], got %d." % gained)
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_premium_meter_signal_timing_and_sections() -> void:
	var booze_id := &"booze"

	# x3 premium line: signal should fire at resolve clear-time and add 1 section.
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

	# x4 premium line should fill 2 sections.
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

	# x5 premium line should fill 3 sections (cap/full).
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
		push_error("Trinity transition appears frozen: spin did not complete in allotted frames.")
		quit(1)
		return
	if not cr.is_waiting_for_free_spin_choice():
		push_error("Expected FREE_SPINS_CHOOSE state after pending free-spin handoff.")
		quit(1)
		return
	cr.choose_free_spins_princess(&"storm")
	if not cr.free_spins.active:
		push_error("Expected free spins to activate after choosing princess.")
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
	# Seed one 3-line in the middle with symbols above and empty space below.
	# After clear, upper symbols must fall down (gravity) but no spawns are allowed.
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
		push_error("Regular Free Spins (Trinity Run) should allow symbols to fall via gravity.")
		quit(1)
		return
	if int(spawn_events["count"]) != 0:
		push_error("Regular Free Spins (Trinity Run) should not spawn new symbols.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_goal_budget_win_or_fail() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	var goal: Resource = load("res://combat/scripts/goal_payout_threshold.gd").new()
	goal.set("display_text", "Payout")
	goal.set("target_payout", 9999)
	var enc: Resource = load("res://combat/scripts/encounter.gd").new()
	enc.set("goal", goal)
	enc.set("spin_budget", 1)
	cr.encounter_def = enc
	cr.setup_new_grid(2001)
	_set_checkerboard_no_clusters(cr)
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if not cr.is_encounter_complete():
		push_error("Encounter should complete after hitting spin budget.")
		quit(1)
		return
	if cr.did_win_encounter():
		push_error("Encounter incorrectly marked as win.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spins_forces_all_three_powers_once() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3001)
	cr.free_spins.start_with_princess(&"love")
	cr.free_spins.spins_remaining = 0
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"love")
	cr.free_spins.consume_spin()
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"star")
	cr.free_spins.consume_spin()
	cr.free_spins.ensure_end_guard_spin()
	cr.free_spins.mark_power_used_once(&"storm")
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
	cr.free_spins.start_with_princess(&"love")
	cr._resolve_cascade_loop_sync()
	var empties_after := 0
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			if cr.grid.get_cell(Vector2i(x, y)) == null:
				empties_after += 1
	if empties_after <= 0:
		push_error("Free Spins should not refill from top; expected empty cells after resolve.")
		quit(1)
		return
	cr.queue_free()
	await process_frame


func _assert_free_spins_spin_preserves_existing_grid() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(3020)
	_set_checkerboard_no_clusters(cr)
	cr.free_spins.start_with_princess(&"love")
	cr.free_spins.mark_power_used_once(&"love")
	cr.free_spins.mark_power_used_once(&"star")
	cr.free_spins.mark_power_used_once(&"storm")
	var before := _snapshot_ids(cr)
	cr.spin_sync()
	var after := _snapshot_ids(cr)
	if before != after:
		push_error("Free Spins should not repopulate a fresh grid at spin start.")
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
	cr.free_spins.start_with_princess(&"love")
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if not cr._is_grid_cleared_for_current_mode():
		push_error("Free Spins should mark grid_cleared when only wild symbols remain.")
		quit(1)
		return
	cr.queue_free()
	await process_frame
