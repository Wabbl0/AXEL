extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const PlayerItemPanelScript := preload("res://combat/scripts/player_item_panel.gd")
const DispatcherScript := preload("res://combat/scripts/item_effect_dispatcher.gd")
const GridManagerScript := preload("res://combat/scripts/grid_manager.gd")
const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const ITEMS_DIR := "res://combat/data/items/"
const WINDOW := Vector2i(1920, 1280)
const ENCOUNTERS := 12
const SPINS_PER_ENCOUNTER := 25
const BANKROLL := 100000000
const FS_POWERS: Array[StringName] = [&"bloody_hand", &"alcohol", &"cigarette"]
const SKIP := {
	"extra_inventory_slots": "only adds loadout slots, nothing to show in a fight",
}

var _verbose := false
var _async := false


class CountingDispatcher:
	extends "res://combat/scripts/item_effect_dispatcher.gd"
	var counts: Dictionary = {}

	func note_proc(item: Resource) -> void:
		if item != null:
			var item_id := str(item.get("id"))
			counts[item_id] = int(counts.get(item_id, 0)) + 1
		super.note_proc(item)


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = WINDOW
	var args := OS.get_cmdline_user_args()
	_verbose = args.has("--verbose")
	_async = args.has("--async")
	var only := ""
	for a in args:
		if a.begins_with("--only="):
			only = a.substr(7)
	var fails := PackedStringArray()
	await _check_c6_repro(fails)
	await _check_pending_pulse(fails)
	var items := _discover_items()
	var rows: Array = []
	for item in items:
		if only != "" and str(item.get("id")) != only:
			continue
		rows.append(await _sweep_item(item))
	_print_table(rows)
	for r in rows:
		if r["status"] == "SKIP":
			continue
		if r["status"] == "NO PULSE":
			fails.append("%s %s procced %d times but pulsed %d" % [r["id"], r["name"], r["procs"], r["pulses"]])
		elif r["status"] == "NEVER":
			fails.append("%s %s never activated in %d spins" % [r["id"], r["name"], r["spins"]])
	if fails.is_empty():
		print("Item proc check OK (%d items)." % rows.size())
		quit(0)
		return
	for msg in fails:
		push_error("item_proc_check: %s" % msg)
	quit(1)


func _discover_items() -> Array:
	var out: Array = []
	var names := PackedStringArray()
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		var fname := f.trim_suffix(".remap")
		if fname.ends_with(".tres") or fname.ends_with(".res"):
			names.append(fname)
	names.sort()
	for fname in names:
		var res := load(ITEMS_DIR + fname)
		if res != null and str(res.get("id")) != "":
			out.append(res)
	return out


func _spawn(item: Resource) -> Dictionary:
	var host := Control.new()
	host.name = "ItemProcHost"
	host.size = Vector2(WINDOW)
	root.add_child(host)
	current_scene = host
	var cr: CombatRoot = CombatRootScene.instantiate()
	host.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var dispatcher := CountingDispatcher.new()
	cr._item_fx = dispatcher
	var panel_host := Control.new()
	panel_host.size = Vector2(700, 900)
	host.add_child(panel_host)
	var panel := PlayerItemPanelScript.new()
	panel_host.add_child(panel)
	if not panel.is_node_ready():
		await panel.ready
	cr.set_ignore_slot_cap(true)
	cr.set_equipped_items([item] if item != null else [])
	panel.set_equipped_items([item] if item != null else [])
	return {"host": host, "cr": cr, "panel": panel, "fx": dispatcher}


func _despawn(ctx: Dictionary) -> void:
	var host: Node = ctx["host"]
	current_scene = null
	host.queue_free()
	await process_frame


func _fresh_encounter(cr: CombatRoot, seed_value: int) -> void:
	cr.set_goal_base_target_cents(BANKROLL)
	cr.setup_new_grid(seed_value)
	cr.restore_run_bankroll(BANKROLL)


func _one_spin(cr: CombatRoot) -> void:
	if _async:
		await cr.spin()
	else:
		cr.spin_sync()


func _force_state(cr: CombatRoot, effect: String) -> void:
	if effect == "free_spins":
		cr._pending_free_spins = true
		cr._awaiting_free_spin_choice = true
		cr._state = CombatRoot.State.FREE_SPINS_CHOOSE
	elif effect == "trinity_echo":
		cr.girl_power_chance = 1.0


