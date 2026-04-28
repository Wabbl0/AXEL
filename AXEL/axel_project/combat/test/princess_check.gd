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
	await _assert_rotation_only_advances_on_activation()
	await _assert_love_changes_full_symbol_set()
	await _assert_star_adds_one_or_two_wilds()
	await _assert_wild_spawn_only_on_3_line()
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


func _assert_rotation_only_advances_on_activation() -> void:
	var cr := _spawn_root()
	await _await_combat_ready(cr)
	cr.setup_new_grid(1001)
	_set_checkerboard_no_clusters(cr)
	cr.princesses.set_current_id(&"love")
	cr.girl_power_chance = 0.0
	cr.spin_sync()
	if cr.get_princess_current_id() != &"love":
		push_error("Princess advanced despite failed girl power roll.")
		quit(1)
		return
	cr.girl_power_chance = 1.0
	cr.spin_sync()
	if cr.get_princess_current_id() != &"star":
		push_error("Princess did not advance after successful activation.")
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
	cr.girl_power_chance = 0.0
	cr.spin_sync()
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
	cr2.girl_power_chance = 0.0
	cr2.spin_sync()
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
