class_name GoalPayoutThreshold
extends "res://combat/scripts/goal_def.gd"

@export var target_payout: int = 100


func init_progress() -> Dictionary:
	return {"payout": 0}


func on_spin_completed(summary: Dictionary, progress: Dictionary) -> void:
	progress["payout"] = int(progress.get("payout", 0)) + int(summary.get("payout", 0))


func is_complete(progress: Dictionary) -> bool:
	return int(progress.get("payout", 0)) >= target_payout


func progress_label(progress: Dictionary) -> String:
	return "%d / %d" % [int(progress.get("payout", 0)), target_payout]
