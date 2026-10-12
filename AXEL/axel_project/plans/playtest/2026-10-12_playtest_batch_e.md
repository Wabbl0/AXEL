# Playtest batch E (0.1.6 exe, 2026-10-12): 26 fixes

## Context
These issues come from playtesting the 0.1.6 Windows build. They fall into 7 areas:
- combat tutorials
- skull feel and input
- the Vice Round and Free Spins skull
- Round Complete FX
- items in combat
- item wording
- overworld rooms

First step of implementation: copy this plan into the repo as `plans/playtest/2026-10-12_playtest_batch_e.md` and add a row to `plans/playtest/README.md`.

Do one section at a time. Each section is one commit. Run its checks before moving on.

Before any combat edit, run `combat/test/combat_test_scaffold_check.gd`. No comments in any script. Use `CombatPace`, not `Engine.time_scale`.

### Canon changes you asked for (reminders; these become canon after this batch)
- **R1.** The overworld item card used to sit under the items_indicator "even when it runs off the bottom". It now flips above the indicator instead (fix E1).
- **R2.** "Every card glows exactly one HUD piece" gets an exception: `slot_vice` glows nothing (fix A5).
- **R3.** Free Spins: the Skull Meter now resets after every free spin, like paid spins. Spins already won are kept. RTP changes, so rerun the RTP audit and update `GuidePages.RTP_PERCENT` (fix C3).
- **R4.** Room fit changes from **cover** to **contain**. The whole PNG is always visible, with dark bars where the window shape differs. At 1920×1280 nothing changes. This also touches the legacy Arc 1 rooms (1.1 / 1.2 / 1.4). You approved this by choosing "Contain" (fix G2).
- **R5.** The skull heartbeat is removed (fix B2).
- **R6.** The `[E] SPIN` chip no longer shows on hover (fix B1).

---

## A. Combat tutorials
Files: `scripts/autoload/axel_tutorial.gd`, `combat/scripts/combat_test.gd`.

### A1. No spin before the "E to spin" card (first playthrough)
- In `AxelTutorial.blocks_spin()` (~:321), also return true when all of these hold:
  - cards are enabled,
  - `fight_spin` is not seen in the profile,
  - the `fight_spin` card is not open yet (it is queued, or still waiting to be requested).
- Once the card is open (typing or waiting), spinning is allowed, and that spin completes it as today.
- All spin paths already go through this check: the E hotkey (`_spin_hotkey_allowed` :1809), the skull click and the button (`_request_spin` :1849).
- Lower the wait before `fight_spin` from 2.5s to 1.0s, so the blocked time is short. Add a separate constant next to `FIRST_TUTORIAL_DELAY_SEC` (combat_test.gd :86). Other first-fight cards keep 2.5s.
- Headless runs, or runs with cards turned off, never block.

### A2. A click closes the bet-change card
- **Cause:** `_on_card_gui_input` (axel_tutorial.gd :616) returns early for gate lessons. `fight_stakes` is a gate, so a click only finishes the typing.
- **Fix:** remove that gate early-return.
  - A click on the card now closes `fight_stakes` and marks it seen, like every other card.
  - Closing lifts the spin gate.
- Esc and X already work. Update `tools/qa/tutorial_popup_check.gd`.

### A3. Freeze starts the same moment the card shows
- **Today:**
  - Freeze turns on when the lesson is queued.
  - The card appears later: after the 0.5s stack gap plus the CRT power-on.
  - The grey overlay fades in over 0.18s.
  - Some grid tweens are not bound to `CombatPace`, so they keep moving.
- **Fix:**
  1. Freeze cards skip the 0.5s stack gap when they cut in (`_try_start` :484).
  2. Turn on `CombatPace.set_freeze(true)` and the grey overlay on the **same frame** the card starts its power-on.
     - Don't turn it on at queue time while nothing is visible.
     - Keep `blocks_spin()` true from queue time, so nothing can spin in between.
  3. The overlay fade-in goes from 0.18s to 0.05s (`_sync_freeze_overlay`, combat_test.gd :2867).
  4. Audit grid-side tweens that still move while frozen. Bind every one to `CombatPace.bind`. Search for `create_tween()` in `combat_test.gd`, `combat_root.gd`, `symbol_slot.gd`, the winnings bar and the `+N` win popups.
- **Verify:** `tutorial_glow_capture.gd --lesson=slot_match` (frames around the open), plus a manual check.

