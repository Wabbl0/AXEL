# AXEL Combat Item Catalog

**Single source of truth** for the combat item roster (baseline + extended). **All future catalog edits go here only** — do not maintain a parallel catalog in `.cursor/plans/`. Keep aligned with [AXEL_combat_design.md](AXEL_combat_design.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).

This file matches the **live game**: 75 `ItemDef` resources in [combat/data/items/](../../combat/data/items/) and 75 icons in [combat/art/item_icons/](../../combat/art/item_icons/).

## Design conventions (persistent)

- **Extended item ids** use **uppercase** tier letter + hyphen + **uppercase** family letter: `C-A`, `U-M`, `L-H`, etc. (Baseline ids stay `C1`**…**`C10`, `U1`**…**`U8`, `R1`**…**`R6`, `E1`**…**`E4`, `L1`**…**`L3` — digit suffixes vs letter codes.)
- **"Add an item" (new mechanic)** defaults to **five variants**, one per rarity (**Common → Legendary**), unless you explicitly ask for a single tier or subset.
- `L-A` **is unused.** No `.tres`, no icon. Vice Overclock ships as `L2` only. QA fails if `L-A` appears.

## Live roster

**75 items:** 31 baseline + 44 extended.

Extended families are **A–F**, **M**, **G**, **H** (nine lanes). Nine × five rarities would be 45, minus unused `L-A` = **44**.

Opening the locker only sets the tutorial flag (`locker_stash_granted`). It does **not** grant items. Floor scatter rolls extended `TIER-FAMILY` ids (`C-A`, `L-G`, …) **and** baseline lines from [combat/scripts/item_lines.gd](../../combat/scripts/item_lines.gd). It never rolls an id you already own or that is already sitting on a floor. If Legendary family A is rolled, `L-A` is missing so the world walks down to `E-A`.

## Canon Alignment Check

- Alignment target: [AI_DOCS.md](../core/AI_DOCS.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).
- User-approved override path: diagonal and board-count wins are allowed as **item-scoped core resolver overrides** when equipped.
- **Family G:** live combat is already gravity-only (`grid.refill()` is never called). G’s live effect is a **regular-spin payout bonus**. A refill skip-guard still exists if refill is ever invoked. G does not run in Vice Round or Free Spins.
- Terminology lock: Vice Round naming and power alias map from [AXEL_combat_design.md](AXEL_combat_design.md). Prefer the name “alcohol” (not “booze”) in docs and user-facing text. Player-facing item names use **Vice** (Vice Ash, Weighted Vice Die, …), not Trinity. File stems and `effect_id` may still say `trinity`. Vice charms and symbols use cigarette / alcohol / bloody hand (code ids are `cigarette` / `alcohol` / `bloody_hand`).

## External Reference Correlation (Cloverpit)

Use Cloverpit-inspired archetypes, adapted to AXEL spin lifecycle (random triggers, symbol ladders, escalators, late legendaries).

## Extended id scheme (all tiers)


| Tier prefix | Meaning                  | Baseline ids (unchanged) |
| ----------- | ------------------------ | ------------------------ |
| `C-`        | Common-tier **extended** | `C1`…`C10`               |
| `U-`        | Uncommon-tier extended   | `U1`…`U8`                |
| `R-`        | Rare-tier extended       | `R1`…`R6`                |
| `E-`        | Epic-tier extended       | `E1`…`E4`                |
| `L-`        | Legendary-tier extended  | `L1`…`L3`                |


**Family letters (second part):** **A** power chain, **B** premium meter, **C** Vice Round, **D** Free Spins, **E** diagonal, **F** board-count, **M** corner multipliers, **G** sealed grid (regular-spin payout bonus; refill skip-guard), **H** True-path passive (goal percent).

**Baseline lines** (effect pairing, not digit pairing — `C1` is not `L1`). Source: [combat/scripts/item_lines.gd](../../combat/scripts/item_lines.gd).

- Paid spin payout: `C1` → `U1` → `R1` → `E4`
- Normal payout: `C2` → `U2` → `R2`
- Power-symbol weight: `U3` → `R3` → `E1` (`C3` stays a Common unique: normal spawn, not power spawn)
- Power chance: `C4` → `U4` → `R4`
- Cigarette: `C6` → `U6`
- Alcohol: `C7` → `U7`
- Bloody Hand: `C8` → `U8`
- Extra wild: `U5` → `R5` → `E3` → `L1` (`L1` is the unique Legendary row)
- Common-only uniques: `C3`, `C5`, `C9`, `C10`
- Not on floor rolls: `L2` (family A), `L3` (slot bag), `R6` (no Common rung)

