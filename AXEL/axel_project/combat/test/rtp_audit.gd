extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const FS_PICK: StringName = &"storm"
const BASELINE_SEEDS := 20
const PAID_SPINS_PER_SEED := 50
const ENCOUNTER_SEEDS := 120


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var baseline := await _run_baseline_no_item()
	var encounters := await _run_encounter_success()
	var result := _build_report(baseline, encounters)
	print("RTP_AUDIT_JSON %s" % JSON.stringify(result))
	quit(0)


func _run_baseline_no_item() -> Dictionary:
	var per_seed_rtp: Array[float] = []
	var total_wager_cents := 0
	var total_payout_cents := 0
	var total_line_payout_cents := 0
	var total_clear_bonus_cents := 0
	var paid_spins := 0
	var paid_hit_spins := 0
	var free_spins := 0
	var free_hit_spins := 0
	var trinity_entry_count := 0
	var forced_choice_count := 0

	for seed_idx in BASELINE_SEEDS:
		if seed_idx % 5 == 0:
			print("RTP_AUDIT_PROGRESS baseline_seed=%d/%d" % [seed_idx, BASELINE_SEEDS])
		var cr: CombatRoot = CombatRootScene.instantiate()
		root.add_child(cr)
		if not cr.is_node_ready():
			await cr.ready
		cr.encounter_def = null
		cr.setup_new_grid(10000 + seed_idx)
		var seed_wager_cents := 0
		var seed_payout_cents := 0
		var seed_paid_spins := 0
		var loop_guard := 0
		while seed_paid_spins < PAID_SPINS_PER_SEED and loop_guard < PAID_SPINS_PER_SEED * 20:
			loop_guard += 1
			if cr.is_waiting_for_free_spin_choice():
				cr.choose_free_spins_princess(FS_PICK)
				forced_choice_count += 1
				trinity_entry_count += 1
			var was_free_spin := cr.free_spins.active
			var bankroll_before_cents := int(round(cr.get_bankroll()))
			var bet_cents := int(round(cr.total_bet))
			cr.spin_sync()
			var summary := cr.get_last_spin_summary()
			var payout_cents := int(summary.get("payout", 0))
			var line_payout_cents := int(summary.get("line_payout", 0))
			var clear_bonus_cents := int(summary.get("clear_bonus_payout", 0))


			var wager_cents := 0
			if not was_free_spin and bankroll_before_cents >= bet_cents:
				wager_cents = bet_cents

			total_payout_cents += payout_cents
			total_line_payout_cents += line_payout_cents
			total_clear_bonus_cents += clear_bonus_cents
			if was_free_spin:
				free_spins += 1
				if payout_cents > 0:
					free_hit_spins += 1
			else:
				paid_spins += 1
				seed_paid_spins += 1
				total_wager_cents += wager_cents
				seed_wager_cents += wager_cents
				seed_payout_cents += payout_cents
				if payout_cents > 0:
					paid_hit_spins += 1
		if seed_wager_cents > 0:
			per_seed_rtp.append(float(seed_payout_cents) / float(seed_wager_cents))
		cr.queue_free()
		await process_frame

	return {
		"per_seed_rtp": per_seed_rtp,
		"total_wager_cents": total_wager_cents,
		"total_payout_cents": total_payout_cents,
		"total_line_payout_cents": total_line_payout_cents,
		"total_clear_bonus_cents": total_clear_bonus_cents,
		"paid_spins": paid_spins,
		"paid_hit_spins": paid_hit_spins,
		"free_spins": free_spins,
		"free_hit_spins": free_hit_spins,
		"trinity_entry_count": trinity_entry_count,
		"forced_choice_count": forced_choice_count,
	}


func _run_encounter_success() -> Dictionary:
	var wins := 0
	for seed_idx in ENCOUNTER_SEEDS:
		if seed_idx % 20 == 0:
			print("RTP_AUDIT_PROGRESS encounter_seed=%d/%d" % [seed_idx, ENCOUNTER_SEEDS])
		var cr: CombatRoot = CombatRootScene.instantiate()
		root.add_child(cr)
		if not cr.is_node_ready():
			await cr.ready
		cr.setup_new_grid(500000 + seed_idx)
		var guard := 0
		while not cr.is_encounter_complete() and guard < 200:
			guard += 1
			if cr.is_waiting_for_free_spin_choice():
				cr.choose_free_spins_princess(FS_PICK)
			cr.spin_sync()
		if cr.is_encounter_complete() and cr.did_win_encounter():
			wins += 1
		cr.queue_free()
		await process_frame
	return {
		"encounters": ENCOUNTER_SEEDS,
		"wins": wins,
	}


