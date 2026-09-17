# AXEL Combat Item Catalog

**Single source of truth** for the combat item roster (baseline + extended). **All future catalog edits go here only** — do not maintain a parallel catalog in `.cursor/plans/`. Keep aligned with [AXEL_combat_design.md](AXEL_combat_design.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).

This file matches the **live game**: 75 `ItemDef` resources in [combat/data/items/](../../combat/data/items/) and 75 icons in [combat/art/item_icons/](../../combat/art/item_icons/).

## Design conventions (persistent)

- **Extended item ids** use **uppercase** tier letter + hyphen + **uppercase** family letter: `C-A`, `U-M`, `L-H`, etc. (Baseline ids stay **`C1`…`C10`**, **`U1`…`U8`**, **`R1`…`R6`**, **`E1`…`E4`**, **`L1`…`L3`** — digit suffixes vs letter codes.)
- **"Add an item" (new mechanic)** defaults to **five variants**, one per rarity (**Common → Legendary**), unless you explicitly ask for a single tier or subset.
- **`L-A` is unused.** No `.tres`, no icon. Trinity Overclock ships as **`L2`** only. QA fails if `L-A` appears.

## Live roster

**75 items:** 31 baseline + 44 extended.

Extended families are **A–F**, **M**, **G**, **H** (nine lanes). Nine × five rarities would be 45, minus unused `L-A` = **44**.

Opening the locker only sets the tutorial flag (`locker_stash_granted`). It does **not** grant items. Floor scatter rolls extended `TIER-FAMILY` ids (`C-A`, `L-G`, …) **and** baseline lines from [combat/scripts/item_lines.gd](../../combat/scripts/item_lines.gd). It never rolls an id you already own or that is already sitting on a floor. If Legendary family A is rolled, `L-A` is missing so the world walks down to **`E-A`**.

## Canon Alignment Check

- Alignment target: [AI_DOCS.md](../core/AI_DOCS.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).
- User-approved override path: diagonal and board-count wins are allowed as **item-scoped core resolver overrides** when equipped.
- **Family G:** live combat is already gravity-only (`grid.refill()` is never called). G’s live effect is a **regular-spin payout bonus**. A refill skip-guard still exists if refill is ever invoked. G does not run in Trinity or Free Spins.
- Terminology lock: Trinity Run naming and power alias map from [AXEL_combat_design.md](AXEL_combat_design.md). Prefer the name “alcohol” (not “booze”) in docs and user-facing text.

## External Reference Correlation (Cloverpit)

Use Cloverpit-inspired archetypes, adapted to AXEL spin lifecycle (random triggers, symbol ladders, escalators, late legendaries).

## Extended id scheme (all tiers)

| Tier prefix | Meaning | Baseline ids (unchanged) |
|---|---|---|
| `C-` | Common-tier **extended** | `C1`…`C10` |
| `U-` | Uncommon-tier extended | `U1`…`U8` |
| `R-` | Rare-tier extended | `R1`…`R6` |
| `E-` | Epic-tier extended | `E1`…`E4` |
| `L-` | Legendary-tier extended | `L1`…`L3` |

**Family letters (second part):** **A** power chain, **B** premium meter, **C** Trinity Run, **D** Free Spins, **E** diagonal, **F** board-count, **M** corner multipliers, **G** sealed grid (regular-spin payout bonus; refill skip-guard), **H** True-path passive (goal percent).

**Baseline lines** (effect pairing, not digit pairing — `C1` is not `L1`). Source: [combat/scripts/item_lines.gd](../../combat/scripts/item_lines.gd).

- Reroll payout: `C1` → `U1` → `R1` → `E4`
- Normal payout: `C2` → `U2` → `R2`
- Power-symbol weight: `U3` → `R3` → `E1` (`C3` stays a Common unique: normal spawn, not power spawn)
- Power chance: `C4` → `U4` → `R4`
- Storm: `C6` → `U6`
- Star: `C7` → `U7`
- Love: `C8` → `U8`
- Extra wild: `U5` → `R5` → `E3` → `L1` (`L1` is the unique Legendary row)
- Common-only uniques: `C3`, `C5`, `C9`, `C10`
- Not on floor rolls: `L2` (family A), `L3` (slot bag), `R6` (no Common rung)

---

## Full Catalog by Rarity (75 items)

