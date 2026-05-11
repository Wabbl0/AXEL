# AXEL Combat Starter Items Plan

**Single source of truth** for the combat item roster (baseline + extended mechanics). **All future edits go here only** — do not maintain a parallel catalog in `.cursor/plans/` (that path is a stub pointer). Keep aligned with [AXEL_combat_design.md](AXEL_combat_design.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).

## Design conventions (persistent)

- **Extended item ids** use **uppercase** tier letter + hyphen + **uppercase** family letter: `C-A`, `U-M`, `L-H`, etc. (Baseline ids stay **`C1`…`C10`**, **`R1`…`R6`**, **`E1`…`E4`**, **`L1`…`L2`** — digit suffixes vs letter codes.)
- **“Add an item” (new mechanic)** defaults to **five variants**, one per rarity (**Common → Legendary**), unless you explicitly ask for a single tier or subset. Same rule applies in future chats unless stated otherwise.

## Inferred Intent

A detailed item catalog (combat-use, map-gathered) for implementation chats. Includes **30 baseline** entries plus **extended** lines: families **A–F**, corner glyphs **M**, sealed-grid / no top refill **G**, and optional **True-path** passives **H** (nine letters × five rarities = **45** extended). **75 items total.**

## Canon Alignment Check

- Alignment target: [AI_DOCS.md](AI_DOCS.md) and [AXEL_combat_implementation.md](AXEL_combat_implementation.md).
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

### Common (19)

**Original**

- `C1 Ash Reroll Token`: each reroll adds `+0.10x` encounter payout scalar (cap `+0.60x`).
- `C2 Chalk Dust`: normal-symbol payout value `+10%`.
- `C3 Locker Map Pin`: normal-symbol spawn weight `+8%`.
- `C4 Static Spark`: random power activation chance `+5%`.
- `C5 Burn Mark`: if no power activates for 2 spins, next spin gets `+8%` random power chance.
- `C6 Cigarette Stub`: Storm-symbol payout value `+10%`.
- `C7 Broken Bottle Cap`: Star-symbol payout value `+10%`.
- `C8 Bloody Gauze`: Love-symbol payout value `+10%`.
- `C9 Dusty Battery`: first non-winning spin each encounter grants `+6%` power-symbol spawn for next spin.
- `C10 Tarnished Coin`: on first reroll each encounter, refund 25% reroll cost.

**Extended**

- `C-A` Echo Splinter (power chain): when any power activates, `20%` chance one other random power activates at `25%` potency.
- `C-B` Meter Scratch (premium meter): premium meter gain from premium lines `+1` on first qualifying line each spin.
- `C-C` Trinity Ash (Trinity Run): during Trinity Run, normal-symbol payout value `+15%`.
- `C-D` Super Teaser (SUPER Free Spins): when entering SUPER Free Spins, gain a small immediate payout burst (`+0.5x` stake).
- `C-E` Diagonal Chalk (diagonal wins): enables major-diagonal contiguous 3+ wins only.
- `C-F` Threshold Trace (board-count): if 8+ matching symbols are present on board after cascade, award a minor bonus win.
- `C-M` Chalk Mark (corner multipliers): roll **individual random multipliers** on random cells; show **top-left** on that symbol icon. When that cell pays in a resolved line, bonus goes **to that spin’s winnings only** (tune e.g. low `×2`–`×2.5` equivalent).
- `C-G` Locker Tape (sealed grid): **base-game regular spins only** — after line clears and gravity, **no new symbols spawn from the top**; empty cells stay empty until the spin chain ends / next full repopulate. **Encounter payout / line payout bonus** (tune e.g. `+12%` effective) to compensate. Does **not** override Trinity Run or SUPER Free Spins refill rules unless a later spec explicitly wires it.
- `C-H` Loose Thread (True-path passive): **optional passive** — at encounter start, increase the active encounter goal by **+8%**. Tracks toward **True Ending meta** (see **True-path passives** below).

### Uncommon (17)

**Original**

