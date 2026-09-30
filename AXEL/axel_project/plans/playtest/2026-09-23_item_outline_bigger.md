# Plan: Bigger red outline on the items_indicator

Plan only. Do not implement in the planning chat.

## What you asked

Make the red outline around the overworld item marker larger.

## What the game does now

- The floor marker is the items_indicator (`scenes/world/ItemMarker.tscn`).
- `scenes/fx/marker_outline_style.gd` uses one `SPREAD` of `12` for the items_indicator’s red glow and for the memory blob’s white halo.
- The shader `scenes/fx/memory_outer_glow.gdshader` clamps `spread` to `28`.
- The items_indicator stays white. The memory blob is a separate note (grey fill, white outline).

## Locked choices

- Split the shared spread. Item spread becomes `20`. Memory spread stays `12`.
- Do not change the items_indicator sprite size, the drop shadow, or the red color (`Color(0.9, 0, 0)`).
- Do not change the memory blob’s color in this note.

## Steps

1. In `marker_outline_style.gd`, replace `SPREAD` with `ITEM_SPREAD := 20.0` and `MEMORY_SPREAD := 12.0`.
2. `apply_item_halo` uses `ITEM_SPREAD`. `apply_memory` uses `MEMORY_SPREAD`.
3. Leave the shader cap at `28`. `20` is inside it.

## What you should see

The faint red edge around the items_indicator is wider. The items_indicator is still white. Memory markers do not grow.

## How to test

1. Walk to a floor item. Compare the red fringe to a memory blob in another room. Only the items_indicator’s fringe is larger.
2. No headless check draws the shader (`--headless` does not compile shaders). A windowed glance is the check.

## Risks

- If `20` is still too faint, the next step is a higher spread up to `28`, not a bigger items_indicator picture.

## When this ships

One changelog line. The memory color change is a separate note and must not be folded into this one.