---

## Full Catalog by Rarity (75 items)

Original starter items first under each tier; **Extended** follow.
Paid-spin scaling on baseline items uses a **separate encounter payout scalar**.

Icons are the live 1024×1024 PNGs at `res://combat/art/item_icons/{id}.png`, shown here at 48 px.

> **Rarity Key:**
> `◇` Common | `◈` Uncommon | `◆` Rare | `★` Epic | `✦` Legendary
>
> **Family Key:**
> `A` Power Chain | `B` Premium Meter | `C` Vice Round | `D` Free Spins
> `E` Diagonal Wins | `F` Board-Count | `M` Corner Multipliers | `G` Sealed Grid | `H` True-path

---

### ◇ Common (19)

#### Baseline


| Icon                                        | ID    | Name                  | Effect                                                                               |
| ------------------------------------------- | ----- | --------------------- | ------------------------------------------------------------------------------------ |
| ![C1](../../combat/art/item_icons/C1.png)   | `C1`  | **Ash Spin Token**    | Each paid spin adds `+0.10x` encounter payout scalar (cap `+0.40x`)                  |
| ![C2](../../combat/art/item_icons/C2.png)   | `C2`  | **Chalk Dust**        | Normal-symbol payout value `+10%`                                                    |
| ![C3](../../combat/art/item_icons/C3.png)   | `C3`  | **Locker Map Pin**    | Makes Normal-symbols 10% more likely to appear                                       |
| ![C4](../../combat/art/item_icons/C4.png)   | `C4`  | **Static Spark**      | Random power activation chance `+5%`                                                 |
| ![C5](../../combat/art/item_icons/C5.png)   | `C5`  | **Burn Mark**         | If no power activates for 2 spins, next spin gets `+10%` random power chance         |
| ![C6](../../combat/art/item_icons/C6.png)   | `C6`  | **Cigarette Stub**    | Cigarette-symbol payout value `+10%`                                                 |
| ![C7](../../combat/art/item_icons/C7.png)   | `C7`  | **Broken Bottle Cap** | Alcohol-symbol payout value `+10%`                                                   |
| ![C8](../../combat/art/item_icons/C8.png)   | `C8`  | **Bloody Gauze**      | Bloody-hand-symbol payout value `+10%`                                               |
| ![C9](../../combat/art/item_icons/C9.png)   | `C9`  | **Dusty Battery**     | First non-winning spin each encounter grants `+10%` power-symbol spawn for next spin |
| ![C10](../../combat/art/item_icons/C10.png) | `C10` | **Tarnished Coin**    | On first paid spin each encounter, refund 25% of the bet                             |


#### Extended


| Icon                                        | ID    | Name                  | Family | Effect                                                                                                                     |
| ------------------------------------------- | ----- | --------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------- |
| ![C-A](../../combat/art/item_icons/C-A.png) | `C-A` | **Echo Splinter**     | `A`    | When any power activates, `20%` chance one other random power activates at `25%` potency                                   |
| ![C-B](../../combat/art/item_icons/C-B.png) | `C-B` | **Meter Scratch**     | `B`    | Premium meter gain from premium lines `+1` on first qualifying line each spin                                              |
| ![C-C](../../combat/art/item_icons/C-C.png) | `C-C` | **Vice Ash**          | `C`    | During Vice Round, normal-symbol payout value `+15%`                                                                       |
| ![C-D](../../combat/art/item_icons/C-D.png) | `C-D` | **Free Spins Teaser** | `D`    | When entering Free Spins, gain immediate payout burst (`+0.5x` stake; no `0.431` scalar)                                   |
| ![C-E](../../combat/art/item_icons/C-E.png) | `C-E` | **Diagonal Chalk**    | `E`    | Enables major-diagonal contiguous 3+ wins only                                                                             |
| ![C-F](../../combat/art/item_icons/C-F.png) | `C-F` | **Threshold Trace**   | `F`    | If 8+ matching symbols on board after cascade, award `0.25×` stake (then `0.431` payout scalar)                            |
| ![C-M](../../combat/art/item_icons/C-M.png) | `C-M` | **Chalk Mark**        | `M`    | 1 random cell, multiplier `x2`–`x2.5`; bonus to that spin’s winnings only                                                  |
| ![C-G](../../combat/art/item_icons/C-G.png) | `C-G` | **Locker Tape**       | `G`    | Regular spins only — payout bonus `+15%`. Skip-guard if refill is ever invoked. Does not apply in Vice Round or Free Spins |
| ![C-H](../../combat/art/item_icons/C-H.png) | `C-H` | **Loose Thread**      | `H`    | Each fight starts with **5%** of the goal already paid. Additive with other `*-H`                               |