### A4. Item card at the start of the fight
- Request `fight_items` straight away in `_maybe_queue_fight_tutorials` (:2973-2990) when something is equipped. It opens about 0.5s after the HUD is idle.
- Remove it from `_after_match_lessons`, and drop the "first spin ended" condition for it.
- Keep: it never blocks spinning, and it closes when a spin ends while it is showing.
- First-fight order is unchanged, because the locker tutorial has no items.

### A5. Vice Round card: freeze only, no highlight
- `GLOW_PIECES["slot_vice"] = []` (axel_tutorial.gd ~:104). The grey freeze still runs.
- Update the expected glow in `tutorial_popup_check.gd`.

---

## B. Skull feel and combat input
Files: `combat/scripts/premium_skull_meter.gd`, `combat/scripts/combat_test.gd`.

### B1. `[E] SPIN` chip only after idle
- Remove the chip from hover (the hover grow, tilt and white outline stay). Also remove the first-spin hint chip:
  - `_refresh_skull_first_spin_hint` (:2809) stops turning it on,
  - `set_first_spin_hint` no longer shows it.
- After 6s of no input while a spin is allowed, the chip fades in over 0.4s and **stays**. This reuses the existing idle nudge timer.
- It fades out over 0.2s on any of these:
  - mouse hover over the skull,
  - any `interact` press,
  - a spin start.
- The idle clock restarts after it hides.
- It stays off while the tutorial suppresses the skull hint.
- Update `tools/qa/skull_feel_check.gd`.

### B2. No heartbeat; a smooth float
- In `_apply_feel_layer` (:318-353), drop the `_heartbeat` term from both scale and rim glow. Delete `_heartbeat` and the `HEART_*` constants.
- Keep the breathing sine as a slow float in and out: `BREATH_SEC` 2.4, amplitude ±3%. Use eased sine only.
- The "faster when full" rule goes, because it only applied to the heartbeat.
- Update `skull_feel_check.gd`.

### B3. Spam clicking empty space rushes animations
- In `combat_test._input`, on a left mouse press:
  1. Find `get_viewport().gui_get_hovered_control()`.
  2. Walk up its parents. If none of them is interactive, call the same rush path as `interact` (`CombatPace.rush_beat()`, or `set_rush(true)` on the loss screen). Interactive means:
     - a `BaseButton`,
     - a `Range` / `LineEdit`,
     - a clickable `HudPiece` (Execute, bets, settings),
     - a `PlayerItemPanel` row,
     - a tutorial card.
- A click never starts a spin.
- Respect `_rush_allowed()` and the tutorial freeze.
- Presses never stack (same rule as E).

---

## C. Vice Round and Free Spins skull
Files: `combat/scripts/combat_root.gd`, `combat/scripts/premium_skull_meter.gd`, `combat/shaders/flame_crown.gdshader`, `combat/scripts/combat_test.gd`.

### C1. Each Vice power drains a third of the fluid
- Add a UI-only signal `vice_power_fired(index: int, count: int)` to `combat_root.gd`.
  - Emit it in `_run_trinity_round_async` (:2495-2531) right after each power's act FX.
  - It uses no RNG, so determinism is unchanged.
- In `combat_test.gd`, connect it to a new `premium_skull_meter.drain_fluid_to(level)` with `level = 1 - (index+1)/count`.
  - The drain is a 0.35s tween bound to `CombatPace`, with a slosh and a small drip from the mouth.
  - Do it while the full face stays locked.
- On the Vice clear, `play_spit` keeps the punch and the drops but skips the drain, because the skull is already empty.
- `skull_fluid_check.gd`: assert the fluid is at 2/3, then 1/3, then 0 after each power.

### C2. Free Spins flames hug the skull
- Rewrite the placement in `flame_crown.gdshader` and `_ensure_flame_crown` (premium_skull_meter.gd :575). Flames should follow the cranium outline, as in your green drawing:
  1. At load, measure the full-face skull texture's alpha.
     - For each row in the top ~55% of the skull, take the leftmost and rightmost opaque x.
     - Fit an ellipse to that: center, x radius, y radius.
     - Pass it as uniforms in the crown rect's UV space.
  2. Place `COPIES` (raise to ~11) flames on that ellipse from the left temple (~200°) over the top to the right temple (~-20°).
     - Each flame's base sits slightly inside the bone line (behind the skull).
     - Each is rotated so its tips point out along the outline normal.
  3. Height varies: tallest on top (×1.0), shorter toward the temples (×0.55).
     - Each copy has its own frame offset so they don't flicker in sync.
  4. Grow `FLAME_CROWN_SIZE` / `POS` so the rect contains the ellipse plus the tallest flame. Compute them from the fit, not by hand.