Original starter items first under each tier; **Extended** follow.
Reroll-scaling on baseline items uses a **separate encounter payout scalar**.

Icons are the live 1024×1024 PNGs at `res://combat/art/item_icons/{id}.png`, shown here at 48 px.

> **Rarity Key:**
> `◇` Common | `◈` Uncommon | `◆` Rare | `★` Epic | `✦` Legendary
>
> **Family Key:**
> `A` Power Chain | `B` Premium Meter | `C` Trinity Run | `D` Free Spins
> `E` Diagonal Wins | `F` Board-Count | `M` Corner Multipliers | `G` Sealed Grid | `H` True-path

---

### ◇ Common (19)

#### Baseline

| Icon | ID | Name | Effect |
|:---:|:---:|:---|:---|
| <img src="../../combat/art/item_icons/C1.png" width="48" alt="C1"> | `C1` | **Ash Reroll Token** | Each reroll adds `+0.06x` encounter payout scalar (cap `+0.36x`) |
| <img src="../../combat/art/item_icons/C2.png" width="48" alt="C2"> | `C2` | **Chalk Dust** | Normal-symbol payout value `+10%` |
| <img src="../../combat/art/item_icons/C3.png" width="48" alt="C3"> | `C3` | **Locker Map Pin** | Makes Normal-symbols 8% more likely to appear |
| <img src="../../combat/art/item_icons/C4.png" width="48" alt="C4"> | `C4` | **Static Spark** | Random power activation chance `+5%` |
| <img src="../../combat/art/item_icons/C5.png" width="48" alt="C5"> | `C5` | **Burn Mark** | If no power activates for 2 spins, next spin gets `+8%` random power chance |
| <img src="../../combat/art/item_icons/C6.png" width="48" alt="C6"> | `C6` | **Cigarette Stub** | Storm-symbol payout value `+10%` |
| <img src="../../combat/art/item_icons/C7.png" width="48" alt="C7"> | `C7` | **Broken Bottle Cap** | Star-symbol payout value `+10%` |
| <img src="../../combat/art/item_icons/C8.png" width="48" alt="C8"> | `C8` | **Bloody Gauze** | Love-symbol payout value `+10%` |
| <img src="../../combat/art/item_icons/C9.png" width="48" alt="C9"> | `C9` | **Dusty Battery** | First non-winning spin each encounter grants `+6%` power-symbol spawn for next spin |
| <img src="../../combat/art/item_icons/C10.png" width="48" alt="C10"> | `C10` | **Tarnished Coin** | On first reroll each encounter, refund 25% reroll cost |

#### Extended

| Icon | ID | Name | Family | Effect |
|:---:|:---:|:---|:---:|:---|
| <img src="../../combat/art/item_icons/C-A.png" width="48" alt="C-A"> | `C-A` | **Echo Splinter** | `A` | When any power activates, `20%` chance one other random power activates at `25%` potency |
| <img src="../../combat/art/item_icons/C-B.png" width="48" alt="C-B"> | `C-B` | **Meter Scratch** | `B` | Premium meter gain from premium lines `+1` on first qualifying line each spin |
| <img src="../../combat/art/item_icons/C-C.png" width="48" alt="C-C"> | `C-C` | **Trinity Ash** | `C` | During Trinity Run, normal-symbol payout value `+15%` |
| <img src="../../combat/art/item_icons/C-D.png" width="48" alt="C-D"> | `C-D` | **Free Spins Teaser** | `D` | When entering Free Spins, gain immediate payout burst (`+0.5x` stake; no `0.431` scalar) |
| <img src="../../combat/art/item_icons/C-E.png" width="48" alt="C-E"> | `C-E` | **Diagonal Chalk** | `E` | Enables major-diagonal contiguous 3+ wins only |
| <img src="../../combat/art/item_icons/C-F.png" width="48" alt="C-F"> | `C-F` | **Threshold Trace** | `F` | If 8+ matching symbols on board after cascade, award `0.25×` stake (then `0.431` payout scalar) |
| <img src="../../combat/art/item_icons/C-M.png" width="48" alt="C-M"> | `C-M` | **Chalk Mark** | `M` | 1 random cell, multiplier `x2`–`x2.5`; bonus to that spin’s winnings only |
| <img src="../../combat/art/item_icons/C-G.png" width="48" alt="C-G"> | `C-G` | **Locker Tape** | `G` | Regular spins only — payout bonus `+12%`. Skip-guard if refill is ever invoked. Does not apply in Trinity or Free Spins |
| <img src="../../combat/art/item_icons/C-H.png" width="48" alt="C-H"> | `C-H` | **Loose Thread** | `H` | Encounter goal **+8%** at start (playtest Base and world ladder). Additive with other `*-H` |

