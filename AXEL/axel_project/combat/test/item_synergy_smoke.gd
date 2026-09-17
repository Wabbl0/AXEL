extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const FS_PICK: StringName = &"storm"
const FIXED_SEED := 42

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await _test_single_item_equip()
	await _test_duplicate_id_rejected()
	await _test_base_slot_limit()
	await _test_slot_expander_dynamic_cap()
	await _test_slot_expander_raises_cap_when_at_base_limit()
	await _test_deterministic_scalar_across_runs()
	await _test_unequip_expander_over_cap_graceful()
	await _test_coexistence_c1_and_l3()
	await _test_family_rank_swap_keeps_index()
	await _test_effects_fire_in_tick_order()
	await _test_ignore_slot_cap()
	await _test_g_bonus_zero_in_trinity_and_fs()
	await _test_h_changes_effective_goal()
	await _test_l_a_absent()
	await _test_set_spins_used_changes_c1_scalar()
	await _test_goal_setters_do_not_reseed()

	print("")
	print("SYNERGY_SMOKE_RESULT pass=%d fail=%d total=%d" % [_pass_count, _fail_count, _pass_count + _fail_count])
	if _fail_count > 0:
		quit(1)
	else:
		quit(0)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		_fail_count += 1
		print("  FAIL: %s" % test_name)