---

### ◈ Uncommon (17)

#### Baseline


| Icon                                      | ID   | Name                  | Effect                                                                                           |
| ----------------------------------------- | ---- | --------------------- | ------------------------------------------------------------------------------------------------ |
| ![U1](../../combat/art/item_icons/U1.png) | `U1` | **Filtered Spinner**  | Each paid spin adds `+0.10x` payout scalar (cap `+0.60x`)                                        |
| ![U2](../../combat/art/item_icons/U2.png) | `U2` | **Iron Lighter**      | Normal-symbol payout value `+20%`                                                                |
| ![U3](../../combat/art/item_icons/U3.png) | `U3` | **Weighted Vice Die** | Makes power symbols 10% more likely to appear                                                    |
| ![U4](../../combat/art/item_icons/U4.png) | `U4` | **Faulty Relay**      | Random power activation chance `+10%`                                                            |
| ![U5](../../combat/art/item_icons/U5.png) | `U5` | **Split Wick**        | When a wild is created, `25%` chance to spawn one extra wild in nearest valid empty cell         |
| ![U6](../../combat/art/item_icons/U6.png) | `U6` | **Cigarette Charm**   | Cigarette symbol chance `+15%`; Cigarette power removes `+1` extra low-pay set at `20%` chance   |
| ![U7](../../combat/art/item_icons/U7.png) | `U7` | **Alcohol Charm**     | Alcohol symbol chance `+15%`; Alcohol power has `30%` chance to add `+1` extra wild              |
| ![U8](../../combat/art/item_icons/U8.png) | `U8` | **Bloody Hand Charm** | Bloody-hand symbol chance `+15%`; Bloody-hand power transforms `+1` extra symbol at `25%` chance |


#### Extended


| Icon                                        | ID    | Name                  | Family | Effect                                                                |
| ------------------------------------------- | ----- | --------------------- | ------ | --------------------------------------------------------------------- |
| ![U-A](../../combat/art/item_icons/U-A.png) | `U-A` | **Echo Fuse**         | `A`    | `35%` chance one other power activates at `35%` potency               |
| ![U-B](../../combat/art/item_icons/U-B.png) | `U-B` | **Meter Hook**        | `B`    | Premium meter gains x`1.25`                                           |
| ![U-C](../../combat/art/item_icons/U-C.png) | `U-C` | **Vice Matchbook**    | `C`    | If Vice Round's first spin has no matches, gain `+1` extra spin       |
| ![U-D](../../combat/art/item_icons/U-D.png) | `U-D` | **Free Spins Primer** | `D`    | Free Spins start with `+2` extra spins                                |
| ![U-E](../../combat/art/item_icons/U-E.png) | `U-E` | **Diagonal Compass**  | `E`    | Enables both major diagonals for 3+ contiguous wins                   |
| ![U-F](../../combat/art/item_icons/U-F.png) | `U-F` | **Threshold Knot**    | `F`    | Threshold `7+`; bonus `0.50×` stake (then `0.431` payout scalar)      |
| ![U-M](../../combat/art/item_icons/U-M.png) | `U-M` | **Ink Tag**           | `M`    | 3 cells, multiplier `x2`–`x3`; winnings-only bonus                    |
| ![U-G](../../combat/art/item_icons/U-G.png) | `U-G` | **Rusted Hasp**       | `G`    | Same as `C-G` with stronger payout bonus (`+20%`); regular spins only |
| ![U-H](../../combat/art/item_icons/U-H.png) | `U-H` | **Torn Label**        | `H`    | Each fight starts with **10%** of the goal already paid              |


---

### ◆ Rare (15)

#### Baseline


