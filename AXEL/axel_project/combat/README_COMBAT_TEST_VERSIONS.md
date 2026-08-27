# Combat Test UI

The playtest shell uses a **drawing-backed HUD**: white plate + one node per drawing under `%HudCanvas` (3508×2480 drawing pixels), integer economy readouts, and a dev item picker.

## Canonical entry

| Entry | Scene | Script |
|-------|-------|--------|
| **Default** | `res://combat/combat_test.tscn` | `scripts/combat_test.gd` |

## Launch

- Open `combat/combat_test.tscn` → **F6** (Play Scene).

Headless combat checks (`princess_check`, `determinism_check`) use `combat_root.tscn` only — not this shell.

## HUD features

- `%HudCanvas` + `HudArt` show `res://exports/Drawings/axel_combat_plate_white.png` (white 3508×2480 plate).
- `HudPieces` holds one `TextureRect` per cut-out: grid, history, items, bets, goal, multiplier, exit (`exports/Drawings/axel_combat_*.png`). Drag these in the 2D editor to align.
- `PremiumSkull` holds the three skull stage drawings (feel-only hover/press + `preview_fill`; not wired to meter/EXECUTE yet).
- Drag widgets in the 2D editor **inside `HudCanvas`** (1 unit = 1 drawing pixel). Play keeps those positions — no percentage layout rewrite.
- Live text + the 5×5 grid sit on top; HISTORY / ITEMS / EXECUTE computer chrome is see-through so the drawings paint the frames. `%SpinButton` remains the click target with empty text.
- Placeable: meta + **SEED**, bankroll/stake, goal, history log, items picker, score readout, premium progress bar, EXECUTE hit area.
- Match payout numbers flash on winning symbols during resolve.
- Side bars use a white `BlackBackground` ColorRect (name kept for restore-from-baseline).
- Room FX on combat is behind `AxelPostFxStack.COMBAT_ROOM_FX_TEST` (test flag; flip false to restore combat-only scanline). Local `ScanlineOverlay` hides when that flag is on.

## Shared `combat_root`

The shell instances `combat_root.tscn`. Economy uses integer chip units (`ECONOMY_DISPLAY_SCALE = 100` vs legacy decimal display). Paytable values in symbol `.tres` files are scaled accordingly.
