# Combat Min Context

**Prefix:** `combat:` | **Unlock for:** scenes, narrative

## Pointers (on demand)

`AI_DOCS.md` §5 · `plans/combat/AXEL_combat_implementation.md` · `AXEL_combat_design.md` · `AXEL_COMBAT_ITEM_CATALOG_PLAN.md` · `combat/VERIFICATION_CHECKLIST.md`

**Runtime:** `combat/scripts/combat_root.gd` · `combat/combat_test.tscn` · Moon Princess exports = reference only

## Invariants

- 5×5 grid; deterministic RNG; line wins 3+ (rows/cols); no flood-fill cluster wins
- Wild: exactly-3 line → middle cell only
- Multiplier = cascade progression
- Princess map: cigarette→Storm, booze/alcohol→Star, bloody hand→Love
- Trinity Run vs SUPER FS — clarify if prompt says only "Free Spins"
- Catalog edits only in `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`; new mechanic = 5 tiers unless one tier requested

## Hard gates

- **Scaffold:** keep `%CombatRoot`, `%MetaBox`, `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, stake row, SUPER FS buttons — check `combat_test_scaffold_check.gd`
- **Post-FX:** `res://combat/*` excluded from `AxelPostFxStack` — no overworld noir/scanline/CRT pattern in combat
- **Lock:** no `plans/scenes/*`, `game.html`, scene-builder unless unlocked
- **QA:** combat checks only unless user requests full `qa`
