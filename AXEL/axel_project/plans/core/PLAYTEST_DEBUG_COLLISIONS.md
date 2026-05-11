# Playtest collision debug overlay

Runtime-only helper kept **out of AXEL palette** so collision / interact geometry is readable while playtesting.

## What it does

Autoload **`PlaytestCollisionDebug`** scans the scene tree for `CollisionShape2D` and `CollisionPolygon2D` and draws neon **cyan/teal** outlines (`outline_color`) on **`CanvasLayer` 2000** so overlays sit above typical gameplay layers (`PlayerLayer` uses 100).

- **Runs only when** `OS.is_debug_build()` is true (editor / debug builds). Exported release builds disable the overlay in `_ready()`.
- **Toggle:** **`F7`** — show/hide outlines without restarting.

## Changing color or width

Inspect the singleton in Remote scene tree (`/root/PlaytestCollisionDebug`) or edit `@export`:

- [`scripts/debug/playtest_collision_debug.gd`](../scripts/debug/playtest_collision_debug.gd) — `outline_color`, `line_width`, `debug_canvas_layer`

## Engine collision debug vs this overlay

Project View menu **Visible collision shapes** can still tint built-in diagnostics; this overlay is independent and intentionally uses cyan so it stays distinct from red/black/white gameplay.
