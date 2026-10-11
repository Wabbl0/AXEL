# Combat: E speeds up in two steps

**Note:** E during a spin jumped straight to an 8× rush, which felt like skipping.

**Fix (shipped):** `CombatPace` keeps a rush level (`RUSH_STEPS` = 1×, 3×, 8×). In a spin, a cascade, a power, the Vice Round, free-spin autoplay or the win burst, the first `interact` gives 3× (`CombatPace.step_rush()`) and the second gives 8×. It still clears when the game next waits. The loss shatter still goes straight to 8× (`set_rush(true)`). Combat speed from Options still multiplies on top (fast: 6×, then 16×).

**Check:** `tools/qa/combat_pace_check.gd`.
