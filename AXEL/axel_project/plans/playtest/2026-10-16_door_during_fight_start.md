# Door during fight start (1.2 → 1.4 bounce)

## Bug

After a fight starts in `1.2` (fight intro lines, then combat wipe), Mike could still reach the right `ExitTrigger`. `1.4` loaded, combat then opened from `1.4`, and the win sent Mike back to `1.2` (the fight's return room). It looked like the door "teleports back to 1.2".

## Fix

- `ExplorationRoom.begin_scene_change` refuses while `fight_is_starting()` (`AxelWorld.is_fight_starting()` and `AxelRun.is_in_encounter()`). This covers every room door.
- `1.2` / `1.4` exit triggers skip early too, so no stale spawn side or arrival t is written.

## Checks

Standard checks plus `basement_route_check`, `world_combat_roundtrip_check`, `world_combat_loop_check`, `corridor_right_hint_check`, `basement_right_hint_check`: all pass.
