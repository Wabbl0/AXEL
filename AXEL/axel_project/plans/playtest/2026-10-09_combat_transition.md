# Combat transition: symmetric bars + 3 new styles

## Context
Playtest (v0.1.3) asked for a symmetric combat transition, with all bars moving together and red and black bars crossing the same way, plus three more transitions in the same simple style.

How it works now ([combat_wipe_overlay.gd](AXEL/axel_project/scenes/fx/combat_wipe_overlay.gd)):
- 12 rows. Red rows (even) grow from the left and black rows (odd) grow from the right, all driven by one shared `fill` value.
- Why it still looks off:
  1. **Open runs backwards.** After the fight loads, the bars slide back the way they came instead of crossing over.
  2. **12 rows is an even number.** The top row is red and the bottom row is black, so the screen is not mirrored top to bottom.
  3. **Rows overlap.** Each row is `ceilf(bar_h) + 1` tall, so every black row covers 1–2 px of the red row above it, and the rows end up slightly different sizes.
  4. **Choppy timing during the scene load.** The loop adds a fixed 0.016 s per timer tick, so the open stutters and drags while the combat scene's first frames are heavy.

Decisions you made: bars **pass through** (red leaves right, black leaves left). Each fight gets a **random** style, never the same twice in a row. The new styles are **Blinds, Slash and Center split**.

## Approach
Each style is the same simple building block: N flat red/black `ColorRect`s, moved by **one progress value `p`**.
- `p = 0`: hidden. `p = 1`: screen covered. `p = 2`: gone.
- Close tweens `p` from 0 to 1. Open tweens it from 1 to 2.
- Each frame, one layout call places every piece from that same `p`. That is why all bars always move at the same time.

### 1. `scenes/fx/combat_wipe_overlay.gd` (main change, still one file)
- `BAR_COUNT := 13` (an odd number), so the top and bottom rows are both red and the layout mirrors top to bottom. Even index = red, odd = black (same colors as now).
- Pixel-snapped rows: `y0 = round(i*h)`, `y1 = round((i+1)*h)`. No overlap and no gaps, so every row is equal.
- `enum Style { BARS, BLINDS, SLASH, CENTER_SPLIT }`, plus `var _style` and `var _progress`.
- **Two pieces per row** (`_pieces`, size `BAR_COUNT * 2`). Center split needs two. The other styles hide the second piece.
- Split the nodes:
  - `_bars_root` is a Control that can be rotated (for Slash).
  - `_flash` becomes a separate full-screen sibling, so it never rotates.
- `close_wipe(style: int = Style.BARS)` stores `_style`, plays the existing flashes (still skipped by `reduce_flashing`), then animates `p` from 0 to 1.
- `open_wipe()` animates `p` from 1 to 2 with the stored style, then calls `_set_hidden()`.
- `_layout(p)` sets the frame for `_bars_root`, then calls the layout function for the current style. In the formulas, `W` is the area width, `c = clamp(p,0,1)` and `q = clamp(p-1,0,1)`.

| Style | Close (p 0→1) | Open (p 1→2) |
|---|---|---|
| **Bars** | Red: `x=0, w=W*c`. Black is the exact mirror: `x=W-W*c`. | Red keeps going right: `x=W*q, w=W*(1-q)`. Black keeps going left: `x=0, w=W*(1-q)`. |
| **Blinds** | Each row grows taller from its own middle line: `h_row * c`. Same for red and black. | It shrinks back to that line: `h_row * (1-q)`. |
| **Slash** | Same formulas as Bars, inside `_bars_root` rotated −20° around the screen center. | Same as Bars. |
| **Center split** | Piece A covers `[W/2 − W/2*c, W/2]` and piece B covers `[W/2, W/2 + W/2*c]`. Both colors move the same way. | The halves part at the center and slide off to the edges, like doors opening: A ends at `W/2 − W/2*q`, B starts at `W/2 + W/2*q`. |

