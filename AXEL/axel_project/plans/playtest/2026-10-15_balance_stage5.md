# Balance stage 5 — reaching ~64 % dead (2026-10-15)

HANDOFF item 5. Target: ~64 % of runs dead by the end at the lowest bet (items uncapped).

## Sweep (200 runs each, min bet, `difficulty_curve_sim.gd`)

Dead by fight 4 / 6 / 9 / 13 / 17 / 21. Stalls = fights that hit 4000 spins without finishing; the sim counts them as deaths, so they are not real losses.

| Setting | Random picks | One-family picks | Stalls (R / S) |
|---|---|---|---|
| Shipped | 3 / 15.5 / 41.5 / 48.5 / 53.5 / **56.5** | 4 / 17 / 44.5 / 54.5 / 57.5 / **59** | 0 / 0 |
| Growth step 0.04 | … / **62** | … / **60** | 9 / 3 |
| Growth step 0.05 | … / **68** | … / **64.5** | 24 / 11 |
| Growth step 0.06 | … / **77** | … / **70** | 40 / 24 |
| Growth 1.6 (step 0.02) | … / **64** | … / **61** | 15 / 3 |
| Growth 1.65, step 0 | … / **59** | … / **58** | 3 / 0 |
| Growth 1.55, step 0.03 | … / **62.5** | … / **60** | 12 / 3 |
| Depth-3 goal ×2.2 | … / **57** | … / **58.5** | 1 / 0 |
| Memory Dread 15 % | … / **57** | … / **59.5** | 1 / 0 |
| Item Dread ×1.5 | 3 / 16 / 40 / 50.5 / 55 / **57.5** | 4.5 / 17 / 47 / 57 / 59.5 / **61** | 0 / 0 |
| Item Dread ×2 | 3 / 17 / 41.5 / 52 / 56 / **61** | 4.5 / 19.5 / 48.5 / 56.5 / 59 / **60** | 3 / 0 |
| Item Dread ×2.5 | 4 / 18 / 43 / 52 / 56 / **62** | 6 / 21 / 48.5 / 56.5 / 59.5 / **59.5** | 6 / 0 |
| Item Dread ×2 + memory 15 % | … / **60.5** | … / **60** | 3 / 0 |
| Ladder tail 150/205/280/380 | … / **59** | … / **59.5** | 0 / 0 |
| ⅕ bet, shipped / item Dread ×2 | **85.5** / **85.5** | | 0 / 0 |

## Finding

- Goal-side levers top out at ~60 % real deaths. The higher numbers are stalls: late fights at the lowest bet need thousands of spins.
- Once a run survives to about fight 13, its payout rate is over 100 % (it earns money every spin), so no goal size can kill it, it only makes the fight longer.
- Reaching 64 % needs a payout-side change (keep late payout under ~100 % until about item 9, the master plan target) or a bet-side change.

## Decision (user, 2026-10-15)

- Items stay uncapped, and the lowest bet never rises (players may always play at 100).
- **Item Dread doubled:** `AxelRun.DREAD_BY_RANK` C 8 / U 10 / R 12 / E 16 / L 20 % (was 4/5/6/8/10). Memory Dread stays 10 %. The sim constant matches.
- Sim tools: `DIFF_RUN_OFFSET` (split one sim over several processes) and `DIFF_RUN_LOG=1` (one `DIFF_RUN` line per run: death fight, main family, picks with fight number).

## Big sim with the new Dread (1000 runs, one-family picks, min bet)

Dead by fight 4 / 6 / 9 / 13 / 17 / 21: 2.5 / 21.7 / 49.8 / 56.5 / 58.8 / **61.0 %** (6 stalls).

**Lift** = survival of runs that picked the item minus the survival of all runs alive at that fight (in points). **Solo** = payout % of the item alone, spins 150–400 at bet 100 (no items: 38.5 %).

### Strongest

| Item | Lift | Solo | Why |
|---|---|---|---|
| E3 Echo Loom | +22.8 | 66 % | 50 % second Wild; wilds family runs survive 74 % |
| R1 Fractured Reel | +20.7 | 1109 % | +10 % per paid spin, uncapped, for the whole fight |
| E4 Overflow Ledger | +20.0 | 1859 % | +15 % per paid spin, uncapped |
| U-M Ink Tag | +17.8 | 69 % | glyph line multiplier, cheap rarity; M runs survive 74 % |
| U1 Filtered Spinner | +15.1 | 1109 % | same as R1 without the free first spin |
| C10 Tarnished Coin | +15.3 | (no solo effect) | check: lift without a solo effect is suspicious |
| R5 Chain Wildseed | +13.9 | 83 % | |
| L-M Red Glyph / L1 Twin Pentagram | +9.5 / +7.3 | 114 % / 139 % | best Legendaries |

The spinpay items (C1, U1, R1, E4) snowball inside one fight: the old `PAID_SPIN_SCALAR_TOTAL_CAP 2.0` is gone, so +10 % per spin keeps stacking. They are the main reason late fights cannot be lost. (AI_DOCS still says this cap exists; fix on "update docs".)

### Weakest

| Item | Lift | Solo |
|---|---|---|
| R2 Gilded Commons | −17.3 | 45 % |
| U-D Free Spins Primer | −15.6 | no effect |
| E-D / C-D / R-D (Free Spins) | −12.6 / −11.0 / −8.8 | no effect |
| C-C Trinity Ash / U-C / R-C / E-C (Vice) | −12.5 / −9.8 / −10.5 / −10.6 | 39–44 % or none |
| R-H / C-H / E-H / L-H (head start) | −10.8 / −5.7 / −5.6 / −2.9 | none (expected) |
| C-A Echo Splinter / U-A / R-A | −10.7 / −5.6 / −4.8 | 39–59 % |
| L-B Meter Blood Moon | −6.1 | 38 % (weakest Legendary, below no items) |
| R4 Glitch Button | −7.6 | 37 % |

Families by survival (main family at the end): M 74 %, wilds 74 %, B 51 %, G / E / F 48 %, spinpay 39 %, C 36 %, H 36 %, D 32 %, pwrwgt 17 %, normpay 6 %, A 6 %, power-chance and single-power lanes 0 %.

## Next (not decided)

- 61 % is still 3 points under 64 %. The clean lever left is the spinpay snowball (a per-fight limit on that one effect) — this would be a cap, so ask first.
- Buff the dead lanes (D, C/Vice, A, single powers, R2, L-B) so one-family play is fair across families.