---

### ◈ Uncommon (17)

#### Baseline

| Icon | ID | Name | Effect |
|:---:|:---:|:---|:---|
| <img src="../../combat/art/item_icons/U1.png" width="48" alt="U1"> | `U1` | **Filtered Reroller** | Each reroll adds `+0.15x` payout scalar (cap `+0.90x`) |
| <img src="../../combat/art/item_icons/U2.png" width="48" alt="U2"> | `U2` | **Iron Lighter** | Normal-symbol payout value `+20%` |
| <img src="../../combat/art/item_icons/U3.png" width="48" alt="U3"> | `U3` | **Weighted Trinity Die** | Makes power symbols 10% more likely to appear |
| <img src="../../combat/art/item_icons/U4.png" width="48" alt="U4"> | `U4` | **Faulty Relay** | Random power activation chance `+10%` |
| <img src="../../combat/art/item_icons/U5.png" width="48" alt="U5"> | `U5` | **Split Wick** | When a wild is created, `25%` chance to spawn one extra wild in nearest valid empty cell |
| <img src="../../combat/art/item_icons/U6.png" width="48" alt="U6"> | `U6` | **Storm Charm** | Storm symbol chance `+12%`; Storm power removes `+1` extra low-pay set at `20%` chance |
| <img src="../../combat/art/item_icons/U7.png" width="48" alt="U7"> | `U7` | **Star Charm** | Star symbol chance `+12%`; Star power has `30%` chance to add `+1` extra wild |
| <img src="../../combat/art/item_icons/U8.png" width="48" alt="U8"> | `U8` | **Love Charm** | Love symbol chance `+12%`; Love power transforms `+1` extra symbol at `25%` chance |

#### Extended

| Icon | ID | Name | Family | Effect |
|:---:|:---:|:---|:---:|:---|
| <img src="../../combat/art/item_icons/U-A.png" width="48" alt="U-A"> | `U-A` | **Echo Fuse** | `A` | `35%` chance one other power activates at `35%` potency |
| <img src="../../combat/art/item_icons/U-B.png" width="48" alt="U-B"> | `U-B` | **Meter Hook** | `B` | Premium meter gains x`1.25` |
| <img src="../../combat/art/item_icons/U-C.png" width="48" alt="U-C"> | `U-C` | **Trinity Matchbook** | `C` | At Trinity Run start, gain `+1` starting spin |
| <img src="../../combat/art/item_icons/U-D.png" width="48" alt="U-D"> | `U-D` | **Free Spins Primer** | `D` | Free Spins start with `+2` extra spins |
| <img src="../../combat/art/item_icons/U-E.png" width="48" alt="U-E"> | `U-E` | **Diagonal Compass** | `E` | Enables both major diagonals for 3+ contiguous wins |
| <img src="../../combat/art/item_icons/U-F.png" width="48" alt="U-F"> | `U-F` | **Threshold Knot** | `F` | Threshold `7+`; bonus `0.50×` stake (then `0.431` payout scalar) |
| <img src="../../combat/art/item_icons/U-M.png" width="48" alt="U-M"> | `U-M` | **Ink Tag** | `M` | 3 cells, multiplier `x2`–`x3`; winnings-only bonus |
| <img src="../../combat/art/item_icons/U-G.png" width="48" alt="U-G"> | `U-G` | **Rusted Hasp** | `G` | Same as `C-G` with stronger payout bonus (`+20%`); regular spins only |
| <img src="../../combat/art/item_icons/U-H.png" width="48" alt="U-H"> | `U-H` | **Torn Label** | `H` | Encounter goal **+12%** (playtest Base and world ladder) |

---

### ◆ Rare (15)

#### Baseline

