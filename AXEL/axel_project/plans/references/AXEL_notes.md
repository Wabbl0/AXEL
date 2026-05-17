# AXEL — Game Design Notes

> Compiled from design conversation. Single source of truth for the roguelite encounter, economy, and progression layer.
> Companion docs: `../combat/AXEL_combat_design.md`, `../combat/AXEL_combat_implementation.md`, `../scenes/AXEL_SCENES_BLUEPRINT.md`, `AXEL_SCENE_DIALOGUES.md`, `README_STRUCTURE.md`.

---

## 1. Game Overview

AXEL is a top-down 2D psychological horror. The player controls a protagonist returning to an abandoned school where they abandoned a friend (Axel) who later died. The game has two interlocking phases:

- **Exploration phase** — hub-and-spoke school navigation, dialogue scenes, collecting items and memories.
- **Combat phase** — triggered by exploration actions. A reskinned Moon Princess 100 slot system. Target ratio: **60%+ of playtime should be combat.**

Combat is framed narratively as a dream/memory/intrusion space the protagonist falls into when overwhelmed by guilt and rot.

---

## 2. Areas

### 2.1 Structure

- The school is divided into **6 areas**.
- Each area has its own **seed-locked item pool of approximately 10 items**.
- Per run, **1–3 active items** are randomly drawn from that pool and physically placed inside the area.
- **Passive items** are always present in their designated area; per-seed their location varies across the 6 areas, but they are always findable somewhere on every seed. Mid-run events do not move them. Passive items are not part of the 1–3 active item draw.
- Players can visit areas early to preview which items are there. Items keep the same identity across the run — only their rarity/effect scales.
- The player is **not told** how many items exist inside each area.

### 2.2 Area-specific item themes

Each area's items share a mechanical theme tied to the room's narrative identity. Examples:

- **Cafeteria** — items that increase the chance of specific symbols appearing on the grid.
- **Teachers' Lounge** — items affecting multiplier, payout requirements, or bet amount.
- Other areas (Backyard, Classroom, Basement, Corridor/Locker hub) — themes TBD, each distinct.

### 2.3 Rarity tiers

Tiers, ascending: **Common → Uncommon → Rare → Epic** (exact names placeholder).

Rules:

- All items in a starting run begin at **Common**.
- The moment a player picks up **at least 1 active item from an area** (mid-clear counts), all items in **not-yet-entered or not-yet-cleared areas** upgrade by one rarity tier. Visible if the player has previously previewed those areas.
- When an area is **fully cleared** (all 1–3 active items collected), the same upgrade triggers — areas already upgraded once now upgrade again.
- Passive items also upgrade in rarity as other areas are cleared.
- The mechanic is not explained to the player — it is discovered through play.
- A player **cannot stack 6 Rare items simultaneously**. Realistic ceiling is roughly 3 same-rarity items from larger areas, with the next area's items at Epic.

### 2.4 Difficulty scaling

- Each area cleared raises the **base difficulty** of all subsequent encounters in the run. The player feels this directly in payout requirements and symbol weighting (handled in `../combat/AXEL_combat_design.md` §5).
- This means there is no "skipping" difficulty by avoiding items — clearing areas is the difficulty driver, not item count alone.
- The player can choose to skip individual items inside an area to enter encounters underequipped. This makes the run "much harder but not impossible" — explicitly **not the intended path**.

### 2.5 Re-entering areas

- Areas can be re-entered freely.
- Re-entering does not change which items spawn — items are seed-locked from the start of the run.
- **Exception:** items sold to The Hole return to the area pool and may reappear on later visits to other areas.
- Walking back into a previously-cleared area to retrieve a missed passive item is allowed but carries the small step-encounter risk (§5.3).

---

## 3. Combat Triggers

Combat phase is triggered by specific actions in exploration. There is no fixed "encounter meter" exposed to the player; instead, encounters fire on discrete events plus a low passive step-chance.

### 3.1 Guaranteed triggers

- **Picking up an item** — every active item pickup triggers an encounter immediately. The newly picked-up item **can be used in that encounter**.
- **Picking up a passive item** — also triggers an encounter on pickup (passive item is equipped going into the fight).

### 3.2 Step-based random encounters

- Each step has a small chance to trigger an encounter.
- Starting chance: **0.1% per step**.
- Endgame chance: **~1% per step** (after most areas cleared).
- Curve shape: scales upward as areas are cleared. Whether the increase is smooth or stepped per area-clear is open (see Question 1 below).
- Step-based encounters use the **same encounter pool** as item-pickup encounters (no separate "ambush" type) unless later design proves otherwise (Question 2).

