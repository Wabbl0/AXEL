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
│   ├── cluster_detector.gd     # flood-fill cluster detection
│   ├── princess_controller.gd  # rotation + power dispatch
│   ├── multiplier.gd           # per-spin multiplier tracking
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
- Premium: `sym_cigarette` (Storm), `sym_booze` (Star), `sym_bloody_hand` (Love)
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

---

## 3. The spin lifecycle

This is the beating heart. Implement it as an explicit state machine in `combat_root.gd`:

```
IDLE → SPINNING → RESOLVING_CLUSTERS → CASCADING → (loop back to RESOLVING_CLUSTERS)
     → PRINCESS_POWER (only if no clusters found this spin)
     → GOAL_CHECK → IDLE (or END_ENCOUNTER)
```

Key detail: the **loop between RESOLVING_CLUSTERS ↔ CASCADING** continues until a resolve pass finds no clusters. The princess power only fires once per *player-initiated* spin, and only if the *entire* cascade chain produced zero clusters.

Pseudocode skeleton:

```gdscript
func spin() -> void:
    state = State.SPINNING
    _drop_fresh_grid_if_needed()
    _emit_spin_started()

    var produced_any_cluster := false
    while true:
        var clusters = ClusterDetector.find_clusters(grid.cells)
        if clusters.is_empty():
            break
        produced_any_cluster = true
        await _resolve_clusters(clusters)   # removes cells, drops wild at center, +1 mult per cluster
        await _apply_gravity_and_refill()   # cascade + spawn new symbols
        await _item_hooks_post_cascade()

    if not produced_any_cluster:
        await princesses.trigger_current_power()
        princesses.advance_rotation()

    goal_tracker.on_spin_completed(_last_spin_summary())
    if goal_tracker.is_complete():
        end_encounter(true)
    elif spins_used >= encounter.spin_budget:
        end_encounter(false)
    state = State.IDLE
```

The `await` calls let you drive animations without blocking logic; make each phase return after the renderer finishes tweens.

---

## 4. Cluster detection

Flood fill, 4-connected, same-symbol-id. Wild substitutes for *any* low or premium symbol but **does not** form its own cluster with other wilds unless an adjacent non-wild anchor exists.

```gdscript
class_name ClusterDetector

static func find_clusters(cells: Array) -> Array:
    var rows = cells.size()
    var cols = cells[0].size()
    var visited := {}
    var clusters: Array = []

    for r in rows:
        for c in cols:
            if visited.has(Vector2i(c, r)):
                continue
            var sym = cells[r][c]
            if sym == null or sym.tier == SymbolDef.Tier.HAZARD:
                continue
            var component = _flood(cells, visited, Vector2i(c, r), sym.id)
            if component.size() >= 3:
                clusters.append({"symbol_id": sym.id, "cells": component})
    return clusters

static func _flood(cells, visited, start, symbol_id) -> Array:
    var stack := [start]
    var out := []
    while not stack.is_empty():
        var p = stack.pop_back()
        if visited.has(p): continue
        visited[p] = true
        var sym = cells[p.y][p.x]
        if sym == null: continue
        # Wild rule: matches if sym.id == symbol_id OR sym is wild
        if sym.id != symbol_id and sym.tier != SymbolDef.Tier.WILD:
            continue
        out.append(p)
        for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
            var np = p + dir
            if np.x >= 0 and np.x < cells[0].size() and np.y >= 0 and np.y < cells.size():
                if not visited.has(np):
                    stack.append(np)
    return out
```

Two subtleties to watch:
- A wild used as a bridge for symbol A's cluster can **also** be claimed by symbol B's overlapping cluster — design decision: MP100 treats the wild as consumed once. Pick one, document it.
- When multiple clusters resolve in the same pass, decide the **wild-drop center** deterministically — round toward top-left so replays match.

---

## 5. Cascade + refill

1. Mark cluster cells as `null`.
2. For each column, pull non-null entries downward (gravity).
3. Fill empties from the top using a weighted draw from the encounter's symbol weights.

Draw weights are a simple roulette:

```gdscript
func _draw_symbol() -> SymbolDef:
    var total := 0.0
    for s in available_symbols:
        total += _weight_for(s)
    var pick = rng.randf() * total
    var acc := 0.0
    for s in available_symbols:
        acc += _weight_for(s)
        if pick <= acc:
            return s
    return available_symbols.back()
```

Item hooks like `Rotted notebook` peek at the *next N* draws by pre-computing and buffering them.

---

## 6. Wild placement on resolve

Per MP100: each resolved cluster drops **one wild** roughly at its centroid. Compute centroid, round to nearest cell that's currently empty (post-clear) within the cluster's footprint, place wild there, and add `+1` to the spin's multiplier.