- Keep these: the inverted ink, the dimming over History with the border cut-out, reduce flashing on the first frame, ignore mouse.
- **Verify:** capture the Free Spins skull (extend `tools/qa/skull_fluid_capture.gd` with a Free Spins pose) and compare it to image #5.

### C3. Free Spins Skull Meter resets every spin
- `_reset_premium_meter_after_paid_spin` (:2152) → rename it `_reset_premium_meter_after_spin` and drop the `free_spins.active` early-return.
- Order inside a free spin:
  1. Lines fill the meter (only Power symbol lines, which is already true in `_apply_meter_from_lines`).
  2. If full, `_grant_free_spin_meter_bonus` adds the spins.
  3. At spin end the meter resets.
- Spins already awarded stay.
- The fluid shows the free-spin fill and drains to empty at spin end. Use `set_fluid_target`, separate from the locked full face.
- Run `determinism_check`, `powers_check` and `combat/test/free_spins_round_check.gd`, and add a reset assertion.
- Rerun `combat/test/rtp_audit.gd`, then update `GuidePages.RTP_PERCENT`.

---

## D. Round Complete FX
Files: `scenes/fx/round_jackpot_fx.gd`, `combat/scripts/flame_burst.gd`, `combat/scripts/bonus_intro_fx.gd`, `combat/scripts/empty_item_dvd.gd`.

### D1. Skulls bounce on the real bottom and fall off softly
- **Floor:**
  - Take the floor from the visible viewport bottom converted into the FX control's local space, not from `size.y` and an 8px pad.
  - Subtract the skull art's real ink bottom, measured once from the texture's used rect and scaled to `SKULL_DRAW`.
  - Apply the same floor to `flame_burst._floor_y` (:98).
- **Fall-off:** remove the `SKULL_FALL_SPEED` 520 snap (:352). After the last bounce, keep the same gravity (260) and drag, and just ignore the floor.
- Remove a skull only once it is past the bottom by its draw size. Raise `SKULL_MAX_AGE` if needed so slow fallers are not cut early.
- Update `round_complete_overlay_check.gd`. Assert that the lowest bounce point equals the viewport bottom ±2px at 1920×1280 and at 1920×1080.

### D2. Sparks and flames burn out instead of popping off
- Sparks (`_draw_front` :433-441): over the last 50% of life, eased (quadratic):
  - alpha fades out,
  - size shrinks to 30%,
  - color goes white → red → dark red, with a small flicker.
- Non-lingering `flame_burst` sprites get a 0.35s fade and shrink at the end instead of vanishing.
- Same for `bonus_intro_fx.gd`.

### D3. Palette colors only
- **Cause:** `flame_1_48x48.png` has its own orange and yellow pixels. A white `modulate` shows them as they are.
- **Fix:**
  - Add a shared static helper (new `combat/scripts/palette_flame_sheet.gd`). It loads a sheet, converts each pixel to grey luminance (keeps alpha) and caches the `ImageTexture`.
  - Use it in `flame_burst.gd` and `empty_item_dvd.gd`.
  - The palette `modulate` (red / white / grey) then gives only game colors.
- Check that `flame_6` (crown) is inverted, so it reads red. If it has the same issue, apply the helper to it too.
- Grep the whole project for other particle or fire color sources (overworld included) and fix any warm hues.
- Add `tools/qa/fx_palette_check.gd`. It loads every FX color constant and the processed sheets, and fails on hue outside red with saturation > 0.15.

---

## E. Items in combat and the item card
Files: `combat/scripts/player_item_panel.gd`, `scenes/ui/world_item_info_card.gd`, `combat/scripts/item_effect_dispatcher.gd`, `combat/scripts/combat_root.gd`, `combat/scripts/glyph_mark.gd`, `combat/scripts/symbol_slot.gd`.

### E1. The overworld item card flips above when it would be cut off
- In `_update_screen_position` (:346-364), if `pos.y + card_h > view_h - WINDOW_PAD`, set `pos.y = indicator_rect.position.y - ITEMS_INDICATOR_GAP_PX - card_h`.
- Keep the x clamp.
- Update `world_item_card_check.gd` with an indicator near the bottom edge.

