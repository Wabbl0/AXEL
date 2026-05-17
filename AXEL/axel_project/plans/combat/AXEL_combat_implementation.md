# AXEL — Combat Implementation Guide (for Cursor + Godot)

Companion to `AXEL_combat_design.md`. This file is the engineering plan: project structure, data model, core algorithms, and a phased build order you can execute inside Cursor against a Godot 4 project. Assumes Godot 4.x + GDScript. Swap to C# if you prefer; structure holds.

> **Read this first, then open `AXEL_combat_design.md` in a side tab.** Design doc = what. This doc = how.

---

## 0. Before you write code

1. **Install:** Godot 4.x (LTS) + the `godot-tools` extension for Cursor.
2. **Repo hygiene:** combat layer lives in `res://combat/` as a self-contained subsystem. It should be runnable in isolation via a test scene (`res://combat/test/combat_test.tscn`) — you want to iterate on combat without launching the whole school.
3. **Asset plan:** placeholder symbols are flat PNGs (16px or 32px, red-on-black). Make a `res://combat/art/placeholders/` folder. Don't block on final art — all symbols are data-driven by ID, so sprites can be swapped without touching code.
4. **Tooling target:** keep combat deterministic when seeded. All randomness goes through a single `RNG` instance on the encounter state — never `randi()` directly. This is essential for bug-repro and for supporting a "daily seed" run later.

---

## 1. Directory layout

```
res://combat/
├── combat_test.tscn            # standalone test scene, boots straight into a fight
├── scenes/
│   ├── combat_root.tscn        # top-level combat scene (grid + HUD + princess UI)
│   ├── symbol.tscn             # one cell's renderable symbol
│   └── goal_hud.tscn           # encounter goal display
├── scripts/
│   ├── combat_root.gd          # orchestrates spin → resolve → cascade → powers
│   ├── grid_manager.gd         # grid state, spawning, cascading
│   ├── line_detector.gd        # row/column line win detection
│   ├── princess_controller.gd  # rotation + power dispatch
│   ├── multiplier.gd           # per-spin multiplier tracking
│   ├── meter.gd                # Trinity meter state and logic
│   ├── free_spins.gd           # Free Spins state machine
│   ├── goal_tracker.gd         # goal evaluation per encounter
│   ├── item_inventory.gd       # held items + hook dispatch
│   ├── encounter.gd            # one encounter: goal + budget + modifiers
│   ├── run_state.gd            # cross-encounter: currency, items, act progress
│   └── rng.gd                  # seeded RNG wrapper
├── data/
│   ├── symbols/                # SymbolDef resources (.tres)
│   ├── goals/                  # GoalDef resources
│   ├── items/                  # ItemDef resources
│   └── encounters/             # EncounterDef resources
└── art/placeholders/
```

Rule of thumb: if a thing is *content* (a symbol type, a goal type, an item), make it a `Resource`. If it's *behavior*, make it a script on a Node. Content should be editable in the Godot inspector without recompiling logic.

---

## 2. Core data model

### 2.1 SymbolDef (Resource)

```gdscript
# res://combat/scripts/symbol_def.gd
class_name SymbolDef extends Resource

enum Tier { LOW, PREMIUM, WILD, HAZARD }

@export var id: StringName
@export var display_name: String
@export var tier: Tier
@export var texture: Texture2D
@export var base_weight: float = 1.0
# Premium-specific: which princess owns this symbol (null for others)
@export var princess_id: StringName = &""
```

Register the eight gameplay symbols as `.tres` files:
- Low: `sym_green_circle`, `sym_yellow_triangle`, `sym_blue_star`, `sym_red_heart`
- Premium (Princess Power aliases): `sym_cigarette` (= Storm), `sym_booze`/alcohol (= Star), `sym_bloody_hand` (= Love)
- Wild: `sym_satanic`
- Hazard (later): `sym_scar`

### 2.2 Grid state

Use a flat 2D array of `SymbolDef` references plus a parallel 2D array of cell flags.

```gdscript
# res://combat/scripts/grid_manager.gd
class_name GridManager extends Node

const COLS := 5
const ROWS := 5

var cells: Array = []        # cells[row][col] : SymbolDef
var flags: Array = []        # flags[row][col] : Dictionary (e.g., {"wild_locked": true, "scar": false})

signal grid_populated
signal cells_cleared(coords: Array[Vector2i])
signal symbols_fell(moves: Array)   # moves: [{from: Vector2i, to: Vector2i}]
signal symbols_spawned(spawns: Array) # spawns: [{coord: Vector2i, sym: SymbolDef}]
```

