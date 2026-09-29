# AXEL — Combat Implementation Guide (for Cursor + Godot)

Companion to `AXEL_combat_design.md`. This file is the engineering plan: project structure, data model, core algorithms, and a phased build order you can execute inside Cursor against a Godot 4 project. Assumes Godot 4.x + GDScript. Swap to C# if you prefer; structure holds.

> **Read this first, then open `AXEL_combat_design.md` in a side tab.** Design doc = what. This doc = how.

---

## 0. Before you write code

1. **Install:** Godot 4.x (LTS) + the `godot-tools` extension for Cursor.
2. **Repo hygiene:** combat layer lives in `res://combat/` as a self-contained subsystem. It should be runnable in isolation via a test scene (`res://combat/combat_test.tscn`) — you want to iterate on combat without launching the whole school. Standalone F6 is that scene. Autoload `AxelCombatDevTools` (`scripts/debug/axel_combat_dev_tools.gd`) is editor/debug-only (`OS.is_debug_build()`); it must not change release RNG. BGM is autoload `AxelMusic` — `combat_root` calls `notify_trinity` / `notify_trinity_ended` / `notify_free_spins_ended` / `reset_combat_encounter` and must not await audio.
3. **Asset plan:** symbol sprites are 128×128 PNGs under `res://combat/art/grid_symbols/`. Suit symbols (square / triangle / star / heart; files still named `green_circle` / `yellow_triangle` / `blue_star` / `red_heart`) are hollow **red** outlines with the same stroke, carved from Unicode silhouettes (■ ▲ ★ ♥) so they have no fill. Premium / wild (cigarette, bottle, hand, skull) are **hand-authored** — `python combat/art/generate_placeholders.py` must not redraw them; it only adds a 1px faint white halo on the wild (`satanic_wild`). Cigarette / alcohol / bloody hand stay without a halo (`tools/combat/strip_premium_halo.gd` if one reappears). Don't block on final art — all symbols are data-driven by ID, so sprites can be swapped without touching code.
4. **Tooling target:** keep combat deterministic when seeded. All randomness goes through a single `RNG` instance on the encounter state — never `randi()` directly. This is essential for bug-repro and for supporting a "daily seed" run later.

---

## 1. Directory layout

```
res://combat/
├── combat_test.tscn            # F6 catalog tool and world-fight host
├── scenes/
│   ├── combat_root.tscn        # grid + HUD; center PowerIntroIcon names the acting power
│   └── symbol.tscn             # one cell's renderable symbol
├── scripts/
│   ├── combat_root.gd          # orchestrates spin → resolve → cascade → powers
│   ├── grid_manager.gd         # grid state, spawning, cascading
│   ├── line_detector.gd        # row/column line win detection
│   ├── power_controller.gd     # rotation + power dispatch
│   ├── multiplier.gd           # per-spin multiplier tracking
│   ├── meter.gd                # Vice meter state
│   ├── premium_skull_meter.gd  # skull HUD widget (no ring)
│   ├── free_spins.gd           # Free Spins state machine
│   ├── goal_tracker.gd         # goal evaluation per encounter
│   ├── item_inventory.gd       # held items + hook dispatch
│   ├── encounter.gd            # one encounter: goal + budget + modifiers
│   ├── run_state.gd            # live Resource; AxelRun holds the instance
│   └── rng.gd                  # seeded RNG wrapper (`CombatRNG`)
├── data/
│   ├── symbols/                # SymbolDef resources (.tres)
│   ├── goals/                  # GoalDef resources
│   ├── items/                  # ItemDef resources
│   └── encounters/             # EncounterDef resources
└── art/grid_symbols/
```

> **RunState status:** `combat/scripts/run_state.gd` is live (`class_name RunState`). Autoload `AxelRun` owns the instance and serializes it through `AxelSaves` (three slots under `user://saves/`). There is no `RunState` autoload and no `user://run.save`. Goal text is `%GoalLabel` in `combat_test.tscn`. `combat/scenes/goal_hud.tscn` was archived 2026-09-17. Do not restore `RightMeterStack` / `PremiumMeterCircle` / `premium_meter_circle.gd` (deleted, not archived) or the `FeelWinLines` overlay.

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
# Premium-specific: which power owns this symbol (empty for others)
@export var power_id: StringName = &""
```

Register the eight gameplay symbols as `.tres` files:
- Low: `sym_green_circle`, `sym_yellow_triangle`, `sym_blue_star`, `sym_red_heart`
- Premium: `sym_cigarette` (cigarette), `sym_booze`/alcohol, `sym_bloody_hand` (bloody hand). Code power ids are `cigarette` / `alcohol` / `bloody_hand`.
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

Add explicit resource state for Vice Round and Free Spins so the spin machine remains deterministic and debuggable.

```gdscript
class_name MeterState extends Resource
@export var sections_filled: int = 0            # 0..3
@export var saved_active_power: StringName = &""
```

```gdscript
class_name FreeSpinsState extends Resource
@export var active: bool = false
@export var chosen_power: StringName = &""
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
- Power symbols: x3 0.48, x4 1.60, x5 16.00
- Any power: x3 0.32, x4 0.80, x5 8.00
- Bell / Heart: x3 0.24, x4 0.48, x5 4.80
- Star / Green coin: x3 0.16, x4 0.32, x5 3.20
- Wild: x3 1.60, x4 3.20, x5 80.00

