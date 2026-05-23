extends SceneTree
## Headless guardrail: verify combat_test.tscn contains required scaffold nodes.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd

const ValidatorsScript := preload("res://test/qa/qa_canon_validators.gd")

const SCENE_PATH := ValidatorsScript.COMBAT_TEST_SCENE


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("Scaffold FAIL: missing resource: %s" % SCENE_PATH)
		quit(1)
		return
	var res: Resource = load(SCENE_PATH)
	if res == null:
		push_error("Scaffold FAIL: load() returned null: %s" % SCENE_PATH)
		quit(1)
		return
	var ps: PackedScene = res as PackedScene
	if ps == null:
		push_error("Scaffold FAIL: not a PackedScene: %s" % SCENE_PATH)
		quit(1)
		return
	var root_ui: Node = ps.instantiate() as Node
	if root_ui == null:
		push_error("Scaffold FAIL: instantiate() returned null: %s" % SCENE_PATH)
		quit(1)
		return
	root.add_child(root_ui)
	if not root_ui.is_node_ready():
		await root_ui.ready
	await process_frame

	var missing := ValidatorsScript.missing_combat_test_unique(root_ui)
	var combat := root_ui.find_child("CombatRoot", true, false)
	var grid_violations := ValidatorsScript.check_combat_root_grid_uniqueness(combat)

	if not grid_violations.is_empty():
		push_error("Scaffold FAIL (%s): %s" % [SCENE_PATH, ", ".join(grid_violations)])
		quit(1)
		return

	if not missing.is_empty():
		push_error("Scaffold FAIL (%s): missing %s" % [SCENE_PATH, ", ".join(missing)])
		quit(1)
		return

	print("Combat test scaffold check OK.")
	quit(0)