func _test_single_item_equip() -> void:
	print("--- test_single_item_equip ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	var item := _make_mock_item(&"test_c1", "Test C1", 0, &"reroll_payout_scalar", {"per_reroll": 0.06, "cap": 0.36})
	var success: bool = cr.equip_item(item)
	_assert(success, "equip single item succeeds")
	_assert(cr.inventory.size() == 1, "inventory size is 1 after equip")
	_assert(cr.inventory.has_item(&"test_c1"), "inventory has the equipped item id")

	cr.queue_free()
	await process_frame


func _test_duplicate_id_rejected() -> void:
	print("--- test_duplicate_id_rejected ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	var item1 := _make_mock_item(&"dup_test", "Dup A", 0, &"reroll_payout_scalar", {"per_reroll": 0.05, "cap": 0.3})
	var item2 := _make_mock_item(&"dup_test", "Dup B", 0, &"reroll_payout_scalar", {"per_reroll": 0.05, "cap": 0.3})

	cr.equip_item(item1)
	var second: bool = cr.equip_item(item2)
	_assert(not second, "duplicate id rejected")
	_assert(cr.inventory.size() == 1, "still only 1 item after duplicate attempt")

	cr.queue_free()
	await process_frame


func _test_base_slot_limit() -> void:
	print("--- test_base_slot_limit ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	_assert(cr.inventory.get_current_max_slots() == 7, "base max is 7")

	for i in 7:
		var item := _make_mock_item(StringName("slot_%d" % i), "Slot %d" % i, 0, &"noop", {})
		cr.equip_item(item)

	_assert(cr.inventory.size() == 7, "7 items equipped at base cap")

	var overflow := _make_mock_item(&"slot_overflow", "Overflow", 0, &"noop", {})
	var result: bool = cr.equip_item(overflow)
	_assert(not result, "8th item rejected at base cap")
	_assert(cr.inventory.size() == 7, "still 7 after rejection")

	cr.queue_free()
	await process_frame


func _test_slot_expander_dynamic_cap() -> void:
	print("--- test_slot_expander_dynamic_cap ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	var expander := _make_mock_item(&"L3_exp", "Void Satchel", 4, &"extra_inventory_slots", {"bonus_slots": 2})
	cr.equip_item(expander)
	_assert(cr.inventory.get_current_max_slots() == 9, "max slots increased to 9 with expander")

	for i in 8:
		var item := _make_mock_item(StringName("fill_%d" % i), "Fill %d" % i, 0, &"noop", {})
		cr.equip_item(item)

	_assert(cr.inventory.size() == 9, "9 items equipped with expander active")

	var overflow := _make_mock_item(&"fill_overflow", "Overflow", 0, &"noop", {})
	var result: bool = cr.equip_item(overflow)
	_assert(not result, "10th item rejected at expanded cap of 9")

	cr.queue_free()
	await process_frame


func _test_slot_expander_raises_cap_when_at_base_limit() -> void:
	print("--- test_slot_expander_raises_cap_when_at_base_limit ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	for i in 6:
		var item := _make_mock_item(StringName("pre_%d" % i), "Pre %d" % i, 0, &"noop", {})
		cr.equip_item(item)
	_assert(cr.inventory.size() == 6, "6 items pre-equipped")

	var expander := _make_mock_item(&"L3_exp2", "Void Satchel", 4, &"extra_inventory_slots", {"bonus_slots": 2})
	var ok: bool = cr.equip_item(expander)
	_assert(ok, "expander equips as 7th item (within base cap)")
	_assert(cr.inventory.get_current_max_slots() == 9, "max now 9")

	var extra1 := _make_mock_item(&"extra_1", "Extra 1", 0, &"noop", {})
	var extra2 := _make_mock_item(&"extra_2", "Extra 2", 0, &"noop", {})
	cr.equip_item(extra1)
	cr.equip_item(extra2)
	_assert(cr.inventory.size() == 9, "filled to 9 with expander")

	cr.queue_free()
	await process_frame


func _test_deterministic_scalar_across_runs() -> void:
	print("--- test_deterministic_scalar_across_runs ---")
	var results: Array = []

	for run in 2:
		var cr: CombatRoot = CombatRootScene.instantiate()
		root.add_child(cr)
		if not cr.is_node_ready():
			await cr.ready

		var item := _make_mock_item(&"det_c1", "Det C1", 0, &"reroll_payout_scalar", {"per_reroll": 0.06, "cap": 0.36})
		cr.equip_item(item)
		cr.encounter_def = null
		cr.setup_new_grid(FIXED_SEED)

		var payouts: Array[int] = []
		for spin_idx in 10:
			if cr.is_waiting_for_free_spin_choice():
				cr.choose_free_spins_princess(FS_PICK)
			cr.spin_sync()
			var summary := cr.get_last_spin_summary()
			payouts.append(int(summary.get("payout", 0)))

		results.append(payouts)
		cr.queue_free()
		await process_frame

	var match_all := true
	for i in results[0].size():
		if results[0][i] != results[1][i]:
			match_all = false
			break

	_assert(match_all, "identical payouts across two runs with same seed and loadout")


func _test_unequip_expander_over_cap_graceful() -> void:
	print("--- test_unequip_expander_over_cap_graceful ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	var expander := _make_mock_item(&"L3_ue", "Expander", 4, &"extra_inventory_slots", {"bonus_slots": 2})
	cr.equip_item(expander)

	for i in 8:
		var item := _make_mock_item(StringName("ue_%d" % i), "UE %d" % i, 0, &"noop", {})
		cr.equip_item(item)
	_assert(cr.inventory.size() == 9, "9 items before unequip expander")

	cr.unequip_item(expander)
	_assert(cr.inventory.size() == 8, "8 items after unequip expander")
	_assert(cr.inventory.get_current_max_slots() == 7, "max reverts to 7 after expander removed")

	var new_item := _make_mock_item(&"ue_blocked", "Blocked", 0, &"noop", {})
	var result: bool = cr.equip_item(new_item)
	_assert(not result, "equip blocked when over cap after expander removal")

	cr.queue_free()
	await process_frame


func _test_coexistence_c1_and_l3() -> void:
	print("--- test_coexistence_c1_and_l3 ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready

	var c1 := _make_mock_item(&"C1", "Ash Reroll Token", 0, &"reroll_payout_scalar", {"per_reroll": 0.06, "cap": 0.36})
	var l3 := _make_mock_item(&"L3", "Void Satchel", 4, &"extra_inventory_slots", {"bonus_slots": 2})

	cr.equip_item(c1)
	cr.equip_item(l3)
	_assert(cr.inventory.size() == 2, "C1 and L3 coexist")
	_assert(cr.inventory.get_current_max_slots() == 9, "L3 raises cap while C1 equipped")
	_assert(cr.inventory.has_item(&"C1"), "C1 present")
	_assert(cr.inventory.has_item(&"L3"), "L3 present")

	cr.encounter_def = null
	cr.setup_new_grid(FIXED_SEED)
	for spin_idx in 5:
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_princess(FS_PICK)
		cr.spin_sync()
	var summary := cr.get_last_spin_summary()
	_assert(summary != null, "spin summary produced with mixed loadout")

	cr.queue_free()
	await process_frame


func _test_family_rank_swap_keeps_index() -> void:
	print("--- test_family_rank_swap_keeps_index ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var ca := _make_mock_item(&"C-A", "Echo Splinter", 0, &"power_chain", {"chance": 0.2, "potency": 0.25, "other_count": 1})
	ca.family = "A"
	var ua := _make_mock_item(&"U-A", "Echo Fuse", 1, &"power_chain", {"chance": 0.35, "potency": 0.35, "other_count": 1})
	ua.family = "A"
	var c1 := _make_mock_item(&"C1", "Ash Reroll Token", 0, &"reroll_payout_scalar", {"per_reroll": 0.06, "cap": 0.36})
	cr.equip_item(ca)
	cr.equip_item(c1)
	_assert(String(cr.inventory.items[0].id) == "C-A", "family item is index 0")
	var ok: bool = cr.replace_item_at(0, ua)
	_assert(ok, "replace_at succeeded")
	_assert(String(cr.inventory.items[0].id) == "U-A", "rank swap kept index 0")
	_assert(String(cr.inventory.items[1].id) == "C1", "later item stayed at index 1")
	cr.queue_free()
	await process_frame


func _test_effects_fire_in_tick_order() -> void:
	print("--- test_effects_fire_in_tick_order ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var a := _make_mock_item(&"ord_a", "A", 0, &"normal_payout_bonus", {"amount": 0.10})
	var b := _make_mock_item(&"ord_b", "B", 0, &"normal_payout_bonus", {"amount": 0.20})
	cr.equip_item(a)
	cr.equip_item(b)
	_assert(String(cr.inventory.items[0].id) == "ord_a", "first ticked is first")
	_assert(String(cr.inventory.items[1].id) == "ord_b", "second ticked is second")
	cr.queue_free()
	await process_frame


func _test_ignore_slot_cap() -> void:
	print("--- test_ignore_slot_cap ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.set_ignore_slot_cap(true)
	for i in 8:
		cr.equip_item(_make_mock_item(StringName("cap_%d" % i), "Cap %d" % i, 0, &"noop", {}))
	_assert(cr.inventory.size() == 8, "ignore cap allows 8 without L3")
	_assert(cr.inventory.get_current_max_slots() == 7, "displayed max stays 7")
	cr.queue_free()
	await process_frame


func _test_g_bonus_zero_in_trinity_and_fs() -> void:
	print("--- test_g_bonus_zero_in_trinity_and_fs ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var g := _make_mock_item(&"C-G", "Locker Tape", 0, &"sealed_grid", {"payout_bonus": 0.12})
	g.family = "G"
	cr.equip_item(g)
	_assert(cr.get_sealed_grid_payout_bonus() > 0.0, "G bonus on regular spins")
	cr._in_trinity_round = true
	_assert(is_zero_approx(cr.get_sealed_grid_payout_bonus()), "G bonus 0 in Trinity")
	cr._in_trinity_round = false
	cr.free_spins.active = true
	_assert(is_zero_approx(cr.get_sealed_grid_payout_bonus()), "G bonus 0 in Free Spins")
	cr.queue_free()
	await process_frame


func _test_h_changes_effective_goal() -> void:
	print("--- test_h_changes_effective_goal ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.set_goal_base_target_cents(10000)
	_assert(cr.get_effective_goal_target_cents() == 10000, "base effective without H")
	var h := _make_mock_item(&"E-H", "Confession Card", 3, &"true_path_goal", {"goal_percent": 0.25})
	h.family = "H"
	cr.equip_item(h)
	_assert(cr.get_effective_goal_target_cents() == 12500, "H Epic raises effective to 12500")
	cr.queue_free()
	await process_frame


func _test_l_a_absent() -> void:
	print("--- test_l_a_absent ---")
	var found := false
	var dir := DirAccess.open("res://combat/data/items")
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.contains("L-A") or file_name.contains("L_A"):
				found = true
			var res_path := "res://combat/data/items".path_join(file_name)
			if file_name.ends_with(".tres"):
				var res := load(res_path)
				if res != null and str(res.get("id")) == "L-A":
					found = true
			file_name = dir.get_next()
		dir.list_dir_end()
	_assert(not found, "L-A resource absent")


func _test_set_spins_used_changes_c1_scalar() -> void:
	print("--- test_set_spins_used_changes_c1_scalar ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var c1 := _make_mock_item(&"C1", "Ash Reroll Token", 0, &"reroll_payout_scalar", {"per_reroll": 0.06, "cap": 0.36})
	cr.equip_item(c1)
	cr.set_spins_used(6)
	_assert(is_equal_approx(cr.get_item_payout_scalar(), 0.36), "C1 at cap 0.36 without spinning")
	cr.set_spins_used(3)
	_assert(is_equal_approx(cr.get_item_payout_scalar(), 0.18), "C1 +0.18x at 3 used")
	cr.queue_free()
	await process_frame


func _test_goal_setters_do_not_reseed() -> void:
	print("--- test_goal_setters_do_not_reseed ---")
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.setup_new_grid(FIXED_SEED)
	var seed_before := cr.get_current_seed()
	var snap_before := cr.serialize_spin_result()
	cr.set_goal_base_target_cents(8000)
	cr.set_goal_progress_cents(100)
	_assert(cr.get_current_seed() == seed_before, "goal setters do not change seed")
	_assert(cr.serialize_spin_result() == snap_before, "goal setters do not change grid")
	cr.queue_free()
	await process_frame


func _make_mock_item(id: StringName, display_name: String, rarity: int, effect_id: StringName, effect_params: Dictionary) -> Resource:
	var item := ItemDefScript.new()
	item.id = id
	item.display_name = display_name
	item.rarity = rarity as ItemDefScript.Rarity
	item.family = ""
	item.description = ""
	item.effect_id = effect_id
	item.effect_params = effect_params
	return item