### 3.3 Farming protection

- Step-encounter chance has a soft cap; players cannot grind encounters past a certain point in the run.
- Exact cap rule TBD (Question 3) — based either on total encounters fired, total steps taken, or a combined cooldown.

### 3.4 Memory pickup

- Memories **do not trigger combat encounters**. Picking them up is free of immediate cost.
- Memories instead carry a permanent payout-requirement penalty (§7.1).

---

## 4. Items

### 4.1 Active items

- Up to **6 active items** can be held in the locker at a time.
- Active items modify combat at one or more of the hook points listed in `../combat/AXEL_combat_design.md` §6 (encounter start, spin start, cluster resolve, princess power, encounter end).
- Active items can be sold in The Hole.

### 4.2 Passive items

- **Always labeled "passive"** in the item description so players can identify them on sight.
- **Cannot be sold.**
- **Do not count toward the 6-item locker limit.**
- **Do not count toward the 1–3 per-area pool draw.**
- Always present in the run; their location across the 6 areas varies per seed.
- Required for the True Ending (§9.1).
- Offer small passive bonuses but their main role is **story progression and True Ending eligibility**.

### 4.3 Locker overflow handling

- If the player picks up a 7th active item with a full locker:
  - The player is offered a **swap**: exchange an existing item for the new one.
  - On swap, the player gains **the sell value of the higher-rarity item** of the two as currency.
- Overflow forces a Hole visit (§6.2).

### 4.4 Item reappearance

- Sold items return to their original area's pool and may reappear in later areas via the random 1–3 draw.

### 4.5 Item example: reroll-multiplier

A specific passive item: while equipped, every reroll ticket currently held in inventory grants **+0.1× to the spin multiplier**. This makes hoarding tickets a viable build axis (instead of always spending them).

---

## 5. Currency (Bet / Smokes)

### 5.1 Default starting amount

- Every run starts the player with **10 currency** (default starting bet).
- Only **winnings carry over** between encounters and areas. There is no carry-over of base currency.

### 5.2 Spin / bet behavior

- Bet is a fixed amount per spin in the encounter (constant within an encounter).
- Items modify spin behavior — variety comes from items, not from manual bet adjustment mid-encounter.
- Possible bet amounts per encounter: **0.1, 0.4, 1, 5** (and the default 10). Player chooses ante before the encounter starts.
- Items can affect bet, payout, spin amount, and other parameters depending on the item.

### 5.3 Losing currency

- Reaching 0 currency in an encounter = loss.
- On loss: **full restart of the current run**, Slay the Spire style.
- **Story progress (memories collected, dialogue seen) is preserved** across restarts so the player doesn't re-read dialogue.
- All encounters reset, all items reset, all area-clears reset. Everything mechanical starts from scratch.
- After one loss, the **True Ending becomes locked for that save file** (§9.1).

### 5.4 50/50 gamble

- Voluntary at any safe moment (between encounters, in The Hole, etc. — exact location TBD, Question 4).
- **Double-or-nothing** on surplus winnings only.
- Repeatable — the player can chain 50/50s as many times as they want.
- **Loses only the surplus on a fail.** A failed 50/50 returns the player to exactly **10 currency** (default base, never below).
- Worked example: player has 10 base + 40 surplus = 50 total. Wins 50/50 → 10 base + 80 surplus = 90 total. Wins again → 10 + 160 = 170. Loses next 50/50 → drops to 10. The full surplus is wiped, base is preserved.

### 5.5 Spending overflow winnings

Surplus currency above 10 can be spent on:

- **Raising default starting bet** (e.g., 10 → 20). **Does not survive restarts.** Resets to 10 on death.
- **Reroll tickets** (§6.4).
- Other shop purchases (§6).
- Saved for higher antes in later encounters.

Pricing for these upgrades should be calculated against the system's RTP (§8).

---

## 6. The Hole (Shop)

### 6.1 Identity

"The Hole" is the shop scene. It is the only place where the player can sell items, buy reroll tickets, and use overflow winnings on upgrades.

### 6.2 When The Hole is available

- **Forced** when the player picks up a 7th item with a full locker (overflow).
- **Optional** anytime the player is at the locker hub.

### 6.3 What The Hole sells / does

