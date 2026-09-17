extends SceneTree


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var pass_a := await _run_determinism_pass()
	var pass_b := await _run_determinism_pass()
	if not _logs_equal(pass_a["snapshots"], pass_b["snapshots"]):
		push_error("Determinism check FAILED: logs differ.")
		quit(1)
		return
	if pass_a["princess_current"] != pass_b["princess_current"]:
		push_error("Determinism check FAILED: princess rotation drift.")
		quit(1)
		return
	print("Determinism check OK (100 spins, seed 12345).")
	quit(0)


func _run_determinism_pass() -> Dictionary:
	var cr: CombatRoot = load("res://combat/scenes/combat_root.tscn").instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready


	cr.encounter_def = null
	cr.setup_new_grid(12345)
	var snapshots: PackedStringArray = PackedStringArray()
	for i in 100:
		cr.spin_sync()
		snapshots.append(cr.serialize_spin_result())
	var princess_current := String(cr.get_princess_current_id())
	cr.queue_free()
	await process_frame
	await process_frame
	return {
		"snapshots": snapshots,
		"princess_current": princess_current,
	}


func _logs_equal(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true
