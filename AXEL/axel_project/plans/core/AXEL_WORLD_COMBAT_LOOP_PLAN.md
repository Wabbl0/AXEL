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
- All item ranks start Common; picking up in one area upgrades the rooms you
  have not touched yet.
- The locker is equip-only. `START RUN` is gone.
- The school map shows unvisited rooms dark and refuses to travel there.
- A full-screen wipe plays on the way into every fight.
- Winning puts you back in the room you left, on the spot you left.
- Losing still writes the tombstone and returns to the title (permadeath).

## Layer rule

Narrative decides *when* a fight starts. `AxelRun` is still the only thing that
starts one, and combat still never reads a story flag. The new autoload
`AxelWorld` sits on the narrative side of that line.

## Areas (6 written areas → live rooms)

| Area id | Rooms | Floor items | Step fights |
| --- | --- | --- | --- |
| `halls` | `1.2_Corridor`, `2.4_ClassroomsCorridor` | 2 + 1 | yes |
| `cafeteria` | `2.1_Cafeteria` | 3 | yes |
| `kitchen` | `2.3_Kitchen` | 2 | yes |
| `lounge` | `4.1_TeachersLounge` | 2 | yes |
| `classroom` | `5.1_Classroom` | 2 | yes |
| `basement` | `1.4_BasementDoor` | 1 | yes |

`1.1_SchoolExterior` and `3.1_Backyard` are outdoors: no step fights, no floor
items. Greybox rooms (`6.x`, `5.3`, `5.4`) have no Player node, so they get no
step fights either — only their lore pickups start fights.

## Rank progression (AXEL_notes §2.3)

Every area starts at Common. The first time you take an active item from an
area, that area is *engaged* and its rank freezes; every area that is neither
engaged nor cleared moves up one rank (cap Legendary). Clearing an area (all
its floor items taken) upgrades the untouched areas again.

Item ids resolve as `TIER-FAMILY` from the live `.tres` files. Each area owns a
short family list; the roll walks down from the area rank until an id exists.

## Numbers (tuning constants at the top of `axel_world.gd`)

- `STEP_CHANCE_BASE` `0.001` (0.1% per 8 px step)
- `STEP_CHANCE_PER_CLEARED_AREA` `0.0015`
- `STEP_CHANCE_MAX` `0.01` (1% once all six areas are cleared)
- `STEP_GRACE_AFTER_FIGHT` `200` steps with no step fight after any fight
- `MAX_STEP_FIGHTS_PER_VISIT` `2` per room visit

## Implementation steps

1. `combat/scripts/run_state.gd` — add `world_encounter`, `world_reason`,
   `world_return_scene`, `world_return_tex_x/y`, `world_return_tex_valid`,
   `world_encounter_index`; serialise them.
2. `scripts/autoload/axel_run.gd` — add `enter_world_encounter()`. It plays the
   wipe, switches music, and loads `combat/combat_run.tscn`. World encounters do
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
6. `combat/scripts/combat_run.gd` — clear the wipe once the board is up.
7. `exports/GameManager.gd` — `visited_rooms` set plus `mark_room_visited()` /
   `has_visited()`; save body carries `visited_rooms` and the `AxelWorld` block.
8. `scripts/Player.gd` — one call to `AxelWorld.register_walk_step()` next to
   the existing `AxelEventFx.register_walk_step()`.
9. `scenes/ui/locker_interior.gd` + `scenes/Arc_1/1.3_LockerHub.gd` — remove the
   `START RUN` button, the act line, and the pre-run warning. Keep the LOCKER
   button, the equip grid, and the C1/C2/C3 starter grant.
10. `scenes/Arc_1/1.3_SchoolMap.gd` — travel needs `GameManager.has_visited()`.
    Unvisited rooms get a dark card, a `?????` label, and no click.
11. Memory stills — `2.2_CafeteriaMemory.gd`, `3.2_BackyardMemory.gd`,
    `4.2_TeachersMemory.gd`, `5.2_ClassroomDesk.gd`: leave through
    `AxelWorld.start_memory_fight()` instead of `change_scene_to_file`. `5.2`
    fights but stays *not* a 5/5 memory.
12. Lore pickups — `2.3_Kitchen.gd` (flashlight), `4.1_TeachersLounge.gd` (key),
    `scenes/core/greybox_choice.gd` (shovel, name): fight after the line, once
    per flag.
13. Docs — name the six areas in the catalog plan's Area / Rarity Progression
    section, gate `L-G Iron Lung` to the basement, add `AxelWorld` to `AI_DOCS`,
    log the D7 replacement in `AI_CHANGELOG`.
14. `tools/qa/world_combat_loop_check.gd`, `tools/qa/world_item_scatter_check.gd`,
    `tools/qa/world_combat_roundtrip_check.gd` (new) — headless checks for the
    area table / rank curve / save round trip, for floor items landing on
    reachable floor in every indoor room, and for the full room → fight → same
    room → same spot trip.

## Acceptance criteria

- Walking indoors sometimes starts a fight; `1.1` and `3.1` never do.
- Flashlight / key / shovel / name each start exactly one fight, ever.
- Every memory still ends in a fight. The locker map paper (`scene_3`) does not.
- Floor items show `[E]`, join the locker on pickup, and start a fight.
- The first area's floor items are Common; untouched areas read one rank higher
  after the first pickup.
- The locker panel has no START RUN.
- Unvisited map rooms are dark and unclickable; visiting once unlocks them.
- A wipe plays before each fight; a win returns to the same room and spot.

## Manual test checklist

1. New game → walk `1.2` until a fight starts → win → you are back in `1.2`
   where you stood.
2. Open the map before visiting `2.3`: kitchen is dark and dead. Walk there,
   reopen: it works.
3. Take the floor item in `2.1` → fight → win → the `4.1` floor item reads one
   rank above Common.
4. Play the cafeteria memory to the end → fight starts after the last line →
   win → back in `2.1`.
5. Open the locker (equip grid only, no START RUN), then walk `1.1` and `3.1`
   for a while: no fight.

## Found while building

- Repositioning the player (spawn placement, cover-fit, post-fight return) used
  to feed the step counter, so entering a room banked hundreds of "steps" at
  once and could start a fight immediately. `Player.gd` now drops any jump of
  64 px or more instead of counting it. This also fixes the same flaw in the
  existing CRT pulse cadence.
- One area only ever grants one rank upgrade to the untouched areas — the first
  pickup there *or* clearing it, whichever comes first. Counting both would have
  doubled the curve.
- Floor spots are searched on both axes and dodge interact zones as well as
  walls; if a room's whole floor is door boxes (`2.4`), the second pass settles
  for open floor that shares a zone rather than putting the item in a wall.

## Risks and rollback

- Step rate is a guess; tune the five constants after one playtest.
- `2.4_ClassroomsCorridor`'s single floor item shares a door box, so two `[E]`
  chips can show there. Adding authored spawn points to that room fixes it.
- Save bodies gain two blocks. Missing keys default, so old slots still load.
- Return placement runs a few frames after the room settles; if a room ever
  moves the player later than that, the spot can be off by a step.
- Floor-item spots are picked at runtime from the room's floor line and stored
  in the save. Add an `ItemSpawnPoints` node with `Marker2D` children to a room
  later if a spot looks wrong.
- Rollback: `AXEL_WORLD_COMBAT=0` disables every new trigger and hides floor
  items; the rooms stay playable. Restoring START RUN is a small revert.
