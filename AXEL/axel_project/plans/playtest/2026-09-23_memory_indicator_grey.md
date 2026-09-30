# Plan: Grey memory marker, white outline

Plan only. Do not implement in the planning chat.

## What you asked

The overworld memory indicator should be grey, with a white outline.

## What the game does now

- `scenes/fx/memory_indicator.gd` draws the blob from `memory_glow-Sheet.png` and a halo behind it.
- `scenes/fx/marker_outline_style.gd` tints the blob red (`MEMORY_SPRITE_COLOR = Color(0.9, 0, 0)`) and the halo white (`MEMORY_HALO_COLOR = Color(1, 1, 1)`).
- The marker sits on `PlayerLayer`, above the noir filter, so the grey will show as grey. Noir will not recolor it.
- The items_indicator uses the same style file for a red outline. That outline is a separate note.

## Locked choices

- Blob fill becomes a mid grey, `Color(0.55, 0.55, 0.55)`.
- The halo stays white. That is the outline.
- Do not change `indicator_scale` (`2.25`), `visual_offset`, or which rooms spawn a marker.
- Do not change the items_indicator’s red outline or its spread in this note.

## Steps

1. In `marker_outline_style.gd`, set `MEMORY_SPRITE_COLOR` to `Color(0.55, 0.55, 0.55, 1)`.
2. Leave `MEMORY_HALO_COLOR` white.
3. If item and memory spreads were split by the other note, do not merge them back. This note only changes the blob color.

## What you should see

Memory markers are grey shapes with a white fringe. They are no longer red blobs. Items_indicators stay white with a red fringe.

## How to test

1. Open a room with a memory (for example a still that still has its marker). The blob is grey and the edge is white.
2. Stand near a floor item. That marker is still the items_indicator, not grey.

## Risks

- A grey that is too dark disappears on the black floor. `0.55` is the starting fill. Do not drop it under `0.4` without looking at it in a room.

## When this ships

One changelog line. Update the memory-indicator sentence in `plans/core/AI_DOCS.md`.