| Icon                                      | ID   | Name               | Effect                                                                                                         |
| ----------------------------------------- | ---- | ------------------ | -------------------------------------------------------------------------------------------------------------- |
| ![R1](../../combat/art/item_icons/R1.png) | `R1` | **Fractured Reel** | Each paid spin adds `+0.10x` payout scalar (cap `+1.00x`); first paid spin per encounter is free |
| ![R2](../../combat/art/item_icons/R2.png) | `R2` | **Gilded Commons** | Normal-symbols pay 35% more and are 10% more likely to appear                                                  |
| ![R3](../../combat/art/item_icons/R3.png) | `R3` | **Triune Sigil**   | Power symbols are 15% more likely to appear and pay 15% more                                                   |
| ![R4](../../combat/art/item_icons/R4.png) | `R4` | **Glitch Button**  | Random power activation chance doubled (no downside)                               |
| ![R5](../../combat/art/item_icons/R5.png) | `R5` | **Chain Wildseed** | Every 3rd wild created in an encounter automatically creates a bonus wild                                      |
| ![R6](../../combat/art/item_icons/R6.png) | `R6` | **Vice Echo**      | When a random power triggers, `30%` chance to trigger a second at `50%` potency                                |


#### Extended


| Icon                                        | ID    | Name                    | Family | Effect                                                                                         |
| ------------------------------------------- | ----- | ----------------------- | ------ | ---------------------------------------------------------------------------------------------- |
| ![R-A](../../combat/art/item_icons/R-A.png) | `R-A` | **Echo Relay**          | `A`    | Whenever a power activates, one other power activates at `50%` potency                         |
| ![R-B](../../combat/art/item_icons/R-B.png) | `R-B` | **Meter Coil**          | `B`    | x3/x4/x5 premium-line fills count as `+2/+3/+4` instead of base                                |
| ![R-C](../../combat/art/item_icons/R-C.png) | `R-C` | **Vice Syringe**        | `C`    | Each Vice Round spin that wins grants `+0.2x` temporary run scalar                             |
| ![R-D](../../combat/art/item_icons/R-D.png) | `R-D` | **Free Spins Injector** | `D`    | During Free Spins, each cascade adds `+1` extra payout step                                    |
| ![R-E](../../combat/art/item_icons/R-E.png) | `R-E` | **Diagonal Grid Lens**  | `E`    | Major diagonal only; diagonal wins can spawn wilds on exact-3 middle cells                    |
| ![R-F](../../combat/art/item_icons/R-F.png) | `R-F` | **Threshold Brand**     | `F`    | Threshold `6+`; `0.75×` stake (then `0.431` scalar); once per cascade step                     |
| ![R-M](../../combat/art/item_icons/R-M.png) | `R-M` | **Scratch Ticket**      | `M`    | 3 cells, `x2`–`x3`; on match split **60%** to spin winnings, **40%** bump to active multiplier |
| ![R-G](../../combat/art/item_icons/R-G.png) | `R-G` | **Basement Bar**        | `G`    | Stronger seal + payout trade (`+30%`); regular spins only                                      |
| ![R-H](../../combat/art/item_icons/R-H.png) | `R-H` | **Witness Slip**        | `H`    | Each fight starts with **15%** of the goal already paid                                       |


---

### ★ Epic (13)

#### Baseline


| Icon                                      | ID   | Name                 | Effect                                                                                                                                          |
| ----------------------------------------- | ---- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| ![E1](../../combat/art/item_icons/E1.png) | `E1` | **Ash Crown**        | Each power symbol (cigarette / alcohol / bloody hand) is 20% more likely to appear; potency +25%                                                |
| ![E2](../../combat/art/item_icons/E2.png) | `E2` | **Null Gravity Pin** | On fully non-winning spin, `40%` chance to force one random power activation                                                                    |
| ![E3](../../combat/art/item_icons/E3.png) | `E3` | **Echo Loom**        | First wild created each spin duplicates into nearest legal cell                                                                                 |
| ![E4](../../combat/art/item_icons/E4.png) | `E4` | **Overflow Ledger**  | Each paid spin adds `+0.15x` payout scalar (cap `+1.50x`). `+5%` total power-symbol chance **while equipped** (not per paid spin) |


#### Extended