### E2. All 7 items fit; descriptions are never clipped
- **Row height:**
  - When the slot cap is 7 or less: `row_h = clamp((scroll_h - 6*sep) / 7, 72, 144)`.
  - Scale the icon, name font (84 → proportional) and title band with `row_h`.
  - Turn vertical scroll on (`SCROLL_MODE_AUTO`) only when the cap is above 7 (a cap-raising item like Void Satchel is held). Otherwise `SCROLL_MODE_DISABLED`.
- **Descriptions:** move the description panel out of the row and the `ScrollContainer` into one shared `DescLayer` Control under the panel with `top_level = true`, so it is not clipped.
  - Place it in global coordinates under the hovered name.
  - If its bottom would pass the viewport bottom minus 8px, place it above the row.
  - It may cover the item box frame.
- Verify with a 7-item loadout capture, hovering the lowest two items (image #9).

### E3. Activation flash: icon only
- In `pulse_item` (:130-163), size `PulseBack` to the icon's rect (plus about 6px padding) instead of the full row.
- Stop tinting the name label red. The icon scale pop stays.

### E4. Cell marks: number for multiplier cells, bigger inset
- `glyph_mark.gd`:
  - `INSET_PX` goes from 4 to about 10% of the cell side (min 8px).
  - `SIZE_SHARE` goes from 0.13 to 0.18 (max 40px), so the mark sits clearly inside the cell and never on the grid line.
- Multiplier items (Chalk Mark, Ink Tag, CRT Etching, Scratch Ticket, Red Glyph) pass the cell's value as text, such as `x2`, `x3` or `+3`, instead of the rarity glyph.
  - Draw it as VT323 white text with a dark-red backing plate, using the same corner box.
  - The value comes from where the glyph cells are rolled (`item_effect_dispatcher.gd` ~:480, `combat_root._refresh_glyph_marks` :1204-1214). It is stored per cell next to the owner item.
- Recheck why some marks looked off (image #2): confirm the slot rect matches the visible cell. If slots overlap the grid lines, use the grid cell rect from `grid_ui`.
- Verify with `tools/qa/glyph_mark_capture.gd`.

### E5. One clear rule for item activations
**Rule:** an item pulses only on the spin where its effect actually changed something on screen. Pure odds items pulse once at fight start.

| effect_id | Pulses when |
|---|---|
| `girl_power_chance` (Static Spark, Faulty Relay, Glitch Button) | The random power fires **because of** the item: the roll `r` is ≤ the total chance but > the base chance. Use the same `rng.randf()` value. No extra RNG. |
| `spawn_weight_normals`, `power_symbol_weight` | Once at fight start (odds only) |
| `paid_spin_payout_scalar`, `normal_payout_bonus`, `power_payout_bonus`, `sealed_grid` | Its bonus added > 0 this spin |
| `premium_meter` | It added extra Skull Meter steps |
| `board_count` | The threshold was met and it paid |
| `corner_glyphs` | A win went through its cell (as today) |
| `diagonal` | A diagonal line won |
| `power_chain`, `trinity_run`, `trinity_echo`, `free_spins`, `power_charm` | Its extra event happened |
| `extra_wild_on_create`, `first_dead_power_spawn`, `dead_spin_power_catchup`, `null_gravity` | It spawned or moved something |
| `first_paid_spin_refund` | The refund was paid |
| `goal_head_start` | Once at fight start |
| `extra_inventory_slots` | Never in combat |

- In `note_paid_spin_passives` (:91-105), remove the unconditional `hit = true` for the three odds and chance ids.
- Change `_should_trigger_girl_power` (combat_root :2119) to return whether the power fired, and also `note_proc` each contributing item when `base < r <= total`.
- Audit every other `note_proc` call against the table.
- Write the table into `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- `determinism_check` must still pass (no new RNG draws).

### E6. Drag to reorder the item box
- `PlayerItemPanel` rows get `_get_drag_data`, `_can_drop_data` and `_drop_data`. Dragging a row moves it, and a drop line shows where it will land.
- Dragging works only when the fight is idle (no spin running).
- The order is **display only**. Store it as `RunState.item_box_order` so it survives fights and saves.
- Combat effect order (`inventory.items`) is unchanged, so the result is deterministic.
- A click (no drag) still opens the description as today.

---

## F. Item wording (one glossary)
Files: `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` (the only place catalog text is edited), `tools/combat/generate_item_resources.py`, then regenerate `combat/data/items/*.tres`.

### F1. Glossary (add at the top of the catalog plan)
| Term | Meaning |
|---|---|
| symbol | Anything in a cell. Never "picture", "icon" or "tile". |
| Normal symbol | The shape symbols |
| Power symbol | Cigarette, alcohol, bloody hand |
| Wild | The wild skull |
| grid | Never "board" |
| cell | One grid square |
| win | A line of 3, 4 or 5 matching symbols |
| BET, BALANCE, GOAL, MULTIPLIER | HUD words, in caps |
| Skull Meter, Skull Meter step | Never "SKULL step" or "SKULL" |
| power | What fires: "a power activates" |
| paid spin, Vice Round, Free Spins | |

### F2. Rewrite every item description to the glossary (all 75)
Examples:
- **Meter Coil:** "Power symbol wins fill 1 extra Skull Meter step." (the effect is unchanged, as you chose)
- **Threshold Tribunal:** "If 6 or more of one symbol are on the grid, win 0.75x your BET and fill 1 Skull Meter step."
- **Mason Lock:** "Paid spins: wins pay 40% more. Not in the Vice Round or Free Spins."

Steps:
1. Update the generator to match.
2. Regenerate the `.tres` files.
3. Run the same word sweep over the tutorial card bodies (`axel_tutorial.gd` `LESSONS`, e.g. "picture value") and `scenes/ui/guide_pages.gd`, so the whole game uses one set of words.

### F3. Check
Add `tools/qa/item_wording_check.gd`. It loads every `ItemDef`, plus the lesson and guide text, and fails on these banned words: `picture`, `board`, `SKULL step`, `tile`, `booze`, `Trinity`, and `Free Spins` used for the Vice Round.

---

## G. Overworld
### G1. Map unlocked by the tutorial fight
- In `AxelWorld.notify_fight_won` (`axel_world.gd` :474), when the reason is `locker_tutorial`, set the `GameManager` flag `map_unlocked` (saved like the other flags).
- `AxelSaves.has_map()` (`axel_saves.gd` :88) becomes `has_memory_scene("scene_3") or map_unlocked`.
- The pause Map button and M follow automatically.
- Extend `tools/qa/locker_map_travel_check.gd`: pass the locker without opening it, win the tutorial, then `has_map()` is true.

### G2. Contain fit: the whole picture always visible (R4)
- `scenes/core/background_layout.gd` `apply()` (:32-71):
  - **Static-locked rooms:** scale is `min(vp.x/tex.x, vp.y/tex.y)` (contain), and the picture is centered. Remove the `edge_reveal` shrink, because contain already shows it all.
  - **Movable-follow rooms** (like 2.4): fit the axis that does not scroll in full, and scroll the other one.
- `background_camera_controller.gd`:
  - Center on the picture.
  - Drop hand-set `static_center` offsets such as the kitchen's `(560, 0)` (`2.3_Kitchen.tscn`). AI_DOCS already says "never hand-tune".
  - Limits come from the art.
- `scenes/core/player_cover_sync.gd`: the ratio becomes the **applied** background scale divided by the baseline scale at 1920×1280.
  - At 3:2 contain equals cover, so authored Player scales and `_OLD_BG_SCALE` rooms look the same.
  - At other shapes Mike, colliders and the glow follow the real fit.
- The space outside the picture is already painted black by `AxelRoomEdge` and by the white clear color (dark after noir). Confirm the CRT rim still starts 3px outside the art.
- **Verify:**
  - `tools/qa/capture_matrix.ps1` (every room × 5 sizes): no art cut on any side.
  - `player_cover_sync_check.gd`, `wall_sprite_clearance_check.gd`, `interact_arrival_check.gd`, `corridor_crt_rim_check.gd`.
  - Then update the AI_DOCS and SCENE_BUILDING cover-fit text.

### G3. Teachers lounge: behind filter follows the desk's slanted front edge
- **Cause:** `_occlusion_y_cutoff` (`4.1_TeachersLounge.gd` :331-343) uses one flat y, the polygon's lowest point. At the desk's slanted left end, Mike in front of the edge is still above that y (image #10).
- **Fix (4.1 only; 1.1 is legacy):** every physics frame, for each Behind zone:
  1. Compute the front edge y **at Mike's feet x**. That is the largest y where a vertical line at feet x crosses the polygon's edges.
  2. If feet x is outside the polygon's x range, he is never behind it.
  3. Push it with a new `Player.set_leaf_y_cutoff(slot, y)`, which sets the existing `leaf_y_cutoff_N` uniform.
- Extend `tools/qa/behind_front_edge_check.gd` with a point just in front of the desk's left corner. It must not be filtered.

### G4. 2.4 corridor keeps the big size after a fight
- **Cause:** after the fight return, `_depth_factor` starts at 1.0. `_update_depth_factor_from_player` (:233-246) returns early outside the ramp rect, so at the classroom door Mike stays small.
- **Fix:** add `_depth_from_position(pos)`.
  - Past the ramp's far edge → 1.5.
  - Before the near edge → 1.0.
  - Inside → lerp.
- Call it on ready when there is no spawn side, and whenever Mike's position jumps 64px or more in a frame. That covers the fight return (`AxelWorld._apply_return_placement`), Continue and the pause-map return.
- Add a case to `world_combat_roundtrip_check.gd`: a fight starts at the classroom door in 2.4, and after the return the scale is the far scale.

### G5. Leaving a classroom puts Mike on the floor
- **Cause to confirm with a live measure:**
  - The `classroom_door` arrival places Front inside `ClassroomInteractArea` (PeekEdge.TOP) before the 1.5 depth scale is applied.
  - When he grows, his body overlaps the wall or door.
  - No wall clearance runs after that.
- **Fix:** in `2.4_ClassroomsCorridor.gd` `_apply_spawn_peek_if_pending` (:185-215):
  1. Apply the cover and depth scale first.
  2. Then `apply_arrival_inside`.
  3. Then the shared wall-clearance resolve, so Front sits on walkable floor and the sprite stays in the room.
- Same path for `lounge_door` (4.1 → 2.4).
- Re-measure the live dest box in this session (canon rule).
- Add the 5.1 → 2.4 and 4.1 → 2.4 cases to `scenes/core/test/interact_arrival_check.gd`. Front must be inside the walkable floor and not overlapping `TopWall` or the doors.

---

## Order of work
1. **A** (tutorials)
2. **B** (skull and input)
3. **E1-E4, E6** (item UI)
4. **E5 + C3** (combat logic, determinism)
5. **C1-C2** (Vice and Free Spins skull)
6. **D** (FX)
7. **F** (wording)
8. **G1, G3-G5** (overworld)
9. **G2** last, because it is the biggest and touches every room

Each step is its own commit. After all of them, "update docs": AI_DOCS (the canon changes R1-R6, tutorial list, skull feel, item rule, fit) and the matching plans.

## Verification
From the repo root, `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://<script>`. Run `--import` first. Force `root.size = Vector2i(1920,1280)` in scene checks.

- **Always:**
  - `combat/test/combat_test_scaffold_check.gd` (before and after combat edits)
  - `determinism_check.gd`, `powers_check.gd`
  - `tools/scene_smoke_check.gd`
  - `audio_bus_layout_check.gd`, `settings_persistence_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`
- **Per section:**
  - `tutorial_popup_check`
  - `combat_pace_check`
  - `skull_feel_check`
  - `skull_fluid_check`
  - `free_spins_round_check`
  - `round_complete_overlay_check`
  - new `fx_palette_check`
  - `world_item_card_check`
  - `item_wheel_check`
  - new `item_wording_check`
  - `locker_map_travel_check`
  - `behind_front_edge_check`
  - `world_combat_roundtrip_check`
  - `interact_arrival_check`
  - `player_cover_sync_check`
  - `wall_sprite_clearance_check`
  - `corridor_crt_rim_check`
  - `rtp_audit`
- **Shaders:** after shader edits, run a short windowed `--quit-after` and look for `SHADER ERROR`.
- **Captures:**
  - `tutorial_glow_capture` (slot_match, slot_vice)
  - `glyph_mark_capture`
  - Free Spins skull pose
  - 7-item box hover
  - `capture_matrix.ps1` for G2
- **Manual playtest in Godot:**
  - first fight (no early spin, click the bets card, freeze timing)
  - an item fight (items card at start, click spam rush, reorder)
  - Vice → Free Spins (drain, flames, meter reset)
  - Round Complete
  - kitchen and 16:9 fullscreen
  - lounge desk edge
  - a 2.4 fight at the classroom door
  - exiting 5.1 and 4.1