**Signals matter.** The renderer listens to these and animates. Keep logic and rendering fully decoupled — the grid data should be resolvable without any visuals in the scene.

### 2.3 Encounter & run state

```gdscript
class_name EncounterDef extends Resource
@export var id: StringName
@export var act: int
@export var tier: int                 # difficulty 1..N
@export var goal: GoalDef
@export var spin_budget: int = 8
@export var symbol_weights: Dictionary = {}  # override base_weight per symbol id
@export var starting_modifiers: Array[StringName] = []   # item-like effects not in inventory
```

```gdscript
class_name RunState extends Resource
@export var seed: int
@export var act: int = 1
@export var encounter_index: int = 0
@export var smokes: int = 0
@export var memory_fragments: int = 0
@export var rot: int = 0
@export var lucid: int = 0
@export var items: Array[StringName] = []
```

Store one active `RunState` on an autoload (singleton) — everything else reads from it.

### 2.4 Meter and Free Spins state

Add explicit resource state for Trinity and Free Spins so the spin machine remains deterministic and debuggable.

```gdscript
class_name MeterState extends Resource
@export var sections_filled: int = 0            # 0..3
@export var saved_active_princess: StringName = &""
```

```gdscript
class_name FreeSpinsState extends Resource
@export var active: bool = false
@export var chosen_princess: StringName = &""
@export var spins_remaining: int = 0
@export var spins_awarded_total: int = 0
@export var multiplier_cap: int = 100
@export var total_spin_cap: int = 100
```

```gdscript
class_name PaytableDef extends Resource
@export var pay_x3: Dictionary = {}
@export var pay_x4: Dictionary = {}
@export var pay_x5: Dictionary = {}
```

Seed `PaytableDef` with the screenshot values as source-of-truth tuning inputs:
- Princess symbols: x3 0.48, x4 1.60, x5 16.00
- Any princess: x3 0.32, x4 0.80, x5 8.00
- Bell / Heart: x3 0.24, x4 0.48, x5 4.80
- Star / Green coin: x3 0.16, x4 0.32, x5 3.20
- Wild: x3 1.60, x4 3.20, x5 80.00

---

## 3. The spin lifecycle

This is the beating heart. Implement it as an explicit state machine in `combat_root.gd`:

```
IDLE → SPINNING → RESOLVING_LINES → CASCADING → (loop back to RESOLVING_LINES)
     → TRINITY_CHECK
     → GIRL_POWER_ROLL (only if entire spin had no wins, and not in Trinity/FreeSpins-forced mode)
     → CLEAR_GRID_PRIZE_CHECK
     → GOAL_CHECK → IDLE (or END_ENCOUNTER / ENTER_FREE_SPINS)
```

Key detail: the **loop between RESOLVING_LINES ↔ CASCADING** continues until a resolve pass finds no wins. Also, the multiplier increments **once per cascade drop**, not once per winning line.

Pseudocode skeleton:

```gdscript
func spin() -> void:
    state = State.SPINNING
    _drop_fresh_grid_if_needed()
    _emit_spin_started()

    var produced_any_win := false
    var cascade_drops := 0
    while true:
        var lines = LineDetector.find_lines(grid.cells)
        if lines.is_empty():
            break
        produced_any_win = true
        await _resolve_lines(lines)         # removes winning cells, drops wilds only from 3-lines
        await _apply_gravity_and_refill()   # gravity-only cascade (no top refill)
        cascade_drops += 1
        multiplier.add(1)                   # +1 per drop event
        await _item_hooks_post_cascade()
        meter.apply_line_contributions(lines) # princess-only contribution: x3=+1, x4=+2, x5=+3

    if _should_enter_trinity(meter, produced_any_win):
        await _run_trinity_round()          # fixed Love→Star→Storm sequence, non-winning drops only
    elif free_spins.active:
        await _run_forced_princess_on_non_win(free_spins.chosen_princess, produced_any_win)
    elif not produced_any_win and _roll_girl_power():
        await princesses.trigger_active_power()
        princesses.advance_rotation_after_activation()

    if _is_grid_empty():
        if _in_trinity_round:
            _enter_free_spins_choose_state()
        else:
            _award_clear_grid_prize()       # 50x total bet x active multiplier

    goal_tracker.on_spin_completed(_last_spin_summary())
    if goal_tracker.is_complete():
        end_encounter(true)
    elif spins_used >= encounter.spin_budget:
        end_encounter(false)
    state = State.IDLE
```