| Icon                                        | ID    | Name                   | Family | Effect                                                                                                                  |
| ------------------------------------------- | ----- | ---------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------- |
| ![E-A](../../combat/art/item_icons/E-A.png) | `E-A` | **Vice Relay Spine**   | `A`    | Each power activation triggers both other powers at `50%` potency                                                       |
| ![E-B](../../combat/art/item_icons/E-B.png) | `E-B` | **Meter Furnace**      | `B`    | Premium meter fills on any winning premium line (live: at least a full 3-section fill) |
| ![E-C](../../combat/art/item_icons/E-C.png) | `E-C` | **Vice Halo**          | `C`    | During the Vice Round, every power fires at **150%** strength (`vice_potency: 1.5`)                                              |
| ![E-D](../../combat/art/item_icons/E-D.png) | `E-D` | **Free Spins Engine**  | `D`    | First win each Free Spins spin duplicates 1 winning symbol into wild                                                    |
| ![E-E](../../combat/art/item_icons/E-E.png) | `E-E` | **Diagonal Cruciform** | `E`    | Both major diagonals; diagonal wins contribute to premium meter at `75%` normal contribution                            |
| ![E-F](../../combat/art/item_icons/E-F.png) | `E-F` | **Threshold Tribunal** | `F`    | Threshold `6+`; `0.75×` stake (then `0.431` scalar); board-count also grants **one** premium meter section              |
| ![E-M](../../combat/art/item_icons/E-M.png) | `E-M` | **CRT Etching**        | `M`    | 4 cells, `x2`–`x3`; a marked win adds the full mark (rounded) to the active multiplier (`dest: all_mult`)          |
| ![E-G](../../combat/art/item_icons/E-G.png) | `E-G` | **Mason Lock**         | `G`    | Large payout trade (`+40%`); regular spins only                                                                         |
| ![E-H](../../combat/art/item_icons/E-H.png) | `E-H` | **Confession Card**    | `H`    | Each fight starts with **20%** of the goal already paid                                                                |


---

### ✦ Legendary (11)

#### Baseline


| Icon                                      | ID   | Name               | Effect                                                                                                                                                                                                |
| ----------------------------------------- | ---- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![L1](../../combat/art/item_icons/L1.png) | `L1` | **Twin Pentagram** | Whenever a wild is created, create one additional wild (legendary-only pool, late-game)                                                                                                               |
| ![L2](../../combat/art/item_icons/L2.png) | `L2` | **Vice Overclock** | Each power activation activates all other powers afterward at full potency (once-per-spin cap). This is the family-A legendary unique                                                                 |
| ![L3](../../combat/art/item_icons/L3.png) | `L3` | **Void Satchel**   | Expands loadout capacity by `+2` slots (max 9). Utility/meta item; legendary-only gating in `ItemInventory`. Does not contribute to payout scalar. World scatter still never rolls `L2` / `L3` / `R6` |


#### Extended

`L-A` is **not in the live game** (no resource, no icon). Overclock is `L2` only.


| Icon                                        | ID    | Name                       | Family | Effect                                                                                                                                           |
| ------------------------------------------- | ----- | -------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| ![L-B](../../combat/art/item_icons/L-B.png) | `L-B` | **Meter Blood Moon**       | `B`    | First premium win each spin fills **one** meter section (overwrites a longer first line to 1); can overflow                                      |
| ![L-C](../../combat/art/item_icons/L-C.png) | `L-C` | **Vice Crucible**          | `C`    | During Vice Round, chosen power + one extra random power at `60%` potency when bloody hand / alcohol / cigarette fire in the Vice Round sequence |
| ![L-D](../../combat/art/item_icons/L-D.png) | `L-D` | **Free Spins Catastrophe** | `D`    | During Free Spins, each power activation chains one extra random power at `75%` potency                                                          |
| ![L-E](../../combat/art/item_icons/L-E.png) | `L-E` | **Diagonal Covenant**      | `E`    | Diagonal wins treated as full standard line wins. Live mode is `all` (more than the two main diagonals) + wilds                                  |
| ![L-F](../../combat/art/item_icons/L-F.png) | `L-F` | **Threshold Dominion**     | `F`    | Threshold `8+`; board-count wins become full resolver wins (line wins first; leftover matching cells clear)                                      |
| ![L-M](../../combat/art/item_icons/L-M.png) | `L-M` | **Red Glyph**              | `M`    | 4 cells, `x2.5`–`x3.5`; glyph value immediately to active total multiplier for the spin                                                          |
| ![L-G](../../combat/art/item_icons/L-G.png) | `L-G` | **Iron Lung**              | `G`    | Maximum seal + payout trade (`+50%`); regular spins only. Not combat-gated — basement floor scatter is the only world roll for family `G`        |
| ![L-H](../../combat/art/item_icons/L-H.png) | `L-H` | **True Name Tag**          | `H`    | Each fight starts with **25%** of the goal already paid. Strongest live H percent. True Ending meta flags are **not wired**                     |


---

### Summary Matrix (Extended Families across Rarities)


