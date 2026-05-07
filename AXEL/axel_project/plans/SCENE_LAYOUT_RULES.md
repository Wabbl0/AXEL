# AXEL Scene Layout Rules

## Goal

Keep scenes visibly abandoned, looted, broken, and rotting while preserving readable movement flow for the player.

## Core Composition

- Build from a recognizable institutional base (classroom rows, corridor wall props, library shelf blocks).
- Disrupt structure with decay clusters (fallen props, tilt offsets, missing symmetry).
- Keep focal narrative props (locker, desk, board, graffiti) readable near primary camera attention.

## Pathing Policy (Balanced)

- Maintain one clear primary route from entry region to exit/interaction region.
- Allow occasional narrow chokepoints to increase tension.
- Never block the route with hard obstacles.
- Place heavier debris on side lanes and corners first.

## Decay and Chaos

- Use clustered clutter, not uniform scatter.
- Prefer edge and wall accumulation for debris/trash.
- Keep center-lane clutter sparse unless the scene explicitly calls for pressure.

## Placement Roles

- `wall_prop`: lockers, cabinets, mounted boards, wall decals.
- `floor_anchor`: desks, shelf islands, teacher furniture.
- `floor_clutter`: debris, trash, broken fragments.
- `focal_prop`: interactive or memory-important item.

## Large Scene Profiles

Large scenes use per-scene tagged profiles:

- `corridor_large`: player scale `0.82`, speed `150`
- `classroom_large`: player scale `0.86`, speed `160`
- `library_large`: player scale `0.78`, speed `145`
- `default`: player scale `1.00`, speed `180`

## Unknown Asset Handling

- If classification confidence is below threshold, move asset to quarantine list.
- Quarantined assets are excluded from auto-placement.
- Quarantine report must include filename and top candidate classes.

## Blueprint Reconciliation

- Scene intent comes from `AXEL_SCENES_BLUEPRINT.md`.
- Narrative tone and canon come from `AI_DOCS.md`.
- If a requested scene composition conflicts with path safety, path safety wins and the draft includes a note.

## Review Bundle Requirements

Each draft set must include:

- Placement JSON per scene
- Preview image per scene
- `review_notes.md` that explains:
  - why each focal cluster exists
  - where chokepoints are and why
  - what was quarantined
