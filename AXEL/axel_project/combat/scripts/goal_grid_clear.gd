class_name GoalGridClear
extends "res://combat/scripts/goal_def.gd"

@export var required_clears: int = 1


func init_progress() -> Dictionary:
	return {"clears": 0}


func on_spin_completed(summary: Dictionary, progress: Dictionary) -> void:
	if bool(summary.get("grid_cleared", false)):
		progress["clears"] = int(progress.get("clears", 0)) + 1


func is_complete(progress: Dictionary) -> bool:
	return int(progress.get("clears", 0)) >= required_clears


func progress_label(progress: Dictionary) -> String:
	return "%d / %d" % [int(progress.get("clears", 0)), required_clears]
