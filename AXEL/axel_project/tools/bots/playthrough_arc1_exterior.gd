extends SceneTree
## Headless playthrough bot: Arc 1 / 1.1 School Exterior.
##
## Verifies real-input fidelity for the overworld traversal + interaction loop.
## Synthesizes physical key events through `Input.parse_input_event()` so the
## same code paths a player exercises (`Player.gd::_physics_process` polling,
## `1.1_SchoolExterior.gd::_unhandled_input` interaction handler) are driven.
##
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_arc1_exterior.gd
##
## Exit codes:
##   0 = scene loaded, player walked to door, interaction key triggered
##       transition to 1.2_Corridor.tscn within timeout.
##   1 = any phase failed (load, traversal, interaction, transition assertion).

const InputEventDriverScript := preload("res://tools/bots/input_event_driver.gd")
const BotScenarioRunnerScript := preload("res://tools/bots/scenario_runner.gd")

const _SCENE_EXTERIOR := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const _SCENE_CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"

## Player starts ~ (120, 360); door interact area spans roughly x=959..1039 at y~360.
## Speed 180 px/s at 60 Hz physics = 3 px / frame; ~290 frames to traverse + buffer.
const _WALK_FRAMES_RIGHT := 340
const _SETTLE_FRAMES_AFTER_WALK := 6
const _INTERACT_TAP_FRAMES := 3
const _TRANSITION_TIMEOUT_FRAMES := 240
const _SCENE_READY_GRACE_FRAMES := 4
const _VERBOSE := true


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var ok := await _run_playthrough()
	if ok:
		print("Arc1 exterior playthrough OK.")
		quit(0)
	else:
		push_error("Arc1 exterior playthrough FAILED.")
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

	# Allow the deferred scene change to install current_scene + run _ready.
	for _i in _SCENE_READY_GRACE_FRAMES:
		await process_frame

	if current_scene == null:
		push_error("Bot FAIL: current_scene is null after change_scene_to_file.")
		return false
	if current_scene.scene_file_path != _SCENE_EXTERIOR:
		push_error("Bot FAIL: expected current_scene=%s, got %s" % [
			_SCENE_EXTERIOR, current_scene.scene_file_path
		])
		return false

	var driver := InputEventDriverScript.new(self, _VERBOSE)
	var runner := BotScenarioRunnerScript.new(self, driver, _VERBOSE)

	var commands: Array = [
		{"op": "log", "msg": "phase 1: warm up frames"},
		{"op": "wait_frames", "frames": 4},

		{"op": "log", "msg": "phase 2: walk right toward door"},
		{"op": "hold", "key": KEY_D, "frames": _WALK_FRAMES_RIGHT},

		{"op": "log", "msg": "phase 3: settle frames after walk"},
		{"op": "wait_frames", "frames": _SETTLE_FRAMES_AFTER_WALK},

		{
			"op": "assert",
			"desc": "player overlaps door interact area before tapping E",
			"fn": Callable(self, "_assert_player_in_door_interact_area"),
		},

		{"op": "log", "msg": "phase 4: tap interaction key (E)"},
		{"op": "tap", "key": KEY_E, "frames": _INTERACT_TAP_FRAMES},

		{"op": "log", "msg": "phase 5: await scene transition to corridor"},
		{
			"op": "assert_eventually",
			"desc": "current_scene becomes 1.2_Corridor.tscn",
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

	print("Bot exterior commands executed: %d, physics_frames=%d" % [
		runner.commands_executed, driver.physics_frame()
	])
	_print_bot_metrics(driver, runner, true)
	return true


func _print_bot_metrics(driver, runner: BotScenarioRunner, transition_ok: bool) -> void:
	var payload := {
		"bot": "arc1_exterior",
		"scene_start": _SCENE_EXTERIOR,
		"scene_end": _SCENE_CORRIDOR,
		"physics_frames": driver.physics_frame(),
		"commands_executed": runner.commands_executed,
		"walk_frames_right": _WALK_FRAMES_RIGHT,
		"interact_key": "E",
		"transition_ok": transition_ok,
	}
	print("BOT_METRICS_JSON %s" % JSON.stringify(payload))


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
	print("recent events (last 8): %s" % str(driver.event_log().slice(-8)))
	print("-----------------------")