| Icon | ID | Name | Effect |
|:---:|:---:|:---|:---|
| <img src="../../combat/art/item_icons/R1.png" width="48" alt="R1"> | `R1` | **Fractured Reel** | Each reroll adds `+0.20x` payout scalar (live cap `99.0` = uncapped); first reroll per encounter is free |
| <img src="../../combat/art/item_icons/R2.png" width="48" alt="R2"> | `R2` | **Gilded Commons** | Normal-symbols pay 35% more and are 10% more likely to appear |
| <img src="../../combat/art/item_icons/R3.png" width="48" alt="R3"> | `R3` | **Triune Sigil** | Power symbols are 15% more likely to appear and pay 15% more |
| <img src="../../combat/art/item_icons/R4.png" width="48" alt="R4"> | `R4` | **Glitch Button** | Random power activation chance doubled; normal-symbol value `-8%` (risk/reward) |
| <img src="../../combat/art/item_icons/R5.png" width="48" alt="R5"> | `R5` | **Chain Wildseed** | Every 2nd wild created in an encounter automatically creates a bonus wild |
| <img src="../../combat/art/item_icons/R6.png" width="48" alt="R6"> | `R6` | **Trinity Echo** | When a random power triggers, `30%` chance to trigger a second at `50%` potency |

#### Extended

| Icon | ID | Name | Family | Effect |
|:---:|:---:|:---|:---:|:---|
| <img src="../../combat/art/item_icons/R-A.png" width="48" alt="R-A"> | `R-A` | **Echo Relay** | `A` | Whenever a power activates, one other power activates at `50%` potency |
| <img src="../../combat/art/item_icons/R-B.png" width="48" alt="R-B"> | `R-B` | **Meter Coil** | `B` | x3/x4/x5 premium-line fills count as `+2/+3/+4` instead of base |
| <img src="../../combat/art/item_icons/R-C.png" width="48" alt="R-C"> | `R-C` | **Trinity Syringe** | `C` | Each Trinity Run spin that wins grants `+0.2x` temporary run scalar |
| <img src="../../combat/art/item_icons/R-D.png" width="48" alt="R-D"> | `R-D` | **Free Spins Injector** | `D` | During Free Spins, each cascade adds `+1` extra payout step |
| <img src="../../combat/art/item_icons/R-E.png" width="48" alt="R-E"> | `R-E` | **Diagonal Grid Lens** | `E` | Both major diagonals; diagonal wins can spawn wilds on exact-3 middle cells |
| <img src="../../combat/art/item_icons/R-F.png" width="48" alt="R-F"> | `R-F` | **Threshold Brand** | `F` | Threshold `6+`; `0.75×` stake (then `0.431` scalar); once per cascade step |
| <img src="../../combat/art/item_icons/R-M.png" width="48" alt="R-M"> | `R-M` | **Scratch Ticket** | `M` | 3 cells, `x2`–`x3`; on match split **60%** to spin winnings, **40%** bump to active multiplier |
| <img src="../../combat/art/item_icons/R-G.png" width="48" alt="R-G"> | `R-G` | **Basement Bar** | `G` | Stronger seal + payout trade (`+28%`); regular spins only |
| <img src="../../combat/art/item_icons/R-H.png" width="48" alt="R-H"> | `R-H` | **Witness Slip** | `H` | Encounter goal **+18%** (playtest Base and world ladder) |

---

### ★ Epic (13)

#### Baseline

| Icon | ID | Name | Effect |
|:---:|:---:|:---|:---|
| <img src="../../combat/art/item_icons/E1.png" width="48" alt="E1"> | `E1` | **Ash Crown** | Each power symbol (Storm/Star/Love) is 20% more likely to appear; potency +25% |
| <img src="../../combat/art/item_icons/E2.png" width="48" alt="E2"> | `E2` | **Null Gravity Pin** | On fully non-winning spin, `40%` chance to force one random power activation |
| <img src="../../combat/art/item_icons/E3.png" width="48" alt="E3"> | `E3` | **Echo Loom** | First wild created each spin duplicates into nearest legal cell |
| <img src="../../combat/art/item_icons/E4.png" width="48" alt="E4"> | `E4` | **Overflow Ledger** | Each reroll adds `+0.30x` payout scalar (live cap `99.0` = uncapped). `+2%` total power-symbol chance **while equipped** (not per reroll) |

#### Extended

