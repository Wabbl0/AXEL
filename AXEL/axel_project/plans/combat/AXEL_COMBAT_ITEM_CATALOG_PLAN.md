# AXEL Combat Starter Items Plan

**Single source of truth** for the combat item roster (baseline + extended mechanics). **All future edits go here only** — do not maintain a parallel catalog in `.cursor/plans/` (that path is a stub pointer). Keep aligned with [AXEL_combat_design.md](AXEL_combat_design.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).

## Design conventions (persistent)

- **Extended item ids** use **uppercase** tier letter + hyphen + **uppercase** family letter: `C-A`, `U-M`, `L-H`, etc. (Baseline ids stay **`C1`…`C10`**, **`R1`…`R6`**, **`E1`…`E4`**, **`L1`…`L2`** — digit suffixes vs letter codes.)
- **"Add an item" (new mechanic)** defaults to **five variants**, one per rarity (**Common → Legendary**), unless you explicitly ask for a single tier or subset. Same rule applies in future chats unless stated otherwise.

## Inferred Intent

A detailed item catalog (combat-use, map-gathered) for implementation chats. Includes **31 baseline** entries plus **extended** lines: families **A–F**, corner glyphs **M**, sealed-grid / no top refill **G**, and optional **True-path** passives **H** (nine letters × five rarities = **45** extended). **76 items total.**

## Canon Alignment Check

- Alignment target: [AI_DOCS.md](../core/AI_DOCS.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).
- User-approved override path: diagonal and board-count wins are allowed as **item-scoped core resolver overrides** when equipped.
- **Family G** (no top refill) changes spawn behavior in **base-game regular spins** only: respect Trinity Run / SUPER Free Spins refill rules as separate modes—item should **not** apply or uses explicit override flags per mode.
- Terminology lock: Trinity Run naming and power alias map from [AXEL_combat_design.md](AXEL_combat_design.md).

## External Reference Correlation (Cloverpit)

Use Cloverpit-inspired archetypes, adapted to AXEL spin lifecycle (random triggers, symbol ladders, escalators, late legendaries).

## Extended id scheme (all tiers)

| Tier prefix | Meaning | Baseline ids (unchanged) |
|---|---|---|
| `C-` | Common-tier **extended** | `C1`…`C10` |
| `U-` | Uncommon-tier extended | `U1`…`U8` |
| `R-` | Rare-tier extended | `R1`…`R6` |
| `E-` | Epic-tier extended | `E1`…`E4` |
| `L-` | Legendary-tier extended | `L1`…`L2` |

**Family letters (second part):** **A** power chain, **B** premium meter, **C** Trinity Run, **D** SUPER Free Spins, **E** diagonal, **F** board-count, **M** corner multipliers, **G** sealed grid (no top refill, higher payout), **H** True-path passive (goal penalty, True Ending meta).

---

## Full Catalog by Rarity (75 items)

Original starter items first under each tier; **Extended** follow.
Reroll-scaling on baseline items uses a **separate encounter payout scalar** where noted elsewhere in this doc.

> **Rarity Key:**
> `◇` Common | `◈` Uncommon | `◆` Rare | `★` Epic | `✦` Legendary
>
> **Family Key:**
> `A` Power Chain | `B` Premium Meter | `C` Trinity Run | `D` SUPER Free Spins
> `E` Diagonal Wins | `F` Board-Count | `M` Corner Multipliers | `G` Sealed Grid | `H` True-path

---

### ◇ Common (19)

#### Baseline

| ID | Name | Effect |
|:---:|:---|:---|
| `C1` | **Ash Reroll Token** | Each reroll adds `+0.06x` encounter payout scalar (cap `+0.36x`) |
| `C2` | **Chalk Dust** | Normal-symbol payout value `+10%` |
| `C3` | **Locker Map Pin** | Normal-symbol spawn weight `+8%` |
| `C4` | **Static Spark** | Random power activation chance `+5%` |
| `C5` | **Burn Mark** | If no power activates for 2 spins, next spin gets `+8%` random power chance |
| `C6` | **Cigarette Stub** | Storm-symbol payout value `+10%` |
| `C7` | **Broken Bottle Cap** | Star-symbol payout value `+10%` |
| `C8` | **Bloody Gauze** | Love-symbol payout value `+10%` |
| `C9` | **Dusty Battery** | First non-winning spin each encounter grants `+6%` power-symbol spawn for next spin |
| `C10` | **Tarnished Coin** | On first reroll each encounter, refund 25% reroll cost |

#### Extended

