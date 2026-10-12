# Skull Fluid premium meter: design plan

## As built (2026-10-12)
- **Shader:** `combat/shaders/skull_fluid.gdshader`.
- **Skull script:** `premium_skull_meter.gd` gained these functions:
  - `_ensure_fluid`, `_tick_fluid`, `_retarget_fluid`
  - `play_spit(big)`
  - `fluid_level()`, `fluid_layer()`, `is_spitting()`, `spit_amount()`
- **Signal:** `CombatRoot.vice_round_cleared` is emitted once, in `_finish_trinity_round` when `_pending_free_spins` is set. All 4 clear paths end there.
- **Wiring:** `combat_test.gd` connects `vice_round_cleared` to the big spit. `free_spins_bonus_granted` plays the small spit.
- **Spit details:**
  - It comes from `SPIT_POS` (346, 660), the open mouth of the full-face art, not from `MOUTH_POS`.
  - A big spit throws 90 drops. A small one throws 36.
  - The skull gulps the fluid up to full for 0.12 s, then drains it in 0.55 s (0.41 s for the small spit).
- **Pause:** there is no hide-while-paused step. The pause menu (250), settings (200) and tutorial cards (114+) are all above layer 95.
- **Tutorial glow:** when the tutorial highlight glow (layer 93) is on the skull, it also turns the art white. During that lesson, a full skull reads as all white.

## Context
The spin-button skull (`HudCanvas/NEW_Execute/PremiumSkull`) shows the premium meter today by swapping 3 skull drawings (`axel_skull_1/2/3.png`). You want a living fluid inside the skull. It rises from the bottom as the meter fills, shows as true white on screen, and is spat out when the Vice Round is cleared. Today nothing on screen marks the Vice clear. There is only a pause before the Free Spins power choice, so the spit fills that gap.

Decisions (your answers):
- **White:** the fluid is drawn on its own layer above the noir filter, so it is real white. It is the only true white on screen. Scanlines and CRT still cover it.
- **Spit timing:** right at the Vice clear, before the Free Spins power choice appears.
- **Free Spins:** the fluid refills. When the meter fills and grants bonus spins, the skull does a smaller spit.

## How it works (plain version)
1. **Fluid shape:** a shader on a rectangle the size of the skull. It uses the current skull drawing as a stencil (cut-out guide). Fluid only appears on the light "bone" pixels. Black lines, eyes and nose stay visible on top, so the skull face reads through the fluid.
2. **Wave:** the top of the fluid is 2 overlapping sine waves that move over time. When the level changes, a short "slosh" makes the waves taller, then they settle. A thin brighter foam line runs along the surface.
3. **Level:** the meter has 4 steps (0, 1/3, 2/3, full). The fluid does not jump. It rises smoothly to the new step (tween, about 0.5 s, bound through `CombatPace`).
4. **Above the filter:** the fluid sits on a new `CanvasLayer` at layer **95** (noir is 90, scanline 105, CRT 108). Each frame it copies the skull's on-screen position, scale and tilt, so it follows the breathing, punches, shakes and Free Spins lift. It also copies the skull's fade (busy alpha). It hides while the game is paused, so it can never float over the pause menu.
5. **Spit (Vice clear):** the skull punches (reuse `_punch_tween`). White droplets burst out of the mouth (`MOUTH_POS` 346,560) in an arc with gravity, using a white `CPUParticles2D` on the same layer 95. At the same time the fluid level drains to 0 in about 0.6 s with big waves. Total length is about 0.9 s and fits inside the existing `free_spin_handoff_pause_sec`. If it doesn't fit, that pause is raised to match.
6. **Small spit (Free Spins bonus):** the same effect at about 40% of the droplets and size.

## Code changes
**New files**
- `combat/shaders/skull_fluid.gdshader`, with these uniforms:
  - `mask_tex`: the current skull stage texture
  - `level` (0–1)
  - `wave_amp`, `wave_speed`, `slosh`, `foam_px`
  - `bone_min`: the brightness threshold, so fluid only covers bone and not lines
  - output is pure white

**Edited files**
- `combat/scripts/premium_skull_meter.gd`. All of these new functions copy the patterns that already exist (`_ensure_flame_crown`, `_ensure_embers`, `_emit_burst`):
  - `_ensure_fluid()`: builds the layer 95, the fluid rect and the white spit particles.
  - `_tick_fluid()`: called from the existing per-frame `_tick_feel`. It copies the skull's global canvas transform and alpha, swaps `mask_tex` when the stage changes, and hides the fluid while paused.
  - `set_fill()` (line 742) also tweens the fluid level. While a spit is playing, an incoming `set_fill(0)` is ignored, because the spit drains the fluid itself.
  - `play_spit(big: bool)`: the punch, the droplets, then the fluid drains.
  - `_exit_tree`: frees the layer.
- `combat/scripts/combat_root.gd`. Combat logic stays deterministic, because this only adds a UI signal:
  - New `signal vice_round_cleared`.
  - Emit it where the grid is cleared and `_pending_free_spins = true` is set. There are 4 places: the main loop at about 2414, the first-miss path at about 2353 and 2372, and the sync variant at about 2447. To avoid copying it 4 times, emit it once from one small helper.
- `combat/scripts/combat_test.gd`:
  - Connect `vice_round_cleared` → `_premium_skull.play_spit(true)`, next to the existing connects at about 777–782.
  - In the existing `free_spins_bonus_granted` listener (about 3145), add `_premium_skull.play_spit(false)`.

Not touched:
- `meter.gd`, items, seeds.
- The 3 skull drawings and their stage swaps. They stay as they are. The fluid sits on top of them.
- The noir filter shader.

## Docs (after it works)
- Save this plan as `plans/combat/AXEL_SKULL_FLUID_PLAN.md`.
- `plans/core/AI_DOCS.md`, palette section: add one rule. "Skull fluid is the single allowed true-white element; it renders on layer 95 above the noir filter, below scanline/CRT."
- `plans/combat/AXEL_combat_implementation.md`, skull HUD notes (about lines 442–443): add the fluid and the spit.

## Verification
Run all checks with `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://...`, in this order:
1. Before any edit: `combat/test/combat_test_scaffold_check.gd`.
2. New `tools/qa/skull_fluid_check.gd`, with root size 1920×1280. It checks:
   - the fluid layer exists at layer 95
   - `set_fill(1/3)`, then `(2/3)`, then `(1)` makes the shader `level` reach each value
   - `play_spit(true)` brings `level` to 0, even with a `set_fill(0)` arriving mid-spit
   - the fluid is hidden while paused
3. The existing checks:
   - `determinism_check.gd`
   - `powers_check.gd`
   - `combat_test_scaffold_check.gd`
   - `tools/qa/skull_feel_check.gd`
   - `combat/test/free_spins_choice_ui_check.gd`
   - `tools/qa/combat_pace_check.gd`
   - `tools/scene_smoke_check.gd`
4. In Godot, play `combat_test.tscn` with the dev "guarantee Vice" fill. Watch for:
   - the fluid rising in 3 steps
   - the face lines visible through it
   - the fluid staying white under the CRT
   - the spit on the Vice clear, before the power choice
   - a smaller spit on a Free Spins meter bonus
   - the fluid following the skull's shake and lift