func _build_report(baseline: Dictionary, encounters: Dictionary) -> Dictionary:
	var total_wager_cents := int(baseline["total_wager_cents"])
	var total_payout_cents := int(baseline["total_payout_cents"])
	var paid_spins := int(baseline["paid_spins"])
	var paid_hit_spins := int(baseline["paid_hit_spins"])
	var free_spins := int(baseline["free_spins"])
	var free_hit_spins := int(baseline["free_hit_spins"])
	var per_seed_rtp := baseline["per_seed_rtp"] as Array[float]
	var mean_seed_rtp := _mean(per_seed_rtp)
	var sd_seed_rtp := _sample_sd(per_seed_rtp, mean_seed_rtp)
	var rtp_mean := 0.0
	if total_wager_cents > 0:
		rtp_mean = float(total_payout_cents) / float(total_wager_cents)
	var rtp_ci := _ci95_from_seed_means(mean_seed_rtp, sd_seed_rtp, per_seed_rtp.size())
	var paid_hit_rate := _ratio(paid_hit_spins, paid_spins)
	var paid_hit_ci := _ci95_binomial(paid_hit_rate, paid_spins)
	var free_hit_rate := _ratio(free_hit_spins, free_spins)
	var encounter_rate := _ratio(int(encounters["wins"]), int(encounters["encounters"]))
	var encounter_ci := _ci95_binomial(encounter_rate, int(encounters["encounters"]))
	var target_low := 0.75
	var target_high := 0.80
	var delta_vs_mid := rtp_mean - 0.775
	var position := "within"
	if rtp_mean < target_low:
		position = "below"
	elif rtp_mean > target_high:
		position = "above"

	return {
		"config": {
			"baseline_seeds": BASELINE_SEEDS,
			"paid_spins_per_seed": PAID_SPINS_PER_SEED,
			"encounter_seeds": ENCOUNTER_SEEDS,
			"free_spin_pick": String(FS_PICK),
		},
		"baseline": {
			"rtp_mean": rtp_mean,
			"rtp_ci95": rtp_ci,
			"rtp_per_seed_mean": mean_seed_rtp,
			"rtp_per_seed_sd": sd_seed_rtp,
			"target_band": [target_low, target_high],
			"target_position": position,
			"delta_vs_target_mid": delta_vs_mid,
			"total_wager_cents": total_wager_cents,
			"total_payout_cents": total_payout_cents,
			"line_payout_cents": int(baseline["total_line_payout_cents"]),
			"clear_bonus_cents": int(baseline["total_clear_bonus_cents"]),
			"free_spin_payout_cents": total_payout_cents - int(baseline["total_line_payout_cents"]) - int(baseline["total_clear_bonus_cents"]),
			"paid_spins": paid_spins,
			"paid_hit_spins": paid_hit_spins,
			"paid_hit_rate": paid_hit_rate,
			"paid_hit_rate_ci95": paid_hit_ci,
			"free_spins": free_spins,
			"free_hit_spins": free_hit_spins,
			"free_hit_rate": free_hit_rate,
			"trinity_entries": int(baseline["trinity_entry_count"]),
			"forced_choice_count": int(baseline["forced_choice_count"]),
		},
		"encounters": {
			"count": int(encounters["encounters"]),
			"wins": int(encounters["wins"]),
			"success_rate": encounter_rate,
			"success_rate_ci95": encounter_ci,
		},
	}


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


func _ci95_from_seed_means(mean_value: float, sd_value: float, n: int) -> Array[float]:
	if n <= 1:
		return [mean_value, mean_value]
	var margin := 1.96 * (sd_value / sqrt(float(n)))
	return [mean_value - margin, mean_value + margin]


func _ci95_binomial(p: float, n: int) -> Array[float]:
	if n <= 0:
		return [0.0, 0.0]
	var se := sqrt((p * (1.0 - p)) / float(n))
	var margin := 1.96 * se
	return [max(0.0, p - margin), min(1.0, p + margin)]
