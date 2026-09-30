# AXEL — World combat loop plan

School → fight loop, world-placed combat items, area item ranks, and the
visited-room map gate. Written 2026-09-06. Supersedes master-plan **D7**
(locker-only entry) and the old `AXEL_notes` line "memories do not trigger
combat".

Canon still wins: `plans/core/AI_DOCS.md`. Catalog text changes only in
`plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.

## What changes for the player

- Walking indoors can start a fight (rare).
- Memories start a fight after the still finishes.
- Flashlight / key / shovel / name start a fight after their line.
- Combat items lie on the floor in indoor rooms; picking one up starts a fight.
- All item ranks start Common; picking up in one area clears it and upgrades
  the rooms you have not taken from yet (those items_indicators change to the new rarity).
- The locker shows lore pictures only. Equip and unequip live on the item wheel. `START RUN` is gone. After a correct board answer the name-tag picture becomes that floor item's icon.
- The locker map and pause Map are the same overlay. A room with floor items travels after a visit and one pickup. Entrance loads `1.2` after a visit. A click on the room you opened the map from does nothing. The basement is not a travel button; its items_indicator is pinned on the right half of Entrance. Items_indicators are placed when the game starts. Each map items_indicator shows the rarity mark, and a rarity step redraws the items_indicators and the hover cards.
- A full-screen wipe plays on the way into every fight.
- Winning puts you back in the room you left, on the spot you left.
- Losing deletes that slot’s save files (no tombstone) and keeps **GONE** up with **Retry** / **Return To Main Menu** / **Exit**. Retry starts a new run from `1.1` on the slot that died. `AxelWorld.notify_fight_ended()` clears `_starting_fight` on a loss so New Game can fight again.

## Layer rule

Narrative decides *when* a fight starts. `AxelRun` is still the only thing that
starts one, and combat still never reads a story flag. The new autoload
`AxelWorld` sits on the narrative side of that line.

## Areas (7 written areas → live rooms)

| Area id | Rooms | Floor items | Step fights |
| --- | --- | --- | --- |
| `halls` | `1.2_Corridor`, `2.4_ClassroomsCorridor` | 0 + 1 | 1.2 gated, 2.4 yes |
| `cafeteria` | `2.1_Cafeteria` | 3 | yes |
| `kitchen` | `2.3_Kitchen` | 2 | yes |
| `lounge` | `4.1_TeachersLounge` | 2 | yes |
| `classroom` | `5.1_Classroom` | 2 | yes |
| `basement` | `1.4_BasementDoor` | 1 | yes |
| `backyard` | `3.1_Backyard` | 2 | no |

`3.1_Backyard` has floor items and does not walk-fight (`walk` false). Greybox rooms (`6.x`, `5.3`, `5.4`) have no Player node, so they
get no step fights either — only their lore pickups start fights.

### Gated rooms: `1.1_SchoolExterior` and `1.2_Corridor`

The two rooms the player sees first are quiet on purpose, so a new run cannot
open with a random fight.

- **No floor items, ever.** `1.2` stays in `halls` with a count of `0` (so its
  rank plumbing keeps working and `halls` is cleared by 2.4's single item);
  `1.1` is deliberately left out of `AREAS` entirely, which is what keeps
  scatter off it while `can_walk_fight()` can still say yes later.
- **Walk fights only, and only after the gate opens.** `AxelWorld.can_walk_fight()`
  routes `GATED_WALK_SCENES` through `walk_fights_unlocked()`, which needs
  `RunState.tutorial_fight_done` **and** a non-empty `RunState.fought_rooms`
  (some other room has already hosted a fight — `1.4` is the usual first).
  A fight in `1.1` or `1.2` never counts toward their own unlock.

### Locker tutorial (first fight)

The flashlight, key, and name tag pictures sit in `1.3_LockerHub` (no LOCKER button). Each stays hidden until that item is picked up. After a correct board answer the name-tag picture becomes that floor item's icon. The shovel is not on the locker. Combat items stay on the item wheel.
First hub visit sets the opened-locker flag — no starter items. Leave the hub
yourself with the red `X` or Esc. The **first** hub→`1.2` leave queues the tutorial.
First-visit map lines block X/Esc. `1.3_LockerHub` calls
`AxelWorld.queue_locker_tutorial_fight()` (no stash required).
`AxelWorld._on_scene_changed` starts it once `1.2_Corridor` is loaded.
`tutorial_fight_done` is set only after `in_encounter` is true. Reason string: `locker_tutorial`.

That fight is the lowest rung of the goal ladder (100 cents), runs with an **empty**
loadout, and locks the last affordable paid spin (including an immediate all-in)
to a fixed seed whose real matches pay the goal (see below). No in-fiction
warning line plays — master plan D10's `first_encounter_warned` flag stays
unwired.

### World goal ladder

`AxelRun.WORLD_GOAL_LADDER_CENTS` = `100, 150, 225`
(HUD units = raw cents), indexed by `RunState.world_fight_count` (monotonic; **not**
`world_encounter_index`, which wraps at 3). Past the last rung each further
fight multiplies by `1.5`, rounded to 25 cents (337.5 → 350). It reaches combat as a plain
number through the pre-existing `CombatRoot.set_goal_base_target_cents()`; the
lore goal bonus and family-H percents still multiply on top. Act fights are
untouched and keep combat's own 10x default.

### Last-spin lock (tutorial / first fight)

`CombatRoot.set_tutorial_last_spin_lock(true)` on the locker tutorial (and the
first world fight). The last affordable paid spin — you can afford this bet,
but not the same bet again, so an immediate all-in of the whole 1000 counts —
reseeds to `TUTORIAL_LAST_SPIN_SEED` (`12`) before the grid populate. Real symbol
matches pay the remaining live lowest-rung goal (100). This replaces the old 99% silent
goal-bar fill (`set_final_spin_goal_assist`). Losing still deletes the save (D8).

This is a deliberate, narrow carve-out from `AXEL_notes` §8.3 ("no minimum
payout safety net"). The lock only remaps that one spin's RNG; other fights
keep their encounter seeds.

### Floor marker and info card

Every floor pickup draws the same items_indicator
(`scenes/world/ItemMarker.tscn`, `assets/sprites/items_indicator-Sheet.png` — 5
frames of 48×48). The pickup `Area2D` stays under `EnvironmentColliders` so
the 220 px interact circle takes the room's cover-fit. The picture reparents
to `PlayerLayer` (above noir, `z_index` `-8` so Mike draws in front) so the
items_indicator stays white. The memory blob is red with a white outline (0.96 texture pixels, 75% opacity). A drop shadow and
a red outline at 75% opacity (`marker_silhouette_outline.gdshader`, 1.92 texture pixels) keep the items_indicator from looking
like that blob.

Scatter only accepts a spot whose **220 px interact circle plus an 8 px pad** (`INTERACT_PAD_PX`; the live Area2D stays 220) misses walls and
furniture (shape query, not a point) and whose cell is on the walkable floor
connected to Mike (Front hitbox flood from the Player node). Pass 1 still tries to dodge door
`Area2D`s; pass 2 may share a door box in a corridor whose floor is all
zones (`2.4`) rather than skip the item.

What the item actually is only shows up when you walk into the existing
220 px radius: `scenes/ui/world_item_info_card.gd` (one per room, layer 109 —
above CRT 108, below dialogue 111) CRT-opens like the dialogue bar. It shows
the item's real name (with the rarity glyph), `description`, and catalog `icon` 10px under the painted
items_indicator. `[E]` is the bottom-right line of that card, at the description font
size. The first time that card opens, the Items lesson plays, and E does not take the item while a lesson card is open. The card is as wide as the icon plus the full title on one row.

Floor pickups auto-equip into a free slot (`AxelRun.equip_owned_if_free`) so that
fight's ITEMS list is live. Unequip is on the overworld item wheel. The locker only shows lore pictures.

## Rank progression (AXEL_notes §2.3)

Every area starts at Common, including extended Commons. The same seed always
shows the same Common board, whether you open `1.4` or `2.1` first. The first
pickup in an area *clears* it and freezes its leftover items at that rarity.
Every area that is neither engaged nor cleared moves up one rank (cap
Legendary) and is rolled again from the same seed at the new rank. Items_indicators stay;
only the item changes. Taking the rest of a cleared area does not bump anyone
again. `1.2` has no floor item, so taking the items_indicator in `2.4` clears Halls.

Item ids resolve as `TIER-FAMILY` from the live `.tres` files, or as a baseline
line from `combat/scripts/item_lines.gd` (C1–C10 and their later rungs). Each
area owns a short family list; the roll mixes those families with leftover
baseline lines and tries the area rank first, then walks down until an id
exists. It skips ids the player already owns and leftover items still lying in
a cleared area.

## Numbers (tuning constants at the top of `axel_world.gd`)

- `STEP_CHANCE_BASE` `0.001` (0.1% per 8 px step)
- `STEP_CHANCE_PER_CLEARED_AREA` `0.0015`
- `STEP_CHANCE_MAX` `0.01` (1% once all six areas are cleared)
- `STEP_GRACE_AFTER_FIGHT` `200` steps with no step fight after any fight
- `MAX_STEP_FIGHTS_PER_VISIT` `2` per room visit
- `INTERACT_PAD_PX` `8` extra clearance around the 220 px pickup circle when choosing a spot (the live Area2D stays 220)

## Implementation steps

1. `combat/scripts/run_state.gd` — add `world_encounter`, `world_reason`,
   `world_return_scene`, `world_return_tex_x/y`, `world_return_tex_valid`,
   `world_encounter_index`; serialise them.
2. `scripts/autoload/axel_run.gd` — add `enter_world_encounter()`. It plays the
   wipe, switches music, and loads `combat/combat_test.tscn`. World encounters do
   not advance acts; on win the run returns to `world_return_scene` and asks
   `AxelWorld` to restore the standing spot. Loss path unchanged. The old
   three-act `enter_combat()` stays in the file, unreachable.
3. `scripts/autoload/axel_world.gd` (new autoload `AxelWorld`) — area table,
   rank state, floor-item placement + persistence, walk-step roll with cooldown
   and per-visit cap, lore-pickup fight guard, visited-room marking, return
   placement after a win. Kill switch: `AXEL_WORLD_COMBAT=0`.
4. `scenes/world/world_item_pickup.gd` (new) — `[E]` floor pickup. Adds the item
   to `AxelRun`, marks it taken, then starts a fight.
5. `scenes/fx/combat_wipe_overlay.gd` (new) + `AxelEventFx.play_combat_wipe()` /
   `clear_combat_wipe()` — red-bar wipe on an autoload layer above CRT so it
   survives the scene change. No sound (D15). `reduce_flashing` gets a plain
   fade. Safety timeout clears a stuck wipe.
6. `combat/scripts/combat_test.gd` — clear the wipe once the board is up.
7. `exports/GameManager.gd` — `visited_rooms` set plus `mark_room_visited()` /
   `has_visited()`; save body carries `visited_rooms` and the `AxelWorld` block.
8. `scripts/Player.gd` — one call to `AxelWorld.register_walk_step()` next to
   the existing `AxelEventFx.register_walk_step()`.
9. `scenes/ui/locker_shelves.gd` + `scenes/Arc_1/1.3_LockerHub.gd` —
   no LOCKER button and no overlay. Flashlight, key, and name tag pictures
   show only after pickup. After a correct board answer the name tag uses that
   floor item's icon. The shovel is not on the locker. First hub visit sets the opened-locker flag (no C1/C2/C3 grant).
10. `scenes/ui/locker_map_overlay.gd` — locker and pause Map share this overlay.
    Travel uses `AxelWorld.map_can_travel()`: a visit, plus one floor-item pickup
    when that room has items_indicators. Entrance loads `1.2` after a visit. A click on the
    room you opened the map from does nothing. The basement is not a travel
    button; its items_indicator is pinned on the right half of Entrance. Items_indicators are placed
    when the game starts. Each pin shows the rarity mark. A rarity step redraws
    the pins and the hover cards.
11. Memory stills — `2.2_CafeteriaMemory.gd`, `3.2_BackyardMemory.gd`,
    `4.2_TeachersMemory.gd`, `5.2_ClassroomDesk.gd`: leave through
    `AxelWorld.start_memory_fight()` instead of `change_scene_to_file`. `5.2`
    fights but stays *not* a 5/5 memory.
12. Lore pickups — `2.3_Kitchen.gd` (flashlight), `4.1_TeachersLounge.gd` (key),
    `scenes/core/greybox_choice.gd` (shovel): fight after the line, once
    per flag. The name fight starts from `5.1` after a correct board answer.
    The basement corpse checks that answered item is equipped.
13. Docs — name the six areas in the catalog plan's Area / Rarity Progression
    section, gate `L-G Iron Lung` to the basement, add `AxelWorld` to `AI_DOCS`,
    log the D7 replacement in `AI_CHANGELOG`.
14. `tools/qa/world_combat_loop_check.gd`, `tools/qa/world_item_scatter_check.gd`,
    `tools/qa/world_combat_roundtrip_check.gd` (new) — headless checks for the
    area table / rank curve / save round trip, for floor items landing on
    reachable floor in every indoor room, and for the full room → fight → same
    room → same spot trip.

## Acceptance criteria

- Walking indoors sometimes starts a fight; `3.1` still never does, and `1.1` / `1.2`
  only after the tutorial gate opens.
- Leaving the hub yourself starts one fight on
  arrival in `1.2`: 100 goal, empty loadout, last affordable paid spin (including
  an immediate all-in) reseeds to a fixed board whose real matches pay the goal.
- Flashlight / key / shovel / name each start exactly one fight, ever.
- Every memory still ends in a fight. The locker map paper (`scene_3`) does not.
- Every floor item looks like the same items_indicator from across the
  room; walking near one shows its real name, description and icon.
- Floor items show `[E]` on the walk-near card, join the item inventory (and auto-equip if a slot is free), and start a fight. The first walk-up opens the Items lesson, and E does not take the item while that card is open.
- `1.1` and `1.2` never hold a floor item. `3.1` holds two.
- Fight goals climb 100, 150, 225, then ×1.5 (rounded to 25).
- The first area's floor items are Common; after that pickup, every area you
  have not taken from reads one rank higher and its items_indicators show the new rarity.
- The locker has no START RUN button and no LOCKER overlay; flashlight, key, and name pictures sit on the locker. Combat equip is the item wheel.
- The locker map and pause Map are the same picture. A room with floor items travels only after a visit and one pickup there. Entrance loads `1.2` after a visit. A click on the room you opened the map from does nothing. Hallway on the map is `2.4`. The basement is not a travel button; its items_indicator is pinned on the right half of Entrance. Items_indicators are placed when the game starts. Each map items_indicator shows the rarity mark, and a rarity step redraws the items_indicators and the hover cards.
- A wipe plays before each fight; a win shows Round Complete!, fades, and returns to the same room and spot.
- The `1.4` chained door plays `"Not yet."` and stays in the room.

## Manual test checklist

1. New game → walk `1.1` and `1.2` for a while: no items_indicators and no fights.
2. Locker → close → red `X`: a fight starts as you land in `1.2`, with a 100
   goal and an empty item panel. Last spin / all-in pays the goal from real
   matches. Win → back in `1.2` where you stood.
3. Walk to `1.4`, walk near the items_indicator: its real name, description and icon
   show before you press `[E]`. Take it → fight (next ladder rung, 150) → win.
   The chained door only plays `"Not yet."` and stays in the room.
4. Return to `1.1` / `1.2` and walk: fights can now happen. `3.1` still cannot walk-fight, but it does have items_indicators.
5. Open the locker map at the start: every floor-item room already has an items_indicator. The basement items_indicator sits on the right half of Entrance. Clicking the room you are already in does nothing. Before visiting `2.3`, kitchen does not travel. Walk there, pick up one items_indicator, reopen: the click works. Hover shows the remaining items_indicators and their cards. The other items_indicators show the next rarity.

## Found while building

- Repositioning the player (spawn placement, cover-fit, post-fight return) used
  to feed the step counter, so entering a room banked hundreds of "steps" at
  once and could start a fight immediately. `Player.gd` now drops any jump of
  64 px or more instead of counting it. This also fixes the same flaw in the
  existing CRT pulse cadence.
- One area only ever grants one rank upgrade to the untouched areas — the first
  pickup there, which is also what clears it. Taking the rest of its items does
  not bump anyone again.
- Floor spots are searched on both axes with the **220 px interact
  circle plus an 8 px pad**; they dodge walls/furniture for sure, and interact zones when a
  hole exists. If a room's whole floor is door boxes (`2.4`), the second pass
  settles for open floor that shares a zone rather than putting the item in a
  wall.

## Risks and rollback

- Step rate is a guess; tune the five constants after one playtest.
- `2.4_ClassroomsCorridor`'s single floor item shares a door box, so two `[E]`
  chips can show there. Adding authored spawn points to that room fixes it.
- Save bodies gain two blocks. Missing keys default, so old slots still load.
- Return placement runs a few frames after the room settles; if a room ever
  moves the player later than that, the spot can be off by a step.
- Floor-item spots are picked when the game starts, from the room's clear spots (the full interact circle misses walls and furniture, and the cell is on Mike's connected walkable floor) using the run seed, then stored in the save. The map can show every items_indicator before that room is walked. A saved spot that fails that test is moved the next time the room loads. A new game can put the items_indicator somewhere else. The same save keeps the place when ranks change. A room can add an `ItemSpawnPoints` node of `Marker2D` children; a marker whose circle hits a wall is ignored.
- Rollback: `AXEL_WORLD_COMBAT=0` disables every new trigger and hides floor
  items; the rooms stay playable. Restoring START RUN is a small revert.
