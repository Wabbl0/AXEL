extends SceneTree
## Headless playthrough bot: dialogue + alternate interact-key fidelity.
##
## Plan step 4 originally targeted `scripts/GameController.gd`. Per
## `AI_CHANGELOG.md` (2026-05-08 "Restore SchoolExterior Full Layout"),
## `GameController.gd` was intentionally stripped from the active scene tree
## (HUD/timer/key/inventory wiring removed). Per `AI_DOCS.md` canon hierarchy
## ("no architecture-layer mixing without intent") we do NOT resurrect it via a
## synthetic scene. Instead this bot exercises the *currently wired* dialogue
## and interaction loop, which is the same spirit (advance/skip + interact +
## final-state assertion) using:
##
##   - `scenes/ui/TopDialogueOverlay.gd`   - typewriter + Tab-skip via `_input`
##   - `scenes/Arc_1/1.1_SchoolExterior.gd` - intro dialogue + door interaction
##                                            via `_unhandled_input`
##
## Distinct from `playthrough_arc1_exterior.gd`:
##   - synthesizes KEY_TAB to drive the typewriter-skip _input handler
##   - uses KEY_SPACE (not KEY_E) for the door interaction, validating the
##     alternate-key branch of `_is_interaction_event` (E/SPACE/ENTER/KP_ENTER)
##
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_dialogue_loop.gd
##
## Exit codes:
##   0 = dialogue overlay accepted Tab skips, walk + Space interaction
##       triggered transition to corridor.
##   1 = any phase failed.

const InputEventDriverScript := preload("res://tools/bots/input_event_driver.gd")
const BotScenarioRunnerScript := preload("res://tools/bots/scenario_runner.gd")

const _SCENE_EXTERIOR := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const _SCENE_CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"

const _SCENE_READY_GRACE_FRAMES := 4
## Intro line 1 fades in (~0.22s) before typewriter starts; ~14 frames safe wait.
const _DIALOGUE_FADE_IN_FRAMES := 18
const _TAB_SKIP_TAP_FRAMES := 2
const _BETWEEN_LINES_WAIT_FRAMES := 60
## Hold Tab during the second line as well to ensure skip propagates while typing.
const _SECOND_TAB_HOLD_FRAMES := 6
## Same traversal budget as primary exterior bot, plus extra buffer for dialogue overhead.
const _WALK_FRAMES_RIGHT := 360
const _SETTLE_FRAMES_AFTER_WALK := 8
const _INTERACT_TAP_FRAMES := 3
const _TRANSITION_TIMEOUT_FRAMES := 240
const _VERBOSE := true


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var ok := await _run_playthrough()
	if ok:
		print("Dialogue/interact playthrough OK.")
		quit(0)
	else:
		push_error("Dialogue/interact playthrough FAILED.")
		quit(1)


