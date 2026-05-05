class_name GoalPayoutThreshold
extends "res://combat/scripts/goal_def.gd"

@export var target_payout: float = 100.0


func init_progress() -> Dictionary:
	return {"payout": 0}


func on_spin_completed(summary: Dictionary, progress: Dictionary) -> void:
	progress["payout"] = int(progress.get("payout", 0)) + int(summary.get("payout", 0))


func is_complete(progress: Dictionary) -> bool:
	var payout_cents := int(progress.get("payout", 0))
	return payout_cents >= int(round(target_payout * 100.0))


func progress_label(progress: Dictionary) -> String:
	var payout_units := float(int(progress.get("payout", 0))) / 100.0
	return "%.2f / %.2f" % [payout_units, target_payout]