| Icon | ID | Name | Family | Effect |
|:---:|:---:|:---|:---:|:---|
| <img src="../../combat/art/item_icons/E-A.png" width="48" alt="E-A"> | `E-A` | **Trinity Relay Spine** | `A` | Each power activation triggers both other powers at `50%` potency |
| <img src="../../combat/art/item_icons/E-B.png" width="48" alt="E-B"> | `E-B` | **Meter Furnace** | `B` | Premium meter fills on any winning premium line (live: at least a full 3-section fill); `+1` extra if wild participates |
| <img src="../../combat/art/item_icons/E-C.png" width="48" alt="E-C"> | `E-C` | **Trinity Halo** | `C` | During Trinity Run, first non-winning spin triggers guaranteed chosen power |
| <img src="../../combat/art/item_icons/E-D.png" width="48" alt="E-D"> | `E-D` | **Free Spins Engine** | `D` | First win each Free Spins spin duplicates 1 winning symbol into wild |
| <img src="../../combat/art/item_icons/E-E.png" width="48" alt="E-E"> | `E-E` | **Diagonal Cruciform** | `E` | Both major diagonals; diagonal wins contribute to premium meter at `75%` normal contribution |
| <img src="../../combat/art/item_icons/E-F.png" width="48" alt="E-F"> | `E-F` | **Threshold Tribunal** | `F` | Threshold `6+`; `0.75×` stake (then `0.431` scalar); board-count also grants **one** premium meter section |
| <img src="../../combat/art/item_icons/E-M.png" width="48" alt="E-M"> | `E-M` | **CRT Etching** | `M` | 4 cells, `x2`–`x3`; live split is **30%** winnings / **70%** active multiplier (hardcoded, not in the `.tres`) |
| <img src="../../combat/art/item_icons/E-G.png" width="48" alt="E-G"> | `E-G` | **Mason Lock** | `G` | Large payout trade (`+38%`); regular spins only |
| <img src="../../combat/art/item_icons/E-H.png" width="48" alt="E-H"> | `E-H` | **Confession Card** | `H` | Encounter goal **+25%** (playtest Base and world ladder) |

---

### ✦ Legendary (11)

#### Baseline

| Icon | ID | Name | Effect |
|:---:|:---:|:---|:---|
| <img src="../../combat/art/item_icons/L1.png" width="48" alt="L1"> | `L1` | **Twin Pentagram** | Whenever a wild is created, create one additional wild (legendary-only pool, late-game) |
| <img src="../../combat/art/item_icons/L2.png" width="48" alt="L2"> | `L2` | **Trinity Overclock** | Each power activation activates all other powers afterward at full potency (once-per-spin cap). This is the family-A legendary unique |
| <img src="../../combat/art/item_icons/L3.png" width="48" alt="L3"> | `L3` | **Void Satchel** | Expands loadout capacity by `+2` slots (max 9). Utility/meta item; legendary-only gating in `ItemInventory`. Does not contribute to payout scalar. World scatter still never rolls `L2` / `L3` / `R6` |

#### Extended

`L-A` is **not in the live game** (no resource, no icon). Overclock is `L2` only.

| Icon | ID | Name | Family | Effect |
|:---:|:---:|:---|:---:|:---|
| <img src="../../combat/art/item_icons/L-B.png" width="48" alt="L-B"> | `L-B` | **Meter Blood Moon** | `B` | First premium win each spin fills **one** meter section (overwrites a longer first line to 1); can overflow |
| <img src="../../combat/art/item_icons/L-C.png" width="48" alt="L-C"> | `L-C` | **Trinity Crucible** | `C` | During Trinity Run, chosen power + one extra random power at `60%` potency when Love/Star/Storm fire in the Trinity sequence |
| <img src="../../combat/art/item_icons/L-D.png" width="48" alt="L-D"> | `L-D` | **Free Spins Catastrophe** | `D` | During Free Spins, each power activation chains one extra random power at `75%` potency |
| <img src="../../combat/art/item_icons/L-E.png" width="48" alt="L-E"> | `L-E` | **Diagonal Covenant** | `E` | Diagonal wins treated as full standard line wins. Live mode is **`all`** (more than the two main diagonals) + wilds |
| <img src="../../combat/art/item_icons/L-F.png" width="48" alt="L-F"> | `L-F` | **Threshold Dominion** | `F` | Threshold `6+`; board-count wins become full resolver wins (line wins first; leftover matching cells clear) |
| <img src="../../combat/art/item_icons/L-M.png" width="48" alt="L-M"> | `L-M` | **Red Glyph** | `M` | 4 cells, `x2.5`–`x3.5`; glyph value immediately to active total multiplier for the spin |
| <img src="../../combat/art/item_icons/L-G.png" width="48" alt="L-G"> | `L-G` | **Iron Lung** | `G` | Maximum seal + payout trade (`+50%`); regular spins only. Not combat-gated — basement floor scatter is the only world roll for family `G` |
| <img src="../../combat/art/item_icons/L-H.png" width="48" alt="L-H"> | `L-H` | **True Name Tag** | `H` | Encounter goal **+35%** (playtest Base and world ladder). Strongest live H percent. True Ending meta flags are **not wired** |

