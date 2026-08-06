# AXEL — Combat System Design

Design recap for the combat layer. Captures the narrative framing, the chosen mechanical base (a reskinned Moon Princess 100), the symbol map, encounter design, and the roguelite item layer. Paired with `AXEL_combat_implementation.md` for the code-facing plan.

---

## 1. Game context

- **AXEL** is a top-down 2D psychological horror about a grown-up returning to the rotting school where they abandoned a friend.
- Story-driven but non-linear — player choice shapes one of five endings.
- Aesthetic: strict black + two reds (`--blood-red #ff0000`, `--dark-blood #4a0000`), CRT scanlines, VT323 / Space Mono type, glitch and shake FX.
- Core exploration loop: hub-and-spoke school, recover 5 memory fragments, collect intangible items (Flashlight, Key, Shovel, *Name*), speak the name over the grave.
- Recurring motifs: lighter with "AXEL" scratched on it, cigarettes as a shared ritual / hint mechanic, the basement as literal + emotional burial, the locker as sanctuary/hub.
- Open question the prototype leaves unanswered: **where does combat live?** This document is the answer.

---

## 2. The direction chosen

Combat is a **slot-machine encounter layer** — a dream/memory/intrusion space the protagonist falls into when overwhelmed by rot and guilt. It is roguelite, run-based, and gambling-coded. The mechanical skeleton is lifted from Play'n GO's *Moon Princess 100* and reskinned around a theme of **self-harm, guilt, and remembering**.

Why this fits AXEL:
- Cascading clusters + a rising multiplier is "one memory unlocks the next." A good spin chains into a flashback.
- The three rotating princesses map cleanly onto AXEL's three premium power symbols through a fixed alias map.
- "Clear the grid" as a meta-goal = "fully remember" as a meta-goal.
- Slot machines as a horror object tie into the gambling system you want — the loop is seductive by design.

Related ideas from the earlier brainstorm that this absorbs pieces of:
- **Idea 6 — Basement Reels:** literal slot-machine exorcism in the dream layer.
- **Idea 3 — Dice of Memory:** symbols behave like committed memory fragments.
- **Idea 4 — Locker Deal (Balatro Jokers):** roguelite items as equipped modifiers.

---

## 3. Moon Princess 100 — base mechanics (reference)

Kept verbatim as the mechanical spine so we know what we're reskinning.

- **Grid:** 5 columns × 5 rows.
- **Win rule:** line pays — 3+ matching symbols connected horizontally or vertically in a single row/column, with no gaps. A symbol may contribute to one horizontal and one vertical win at the same time.
- **Cascade:** winning symbols are removed and remaining symbols fall (gravity-only). No new symbols spawn from the top during a spin round (normal, Trinity, or Free Spins).
- **Wild drop:** when a winning line of exactly 3 symbols resolves, a **wild** appears in the middle cell of that line. 4-symbol and 5-symbol wins do not create a wild.
- **Multiplier:** starts at x1 and increases by +1 for each new drop (each cascade step). During Free Spins, the multiplier can grow up to **100×**.
- **Three princesses (rotating):** exactly one princess is active on-screen. Girl Power triggers at random on non-winning spins. The active princess changes only after a Girl Power activation, in fixed order **Love → Star → Storm**. The opening active princess is random.
  - **Love:** converts one set of symbols into another symbol type.
  - **Star:** adds 1–2 wilds with intelligent placement.
  - **Storm:** removes two sets of symbols from the grid.
