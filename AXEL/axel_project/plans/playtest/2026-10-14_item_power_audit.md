# Item power audit (Phase A) — 2026-10-14

Goal: find out why the game gets too easy after about 5 items, and which items are overpowered. This is measurement only. **No item changes until the user approves the proposal list below.**

Master plan for the next phase: difficulty, routing, replayability (phases A–E). This file is Phase A.

## How it was measured

`combat/test/difficulty_curve_sim.gd` plays whole runs on the 21-fight route with the real goal ladder (50…550, then ×1.5) and a start balance of 3000.

New this session: `DIFF_PICK=synergy` models a player who builds around a family. Each item fight offers `DIFF_CHOICES` (3) items at that rank. The player takes the one from the family they already own most of, and equips the best 7 by family match, then rarity. `DIFF_LANE=<family>` forces one family. The default `DIFF_PICK=random` is the old behaviour.

Solo pass: `DIFF_SOLO=<id>` for all 75 items. That is 6 seeds × 400 paid spins at the minimum bet with an endless goal, and it prints the payout rate (paid back ÷ bet) in spin bands.

## Results

### 1. Difficulty curve (200 runs each)

"dead" = runs dead so far. "pay" = payout rate in that fight (100% = break even).

| Fight | Goal | random, min bet | random, ⅕ bet | synergy, min bet | synergy, ⅕ bet |
|---|---|---|---|---|---|
| 4 (item 3) | 80 | 2.5% dead | 17% | 1.5% | 15% |
| 6 (item 4) | 110 | 12.5% | 45% | 12% | 42% |
| 7 flashlight | 205 | 18.5% | 60% | 21% | 57.5% |
| 9 (item 6) | 635 | 45.5%, pay 134% | 74%, pay 142% | 39.5%, pay 143% | 72%, pay 147% |
| 10 (item 7) | 950 | 48%, pay 286% | 75%, pay 184% | 40.5%, pay 245% | 75%, pay 263% |
| 14 (item 10) | 4805 | 53.5%, pay 745% | 79.5%, pay 665% | 44.5%, pay 712% | 80%, pay 2579% |
| 21 (end) | 103475 | 57%, pay 595% | 83%, pay 658% | 47.5%, pay 845% | 80%, pay 1535% |

Targets (AI_DOCS): ≤2% dead by item 3, ≤7% by item 4, 20–30% by item 6, 10–20% of runs survive all 21.

**Reading:**
- **It is a wall, then a flat line, not a curve.**
  - Fights 6–9 kill most runs. In those fights the goal jumps (110 → 205 → 345 → 635, with the flashlight +15%) while the payout rate is still under 100%.
  - From about item 6–7 the payout rate passes 100%. Each spin then *makes* money, the balance grows faster than the ×1.5 goal, and **almost nobody dies after fight 10**.
- **Synergy picking makes the late game 2–4× richer**: a payout rate of 1,200–5,000% versus 500–750% for random picks.
- **Every family lane ends up unloseable by fight 14.** By fight 21, 76–88% of runs are dead (all deaths early), and the survivors pay back 550–2,300%. So the problem is global, not one family.

### 2. Bankroll snowball

- Without items the slot pays back about **40–50%**, so a fight costs money.
- After 6–7 items, the payout rate goes over 100%. Fights only end when you cannot pay for a spin, so a payout rate over 100% means **you cannot lose**.
- A median wallet of 290,000–550,000 by the end confirms it. The ×1.5 goal never catches a balance that grows on its own.
- **Verdict:** the bankroll snowball is a *symptom*. The cause is item stacks pushing the payout rate over 100%. Money sinks (ticket machine, travel fee, Dread) help, but the stacks must come down first.

### 3. Solo item power (payout rate, spins 150–400; no items = 38.5%)

The 0–50 band is noisy, because one Free Spins jackpot can spike it.

| Item | Rarity | Solo | Note |
|---|---|---|---|
| **L1 Twin Pentagram** | L | **404%** (all bands) | ~10× baseline. Alone it is enough to never lose. |
| **L-E Diagonal Covenant** | L | **266–368%** | all diagonals are full lines, and they spawn wilds |
| **R5 Chain Wildseed** | R | **125–160%** | a Rare above every Epic |
| E-B Meter Furnace | E | 126–131% | any line fills the meter |
| E4 Overflow Ledger | E | 109–136% | |
| E3 Echo Loom | E | 108–111% | |
| U5 Split Wick | U | 90–102% | an Uncommon at Epic level |
| L-M Red Glyph | L | 73–94% | |
| E-M / R-M / U-M glyphs | E/R/U | 82–103% | the M family is strong at every rank; U-M ≈ R-M ≈ E-M |
| R1 Fractured Reel | R | 76–99% | |

**The extra-wild line (U5 → R5 → E3 → L1) is the strongest line at every rank.** The current global wild cap (+1 per created wild) does not limit L1, because L1 alone is exactly +1 on every wild.

