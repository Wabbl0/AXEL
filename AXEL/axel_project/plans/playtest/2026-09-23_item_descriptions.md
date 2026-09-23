# Plan: Plain item descriptions

Plan only. Do not implement in the planning chat.

## What you asked

Check every item description. The in-game text and `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` do not match. Locker Tape’s in-game line is misleading. Make every description short and easy to read, and make the game and the catalog say the same thing.

## What the game does now

- The line the player reads is `description` on each `combat/data/items/*.tres`.
- The catalog table is a separate write-up. It is not loaded at runtime.
- Locker Tape (`C-G_locker_tape.tres`) says: “Regular spins only: skip top refill; payout bonus +12%. Does not apply in Vice Round or Free Spins.” “Skip top refill” sounds like a button. It is an internal guard. The catalog says “Skip-guard if refill is ever invoked,” which is the same idea in developer words.
- The card, the combat hover, and (before the item wheel) the pause list all show this `description` field.

## Locked choices

- Rewrite the player-facing sentence only. Do not change `effect_id`, `effect_params`, rarity, or names.
- The catalog effect cell and the `.tres` `description` become the same sentence.
- Keep the numbers (12%, caps, counts). Drop internal words: skip-guard, refill, scalar, playtest Base target, potency, unless a plain phrase can carry the number.
- Locker Tape’s sentence is: “On normal spins, wins pay 12% more. Does nothing in Vice Round or Free Spins.”

## Steps

1. Read each item’s `effect_params` and the catalog row so the new sentence is true.
2. Write one or two short sentences. Put that exact text in the `.tres` `description` and in the catalog effect cell.
3. Do the whole catalog, not only Locker Tape. Common through Legendary.
4. Add a headless check that loads every item resource, reads the catalog table, and fails if a listed id’s description string is not the catalog sentence (or if Locker Tape still contains “skip” or “refill”).

## What you should see

Hovering Locker Tape no longer mentions refill. The card, combat hover, and catalog agree. Other items read like “wins pay more” or “this symbol shows up more often,” not like code notes.

## How to test

1. In a room, walk up to Locker Tape. Read the card.
2. Spot-check one item of each rank in combat hover.
3. Run the new description check headless and expect exit 0.
4. Run `powers_check.gd` or `determinism_check.gd` and expect exit 0, to confirm no effect numbers changed.

## Risks

- A shorter sentence must not drop a limit the player needs (Vice Round, Free Spins, first spin only, a cap).
- Do not bake icons or touch effect code in this note.

## When this ships

One changelog line. The catalog plan stays the list of items. The `.tres` files stay what the game shows.