| ID | Name | Family | Effect |
|:---:|:---|:---:|:---|
| `C-A` | **Echo Splinter** | `A` | When any power activates, `20%` chance one other random power activates at `25%` potency |
| `C-B` | **Meter Scratch** | `B` | Premium meter gain from premium lines `+1` on first qualifying line each spin |
| `C-C` | **Trinity Ash** | `C` | During Trinity Run, normal-symbol payout value `+15%` |
| `C-D` | **Super Teaser** | `D` | When entering SUPER Free Spins, gain immediate payout burst (`+0.5x` stake) |
| `C-E` | **Diagonal Chalk** | `E` | Enables major-diagonal contiguous 3+ wins only |
| `C-F` | **Threshold Trace** | `F` | If 8+ matching symbols on board after cascade, award a minor bonus win |
| `C-M` | **Chalk Mark** | `M` | Roll individual random multipliers on random cells; top-left icon. When cell pays in a resolved line, bonus to that spin's winnings only (tune `x2`–`x2.5`) |
| `C-G` | **Locker Tape** | `G` | **Base-game regular spins only** — after line clears + gravity, no new symbols spawn from top; empty cells stay empty until spin chain ends. Payout bonus `+12%` to compensate. Does not override Trinity Run / SUPER refill rules |
| `C-H` | **Loose Thread** | `H` | **Optional passive** — encounter goal **+8%** at start. Tracks toward True Ending meta |

---

### ◈ Uncommon (17)

#### Baseline

| ID | Name | Effect |
|:---:|:---|:---|
| `U1` | **Filtered Reroller** | Each reroll adds `+0.15x` payout scalar (cap `+0.90x`) |
| `U2` | **Iron Lighter** | Normal-symbol payout value `+20%` |
| `U3` | **Weighted Trinity Die** | Total power-symbol spawn weight `+10%` |
| `U4` | **Faulty Relay** | Random power activation chance `+10%` |
| `U5` | **Split Wick** | When a wild is created, `25%` chance to spawn one extra wild in nearest valid empty cell |
| `U6` | **Storm Charm** | Storm symbol chance `+12%`; Storm power removes `+1` extra low-pay set at `20%` chance |
| `U7` | **Star Charm** | Star symbol chance `+12%`; Star power has `30%` chance to add `+1` extra wild |
| `U8` | **Love Charm** | Love symbol chance `+12%`; Love power transforms `+1` extra symbol at `25%` chance |

#### Extended

| ID | Name | Family | Effect |
|:---:|:---|:---:|:---|
| `U-A` | **Echo Fuse** | `A` | `35%` chance one other power activates at `35%` potency |
| `U-B` | **Meter Hook** | `B` | Premium meter gains x`1.25` |
| `U-C` | **Trinity Matchbook** | `C` | At Trinity Run start, gain `+1` starting spin |
| `U-D` | **Super Primer** | `D` | SUPER Free Spins start with `+2` extra spins |
| `U-E` | **Diagonal Compass** | `E` | Enables both major diagonals for 3+ contiguous wins |
| `U-F` | **Threshold Knot** | `F` | Threshold `7+`; bonus payout scalar increased |
| `U-M` | **Ink Tag** | `M` | Same glyph UI as `C-M`; wider band / more tagged cells; winnings-only bonus (tune up to `x3`) |
| `U-G` | **Rusted Hasp** | `G` | Same as `C-G` with stronger payout bonus (`+20%`); base game regular spins only |
| `U-H` | **Torn Label** | `H` | Optional passive — encounter goal **+12%**; True Ending meta |

---

### ◆ Rare (15)

#### Baseline

| ID | Name | Effect |
|:---:|:---|:---|
| `R1` | **Fractured Reel** | Each reroll adds `+0.20x` payout scalar; first reroll per encounter is free |
| `R2` | **Gilded Commons** | All normal symbols gain `+35%` value and `+10%` spawn weight |
| `R3` | **Triune Sigil** | All power symbols gain `+15%` spawn weight and `+15%` payout value |
| `R4` | **Glitch Button** | Random power activation chance doubled; normal-symbol value `-8%` (risk/reward) |
| `R5` | **Chain Wildseed** | Every 2nd wild created in an encounter automatically creates a bonus wild |
| `R6` | **Trinity Echo** | When a random power triggers, `30%` chance to trigger a second at `50%` potency |

#### Extended

| ID | Name | Family | Effect |
|:---:|:---|:---:|:---|
| `R-A` | **Echo Relay** | `A` | Whenever a power activates, one other power activates at `50%` potency |
| `R-B` | **Meter Coil** | `B` | x3/x4/x5 premium-line fills count as `+2/+3/+4` instead of base |
| `R-C` | **Trinity Syringe** | `C` | Each Trinity Run spin that wins grants `+0.2x` temporary run scalar |
| `R-D` | **Super Injector** | `D` | During SUPER Free Spins, each cascade adds `+1` extra payout step |
| `R-E` | **Diagonal Grid Lens** | `E` | Diagonal wins can spawn wilds on exact-3 middle cells (same spawn rule) |
| `R-F` | **Threshold Brand** | `F` | Threshold `6+`; can trigger once per cascade step |
| `R-M` | **Scratch Ticket** | `M` | On match, split: part to spin winnings, part as one-shot bump to active multiplier on next cascade step (60%/40%) |
| `R-G` | **Basement Bar** | `G` | Stronger seal + payout trade (`+28%`); base game regular spins default |
| `R-H` | **Witness Slip** | `H` | Optional — encounter goal **+18%**; True Ending meta |

