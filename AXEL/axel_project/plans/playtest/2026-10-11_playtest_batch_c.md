# 2026-10-11 Playtest fixes, batch C

Rule from this playtest: **update and check in Godot first, then export.** (Saved in the `release-build` skill, step 0.)

## Fixes
1. **Tutorial glow looked like an offset shadow.** `piece_highlight_glow.gdshader` did not compile in Godot 4.7 (`TEXTURE` used inside a helper function). The copy drew raw art, offset by the bloom pad. Fix: pass the sampler into `ink_at(tex, uv)`.
2. **"? Fights ?" card too tall.** `_place_over_skull` stretched the gated card to the skull's height. It now keeps its text height and stays centered on the skull. Spinning is still blocked by `blocks_spin`.
3. **Skull burst point.** The skull ignores the mouse, so the press point was never set. `set_pressed` now reads the mouse position on a left click. E / Space bursts from `FACE_POS`, between the eyes and the nose.
4. **Skull hover outline.** A white silhouette outline (shader mode 2) on `HudHighlightLayer` fades in on hover when a spin is allowed.
5. **Rush.** One press = only the running animation at 4× (`CombatPace.rush_beat`). Hold E (after 0.3s) or spam it to skip more. No more 3× → 8× stacking.
6. **Round Complete skulls.** They burst from the center toward every edge, float down on low gravity, bounce 2–3 times on the bottom, and fall off.
7. **Item cap count** font 40 → 60.
8. **Room edge line.** New autoload `AxelRoomEdge` draws a dark red frame on the room picture's four edges.
9. **Scratch Ticket / CRT Etching.** The cells show the owning item's rarity glyph (bottom-left) every spin. The item pulses only when a win crosses its own cell.
10. **Loss rule.** Lose only when BALANCE < 100. Below the current bet, the bet drops by itself to the largest affordable step.

## Checks
- `combat_pace_check.gd` (rewritten for beats), `powers_check.gd` (+ low balance, + glyph owner), and all CLAUDE.md checks.
- Captures: `tools/qa/tutorial_glow_capture.gd`, `tools/qa/glyph_mark_capture.gd` (windowed, not headless).

## Not in this batch
- The skull fluid premium meter: a design plan in a new session.
