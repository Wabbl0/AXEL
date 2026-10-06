# F6 fresh test start

## Goal

Pressing F6 on a room plays like a first-time player: every tutorial card shows, the Guide stays locked until the first fight ends, and walking past the locker in `1.2` starts the tutorial fight. The real saves and real profile are never touched.

## Already in place

- `AxelSaves.maybe_begin_play_scene()` starts a new run in `user://saves_play_scene/` (not the 3 slots), so `tutorial_fight_done` is false.

## Change

- `AxelProfile.begin_play_scene_profile()` switches to a fresh `user://axel_profile_play_scene.cfg`. It stays on for the whole F6 run, also after Quit to Title.
- `maybe_begin_play_scene()` calls it after the play-scene run starts.
- The temp file is deleted when the game closes and again on the next start.
- `end_play_scene_profile()` restores the earlier profile (used by the check).

## Check

`tools/qa/play_scene_profile_check.gd`
