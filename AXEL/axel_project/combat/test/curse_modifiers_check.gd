extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const FightCursesScript := preload("res://combat/scripts/fight_curses.gd")
const ITEM_PATHS: Array[String] = [
	"res://combat/data/items/C1_ash_spin_token.tres",
	"res://combat/data/items/C2_chalk_dust.tres",
	"res://combat/data/items/C-A_echo_splinter.tres",
]
const SEED := 4242
const SPINS := 40
const BIG_GOAL := 1000000000
const BIG_BANKROLL := 100000000

var _failures: int = 0


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await _test_all_curses_load()
	await _test_no_curse_matches_plain_run()
	await _test_each_curse_repeatable()
	await _test_double_goal()
	await _test_thin_wallet()
	await _test_heavy_meter()
	await _test_ash()
	await _test_short_fuse()
	await _test_no_vice()
	await _test_item_jam()
	await _test_sealed()
	await _test_blind()
	if _failures > 0:
		push_error("Curse modifiers check FAILED (%d)." % _failures)
		quit(1)
		return
	print("Curse modifiers check OK.")
	quit(0)


func _assert(cond: bool, label: String) -> void:
	if cond:
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _items() -> Array:
	var out: Array = []
	for path in ITEM_PATHS:
		var item := load(path)
		if item != null:
			out.append(item)
	return out


func _make(curses: Array, with_items: bool = false) -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.set_fight_curses(curses)
	if with_items:
		cr.set_equipped_items(_items())
	cr.set_goal_base_target_cents(BIG_GOAL)
	cr.setup_new_grid(SEED)
	cr.restore_run_bankroll(BIG_BANKROLL)
	return cr


func _drop(cr: CombatRoot) -> void:
	cr.queue_free()
	await process_frame
	await process_frame


func _spin_once(cr: CombatRoot) -> void:
	if cr.is_waiting_for_free_spin_choice():
		cr.choose_free_spins_power(&"cigarette")
		cr.run_free_spin_round_sync()
		return
	cr.spin_sync()


func _run_log(curses: Array, with_items: bool) -> PackedStringArray:
	var cr := await _make(curses, with_items)
	var entries := PackedStringArray()
	entries.append("sealed=%s" % str(cr.get_sealed_symbol_ids()))
	for i in SPINS:
		if cr.is_encounter_complete():
			break
		_spin_once(cr)
		entries.append("%s|b=%d|g=%d|j=%s|m=%d" % [
			cr.serialize_spin_result(),
			int(cr.get_bankroll()),
			cr.get_chip_bar_goal_progress_cents(),
			str(cr.get_jammed_item_ids()),
			cr.get_meter_sections_filled(),
		])
	await _drop(cr)
	return entries