---

## 3. The spin lifecycle

This is the beating heart. Implement it as an explicit state machine in `combat_root.gd`:

```
IDLE → SPINNING → RESOLVING_LINES → CASCADING → (loop back to RESOLVING_LINES)
     → TRINITY_CHECK
     → GIRL_POWER_ROLL (only if entire spin had no wins, and not in Vice Round/FreeSpins-forced mode)
     → GRID_CLEAR_CHECK
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
        meter.apply_line_contributions(lines) # power-symbol contribution: x3=+1, x4=+2, x5=+3

    if _should_enter_trinity(meter, produced_any_win):
        await _run_trinity_round()          # fixed bloody hand→alcohol→cigarette sequence, non-winning drops only
    elif free_spins.active:
        await _run_forced_power_on_non_win(free_spins.chosen_power, produced_any_win)
    elif not produced_any_win and _roll_girl_power():
        await powers.trigger_current_power(ctx)
        powers.advance_rotation()

    if _is_grid_empty() and _in_trinity_round:
        _enter_free_spins_choose_state()
    # A cleared grid pays no extra prize. Line wins already paid.

    goal_tracker.on_spin_completed(_last_spin_summary())
    if _in_trinity_round or _pending_free_spins or _awaiting_free_spin_choice or free_spins.active:
        pass
    elif goal_tracker.is_complete():
        end_encounter(true)
    elif not can_afford_next_paid_spin():
        end_encounter(false)
    # Fights end on can't-afford or GOAL. No playtest spin-budget cap.
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
3. **Do not** fill empties from the top during a spin round. Mid-round resolution is depletion-only in all modes (normal, Vice Round, Free Spins).

Initial spin setup still populates a fresh 5x5 via `grid.populate()` at paid-spin start and encounter setup. `GridManager.refill()` remains available for future item hooks but is not called from cascade resolution.

Every `grid.populate()` (paid-spin start, encounter setup, Vice Round entry, Free Spins entry) plays the **board swap**: the old symbols leave as rigid per-column tubes falling off the bottom, leftmost column first, then the new board streams in the same way from the top, leftmost column first, each column one row behind its left neighbour. It is visual only — no RNG draws — and takes ~1.9 s (`board_swap_*` exports on `CombatRoot`). At paid-spin start it replaces the old flat `pause_at_spin_start_sec` wait; Free Spins keep that pause because they reuse the entry board. The mid-round cascade never uses it.

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

## 7. Power rotation

`PowerController` holds ordered power ids `[bloody_hand, alcohol, cigarette]` (display names: bloody hand, alcohol, cigarette) and one active index. On encounter start, randomize the active index once (`rng.randi_range(0, 2)`). Live methods: `current_id()`, `trigger_current_power(ctx)`, `advance_rotation()`.

Trigger rules:
- In the base game, Girl Power may trigger only on a spin that produced zero wins after full cascade resolution.
- Trigger chance is probabilistic (`p_girl_power` data value), not guaranteed.
- Rotation advances only after an actual Girl Power activation.
- Free Spins overrides this: the chosen power always fires when that spin's opening grid has no wins. A winning opening grid uses the normal small chance.
- Vice Round overrides this (fixed bloody hand → alcohol → cigarette sequence, then restore previously active power).
- When a power changes cells, those cells play a 0.48s white-to-grey motion (bloody hand morphs, alcohol is eaten by the wild skull, cigarette burns to ash). The power-icon hold is 0.31s so the activation stays 1.75s. Headless and sync spins skip the motion.

```gdscript
func trigger_current_power(ctx: Dictionary) -> void:
    match current_id():
        &"bloody_hand":    _bloody_hand_transform(ctx)
        &"alcohol":    _alcohol_add_wilds(ctx)
        &"cigarette":   _cigarette_remove_lowpays(ctx)