---

### ★ Epic (13)

#### Baseline

| ID | Name | Effect |
|:---:|:---|:---|
| `E1` | **Ash Crown** | Each power symbol (Storm/Star/Love) gets `+20%` spawn weight; potency `+25%` |
| `E2` | **Null Gravity Pin** | On fully non-winning spin, `40%` chance to force one random power activation |
| `E3` | **Echo Loom** | First wild created each spin duplicates into nearest legal cell |
| `E4` | **Overflow Ledger** | Each reroll adds `+0.30x` payout scalar + `+2%` total power-symbol chance for that encounter |

#### Extended

| ID | Name | Family | Effect |
|:---:|:---|:---:|:---|
| `E-A` | **Trinity Relay Spine** | `A` | Each power activation triggers both other powers at `50%` potency |
| `E-B` | **Meter Furnace** | `B` | Premium meter fills on any winning premium line; `+1` extra if wild participates |
| `E-C` | **Trinity Halo** | `C` | During Trinity Run, first non-winning spin triggers guaranteed chosen power |
| `E-D` | **Super Engine** | `D` | First win each SUPER spin duplicates 1 winning symbol into wild |
| `E-E` | **Diagonal Cruciform** | `E` | Diagonal wins contribute to premium meter at `75%` normal contribution |
| `E-F` | **Threshold Tribunal** | `F` | Board-count wins can trigger premium meter gain at reduced rate |
| `E-M` | **CRT Etching** | `M` | Majority of glyph value feeds active multiplier for rest of spin chain; minority flat spin payout |
| `E-G` | **Mason Lock** | `G` | Large payout trade (`+38%`); base game regular spins default; clarify interaction with forced repopulate hooks |
| `E-H` | **Confession Card** | `H` | Optional — encounter goal **+25%**; True Ending meta |

---

### ✦ Legendary (11)

#### Baseline

| ID | Name | Effect |
|:---:|:---|:---|
| `L1` | **Twin Pentagram** | Whenever a wild is created, create one additional wild (legendary-only pool, late-game) |
| `L2` | **Trinity Overclock** | Each power activation activates all other powers afterward at full potency (once-per-spin cap) |
| `L3` | **Void Satchel** | Expands loadout capacity by `+2` slots (max 9). Utility/meta item; legendary-only gating enforced in `ItemInventory`. Does not contribute to payout scalar |

#### Extended

| ID | Name | Family | Effect |
|:---:|:---|:---:|:---|
| `L-A` | **Trinity Overclock** | `A` | Same rule as `L2` — full chain after each activation. *One implementation, two ids unless merged* |
| `L-B` | **Meter Blood Moon** | `B` | First premium win each spin fully fills one meter section; can overflow |
| `L-C` | **Trinity Crucible** | `C` | During Trinity Run, every spin applies chosen power + one extra random power at `60%` potency |
| `L-D` | **Super Catastrophe** | `D` | During SUPER Free Spins, each power activation chains one extra random power at `75%` potency |
| `L-E` | **Diagonal Covenant** | `E` | Diagonal wins treated as full standard line wins |
| `L-F` | **Threshold Dominion** | `F` | Board-count wins become full resolver wins (strict priority order vs line wins) |
| `L-M` | **Red Glyph** | `M` | Glyph value immediately to active total multiplier for the spin; late pool; high volatility |
| `L-G` | **Iron Lung** | `G` | Maximum seal + payout trade (`+50%`+); base game regular spins; **area-gated** |
| `L-H` | **True Name Tag** | `H` | Optional — encounter goal **+35%**; strongest True Ending unlock weight. Requires meta credit: equip for final qualifying encounter + narrative gates, or own all five `*-H` pieces in meta |

---

### Summary Matrix (Extended Families across Rarities)

