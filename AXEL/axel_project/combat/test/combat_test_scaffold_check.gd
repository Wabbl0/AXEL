extends SceneTree
## Headless guardrail: verify combat_test.tscn contains required scaffold nodes.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd

const ValidatorsScript := preload("res://tools/qa/qa_canon_validators.gd")

const SCENE_PATH := ValidatorsScript.COMBAT_TEST_SCENE

const VIEWPORT_BREAKPOINTS: Array[Vector2] = [
	Vector2(1280, 720),
	Vector2(800, 600),
]


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
	var root_ui: Control = ps.instantiate() as Control
	if root_ui == null:
		push_error("Scaffold FAIL: instantiate() returned null: %s" % SCENE_PATH)
		quit(1)
		return
	root.add_child(root_ui)
	if not root_ui.is_node_ready():
		await root_ui.ready

	var missing := ValidatorsScript.missing_combat_test_unique(root_ui)
	var combat := root_ui.find_child("CombatRoot", true, false)
	var grid_violations := ValidatorsScript.check_combat_root_grid_uniqueness(combat)

	var suffix_violations := _check_numbered_grid_suffixes(combat)
	if not suffix_violations.is_empty():
		for item in suffix_violations:
			grid_violations.append(item)

	var validators := load("res://tools/qa/qa_canon_validators.gd") as Script
	var econ_violations: PackedStringArray = PackedStringArray()
	if validators != null:
		econ_violations = PackedStringArray(validators.call("check_economics_center_uniqueness", root_ui))
	if not econ_violations.is_empty():
		for item in econ_violations:
			grid_violations.append(item)

	if not grid_violations.is_empty():
		push_error("Scaffold FAIL (%s): %s" % [SCENE_PATH, ", ".join(grid_violations)])
		quit(1)
		return

	if not missing.is_empty():
		push_error("Scaffold FAIL (%s): missing %s" % [SCENE_PATH, ", ".join(missing)])
		quit(1)
		return

	var placement_violations := ValidatorsScript.check_combat_hud_anchors(root_ui)
	if not placement_violations.is_empty():
		push_error(
			"Scaffold FAIL (%s): HUD canvas placement: %s"
			% [SCENE_PATH, ", ".join(placement_violations)]
		)
		quit(1)
		return

	for viewport_size in VIEWPORT_BREAKPOINTS:
		await _apply_viewport_and_wait_layout(root_ui, viewport_size)
		var fit_violations := ValidatorsScript.check_combat_hud_anchors(root_ui, viewport_size)
		if not fit_violations.is_empty():
			push_error(
				"Scaffold FAIL (%s): HudCanvas fit at %.0fx%.0f: %s"
				% [SCENE_PATH, viewport_size.x, viewport_size.y, ", ".join(fit_violations)]
			)
			quit(1)
			return
		var canvas := root_ui.find_child("HudCanvas", true, false) as Control
		if canvas == null:
			push_error("Scaffold FAIL (%s): HudCanvas missing after resize" % SCENE_PATH)
			quit(1)
			return
		var s := minf(viewport_size.x / 3508.0, viewport_size.y / 2480.0)
		var expected_pos := Vector2(
			(viewport_size.x - 3508.0 * s) * 0.5,
			(viewport_size.y - 2480.0 * s) * 0.5
		)
		if canvas.position.distance_to(expected_pos) > 2.0:
			push_error(
				"Scaffold FAIL (%s): HudCanvas not centered at %.0fx%.0f (got %s expected %s)"
				% [SCENE_PATH, viewport_size.x, viewport_size.y, str(canvas.position), str(expected_pos)]
			)
			quit(1)
			return
		if absf(canvas.scale.x - s) > 0.01 or absf(canvas.scale.y - s) > 0.01:
			push_error(
				"Scaffold FAIL (%s): HudCanvas scale drift at %.0fx%.0f (got %s expected %.4f)"
				% [SCENE_PATH, viewport_size.x, viewport_size.y, str(canvas.scale), s]
			)
			quit(1)
			return

	print("Combat test scaffold check OK.")
	quit(0)


func _check_numbered_grid_suffixes(combat: Node) -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	if combat == null:
		return violations

	var bases: Array[String] = [
		"GridManager",
		"GridFrame",
		"GridUI",
		"GridFlashOverlay",
		"PowerIntroLayer",
		"RoundWinningsLabel",
		"EncounterWonLabel",
		"MultiplierLabel",
	]

	var re := RegEx.new()
	var pattern := "^(%s)([0-9]+)$" % "|".join(bases)
	var err := re.compile(pattern)
	if err != OK:
		violations.append("internal: failed to compile suffix regex")
		return violations

	for child in combat.get_children():
		var m := re.search(String(child.name))
		if m == null:
			continue
		var n := int(m.get_string(2))
		if n >= 2:
			violations.append("CombatRoot duplicate node %s" % String(child.name))
	return violations


func _apply_viewport_and_wait_layout(root_ui: Control, viewport_size: Vector2) -> void:
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root_ui.anchor_right = 0.0
	root_ui.anchor_bottom = 0.0
	root_ui.size = viewport_size
	root_ui.custom_minimum_size = viewport_size
	root_ui.position = Vector2.ZERO
	if root_ui.has_method("_fit_hud_canvas"):
		root_ui.call("_fit_hud_canvas", viewport_size)
	await process_frame
	await process_frame
	await process_frame
	if root_ui.has_method("_fit_hud_canvas"):
		root_ui.call("_fit_hud_canvas", viewport_size)
	await process_frame