func _run_playthrough() -> bool:
	if not ResourceLoader.exists(_SCENE_EXTERIOR):
		push_error("Bot FAIL: missing exterior scene resource: %s" % _SCENE_EXTERIOR)
		return false
	if not ResourceLoader.exists(_SCENE_CORRIDOR):
		push_error("Bot FAIL: missing corridor scene resource: %s" % _SCENE_CORRIDOR)
		return false

	var change_err := change_scene_to_file(_SCENE_EXTERIOR)
	if change_err != OK:
		push_error("Bot FAIL: change_scene_to_file(exterior) -> %d" % change_err)
		return false

	for _i in _SCENE_READY_GRACE_FRAMES:
		await process_frame

	if current_scene == null or current_scene.scene_file_path != _SCENE_EXTERIOR:
		push_error("Bot FAIL: exterior scene did not become current_scene.")
		return false

	var driver := InputEventDriverScript.new(self, _VERBOSE)
	var runner := BotScenarioRunnerScript.new(self, driver, _VERBOSE)

	var commands: Array = [
		{"op": "log", "msg": "phase 1: wait for dialogue fade-in / typewriter to start"},
		{"op": "wait_frames", "frames": _DIALOGUE_FADE_IN_FRAMES},

		{
			"op": "assert_eventually",
			"desc": "TopDialogueOverlay becomes visible during intro",
			"fn": Callable(self, "_assert_dialogue_visible"),
			"timeout_frames": 60,
			"poll_every_frames": 1,
		},

		{"op": "log", "msg": "phase 2: tap TAB to skip typewriter on line 1"},
		{"op": "tap", "key": KEY_TAB, "frames": _TAB_SKIP_TAP_FRAMES},

		{"op": "log", "msg": "phase 3: wait between lines and tap TAB again on line 2/3"},
		{"op": "wait_frames", "frames": _BETWEEN_LINES_WAIT_FRAMES},
		{"op": "hold", "key": KEY_TAB, "frames": _SECOND_TAB_HOLD_FRAMES},

		{"op": "log", "msg": "phase 4: walk right toward door (alt interact path)"},
		{"op": "hold", "key": KEY_D, "frames": _WALK_FRAMES_RIGHT},

		{"op": "log", "msg": "phase 5: settle frames after walk"},
		{"op": "wait_frames", "frames": _SETTLE_FRAMES_AFTER_WALK},

		{
			"op": "assert",
			"desc": "player overlaps door interact area before tapping SPACE",
			"fn": Callable(self, "_assert_player_in_door_interact_area"),
		},

		{"op": "log", "msg": "phase 6: tap SPACE (alt interact key) to trigger door"},
		{"op": "tap", "key": KEY_SPACE, "frames": _INTERACT_TAP_FRAMES},

		{"op": "log", "msg": "phase 7: await scene transition to corridor"},
		{
			"op": "assert_eventually",
			"desc": "current_scene becomes 1.2_Corridor.tscn after SPACE interact",
			"fn": Callable(self, "_assert_corridor_loaded"),
			"timeout_frames": _TRANSITION_TIMEOUT_FRAMES,
			"poll_every_frames": 1,
		},
	]

	var ok := await runner.run(commands)
	driver.release_all()

	if not ok:
		push_error("Bot FAIL [%s]" % runner.failure_summary())
		_dump_diagnostics(driver)
		return false

	print("Bot dialogue/interact commands executed: %d, physics_frames=%d" % [
		runner.commands_executed, driver.physics_frame()
	])
	_print_bot_metrics(driver, runner, true)
	return true


func _print_bot_metrics(driver, runner: BotScenarioRunner, transition_ok: bool) -> void:
	var payload := {
		"bot": "dialogue_loop",
		"scene_start": _SCENE_EXTERIOR,
		"scene_end": _SCENE_CORRIDOR,
		"physics_frames": driver.physics_frame(),
		"commands_executed": runner.commands_executed,
		"walk_frames_right": _WALK_FRAMES_RIGHT,
		"interact_key": "SPACE",
		"transition_ok": transition_ok,
	}
	print("BOT_METRICS_JSON %s" % JSON.stringify(payload))


func _assert_dialogue_visible() -> bool:
	var overlay := _find_dialogue_overlay()
	if overlay == null:
		return false
	var fade_root := overlay.get_node_or_null("RootMargin")
	if fade_root == null:
		return false
	return bool(fade_root.visible)


func _find_dialogue_overlay() -> CanvasLayer:
	if current_scene == null:
		return null
	# Exterior root has child `TopDialogueOverlay` per `1.1_SchoolExterior.tscn`.
	var node := current_scene.get_node_or_null("TopDialogueOverlay")
	if node is CanvasLayer:
		return node as CanvasLayer
	# Corridor root also embeds it; if scene already transitioned, look there.
	for child in current_scene.get_children():
		if child is CanvasLayer and String(child.name) == "TopDialogueOverlay":
			return child as CanvasLayer
	return null


func _assert_player_in_door_interact_area() -> bool:
	if current_scene == null:
		return false
	var area: Area2D = current_scene.get_node_or_null(
		"1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea"
	)
	var player: CharacterBody2D = current_scene.get_node_or_null("PlayerLayer/Player")
	if area == null or player == null:
		return false
	for body in area.get_overlapping_bodies():
		if body == player:
			return true
	return false


func _assert_corridor_loaded() -> bool:
	if current_scene == null:
		return false
	return current_scene.scene_file_path == _SCENE_CORRIDOR


func _dump_diagnostics(driver) -> void:
	print("--- Bot diagnostics ---")
	print("physics_frame=%d, held_keys=%s" % [
		driver.physics_frame(), str(driver.held_keys())
	])
	if current_scene != null:
		print("current_scene.scene_file_path=%s" % current_scene.scene_file_path)
		var player: CharacterBody2D = current_scene.get_node_or_null("PlayerLayer/Player")
		if player != null:
			print("player.position=%s" % str(player.position))
		var overlay := _find_dialogue_overlay()
		if overlay != null:
			var fade_root := overlay.get_node_or_null("RootMargin")
			print("dialogue_overlay.visible=%s" % str(
				fade_root != null and fade_root.visible
			))
	print("recent events (last 12): %s" % str(driver.event_log().slice(-12)))
	print("-----------------------")
