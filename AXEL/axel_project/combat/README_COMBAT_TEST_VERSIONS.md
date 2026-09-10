# Combat Test UI

The playtest shell uses a **drawing-backed HUD**: white plate + one node per drawing under `%HudCanvas` (3508×2480 drawing pixels), integer economy readouts, and a dev item picker.

## Canonical entries

| Entry | Scene | Script | Who |
|-------|-------|--------|-----|
| **Playtest (Godot / F6 only)** | `res://combat/combat_test.tscn` | `scripts/combat_test.gd` | Full catalog picker, seed, Ignore cap, DEV TOOLS. Overworld never loads this file. |
| **Player (overworld)** | `res://combat/combat_run.tscn` | `scripts/combat_run.gd` | Instanced HUD. Hides playtest chrome. Shows `NEW_Items`: locker tutorial / F6 preview = empty DVD mill + “Nothing but us chickens.” ticker; later fights = read-only equipped icons. |

## Launch

- Open `combat/combat_test.tscn` → **F6** (Play Scene) for the catalog tool.
- Overworld fights load `combat/combat_run.tscn` via `AxelRun`. F6 on that scene previews the empty item box.

Headless combat checks (`princess_check`, `determinism_check`) use `combat_root.tscn` only — not this shell.

## HUD features

- `%HudCanvas` + `HudArt` show `res://exports/Drawings/axel_combat_plate_white.png` (white 3508×2480 plate).
- `%HudArtGuide` is the optional `axel_ui.png` overlay (50% opacity). It starts **hidden**. Toggle the eye in the scene tree to line up pieces. Play always hides it.
- **Never move or resize `%HudArtGuide` or `HudPieces`.** Both must stay at `0,0` sized `3508×2480`, 1:1 with the plate. Every piece is positioned by eye against the guide, so nudging the guide silently drags the whole HUD off-window. `tools/qa/hud_piece_placement_check.gd` fails if that happens.
- **Art pieces (`NEW_`):** already placed drawings. Do not drag these unless the art itself is wrong: `NEW_Grid`, `NEW_Goal`, `NEW_Items`, `NEW_History`, `NEW_Bets`, `NEW_Multiplier`, `NEW_Settings`, `NEW_Execute`. Each one sits at its native texture size — a stretched piece blurs the hand-drawn line work, so the placement check also enforces that.
- **Interactables (`MOVE_`):** drag these to sit on the drawings — text boxes, `+`/`-`, bet strip, balance, premium bar, spin money. Each art piece has a `MOVE_TextBox` child for text/widgets.
- Clickable: skull Execute, Items checkboxes, `+`/`-`, Settings. Settings window: only **DEV TOOLS** opens `AxelCombatDevTools` (no standalone wrench button).
- Bet strip shows `100 | 200 | … | 1000` and slides on `+`/`-`. Multiplier reads `1X` / `2X`. Skull meter fill is shown on the skull art only (no separate `0/3` counter). Premium bar color steps with fill; spin money sits on that rectangle.
- Protected scaffold unique names (`%SpinButton`, `%BetLabel`, `%BankrollLabel`, …) stay in the tree — re-parented at runtime, not deleted.
- Old computer HUD chrome is off: black winnings/multiplier pills, thin `PremiumProgressBar`, CombatRoot `Multiplier: 1×` / round-winnings labels, gear/home/? row. Numbers sit on the piece drawings instead.
- Match payout numbers flash on winning symbols during resolve.
- Side bars use a white `BlackBackground` ColorRect (name kept for restore-from-baseline).
- Room FX on combat is behind `AxelPostFxStack.COMBAT_ROOM_FX_TEST` (test flag; flip false to restore combat-only scanline). When the flag is on, combat gets flat `CrtCombatOverlay.tscn` (same CRT shader, zero curve/vignette/rim — edge-fringe fix without the round-TV look). Local `ScanlineOverlay` hides when that flag is on.
- **Live widgets under CRT/pulse/glitch:** `WidgetLayer` (`CanvasLayer` 106) hosts numbers, item checks, history, `+/−`, and the 5×5 grid — above noir (90) so text stays white, below CRT (108) / pulse (109) / glitch (112) so symbols and readouts share the shake. Each host follows its `MOVE_TextBox` rect. Hand-drawn `NEW_*` pieces stay under the FX. `WidgetRoot` carries `terminal_theme.tres` (CanvasLayer breaks theme inheritance from the root Control).
- **Grid:** `NEW_Grid` has a `MOVE_TextBox`; `GridHost` / `%CombatRoot` live under `WidgetLayer` and fill that box (not the old PlayArea host).
- **Clicks:** Settings / Execute / `+` / `−` use each piece’s `MOVE_TextBox` rect (not the art frame, not opaque pixels, not the skull polygon). `SkullClickPolygon` is editor tracing only. One spin per click (shared guard).
- **Piece authoring (canon):** combat drawings use **black ink on white fill** (same rule as room backgrounds). Noir turns black → red and white → dark. Original white-on-black exports were inverted in place by `tools/invert_drawing_colors.gd`; pre-invert copies live in `exports/Drawings/backup_pre_invert/` (ignored by Godot). Re-run that tool after exporting a new white-on-black piece.

## Shared `combat_root`

The shell instances `combat_root.tscn`. Economy uses integer chip units (`ECONOMY_DISPLAY_SCALE = 100` vs legacy decimal display). Paytable values in symbol `.tres` files are scaled accordingly.
