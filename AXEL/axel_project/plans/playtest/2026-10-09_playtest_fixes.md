# Playtest fixes, 2026-10-09 (tutorials, exit X, item cards, Vice Round, GOAL)

## Context
Playtest feedback from v0.1.3. Tutorial cards show in the wrong order and are hard to dismiss. The exit X is hard to find. Overworld item cards are too small. The Vice Round title and its card overlap. GOAL can lag behind the winnings bar (90 on the bar, 69 on GOAL).

Three items get their own plan in a separate chat, so they are **not** in this plan: the combat transition, the Round Complete effects, and the death screen. Ready-to-paste prompts for those are at the end.

When I implement this, I'll save a copy as `plans/playtest/2026-10-09_playtest_fixes.md`, then update `AI_DOCS.md` (Tutorial cards, Design ideology line 71, GOAL paragraph).

**Canon changes to confirm:** AI_DOCS line 71 says normal cards close only on their action or the X. This plan adds: a click on the card, Esc, Backspace or Delete closes **any** card and marks it seen. That includes `fight_stakes`, which also gets an X.

---

## 1. "Fights" card shows before "Matches"
Cause: `fight_stakes` is requested on the first idle fight (`combat_test.gd:2856 _maybe_queue_fight_tutorials`). It opens during the first spin. Then the held `slot_match` freeze card bumps it (`axel_tutorial.gd:170 _bump_calm_cards`), and it comes back afterwards.

Fix (`combat_test.gd`):
- Stop requesting `fight_stakes` in `_maybe_queue_fight_tutorials`.
- Request it only after `slot_match` closes. Listen for the tutorial close signal, or poll `AxelTutorial` for `slot_match` being seen.
- Fallback: if the first spin finishes with no line win (`slot_match` never queued), request it at that spin's end.
- General guard in `axel_tutorial.gd _try_start`: don't open a calm card while combat holds a freeze lesson. Add `AxelTutorial.set_freeze_pending(bool)`, set from `combat_test.gd` when `_held_freeze_lessons` is non-empty. This stops the same flash for `slot_power`.

## 2. Click to close, bigger tutorial X
In `axel_tutorial.gd`:
- Add a `gui_input` handler on the card panel. A left click closes the card and marks it seen through the same path as `_on_exit_pressed_slot` → `_start_close(slot, true)`.
- Remove the `action_only` guard on the X and on click (lines 191, 433, 520), so `fight_stakes` can be closed too.
- While the text is still typing, the first click only reveals the full text, as it does today. The next click closes the card.
- Make the X bigger: change the `scale*0.5` call at lines 673-676 to roughly `scale*0.85`. Keep the X red with no pulse, so it doesn't look like the scene exit.

## 3. Scene exit X: bigger, pulse, glow
Change the shared helper `scenes/core/ui_viewport_scale.gd apply_exit_button()` (lines 7-9, 29-38), so every exit X gets the change at once: 1.3 hub, 1.3 school map overlay (`locker_map_overlay.gd:227-256`), and the 2.2 / 3.2 / 4.2 / 5.2 memory stills.
- Size: 58 → about 96 px, font 36 → about 60, margin stays 24.
- Pulse: a looping tween on `scale` (1.0 ↔ 1.08, about 1.4s, pivot at center).
- Glow: a soft red outer glow behind the X, with alpha pulsing in sync (font outline plus a shadow, or a small glow `StyleBox`). It holds steady when reduce flashing is on.
- Add an opt-in flag (`pulse := true`) so the tutorial card X can call the same helper without pulsing.

## 4. Overworld item cards bigger, colored numbers
- **Map cards** (`scenes/ui/locker_map_overlay.gd:12-18, 758-834`): icon 64 → 96, name font 26 → 34, description 20 → 28. Scale padding with them, and widen the description (it is no longer tied to the title width).
- **Walk-near floor card** (`scenes/ui/world_item_info_card.gd:7-14`): same new sizes. It is used in every room, including 1.3.
- **Numbers in color:**
  - Change the description `Label` to `RichTextLabel` (`bbcode_enabled`, `fit_content`, autowrap). Wrapping text needs `custom_maximum_size`, per CLAUDE.md.
  - Add one shared helper, `ItemDescFormat.colorize_numbers(text)`, as a new small script. It wraps every number token (`\d+(\.\d+)?%?`, also `x2` / `+15`) in the palette's bright red. The rest of the text stays white.
  - Use it in both cards. Also use it in the in-fight panel (`combat/scripts/player_item_panel.gd` ~186-300), so the item text looks the same everywhere.