```

Implementation notes per power:
- **Bloody hand (`bloody_hand`):** select one source symbol type currently on grid and convert that full set into one target symbol type.
- **Alcohol (`alcohol`):** pick 1–2 empty-ish cells "intelligently" — simplest heuristic is "cell that would create the strongest immediate line-win potential if it were a wild"; score each candidate, pick top.
- **Cigarette (`cigarette`):** remove two symbol sets from the grid, then cascade.

Items can swap, amplify, or suppress these via hooks (see §9).

---

## 7a. Vice meter

`MeterState` tracks the 3-section Vice meter.

- On each resolved line, meter contribution is counted only from power-symbol lines:
  - x3 line -> +1 section
  - x4 line -> +2 sections
  - x5 line -> +3 sections
- Wilds can contribute when they are part of a power-symbol line.
- Meter caps at 3 sections.
- When meter is full and the current cascade chain reaches a non-winning drop, enter one Vice Round:
  1. Save current active power id.
  2. Play meter-full transition FX.
  3. Repopulate a fresh 5×5 grid (same encounter RNG stream; no reseed).
  4. Reset multiplier to x1.
  5. On each non-winning drop, trigger Girl Power in fixed order bloody hand -> alcohol -> cigarette.
  6. Exit after all three powers have triggered, restore saved active power.
- If grid clears during Vice Round, transition to Free Spins.
- A cleared grid never pays an extra prize. Line wins that emptied the board already paid.

---

## 7b. Free Spins

Create a dedicated `free_spins.gd` controller.

- Entry: only by clearing the grid during Vice Round.
- Pre-entry choice: player selects a power:
  - Bloody hand: 4 starting spins
  - Alcohol: 5 starting spins
  - Cigarette: 8 starting spins
- On power choice: repopulate a fresh 5×5 grid (same encounter RNG stream; no reseed). That grid is spin 1/X. The rest of the round plays by itself. Execute is ignored until it ends.
- Vice wins and Free Spin wins stay on the winnings bar until that round ends, then the whole bar is added to the goal. The balance still rises as each spin pays.
- During Free Spins:
  - chosen Girl Power triggers on every non-winning opening grid; a winning opening grid uses the normal small chance
  - the first free spin plays the grid from the power choice; each later free spin repopulates a fresh 5×5 before it is judged (same RNG stream, no reseed)
  - cascade resolve inside one spin is gravity-only (no top refill / no new symbol spawns)
  - free-spin depletion/clear checks are based on non-wild symbols; wild-only board states count as cleared
  - Vice Round cannot trigger
  - meter fills grant extra spins before the count advances:
    - Bloody hand +4
    - Alcohol +3
    - Cigarette +2
  - cap total awarded/remaining spins at 100
  - carry multiplier from Vice Round into Free Spins and cap it at x100
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

`GoalTracker` owns the `progress` dict and forwards `on_spin_completed` to the active goal with a spin summary (payout, wilds placed, lines formed, power triggered, etc).

Important clarifications:
- `GoalTrinity` succeeds when the player triggers the real Vice Round.
- `GoalMultiplierCeiling` in base game is measured against single-chain peak multiplier; in Free Spins it may use carried multiplier peak.

---

## 9. Items — the hook system

Items should be data + a small script that subscribes to lifecycle signals. Define a fixed set of hook points:

```
on_encounter_start(ctx)
on_spin_start(ctx)
on_line_resolve(ctx, line)
on_power(ctx, power_id)   # can mutate/cancel
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
- **Empty bottle** (`on_power` where power==alcohol → add +1 wild)
- **Lighter ("AXEL")** (`on_spin_start` once-per-encounter → spin a new grid)

Ship those before filling out the full table from design doc §6.

---

## 10. UI / renderer