- `U1 Filtered Reroller`: each reroll adds `+0.15x` payout scalar (cap `+0.90x`).
- `U2 Iron Lighter`: normal-symbol payout value `+20%`.
- `U3 Weighted Trinity Die`: total power-symbol spawn weight `+10%`.
- `U4 Faulty Relay`: random power activation chance `+10%`.
- `U5 Split Wick`: when a wild is created, `25%` chance to spawn one extra wild in nearest valid empty cell.
- `U6 Storm Charm`: Storm symbol chance `+12%`; Storm power removes `+1` extra low-pay set at `20%` chance.
- `U7 Star Charm`: Star symbol chance `+12%`; Star power has `30%` chance to add `+1` extra wild.
- `U8 Love Charm`: Love symbol chance `+12%`; Love power transforms `+1` extra symbol at `25%` chance.

**Extended**

- `U-A` Echo Fuse (power chain): `35%` chance one other power activates at `35%` potency.
- `U-B` Meter Hook (premium meter): premium meter gains ×`1.25`.
- `U-C` Trinity Matchbook (Trinity Run): at Trinity Run start, gain `+1` starting spin.
- `U-D` Super Primer (SUPER Free Spins): SUPER Free Spins start with `+2` extra spins.
- `U-E` Diagonal Compass (diagonal wins): enables both major diagonals for 3+ contiguous wins.
- `U-F` Threshold Knot (board-count): threshold `7+`; bonus payout scalar increased.
- `U-M` Ink Tag (corner multipliers): same glyph UI as `C-M`; wider band / more tagged cells; winnings-only bonus (tune e.g. up to `×3` equivalent).
- `U-G` Rusted Hasp (sealed grid): same as `C-G` with stronger payout bonus (tune e.g. `+20%`); base game regular spins only unless spec’d.
- `U-H` Torn Label (True-path passive): optional passive — encounter goal **+12%**; True Ending meta.

### Rare (15)

**Original**

- `R1 Fractured Reel`: each reroll adds `+0.20x` payout scalar; first reroll per encounter is free.
- `R2 Gilded Commons`: all normal symbols gain `+35%` value and `+10%` spawn weight.
- `R3 Triune Sigil`: all power symbols gain `+15%` spawn weight and `+15%` payout value.
- `R4 Glitch Button`: random power activation chance is doubled; normal-symbol value `-8%` (risk/reward).
- `R5 Chain Wildseed`: every 2nd wild created in an encounter automatically creates a bonus wild.
- `R6 Trinity Echo`: when a random power triggers, `30%` chance to trigger a second random power at `50%` potency.

**Extended**

- `R-A` Echo Relay (power chain): whenever a power activates, one other power activates at `50%` potency.
- `R-B` Meter Coil (premium meter): x3/x4/x5 premium-line fills count as `+2/+3/+4` instead of base.
- `R-C` Trinity Syringe (Trinity Run): each Trinity Run spin that wins grants `+0.2x` temporary run scalar.
- `R-D` Super Injector (SUPER Free Spins): during SUPER Free Spins, each cascade adds `+1` extra payout step.
- `R-E` Diagonal Grid Lens (diagonal wins): diagonal wins can spawn wilds on exact-3 middle cells (same spawn rule).
- `R-F` Threshold Brand (board-count): threshold `6+`; can trigger once per cascade step.
- `R-M` Scratch Ticket (corner multipliers): on match, **split**: part to spin winnings, part as **one-shot bump** to active multiplier on **next cascade step** (tune e.g. 60% / 40%).
- `R-G` Basement Bar (sealed grid): stronger seal + payout trade (tune e.g. `+28%`); base game regular spins default.
- `R-H` Witness Slip (True-path passive): optional — encounter goal **+18%**; True Ending meta.

### Epic (13)

**Original**

- `E1 Ash Crown`: each power symbol (`Storm/Star/Love`) gets `+20%` spawn weight; associated power potency `+25%`.
- `E2 Null Gravity Pin`: on fully non-winning spin, `40%` chance to force one random power activation.
- `E3 Echo Loom`: first wild created each spin duplicates into nearest legal cell.
- `E4 Overflow Ledger`: each reroll adds `+0.30x` payout scalar; each reroll also grants `+2%` total power-symbol chance for that encounter.

**Extended**