**No measurable effect when used alone** (the numbers are identical to no items): C-D, R-D, U-D, E-D, L-D (Free Spins), all H (head start, which does not raise payout; expected), C9, C10, E-C, L3. The D family almost never fires, because Free Spins is rare in 400 spins. These items are dead picks in the early game.

## Proposal (needs user approval)

### A. Wild line (biggest lever)
- **U5 Split Wick:** 25% → 15%.
- **R5 Chain Wildseed:** every 3rd → every 5th wild.
- **E3 Echo Loom:** first wild each spin → 50% chance on the first wild each spin.
- **L1 Twin Pentagram:** every wild → 50% chance, plus a curse: the skull meter needs one extra section while it is equipped. Wilds made by an item never make more wilds (no chains).
- **Global:** keep the +1 cap, and add "item-made wilds do not trigger items".

### B. Other outliers
- **L-E Diagonal Covenant:** mode `all` → the two main diagonals only, and its diagonal wins do not spawn wilds.
- **E-B Meter Furnace:** "any line fills" → every 2nd line fills.
- **M family:** U-M x2–3 → x1.5–2.5; R-M and E-M one cell fewer; L-M keeps its cells, but its total multiplier is capped (below).

### C. Global caps for effect types that have none (`item_effect_dispatcher.gd`)
- Summed `line_payout_bonus`: cap at +100%.
- Glyph multiplier going to the total multiplier: cap the summed glyph value at x4 per spin.
- `free_spins_mods.extra_spins`: cap at +4.

### D. Early wall
- **Ladder change:** `50, 60, 70, 80, 90, 110, 175, 300, 550` → `50, 60, 70, 80, 95, 115, 145, 190, 250, 330`, then ×1.5.
  - It removes the 110 → 175 → 300 → 550 jump.
  - Steep late growth is left to Dread (Phase B).

### E. Dead families
- **D (Free Spins) and the Vice-only C items:** add a small always-on part (for example +1 Vice meter section at fight start) so they are not blank picks. Exact numbers are decided after A–D are measured.

### F. Sim gap
- `MAX_EQUIPPED := 7` is hardcoded, so L3's 9 slots are never modelled. The bet ladder in the sim stops at 1000.

### After approval
1. Apply A–D in the item `.tres` files, the dispatcher and `axel_run.gd`. Update this catalog row by row in `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
2. Re-run all curves (random min, random ⅕, synergy ⅕) and the solo pass.
3. Run the standard checks plus `item_synergy_smoke.gd`, and re-check `GuidePages.RTP_PERCENT` with `rtp_audit.gd`.
4. Target after the change: the payout rate stays under ~100% until about item 9, and late deaths come back.

## After-nerf numbers (2026-10-14, nerfs A–D applied; E and F not done)

### Solo (spins 150–400; no items = 38.5%)

| Item | Before | After |
|---|---|---|
| L1 | 404% | 139–178% |
| U5 | 90–102% | 66–79% |
| R5 | 125–160% | 83–88% |
| E3 | 108–111% | 66–87% |
| L-E | 266–368% | **42–59%** |
| E-B | 126–131% | 49–92% |
| U-M | 82–99% | 62–82% |
| R-M | 83–103% | 65–75% |
| E-M | 86% | 55–65% |
| L-M | 73–94% | 56–66% |

**L-E is now over-nerfed.** It is barely above no items, because a 4+ diagonal is rare. Next session, pick one:
- (a) mode `all` with `min_length` 4, plus diagonal wins pay ×1.5
- (b) `min_length` 4, but diagonal 4-lines may spawn a wild

L-M is also now weaker than R5. Re-balance the Legendaries as a group.

### Curves (200 runs)

| Fight | Goal | random min: dead / pay | synergy ⅕: dead / pay |
|---|---|---|---|
| 4 (item 3) | 80 | 2.5% / 50% | 14.5% / 46% |
| 6 (item 4) | 115 | 14% / 76% | 44.5% / 85% |
| 7 flashlight | 170 | 19% / 78% | 57.5% / 62% |
| 9 (item 6) | 290 | 39.5% / 115% | 73% / 98% |
| 10 (item 7) | 380 | 43% / 155% | 75% / 182% |
| 14 (item 10) | 1920 | 53% / 245% | 80.5% / 206% |
| 21 (end) | 41390 | **64.5%** / 333% | 85% / 351% |

**Reading:**
- Late pay dropped from 600–2,500% to about 200–500%, and late deaths exist again: at minimum bet, deaths after fight 10 went from 9% to 21.5%.
- The payout rate still passes 100% from about item 6–7, so **Phase B (Dread + steeper growth) is still needed** to make the late game urgent.
- The ⅕-bet player still hits a wall at fights 5–8 (57.5% dead by the flashlight). Partly that's an aggressive bet style. Decide in Phase B whether the early game should forgive big bets.

### RTP audit

`rtp_audit.gd` baseline (no items): 51.3%. `GuidePages.RTP_PERCENT` = 51, so it stays.