- **Trinity meter:** princess-symbol wins fill a 3-section meter (x3 fills 1 section, x4 fills 2 sections, x5 fills 3 sections). Wilds can contribute to princess wins. When the meter is full and no further wins are achieved, a Trinity round starts: meter-full transition, then a **fresh 5×5 grid**, then multiplier resets and Love/Star/Storm Girl Powers are performed in fixed order on non-winning drops.
- **Clear the Grid:** fully emptying the grid pays `50 × total bet × active multiplier` (except during Trinity, where grid clear triggers Free Spins instead of paying the instant prize).
- **Free Spins (Super Free Spins):** triggered by clearing the grid during Trinity (non-wild symbols gone). Player chooses Love (4 spins), Star (5), or Storm (8), then receives a **fresh 5×5 grid** before the first Super Free Spin round. Chosen Girl Power triggers on every non-winning spin. Each subsequent Super Free Spin continues from the depleted entry grid (no per-spin repopulate). Winning symbols are removed and gravity collapses remaining symbols, but no new symbols are spawned from the top (depletion mode). The progression target is to clear all non-wild symbols from the grid; wild-only leftovers still count as cleared for this purpose. Trinity cannot retrigger. Meter fills grant extra spins (Love +4, Star +3, Storm +2), up to 100 total.
- **RTP:** 94.20%, high volatility. **Max win:** 15,000× stake.

Source references are listed at the bottom of this doc.

---

## 4. AXEL reskin — symbol map

All symbols are placeholder art for now (red-on-black, respects the existing palette).

### Low-paying symbols (the four "suit" symbols)

| Role in MP100 | AXEL placeholder | Eventual art intent |
|---|---|---|
| Green gem / circle | **Green circle** | TBD (some mundane object — pill? button? pebble?) |
| Bell | **Yellow triangle** | TBD (warning sign? tooth?) |
| Star | **Blue star** | TBD (badge? pin?) |
| Heart | **Red heart** | TBD (literal heart? locket?) |

### Premium symbols (Princess Power aliases)

Power-symbol alias map used across this project:
- `cigarette` means **Storm**
- `alcohol` means **Star** (prefer this name; older code may still use id `booze`)
- `bloody hand` means **Love**

| MP100 princess | AXEL premium | Power role |
|---|---|---|
| **Storm (green)** | **Cigarette** | Removes two low-pay symbol types from the grid — "burning away noise." |
| **Star (blue)** | **Alcohol bottle (XXX label)** | Adds 1–2 wilds with intelligent placement — "drowning it out." |
| **Love (red)** | **Bloody hand** | Transforms a random symbol into another type — "rewriting the memory." |

### Wild

| MP100 wild | AXEL wild |
|---|---|
| Moon | **Satanic symbol (red)** — placeholder |

Princess-symbol wins (including AXEL alias symbols cigarette/booze/bloody hand) are the only wins that feed the Trinity meter; low-pay suit symbols do not charge it.

### MP100 paytable snapshot (from provided info screens)

| Symbol group | X5 | X4 | X3 |
|---|---:|---:|---:|
| Princess (Love / Star / Storm) | 16.00 | 1.60 | 0.48 |
| Any princess (mixed princess line) | 8.00 | 0.80 | 0.32 |
| Bell / Heart | 4.80 | 0.48 | 0.24 |
| Star / Green coin | 3.20 | 0.32 | 0.16 |
| Wild | 80.00 | 3.20 | 1.60 |

Reading the combat language: the three premium symbols are simply the visual aliases for the same Princess Power trio (Storm/Star/Love). The wild remains the high-impact catalyst symbol.

---

## 5. Encounter design — varied goals, escalating difficulty

A run is a sequence of encounters. Each encounter has **one goal**, a **spin budget** (or a soft budget in the form of resources), and a **difficulty tier**. Failing the goal before the budget runs out ends the run.

### Goal types (mix and match across encounters)

1. **Payout threshold** — reach `X ×` total payout within N spins. (Straight MP100 scoring.)
2. **Wild count** — place `X` wilds on the grid during the encounter.
3. **Row/column pay** — form at least one winning line that spans a full 5-row or 5-column line.
4. **Grid clear** — fully clear the grid at least once within N spins.
5. **Multiplier ceiling** — reach a spin multiplier of at least `X`.
6. **Symbol purge** — clear every instance of a specific low-pay symbol from the grid.
7. **Trinity** — trigger a real Trinity round (meter fills, then Love/Star/Storm sequence) at least once in a single encounter.
8. **Free Spins trigger** — clear the grid during Trinity to enter Free Spins at least once.
9. **Abstinence** — reach payout `X ×` *without* any princess power triggering. (Thematically: remember without crutches.)
10. **Burn a memory** — force-destroy a specific pre-placed "memory symbol" on the grid (these are intro-ed later in the run).