- `E-A` Trinity Relay Spine (power chain): each power activation triggers both other powers at `50%` potency.
- `E-B` Meter Furnace (premium meter): premium meter fills on any winning premium line; `+1` extra if wild participates.
- `E-C` Trinity Halo (Trinity Run): during Trinity Run, first non-winning spin triggers guaranteed chosen power.
- `E-D` Super Engine (SUPER Free Spins): first win each SUPER spin duplicates 1 winning symbol into wild.
- `E-E` Diagonal Cruciform (diagonal wins): diagonal wins contribute to premium meter at `75%` normal contribution.
- `E-F` Threshold Tribunal (board-count): board-count wins can trigger premium meter gain at reduced rate.
- `E-M` CRT Etching (corner multipliers): majority of glyph value feeds **active multiplier** for rest of spin chain; minority flat spin payout; test vs multiplier controller order.
- `E-G` Mason Lock (sealed grid): large payout trade (tune e.g. `+38%`); base game regular spins default; clarify interaction with forced repopulate hooks.
- `E-H` Confession Card (True-path passive): optional — encounter goal **+25%**; True Ending meta.

### Legendary (11)

**Original**

- `L1 Twin Pentagram` (late-game): whenever a wild is created, create one additional wild (legendary-only pool).
- `L2 Trinity Overclock`: **each power activation activates all other powers afterward** at full potency (once-per-spin cap).

**Extended**

- `L-A` Trinity Overclock (power chain): same rule as `L2` — **full chain** after each activation. *One implementation, two ids unless merged.*
- `L-B` Meter Blood Moon (premium meter): first premium win each spin fully fills one meter section; can overflow.
- `L-C` Trinity Crucible (Trinity Run): during Trinity Run, every spin applies chosen power + one extra random power at `60%` potency.
- `L-D` Super Catastrophe (SUPER Free Spins): during SUPER Free Spins, each power activation chains one extra random power at `75%` potency.
- `L-E` Diagonal Covenant (diagonal wins): diagonal wins treated as full standard line wins.
- `L-F` Threshold Dominion (board-count): board-count wins become full resolver wins (strict priority order vs line wins).
- `L-M` Red Glyph (corner multipliers): glyph value **immediately** to active total multiplier for the spin; late pool; high volatility.
- `L-G` Iron Lung (sealed grid): maximum seal + payout trade (tune e.g. `+50%`+); base game regular spins; **area-gated**.
- `L-H` True Name Tag (True-path passive): optional — encounter goal **+35%** (tune); strongest True Ending unlock weight. **True Ending** (design default): requires **meta credit** for this line — e.g. **equip `L-H` for the final qualifying encounter** and satisfy other narrative gates, or **own all five `*-H` pieces** in meta; choose one in implementation and document in `AXEL_combat_design.md`.

---

## True-path passives (`*-H`) — summary

- **Passive / optional:** player can skip them; skipping avoids goal inflation but **blocks or delays True Ending** unless another canon route is added later.
- **Effect:** increases **current encounter goal** by a **fixed percent** at encounter start (values above are starting tuning).
- **True Ending:** these items are the **mechanical hook** for the “hard honesty / lucid” route aligned with [AXEL_combat_design.md](AXEL_combat_design.md) abstinence/lucid themes — exact gate (single legendary vs full set) is a **design choice** to lock when wiring endings.

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
- Grid / spawn: [../combat/scripts/grid_manager.gd](../combat/scripts/grid_manager.gd) — **family G** must flag “no top refill” per spin phase.
- Goals: `goal_tracker.gd` / encounter def — **family H** adjusts goal threshold at encounter start; meta flags for True Ending in run/narrative state.
- Meta / endings: narrative flags (prototype layer or run singleton) for `*-H` progress.

## Ordered Execution Strategy For Future Chats

1. Baseline `C*` / `U*` / `R*` / `E*` / `L*` items + hooks.
2. Extended **A–F**, **M** lines; dedupe **`L2`** and **`L-A`**.
3. **G** line: refill suppression + payout scalar; mode checks (base vs Trinity Run vs SUPER).
4. **H** line: goal % modifier + meta True Ending flags.
5. Mythic variants after balance pass.

## Validation / Acceptance Checks

- **75** entries: 30 baseline + 45 extended (`C-A`… style).
- **“Add an item”** defaults to **five** rarities unless user narrows scope.
- Corner glyphs (`*-M`) deterministic from seed; `*-G` never breaks depletion-mode features accidentally.
- True-path `*-H` documented for ending team.

## Risks and Fallbacks

- **G + empty grid:** edge cases when board cannot refill — define lose-stuck or forced end-spin behavior in implementation.
- **H stacking:** if multiple `*-H` equipped, clarify additive vs multiplicative goal % — recommend **additive stacking with cap** or **highest only**.
- Resolver overrides (E/F families): keep scoped and logged.