The `await` calls let you drive animations without blocking logic; make each phase return after the renderer finishes tweens.

---

## 4. Line detection

Do not use flood fill. MP100 wins are line-based: contiguous runs of 3+ in one row or one column, no gaps.

```gdscript
class_name LineDetector

static func find_lines(cells: Array) -> Array:
    var lines: Array = []
    for r in ROWS:
        _scan_run(cells, lines, Vector2i(0, r), Vector2i(1, 0), COLS)
    for c in COLS:
        _scan_run(cells, lines, Vector2i(c, 0), Vector2i(0, 1), ROWS)
    return lines
```

`_scan_run` tracks one line at a time with run-length logic:
- Choose an anchor symbol id for a run.
- A wild matches the active anchor id.
- A run of length `>= 3` emits `{symbol_id, cells, length, axis}`.
- The same cell can participate in one horizontal and one vertical line.
- Payout is summed over all emitted lines, but clear/destroy is deduplicated by cell.

Pure-wild runs are valid and pay as wild (wild has explicit x3/x4/x5 pay values).

---

## 5. Cascade (gravity-only)

1. Mark winning-line cells as `null`.
2. For each column, pull non-null entries downward (gravity).
3. **Do not** fill empties from the top during a spin round. Mid-round resolution is depletion-only in all modes (normal, Trinity Run, SUPER Free Spins).

Initial spin setup still populates a fresh 5x5 via `grid.populate()` at paid-spin start and encounter setup. `GridManager.refill()` remains available for future item hooks but is not called from cascade resolution.

Item hooks like `Rotted notebook` may later peek at buffered draws if a separate preview/refill feature is added; cascade resolution itself does not consume the drop queue.

---

## 6. Wild placement on resolve

Per MP100: a wild is created only from winning lines of **exactly 3** symbols, and only at that line's middle cell.

```gdscript
func _resolve_lines(lines: Array) -> void:
    var to_clear := {}
    var wild_spawns := {}
    for line in lines:
        for p in line.cells:
            to_clear[p] = true
        if line.length == 3:
            var mid: Vector2i = line.cells[1] # sorted contiguous line
            wild_spawns[mid] = true
    for p in to_clear.keys():
        grid.set_cell(p, null)
    for p in wild_spawns.keys():
        if grid.get_cell(p) == null:
            grid.set_cell(p, WILD_SYMBOL)
    await _renderer_flush()
```

Do not spawn wilds for 4- or 5-symbol wins. If two 3-lines overlap and point to same middle cell, spawn once.

---

## 7. Princess rotation + powers

`PrincessController` holds ordered princess ids `[Love, Star, Storm]` and one active index. On encounter start, randomize the active index once (`rng.randi_range(0, 2)`).

Trigger rules:
- In the base game, Girl Power may trigger only on a spin that produced zero wins after full cascade resolution.
- Trigger chance is probabilistic (`p_girl_power` data value), not guaranteed.
- Rotation advances only after an actual Girl Power activation.
- Free Spins overrides this (chosen princess forced every non-winning spin).
- Trinity round overrides this (fixed Love → Star → Storm sequence, then restore previously active princess).

```gdscript
func trigger_active_power(grid: GridManager) -> void:
    match active_princess_id():
        &"love":    _love_transform(grid)
        &"star":    _star_add_wilds(grid, rng.randi_range(1, 2))
        &"storm":   _storm_remove_two_symbol_sets(grid)
```

Implementation notes per power:
- **Love:** select one source symbol type currently on grid and convert that full set into one target symbol type.
- **Star:** pick 1–2 empty-ish cells "intelligently" — simplest heuristic is "cell that would create the strongest immediate line-win potential if it were a wild"; score each candidate, pick top.
- **Storm:** remove two symbol sets from the grid, then cascade.

Items can swap, amplify, or suppress these via hooks (see §9).

---

## 7a. Trinity meter

`MeterState` tracks the 3-section Trinity meter.

- On each resolved line, meter contribution is counted only from princess-symbol lines:
  - x3 line -> +1 section
  - x4 line -> +2 sections
  - x5 line -> +3 sections
- Wilds can contribute when they are part of a princess-symbol line.
- Meter caps at 3 sections.
- When meter is full and the current cascade chain reaches a non-winning drop, enter one Trinity round:
  1. Save current active princess id.
  2. Play meter-full transition FX.
  3. Repopulate a fresh 5×5 grid (same encounter RNG stream; no reseed).
  4. Reset multiplier to x1.
  5. On each non-winning drop, trigger Girl Power in fixed order Love -> Star -> Storm.
  6. Exit after all three powers have triggered, restore saved active princess.
