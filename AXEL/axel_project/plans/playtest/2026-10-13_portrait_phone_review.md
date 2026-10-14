# Portrait phone review (2026-10-13)

Shots: every scene's opening frame at iPhone 15 portrait (1179×2556), before and after the narrow-screen zoom. They're on the private "AXEL Phone Shots" page. Local PNGs are in `out/captures/phones/before|after/` and are not committed.

## What changed (built 2026-10-13)
- On screens narrower than 1920×1280, rooms with a locked camera and a follow target now keep the room's height on screen. Mike keeps the same size relative to the screen height, and the camera pans left and right with him (`BackgroundLayout.apply(keep_height)`, `BackgroundCamera.keeps_height()` / `_follow_x`). Wider screens are unchanged.
- The whole picture still shows at 1.415:1 or wider for the 3508×2480 rooms, and at 1.5:1 or wider for 1.2 (2400×1500).
- Memory pictures (no target) still show whole.
- 1.2 Corridor's camera now targets Mike.
- AxelWorld's item-placement probe uses the same fit.
- Check: `tools/qa/narrow_zoom_check.gd`.

## Verdict per scene (portrait, after)
| Scene | Verdict |
|---|---|
| Main menu, Saves, Options, Credits | OK |
| 1.2, 1.4, 2.1, 2.3, 3.1, 4.1, 5.1 rooms | OK now: Mike is full size and the camera pans |
| Memories 2.2, 3.2, 4.2, 5.2 | Whole picture in a thin strip, by choice |
| 1.3 Locker hub / map | OK, fills the screen |
| 1.1 School exterior | Already a panning room. Needs a look on a phone |
| 2.4 Classrooms | Broken in portrait: Mike floats high in a dark area. It's a cover-fit panning room, not touched by this change |
| Combat | Fits but small: the board is about a third of the screen height, with big black bands |

## Open items
1. Fix the 2.4 portrait framing.
2. Decide on combat in portrait: a portrait HUD layout, or lock combat to landscape.
3. Arrow hints in 1.2 and 1.4 sit at the screen's right edge, not the room's. Check that this still reads right while panning.
4. Doors at the room edges are off-screen until Mike walks toward them. Playtest whether that's clear enough.
5. ~~Replace the batch E "static-locked rooms are always contain" rule in `AI_DOCS.md` / `SCENE_BUILDING.md`.~~ Done 2026-10-14.