| Family              | ◇ Common          | ◈ Uncommon        | ◆ Rare              | ★ Epic             | ✦ Legendary                                  |
| ------------------- | ----------------- | ----------------- | ------------------- | ------------------ | -------------------------------------------- |
| **A** Power Chain   | Echo Splinter     | Echo Fuse         | Echo Relay          | Vice Relay Spine   | **L2** Vice Overclock (not shipped as `L-A`) |
| **B** Premium Meter | Meter Scratch     | Meter Hook        | Meter Coil          | Meter Furnace      | Meter Blood Moon                             |
| **C** Vice Round    | Vice Ash          | Vice Matchbook    | Vice Syringe        | Vice Halo          | Vice Crucible                                |
| **D** Free Spins    | Free Spins Teaser | Free Spins Primer | Free Spins Injector | Free Spins Engine  | Free Spins Catastrophe                       |
| **E** Diagonal      | Diagonal Chalk    | Diagonal Compass  | Diagonal Grid Lens  | Diagonal Cruciform | Diagonal Covenant                            |
| **F** Board-Count   | Threshold Trace   | Threshold Knot    | Threshold Brand     | Threshold Tribunal | Threshold Dominion                           |
| **M** Corner Mult.  | Chalk Mark        | Ink Tag           | Scratch Ticket      | CRT Etching        | Red Glyph                                    |
| **G** Sealed Grid   | Locker Tape       | Rusted Hasp       | Basement Bar        | Mason Lock         | Iron Lung                                    |
| **H** True-path     | Loose Thread      | Torn Label        | Witness Slip        | Confession Card    | True Name Tag                                |


---

## True-path passives (`*-H`) — live

- **Effect (`goal_head_start`, `paid_percent`):** each fight starts with a share of the goal already counted toward GOAL: **5 / 10 / 15 / 20 / 25%**. The goal itself does not change.
- **Stacking:** percents **add**, capped at **50%** (`HEAD_START_CAP` in `item_effect_dispatcher.gd`), then `floor(goal * pct)` to a multiple of 5, never the full goal. Example: C-H + U-H → 15%.
- **Where:** `CombatRoot._refresh_goal_head_start()` on fight setup and on loadout or goal change, until the first paid spin. Same on the playtest Base target and live world-fight ladder.
- **True Ending:** not wired. H items only give the head start. Exact ending gate (single legendary vs full set) is still a design choice.

---

## Family G — live

Live combat never calls `grid.refill()`. Empty cells already stay empty for everyone after gravity.

- Live G effect: regular-spin **payout bonus** **15 / 20 / 30 / 40 / 50%**.
- A skip-guard still runs if refill is ever invoked; it does not apply in Vice Round or Free Spins.
- `L-G` has no combat-side area flag. World scatter only rolls family `G` from the basement.

---

## Family M — live cell counts


| ID    | Cells | Mult          | Destination                                                     |
| ----- | ----- | ------------- | --------------------------------------------------------------- |
| `C-M` | 1     | `x2`–`x2.5`   | winnings                                                        |
| `U-M` | 3     | `x2`–`x3`     | winnings                                                        |
| `R-M` | 3     | `x2`–`x3`     | split 60% winnings / 40% multiplier                             |
| `E-M` | 4     | `x2`–`x3`     | all_mult — full mark value to the multiplier |
| `L-M` | 4     | `x2.5`–`x3.5` | all_mult                                                        |


---

## Family F — live board-count

Line wins resolve first. Placeholder bonuses use `bonus_stake * total_bet * BASELINE_PAYOUT_SCALAR` (`0.431` in `combat_root.gd`), except where noted.


| ID    | Threshold | Live extra                               |
| ----- | --------- | ---------------------------------------- |
| `C-F` | 8+        | `0.25×` stake                            |
| `U-F` | 7+        | `0.50×` stake                            |
| `R-F` | 6+        | `0.75×` stake; once per cascade step     |
| `E-F` | 6+        | `0.75×` stake + one meter section        |
| `L-F` | 8+        | full resolver on leftover matching cells |


---

## Secret Mythic Rank (not shipped)

Optional hidden **Mythic** variant per extended family lane (**A, B, C, D, E, F, M, G, H**). Not in the 75-item pool. No `.tres` files.

## Area / Rarity Progression Plan

Live rule (implemented in `scripts/autoload/axel_world.gd`): every area starts
**Common**, including extended Commons. The first pickup in an area *clears*
it and freezes leftover items there. That area lifts the rank of every area
you have not taken from by one tier, once, and those items_indicators are rolled again
from the same seed at the new rank. Cap is Legendary, so taking from four
areas puts a still-untouched area at `L-*`. `1.2` has no floor item, so the
Halls pickup is the items_indicator in `2.4`.

