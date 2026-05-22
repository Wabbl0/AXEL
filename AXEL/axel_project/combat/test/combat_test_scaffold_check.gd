extends SceneTree
## Headless guardrail: verify combat_test.tscn contains required scaffold nodes.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd

const SCENE_PATH := "res://combat/combat_test.tscn"

const REQUIRED_UNIQUE: Array[String] = [
	"CombatRoot",
	"MetaBox",
	"SeedSpinBox",
	"SpinButton",
	"BankrollLabel",
	"GoalBox",
	"GoalLabel",
	"BetMinusButton",
	"BetLabel",
	"BetPlusButton",
	"MultiplierReadout",
	"EncounterWinOverlay",
	"EncounterWinLabel",
	"SuperFSChoiceOverlay",
	"ChooseLoveButton",
	"ChooseStarButton",
	"ChooseStormButton",
]

const REQUIRED_PATHS: Array[String] = []


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

	var missing: PackedStringArray = PackedStringArray()
	for uname in REQUIRED_UNIQUE:
		if root_ui.find_child(uname, true, false) == null:
			missing.append(uname)

	for path in REQUIRED_PATHS:
		if root_ui.get_node_or_null(path) == null:
			missing.append(path)

	var combat := root_ui.find_child("CombatRoot", true, false)
	if combat != null and combat.get_node_or_null("GridUI") == null:
		missing.append("CombatRoot/GridUI")

	if not missing.is_empty():
		push_error("Scaffold FAIL (%s): missing %s" % [SCENE_PATH, ", ".join(missing)])
		quit(1)
		return

	print("Combat test scaffold check OK.")
	quit(0)
