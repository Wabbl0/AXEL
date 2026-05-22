# Combat Test UI

The playtest shell uses a **mirrored grid layout** (spin-history placeholder | 5×5 grid + premium bar | items), integer economy readouts, and dev item picker on the right.

## Canonical entry

| Entry | Scene | Script |
|-------|-------|--------|
| **Default** | `res://combat/combat_test.tscn` | `scripts/combat_test.gd` |

## Launch

- Open `combat/combat_test.tscn` → **F6** (Play Scene).

Headless combat checks (`princess_check`, `determinism_check`) use `combat_root.tscn` only — not this shell.

## HUD features

- Top-left **meta** icons + **SEED** `SpinBox`; top-right **GOAL** progress
- Top-center **BANKROLL** (`current/cap`) and **STAKE** pill with `-` / `+` (integer units)
- Play row: left **HISTORY** placeholder | 5×5 grid + **premium progress bar** (3 sections) | right **ITEMS** dev picker
- Center readout: round **winnings** (integer) between premium bar and **EXECUTE**
- Wide bottom **EXECUTE** button (width tracks grid after layout)
- Match payout numbers flash on winning symbols during resolve

There is no `combat_test_v1` / `combat_test_v2` split — use only the canonical scene above.

## Required scene scaffold (do not delete)

`combat_test.tscn` must contain these nodes (unique names where noted):

- `%CombatRoot` (instance of `res://combat/scenes/combat_root.tscn`)
- `%MetaBox`, `%SeedSpinBox`, `%BankrollLabel`, `%GoalBox`, `%GoalLabel`
- `StakeSelector` / bet row (`%BetMinusButton`, `%BetLabel`, `%BetPlusButton`)
- `%SpinButton`, `%MultiplierReadout`
- `%EncounterWinOverlay`, `%SuperFSChoiceOverlay`, princess choice buttons

**Editor save:** `@tool` layout preview can reparent nodes. Keep `editor_preview_enabled` off unless you need the 2D preview; after enabling preview, confirm scaffold markers still exist before saving. Saving a stripped tree is what causes Play to show only scanlines.

If they are missing, Play/F6 shows only black background + scanlines. Restore with:

```bat
git checkout bab7ec5 -- AXEL/axel_project/combat/combat_test.tscn
```

Verify:

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd
```

## Shared `combat_root`

The shell instances `combat_root.tscn`. Economy uses integer chip units (`ECONOMY_DISPLAY_SCALE = 100` vs legacy decimal display). Paytable values in symbol `.tres` files are scaled accordingly.
