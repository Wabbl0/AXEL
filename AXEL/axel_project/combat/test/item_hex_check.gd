extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const ITEM_PATHS: Array[String] = [
	"res://combat/data/items/C1_ash_spin_token.tres",
	"res://combat/data/items/C2_chalk_dust.tres",
	"res://combat/data/items/C-A_echo_splinter.tres",
]
const SEED := 4242
const SPINS := 30
const BIG_GOAL := 1000000000
const BIG_BANKROLL := 100000000

var _failures: int = 0


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	_test_table()
	_test_masks()
	_test_param_scaling()
	await _test_no_hex_matches_plain()
	await _test_repeatable()
	await _test_sleep()
	await _test_fickle()
	if _failures > 0:
		push_error("Item hex check FAILED (%d)." % _failures)
		quit(1)
		return
	print("Item hex check OK.")
	quit(0)


func _assert(cond: bool, label: String) -> void:
	if cond:
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _run() -> Node:
	return root.get_node_or_null("AxelRun")


func _test_table() -> void:
	var run := _run()
	run.call("reset_run")
	run.state.seed = 777
	var table: Dictionary = run.call("hex_table")
	_assert(table.size() == 9, "hex table covers the nine families")
	for family in table.keys():
		var row: Dictionary = table[family]
		_assert(String(row["target"]) != String(family), "family %s never hexes itself" % family)
		_assert(["weak", "fickle", "wildless", "jammed", "sleep"].has(String(row["hex"])), "family %s has a known hex" % family)
		_assert(["ash", "heavy_meter", "thin_wallet"].has(String(row["curse"])), "family %s has a light curse" % family)
	_assert((run.call("hex_table") as Dictionary) == table, "hex table is the same for the same seed")
	var differs := false
	for s in range(778, 800):
		run.state.seed = s
		if (run.call("hex_table") as Dictionary) != table:
			differs = true
			break
	_assert(differs, "hex table changes between seeds")
	run.state.seed = 777
	_assert((run.call("hex_for_item", "R-A") as Dictionary).is_empty(), "Rare items carry no hex")
	_assert((run.call("hex_for_item", "E1") as Dictionary).is_empty(), "numbered items carry no hex")
	var epic: Dictionary = run.call("hex_for_item", "E-A")
	_assert(not epic.is_empty() and not epic.has("curse"), "Epic carries a hex and no curse")
	var legend: Dictionary = run.call("hex_for_item", "L-A")
	_assert(not legend.is_empty() and legend.has("curse"), "Legendary carries a hex and a curse")
	_assert(String(run.call("hex_text", "L-A")).begins_with("Hex: "), "hex text starts with Hex:")
	_assert(String(run.call("hex_text", "C-A")) == "", "Common shows no hex text")


func _test_masks() -> void:
	var run := _run()
	run.state.seed = 777
	var hex: Dictionary = run.call("hex_for_item", "E-A")
	var target := String(hex["target"])
	var victim := "U-%s" % target
	var masks: Dictionary = run.call("hex_masks", ["E-A", victim, "C1"])
	_assert(masks.has(StringName(victim)), "equipped target-family item gets a mask")
	_assert(not masks.has(&"C1"), "numbered item is never hexed")
	_assert(not masks.has(&"E-A"), "the hexer is not hexed by itself")
	var none: Dictionary = run.call("hex_masks", [victim])
	_assert(none.is_empty(), "no Epic equipped means no hex")
	var curses: Array = run.call("legendary_fight_curses", ["L-A", "E-B"])
	_assert(curses.size() == 1, "only the Legendary adds a light fight curse")


func _test_param_scaling() -> void:
	var weak := ItemEffectDispatcher.weaken_params({"chance": 0.2, "cells": 3, "mult_min": 2.5, "mode": "major", "full_lines": true}, 0.5)
	_assert(is_equal_approx(float(weak["chance"]), 0.1), "Weak halves a chance")
	_assert(int(weak["cells"]) == 1, "Weak floors an int, min 1")
	_assert(is_equal_approx(float(weak["mult_min"]), 1.75), "Weak halves the bonus part of a multiplier")
	_assert(String(weak["mode"]) == "major" and bool(weak["full_lines"]), "Weak keeps structural params")
	var bare := ItemEffectDispatcher.strip_wilds({"mode": "all", "wilds": true, "wild_lengths": [4]})
	_assert(not bool(bare["wilds"]) and (bare["wild_lengths"] as Array).is_empty(), "Wildless strips wild making")


func _items() -> Array:
	var out: Array = []
	for path in ITEM_PATHS:
		var item := load(path)
		if item != null:
			out.append(item)
	return out


func _make(masks: Variant) -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.set_equipped_items(_items())
	if masks is Dictionary:
		cr.set_item_hexes(masks)
	cr.set_goal_base_target_cents(BIG_GOAL)
	cr.setup_new_grid(SEED)
	cr.restore_run_bankroll(BIG_BANKROLL)
	return cr


func _spin_once(cr: CombatRoot) -> void:
	if cr.is_waiting_for_free_spin_choice():
		cr.choose_free_spins_power(&"cigarette")
		cr.run_free_spin_round_sync()
		return
	cr.spin_sync()


func _log(masks: Variant) -> Array:
	var cr := await _make(masks)
	var entries: Array = []
	for i in SPINS:
		if cr.is_encounter_complete():
			break
		_spin_once(cr)
		entries.append([cr.serialize_spin_result(), int(cr.get_bankroll()), str(cr.get_jammed_item_ids())])
	cr.queue_free()
	await process_frame
	await process_frame
	return entries


func _test_no_hex_matches_plain() -> void:
	var plain := await _log(null)
	var empty := await _log({})
	_assert(plain == empty, "an empty hex list plays exactly like no hexes")


func _test_repeatable() -> void:
	var masks := {&"C-A": {"fickle": 0.5, "potency": 0.5}}
	var a := await _log(masks)
	var b := await _log(masks)
	_assert(a == b, "the same hexes on the same seed give the same fight")


func _test_sleep() -> void:
	var cr := await _make({&"C-A": {"sleep_spins": 3}})
	var asleep := 0
	var awake_later := true
	for i in 6:
		if cr.is_waiting_for_free_spin_choice():
			break
		cr.spin_sync()
		var jammed := str(cr.get_jammed_item_ids())
		if i < 3 and jammed.contains("C-A"):
			asleep += 1
		if i >= 3 and jammed.contains("C-A"):
			awake_later = false
	_assert(asleep == 3, "Sleep keeps the item off for the first 3 paid spins (got %d)" % asleep)
	_assert(awake_later, "Sleep ends after 3 paid spins")
	cr.queue_free()
	await process_frame


func _test_fickle() -> void:
	var cr := await _make({&"C-A": {"fickle": 0.5}})
	var off := 0
	var on := 0
	for i in SPINS:
		if cr.is_encounter_complete():
			break
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_power(&"cigarette")
			cr.run_free_spin_round_sync()
			continue
		cr.spin_sync()
		if str(cr.get_jammed_item_ids()).contains("C-A"):
			off += 1
		else:
			on += 1
	_assert(off > 0 and on > 0, "Fickle switches the item off on some spins only (off %d, on %d)" % [off, on])
	cr.queue_free()
	await process_frame