---

### Summary Matrix (Extended Families across Rarities)

| Family | ◇ Common | ◈ Uncommon | ◆ Rare | ★ Epic | ✦ Legendary |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **A** Power Chain | Echo Splinter | Echo Fuse | Echo Relay | Trinity Relay Spine | **L2** Trinity Overclock (not shipped as `L-A`) |
| **B** Premium Meter | Meter Scratch | Meter Hook | Meter Coil | Meter Furnace | Meter Blood Moon |
| **C** Trinity Run | Trinity Ash | Trinity Matchbook | Trinity Syringe | Trinity Halo | Trinity Crucible |
| **D** Free Spins | Free Spins Teaser | Free Spins Primer | Free Spins Injector | Free Spins Engine | Free Spins Catastrophe |
| **E** Diagonal | Diagonal Chalk | Diagonal Compass | Diagonal Grid Lens | Diagonal Cruciform | Diagonal Covenant |
| **F** Board-Count | Threshold Trace | Threshold Knot | Threshold Brand | Threshold Tribunal | Threshold Dominion |
| **M** Corner Mult. | Chalk Mark | Ink Tag | Scratch Ticket | CRT Etching | Red Glyph |
| **G** Sealed Grid | Locker Tape | Rusted Hasp | Basement Bar | Mason Lock | Iron Lung |
| **H** True-path | Loose Thread | Torn Label | Witness Slip | Confession Card | True Name Tag |

---

## True-path passives (`*-H`) — live

- **Effect:** increases the **current encounter goal** by a fixed percent at encounter start: **8 / 12 / 18 / 25 / 35**.
- **Stacking:** percents **add**, then multiply once: `effective = round(base * (1 + sum H% + lore bonus))`. Example: C-H + U-H → `base * 1.20`, not `1.08 * 1.12`.
- **Where:** same formula on the playtest Base target **and** live world-fight ladder bases (`AxelRun.set_goal_base_target_cents()`). `.tres` text still says “playtest Base target”; the code is not playtest-only.
- **True Ending:** not wired. H items only bump the goal. Exact ending gate (single legendary vs full set) is still a design choice.

---

## Family G — live

Live combat never calls `grid.refill()`. Empty cells already stay empty for everyone after gravity.

- Live G effect: regular-spin **payout bonus** **12 / 20 / 28 / 38 / 50%**.
- A skip-guard still runs if refill is ever invoked; it does not apply in Trinity or Free Spins.
- `L-G` has no combat-side area flag. World scatter only rolls family `G` from the basement.

---

## Family M — live cell counts

| ID | Cells | Mult | Destination |
|:---:|:---:|:---|:---|
| `C-M` | 1 | `x2`–`x2.5` | winnings |
| `U-M` | 3 | `x2`–`x3` | winnings |
| `R-M` | 3 | `x2`–`x3` | split 60% winnings / 40% multiplier |
| `E-M` | 4 | `x2`–`x3` | majority_mult — code uses **30%** winnings / **70%** multiplier |
| `L-M` | 4 | `x2.5`–`x3.5` | all_mult |

---

## Family F — live board-count

Line wins resolve first. Placeholder bonuses use `bonus_stake * total_bet * BASELINE_PAYOUT_SCALAR` (`0.431` in `combat_root.gd`), except where noted.

| ID | Threshold | Live extra |
|:---:|:---:|:---|
| `C-F` | 8+ | `0.25×` stake |
| `U-F` | 7+ | `0.50×` stake |
| `R-F` | 6+ | `0.75×` stake; once per cascade step |
| `E-F` | 6+ | `0.75×` stake + one meter section |
| `L-F` | 6+ | full resolver on leftover matching cells |

---

## Secret Mythic Rank (not shipped)

Optional hidden **Mythic** variant per extended family lane (**A, B, C, D, E, F, M, G, H**). Not in the 75-item pool. No `.tres` files.