func _sweep_item(item: Resource) -> Dictionary:
	var item_id := str(item.get("id"))
	var effect := str(item.get("effect_id"))
	if SKIP.has(effect):
		return {
			"id": item_id,
			"name": str(item.get("display_name")),
			"effect": effect,
			"spins": 0,
			"first": -1,
			"procs": 0,
			"pulses": 0,
			"status": "SKIP",
			"note": SKIP[effect],
		}
	var ctx: Dictionary = await _spawn(item)
	var cr: CombatRoot = ctx["cr"]
	var panel = ctx["panel"]
	var fx: CountingDispatcher = ctx["fx"]
	var spins := 0
	var first_spin := -1
	var fs_pick := 0
	for e in ENCOUNTERS:
		_fresh_encounter(cr, 7000 + e * 131)
		_force_state(cr, effect)
		for _s in SPINS_PER_ENCOUNTER:
			if cr.get_state() == CombatRoot.State.ENDED:
				break
			if cr.get_state() == CombatRoot.State.FREE_SPINS_CHOOSE:
				cr.choose_free_spins_power(FS_POWERS[fs_pick % FS_POWERS.size()])
				fs_pick += 1
				if _async:
					await cr.run_free_spin_round()
				else:
					cr.run_free_spin_round_sync()
				continue
			if cr.get_state() != CombatRoot.State.IDLE:
				break
			await _one_spin(cr)
			spins += 1
			if first_spin < 0 and int(fx.counts.get(item_id, 0)) > 0:
				first_spin = spins
		if first_spin >= 0 and not _verbose:
			break
	var procs := int(fx.counts.get(item_id, 0))
	var pulses := int(panel.pulse_play_count(item_id))
	var status := "OK"
	if procs == 0 and pulses == 0:
		status = "NEVER"
	elif pulses == 0:
		status = "NO PULSE"
	elif procs != pulses:
		status = "MISMATCH"
	await _despawn(ctx)
	return {
		"id": item_id,
		"name": str(item.get("display_name")),
		"effect": str(item.get("effect_id")),
		"spins": spins,
		"first": first_spin,
		"procs": procs,
		"pulses": pulses,
		"status": status,
	}


func _print_table(rows: Array) -> void:
	print("")
	print("%-5s %-26s %-28s %6s %6s %6s  %s" % ["id", "name", "effect", "first", "procs", "pulse", "status"])
	for r in rows:
		print("%-5s %-26s %-28s %6d %6d %6d  %s %s" % [r["id"], r["name"], r["effect"], r["first"], r["procs"], r["pulses"], r["status"], str(r.get("note", ""))])
	var counts := {}
	for r in rows:
		counts[r["status"]] = int(counts.get(r["status"], 0)) + 1
	print("Summary: %s" % str(counts))
	print("")


func _symbol(cr: CombatRoot, id_name: StringName) -> SymbolDefScript:
	for r in cr.symbol_resources:
		var sym := r as SymbolDefScript
		if sym != null and sym.id == id_name:
			return sym
	return null


func _cigarette_symbol(cr: CombatRoot) -> SymbolDefScript:
	for r in cr.symbol_resources:
		var sym := r as SymbolDefScript
		if sym != null and sym.power_id == &"cigarette":
			return sym
	return null


func _checkerboard(cr: CombatRoot) -> void:
	var a := _symbol(cr, &"sym_green_circle")
	var b := _symbol(cr, &"sym_yellow_triangle")
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), a if (x + y) % 2 == 0 else b)


func _check_c6_repro(fails: PackedStringArray) -> void:
	var item := load(ITEMS_DIR + "C6_cigarette_stub.tres")
	if item == null:
		fails.append("C6_cigarette_stub.tres missing")
		return
	for use_wild in [false, true]:
		for use_async in [false, true]:
			var ctx: Dictionary = await _spawn(item)
			var cr: CombatRoot = ctx["cr"]
			var panel = ctx["panel"]
			var fx: CountingDispatcher = ctx["fx"]
			_fresh_encounter(cr, 4242)
			_checkerboard(cr)
			var cig := _cigarette_symbol(cr)
			if cig == null:
				fails.append("no symbol with power_id cigarette")
				await _despawn(ctx)
				return
			cr.grid.set_cell(Vector2i(0, 2), cig)
			cr.grid.set_cell(Vector2i(1, 2), cr.wild_symbol if use_wild else cig)
			cr.grid.set_cell(Vector2i(2, 2), cig)
			var lines: Array = cr._find_lines()
			var cig_lines := 0
			for line in lines:
				if line.get("symbol_id", &"") == cig.id:
					cig_lines += 1
			var before := int(fx.counts.get("C6", 0))
			if use_async:
				await cr._resolve_lines(lines)
			else:
				cr._note_paid_line_procs(lines)
			cr._release_item_pulses()
			var procs := int(fx.counts.get("C6", 0)) - before
			var pulses := int(panel.pulse_play_count("C6"))
			var label := "C6 repro %s line, %s path: lines=%d cig_lines=%d procs=%d pulses=%d" % [
				"wild" if use_wild else "plain", "async" if use_async else "sync", lines.size(), cig_lines, procs, pulses]
			print(label)
			if procs <= 0 or pulses <= 0:
				fails.append(label)
			await _despawn(ctx)


func _check_pending_pulse(fails: PackedStringArray) -> void:
	var item := load(ITEMS_DIR + "C-H_loose_thread.tres")
	var host := Control.new()
	host.size = Vector2(700, 900)
	root.add_child(host)
	var panel := PlayerItemPanelScript.new()
	host.add_child(panel)
	if not panel.is_node_ready():
		await panel.ready
	panel.pulse_item("C-H")
	var early := int(panel.pulse_play_count("C-H"))
	panel.set_equipped_items([item])
	var late := int(panel.pulse_play_count("C-H"))
	print("Pending pulse: before rows=%d after rows=%d" % [early, late])
	if early != 0 or late != 1:
		fails.append("pulse requested before the item row exists should play once the row appears")
	host.queue_free()
	await process_frame
