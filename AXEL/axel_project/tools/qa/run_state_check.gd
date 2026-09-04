extends SceneTree
## Phase 2: RunState serialize, locker stash, lore bonus, acts, tombstone.

func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var run := root.get_node_or_null("AxelRun")
	var saves := root.get_node_or_null("AxelSaves")
	var gm := root.get_node_or_null("GameManager")
	if run == null or saves == null or gm == null:
		push_error("run_state_check: AxelRun / AxelSaves / GameManager missing")
		quit(1)
		return

	saves.dir_override = "user://saves_qa_run_tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(saves.dir_override))
	for i in 3:
		saves._delete_slot_files(i)

	if not bool(saves.call("new_game", 0)):
		failures.append("new_game(0) failed")

	run.call("reset_run")
	run.state.seed = 42
	if int(run.state.act) != 1 or int(run.state.encounter_index) != 0:
		failures.append("fresh run is not Act I encounter 0")
	if not bool(run.call("can_start_encounter")):
		failures.append("fresh run should be able to start")

	run.call("grant_locker_stash_once")
	run.call("grant_locker_stash_once")
	var owned: Array = run.call("owned_items")
	if owned.size() != 3:
		failures.append("locker stash should grant C1 C2 C3 once, got %d" % owned.size())
	if bool(run.call("toggle_equip", "C1")) != true:
		failures.append("equip C1 failed")
	if run.state.equipped_item_ids.size() != 1:
		failures.append("equipped count after C1")
	if bool(run.call("toggle_equip", "C1")) != true:
		failures.append("unequip C1 failed")
	if run.state.equipped_item_ids.size() != 0:
		failures.append("unequip did not clear")
	if bool(run.call("toggle_equip", "C99")):
		failures.append("equip unknown id should fail")

	var dumped: Dictionary = run.call("to_dict")
	run.call("from_dict", dumped)
	if int(run.state.seed) != 42:
		failures.append("from_dict lost seed")
	if not bool(run.state.locker_stash_granted):
		failures.append("from_dict lost locker_stash_granted")

	if absf(float(run.call("lore_goal_bonus")) - 0.0) > 0.001:
		failures.append("lore bonus should be 0 with no flags")
	gm.call("set_flag", "hasFlashlight", true)
	gm.call("set_flag", "hasKey", true)
	var bonus := float(run.call("lore_goal_bonus"))
	if absf(bonus - 0.30) > 0.001:
		failures.append("lore bonus should be 0.30 with two items, got %s" % bonus)

	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	if int(run.state.act) != 2 or int(run.state.encounter_index) != 0:
		failures.append("three wins should roll to Act II, got act=%d idx=%d" % [run.state.act, run.state.encounter_index])
	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	if int(run.state.act) != 3:
		failures.append("six wins should reach Act III, got act=%d" % run.state.act)
	if not bool(run.call("can_start_encounter")):
		failures.append("Act III should be playable once the basement exists")
	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	run.call("_apply_win_progress")
	if bool(run.call("can_start_encounter")):
		failures.append("Act IV should not exist")

	var body: Dictionary = gm.call("export_save_body")
	if not body.has("run_state"):
		failures.append("export_save_body missing run_state")
	elif int(body["run_state"].get("act", 0)) != 3:
		failures.append("exported run_state act mismatch")

	saves.call("save_active_now")
	var header: Dictionary = saves.call("read_header", 0)
	if int(header.get("act", 0)) < 3:
		failures.append("header missing act")

	run.state.in_encounter = true
	run.call("write_tombstone_only")
	if not bool(saves.call("is_dead", 0)):
		failures.append("write_tombstone_only did not mark slot dead")
	if bool(saves.call("is_active")):
		failures.append("tombstone should clear the active slot")

	# Chip-bar lore math on a live CombatRoot (no RNG).
	if not ResourceLoader.exists("res://combat/scenes/combat_root.tscn"):
		failures.append("combat_root.tscn missing")
	else:
		var packed: PackedScene = load("res://combat/scenes/combat_root.tscn")
		var combat: Node = packed.instantiate()
		root.add_child(combat)
		if not combat.is_node_ready():
			await combat.ready
		await process_frame
		var base: int = int(combat.call("get_effective_goal_target_cents"))
		combat.call("set_lore_goal_bonus", 0.15)
		var scaled: int = int(combat.call("get_effective_goal_target_cents"))
		if scaled <= base:
			failures.append("lore bonus did not raise chip-bar goal (%d -> %d)" % [base, scaled])
		var saw := {"n": 0, "ok": false}
		combat.connect("encounter_finished", func(success: bool) -> void:
			saw["n"] = int(saw["n"]) + 1
			saw["ok"] = success
		)
		combat.call("end_encounter", true)
		combat.call("end_encounter", false)
		if int(saw["n"]) != 1 or not bool(saw["ok"]):
			failures.append("end_encounter should emit once (got %s success=%s)" % [saw["n"], saw["ok"]])
		combat.queue_free()
		await process_frame

	for i in 3:
		saves._delete_slot_files(i)
	saves.call("deactivate")
	saves.dir_override = ""
	run.call("reset_run")
	gm.call("reset_state")

	if failures.is_empty():
		print("Run state check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("run_state_check: %s" % f)
		quit(1)