```gdscript
func _resolve_clusters(clusters: Array) -> void:
    for cluster in clusters:
        for p in cluster.cells:
            grid.set_cell(p, null)
        var center = _centroid_cell(cluster.cells)
        grid.set_cell(center, WILD_SYMBOL)
        multiplier.add(1)
    await _renderer_flush()
```

---

## 7. Princess rotation + powers

`PrincessController` holds an ordered queue (default: `[Love, Star, Storm]`), exposes `current()`, `trigger_current_power(grid)`, `advance_rotation()`.

```gdscript
func trigger_current_power(grid: GridManager) -> void:
    match current():
        &"love":    _love_transform(grid)
        &"star":    _star_add_wilds(grid, randi_range(1, 2))
        &"storm":   _storm_remove_lowpays(grid, 2)
```

Implementation notes per power:
- **Love:** pick a non-wild, non-hazard cell; pick a target symbol different from the source; rewrite.
- **Star:** pick 1–2 empty-ish cells "intelligently" — simplest heuristic is "cell that would create the largest new cluster if it were a wild"; score each candidate, pick top.
- **Storm:** identify the two lowest-pay tier symbols currently on the grid by count, null them out, cascade.

Items can swap, amplify, or suppress these via hooks (see §9).

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
- `GoalAbstinence`
- `GoalBurnMemory`

`GoalTracker` owns the `progress` dict and forwards `on_spin_completed` to the active goal with a spin summary (payout, wilds placed, clusters formed, princess triggered, etc).

---

## 9. Items — the hook system

Items should be data + a small script that subscribes to lifecycle signals. Define a fixed set of hook points:

```
on_encounter_start(ctx)
on_spin_start(ctx)
on_cluster_resolve(ctx, cluster)
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
- HUD: current goal text + progress, spin budget remaining, current multiplier, stake, active princess portrait + next princess preview.
- **Feel FX to ship early:** CRT scanline shader overlay (carry from prototype), glitch flash on big multipliers, screen shake scaled to multiplier value. Audio: muffled stab on princess trigger, a quiet tone on grid clear. Big wins should feel *wrong* — see design doc §7.

---

## 11. Persistence & runs

- Autoload `RunState` as a singleton. Serialize to `user://run.save` with `var_to_bytes`/`bytes_to_var` between encounters.
- Keep `RunState` small — currency, items, act/encounter index, seed. Never store renderer state.
- A new run creates a new `RunState` with `seed = Time.get_unix_time_from_system()` unless a daily-seed mode is active.

---

## 12. Testing plan

Write headless tests (no scene tree) for:
1. **Cluster detector** — canned grids with known clusters, edge cases (wild bridges, all-wild grid, single-row line).
2. **Cascade** — column pull correctness and refill ordering.
3. **Wild centroid** — given a cluster footprint, returns expected cell.
4. **Princess powers** — mocked grid before/after for Love, Star, Storm.
5. **Goal evaluation** — every goal type with synthetic spin summaries.
6. **Determinism** — seed the RNG, run 100 spins on a fixed encounter, verify identical final grid on replay.

Use [GUT](https://github.com/bitwes/Gut) or `gdunit4` for the runner — both work fine in Cursor.

For visual iteration, keep `combat_test.tscn` bound to F5 with a dropdown to pick encounter and seed.

---

## 13. Phased build order

**Phase 1 — Silent grid (no theme, no polish).**
Goal: spin, see clusters resolve, see cascades, place wilds, read multiplier. No princesses, no goals, no items. Must be deterministic under a fixed seed.

**Phase 2 — Princess rotation.**
Add the three powers. Hook them to "spin produced no clusters." Verify rotation advances only on a no-win spin.

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
- **Floating-point cluster bugs:** centroid math on even-sized clusters is ambiguous. Use integer math + documented tie-break (top-left).
- **Princess-power feedback loop:** Storm removes symbols → cascade → new symbols → maybe new clusters — that's expected; just make sure a princess power does *not* re-queue another princess power on the same spin.
- **Item ordering:** when two items modify the same hook, a later addition can break earlier behavior. Add an item-stack snapshot in the debug HUD from Phase 4 onward.
- **Save-safety:** `RunState` schema changes break saves. Add a `schema_version` field from day 1 and handle migrations.

---

## 15. What to hand back to this design loop

Once Phase 3 runs end-to-end, export:
- A 30-second clip of a cascading spin.
- A JSON dump of one full encounter's spin log (seed, actions, results).
- Any mechanic that felt wrong in play — especially around princess power timing and grid-clear pacing.

That feedback is where the design doc gets its next revision.
