# AXEL Overworld Event FX

Canonical reference for **event-tier** overworld visual effects — distinct from the passive baseline stack in `AxelPostFxStack`.

## Three-layer model

| Layer | Owner | Behavior |
|-------|-------|----------|
| **Baseline post-FX** | `AxelPostFxStack` autoload | Always-on 8-band inverted noir + scanline + CRT on non-combat scene enter |
| **Event-tier overlays** | `AxelEventFx` autoload | Pulse-only red interference wave + scripted glitch bursts + interface pulse cadence |
| **Future micro-FX** | Per-scene (planned) | StoryBox text glitch, camera shake tweens, localized flashes |

Do **not** embed baseline noir/scanline/CRT in overworld `.tscn` files. Event overlays are owned globally by `AxelEventFx` — do not duplicate `IntroGlitchOverlay` / `InterfacePulseOverlay` in scene files.

## Autoload: `AxelEventFx`

Path: `res://scripts/autoload/axel_event_fx.gd`

### Scene-transition glitch

On every non-combat scene enter, plays a brief VHS glitch burst (`IntroGlitchOverlay`, layer 113).

**Opt-outs:**

- Combat scenes (`res://combat/*`)
- `1.1_SchoolExterior` when forced intro runs (intro plays its own glitch; use `AXEL_SKIP_INTRO=1` to get enter glitch instead)
- `AXEL_DISABLE_POST_FX=1` or `AXEL_DISABLE_EVENT_FX=1`
- Scenes with `StyleSweepOverlays` node (style-sweep harness)

### Global event / jumpscare API

Call from any scene script — no per-scene overlay wiring:

```gdscript
await AxelEventFx.play_glitch_burst(0.85)          # VHS glitch burst
await AxelEventFx.play_interface_pulse(1.1)        # timed CRT pulse
AxelEventFx.start_interface_distortion()           # sustained CRT during scripted walk
await AxelEventFx.stop_interface_distortion()
await AxelEventFx.play_jumpscare()                 # glitch then pulse preset
AxelEventFx.set_cadence_enabled(false)             # pause random cadence (intro beats)
AxelEventFx.set_cadence_enabled(true)              # resume after intro unlock
```

**When to use:**

- **Glitch burst** — scene transitions (automatic), memory spikes, jumpscares, narrative corruption beats
- **Interface pulse / distortion** — “system interface” unease during movement or UI beats (distinct from glitch). The **interference wave** (rolling CRT band in `InterfacePulseOverlay`) is **pulse-only**: rest alpha is `0` (no always-on baseline after scene change). Surges come from `play_interface_pulse` / `play_pulse` (and scripted `start_interface_distortion`) and settle back to zero.

### Pulse-only interference wave

The wave does **not** stay on after scene change. `start_ambient()` is a no-op for visibility (rest `0`; it does not fade to `BASELINE_ALPHA` `0.20`). The roll is visible only during a pulse. A pulse **keeps going** if a dialogue line opens — do not stop it just because the bar is up. Layer 112 + viewport `BackBufferCopy` make the roll apply to the box.

**Surges** (scripted distortion, cadence pulses) rise to **peak** alpha (`0.536`) and fade back to rest `0`. The rolling line is **red only** (`option_1_crt_tv.gdshader` adds `vec3(roll_line * 0.12, 0.0, 0.0)`; `InterfacePulseOverlay` `FilterRect` color is `Color(1, 0, 0, 1)`).

Combat, `AXEL_DISABLE_POST_FX=1`, `AXEL_DISABLE_EVENT_FX=1`, and style-sweep scenes keep the wave off. `reduce_flashing` still skips pulses.

### Interface cadence (passive)

While the player has control in a non-combat scene, fires an interface pulse when a **30 s** timer elapses (`CADENCE_TIMER_MIN` / `MAX` both `30.0`). **No cooldown** (`CADENCE_COOLDOWN_SEC` `0.0`). Walk steps do **not** advance cadence — `Player.gd` still calls `AxelEventFx.register_walk_step()`, but that function is a no-op (kept so callers compile).

Pause cadence during scripted intros via `set_cadence_enabled(false)`.

## Overlay provenance

| Overlay | Shader source | Role |
|---------|---------------|------|
| `IntroGlitchOverlay` | `tools/visual_style/shaders/option_2_vhs_glitch.gdshader` | Discrete burst |
| `InterfacePulseOverlay` | `tools/visual_style/shaders/option_1_crt_tv.gdshader` | Pulse-only red interference wave + sustained / pulsed CRT surges. Pulse no longer warps, chroma-splits, or vignettes (`curvature`/`chroma`/`vignette`/`player_chroma` all `0` on the overlay) — keeps scanlines, red roll, noise, and glitch bursts only so it does not peel a second lens off the baseline CRT. |

## Canvas layer stack

```
Noir 90 → Scanline 105 → CRT 108 → InteractPrompt 110 → TopDialogue 111 → InterfacePulse 112 → IntroGlitch 113
(Dialogue must draw above the `[E]` prompt. The wave sits above the bar and recopies the viewport so the roll applies to the box.)
```

`InteractPromptOverlay` is scene-local (not `AxelEventFx`): CRT chip at door/proximity via `1.1_SchoolExterior.gd` + `EnvironmentColliders/Doors/DoorInteractArea`.

## Environment bypass flags

| Flag | Effect |
|------|--------|
| `AXEL_DISABLE_POST_FX=1` | Disables baseline stack **and** passive event FX (enter glitch + cadence) |
| `AXEL_DISABLE_EVENT_FX=1` | Disables passive event FX only; manual API calls still work |
| `AXEL_SKIP_INTRO=1` | Skips 1.1 forced intro; enter glitch plays on 1.1 load |

## Pilot reference: Arc 1.1 intro

Sequence in `1.1_SchoolExterior.gd`:

1. Disable cadence (wave stays at rest `0` — no always-on roll)
2. Glitch burst (manual API — skips duplicate enter glitch)
3. 1 s wait
4. Start interface distortion (red wave surges from rest `0`)
5. Scripted walk to stones
6. Unlock controls; first dialogue while the wave is still up (layer 112 samples the bar)
7. After the first line hides, stop distortion (settles back to rest `0`) and enable cadence
8. Second dialogue after ~50 px movement (scene-local, not event FX)
9. `InteractPromptOverlay` when player overlaps `DoorInteractArea` (intro unlocked); E/Space/Enter → `1.2_Corridor`

## Adding future event / jumpscare beats

1. Call `await AxelEventFx.play_glitch_burst()` at the beat moment in scene script.
2. For combo beats: `await AxelEventFx.play_jumpscare()`.
3. Pause cadence if the beat overlaps free movement: `set_cadence_enabled(false)` / `true`.
4. After implement, git commit; optional log in `plans/core/AI_CHANGELOG.md` on `update docs`.

Do not add new overlay instances to `.tscn` files — extend via the autoload API.