## Area / Rarity Progression Plan

Live rule (implemented in `scripts/autoload/axel_world.gd`): every area starts
**Common**. An area lifts the rank of every *untouched* area by one tier, once,
the first time you either take an item there or clear it. Cap is Legendary, so
touching four areas puts a still-untouched area at `L-*`.

The six written areas map onto the live rooms like this. `Families` are the
extended lanes each area rolls from. Each pickup also mixes in leftover
baseline lines from `item_lines.gd` (C1–C10 and their later rungs). The roll
walks down from the area's rank until a real `.tres` exists.

| Area | Rooms | Floor items | Families |
|:---|:---|:---:|:---|
| Halls | `1.2_Corridor`, `2.4_ClassroomsCorridor` | 0 + 1 | `F`, `H`, `M` |
| Cafeteria | `2.1_Cafeteria` | 3 | `A`, `D`, `M` |
| Kitchen | `2.3_Kitchen` | 2 | `B`, `E`, `H` |
| Teachers Lounge | `4.1_TeachersLounge` | 2 | `C`, `H`, `M` |
| Classroom | `5.1_Classroom` | 2 | `D`, `E`, `A` |
| Basement | `1.4_BasementDoor` | 1 | `G`, `B`, `F` |

`3.1_Backyard` is outdoors: no floor items, and no walking encounters, ever.
`1.1_SchoolExterior` and `1.2_Corridor` also never hold floor items, but they
do get walking encounters once the locker tutorial is done and some other room
has already hosted a fight — so `Halls` is cleared by 2.4's single item.
Details: `plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md`.

Every floor item shows the same white pointing-hand marker rather than its own
picture; the item's name, description and real icon appear on a walk-near card.

Rough shape over a playthrough:

- Early: Common baseline (`C1`–`C10`) + low extended.
- Mid: `R-*`, `E-*`.
- Late: `L-*`, especially `L-G`, `L-M`, `L-H`.

## Live code (where the 75 items live)

- Content: [../../combat/data/items/](../../combat/data/items/) — 75 `ItemDef` `.tres` files
- Class: [../../combat/scripts/item_def.gd](../../combat/scripts/item_def.gd)
- Catalog scan: [../../scripts/autoload/axel_run.gd](../../scripts/autoload/axel_run.gd) (`_ensure_catalog()`, locker open flag only)
- Baseline lines: [../../combat/scripts/item_lines.gd](../../combat/scripts/item_lines.gd)
- Inventory cap 7, or 9 with `L3`: [../../combat/scripts/item_inventory.gd](../../combat/scripts/item_inventory.gd)
- Effect math: [../../combat/scripts/item_effect_dispatcher.gd](../../combat/scripts/item_effect_dispatcher.gd)
- Hooks: [../../combat/scripts/combat_root.gd](../../combat/scripts/combat_root.gd)
- World floor ranks / families: [../../scripts/autoload/axel_world.gd](../../scripts/autoload/axel_world.gd)
- Icon QA: [../../tools/qa/item_icons_check.gd](../../tools/qa/item_icons_check.gd) — **75 × 1024**, no `L-A`. Draw-size QA: [../../tools/qa/item_icon_draw_size_check.gd](../../tools/qa/item_icon_draw_size_check.gd) — combat ITEMS/equipped **48px**, locker shelf buttons **1024px**.

## Still future

1. Mythic variants after a balance pass.
2. True Ending meta flags for `*-H` (items only bump the goal today).

## Validation / Acceptance Checks

- **75** live entries: 31 baseline + 44 extended. `L-A` must stay absent.
- **"Add an item"** defaults to **five** rarities unless the user narrows scope.
- Every live id has `res://combat/art/item_icons/{id}.png` at **1024×1024**.
- Corner glyphs (`*-M`) are deterministic from seed.
- `*-G` must not break depletion-mode features if refill is ever turned on.

## Risks and Fallbacks

- **G + empty grid:** edge cases if refill returns — define lose-stuck or forced end-spin behavior then.
- **H stacking:** playtest and world fights use **additive** goal percents on the Base target.
- Resolver overrides (E/F families): keep scoped and logged. **Family F vs lines:** line wins resolve first; L-F board-count full-resolver clears leftover matching cells not already paid this cascade step.

## Playtest HUD (combat_test only)

