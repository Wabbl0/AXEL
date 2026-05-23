extends RefCounted
class_name QaCanonValidators
## Shared canon/consistency assertions for combat test and movement scenes.
## Used by combat_test_scaffold_check, scene_smoke_check, and canon_consistency_audit.

const COMBAT_TEST_SCENE := "res://combat/combat_test.tscn"

const REQUIRED_COMBAT_TEST_UNIQUE: Array[String] = [
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

## Direct CombatRoot children that must exist exactly once (duplicate-grid guard).
## combat_test.tscn must instance combat_root.tscn — do not add these as sibling inline nodes.
## Pre-commit: tools/qa/check_combat_test_scaffold.py (sanitize_duplicate_combat_root_grid).
const COMBAT_ROOT_GRID_UNIQUE: Array[String] = [
	"GridManager",
	"GridFrame",
	"GridUI",
	"GridFlashOverlay",
	"PowerIntroLayer",
	"RoundWinningsLabel",
	"EncounterWonLabel",
]

const COMBAT_ROOT_NO_SUFFIX2: Array[String] = [
	"GridManager",
	"GridFrame",
	"GridUI",
	"GridFlashOverlay",
	"PowerIntroLayer",
	"RoundWinningsLabel",
	"EncounterWonLabel",
	"MultiplierLabel",
]

const MOVEMENT_SCENE_PROFILES: Dictionary = {
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn": {
		"label": "school_exterior",
		"speed_min": 150.0,
		"speed_max": 210.0,
		"scale_min": 1.0,
		"scale_max": 1.35,
		"required_paths": [
			"PlayerLayer/Player",
			"Camera2D",
			"TopDialogueOverlay",
			"1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea",
		],
	},
	"res://scenes/Arc_1/1.2_Corridor.tscn": {
		"label": "corridor_large",
		"speed_min": 130.0,
		"speed_max": 175.0,
		"scale_min": 0.75,
		"scale_max": 0.95,
		"required_paths": [
			"PlayerLayer/Player",
			"TopDialogueOverlay",
		],
	},
}


static func check_combat_root_grid_uniqueness(combat: Node) -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	if combat == null:
		return violations
	for base_name in COMBAT_ROOT_GRID_UNIQUE:
		var count := 0
		for child in combat.get_children():
			if child.name == base_name:
				count += 1
		if count == 0:
			violations.append("CombatRoot missing %s" % base_name)
		elif count > 1:
			violations.append("CombatRoot has %d× %s (expected 1)" % [count, base_name])
	for base_name in COMBAT_ROOT_NO_SUFFIX2:
		var dup_name := "%s2" % base_name
		if combat.get_node_or_null(NodePath(dup_name)) != null:
			violations.append("CombatRoot duplicate node %s" % dup_name)
	return violations


static func missing_combat_test_unique(root_ui: Node) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	if root_ui == null:
		return PackedStringArray(["combat_test root is null"])
	for uname in REQUIRED_COMBAT_TEST_UNIQUE:
		if root_ui.find_child(uname, true, false) == null:
			missing.append(uname)
	var combat := root_ui.find_child("CombatRoot", true, false)
	if combat != null and combat.get_node_or_null("GridUI") == null:
		missing.append("CombatRoot/GridUI")
	return missing


static func make_finding(
	id: String,
	severity: String,
	category: String,
	scene: String,
	evidence: String,
	recommendation: String
) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"category": category,
		"scene": scene,
		"evidence": evidence,
		"recommendation": recommendation,
	}


static func collect_combat_test_findings(root_ui: Node, scene_path: String = COMBAT_TEST_SCENE) -> Array:
	var findings: Array = []
	if root_ui == null:
		findings.append(make_finding(
			"combat.instantiate_failed",
			"blocker",
			"BUG",
			scene_path,
			"combat_test instantiate returned null",
			"Fix combat_test.tscn load/instantiate errors before QA."
		))
		return findings

	for missing_name in missing_combat_test_unique(root_ui):
		findings.append(make_finding(
			"combat.scaffold_missing_%s" % missing_name.replace("/", "_"),
			"major",
			"REGRESSION",
			scene_path,
			"Missing required node: %s" % missing_name,
			"Restore combat_test scaffold node per AI_DOCS §8 protected scaffold."
		))

	var combat := root_ui.find_child("CombatRoot", true, false)
	for violation in check_combat_root_grid_uniqueness(combat):
		findings.append(make_finding(
			"combat.grid_duplicate",
			"major",
			"COMBAT",
			scene_path,
			violation,
			"Remove duplicate grid/overlay nodes under CombatRoot; keep a single GridUI/GridManager stack."
		))

	if combat != null:
		var grid_ui := combat.get_node_or_null("GridUI") as GridContainer
		if grid_ui != null and grid_ui.get_child_count() > 0:
			if grid_ui.get_child_count() != 25:
				findings.append(make_finding(
					"combat.grid_cell_count",
					"minor",
					"COMBAT",
					scene_path,
					"GridUI has %d children (expected 25 for 5×5)" % grid_ui.get_child_count(),
					"Align GridUI slot count with 5×5 combat invariant or document intentional deviation."
				))

	var scanline := root_ui.find_child("ScanlineOverlay", true, false)
	if scanline == null:
		findings.append(make_finding(
			"combat.scanline_missing",
			"minor",
			"STYLE",
			scene_path,
			"No ScanlineOverlay node found in combat_test",
			"Add scanline/CRT overlay to combat test to match AXEL style canon (AI_DOCS §6)."
		))

	return findings