The six written areas map onto the live rooms like this. `Families` are the
extended lanes each area rolls from. Each pickup also mixes in leftover
baseline lines from `item_lines.gd` (C1–C10 and their later rungs). The roll
tries the area's rank first, then walks down until a real `.tres` exists.


| Area            | Rooms                                    | Floor items | Families      |
| --------------- | ---------------------------------------- | ----------- | ------------- |
| Halls           | `1.2_Corridor`, `2.4_ClassroomsCorridor` | 0 + 1       | `F`, `H`, `M` |
| Cafeteria       | `2.1_Cafeteria`                          | 3           | `A`, `D`, `M` |
| Kitchen         | `2.3_Kitchen`                            | 2           | `B`, `E`, `H` |
| Teachers Lounge | `4.1_TeachersLounge`                     | 2           | `C`, `H`, `M` |
| Classroom       | `5.1_Classroom`                          | 2           | `D`, `E`, `A` |
| Basement        | `1.4_BasementDoor`                       | 1           | `G`, `B`, `F` |


`3.1_Backyard` is outdoors: no floor items, and no walking encounters, ever.
`1.1_SchoolExterior` and `1.2_Corridor` also never hold floor items, but they
do get walking encounters once the locker tutorial is done and some other room
has already hosted a fight — so `Halls` is cleared by 2.4's single item.
Details: `plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md`.

Every floor item shows the same items_indicator rather than its own
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
- Icon QA: [../../tools/qa/item_icons_check.gd](../../tools/qa/item_icons_check.gd) — **75 × 1024**, no `L-A`. Draw-size QA: [../../tools/qa/item_icon_draw_size_check.gd](../../tools/qa/item_icon_draw_size_check.gd) — combat slot **144px** / texture **120px**. The item wheel keeps the **1024** file. Locker shelves show lore, not combat icons.

## Still future

1. Mythic variants after a balance pass.
2. True Ending meta flags for `*-H` (items only give a goal head start today).

## Validation / Acceptance Checks

- **75** live entries: 31 baseline + 44 extended. `L-A` must stay absent.
- **"Add an item"** defaults to **five** rarities unless the user narrows scope.
- Every live id has `res://combat/art/item_icons/{id}.png` at **1024×1024**.
- Corner glyphs (`*-M`) are deterministic from seed.
- `*-G` must not break depletion-mode features if refill is ever turned on.

## Risks and Fallbacks

- **G + empty grid:** edge cases if refill returns — define lose-stuck or forced end-spin behavior then.
- **H stacking:** playtest and world fights use **additive** head-start percents (cap 50%).
- Resolver overrides (E/F families): keep scoped and logged. **Family F vs lines:** line wins resolve first; L-F board-count full-resolver clears leftover matching cells not already paid this cascade step.

## Playtest HUD (combat_test only)

Not player-final. Right-hand ITEMS list:

- Rebuilds from `combat/data/items/` at Play (FAMILIES + uniques). Rebind the live `ScrollContainer` children — do not trust scene-saved panel meta `Object()` copies. One scene: `combat_test.tscn`. F6 (no live encounter) shows the catalog picker. World fights load that same scene and **show** `NEW_Items`: locker tutorial is the empty DVD mill + red “Nothing but us chickens.” ticker; later fights are a read-only list of equipped icons. No checkboxes, no rank buttons, no catalog during a live fight.
- **Family rows** (C→E rank button, no Legendary on the slider): A Power Chain, B Premium Meter, C Vice Round, D Free Spins, E Diagonal, F Board-count, M Corner glyphs, G Sealed grid, H True-path, plus baseline lines (Paid spin payout, Normal payout, Power-symbol weight, Power chance, Cigarette, Alcohol, Bloody Hand, Extra wild). Legendary of a line is a unique row (`L2` Overclock is the A legendary unique; `L1` is the Extra-wild legendary unique; `L-B`…`L-H` unique).
- **Unique items** grouped by rarity (rainbow rarity text). Common-only leftovers stay here (`C3`, `C5`, `C9`, `C10`). Within a rarity group, sort by real item number (`C3` before `C10`, not string order). `L-A` is not listed.
- Header `ITEMS (n/max)` plus debug **Ignore slot cap** (off by default). Default cap 7, or 9 with Void Satchel.
- **GOAL:** Base Target + Progress live in **AxelCombatDevTools** (debug wrench menu), not the ITEMS panel. Effective = `round(base * (1 + lore bonus))`; H items add a head start instead. `%GoalLabel` stays as display. **Live world fights do not use the 10000 default** — `AxelRun` pushes the ladder rung (`100 / 150 / 225`, then ×1.5 per further fight rounded to 25) through `set_goal_base_target_cents()`, and H items pre-pay part of it. Act fights keep 10000.
- **Hover description:** runtime `ItemDescOverlay` (not saved in the `.tscn`). Own **CanvasLayer 107** (above WidgetLayer 106, below CRT 108) so it **can draw over** item rows. Solid black fill, whole card **90%** opacity, word wrap, 0.08s fade-in (text swap while open stays instant). Tries to sit under the cursor / below the row and clip to the ITEMS rectangle.

