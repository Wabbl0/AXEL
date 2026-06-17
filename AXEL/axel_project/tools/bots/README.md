# AXEL Overworld Playthrough Bots

High-fidelity headless bots that simulate a real player by synthesizing
`InputEventKey` events through the engine input pipeline. Used by
`run_default_playtest.ps1`
playtest mode to gate overworld scene flow (movement, dialogue, interaction)
in addition to the existing combat headless checks.

## Architecture

```
playthrough_*.gd  (SceneTree script, the scenario)
        |
        v
scenario_runner.gd  (interprets command list, runs assertions)
        |
        v
input_event_driver.gd  (Input.parse_input_event for press/release/hold/tap)
        |
        v
SceneTree -> Player.gd / *.gd::_unhandled_input / TopDialogueOverlay.gd::_input
```

Synthetic events take the same path as real keyboard input:

- `Input.is_key_pressed()` polling in `scripts/Player.gd::_physics_process`
- `_unhandled_input(event)` in `scenes/Arc_1/1.1_SchoolExterior.gd`
- `_input(event)` in `scenes/ui/TopDialogueOverlay.gd`

## Files

| File | Role |
|------|------|
| `input_event_driver.gd` | Press/release/hold/tap utilities + physics-frame stepper. Tracks held keys + event log. |
| `scenario_runner.gd` | Interprets scenario command lists. Supports `press`, `release`, `release_all`, `tap`, `hold`, `wait_frames`, `wait_process_frames`, `wait_seconds`, `log`, `assert`, `assert_eventually`. Records first failure with frame + step context. |
| `playthrough_arc1_exterior.gd` | Bot 1: walks player right, taps `E`, asserts transition `1.1_SchoolExterior.tscn` -> `1.2_Corridor.tscn`. |
| `playthrough_dialogue_loop.gd` | Bot 2: drives `TopDialogueOverlay` full-line skip (Tab), then walks + taps `SPACE` (alternate interact key), asserts same transition. |

## Run

From repo root (Windows uses `tools\cmd\godot.cmd`):

```bat
:: Bot 1: walk + interact (KEY_E)
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_arc1_exterior.gd

:: Bot 2: dialogue skip (KEY_TAB) + walk + interact (KEY_SPACE)
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_dialogue_loop.gd
```

Both bots:

- Exit `0` on success, `1` on first failed assertion.
- On success, print `BOT_METRICS_JSON` (physics frames, interact key, transition flag) for QA analytics ingestion.
- Print verbose step-by-step trace (`[bot.scenario] step=N op=...`) plus
  per-event input log (`[bot.input] frame=N PRESS keycode=...`) so failures
  pinpoint the exact frame and command index.
- Dump diagnostics on failure (current scene path, player position, last
  events) before exiting non-zero.

## Determinism notes

- Both bots step time via `await tree.physics_frame`, which fires at the
  fixed physics rate (60 Hz default). Movement integration in
  `Player.gd::_physics_process` is therefore deterministic across runs.
- `Input.parse_input_event()` updates `Input` polling state and dispatches
  callbacks synchronously, so a press emitted on frame N is observable on
  frame N+1's `_physics_process`.
- Walk durations are sized for player `speed=180` px/s and door
  `InteractArea` x-range `~959..1039`, with ~50-70 frame buffer.

## Authoring new scenarios

Scenarios are arrays of dictionaries. Minimum example:

```gdscript
const InputEventDriverScript := preload("res://tools/bots/input_event_driver.gd")
const BotScenarioRunnerScript := preload("res://tools/bots/scenario_runner.gd")

var driver := InputEventDriverScript.new(self, true)
var runner := BotScenarioRunnerScript.new(self, driver, true)

var commands: Array = [
    {"op": "wait_frames", "frames": 4},
    {"op": "hold", "key": KEY_W, "frames": 60},
    {"op": "tap",  "key": KEY_E, "frames": 2},
    {
        "op": "assert_eventually",
        "desc": "expected state reached",
        "fn": Callable(self, "_my_check"),
        "timeout_frames": 120,
    },
]

if not await runner.run(commands):
    push_error(runner.failure_summary())
    quit(1)
```

Always end scenarios via `driver.release_all()` (the runner does this
automatically on failure). Prefer `wait_frames` (physics) over
`wait_seconds` (wall clock) for deterministic timing.

## Plan-step 4 canon resolution

Plan step 4 originally targeted `scripts/GameController.gd`. Per
`plans/core/archive/AI_CHANGELOG_2026.md` (2026-05-08 "Restore SchoolExterior Full Layout"),
that script was deliberately stripped from active scenes. Per
`plans/core/AI_DOCS.md` canon hierarchy, we did **not** resurrect it via a
synthetic test scene (would violate "no architecture-layer mixing without
intent"). `playthrough_dialogue_loop.gd` covers the same intent (dialogue
advance/skip + interaction + state assertion) using currently-wired
`TopDialogueOverlay` (Tab / E / Space / Enter / click skip while bar visible)
+ `1.1_SchoolExterior` interaction handler.