- If grid clears during Trinity, transition to Free Spins (no instant clear-grid payout).

---

## 7b. Free Spins

Create a dedicated `free_spins.gd` controller.

- Entry: only by clearing the grid during Trinity.
- Pre-entry choice: player selects princess:
  - Love: 4 starting spins
  - Star: 5 starting spins
  - Storm: 8 starting spins
- On princess choice: repopulate a fresh 5×5 grid (same encounter RNG stream; no reseed) before the first Super Free Spin.
- During Free Spins:
  - chosen Girl Power triggers on every non-winning spin
  - spin start does not repopulate; each spin continues from the entry grid state and depletes it
  - cascade resolve is gravity-only (no top refill / no new symbol spawns)
  - free-spin depletion/clear checks are based on non-wild symbols; wild-only board states count as cleared
  - Trinity cannot trigger
  - meter fills grant extra spins:
    - Love +4
    - Star +3
    - Storm +2
  - cap total awarded/remaining spins at 100
  - carry multiplier from Trinity into Free Spins and cap it at x100
- On exit: reset/free-spin-specific state and return to base spin flow.

---

## 8. Goals (encounter win conditions)

Each `GoalDef` is a resource that subclasses a base script implementing an interface:

```gdscript
class_name GoalDef extends Resource
@export var id: StringName
@export var display_text: String
func on_spin_completed(summary: Dictionary, progress: Dictionary) -> void: pass
func is_complete(progress: Dictionary) -> bool: return false
func progress_label(progress: Dictionary) -> String: return ""
```

Create concrete subclasses per goal type from design doc §5:
- `GoalPayoutThreshold`
- `GoalWildCount`
- `GoalRowColumnPay`
- `GoalGridClear`
- `GoalMultiplierCeiling`
- `GoalSymbolPurge`
- `GoalTrinity`
- `GoalFreeSpins`
- `GoalAbstinence`
- `GoalBurnMemory`

`GoalTracker` owns the `progress` dict and forwards `on_spin_completed` to the active goal with a spin summary (payout, wilds placed, lines formed, princess triggered, etc).

Important clarifications:
- `GoalTrinity` succeeds when the player triggers the real Trinity round.
- `GoalMultiplierCeiling` in base game is measured against single-chain peak multiplier; in Free Spins it may use carried multiplier peak.

---

## 9. Items — the hook system

Items should be data + a small script that subscribes to lifecycle signals. Define a fixed set of hook points:

```
on_encounter_start(ctx)
on_spin_start(ctx)
on_line_resolve(ctx, line)
on_princess_power(ctx, princess_id)   # can mutate/cancel
on_cascade_end(ctx)
on_encounter_end(ctx, result)
```

`ctx` carries references to grid, multiplier, goal tracker, run state, and RNG.

```gdscript
class_name ItemDef extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var hook_script: Script   # attached implementation
```

`ItemInventory` walks active items and calls each hook in registration order. Keep the order **stable** — items that depend on each other (e.g., `Shaky hands` + `Empty bottle`) will need a deterministic ordering.

Start by implementing three items end-to-end so the hook wiring is battle-tested:
- **Half-smoked cigarette** (`on_encounter_start` → place one wild)
- **Empty bottle** (`on_princess_power` where princess==star → add +1 wild)
- **Lighter ("AXEL")** (`on_spin_start` once-per-encounter → reroll grid)

Ship those before filling out the full table from design doc §6.

---

## 10. UI / renderer

- Grid: a `GridContainer` with 25 `TextureRect` children, each bound to a cell. Listen to `grid_populated`, `cells_cleared`, `symbols_fell`, `symbols_spawned` — animate from signal payloads. Keep animations short (≤200ms per step) so cascade chains don't drag.
- HUD: current goal text + progress, spin budget remaining, current multiplier, stake, active princess portrait, Trinity meter (3 sections).
- Free Spins HUD: chosen princess, spins remaining, carry multiplier, total-spin-cap progress.
- **Feel FX to ship early:** CRT scanline shader overlay (carry from prototype), glitch flash on big multipliers, screen shake scaled to multiplier value. Audio: muffled stab on princess trigger, a quiet tone on grid clear. Big wins should feel *wrong* — see design doc §7.

---

## 11. Persistence & runs

- Autoload `RunState` as a singleton. Serialize to `user://run.save` with `var_to_bytes`/`bytes_to_var` between encounters.
- Keep `RunState` small — currency, items, act/encounter index, seed. Never store renderer state.
- A new run creates a new `RunState` with `seed = Time.get_unix_time_from_system()` unless a daily-seed mode is active.

