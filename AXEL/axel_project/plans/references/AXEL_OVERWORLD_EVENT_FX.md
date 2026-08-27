# AXEL Overworld Event FX

Canonical reference for **event-tier** overworld visual effects — distinct from the passive baseline stack in `AxelPostFxStack`.

## Three-layer model

| Layer | Owner | Behavior |
|-------|-------|----------|
| **Baseline post-FX** | `AxelPostFxStack` autoload | Always-on 8-band inverted noir + scanline + CRT on non-combat scene enter |
| **Event-tier overlays** | `AxelEventFx` autoload | Always-on interference wave + scripted glitch bursts + interface pulse cadence |
| **Future micro-FX** | Per-scene (planned) | StoryBox text glitch, camera shake tweens, localized flashes |

Do **not** embed baseline noir/scanline/CRT in overworld `.tscn` files. Event overlays are owned globally by `AxelEventFx` — do not duplicate `IntroGlitchOverlay` / `InterfacePulseOverlay` in scene files.

## Autoload: `AxelEventFx`

Path: `res://scripts/autoload/axel_event_fx.gd`

### Scene-transition glitch

On every non-combat scene enter, plays a brief VHS glitch burst (`IntroGlitchOverlay`, layer 112).

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
- **Interface pulse / distortion** — “system interface” unease during movement or UI beats (distinct from glitch). The **interference wave** (rolling CRT band in `InterfacePulseOverlay`) is always on at a faint baseline in non-combat scenes; surges rise from that level and settle back.

### Always-on interference wave

On every non-combat scene enter (same opt-outs as cadence), `InterfacePulseOverlay` fades to a constant **baseline** alpha (`0.30`) and stays visible. This keeps the CRT interference wave present in the normal look instead of popping in from nothing.

**Surges** (scripted distortion, cadence pulses) rise to **peak** alpha (`0.80`, ~20% below the old full-strength pop) and fade back to baseline — not to zero.

Combat, `AXEL_DISABLE_POST_FX=1`, `AXEL_DISABLE_EVENT_FX=1`, and style-sweep scenes turn the wave off entirely.

### Interface cadence (passive)

While player has control in a non-combat scene, fires an interface pulse when **either**:

- Random timer elapses (**30–60 s**), or
- Player walks **40–90 steps** (8 px per step, input-enabled movement only)

Whichever fires first wins; both targets re-arm after each pulse. **Shared 30 s cooldown** blocks back-to-back triggers.

Step reporting: `Player.gd` → `AxelEventFx.register_walk_step()`.

Pause cadence during scripted intros via `set_cadence_enabled(false)`.

## Overlay provenance

| Overlay | Shader source | Role |
|---------|---------------|------|
| `IntroGlitchOverlay` | `tools/visual_style/shaders/option_2_vhs_glitch.gdshader` | Discrete burst |
| `InterfacePulseOverlay` | `tools/visual_style/shaders/option_1_crt_tv.gdshader` | Always-on interference wave + sustained / pulsed CRT surges. Pulse no longer warps, chroma-splits, or vignettes (`curvature`/`chroma`/`vignette`/`player_chroma` all `0` on the overlay) — keeps scanlines, roll, noise, and glitch bursts only so it does not peel a second lens off the baseline CRT. |

## Canvas layer stack

```
Noir 90 → Scanline 105 → CRT 108 → InterfacePulse 109 → InteractPrompt 110 → TopDialogue 111 → IntroGlitch 112
(Dialogue must draw above the `[E]` prompt.)
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

1. Disable cadence (ambient wave stays on)
2. Glitch burst (manual API — skips duplicate enter glitch)
3. 1 s wait
4. Start interface distortion (surges from baseline wave)
5. Scripted walk to stones
6. Stop distortion (settles back to baseline wave)
7. First dialogue → unlock controls → enable cadence
8. Second dialogue after ~50 px movement (scene-local, not event FX)
9. `InteractPromptOverlay` when player overlaps `DoorInteractArea` (intro unlocked); E/Space/Enter → `1.2_Corridor`

## Adding future event / jumpscare beats

1. Call `await AxelEventFx.play_glitch_burst()` at the beat moment in scene script.
2. For combo beats: `await AxelEventFx.play_jumpscare()`.
3. Pause cadence if the beat overlaps free movement: `set_cadence_enabled(false)` / `true`.
4. After implement, git commit; optional log in `plans/core/AI_CHANGELOG.md` on `update docs`.

Do not add new overlay instances to `.tscn` files — extend via the autoload API.
