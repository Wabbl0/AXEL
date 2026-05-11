extends SceneTree
## Deterministic synergy smoke test for multi-item stacking and inventory constraints.
## Verifies payout scalar math, equip limits, slot-expander behavior, and loadout
## determinism across identical seeds.
##
## Run:
## tools/cmd/godot.cmd --path AXEL/axel_project --headless -s res://combat/test/item_synergy_smoke.gd

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
