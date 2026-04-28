class_name GoalWildCount
extends "res://combat/scripts/goal_def.gd"

@export var target_wilds: int = 6


func init_progress() -> Dictionary:
	return {"wilds": 0}


func on_spin_completed(summary: Dictionary, progress: Dictionary) -> void:
	progress["wilds"] = int(progress.get("wilds", 0)) + int(summary.get("wilds_placed", 0))


func is_complete(progress: Dictionary) -> bool:
	return int(progress.get("wilds", 0)) >= target_wilds


func progress_label(progress: Dictionary) -> String:
	return "%d / %d" % [int(progress.get("wilds", 0)), target_wilds]
