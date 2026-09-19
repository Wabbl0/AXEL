extends RefCounted
class_name QaCanonValidators

const BackgroundLayoutScript := preload("res://scenes/core/background_layout.gd")
const BackgroundCameraScript := preload("res://scenes/core/background_camera_controller.gd")
const PlayerWalkSpeedScript := preload("res://scenes/core/player_walk_speed.gd")

const COMBAT_TEST_SCENE := "res://combat/combat_test.tscn"

const CombatTestScript := preload("res://combat/scripts/combat_test.gd")

const ANCHOR_EPS := 0.001

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
	"ChooseBloodyHandButton",
	"ChooseAlcoholButton",
	"ChooseCigaretteButton",
]

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
		"speed_min": 90.0,
		"speed_max": 160.0,
		"scale_min": 0.07,
		"scale_max": 0.09,
		"required_paths": [
			"PlayerLayer/Player",
			"Camera2D",
			"TopDialogueOverlay",
			"InteractPromptOverlay",
			"EnvironmentColliders/Doors/DoorInteractArea",
		],
	},
	"res://scenes/Arc_1/1.2_Corridor.tscn": {
		"label": "corridor_large",
		"speed_min": 160.0,
		"speed_max": 250.0,
		"scale_min": 0.18,
		"scale_max": 0.22,
		"required_paths": [
			"PlayerLayer/Player",
			"Camera2D",
			"TopDialogueOverlay",
			"WalkableWorld/EnvironmentColliders/TopWall",
			"WalkableWorld/EnvironmentColliders/BottomWall",
			"WalkableWorld/EnvironmentColliders/LeftWall",
			"WalkableWorld/EnvironmentColliders/RightWall",
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

		for child in combat.get_children():
			var name_s := String(child.name)
			if not name_s.begins_with(base_name):
				continue
			if name_s == base_name:
				continue
			var suffix := name_s.substr(base_name.length())
			if suffix.length() == 0:
				continue
			var n := suffix.to_int()
			if n >= 2 and str(n) == suffix:
				violations.append("CombatRoot duplicate node %s" % name_s)
	return violations


static func check_economics_center_uniqueness(root_ui: Node) -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	if root_ui == null:
		return violations

	var ec := root_ui.find_child("EconomicsCenter", true, false) as Node
	if ec == null:
		violations.append("EconomicsCenter missing")
		return violations

	var stack_count := 0
	var stack: Node = null
	for child in ec.get_children():
		if child.name == "EconomicsStack":
			stack_count += 1
			stack = child
		if String(child.name).begins_with("@VBoxContainer@"):
			violations.append("EconomicsCenter orphan stack %s" % String(child.name))

	if stack_count == 0:
		violations.append("EconomicsCenter missing EconomicsStack")
		return violations
	if stack_count > 1:
		violations.append("EconomicsCenter has %d× EconomicsStack (expected 1)" % stack_count)

	if stack != null:
		var bl := root_ui.find_child("BankrollLabel", true, false) as Node
		if bl != null and not (bl.get_parent() == stack):
			violations.append("BankrollLabel parent drift: expected EconomicsCenter/EconomicsStack")
		var ss := root_ui.find_child("StakeSelector", true, false) as Node
		if ss != null and not (ss.get_parent() == stack):
			violations.append("StakeSelector parent drift: expected EconomicsCenter/EconomicsStack")

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


static func collect_combat_test_findings(
	root_ui: Node,
	scene_path: String = COMBAT_TEST_SCENE,
	viewport_size: Vector2 = Vector2.ZERO
) -> Array:
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

	for violation in check_economics_center_uniqueness(root_ui):
		findings.append(make_finding(
			"combat.economics_duplicate",
			"major",
			"COMBAT",
			scene_path,
			violation,
			"Keep a single EconomicsCenter/EconomicsStack; remove orphan VBox stacks and keep bankroll/stake under EconomicsStack."
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

	if viewport_size != Vector2.ZERO:
		findings.append_array(collect_combat_hud_layout_findings(root_ui, scene_path, viewport_size))

	return findings


static func expected_economics_hud_x(_viewport_w: float) -> Vector2:

	return Vector2.ZERO


static func check_combat_hud_anchors(root_ui: Node, viewport_size: Vector2 = Vector2.ZERO) -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	if root_ui == null:
		return PackedStringArray(["combat_test root is null"])

	var canvas := root_ui.find_child("HudCanvas", true, false) as Control
	if canvas == null:
		return PackedStringArray(["HudCanvas missing"])

	const HUD_W := 3508.0
	const HUD_H := 2480.0
	const EPS := 1.0


	var canvas_size := canvas.size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		canvas_size = Vector2(
			absf(canvas.offset_right - canvas.offset_left),
			absf(canvas.offset_bottom - canvas.offset_top)
		)
	if absf(canvas_size.x - HUD_W) > EPS or absf(canvas_size.y - HUD_H) > EPS:
		violations.append(
			"HudCanvas size=%.1fx%.1f expected %.0fx%.0f"
			% [canvas_size.x, canvas_size.y, HUD_W, HUD_H]
		)

	var art := canvas.get_node_or_null("HudArt") as TextureRect
	if art == null:
		violations.append("HudArt missing under HudCanvas")
	elif art.texture == null:
		violations.append("HudArt has no texture")

	for unique_name in REQUIRED_COMBAT_TEST_UNIQUE:
		var node := root_ui.find_child(unique_name, true, false) as Node
		if node == null:
			violations.append("%s missing" % unique_name)
			continue

		var widget_layer := root_ui.find_child("WidgetLayer", true, false)
		var under_widget_layer := widget_layer != null and widget_layer.is_ancestor_of(node)
		if not under_widget_layer and not canvas.is_ancestor_of(node) and node != canvas:
			violations.append("%s is not under HudCanvas" % unique_name)
			continue
		if under_widget_layer:
			continue
		if node is Control:
			var control := node as Control
			var rect := control.get_rect()

			if rect.position.x < -EPS or rect.position.y < -EPS:
				violations.append(
					"%s origin outside HudCanvas (%.1f, %.1f)"
					% [unique_name, rect.position.x, rect.position.y]
				)
			if rect.position.x > HUD_W + EPS or rect.position.y > HUD_H + EPS:
				violations.append(
					"%s origin beyond HudCanvas (%.1f, %.1f)"
					% [unique_name, rect.position.x, rect.position.y]
				)

	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		var s := minf(viewport_size.x / HUD_W, viewport_size.y / HUD_H)
		var scaled := Vector2(HUD_W * s, HUD_H * s)
		if scaled.x > viewport_size.x + EPS or scaled.y > viewport_size.y + EPS:
			violations.append(
				"HudCanvas scaled size %.1fx%.1f exceeds viewport %.0fx%.0f"
				% [scaled.x, scaled.y, viewport_size.x, viewport_size.y]
			)

	return violations


static func _append_anchor_violations(
	_violations: PackedStringArray,
	_node_name: String,
	_control: Control,
	_spec: Dictionary,
	_viewport_size: Vector2
) -> void:

	pass


static func collect_combat_hud_layout_findings(
	root_ui: Node,
	scene_path: String,
	viewport_size: Vector2
) -> Array:
	var findings: Array = []
	for violation in check_combat_hud_anchors(root_ui, viewport_size):
		findings.append(make_finding(
			"combat.hud_canvas_placement",
			"major",
			"REGRESSION",
			scene_path,
			violation,
			"Keep required unique nodes under HudCanvas (3508x2480), or under WidgetLayer after live-widget bind (layer 115 above room FX)."
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
				"Restore node per SCENE_BUILDING.md / scene contract for this location."
			))

	var player := root.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	if player == null:
		return findings


	var speed := float(player.get("speed"))
	if player.has_meta("axel_authored_speed"):
		speed = float(player.get_meta("axel_authored_speed"))
	var scale_xy := player.scale
	if player.has_meta("axel_authored_scale"):
		scale_xy = player.get_meta("axel_authored_scale") as Vector2
	var expected_speed := PlayerWalkSpeedScript.from_scale(scale_xy.x)
	if absf(speed - expected_speed) > 0.5:
		findings.append(make_finding(
			"movement.speed_from_scale",
			"minor",
			"CLARITY",
			scene_path,
			"Player.speed=%.2f does not match PlayerWalkSpeed.from_scale(%.6f)=%.2f"
			% [speed, scale_xy.x, expected_speed],
			"Bake speed from PlayerWalkSpeed / let PlayerCoverSync.bind_from_player set it."
		))
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
			"Tune Player.speed to SCENE_BUILDING profile for this scene."
		))

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
			"Adjust Player scale to match large-scene profile in SCENE_BUILDING."
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

	var child_pos_eps := 0.05
	for child_name in ["AnimatedSprite", "FallbackBody", "CollisionShape2D"]:
		var child := player.get_node_or_null(child_name) as Node2D
		if child == null:
			continue
		if child.position.length() > child_pos_eps:
			findings.append(make_finding(
				"movement.player_child_offset",
				"major",
				"REGRESSION",
				scene_path,
				"Player/%s position=%s (must be (0, 0))" % [child_name, child.position],
				"Zero the child offset and move the Player node instead."
			))

	var shadow := player.get_node_or_null("ShadowOutline") as Node2D
	if shadow != null:
		var expected_pos := Vector2(-5.0416956, -5.041732)
		var expected_scale := Vector2(1.0335996, 0.9969109)
		if shadow.position.distance_to(expected_pos) > child_pos_eps:
			findings.append(make_finding(
				"movement.shadow_outline_fit",
				"major",
				"REGRESSION",
				scene_path,
				"Player/ShadowOutline position=%s (must match 1.2 fit %s)" % [shadow.position, expected_pos],
				"Copy ShadowOutline position/scale from 1.2_Corridor (shared Mike silhouette fit)."
			))
		if shadow.scale.distance_to(expected_scale) > child_pos_eps:
			findings.append(make_finding(
				"movement.shadow_outline_fit",
				"major",
				"REGRESSION",
				scene_path,
				"Player/ShadowOutline scale=%s (must match 1.2 fit %s)" % [shadow.scale, expected_scale],
				"Copy ShadowOutline position/scale from 1.2_Corridor (shared Mike silhouette fit)."
			))

	var scene_script := root.get_script() as Script
	if scene_script != null and scene_script.resource_path.begins_with("res://scenes/"):
		var src := FileAccess.get_file_as_string(scene_script.resource_path)
		if src.contains("env.to_global(Vector2("):
			findings.append(make_finding(
				"movement.hardcoded_player_spawn",
				"major",
				"REGRESSION",
				scene_path,
				"Scene script hardcodes env.to_global(Vector2(...)) spawn",
				"Use PlayerSpawnSync from the Player node. Never overwrite default spawn."
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

	findings.append_array(collect_background_camera_findings(root, scene_path))
	findings.append_array(collect_background_editor_lock_findings(root, scene_path))
	return findings


static func collect_background_editor_lock_findings(root: Node, scene_path: String) -> Array:
	var findings: Array = []
	if root == null or not root.is_inside_tree():
		return findings
	for node in root.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		if not _is_exploration_background_sprite(sprite):
			continue
		if sprite.has_meta(BackgroundLayoutScript.EDIT_LOCK_META):
			continue
		findings.append(make_finding(
			"exploration.background_not_editor_locked",
			"minor",
			"CLARITY",
			scene_path,
			"Exploration background %s is not editor-locked" % sprite.get_path(),
			"Attach locked_exploration_background.gd and set metadata/_edit_lock_ = true."
		))
	return findings


static func _is_exploration_background_sprite(sprite: Sprite2D) -> bool:
	var node_name := sprite.name
	if node_name == "Background" or node_name.begins_with("Background_"):
		return true
	return sprite.get_parent() != null and sprite.get_parent().name == "WalkableWorld" and node_name.contains("Background")


static func collect_background_camera_findings(root: Node, scene_path: String) -> Array:
	var findings: Array = []
	if root == null or not root.is_inside_tree():
		return findings
	var camera := root.find_child("Camera2D", true, false) as Camera2D
	if camera == null or camera.get_script() != BackgroundCameraScript:
		return findings
	var bg_path: NodePath = camera.get("background_path")
	if bg_path.is_empty():
		findings.append(make_finding(
			"exploration.camera_missing_background_path",
			"major",
			"REGRESSION",
			scene_path,
			"Camera2D uses BackgroundCamera but background_path is empty",
			"Set background_path to WalkableWorld/Background on new exploration scenes."
		))
		return findings
	var background := camera.get_node_or_null(bg_path) as Sprite2D
	if background == null or background.texture == null:
		findings.append(make_finding(
			"exploration.camera_background_unresolved",
			"blocker",
			"BUG",
			scene_path,
			"BackgroundCamera background_path does not resolve to a textured Sprite2D",
			"Wire WalkableWorld/Background and assign the scene PNG."
		))
		return findings
	var viewport_size: Vector2 = BackgroundLayoutScript.get_viewport_size(root)
	var world_rect: Rect2 = BackgroundLayoutScript.compute_world_rect(
		background, background.position, background.scale
	)
	var margin_inset_px: float = camera.get("margin_px")
	var violations: PackedStringArray = BackgroundCameraScript.limits_enclose_rect(
		camera, world_rect, viewport_size, margin_inset_px
	)
	for violation in violations:
		findings.append(make_finding(
			"exploration.camera_limits_bleed",
			"blocker",
			"BUG",
			scene_path,
			violation,
			"Re-run BackgroundLayout + BackgroundCamera.apply_limits after _ready; check fit_mode and margin_px."
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