func _logs_equal(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


func _test_all_curses_load() -> void:
	for curse_id in FightCursesScript.ALL_IDS:
		var def: Resource = FightCursesScript.load_def(curse_id)
		_assert(def != null, "%s.tres loads" % curse_id)
		if def == null:
			continue
		_assert(StringName(def.get("id")) == curse_id, "%s.tres id matches" % curse_id)
		_assert(str(def.get("name")) != "", "%s.tres has a name" % curse_id)
		var text := str(def.call("describe", {"left": 3}))
		_assert(text != "" and not text.contains("{"), "%s description fills every value" % curse_id)


func _test_no_curse_matches_plain_run() -> void:
	var with_empty := await _run_log([], true)
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.set_equipped_items(_items())
	cr.set_goal_base_target_cents(BIG_GOAL)
	cr.setup_new_grid(SEED)
	cr.restore_run_bankroll(BIG_BANKROLL)
	var plain := PackedStringArray()
	plain.append("sealed=%s" % str(cr.get_sealed_symbol_ids()))
	for i in SPINS:
		if cr.is_encounter_complete():
			break
		_spin_once(cr)
		plain.append("%s|b=%d|g=%d|j=%s|m=%d" % [
			cr.serialize_spin_result(),
			int(cr.get_bankroll()),
			cr.get_chip_bar_goal_progress_cents(),
			str(cr.get_jammed_item_ids()),
			cr.get_meter_sections_filled(),
		])
	await _drop(cr)
	_assert(_logs_equal(with_empty, plain), "empty curse list plays exactly like no curses")


func _test_each_curse_repeatable() -> void:
	for curse_id in FightCursesScript.ALL_IDS:
		var curses := [{"id": curse_id}]
		var a := await _run_log(curses, true)
		var b := await _run_log(curses, true)
		_assert(a.size() > 1, "%s plays at least one spin" % curse_id)
		_assert(_logs_equal(a, b), "%s: same seed twice gives the same result" % curse_id)


func _test_double_goal() -> void:
	var cr := await _make([{"id": &"double_goal"}])
	cr.set_goal_base_target_cents(1000)
	_assert(cr.get_effective_goal_target_cents() == 2000, "double_goal doubles the goal (got %d)" % cr.get_effective_goal_target_cents())
	cr.set_fight_curses([])
	_assert(cr.get_effective_goal_target_cents() == 1000, "goal returns to normal without the curse")
	cr.set_fight_curses([{"id": &"double_goal", "params": {"mult": 1.5}}])
	cr.set_goal_base_target_cents(333)
	_assert(cr.get_effective_goal_target_cents() == 500, "goal x1.5 rounds up to the next 5 (got %d)" % cr.get_effective_goal_target_cents())
	await _drop(cr)


func _test_thin_wallet() -> void:
	var cr := await _make([{"id": &"thin_wallet"}])
	cr.set_bet_index(0)
	_assert(is_equal_approx(cr.get_current_bet(), 200.0), "thin_wallet lowest bet is 200 (got %s)" % cr.get_current_bet())
	_assert(is_equal_approx(cr.get_min_bet(), 200.0), "get_min_bet reports 200")
	cr.set_bet_index(4)
	cr.restore_run_bankroll(250)
	cr.spin_sync()
	_assert(is_equal_approx(cr.get_current_bet(), 200.0), "auto-lower stops at 200 (got %s)" % cr.get_current_bet())
	cr.restore_run_bankroll(150)
	cr.spin_sync()
	_assert(cr.is_encounter_complete() and not cr.did_win_encounter(), "fight ends when balance is below 200")
	await _drop(cr)


func _test_heavy_meter() -> void:
	var cr := await _make([{"id": &"heavy_meter"}])
	_assert(cr.get_meter_section_count() == 4, "heavy_meter gives 4 sections")
	cr.meter.reset()
	cr.meter.add_sections(3)
	_assert(not cr.meter.is_full(), "3 of 4 sections is not full")
	cr.meter.add_sections(1)
	_assert(cr.meter.is_full(), "4 of 4 sections is full")
	cr.meter.reset()
	await _drop(cr)
	var plain := await _make([])
	_assert(plain.get_meter_section_count() == 3, "no curse keeps 3 sections")
	await _drop(plain)


func _test_ash() -> void:
	var plain := await _make([])
	var ash := await _make([{"id": &"ash"}])
	var low_id: StringName = plain.low_symbol_pool[0].id
	var prem_id: StringName = plain.premium_symbol_pool[0].id
	var low_line := {"symbol_id": low_id, "length": 5}
	var prem_line := {"symbol_id": prem_id, "length": 5}
	var low_plain: int = plain._line_payout_cents(low_line)
	var low_ash: int = ash._line_payout_cents(low_line)
	_assert(low_plain > 0, "low line pays something")
	_assert(absi(low_ash - int(round(low_plain * 0.75))) <= 1, "ash: low line pays 75%% (%d vs %d)" % [low_ash, low_plain])
	_assert(plain._line_payout_cents(prem_line) == ash._line_payout_cents(prem_line), "ash leaves vice symbols alone")
	await _drop(plain)
	await _drop(ash)


func _test_short_fuse() -> void:
	var cr := await _make([{"id": &"short_fuse", "params": {"spins": 3}}])
	_assert(cr.get_curse_spins_left() == 3, "short_fuse starts with 3 left")
	_assert(cr.get_curse_description(&"short_fuse").contains("3 left"), "description shows spins left")
	var guard := 0
	while not cr.is_encounter_complete() and guard < 60:
		if cr.get_spins_used() == 2:
			_assert(cr.is_curse_last_spin(), "third spin is the last chance")
		_spin_once(cr)
		guard += 1
	_assert(cr.is_encounter_complete(), "short_fuse ends the fight")
	_assert(cr.get_spins_used() == 3, "exactly 3 paid spins used (got %d)" % cr.get_spins_used())
	_assert(not cr.did_win_encounter(), "fight is lost when GOAL is not met")
	_assert(cr.get_curse_spins_left() == 0, "0 spins left at the end")
	await _drop(cr)
	var plain := await _make([])
	_assert(plain.get_curse_spins_left() == -1, "no fuse without the curse")
	await _drop(plain)


func _test_no_vice() -> void:
	var cr := await _make([{"id": &"no_vice"}])
	var fired := [0]
	cr.meter_full_transition_started.connect(func() -> void: fired[0] += 1)
	cr.meter.reset()
	cr.meter.add_sections(9)
	_assert(cr.meter.sections_filled == 2, "no_vice stops the meter one short (got %d)" % cr.meter.sections_filled)
	_assert(not cr.meter.is_full(), "no_vice meter is never full")
	cr.meter.reset()
	cr.debug_set_guarantee_trinity(true)
	for i in 10:
		_spin_once(cr)
	cr.debug_set_guarantee_trinity(false)
	_assert(fired[0] == 0, "no Vice Round starts, even with the dev guarantee")
	_assert(not cr.is_waiting_for_free_spin_choice(), "no Free Spins choice appears")
	await _drop(cr)


func _test_item_jam() -> void:
	var cr := await _make([{"id": &"item_jam"}], true)
	var equipped: Array[StringName] = []
	for item in cr.inventory.items:
		if item != null:
			equipped.append(StringName(str(item.get("id"))))
	_assert(cr.get_jammed_item_ids().is_empty(), "nothing is jammed before the first spin")
	var seen: Dictionary = {}
	for i in 12:
		if cr.is_encounter_complete():
			break
		if cr.is_waiting_for_free_spin_choice():
			_spin_once(cr)
			continue
		cr.spin_sync()
		var jammed := cr.get_jammed_item_ids()
		if cr.free_spins.active:
			continue
		_assert(jammed.size() == 1, "one item is jammed each paid spin (got %d)" % jammed.size())
		if jammed.size() == 1:
			_assert(equipped.has(jammed[0]), "jammed item is equipped")
			seen[jammed[0]] = true
	for item in cr.inventory.items:
		if item != null and cr.get_jammed_item_ids().has(StringName(str(item.get("id")))):
			_assert(cr._item_fx._eff(item) == &"", "jammed item has no effect")
	_assert(seen.size() >= 2, "different items get jammed over a fight")
	await _drop(cr)
	var bare := await _make([{"id": &"item_jam"}])
	bare.spin_sync()
	_assert(bare.get_jammed_item_ids().is_empty(), "item_jam with no items is harmless")
	await _drop(bare)


func _test_sealed() -> void:
	var cr := await _make([{"id": &"sealed"}])
	var sealed := cr.get_sealed_symbol_ids()
	_assert(sealed.size() >= 1 and sealed.size() <= 2, "sealed picks 1-2 symbols (got %d)" % sealed.size())
	for sid in sealed:
		var sd: SymbolDef = cr._symbols_by_id.get(sid, null)
		_assert(sd != null and sd.power_id != &"", "sealed symbol %s is a vice symbol" % sid)
	var leaked := false
	for i in 30:
		if cr.is_encounter_complete():
			break
		_spin_once(cr)
		for sid in sealed:
			if cr.grid.snapshot_ids().split("|").has(String(sid)):
				leaked = true
	_assert(not leaked, "sealed symbols never land on the grid")
	await _drop(cr)
	var counts: Dictionary = {}
	for s in 12:
		var probe: CombatRoot = CombatRootScene.instantiate()
		root.add_child(probe)
		if not probe.is_node_ready():
			await probe.ready
		probe.encounter_def = null
		probe.set_fight_curses([{"id": &"sealed"}])
		probe.setup_new_grid(1000 + s)
		counts[probe.get_sealed_symbol_ids().size()] = true
		await _drop(probe)
	_assert(counts.has(1) and counts.has(2), "different seeds seal 1 or 2 symbols")


func _test_blind() -> void:
	var plain := await _run_log([], true)
	var blind := await _run_log([{"id": &"blind"}], true)
	_assert(_logs_equal(plain, blind), "blind resolves exactly like no curse")
	var cr := await _make([{"id": &"blind"}])
	_assert(cr.is_blind_active(), "blind is active")
	var slot: Node = cr.grid_ui.get_child(0)
	var sym: SymbolDef = cr.low_symbol_pool[0]
	cr._blind_cover_all()
	slot.call("set_symbol", sym)
	_assert(bool(slot.call("is_face_down")), "covered slot is face down")
	var shown: Texture2D = (slot.get("_icon") as TextureRect).texture
	_assert(shown != sym.texture, "face-down slot hides the symbol")
	_assert(slot.call("icon_texture") == sym.texture, "face-down slot still knows its symbol")
	cr._blind_reveal_all()
	_assert(not bool(slot.call("is_face_down")), "reveal turns the slot face up")
	_assert((slot.get("_icon") as TextureRect).texture == sym.texture, "revealed slot shows the symbol")
	cr.spin_sync()
	var any_down := false
	for child in cr.grid_ui.get_children():
		if child.has_method("is_face_down") and bool(child.call("is_face_down")):
			any_down = true
	_assert(not any_down, "every cell is face up after the line check")
	await _drop(cr)