- **Buys back unwanted items** from the player (sell value scales with rarity).
- **Sells reroll tickets** (currency-priced, see Question 4 about pricing vs RTP).
- **Sells default-bet upgrades** (10 → 20, etc., resets on death).
- **Does not affect the combat encounter chance.** Visiting The Hole is not a safety valve to reset step-encounter risk.

### 6.4 Reroll tickets

- Granted: **1 ticket per area** the player progresses through.
- **Carry over across areas** — a ticket can be saved for a later area.
- Used to **reroll the active 1–3 item draw inside a specific area**, hunting for synergy items in that area's pool of ~10.
- Currency and reroll tickets are **separate, non-interchangeable** resources. The player cannot convert currency to tickets at any 1:1 ratio — they're bought as a discrete shop product, not a currency conversion.
- Some items (passive or active) can convert held reroll tickets into combat bonuses (e.g., the +0.1× multiplier passive in §4.5). Tickets converted this way are **not consumed permanently** — they remain in inventory and continue providing the bonus until spent normally on a reroll.

---

## 7. Memories

### 7.1 Mechanical effect

- Each memory collected raises the **payout requirement of all subsequent encounters by approximately 5%**.
- Effect is **forward-only** — a memory picked up does not retroactively raise the difficulty of an encounter the player is currently inside (encounters are atomic; memories cannot be picked up during one).
- Memories are required for the True Ending (§9.1), so the player must accept this difficulty curse to qualify.

### 7.2 Communication

- Memories are **clearly visible** in their areas as collectibles.
- A **vague tutorial hint** plays the first time a memory is collected and on **every subsequent memory pickup**, in language like *"the memory of guilt weighs you down."*
- The exact 5% number is never shown to the player.

### 7.3 No combat trigger

- Memory pickup does **not** trigger an encounter. Pickup is the only "free" exploration action in the late game.

---

## 8. RTP & Economy Tuning

### 8.1 RTP target

- **Intentionally well below average online slot RTP** (real online slots are typically 95–97%; AXEL combat should sit lower — exact number TBD, Question 5).
- Reasoning: items are the intended winning strategy. Bare runs (no items) are designed to be **almost impossible** but not strictly impossible.
- Without items, base spin economics will bleed the player out within a few encounters.

### 8.2 What this implies for shop pricing

- Reroll tickets, default-bet upgrades, and any other purchasable advantage must be priced against the low RTP so that:
  - A player who plays well and collects items can earn enough surplus to afford meaningful upgrades.
  - A player who plays without items cannot reach significant surplus.
- Concrete numbers (cost of raising default bet 10→20, cost of one reroll ticket) are not yet set — must come from RTP simulation.

### 8.3 No mercy mechanic

- No floor on losing streaks. No guaranteed cascade after dry spins. No minimum payout safety net.
- A full wipeout (run → 0 currency → restart) is always on the table.
- This is **the central tension of the game** — it justifies the value of items and the importance of synergy hunting.

---

## 9. Endings

### 9.1 True Ending requirements

All three required, no exceptions:

1. **No deaths in the current run.** A single full-currency wipeout permanently locks True Ending for that save.
2. **All memories collected** (raising final-encounter payout requirement substantially — see Question 6).
3. **All correct passive items found and equipped** at the final encounter. The "correct" passive items are always findable in any seed (their location varies per seed but they always exist somewhere across the 6 areas).

### 9.2 Not guaranteed per seed

- Even meeting the three conditions above, the True Ending is **not guaranteed.**
- Combat RNG during the final encounter must also resolve favorably.
- This is **intentional design** — the True Ending is meant to feel earned, including by luck.

### 9.3 Other endings

- The five existing endings from the prototype (`../scenes/AXEL_SCENES_BLUEPRINT.md`) remain. Their integration with the loss/restart system is open (Question 7).

---

## 10. Run Loop Summary

A typical run plays out as:

1. Player starts at the **locker hub** with **10 currency** and **0 reroll tickets**.
2. Player chooses an area to enter. Each area contains 1–3 active items, possibly a passive item, and possibly memories.
3. Player navigates the area's exploration scenes (existing dialogue/scene system from the prototype).
4. Player picks up items → each pickup triggers a combat encounter immediately, with the new item available.
5. Player may pick up memories freely (no encounter), accepting the +5% payout penalty for future encounters.
6. Random step-encounters fire at low chance, scaling with areas cleared.
7. After each encounter, surplus currency carries over. Reroll tickets earned. Optional 50/50 available.
8. Returning to the locker hub gives access to The Hole (shop).
9. Clearing an area upgrades remaining areas' item rarities and raises base difficulty.
10. Player progresses through all 6 areas. Final encounter occurs in the final area (likely Basement, per existing scene structure).
11. Final encounter outcome + collected memories + equipped passives + no-death status determines ending.
12. On any full-currency loss: run restarts. Story is preserved. True Ending is locked for that save.