## Player-facing descriptions

- In-game text lives in `combat/data/items/*.tres` `description` (mirrored in `tools/combat/generate_item_resources.py`). The tables above are design rules, not player text.
- Plain words, one or two short sentences, real numbers from the params. Say what the player sees and gets.
- Never use item codes (`C-G`), or inside words: glyph, scalar, potency, premium meter, resolver, legal cell, seal, playtest Base target. Use: SKULL meter / SKULL step, strength, shapes, power symbols, MULTIPLIER, BET, GOAL, normal spins.
- Sealed-grid items (`*-G`): refill is never run in the live game, so they read as "Normal spins: wins pay X% more".

## Icons (live)

- Game path: `res://combat/art/item_icons/{id}.png` on `ItemDef.icon`.
- Size: **1024×1024** files. File gate: `tools/qa/item_icons_check.gd`. On-screen gate: `tools/qa/item_icon_draw_size_check.gd` (combat slot 144 / res 120). Locker shelves show lore, not combat icons.
- Draw size: combat ITEMS slot stays **144px** and uses a **120px** copy of the icon. The overworld item wheel uses the **1024×1024** file. Locker shelves show lore items, not these combat icons. Pause no longer draws item icons. Walk-near card stays 64px. Do not re-run the old 48×48 baker (`bake_item_icons.gd`) or `bake_item_icons_256.gd` — those sizes overwrite the 1024 set.
- Floor pickups never show this picture — shared items_indicator only. Name / description / icon appear on the walk-near card, the item wheel, and the playtest ITEMS list.
- All **75** live icons are detailed 8-band noir remaps. Stage originals in `tools/combat/ai_icon_src/{id}.png`. Skip `L-A`.
- Bake-time LimeZu map still lives in `tools/combat/item_icon_sources.json` (CLI folder args only — no machine-absolute paths in gameplay). Family A (C-A…E-A) must **not** reuse the L2 clock.

---

## Common-tier balance note (history — 2026-05-11)

C1 (Ash Spin Token) was classified **overpowered** by `item_balance_audit` (delta_rtp=+0.465). Values were cut from `per_paid_spin=0.10 / cap=0.60` to `per_paid_spin=0.06 / cap=0.36`. **That C1 cut shipped.**

A later note proposed a ~40% cut to **C2–C10** and the extended commons. **Those cuts did not ship.** A later pass rounded every chance and percent bonus up to the next multiple of 5. Live commons now match the main table (`C1` +0.10x / cap +0.40x, `C2` +10%, `C3` +10%, `C4` +5%, `C5` +10%, `C6`–`C8` +10%, `C9` +10%, `C10` 25% refund; `C-G` +15%, `C-H` +10%).
## Late-game nerf pass (2026-10-09)

A whole-run sim (`combat/test/difficulty_curve_sim.gd`) showed Rare+ loadouts paying back 150–2000% of the bet, so late fights could not be lost. Shipped:

- `U1` `+0.10x` / cap `+0.60x`; `R1` `+0.10x` / cap `+1.00x`; `E4` `+0.15x` / cap `+1.50x`.
- `R5` every 3rd wild; `R-E` major diagonal only (keeps wilds); `E-B` no wild extra; `L-F` threshold `8+`.
- Global caps in `ItemEffectDispatcher`: the summed paid-spin payout scalar is capped at `+2.0x` (`PAID_SPIN_SCALAR_TOTAL_CAP`), and all extra-wild items together add at most `+1` wild per created wild (`EXTRA_WILDS_PER_CREATE_CAP`).
- `L-E` is unchanged: full lines always spawn wilds, and the global wild cap applies.