Not player-final. Right-hand ITEMS list:

- Rebuilds from `combat/data/items/` at Play (FAMILIES + uniques). Rebind the live `ScrollContainer` children — do not trust scene-saved panel meta `Object()` copies. The catalog picker is F6 `combat_test.tscn` only. World fights load `combat_run.tscn` and **show** `NEW_Items`: locker tutorial (and F6 preview) is the empty DVD mill + red “Nothing but us chickens.” ticker; later fights are a read-only list of equipped icons. No checkboxes, no rank buttons, no catalog.
- **Family rows** (C→E rank button, no Legendary on the slider): A Power Chain, B Premium Meter, C Trinity, D Free Spins, E Diagonal, F Board-count, M Corner glyphs, G Sealed grid, H True-path, plus baseline lines (Reroll payout, Normal payout, Power-symbol weight, Power chance, Storm, Star, Love, Extra wild). Legendary of a line is a unique row (`L2` Overclock is the A legendary unique; `L1` is the Extra-wild legendary unique; `L-B`…`L-H` unique).
- **Unique items** grouped by rarity (rainbow rarity text). Common-only leftovers stay here (`C3`, `C5`, `C9`, `C10`). Within a rarity group, sort by real item number (`C3` before `C10`, not string order). `L-A` is not listed.
- Header `ITEMS (n/max)` plus debug **Ignore slot cap** (off by default). Default cap 7, or 9 with Void Satchel.
- **REROLLS** (paid EXECUTE spins only, not Free Spins remaining): Used SpinBox sets `_spins_used` (C1 / U1 / R1 / E4 / C10). Optional Budget + Limit spins gate. Does not reseed.
- **GOAL:** Base Target + Progress live in **AxelCombatDevTools** (debug wrench menu), not the ITEMS panel. Effective = `round(base * (1 + sum of equipped H percents + lore bonus))`. `%GoalLabel` stays as display. **Live world fights do not use the 10000 default** — `AxelRun` pushes the ladder rung (3000 / 5000 / 7500 / 10000 / 15000 / 20000 / 30000, then ×1.5 per further fight) through `set_goal_base_target_cents()`, and H percents multiply on top of that. Act fights keep 10000.
- **Hover description:** runtime `ItemDescOverlay` (not saved in the `.tscn`). Own **CanvasLayer 107** (above WidgetLayer 106, below CRT 108) so it **can draw over** item rows. Solid black fill, whole card **90%** opacity, word wrap, 0.08s fade-in (text swap while open stays instant). Tries to sit under the cursor / below the row and clip to the ITEMS rectangle.

## Icons (live)

- Game path: `res://combat/art/item_icons/{id}.png` on `ItemDef.icon`.
- Size: **1024×1024** files. File gate: `tools/qa/item_icons_check.gd`. On-screen gate: `tools/qa/item_icon_draw_size_check.gd` (combat 48px / locker 1024px).
- Draw size: combat ITEMS list and equipped panel **48px**; locker shelf buttons **1024px** on screen (one column, scroll). Walk-near card stays 64px. Do not re-run the old 48×48 baker (`bake_item_icons.gd`) or `bake_item_icons_256.gd` — those sizes overwrite the 1024 set.
- Floor pickups never show this picture — shared white pointing hand only. Name / description / icon appear on the walk-near card, locker buttons, and the playtest ITEMS list.
- All **75** live icons are detailed 8-band noir remaps. Stage originals in `tools/combat/ai_icon_src/{id}.png`. Skip `L-A`.
- Bake-time LimeZu map still lives in `tools/combat/item_icon_sources.json` (CLI folder args only — no machine-absolute paths in gameplay). Family A (C-A…E-A) must **not** reuse the L2 clock.

---

## Common-tier balance note (history — 2026-05-11)

C1 (Ash Reroll Token) was classified **overpowered** by `item_balance_audit` (delta_rtp=+0.465). Values were cut from `per_reroll=0.10 / cap=0.60` to **`per_reroll=0.06 / cap=0.36`**. **That C1 cut shipped.**

A later note proposed a ~40% cut to **C2–C10** and the extended commons. **Those cuts did not ship.** Live commons stay at the main-table values (`C2` +10%, `C3` +8%, `C4` +5%, `C5` +8%, `C6`–`C8` +10%, `C9` +6%, `C10` 25% refund; extended commons unchanged).