### Difficulty scaling axes

- **Thresholds rise** — payout targets, wild counts, multiplier ceilings scale up per tier.
- **Budget tightens** — fewer spins allowed per encounter deeper in the run.
- **Symbol weight shifts** — low-pays replace premiums on the drop table in harder encounters, making clusters harder to stumble into.
- **Princess cooldowns** — deeper encounters add a cooldown where a princess can skip her turn in the rotation, punishing reliance on powers.
- **Corruption** — inert "scar" cells that block grid positions; appear in late encounters and can only be cleared by a wild dropping on top.

### Suggested run shape (first pass)

- **Act I — The Locker (easy, 3 encounters):** Payout targets, one wild-count goal. Teaches the loop.
- **Act II — The Halls (medium, 4 encounters):** Adds symbol-purge, multiplier ceiling, one Trinity encounter. Introduces the Corruption hazard.
- **Act III — The Basement (hard, 3 encounters + 1 boss):** Abstinence encounter, burn-a-memory encounter, final encounter is a multi-goal fight against a manifestation of Axel / the rot.

### Betting / gambling layer

Before each encounter, the player picks a **stake** in the run's currency (provisional: cigarettes, or "smokes"). Higher stake raises the payout and item drop quality, also raises the goal threshold by a set %. Between encounters, players may enter a **shop / dare room** where they can bet smokes for a chance at a rare item. Cowork-able later.

---

## 6. Roguelite item layer

Items are passive modifiers (think Slay the Spire relics / Balatro jokers), collected between encounters from drops, shops, and hidden overworld pickups. They hook into specific points in the spin lifecycle.

### Hook points (where items can modify behavior)

- **On encounter start** — pre-place symbols, grant free spins, seed wilds.
- **On spin start** — modify drop weights, reveal upcoming symbols, force active princess.
- **On cluster resolve** — modify multiplier gain, duplicate wilds, trigger extra cascades.
- **On princess power** — amplify, suppress, or swap the effect.
- **On encounter end** — rebate stake, convert leftover grid state to currency, carry-over multiplier.

### Sample item list (first pass — all renamable)