- Description data (`combat/data/items/*.tres`) does not change.

## 5. Vice Round: title first, then card, then start
- `combat_test.gd:2025 _on_meter_full_transition_started`: stop requesting `slot_vice` here.
- `combat_root.gd:2094 _play_meter_full_transition_async`:
  - After the "VICE ROUND" banner finishes (`combat_feel.gd:119`, 1.8s hold plus fade), emit a new signal, `vice_banner_finished`.
  - `combat_test.gd` requests `slot_vice` on that signal.
- `combat_root.gd:2317 _run_trinity_round_async`: after the transition, `await` until the tutorial is clear (`AxelTutorial.is_freezing()` / `freeze_changed`) before `_repopulate_grid_handoff_async`.
  - When the card is already seen, or headless or sync runs are used, skip the wait. This keeps determinism and tests unchanged.

## 6. New multiplier tutorial card
- New lesson `slot_multiplier` in `axel_tutorial.gd LESSONS` (lines 27-72): a `freeze:true` card titled `? Multiplier ?`.
  - Body: "Each match in a row raises the multiplier. Every win this spin is multiplied by it. It resets on the next spin." I'll verify the reset rule in `combat_root.gd` before writing the final text.
- `GLOW_PIECES`: `slot_multiplier → NEW_Multiplier`.
- Add it to `FREEZE_LESSONS` in `combat_test.gd:87`.
- Trigger: the first time the cascade multiplier readout goes above 1× (`combat_test.gd:1105-1118`, where `CascadeMultiplierReadout` updates). Request it through `_tutorial_request`.
- Add a pause Guide entry if the Guide lists the slot cards (`tools/qa/guide_panel_check.gd`).

## 7. Stronger highlight glow
In `combat/shaders/piece_highlight_glow.gdshader` and `axel_tutorial.gd:19-24, 834`:
- Make the core pure white instead of warm grey.
- Add a wider soft outer halo.
- Raise the pulse range: alpha 20–75% → 45–100%, plus a small brightness swell on the halo, still on the 2.6s cycle.
- Reduce flashing still holds it steady.
- Follow-up: the outline alone still read as plain. Added a red bloom that spreads past the piece edge, a white shine band that sweeps across the outline each pulse, a sonar echo that grows outward (1.0 → 1.12) and fades, and a short 2 px CRT jitter about every 3.5 s. Reduce flashing keeps only the steady glow and bloom.

## 8. Esc / Backspace / Delete close cards before pause
- `scripts/autoload/axel_pause.gd:140 _unhandled_input`: if `AxelTutorial.is_open()` (any card, typing or not), call a new `AxelTutorial.dismiss_open_card()`, mark the event handled, and return. Pause opens only when no card is up.
  - This has to sit in `AxelPause`, because it gets input before `AxelTutorial` (autoload order). `AxelPause` stays the only writer of `paused`.
- `dismiss_open_card()`: while typing, reveal the full text; otherwise close and mark seen.
- `back` (Backspace/Delete) and `pause` (Esc) both go through it. Tab/Q/R/I are unchanged.

## 9. GOAL moves with the winnings bar, and every win counts
Cause (from code): the GOAL value in combat is correct (`combat_root.gd:1720 _add_round_winnings` adds the same amount to bar and GOAL). The **display** splits them, though:
- GOAL is redrawn from combat truth right away (`combat_test.gd ~1871`).
- The bar counts up from popup cents, which are computed a second time at display time (`combat_root.gd:1502/1525/1557`), and can drift away from what was really paid.
- The final snap at spin end (`combat_test.gd:1961-1963`) is skipped when the encounter completes.

Fix:
1. **Confirm first:** add a temporary headless repro that logs `_round_winnings_cents`, `_encounter_goal_winnings_cents` and `_target_round_winnings` at `spin_finished` over the scripted seeds and a few item loadouts (Bloody Gauze included). It's deleted after.
2. **Popups carry the real amount:** have the cascade step pass the exact cents it added at line 925 (and the sync twins) to the popup, instead of recomputing with `_line_payout_cents`.
3. **One counter drives both:**
   - Store `goal_at_spin_start` on spin start.
   - The GOAL label shows `goal_at_spin_start + _displayed_round_winnings` and ticks in the same `_run_winnings_counter_async` step as the bar.
   - `_refresh_readouts` stops writing GOAL from truth mid-spin.
   - Feature holds (Vice → Free Spins bar reset) carry the goal base forward.
