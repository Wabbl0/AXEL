# Port Oct 9 cloud branch fixes into main (2026-10-11)

## Context
Two cloud sessions on 2026-10-09 left work on `claude/affectionate-brahmagupta-cvhmmw` (A) and `claude/nifty-knuth-ct4mxf` (B). Release 0.1.4 redid most of A. B's batch was never merged. A plain merge would have overwritten newer 0.1.4 work, so the missing parts were ported by hand onto main. Full original plan: `git show origin/claude/nifty-knuth-ct4mxf:AXEL/axel_project/plans/playtest/2026-10-09_playtest_fixes_b.md`.

## Branch A
- Nothing ported. Its fixes shipped in `2026-10-11_combat_hud_fixes.md`.
- The 5-line wild was declined. Canon stays "exactly-3 lines".

## Ported from B
1. **Editor runs show tutorials fresh.** `AxelProfile._fresh_tutorials()` is on in the editor, off when headless. A new game also clears `AxelTutorial` session marks.
2. **Items cards** get "Items are how you win fights" text.
3. **No player flash after combat.**
   - `AxelWorld` hides the player while the return placement settles.
   - `AxelRun._wait_return_placement` holds the fade-in until the player is placed.
4. **H items give a goal head start** (5/10/15/20/25%, cap 50%) instead of a higher goal.
5. **Item proc flash in the item box** is stronger: bigger pulse, name flash, red row backdrop.
6. **Item wheel:** 2 items sit around the centre. Main's own lag fix stays.
7. **Item box counter** `N / cap` shows from 3 items.
8. **CRT Etching:** a marked win adds the full mark to the multiplier (`all_mult`). The old `majority_mult` code is gone.
9. **Vice Halo:** powers fire at 150% in the Vice Round. The `first_dead_chosen` code is removed.
10. **Glitch Button:** the −10% downside is removed.
11. **Lounge → Corridor arrival.**
    - `LoungeInteractArea` shape is now 176 wide at x 523.
    - Measured live: wall inner edge x 6583. Old arrivals at t=0.5 and t=1 landed at x 7027 and 7284.

## Not ported
- B's item wheel lag rewrite. Main has its own (`2026-10-11_item_wheel_lag.md`).
- B's bigger Round Complete text. Main's jackpot rewrite replaced it.

## Checks
- All CLAUDE.md checks.
- `item_wheel_check`, `item_synergy_smoke`, `playtest_fix_groups_check`, `goal_bar_sync_check`.
- New: `tools/qa/lounge_arrival_check.gd`.
