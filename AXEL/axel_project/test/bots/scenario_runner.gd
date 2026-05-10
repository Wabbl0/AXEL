extends RefCounted
class_name BotScenarioRunner

## Deterministic command-list interpreter for AXEL playthrough bots.
##
## Scenarios are arrays of dictionaries. Each command has an `op` string and
## op-specific fields. The runner sequences commands in order, advancing the
## scene tree between actions, and emits a structured log on failure so the
## first broken assertion can be diagnosed without a live UI.
##
## Supported ops (all lowercase strings):
##   {"op": "press",        "key": KEY_W}
##   {"op": "release",      "key": KEY_W}
##   {"op": "release_all"}
##   {"op": "tap",          "key": KEY_E, "frames": 2}            # frames optional, default 1
##   {"op": "hold",         "key": KEY_D, "frames": 300}          # press, wait, release
##   {"op": "wait_frames",  "frames": 10}                          # physics frames
##   {"op": "wait_process_frames", "frames": 10}
##   {"op": "wait_seconds", "seconds": 1.0}
##   {"op": "log",          "msg": "phase 2 entered"}
##   {"op": "assert",       "fn": Callable, "desc": "..."}         # one-shot
##   {"op": "assert_eventually",
##                          "fn": Callable, "desc": "...",
##                          "timeout_frames": 120,
##                          "poll_every_frames": 1}                 # polls each tick
##
## Callables for assertions take no args and return bool. The runner stores the
## last failure context so the test driver can print/log a clean diagnostic.

const _DEFAULT_EVENTUAL_TIMEOUT_FRAMES := 240
const _DEFAULT_EVENTUAL_POLL := 1

var _tree: SceneTree
var _driver  # InputEventDriver (untyped to avoid load-order dependency on class_name cache)
var _verbose: bool

var last_error: String = ""
var last_failed_index: int = -1
var last_failed_op: String = ""
var commands_executed: int = 0


func _init(tree: SceneTree, input_driver, verbose: bool = false) -> void:
	_tree = tree
	_driver = input_driver
	_verbose = verbose


func driver():
	return _driver


## Execute a scenario command list. Returns true on success, false on first failure.
## On failure, callers can read `last_error`, `last_failed_index`, `last_failed_op`.
func run(commands: Array) -> bool:
	commands_executed = 0
	for i in commands.size():
		var cmd: Dictionary = commands[i]
		var op := String(cmd.get("op", ""))
		if _verbose:
			print("[bot.scenario] step=%d op=%s frame=%d" % [
				i, op, _driver.physics_frame()
			])
		var ok := await _execute(op, cmd)
		if not ok:
			last_failed_index = i
			last_failed_op = op
			_driver.release_all()
			return false
		commands_executed += 1
	return true


func _execute(op: String, cmd: Dictionary) -> bool:
	match op:
		"press":
			_driver.press(int(cmd.get("key", 0)))
			return true
		"release":
			_driver.release(int(cmd.get("key", 0)))
			return true
		"release_all":
			_driver.release_all()
			return true
		"tap":
			await _driver.tap(int(cmd.get("key", 0)), int(cmd.get("frames", 1)))
			return true
		"hold":
			await _driver.hold_for_frames(
				int(cmd.get("key", 0)),
				int(cmd.get("frames", 1))
			)
			return true
		"wait_frames":
			await _driver.await_physics_frames(int(cmd.get("frames", 0)))
			return true
		"wait_process_frames":
			await _driver.await_process_frames(int(cmd.get("frames", 0)))
			return true
		"wait_seconds":
			var seconds := float(cmd.get("seconds", 0.0))
			if seconds > 0.0:
				await _tree.create_timer(seconds).timeout
			return true
		"log":
			print("[bot.scenario] %s" % String(cmd.get("msg", "")))
			return true
		"assert":
			return _run_assert(cmd)
		"assert_eventually":
			return await _run_assert_eventually(cmd)
		_:
			last_error = "Unknown op: %s" % op
			return false


func _run_assert(cmd: Dictionary) -> bool:
	var fn: Callable = cmd.get("fn", Callable())
	var desc := String(cmd.get("desc", "<no desc>"))
	if not fn.is_valid():
		last_error = "assert: invalid Callable for desc=%s" % desc
		return false
	var result: Variant = fn.call()
	if typeof(result) != TYPE_BOOL:
		last_error = "assert: non-bool return for desc=%s (got %s)" % [
			desc, typeof(result)
		]
		return false
	if not result:
		last_error = "assert FAILED: %s (frame=%d)" % [desc, _driver.physics_frame()]
		return false
	if _verbose:
		print("[bot.assert.OK] %s" % desc)
	return true


func _run_assert_eventually(cmd: Dictionary) -> bool:
	var fn: Callable = cmd.get("fn", Callable())
	var desc := String(cmd.get("desc", "<no desc>"))
	var timeout_frames := int(cmd.get("timeout_frames", _DEFAULT_EVENTUAL_TIMEOUT_FRAMES))
	var poll_every := maxi(int(cmd.get("poll_every_frames", _DEFAULT_EVENTUAL_POLL)), 1)
	if not fn.is_valid():
		last_error = "assert_eventually: invalid Callable for desc=%s" % desc
		return false
	var elapsed := 0
	while elapsed <= timeout_frames:
		var result: Variant = fn.call()
		if typeof(result) == TYPE_BOOL and bool(result):
			if _verbose:
				print("[bot.assert_eventually.OK] %s after %d frames" % [desc, elapsed])
			return true
		await _driver.await_physics_frames(poll_every)
		elapsed += poll_every
	last_error = "assert_eventually TIMEOUT after %d frames: %s" % [timeout_frames, desc]
	return false


## Build a single-line failure summary suitable for `push_error` / log dumps.
func failure_summary() -> String:
	if last_failed_index < 0:
		return "no failure"
	return "step=%d op=%s frame=%d: %s" % [
		last_failed_index,
		last_failed_op,
		_driver.physics_frame(),
		last_error,
	]
