# 1.3 locker: show that Esc leaves

**Note:** A new player did not know how to leave the 1.3 locker.

**Fix (shipped):** `1.3_LockerHub.tscn` has a red VT323 `[ESC]` label (`ExitLayer/EscHint`) in the top-left corner. The red `X` stays bottom-right. `1.3_LockerHub.gd` scales the label with `UiViewportScale` and hides it whenever Esc would not leave the room: during the first-visit lines, while the map is open (Esc closes the map), and during the scene change.

**Check:** `tools/qa/locker_map_travel_check.gd`, `tools/scene_smoke_check.gd`.