| Item | Hook | Effect |
|---|---|---|
| **Half-smoked cigarette** | On encounter start | Start with 1 wild pre-placed at a random center. |
| **Empty bottle** | On princess power (Star) | Star adds +1 extra wild. |
| **Nicotine patch** | On encounter start | First spin auto-purges the two lowest-pay symbol types. |
| **Shaky hands** | On cluster resolve | Every multiplier gain is +2 instead of +1, but Love has a 25% chance to misfire (no effect). |
| **Torn photo** | On encounter end | If you cleared the grid at least once, reveal a memory fragment in the overworld. |
| **Lighter ("AXEL")** | On spin start | Once per encounter: reroll the current grid. (Diegetic — the prototype's hint lighter.) |
| **Rotted notebook** | On spin start | Preview the next 3 symbols in the drop queue. |
| **Dog tag** | On cluster resolve | Low-pay symbols adjacent to a wild count toward that wild's cluster. |
| **Loose tooth** | On spin start | Replace all yellow triangles with wilds for one spin, then lose this item. |
| **Funeral suit** | On encounter start | In Abstinence goals, princess rotation is paused one extra turn. |
| **Basement key (chipped)** | Permanent | Unlocks an additional shop slot. |
| **Shovel (replica)** | On encounter end | Convert 1 leftover symbol on the grid to currency. |

Items should be **theme-coded**, not just mechanically driven: each one tied to a real object in the school or the protagonist's pocket.

---

## 7. Thematic ties — keep these honest

- The three premium symbols (cigarette, bottle/alcohol, bloody hand) are visual aliases for Storm/Star/Love and should be communicated as equivalent power channels in UI and tuning docs.
- Every time a princess power triggers and *helps* the player, something in the overworld should subtly worsen — more mold on a wall, a flickering bulb, a new stain. This makes the combat-exploration loop bidirectional: combat rewards come at exploration cost.
- **Winning loudly is suspicious.** Big payouts should trigger glitch/shake FX not as celebration but as intrusion. Consider a "you went too far" flag when the player hits max multiplier too early in an encounter — it unlocks harder variants for the rest of the run.
- **Grid clear = clarity.** The one "clean" feeling in the combat layer should be reserved for full grid clears, where the screen briefly goes still and quiet before the next spin. This is the mechanical equivalent of a recovered memory.
- **Abstinence goals are the route toward the True Ending.** Encounters won without any princess power triggering accrue a hidden "lucid" counter, and a high lucid counter gates later overworld scenes.

---

## 8. Currency & economy (first pass)

- **Smokes** — soft currency, main in-run spend. Used for stakes, shop purchases, and some item activations.
- **Memory fragments** — meta-currency, earned through grid clears and True-path encounters. Persists across runs; spent on unlocks in the overworld meta-layer.
- **Rot** — negative counter, accrued from losing encounters or taking princess-power help in Abstinence goals. High Rot locks the True Ending and gates the *Convicted* / *Hell* endings.

---

## 9. Open decisions

- Does combat share the overworld camera or cut to a full-screen slot layer? (Recommendation: full-screen layer, but framed by the locker door opening — diegetic transition.)
- Do the 5 endings from the prototype map to numeric thresholds (Rot vs. Lucid vs. Memory Fragments), or to specific encounter choices? (Recommendation: thresholds, with one hard gate: must have the Name item.)
- Is "betting the stake" opt-in each encounter, or is every encounter a required ante? (Recommendation: required ante, but the default ante is 0 — the seduction is spending above 0.)
- Does the player see only the active princess, or reveal upcoming order too? (Recommendation: show only the active princess to match MP100. If needed, add an item later that reveals next princess as a modifier.)
- Do items persist between runs? (Recommendation: a small subset as "carry-in" unlocks tied to memory fragments; most reset each run.)

---

## 10. Reference — Moon Princess 100 sources

- Play'n GO official page: https://www.playngo.com/games/moon-princess-100
- BigWinBoard review: https://www.bigwinboard.com/moon-princess-100-playn-go-slot-review/
- FruitySlots review: https://fruityslots.com/slots/reviews/moon-princess-100/
- LCB review: https://lcb.org/games/moon-princess-100
- Dedicated fan page: https://moonprincess100.com/

---

## 11. The 7 combat-system brainstorm (archived — do not lose)

Kept for reference in case the slot direction pivots. Short summaries only.

1. **Memory Deck — "Cards You Regret Playing"** *(Inscryption × Slay the Spire)* — deck of memories, some self-destruct on use; coin-flip altar stakes memories for doubled damage.
2. **CONFRONT / SPARE / LIE** *(Undertale × Deltarune)* — three verbs, typed truths, "Push the Lie" dare.
3. **Dice of Memory** *(Slice & Dice × Inscryption)* — each memory is a custom die, forge faces, slot-strip across dice for revelations.
4. **Locker Deal — Joker Engine** *(Balatro × Cloverpit)* — memory-chip hands, psychological-defense Jokers react to overworld choices.
5. **Cigarette Economy** *(Cloverpit × Inscryption)* — every turn costs one drag; vending machine gambles.
6. **Basement Reels — Slot-Machine Exorcism** *(Cloverpit × Balatro)* — *this is the direction chosen; section 2 expands it.*
7. **Twin-Path Initiative — Truth Deck vs. Lie Deck** *(Deltarune × Slay the Spire)* — two parallel decks, Coin of Guilt gamble, final state decides ending.
