# Plan: CRT wave color 33% less opaque

Plan only. Do not implement in the planning chat.

## What you asked

The CRT wave effect’s color should be 33% less opaque.

## What the game does now

The wave is the black rolling band on `scenes/fx/InterfacePulseOverlay.tscn` (layer 112), shader `tools/visual_style/shaders/option_1_crt_tv.gdshader`.

The mix is:

`col = mix(col, roll_color, wave * roll_color_strength)`

`roll_color` is black. `roll_color_strength` is `0.5`. The QA script `tools/qa/interface_pulse_dialogue_check.gd` calls this value “wave opacity” and expects about `0.50`.

Two other fades are not the wave color:

- Quiet pulse alpha `0.20` (`BASELINE_ALPHA`)
- Surge peak alpha `0.536` (`SURGE_ALPHA`)

Combat does not use this wave. Combat CRT is the flat `CrtCombatOverlay`.

## Locked choice

Change only `roll_color_strength`.

`0.5 × (1 - 0.33) = 0.335`

Leave the quiet pulse, the surge, the warp (`0.0045`), curvature, chroma, and vignette alone. The wave stays black. This is not a recolor of the shimmer.

## Steps

1. In `InterfacePulseOverlay.tscn`, set `shader_parameter/roll_color_strength` from `0.5` to `0.335`.
2. In `interface_pulse_dialogue_check.gd`, expect `0.335` (keep a small tolerance, about `0.02`).
3. In `plans/references/AXEL_OVERWORLD_EVENT_FX.md`, change the strength `0.50` sentence to `0.335`.
4. Do not edit the old changelog line that records the previous `0.50`. Add a new changelog entry when this ships.
5. Do not change `AI_DOCS.md` rest/surge numbers. They are different knobs.

## What you should see

The black roll across the overworld and menus is fainter. The picture still shifts by the same amount. Combat looks the same.

## How to test

1. Run `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/interface_pulse_dialogue_check.gd` and expect exit 0.
2. Play `1.1` windowed (not headless) and watch one roll. It should read as a lighter black band than before.
3. Headless does not compile shaders. After the edit, a short windowed run should print no `SHADER ERROR`.

## Risks

- If the band still feels as strong, the next knob would be `SURGE_ALPHA`, not this one. Do not change it in this task.

## When this ships

Update the event-FX plan line and add a changelog entry.