4. **Always snap at spin end** to combat truth, also when the encounter completed. Do it before the victory prelude count-up (`combat_test.gd:3687-3722`).
5. **Check other bar-only gains:** confirm the bankroll-only refund at `combat_root.gd:1624` and `_item_fx.free_spins_mods` gains are not shown on the bar. If they are, route them through `_add_round_winnings`.
6. **New regression** `combat/test/goal_bar_sync_check.gd`: after every spin (scripted seeds plus item loadouts), the displayed bar equals the displayed GOAL delta equals the payout.

---

## Files touched (main)
- `scripts/autoload/axel_tutorial.gd`
- `scripts/autoload/axel_pause.gd`
- `combat/scripts/combat_test.gd` (grep-edit only)
- `combat/scripts/combat_root.gd` (grep-edit only)
- `combat/shaders/piece_highlight_glow.gdshader`
- `scenes/core/ui_viewport_scale.gd`
- `scenes/ui/locker_map_overlay.gd`
- `scenes/ui/world_item_info_card.gd`
- `combat/scripts/player_item_panel.gd`
- New: number-colorize helper
- New: `combat/test/goal_bar_sync_check.gd`

No comments in scripts. Input stays on named actions. `CombatPace` only.

## Verification
1. `--import` once, then run every check from CLAUDE.md, plus:
   - `tools/qa/tutorial_popup_check.gd`, extended:
     - `fight_stakes` opens only after `slot_match`
     - a click closes and marks seen
     - Esc closes the card and doesn't pause
     - `slot_multiplier` glow map
   - `combat/test/free_spins_round_check.gd`
   - `combat/test/powers_check.gd`
   - `tools/qa/guide_panel_check.gd`
   - the new `goal_bar_sync_check.gd`
2. Headless UI check at 1920×1280:
   - exit X size in 1.3 hub and map
   - item card sizes, and that the description doesn't clip
3. Manual playtest with a fresh profile:
   - first fight card order
   - Vice title → card → start
   - multiplier card on first 2×
   - GOAL ticking with the bar
   - 1.3 exit X visible

---

## Separate-chat prompts (not part of this plan)
- **Combat transition:** "Plan only: make the combat transition symmetrical, all bars moving at the same time, black and red bars crossing over the same way, plus three more transitions in the same simple style. Think thoroughly."
- **Round Complete:** "Plan only: Round Complete! text bounces too much. Make it explode out, more fireworks from the center behind the text, a more dynamic and rewarding animation. Think thoroughly."
- **Death screen:** "Plan only: make the death screen more dynamic. Pieces break and fall in a satisfying, clear order. Center the text. Think thoroughly."

---

## Outcome (2026-10-09)
- Done: items 1–9. All CLAUDE.md checks pass, plus the tutorial, item card, map, free spins, guide and new `goal_bar_sync_check.gd` checks.
- Changed from the plan:
  - A click on a card closes it right away. It does not reveal the text first.
  - Esc / Backspace / Delete also close a card at once.
  - A fully typed `guide_pause` card still lets Esc open pause, because that is the action it asks for.
  - `fight_items` now also waits until after Matches. It closes only when a spin ends while it is showing.
  - Colored numbers are in the overworld cards only (walk-near card and map cards). The in-fight item description panels still use plain Labels.
  - The pause Guide already explains the multiplier, so no new Guide page was added.
- Cause of 90 vs 69: the win pop-ups fill the bar while symbols clear, but GOAL was only credited after gravity. GOAL was read straight from combat, while the bar counted up from pop-ups. Now one counter drives both.

---

## Free Spins skull flames (2026-10-09)
- Problem: the flame crown behind the full-face skull was on during Free Spins but almost invisible. It sat behind the cranium, and its bright yellow art became black under the inverted noir filter.
- Fix: `flame_crown.gdshader` flips the art's brightness so it maps to the red bands. `premium_skull_meter.gd` crown constants: copies 5→6, thin 0.72→0.45, arc 0.22→0.5, pos (40,-46)→(-46,-26), size (612,240)→(780,330). The ring now hugs the top and sides of the skull and stays about 10 px under the history frame.
- Checked with windowed 1920×1280 captures in real Free Spins (crown visible, centered, clear of the history frame, spin blocks and count) and after the round (crown hidden).
- Follow-up: the flames are taller (thin 0.56, arc 0.41, pos (-46,-97), size (780,400)), so their tips reach a little into the History box. `combat_test.gd` passes the history panel to `set_flame_dim_target`. Each frame the skull turns that box into the crown's local space. The shader draws flames inside the box as faint dark red (`dim_level` 0.44) and hides them on a 14 px border band, so the border and the history text stay on top.
