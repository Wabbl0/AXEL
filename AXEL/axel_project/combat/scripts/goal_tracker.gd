class_name GoalTracker
extends RefCounted

var goal: Resource
var progress: Dictionary = {}


func set_goal(new_goal: Resource) -> void:
	goal = new_goal
	progress = {}
	if goal != null:
		progress = goal.call("init_progress")


func on_spin_completed(summary: Dictionary) -> void:
	if goal == null:
		return
	goal.call("on_spin_completed", summary, progress)


func is_complete() -> bool:
	if goal == null:
		return false
	return bool(goal.call("is_complete", progress))


func label() -> String:
	if goal == null:
		return "No goal"
	var body: String = String(goal.call("progress_label", progress))
	return "%s (%s)" % [String(goal.get("display_text")), body]
