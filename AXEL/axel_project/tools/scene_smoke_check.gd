extends SceneTree
## Headless smoke: instantiate canonical scenes, ensure load + ready without bailing early.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/scene_smoke_check.gd
##
## Exit 0 on success; exit 1 on missing resource, load failure, or instantiate failure.

## Curated canonical scenes (not const: PackedStringArray literal is not a const expression in all analyzers).
const ValidatorsScript := preload("res://tools/qa/qa_canon_validators.gd")

const COMBAT_TEST_SCENE := ValidatorsScript.COMBAT_TEST_SCENE

var _smoke_scenes: PackedStringArray = PackedStringArray([
	"res://scenes/Main_Menu/0.1_MainMenu.tscn",
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_1/1.3_LockerHub.tscn",
	"res://scenes/Arc_1/1.3_SchoolMap.tscn",
	"res://scenes/Arc_2/2.1_Cafeteria.tscn",
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
	return ValidatorsScript.missing_combat_test_unique(root_ui)