- Grid: a `GridContainer` with 25 `TextureRect` children, each bound to a cell. Listen to `grid_populated`, `cells_cleared`, `symbols_fell`, `symbols_spawned` — animate from signal payloads. Keep animations short (≤200ms per step) so cascade chains don't drag. **One exception:** the ~1.9 s board swap on `grid_populated` (§5). It happens once per fresh board, never inside a cascade chain.
- HUD: current goal text + progress (`%GoalLabel`, not `goal_hud.tscn`), current multiplier, stake, Vice **skull** meter (3 sections; `premium_skull_meter.gd` + `meter.gd`). No spin-budget readout. Limit spins / Budget / Used are stripped. The lower-grid `FeelGrimeBand` stays hidden. Round winnings, the cascade multiplier, and the selected bet are white. No ring widget. No match win-line overlay (`FeelWinLines` / `show_win_lines` gone). Paid spin uses the `interact` action (E/Space/Enter + pad A) and the EXECUTE piece. The acting power is named by the center power-intro flash, not by a portrait — the old dim corner icon row was removed.
- Free Spins HUD: the skull stays on its full face through Vice Round and Free Spins, a little smaller and higher, with a gap under the history frame. Under it, one white block per spin still left, plus a white `1/8 spins` count. Both sit in front of the skull and above the color filter, each with a small shadow. Extra spins drip from the mouth. The choice card title is **Choose Your Vice**. The settings mark is a bold eight-tooth cog in the square’s ink (`Color8(7, 7, 7)`), about 63% of the square, painted on a 16×16 grid.
- **Feel FX to ship early:** CRT scanline shader overlay (carry from prototype), glitch flash on big multipliers, screen shake scaled to multiplier value. Audio: muffled stab on power trigger, a quiet tone on grid clear. Big wins should feel *wrong* — see design doc §7.

---

## 11. Persistence & runs

Live wiring: `AxelRun` holds a `RunState` Resource and `AxelSaves` writes three slots under `user://saves/`. Do not add a `RunState` autoload or `user://run.save`.

- Keep `RunState` small — currency, items, act/encounter index, seed, world-fight fields. Never store renderer state.
- A new run creates a new `RunState`. Seed comes from the save/new-game path, not from an extra combat autoload.

---

## 12. Testing plan

Write headless tests (no scene tree) for:
1. **Line detector** — canned grids with known row/column runs (x3/x4/x5), gap rejection, wild substitution, pure-wild runs, and cells participating in both horizontal and vertical wins.
2. **Cascade** — column pull correctness; no top refill during cascade loops.
3. **Wild placement** — 3-line spawns in middle cell only; no spawns for 4/5 lines; overlap-spawn dedupe.
4. **Powers** — mocked grid before/after for bloody hand, alcohol, cigarette and rotation changes only on activation. Live check: `combat/test/powers_check.gd`.
5. **Vice meter** — power-symbol line meter increments (x3/x4/x5), cap at 3, save/restore active power behavior.
6. **Free Spins** — initial spin awards by chosen power, extra-spin awards, Vice Round disabled in feature, x100 multiplier cap, a fresh grid on each free spin after the first, and no refill spawns during free-spin cascades.
7. **Goal evaluation** — every goal type with synthetic spin summaries.
8. **Determinism** — seed the RNG, run 100 spins on a fixed encounter, verify identical final grid on replay.

Use [GUT](https://github.com/bitwes/Gut) or `gdunit4` for the runner — both work fine in Cursor.

For visual iteration, F6 `combat_test.tscn` (Play Scene). That same scene is the live fight host. The catalog dropdown is the F6 tool; a live fight hides it and shows equipped items (the locker tutorial shows the empty DVD).

---

## 13. Phased build order

**Phase 1 — Silent grid (no theme, no polish).**
Goal: spin, resolve line wins, gravity-only cascade, place wilds from 3-lines only, read multiplier-per-drop. No powers, no goals, no items. Must be deterministic under a fixed seed.

**Phase 2a — Power rotation (base game).**
Add the three powers. Hook them to random Girl Power on non-winning spins. Verify rotation advances only after activation.

**Phase 2b — Vice meter + Vice Round.**
Implement meter fill from power-symbol wins, fixed bloody hand->alcohol->cigarette Vice Round sequence, and active-power restore.

**Phase 2c — Free Spins.**
Implement feature entry via Vice Round grid clear, power choice, extra-spin grants, and x100 cap.

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
- **Power feedback loop:** Cigarette removes symbols -> cascade -> new symbols -> maybe new lines — that's expected; just make sure a power does not re-queue another power on the same spin.
- **Vice Round restore bug:** save and restore the active power around Vice Round; do not permanently alter base rotation.
- **Multiplier accounting bug:** multiplier increments once per cascade drop, not once per line.
- **Item ordering:** when two items modify the same hook, a later addition can break earlier behavior. Add an item-stack snapshot in the debug HUD from Phase 4 onward.
- **Save-safety:** `RunState` schema changes break saves. Add a `schema_version` field from day 1 and handle migrations.

---

## 15. What to hand back to this design loop

Once Phase 3 runs end-to-end, export:
- A 30-second clip of a cascading spin.
- A JSON dump of one full encounter's spin log (seed, actions, results).
- Any mechanic that felt wrong in play — especially around power timing and grid-clear pacing.

That feedback is where the design doc gets its next revision.
