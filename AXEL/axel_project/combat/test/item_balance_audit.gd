extends SceneTree
## Headless item balance audit: paired Monte Carlo runs (baseline vs equipped item).
## Outputs ITEM_BALANCE_JSON with per-item deltas and classification.
##
## Run:
## tools/cmd/godot.cmd --path AXEL/axel_project --headless -s res://combat/test/item_balance_audit.gd

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const FS_PICK: StringName = &"storm"
const ITEMS_DIR := "res://combat/data/items"
const SEEDS_PER_ITEM := 20
const PAID_SPINS_PER_SEED := 50
const ENCOUNTER_SEEDS_PER_ITEM := 60
const MIN_SEEDS_FOR_CLASSIFICATION := 5
const OVERPOWER_THRESHOLD := 0.02
const UNDERPOWER_THRESHOLD := -0.02


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var item_paths := _discover_item_resources()
	if item_paths.is_empty():
		print("ITEM_BALANCE_SKIP no_items_found")
		quit(0)
		return

	if not await _combat_root_supports_items():
		print("ITEM_BALANCE_SKIP item_api_not_implemented")
		quit(0)
		return

	var baseline := await _run_baseline()
	var item_results: Array[Dictionary] = []
	for i in item_paths.size():
		var path: String = item_paths[i]
		print("ITEM_BALANCE_PROGRESS item=%d/%d path=%s" % [i + 1, item_paths.size(), path])
		var result := await _run_item_audit(path, baseline)
		item_results.append(result)

	var report := _build_report(baseline, item_results)
	print("ITEM_BALANCE_JSON %s" % JSON.stringify(report))
	quit(0)


