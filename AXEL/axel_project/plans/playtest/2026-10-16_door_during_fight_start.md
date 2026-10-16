# Door during fight start (1.2 → 1.4 bounce)

## Bug

After a fight starts in `1.2` (fight intro lines, then combat wipe), Mike could still reach the right `ExitTrigger`. `1.4` loaded, combat then opened from `1.4`, and the win sent Mike back to `1.2` (the fight's return room). It looked like the door "teleports back to 1.2".

## Fix

- `ExplorationRoom.begin_scene_change` refuses while `fight_is_starting()` (`AxelWorld.is_fight_starting()` and `AxelRun.is_in_encounter()`). This covers every room door.
- `1.2` / `1.4` exit triggers skip early too, so no stale spawn side or arrival t is written.

## Real cause (found after playtest of 2.1.2)

The bounce still happened at 2560×1440 fullscreen, with or without a fight. On the first physics frames of `1.4`, its left `ExitTrigger` is still at its old, not-yet-resized physics spot. At 2560×1440 that spot overlaps the Player node, and the trigger started armed, so `1.4` sent Mike straight back to `1.2`. At 1920×1280 the old spot happens not to overlap.

Fix: `1.4` (`ExitTrigger`, `CafeteriaExitTrigger`) and `1.2` (`ExitTrigger`) start disarmed. `_arm_exit*_after_settle` wakes the colliders, waits two physics frames, then runs the usual 0.15s grace before arming. Regression: `tools/qa/door_arrival_bounce_check.gd` (1.2 → 1.4 → 1.2 at seven window sizes, including 2560×1440 and portrait).

## Checks

Standard checks plus `door_arrival_bounce_check`, `continue_exit_spawn_check`, `interact_arrival_check`, `pause_map_restore_check`, `basement_route_check`, `world_combat_roundtrip_check`, `world_combat_loop_check`, `corridor_right_hint_check`, `basement_right_hint_check`: all pass.
