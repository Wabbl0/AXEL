# Editor collision debug colors

Editor-only collision shape colors kept **out of AXEL palette** so collision geometry is readable during scene editing without appearing at runtime.

## How it works

Project Settings under `debug/shapes/collision/` control the fill color and outline of `CollisionShape2D` and `CollisionPolygon2D` nodes **in the 2D editor viewport**. These shapes are invisible at runtime by default — they only appear during gameplay if you explicitly enable **Debug > Visible Collision Shapes** from the editor menu bar (off by default).

Current settings (`project.godot`):

- `shape_color` = `Color(0.0, 0.92, 0.95, 0.42)` — bright cyan, stands out against AXEL red/black/white palette.
- `contact_color` = `Color(0.0, 1.0, 0.5, 0.8)` — green for physics contacts.
- `draw_2d_outlines` = `true` — draws a solid outline around each collision shape.

## Changing colors

Edit values under **Project > Project Settings > Debug > Shapes > Collision** in the Godot editor, or directly in `project.godot` under `[debug]`.

## Legacy runtime overlay (disabled)

The previous `PlaytestCollisionDebug` autoload (`scripts/debug/playtest_collision_debug.gd`) drew cyan outlines at runtime during debug builds. This was removed from the autoload list because it cluttered the running game view. The scripts remain in the repo at `scripts/debug/` for optional re-enablement but are inactive by default.

## Scene 1.2 corridor borders

Tune under `WalkableWorld/EnvironmentColliders` in the **2D editor** — move each `StaticBody2D` (gizmo = collision center; shapes stay at `(0,0)`). Positions are **texture-pixel** coordinates (~2400×1500 space), not small viewport numbers. At play, `1.2_Corridor.gd` rescales/repositions colliders with the cover-fit background; edits made at scene root or with large shape offsets will desync after F6. Use **Debug → Visible Collision Shapes** (F7) while playing to verify alignment with the drawing.
