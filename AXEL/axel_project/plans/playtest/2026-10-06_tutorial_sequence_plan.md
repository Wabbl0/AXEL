# Plan: one-at-a-time combat tutorials, smoother glow, bet hotkeys, softer wave, Guide in tutorial, release rule

## Context
Playtest of the first (locker tutorial) fight in Godot. Findings from this session:
- **The earlier work is in the code AND in the 0.1.1 release** (`AXEL/out/export/*/AXEL_0.1.1.*`, built after commits `1dae47e` + `58d5a94`): scripted seeds `[10, 1, 12]` (`combat_root.gd:101`), lessons `slot_match` / `slot_power` / `slot_vice` with freeze (`axel_tutorial.gd:54-68`), Guide button + panel (`pause_menu.gd:90`, `guide_panel.gd`).
- **Why you don't see them in Godot:** your profile file `%APPDATA%\Godot\app_userdata\AXEL\axel_profile.cfg` already lists every combat lesson as seen, and `guide_unlocked` was never set (no fight was finished since). Tutorials are once per profile, so they are silently skipped. The Guide only unlocks after the first fight ends.
- **Real bugs that burned the cards:** up to 2 cards open together (2 slots, 5 s gap), so glows overlap; `complete()` marks a lesson as *seen* even if it was only queued and never shown (`axel_tutorial.gd:208`); every new spin auto-completes `slot_*` (`combat_test.gd:1887`); freeze cards still auto-close on a reading timer (`_begin_wait`, l.411); `fight_stakes` closes on any spin (`combat_test.gd:1785`).
- No lesson mentions the Guide.

## 1. One tutorial card at a time — `scripts/autoload/axel_tutorial.gd`
- `_try_start`: never open a card while another is open. Keep a short gap (~0.5 s) after a close before the next opens (replace `STACK_OPEN_GAP_SEC` 5 s). Slot 2 stays in code but is unused.
- Urgent cards cut in: when a freeze lesson (`slot_*`) is requested while a non-freeze card is open, close that card *without* marking it seen and put it back at the front of the queue. Freeze lessons are also inserted ahead of non-freeze ones in `_queue`.
- `complete(id)` on a lesson that is only queued: remove it from the queue but do **not** mark it seen (only cards actually shown get marked).
- Freeze cards: remove the reading auto-close timer. They close on X, click, or E/Space (game is frozen, so there is no other action).
- New lesson flag `action_only` for `fight_stakes`: no X button, click/back does not close it. It closes only via `complete("fight_stakes")`.
- Resulting first-fight order: `fight_spin` → (spin 1) `slot_match` → `fight_stakes` (stays until +/−; `slot_power` / `slot_vice` cut in and it returns after) → `fight_items` (only with items) → `guide_pause`.
- New lesson `guide_pause` (title `Guide`): "Forgot a rule? Press Esc and open the Guide. Every lesson is kept there." Requested by `combat_test.gd` when `slot_vice` closes (or at the first fight's end if Vice never came). Glows the pause gear piece if a HUD piece exists for it (name to confirm in `combat_test.tscn`).

## 2. `combat/scripts/combat_test.gd`
- Remove `_tutorial_complete("fight_stakes")` after `await combat.spin()` (l.1785). Keep it in `_on_bet_minus_pressed` / `_on_bet_plus_pressed`.
- `_on_spin_started` (l.1887): only auto-complete `fight_spin`, not `slot_*`.
- Bet hotkeys in `_input` (l.1652): `bet_down` → `_on_bet_minus_pressed()`, `bet_up` → `_on_bet_plus_pressed()`, with the same guards as the spin hotkey (not paused, no dev menu, no Free Spins choice overlay, not mid-spin). Also play the bet button press feel (`_animate_bet_strip` already runs).

## 3. Input actions — `project.godot`
- `bet_up`: R (physical), `+` (logical `KEY_PLUS`, works on Finnish layout), `=` (US Shift+=), numpad `+`.
- `bet_down`: Q (physical), `-` (logical `KEY_MINUS`), numpad `-`.
- Q/R are also `item_wheel`, but the wheel is already disabled in combat (`item_wheel.gd:315-322`), so no clash. No raw `KEY_*` in gameplay code.
- Add a line to the Guide's Bets page (`scenes/ui/guide_pages.gd`) and to the `fight_stakes` text: "Q / − lowers, R / + raises."

## 4. Smoother highlight
- `axel_tutorial.gd`: slower pulse (`GLOW_PULSE_SEC` 1.6 → 2.6), softer range (`GLOW_ALPHA_MIN/MAX` 0 / 1 → 0.2 / 0.75), 0.4 s eased fade-in when a glow starts, eased fade-out 0.35 → 0.6 s.
- `combat/shaders/piece_highlight_glow.gdshader`: replace the hard `a < 0.03` cut with a smooth edge (`smoothstep`), and tint from pure white to the palette's light warm grey so it blends with the noir palette.

## 5. Wave opacity −33%
- The ~30 s wave is the cadence pulse (`axel_event_fx.gd:187`) on `scenes/fx/InterfacePulseOverlay.tscn`. Set `roll_color_strength` 0.335 → **0.224**.
- Update `tools/qa/interface_pulse_dialogue_check.gd:176-177` to expect 0.224.

## 6. Guide reachable during the tutorial fight
- **Canon change (you asked for it):** the Guide was "unlocked after the first fight". Move `_unlock_guide()` so it also runs when any fight starts (`axel_run.gd` `_wire_combat_root`, l.345). Free Spins page stays `???` until reached.
- Update `tools/qa/guide_panel_check.gd` if it asserts "hidden during first fight".

## 7. Seeing the tutorials again in Godot
- No code needed: open the debug dev tools and press **Reset Profile** (`axel_combat_dev_tools.gd`), or delete `axel_profile.cfg`. I'll tell you the exact steps after the change.

## 8. Release rule
- `CLAUDE.md` "Release builds": rename trigger. "commit and push" = only commit + push. Version bump + Windows/Mac export only when you say "make a new release" (or similar).
- `.claude/skills/release-build/SKILL.md`: same change in `description` and step text.

## 9. Docs
- `plans/core/AI_DOCS.md`: one-card-at-a-time rule and urgent cut-in, `fight_stakes` closes only on bet change, freeze cards close on X/click/E, `guide_pause` lesson, Guide unlock at fight start, bet hotkeys, wave strength 0.224, release trigger.
- Copy this plan to `plans/playtest/2026-10-06_tutorial_sequence_plan.md`.

## Verification (repo root, `tools\cmd\godot.cmd`, `--import` first)
- Standard: `combat/test/determinism_check.gd`, `combat/test/powers_check.gd`, `combat/combat_test_scaffold_check.gd`, `tools/scene_smoke_check.gd`, `tools/qa/audio_bus_layout_check.gd`, `settings_persistence_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`.
- Plus: `tools/qa/tutorial_popup_check.gd` (update stacking cases to one-at-a-time; add: queued-then-completed lesson is not marked seen; `fight_stakes` survives a spin and closes on bet change; freeze card has no timer), `tools/qa/interface_pulse_dialogue_check.gd`, `tools/qa/guide_panel_check.gd`, `combat/test/tutorial_script_seeds_check.gd`.
- Manual in Godot: Reset Profile → new game → tutorial fight. Cards appear one by one, glows never overlap, bet card stays until Q/R/+/−, Vice card shows on spin 3, Guide card appears, Esc shows Guide during the fight, wave is fainter.