static func collect_movement_scene_findings(scene_path: String, root: Node) -> Array:
	var findings: Array = []
	if root == null:
		findings.append(make_finding(
			"movement.instantiate_failed",
			"major",
			"BUG",
			scene_path,
			"Scene instantiate returned null",
			"Fix scene resource so movement audit can load the scene."
		))
		return findings

	if not MOVEMENT_SCENE_PROFILES.has(scene_path):
		return findings

	var profile: Dictionary = MOVEMENT_SCENE_PROFILES[scene_path]
	for node_path in profile.get("required_paths", []):
		if root.get_node_or_null(NodePath(node_path)) == null:
			findings.append(make_finding(
				"movement.missing_%s" % String(node_path).replace("/", "_"),
				"major",
				"REGRESSION",
				scene_path,
				"Missing required node path: %s" % node_path,
				"Restore node per AXEL_SCENES_BLUEPRINT / scene contract for this location."
			))

	var player := root.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	if player == null:
		return findings

	var speed := float(player.get("speed"))
	var speed_min := float(profile.get("speed_min", 0.0))
	var speed_max := float(profile.get("speed_max", 9999.0))
	if speed < speed_min or speed > speed_max:
		findings.append(make_finding(
			"movement.speed_profile",
			"minor",
			"CLARITY",
			scene_path,
			"Player.speed=%.1f outside profile [%s, %s] for %s"
			% [speed, speed_min, speed_max, profile.get("label", scene_path)],
			"Tune Player.speed to SCENE_LAYOUT_RULES profile for this scene."
		))

	var scale_xy := player.scale
	var scale_min := float(profile.get("scale_min", 0.0))
	var scale_max := float(profile.get("scale_max", 99.0))
	var scale_avg := (scale_xy.x + scale_xy.y) * 0.5
	if scale_avg < scale_min or scale_avg > scale_max:
		findings.append(make_finding(
			"movement.scale_profile",
			"minor",
			"STYLE",
			scene_path,
			"Player scale avg=%.2f outside profile [%.2f, %.2f]" % [scale_avg, scale_min, scale_max],
			"Adjust Player scale to match large-scene profile in SCENE_LAYOUT_RULES."
		))

	var fallback := player.get_node_or_null("FallbackBody") as CanvasItem
	var animated := player.get_node_or_null("AnimatedSprite") as CanvasItem
	if fallback != null and fallback.visible and animated != null and animated.visible:
		findings.append(make_finding(
			"movement.fallback_and_sprite",
			"nit",
			"STYLE",
			scene_path,
			"FallbackBody and AnimatedSprite both visible",
			"Hide FallbackBody when sprite sheet loads successfully."
		))
	elif fallback != null and fallback.visible:
		findings.append(make_finding(
			"movement.fallback_visible",
			"minor",
			"STYLE",
			scene_path,
			"Player FallbackBody placeholder is visible (sprite sheet missing?)",
			"Assign sprite_sheet on Player or fix asset path under res://assets/sprites/."
		))

	if scene_path == "res://scenes/Arc_1/1.1_SchoolExterior.tscn":
		var camera := root.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			var target_path: NodePath = camera.get("target_path") as NodePath
			if target_path.is_empty() or String(target_path) != "../PlayerLayer/Player":
				findings.append(make_finding(
					"movement.camera_target",
					"minor",
					"CLARITY",
					scene_path,
					"Camera2D target_path=%s (expected ../PlayerLayer/Player)" % str(target_path),
					"Point camera_follow script target_path at Player for consistent follow."
				))

	return findings


static func summarize_findings(findings: Array) -> Dictionary:
	var counts := {
		"blocker": 0,
		"major": 0,
		"minor": 0,
		"nit": 0,
	}
	var by_category: Dictionary = {}
	for item in findings:
		if not item is Dictionary:
			continue
		var sev := String(item.get("severity", "minor"))
		if counts.has(sev):
			counts[sev] += 1
		var cat := String(item.get("category", "REGRESSION"))
		by_category[cat] = int(by_category.get(cat, 0)) + 1
	return {"findings_count": counts, "by_category": by_category}