---

## 11. Open Questions

These questions have not yet been answered and are required before full implementation. Numbered for direct reference.

1. **Step-encounter chance curve shape.** The chance increases from 0.1% to ~1% per step as areas are cleared. Is this a smooth curve (interpolated each step), or does it jump in discrete tiers per area cleared (e.g., area 1 cleared = 0.25%, area 2 = 0.4%, etc.)? Affects implementation directly.
2. **Step-encounter pool identity.** Are step-triggered encounters drawn from the same pool as item-triggered encounters, or is there a separate "ambush" type with different rules (shorter duration, different rewards, weaker enemies)? If the same pool, no extra design needed. If separate, ambush encounters need their own definition.
3. **Step-encounter farming cap.** The chance is capped past a certain point so players can't grind encounters. Is the cap based on:
  - Total encounters fired in the run?
  - Total steps taken since the last encounter?
  - A flat cooldown timer after each encounter?
  - Combination?
4. **The reroll-ticket multiplier interaction (item from §4.5).** When a player spends a ticket mid-run for a reroll, the multiplier bonus drops by 0.1× immediately. Is this loss permanent for the ongoing encounter, or does picking up another ticket later restore the bonus? Also: does the ticket count check happen at encounter start (snapshot) or every spin (live)?
5. **RTP target number.** "Much lower than average net casino slots" needs a concrete percentage to target during economy simulation. Suggested starting range: **75–85%**, but needs decision before tuning shop prices.
6. **Total memory penalty across all 6 areas.** With ~5% payout requirement increase per memory and an unknown total memory count across the 6 areas, what is the ceiling? Has it been stress-tested whether a fully synergized item build can clear the final encounter at maximum penalty, or is the final fight intentionally out of reach without ideal RNG on top of items?
7. **Persistent stat upgrades (future feature).** A future idea was floated: stat upgrades that persist between runs based on high single-run scores. This must be designed carefully because it interacts with:
  - The True Ending's no-death requirement (could let players "buy" their way past difficulty).
  - The intentionally low RTP (persistent upgrades risk inflating the economy).
  - The Slay the Spire-style full restart.
   When this feature is implemented, it should not undermine the core run-restart loop or trivialize True Ending requirements.
8. **Existing endings integration.** The five existing endings from `../scenes/AXEL_SCENES_BLUEPRINT.md` (Fear, Darkness, Wrong Answer, No Name, True) need explicit mapping to the new combat-loss / area-clear / memory-count system. For example: does losing a run still let you reach Ending 1 (Fear)? Or does the loss-restart loop replace the fear-based ending entirely? This needs reconciliation between exploration outcomes and combat outcomes.

---

## 12. Combat Symbol Asset Policy

Combat symbol rendering now uses a dual-texture policy for performance and clarity:

- **Grid symbol texture (`SymbolDef.texture`)** must point to `res://combat/art/grid_symbols/*.png` and is imported with `process/size_limit=128`.
- **Power intro texture (`SymbolDef.power_intro_texture`)** must point to the high-resolution source in `res://combat/art/placeholders/*.png` (720 assets).
- `CombatRoot` power-intro FX must resolve textures via `SymbolDef.texture_for_power_intro()`, so activation moments keep high-definition visuals while normal grid play stays lightweight.
- Flat background art direction is preserved. No transparency-only pipeline is required for these symbols.

When adding or replacing symbols, always provide both texture paths so grid memory use remains capped and power activations stay crisp.

---

## 13. Terminology Lock (Free Spins vs SUPER Free Spins)

To avoid future confusion in chats, reviews, and implementation notes, use these exact terms:

- **Regular Free Spins** = **Trinity Run** (the sequence immediately after the premium meter fills).
- **SUPER Free Spins** = the later bonus feature previously referred to in code/docs as Free Spins.

Gameplay rules tied to those names:

- During **Regular Free Spins (Trinity Run)**, there should be **no cascading symbols** (no new symbol drops/refill behavior).
- During **SUPER Free Spins**, there should be **no cascading symbols** (no new symbol drops BUT new grid after no more matches are done)

If any doc or task says only "Free Spins" without qualifier, treat it as ambiguous and restate which mode is intended before implementation.