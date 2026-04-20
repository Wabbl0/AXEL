extends SceneTree
## Run: godot --path AXEL/axel_project --headless -s res://combat/test/determinism_check.gd


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_assert_centroid_2x2()
	var log_a := await _run_determinism_pass()
	var log_b := await _run_determinism_pass()
	if not _logs_equal(log_a, log_b):
		push_error("Determinism check FAILED: logs differ.")
		quit(1)
		return
	print("Determinism check OK (100 spins, seed 12345).")
	quit(0)


func _assert_centroid_2x2() -> void:
	var pts: Array = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	var c: Vector2i = ClusterDetector.centroid_cell(pts)
	if c != Vector2i(0, 0):
		push_error("Centroid 2x2 expected (0,0) got %s" % c)
		quit(1)
		return


func _run_determinism_pass() -> PackedStringArray:
	var cr: CombatRoot = load("res://combat/scenes/combat_root.tscn").instantiate()
	root.add_child(cr)
	await cr.ready
	cr.setup_new_grid(12345)
	var snapshots: PackedStringArray = PackedStringArray()
	for i in 100:
		cr.spin_sync()
		snapshots.append(cr.serialize_spin_result())
	cr.queue_free()
	await process_frame
	await process_frame
	return snapshots


func _logs_equal(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true