| Family | ◇ Common | ◈ Uncommon | ◆ Rare | ★ Epic | ✦ Legendary |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **A** Power Chain | Echo Splinter | Echo Fuse | Echo Relay | Trinity Relay Spine | Trinity Overclock |
| **B** Premium Meter | Meter Scratch | Meter Hook | Meter Coil | Meter Furnace | Meter Blood Moon |
| **C** Trinity Run | Trinity Ash | Trinity Matchbook | Trinity Syringe | Trinity Halo | Trinity Crucible |
| **D** SUPER Spins | Super Teaser | Super Primer | Super Injector | Super Engine | Super Catastrophe |
| **E** Diagonal | Diagonal Chalk | Diagonal Compass | Diagonal Grid Lens | Diagonal Cruciform | Diagonal Covenant |
| **F** Board-Count | Threshold Trace | Threshold Knot | Threshold Brand | Threshold Tribunal | Threshold Dominion |
| **M** Corner Mult. | Chalk Mark | Ink Tag | Scratch Ticket | CRT Etching | Red Glyph |
| **G** Sealed Grid | Locker Tape | Rusted Hasp | Basement Bar | Mason Lock | Iron Lung |
| **H** True-path | Loose Thread | Torn Label | Witness Slip | Confession Card | True Name Tag |

---

## True-path passives (`*-H`) — summary

- **Passive / optional:** player can skip them; skipping avoids goal inflation but **blocks or delays True Ending** unless another canon route is added later.
- **Effect:** increases **current encounter goal** by a **fixed percent** at encounter start (values above are starting tuning).
- **True Ending:** these items are the **mechanical hook** for the "hard honesty / lucid" route aligned with [AXEL_combat_design.md](AXEL_combat_design.md) abstinence/lucid themes — exact gate (single legendary vs full set) is a **design choice** to lock when wiring endings.

---

## Secret Mythic Rank (Post-Starter Variants)

- Optional hidden **Mythic** variant per extended **family lane**: **A, B, C, D, E, F, M, G, H** (nine lanes), unlocked by deep-run conditions.
- Mythics excluded from the **75** numbered pool until unlocked.

## Area / Rarity Progression Plan

- Early: baseline + low extended.
- Mid: `R-*`, `E-*`.
- Late: `L-*`, especially `L-G`, `L-M`, `L-H`.

## Impact Map (Future Implementation Touchpoints)

- Content: [../combat/data/items/](../combat/data/items/)
- Hooks: [../combat/scripts/item_inventory.gd](../combat/scripts/item_inventory.gd), [../combat/scripts/combat_root.gd](../combat/scripts/combat_root.gd)
- Grid / spawn: [../combat/scripts/grid_manager.gd](../combat/scripts/grid_manager.gd) — **family G** must flag "no top refill" per spin phase.
- Goals: `goal_tracker.gd` / encounter def — **family H** adjusts goal threshold at encounter start; meta flags for True Ending in run/narrative state.
- Meta / endings: narrative flags (prototype layer or run singleton) for `*-H` progress.

## Ordered Execution Strategy For Future Chats

1. Baseline `C*` / `U*` / `R*` / `E*` / `L*` items + hooks.
2. Extended **A–F**, **M** lines; dedupe **`L2`** and **`L-A`**.
3. **G** line: refill suppression + payout scalar; mode checks (base vs Trinity Run vs SUPER).
4. **H** line: goal % modifier + meta True Ending flags.
5. Mythic variants after balance pass.

## Validation / Acceptance Checks

- **76** entries: 31 baseline + 45 extended (`C-A`… style).
- **"Add an item"** defaults to **five** rarities unless user narrows scope.
- Corner glyphs (`*-M`) deterministic from seed; `*-G` never breaks depletion-mode features accidentally.
- True-path `*-H` documented for ending team.

## Risks and Fallbacks

- **G + empty grid:** edge cases when board cannot refill — define lose-stuck or forced end-spin behavior in implementation.
- **H stacking:** if multiple `*-H` equipped, clarify additive vs multiplicative goal % — recommend **additive stacking with cap** or **highest only**.
- Resolver overrides (E/F families): keep scoped and logged.

---

## Common-Tier Balance Tuning Note (2026-05-11)

C1 (Ash Reroll Token) was classified **overpowered** by `item_balance_audit` (delta_rtp=+0.465, CI [0.121, 0.808]). Values reduced from `per_reroll=0.10 / cap=0.60` to `per_reroll=0.06 / cap=0.36` (40% reduction).

If common-tier RTP inflation persists after C1 tuning, apply a proportional reduction (~40%) to all **baseline Common** (`C1`–`C10`) effect magnitudes before implementing their `.tres` files:

| ID | Original | Tuned target |
|:---:|:---|:---|
| `C2` | `+10%` payout | `+6%` |
| `C3` | `+8%` spawn weight | `+5%` |
| `C4` | `+5%` power chance | `+3%` |
| `C5` | `+8%` catch-up power chance | `+5%` |
| `C6`–`C8` | `+10%` princess payout | `+6%` |
| `C9` | `+6%` power-symbol spawn | `+4%` |
| `C10` | `25%` reroll refund | `15%` |

Extended commons (`C-A` through `C-H`, `C-M`, `C-G`) should follow the same tuning direction. Re-audit each batch after implementation to verify delta_rtp stays within neutral band (95% CI overlapping zero).
