extends SceneTree
## Headless smoke: instantiate canonical scenes, ensure load + ready without bailing early.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd
##
## Exit 0 on success; exit 1 on missing resource, load failure, or instantiate failure.

## Curated canonical scenes (not const: PackedStringArray literal is not a const expression in all analyzers).
const COMBAT_TEST_SCENE := "res://combat/combat_test.tscn"

const _COMBAT_TEST_REQUIRED_UNIQUE: Array[String] = [
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
	"CombatRoot",
]

var _smoke_scenes: PackedStringArray = PackedStringArray([
	"res://scenes/Main_Menu/0.1_MainMenu.tscn",
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_2/2.1_LockerHub.tscn",
	"res://combat/scenes/combat_root.tscn",
	COMBAT_TEST_SCENE,
])


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	for i in _smoke_scenes.size():
		var path: String = _smoke_scenes[i]
		if not ResourceLoader.exists(path):
			push_error("Scene smoke FAIL: missing resource: %s" % path)
			quit(1)
			return
		var res: Resource = load(path)
		if res == null:
			push_error("Scene smoke FAIL: load() returned null: %s" % path)
			quit(1)
			return
		var ps: PackedScene = res as PackedScene
		if ps == null:
			push_error("Scene smoke FAIL: not a PackedScene: %s" % path)
			quit(1)
			return
		var node: Node = ps.instantiate() as Node
		if node == null:
			push_error("Scene smoke FAIL: instantiate() returned null: %s" % path)
			quit(1)
			return
		root.add_child(node)
		if path == COMBAT_TEST_SCENE:
			var missing_before_ready := _missing_combat_test_scaffold(node)
			if not missing_before_ready.is_empty():
				push_error(
					"Scene smoke FAIL: combat_test scaffold missing (pre-ready): %s"
					% ", ".join(missing_before_ready)
				)
				quit(1)
				return
		if not node.is_node_ready():
			await node.ready
		await process_frame
		node.queue_free()
		await process_frame

	print("Scene smoke check OK (%d scenes)." % _smoke_scenes.size())
	quit(0)


func _missing_combat_test_scaffold(root_ui: Node) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	for uname in _COMBAT_TEST_REQUIRED_UNIQUE:
		if root_ui.find_child(uname, true, false) == null:
			missing.append(uname)
	var combat := root_ui.find_child("CombatRoot", true, false)
	if combat != null and combat.get_node_or_null("GridUI") == null:
		missing.append("CombatRoot/GridUI")
	return missing
