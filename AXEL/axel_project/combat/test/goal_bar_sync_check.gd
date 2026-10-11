extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const POPUP_CENTS := 37

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("goal_bar_sync_check: could not load combat test")
		quit(1)
		return
	var ui := packed.instantiate()
	root.add_child(ui)
	for _i in 30:
		await process_frame
	var combat = ui.get("combat")
	if combat == null:
		_fail("CombatRoot missing")
		_finish()
		return
	await _check_popup_moves_goal(ui, combat)
	await _check_late_popup_never_overshoots(ui, combat)
	_check_spins_match_truth(ui, combat)
	_finish()


func _check_popup_moves_goal(ui: Node, combat: Node) -> void:
	ui.call("_reset_winnings_counter_display")
	var goal_start := int(combat.call("get_chip_bar_goal_progress_cents"))
	if _shown_goal(ui) != goal_start:
		_fail("goal readout %d does not start at %d" % [_shown_goal(ui), goal_start])
	combat.call("_add_round_winnings", POPUP_CENTS)
	ui.call("_refresh_readouts")
	if _shown_goal(ui) != goal_start:
		_fail("goal readout %d ran ahead of the bar before the popup (start %d)" % [_shown_goal(ui), goal_start])
	ui.call("_on_winnings_popup_border_touched", {"payout_cents": POPUP_CENTS})
	var saw_mid := false
	for _i in 600:
		await process_frame
		var bar := _shown_bar(ui)
		if _shown_goal(ui) != goal_start + bar:
			_fail("goal %d does not move with the bar %d (start %d)" % [_shown_goal(ui), bar, goal_start])
			return
		if bar > 0 and bar < POPUP_CENTS:
			saw_mid = true
		if bar >= POPUP_CENTS and not bool(ui.get("_winnings_counter_running")):
			break
	if _shown_bar(ui) != POPUP_CENTS:
		_fail("bar ended at %d, want %d" % [_shown_bar(ui), POPUP_CENTS])
	if not saw_mid:
		_fail("bar never counted through the middle")
	ui.call("_sync_winnings_counter_to_combat_truth")
	if _shown_goal(ui) != int(combat.call("get_chip_bar_goal_progress_cents")):
		_fail("goal readout did not snap back to the real goal")


func _check_late_popup_never_overshoots(ui: Node, combat: Node) -> void:
	ui.call("_reset_winnings_counter_display")
	combat.call("_add_round_winnings", POPUP_CENTS)
	ui.call("_sync_winnings_counter_to_combat_truth")
	var truth := int(combat.call("get_chip_bar_goal_progress_cents"))
	var shown_before := _shown_goal(ui)
	if shown_before != truth:
		_fail("goal readout %d after sync, real goal %d" % [shown_before, truth])
	ui.call("_on_winnings_popup_border_touched", {"payout_cents": POPUP_CENTS})
	for _i in 120:
		await process_frame
		ui.call("_refresh_readouts")
		if _shown_goal(ui) > truth:
			_fail("late popup pushed goal readout to %d above real goal %d" % [_shown_goal(ui), truth])
			return
		if _shown_bar(ui) > int(combat.call("get_round_winnings")):
			_fail("late popup pushed bar to %d above real bar %d" % [_shown_bar(ui), int(combat.call("get_round_winnings"))])
			return
	ui.call("_on_spin_started", 1)
	ui.call("_refresh_readouts")
	if _shown_goal(ui) < shown_before:
		_fail("goal readout dropped from %d to %d at next spin" % [shown_before, _shown_goal(ui)])


func _check_spins_match_truth(ui: Node, combat: Node) -> void:
	for i in 6:
		var goal_before := int(combat.call("get_chip_bar_goal_progress_cents"))
		combat.call("spin_sync")
		ui.call("_on_spin_finished")
		ui.call("_refresh_readouts")
		var goal_after := int(combat.call("get_chip_bar_goal_progress_cents"))
		var round_total := int(combat.call("get_round_winnings"))
		var summary: Dictionary = combat.call("get_last_spin_summary")
		var payout := int(summary.get("payout", 0))
		if goal_after - goal_before != payout:
			_fail("spin %d: goal moved %d but the spin paid %d" % [i, goal_after - goal_before, payout])
		if round_total != payout and not bool(combat.free_spins.active):
			_fail("spin %d: bar total %d but the spin paid %d" % [i, round_total, payout])
		if _shown_goal(ui) != goal_after:
			_fail("spin %d: goal readout %d, real goal %d" % [i, _shown_goal(ui), goal_after])
		if _shown_bar(ui) != round_total:
			_fail("spin %d: bar readout %d, real bar %d" % [i, _shown_bar(ui), round_total])
		if bool(combat.call("is_encounter_complete")):
			break


func _shown_goal(ui: Node) -> int:
	var label := ui.get("goal_label") as Label
	if label == null:
		return -1
	var text := label.text.replace("GOAL:", "").strip_edges()
	var slash := text.find("/")
	if slash < 0:
		return -1
	return int(text.substr(0, slash).strip_edges())


func _shown_bar(ui: Node) -> int:
	var label := ui.get("mult_label") as Label
	if label == null:
		return -1
	return int(label.text.strip_edges())


func _fail(msg: String) -> void:
	_failures.append(msg)


func _finish() -> void:
	if _failures.is_empty():
		print("Goal bar sync check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error(msg)
	quit(1)