- Frame for `_bars_root`:
  - Every style except Slash uses the full viewport, with rotation 0.
  - Slash uses a square with side `D = ceil(sqrt(W² + H²))`, centered on the screen with `pivot_offset = D/2` and rotation `deg_to_rad(-20)`. This way the tilted bars still cover all four corners at `p = 1`.
- Timing: replace the fixed-step `_tween_bars` with `_tween_progress(from, to, duration)`:
  - It awaits `get_tree().process_frame` and measures real time with `Time.get_ticks_usec()`.
  - Each frame's step is capped at 1/30 s, so one long load hitch cannot skip the whole animation.
  - Keep the same smoothstep easing and the same `CLOSE_SEC` / `OPEN_SEC`. It works while paused, because `process_frame` still fires and the layer is `PROCESS_MODE_ALWAYS`.
  - No `Engine.time_scale`.
- `size_changed` calls `_layout(_progress)`, so a resize keeps the current state.
- `is_covered()`, `clear_now()` and the `_busy` guard keep their current behavior.

### 2. `scripts/autoload/axel_event_fx.gd` (`play_combat_wipe`, ~L694)
- Add `var _wipe_rng := RandomNumberGenerator.new()`, randomized once in `_ready`, and `var _last_wipe_style := -1`.
- Pick a random style that is not `_last_wipe_style`, then call `close_wipe(style)`.
- This RNG belongs only to this visual effect. It never touches the combat seed, so combat stays deterministic.
- Add `func set_next_wipe_style(style: int)`. This one-shot override is used by the new check and by dev testing.

### 3. Nothing changes in the callers
`AxelRun.enter_world_encounter` and `combat_test.gd:_clear_combat_wipe` keep calling the same API.

### 4. New check: `tools/qa/combat_wipe_styles_check.gd`
Headless, with `root.size = Vector2i(1920,1280)`. For each of the 4 styles, it builds the overlay and calls `_layout(p)` directly:
- **Coverage.** Sample a 48×32 grid of screen points, using each piece's global transform so Slash rotation counts:
  - `p=0`: 0% covered.
  - `p=1`: 100% covered.
  - `p=2`: 0% covered.
- **Symmetry.**
  - Row colors are mirrored top to bottom: `color[i] == color[12-i]`.
  - For Bars and Slash, at p = 0.3, 1.0 and 1.6, the red rect equals the mirrored black rect (`x_red == W − x_black − w_black`).
  - All rows have equal height (±1 px).
- **Pass-through.** In Bars at p = 1.5, red pieces sit in the right half and black pieces in the left half.
- **Random pick.** Over 50 picks from `play_combat_wipe`, no style repeats twice in a row, and all 4 appear.

### 5. Docs
- Save this plan as `plans/playtest/2026-10-09_combat_transition.md`.
- Update `plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md` (step 5 at ~L169, the "red-bar wipe" line): 4 random styles, pass-through, 13 rows.
- Add one line to `AI_DOCS.md` near the AxelEventFx line (~L80): "Combat wipe: 4 styles (Bars, Blinds, Slash, Center split), random per fight, never repeated back to back. Visual RNG only, never combat RNG."

## Rules kept
No comments in scripts. No `Engine.time_scale`. Combat RNG untouched. Same layer (200) and same SFX cue. Reduce-flashing still skips the flashes.

## Verification
Run from the repo root with `tools\cmd\godot.cmd`, `--import` first:
1. `tools/qa/combat_wipe_styles_check.gd` (new)
2. `tools/qa/world_combat_roundtrip_check.gd` (the wipe still opens and does not stay covering)
3. `tools/scene_smoke_check.gd`, `pause_contract_check.gd`, `combat/test/determinism_check.gd`, `combat/combat_test_scaffold_check.gd`
4. In game: trigger about 6 world fights. Check all 4 styles, no back-to-back repeat, a smooth open while the board loads, and no stray red/black strip at the edges in Slash.