---

## 12. Testing plan

Write headless tests (no scene tree) for:
1. **Line detector** — canned grids with known row/column runs (x3/x4/x5), gap rejection, wild substitution, pure-wild runs, and cells participating in both horizontal and vertical wins.
2. **Cascade** — column pull correctness; no top refill during cascade loops.
3. **Wild placement** — 3-line spawns in middle cell only; no spawns for 4/5 lines; overlap-spawn dedupe.
4. **Princess powers** — mocked grid before/after for Love, Star, Storm and rotation changes only on activation.
5. **Trinity meter** — princess-line meter increments (x3/x4/x5), cap at 3, save/restore active princess behavior.
6. **Free Spins** — initial spin awards by chosen princess, extra-spin awards, Trinity disabled in feature, x100 multiplier cap, no per-spin repopulation, and no refill spawns during free-spin cascades.
7. **Goal evaluation** — every goal type with synthetic spin summaries.
8. **Determinism** — seed the RNG, run 100 spins on a fixed encounter, verify identical final grid on replay.

Use [GUT](https://github.com/bitwes/Gut) or `gdunit4` for the runner — both work fine in Cursor.

For visual iteration, keep `combat_test.tscn` bound to F5 with a dropdown to pick encounter and seed.

---

## 13. Phased build order

**Phase 1 — Silent grid (no theme, no polish).**
Goal: spin, resolve line wins, gravity-only cascade, place wilds from 3-lines only, read multiplier-per-drop. No princesses, no goals, no items. Must be deterministic under a fixed seed.

**Phase 2a — Princess rotation (base game).**
Add the three powers. Hook them to random Girl Power on non-winning spins. Verify rotation advances only after activation.

**Phase 2b — Trinity meter + Trinity round.**
Implement meter fill from princess wins, fixed Love->Star->Storm Trinity sequence, and active-princess restore.

**Phase 2c — Free Spins.**
Implement feature entry via Trinity grid clear, princess choice, extra-spin grants, and x100 cap.

**Phase 3 — Goals and encounters.**
Implement `GoalDef` base + three goal types (payout threshold, wild count, grid clear). Build one `EncounterDef` per goal. Combat is now win/losable.

**Phase 4 — Items.**
Ship three items end-to-end (cigarette, bottle, lighter). Lock in the hook API.

**Phase 5 — Run structure.**
Stitch encounters into an act. Add shop scene between encounters. Currency + stake flow.

**Phase 6 — Feel pass.**
Scanlines, glitch FX, shake, audio, transitions. The "big wins feel wrong" rule from design doc §7.

**Phase 7 — Escalation.**
Difficulty scaling (thresholds, budgets, weights), Corruption hazard cells, the Abstinence goal, burn-a-memory goal.

**Phase 8 — Meta layer.**
Memory fragments as meta-currency, Rot/Lucid counters, wire the lucid counter to the overworld so combat decisions gate exploration scenes.

Ship Phase 1 before you touch Phase 2. Do not skip phases.

---

## 14. Watchpoints / common pitfalls

- **Await hell:** if `spin()` awaits a renderer that never finishes, the whole machine hangs. Always add a hard timeout fallback on animation awaits in debug builds.
- **Line-vs-cluster confusion:** if any flood-fill logic remains, you'll get invalid wins. Keep win detection strictly row/column run-length.
- **Wild spawn conflicts:** only 3-lines spawn wilds at middle cell. Overlapping 3-lines can target same spawn cell; dedupe deterministically and document resolution order.
- **Princess-power feedback loop:** Storm removes symbols -> cascade -> new symbols -> maybe new lines — that's expected; just make sure a princess power does not re-queue another princess power on the same spin.
- **Trinity restore bug:** save and restore active princess around Trinity; do not permanently alter base rotation.
- **Multiplier accounting bug:** multiplier increments once per cascade drop, not once per line.
- **Item ordering:** when two items modify the same hook, a later addition can break earlier behavior. Add an item-stack snapshot in the debug HUD from Phase 4 onward.
- **Save-safety:** `RunState` schema changes break saves. Add a `schema_version` field from day 1 and handle migrations.

---

## 15. What to hand back to this design loop

Once Phase 3 runs end-to-end, export:
- A 30-second clip of a cascading spin.
- A JSON dump of one full encounter's spin log (seed, actions, results).
- Any mechanic that felt wrong in play — especially around princess power timing and grid-clear pacing.

That feedback is where the design doc gets its next revision.