func _discover_item_resources() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			paths.append(ITEMS_DIR.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _combat_root_supports_items() -> bool:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	var has_api := cr.has_method("equip_item") or cr.has_method("set_equipped_items")
	cr.queue_free()
	await process_frame
	return has_api


func _run_baseline() -> Dictionary:
	print("ITEM_BALANCE_PROGRESS phase=baseline seeds=%d" % SEEDS_PER_ITEM)
	var per_seed_rtp: Array[float] = []
	var total_wager_cents := 0
	var total_payout_cents := 0
	var paid_spins := 0
	var paid_hit_spins := 0
	var free_spins := 0
	var free_hit_spins := 0
	var encounter_wins := 0

	for seed_idx in SEEDS_PER_ITEM:
		var seed_data := await _run_seed_baseline(10000 + seed_idx)
		per_seed_rtp.append(seed_data["seed_rtp"])
		total_wager_cents += seed_data["wager_cents"]
		total_payout_cents += seed_data["payout_cents"]
		paid_spins += seed_data["paid_spins"]
		paid_hit_spins += seed_data["paid_hit_spins"]
		free_spins += seed_data["free_spins"]
		free_hit_spins += seed_data["free_hit_spins"]

	for seed_idx in ENCOUNTER_SEEDS_PER_ITEM:
		if await _run_encounter_seed(500000 + seed_idx, ""):
			encounter_wins += 1

	var mean_rtp := _mean(per_seed_rtp)
	var sd_rtp := _sample_sd(per_seed_rtp, mean_rtp)
	return {
		"per_seed_rtp": per_seed_rtp,
		"mean_rtp": mean_rtp,
		"sd_rtp": sd_rtp,
		"total_wager_cents": total_wager_cents,
		"total_payout_cents": total_payout_cents,
		"paid_spins": paid_spins,
		"paid_hit_spins": paid_hit_spins,
		"paid_hit_rate": _ratio(paid_hit_spins, paid_spins),
		"free_spins": free_spins,
		"free_hit_spins": free_hit_spins,
		"encounter_wins": encounter_wins,
		"encounter_total": ENCOUNTER_SEEDS_PER_ITEM,
		"encounter_success": _ratio(encounter_wins, ENCOUNTER_SEEDS_PER_ITEM),
	}


func _run_seed_baseline(seed_value: int) -> Dictionary:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	cr.encounter_def = null
	cr.setup_new_grid(seed_value)

	var wager_cents := 0
	var payout_cents := 0
	var paid_count := 0
	var paid_hits := 0
	var free_count := 0
	var free_hits := 0
	var loop_guard := 0

	while paid_count < PAID_SPINS_PER_SEED and loop_guard < PAID_SPINS_PER_SEED * 20:
		loop_guard += 1
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_princess(FS_PICK)
		var was_free := cr.free_spins.active
		var bankroll_before := int(round(cr.get_bankroll() * 100.0))
		cr.spin_sync()
		var bankroll_after := int(round(cr.get_bankroll() * 100.0))
		var summary := cr.get_last_spin_summary()
		var spin_payout := int(summary.get("payout", 0))
		var spin_wager := spin_payout - (bankroll_after - bankroll_before)
		if spin_wager < 0:
			spin_wager = 0
		payout_cents += spin_payout
		if was_free:
			free_count += 1
			if spin_payout > 0:
				free_hits += 1
		else:
			paid_count += 1
			wager_cents += spin_wager
			if spin_payout > 0:
				paid_hits += 1

	var seed_rtp := 0.0
	if wager_cents > 0:
		seed_rtp = float(payout_cents) / float(wager_cents)
	cr.queue_free()
	await process_frame
	return {
		"seed_rtp": seed_rtp,
		"wager_cents": wager_cents,
		"payout_cents": payout_cents,
		"paid_spins": paid_count,
		"paid_hit_spins": paid_hits,
		"free_spins": free_count,
		"free_hit_spins": free_hits,
	}


func _run_encounter_seed(seed_value: int, item_path: String) -> bool:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	if not item_path.is_empty():
		_try_equip_item(cr, item_path)
	cr.setup_new_grid(seed_value)
	var guard := 0
	while not cr.is_encounter_complete() and guard < 200:
		guard += 1
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_princess(FS_PICK)
		cr.spin_sync()
	var won := cr.is_encounter_complete() and cr.did_win_encounter()
	cr.queue_free()
	await process_frame
	return won


func _run_item_audit(item_path: String, baseline: Dictionary) -> Dictionary:
	var per_seed_rtp: Array[float] = []
	var total_wager_cents := 0
	var total_payout_cents := 0
	var paid_spins := 0
	var paid_hit_spins := 0
	var free_spins := 0
	var free_hit_spins := 0
	var encounter_wins := 0

	for seed_idx in SEEDS_PER_ITEM:
		var seed_data := await _run_seed_with_item(10000 + seed_idx, item_path)
		per_seed_rtp.append(seed_data["seed_rtp"])
		total_wager_cents += seed_data["wager_cents"]
		total_payout_cents += seed_data["payout_cents"]
		paid_spins += seed_data["paid_spins"]
		paid_hit_spins += seed_data["paid_hit_spins"]
		free_spins += seed_data["free_spins"]
		free_hit_spins += seed_data["free_hit_spins"]

	for seed_idx in ENCOUNTER_SEEDS_PER_ITEM:
		if await _run_encounter_seed(500000 + seed_idx, item_path):
			encounter_wins += 1

	var mean_rtp := _mean(per_seed_rtp)
	var sd_rtp := _sample_sd(per_seed_rtp, mean_rtp)
	var delta_rtp := mean_rtp - float(baseline["mean_rtp"])
	var pooled_sd := _pooled_sd(
		float(baseline["sd_rtp"]), SEEDS_PER_ITEM,
		sd_rtp, SEEDS_PER_ITEM
	)
	var delta_rtp_ci := _ci95_two_sample(delta_rtp, pooled_sd)
	var item_hit_rate := _ratio(paid_hit_spins, paid_spins)
	var item_encounter_success := _ratio(encounter_wins, ENCOUNTER_SEEDS_PER_ITEM)
	var label := _classify(delta_rtp_ci, SEEDS_PER_ITEM)

	var item_id := item_path.get_file().get_basename()
	return {
		"item_id": item_id,
		"item_path": item_path,
		"label": label,
		"seeds_used": SEEDS_PER_ITEM,
		"total_wager_cents": total_wager_cents,
		"total_payout_cents": total_payout_cents,
		"baseline_rtp": float(baseline["mean_rtp"]),
		"item_rtp": mean_rtp,
		"delta_rtp": delta_rtp,
		"delta_rtp_ci95": [delta_rtp_ci[0], delta_rtp_ci[1]],
		"baseline_hit_rate": float(baseline["paid_hit_rate"]),
		"item_hit_rate": item_hit_rate,
		"delta_hit_rate": item_hit_rate - float(baseline["paid_hit_rate"]),
		"free_spins": free_spins,
		"free_hit_spins": free_hit_spins,
		"baseline_encounter_success": float(baseline["encounter_success"]),
		"item_encounter_success": item_encounter_success,
		"delta_encounter_success": item_encounter_success - float(baseline["encounter_success"]),
	}


func _run_seed_with_item(seed_value: int, item_path: String) -> Dictionary:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	_try_equip_item(cr, item_path)
	cr.encounter_def = null
	cr.setup_new_grid(seed_value)

	var wager_cents := 0
	var payout_cents := 0
	var paid_count := 0
	var paid_hits := 0
	var free_count := 0
	var free_hits := 0
	var loop_guard := 0

	while paid_count < PAID_SPINS_PER_SEED and loop_guard < PAID_SPINS_PER_SEED * 20:
		loop_guard += 1
		if cr.is_waiting_for_free_spin_choice():
			cr.choose_free_spins_princess(FS_PICK)
		var was_free := cr.free_spins.active
		var bankroll_before := int(round(cr.get_bankroll() * 100.0))
		cr.spin_sync()
		var bankroll_after := int(round(cr.get_bankroll() * 100.0))
		var summary := cr.get_last_spin_summary()
		var spin_payout := int(summary.get("payout", 0))
		var spin_wager := spin_payout - (bankroll_after - bankroll_before)
		if spin_wager < 0:
			spin_wager = 0
		payout_cents += spin_payout
		if was_free:
			free_count += 1
			if spin_payout > 0:
				free_hits += 1
		else:
			paid_count += 1
			wager_cents += spin_wager
			if spin_payout > 0:
				paid_hits += 1

	var seed_rtp := 0.0
	if wager_cents > 0:
		seed_rtp = float(payout_cents) / float(wager_cents)
	cr.queue_free()
	await process_frame
	return {
		"seed_rtp": seed_rtp,
		"wager_cents": wager_cents,
		"payout_cents": payout_cents,
		"paid_spins": paid_count,
		"paid_hit_spins": paid_hits,
		"free_spins": free_count,
		"free_hit_spins": free_hits,
	}


func _try_equip_item(cr: CombatRoot, item_path: String) -> void:
	var item_res := load(item_path)
	if item_res == null:
		push_warning("item_balance_audit: could not load %s" % item_path)
		return
	if cr.has_method("equip_item"):
		cr.call("equip_item", item_res)
	elif cr.has_method("set_equipped_items"):
		cr.call("set_equipped_items", [item_res])
	else:
		push_warning("item_balance_audit: CombatRoot has no equip method; item ignored")


func _classify(ci95: Array[float], seed_count: int) -> String:
	if seed_count < MIN_SEEDS_FOR_CLASSIFICATION:
		return "insufficient_data"
	if ci95[0] > OVERPOWER_THRESHOLD:
		return "overpowered"
	if ci95[1] < UNDERPOWER_THRESHOLD:
		return "underpowered"
	return "neutral"


func _build_report(baseline: Dictionary, items: Array[Dictionary]) -> Dictionary:
	var overpowered: Array[String] = []
	var underpowered: Array[String] = []
	var neutral: Array[String] = []
	var insufficient: Array[String] = []
	for item in items:
		var id: String = item["item_id"]
		match item["label"]:
			"overpowered": overpowered.append(id)
			"underpowered": underpowered.append(id)
			"neutral": neutral.append(id)
			"insufficient_data": insufficient.append(id)

	return {
		"item_balance_schema_version": 1,
		"config": {
			"seeds_per_item": SEEDS_PER_ITEM,
			"paid_spins_per_seed": PAID_SPINS_PER_SEED,
			"encounter_seeds_per_item": ENCOUNTER_SEEDS_PER_ITEM,
			"overpower_threshold": OVERPOWER_THRESHOLD,
			"underpower_threshold": UNDERPOWER_THRESHOLD,
			"free_spin_pick": String(FS_PICK),
		},
		"baseline_rtp": float(baseline["mean_rtp"]),
		"baseline_hit_rate": float(baseline["paid_hit_rate"]),
		"baseline_encounter_success": float(baseline["encounter_success"]),
		"item_balance": {
			"schema_version": 1,
			"items_tested": items.size(),
			"items_overpowered": overpowered,
			"items_underpowered": underpowered,
			"items_neutral": neutral,
			"items_insufficient_data": insufficient,
		},
		"item_metrics": items,
	}


# --- Statistics helpers ---

func _ratio(num: int, den: int) -> float:
	if den <= 0:
		return 0.0
	return float(num) / float(den)


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / float(values.size())


func _sample_sd(values: Array[float], mean_value: float) -> float:
	if values.size() <= 1:
		return 0.0
	var total := 0.0
	for v in values:
		var d := v - mean_value
		total += d * d
	return sqrt(total / float(values.size() - 1))


func _pooled_sd(sd1: float, n1: int, sd2: float, n2: int) -> float:
	if n1 <= 1 or n2 <= 1:
		return 0.0
	var se := sqrt((sd1 * sd1) / float(n1) + (sd2 * sd2) / float(n2))
	return se


func _ci95_two_sample(delta: float, pooled_se: float) -> Array[float]:
	var margin := 1.96 * pooled_se
	return [delta - margin, delta + margin]
