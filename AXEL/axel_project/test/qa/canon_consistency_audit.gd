extends SceneTree
## Headless canon/visual/gameplay consistency audit for combat test + movement scenes.
## Warn+recommend mode: always exits 0; findings are printed as CANON_AUDIT_JSON.
##
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/qa/canon_consistency_audit.gd

const ValidatorsScript := preload("res://test/qa/qa_canon_validators.gd")

const _MOVEMENT_SCENES: Array[String] = [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var findings: Array = []
	findings.append_array(await _audit_combat_test())
	for scene_path in _MOVEMENT_SCENES:
		findings.append_array(await _audit_movement_scene(scene_path))

	var summary := ValidatorsScript.summarize_findings(findings)
	var payload := {
		"schema_version": 1,
		"audit": "canon_consistency",
		"findings": findings,
		"findings_count": summary["findings_count"],
		"by_category": summary["by_category"],
		"scenes_audited": [_MOVEMENT_SCENES[0], _MOVEMENT_SCENES[1], ValidatorsScript.COMBAT_TEST_SCENE],
	}
	print("CANON_AUDIT_JSON %s" % JSON.stringify(payload))

	if findings.is_empty():
		print("Canon consistency audit OK (no inconsistencies).")
	else:
		print("Canon consistency audit: %d finding(s)." % findings.size())
		for item in findings:
			if item is Dictionary:
				print(
					"  %s | %s | %s | %s"
					% [
						item.get("severity", "?"),
						item.get("category", "?"),
						item.get("id", "?"),
						item.get("evidence", ""),
					]
				)
	quit(0)


func _audit_combat_test() -> Array:
	var path := ValidatorsScript.COMBAT_TEST_SCENE
	if not ResourceLoader.exists(path):
		return [
			ValidatorsScript.make_finding(
				"combat.scene_missing",
				"blocker",
				"BUG",
				path,
				"Resource does not exist",
				"Restore combat_test.tscn at res://combat/combat_test.tscn"
			)
		]
	var ps := load(path) as PackedScene
	if ps == null:
		return [
			ValidatorsScript.make_finding(
				"combat.load_failed",
				"blocker",
				"BUG",
				path,
				"load() returned null",
				"Fix combat_test.tscn parse errors."
			)
		]
	var root_ui := ps.instantiate()
	if root_ui == null:
		return [
			ValidatorsScript.make_finding(
				"combat.instantiate_failed",
				"blocker",
				"BUG",
				path,
				"instantiate() returned null",
				"Fix combat_test root node type/script."
			)
		]
	root.add_child(root_ui)
	if not root_ui.is_node_ready():
		await root_ui.ready
	await process_frame
	var result: Array = ValidatorsScript.collect_combat_test_findings(root_ui, path)
	root_ui.queue_free()
	await process_frame
	return result


func _audit_movement_scene(scene_path: String) -> Array:
	if not ResourceLoader.exists(scene_path):
		return [
			ValidatorsScript.make_finding(
				"movement.scene_missing",
				"major",
				"BUG",
				scene_path,
				"Resource does not exist",
				"Restore canonical scene file under scenes/Arc_1/."
			)
		]
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return [
			ValidatorsScript.make_finding(
				"movement.load_failed",
				"major",
				"BUG",
				scene_path,
				"load() returned null",
				"Fix scene parse/script errors."
			)
		]
	var scene_root := ps.instantiate() as Node
	if scene_root == null:
		return [
			ValidatorsScript.make_finding(
				"movement.instantiate_failed",
				"major",
				"BUG",
				scene_path,
				"instantiate() returned null",
				"Fix scene root node."
			)
		]
	root.add_child(scene_root)
	if not scene_root.is_node_ready():
		await scene_root.ready
	await process_frame
	var result: Array = ValidatorsScript.collect_movement_scene_findings(scene_path, scene_root)
	scene_root.queue_free()
	await process_frame
	return result
