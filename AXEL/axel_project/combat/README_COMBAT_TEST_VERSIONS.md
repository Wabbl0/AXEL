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

## Shared `combat_root`

The shell instances `combat_root.tscn`. Economy uses integer chip units (`ECONOMY_DISPLAY_SCALE = 100` vs legacy decimal display). Paytable values in symbol `.tres` files are scaled accordingly.
