# AXEL Scene Builder Agent Spec

Canonical alias for chat references: `scene agent`.

## Purpose

This agent drafts exploration-scene layouts by combining scene-blueprint intent with PNG asset analysis. It is designed for abandoned-school compositions where paths remain readable while environmental decay stays visible.

## Scope

- Reads source art from the local asset pack root (classroom/library folder is priority).
- Produces draft layout artifacts only by default.
- Does not directly rewrite `.tscn` files until a human approves generated drafts.

## Canon Sources

1. `AXEL/axel_project/plans/core/AI_DOCS.md`
2. `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
3. `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md` (index/TOC — links to per-arc files `AXEL_SCENES_ARC1.md` … `AXEL_SCENES_ARC8.md`)

If conflicts appear, `core/AI_DOCS.md` wins; note the conflict in the implement chat or `core/AI_CHANGELOG.md` on `update docs`.

## Agent Pipeline

1. Asset scan
2. Asset classification
3. Scene draft synthesis
4. Path and profile validation
5. Draft review bundle generation
6. Optional scene patch generation (approval gate required)

## Data Contracts

### Asset Catalog Record

```json
{
  "id": "classroom_and_library_singles_shadowless_48x48_40",
  "source_path": "C:/.../Classroom_and_Library_Singles_Shadowless_48x48_40.png",
  "width": 48,
  "height": 48,
  "alpha_coverage": 0.56,
  "bbox": [2, 1, 45, 47],
  "aspect_ratio": 1.0,
  "class_label": "locker",
  "confidence": 0.91,
  "placement_role": "wall_prop"
}
```

### Layout Draft Record

```json
{
  "scene_id": "scene_2",
  "scene_name": "Corridor",
  "profile": "corridor_large",
  "background_texture_size": [2400, 1500],
  "fit_mode": "cover",
  "camera_mode": "static_locked",
  "player": {"scale": 3.0, "speed": 362.0},
  "path_band": {"x0": 320, "x1": 960, "y0": 430, "y1": 660},
  "placements": [
    {
      "asset_id": "locker_single_48",
      "x": 640,
      "y": 284,
      "z": 2,
      "rotation": 0.0,
      "scale": 1.0,
      "tag": "highlight_candidate"
    }
  ],
  "validator": {"path_clear": true, "notes": []}
}
```

- `background_texture_size`: source PNG width/height in pixels (from import metadata).
- `fit_mode`: `cover` (fill viewport, may crop) or `contain` (letterbox; camera auto-zooms in when art is smaller than window).
- `camera_mode`: `static_locked` (default for new imports — one legal center, no pan) or `movable_follow` (2D follow clamped inside art rect).

## Exploration Scene Template (mandatory for new PNG scenes)

New exploration `.tscn` files MUST use the shared background + camera pipeline. Do **not** hand-tune `limit_*` or `fixed_x`. Do **not** embed noir/scanline/CRT overlays (post-FX stays on `AxelPostFxStack`).

### Scene tree

```
Root (Node2D + scene script)
├── WalkableWorld (Node2D)
│   ├── Background (Sprite2D, centered=false, z_index=-100, script: `locked_exploration_background.gd`, `metadata/_edit_lock_ = true`)
│   └── EnvironmentColliders (Node2D) — texture-pixel space; sync on layout_applied
├── Camera2D — script: res://scenes/core/background_camera_controller.gd
├── Player (CharacterBody2D under WalkableWorld/Player for new scenes — see migration note)
├── TopDialogueOverlay (instanced)
└── InteractPromptOverlay (instanced)
```

**Dialogue:** Use the instanced `TopDialogueOverlay`; player movement stays unlocked. API and two-step advance (5× typing boost, then press to scramble next line or CRT off): `plans/core/AI_DOCS.md` § Style and FX. Multi-line: `show_lines([...])`. Smell→locker swap: `cancel_pending_line()` → `type_line()` → `await_line_advance()` → `hide_line()`.

### Camera2D exports (`BackgroundCamera`)

| Export | Default | Purpose |
|--------|---------|---------|
| `background_path` | — | `NodePath` to `WalkableWorld/Background` |
| `fit_mode` | `cover` | `BackgroundLayout.FitMode` |
| `camera_mode` | `static_locked` | Enable `movable_follow` only when designer needs pan |
| `margin_px` | `0` | Inset art rect for CRT trim |
| `target_path` | — | Follow target (`WalkableWorld/Player` on new scenes) |
| `background_y` | `0` | Vertical offset (top-left anchor) |
| `follow_smoothing` | `5` | Movable follow lerp |
| `max_auto_zoom` | `4` | Cap auto-zoom when art is smaller than window |
| `static_center` | `(inf, inf)` | Optional fixed center for `static_locked` (art center when unset) |

Minimum supported art: prefer PNGs at least as large as the project window (1400×900) on both axes when using `contain`; smaller art relies on auto-zoom (capped by `max_auto_zoom`).

### `_ready()` call order

1. **Layout** — `BackgroundLayout.apply(sprite, viewport, fit_mode, background_y)` → apply scale/position to `Background` (also re-applies editor lock via `apply_to_sprite`).
2. **Colliders** — sync `EnvironmentColliders` position/scale to match background (connect to `Camera2D.layout_applied` or call from scene script).
3. **Camera** — `BackgroundCamera.apply_limits(...)` (automatic when `background_path` is set on the controller; runs in `_ready` + deferred pass).

When using the controller script with `background_path` wired, steps 1 and 3 run on the camera node; the scene script only needs collider sync:

```gdscript
func _ready() -> void:
	$Camera2D.layout_applied.connect(_on_background_layout_applied)

func _on_background_layout_applied(scale_factor: float, bg_position: Vector2, _world_rect: Rect2) -> void:
	_sync_environment_colliders(scale_factor, bg_position)
```

### QA smoke (new scenes)

After `_ready`, headless smoke MUST call `QaCanonValidators.collect_background_camera_findings(root, scene_path)` — asserts the camera view does not extend outside the computed art rect. Also `collect_background_editor_lock_findings` — exploration `Sprite2D` backgrounds must carry `metadata/_edit_lock_`.

### Playtest scene variants (optional)

When a shipped scene has a long intro or setup sequence, add an **inherited** child `.tscn` that instances the canonical scene and overrides only playtest flags (e.g. `skip_intro = true` on the root script). Do **not** duplicate the full scene tree. Example: `1.1_SchoolExterior_Playtest.tscn` → instances `1.1_SchoolExterior.tscn`. Layout edits belong on the base scene; child overrides are for playtest-only deltas.

## Window resolution and aspect (project-wide)

Window size/aspect is global in `project.godot`: base `1920×1280` (true 3:2) with `content_scale_aspect=1` (Keep). The window can be any resolution; gameplay stays 3:2 and auto-letterboxes. New scenes do **not** need a per-scene `design_viewport` — they inherit the global base. `scenes/core/exploration_viewport.gd` is inert (kept so 1.1 / 1.2 still load) and no longer resizes the OS window.

## Deferred migration — Arc 1 scenes 1.1 / 1.2

Do **not** retroactively rewire `1.1_SchoolExterior.tscn` or `1.2_Corridor.tscn` beyond approved deltas without an explicit approval gate. **Already done (approved):** per-scene `ExplorationViewport` window sizing. **Still deferred:** When migrated later:

1. Move player physics/follow target to world space under `WalkableWorld/Player` (replace `PlayerLayer` screen-space workaround).
2. Keep player drawn above noir via documented `z_index` / canvas layer order — not by moving the player off-world.
3. Replace `camera_follow_vertical.gd` + manual limits with `background_camera_controller.gd`.
4. Remove hand-tuned `fixed_x`, `limit_top`, `limit_bottom` values.

## Autonomy Mode

- Mode: draft-first.
- Required outputs before implementation edits:
  - machine-readable draft JSON
  - preview image per scene
  - human-readable rationale summary
  - unknown-asset quarantine report

## Cleanup Policy (MUST FOLLOW)

- When the user explicitly confirms a scene is complete, `scene agent` MUST remove ephemeral debug artifacts created during iterative look-dev (for example ad-hoc filter preview sets, one-off comparison renders, and their `.import` sidecars) from `tools/scene_builder/output/`.
- Keep canonical draft pipeline outputs unless the user asks to purge them:
  - `layout_drafts/*.json`
  - validation/review contracts under `output/*.json` and `review_notes.md`
- Prefer deleting only clearly non-pipeline temporary assets first, then report exactly what was removed.

## Layout Rules (high-level)

- Composition style: mixed decay.
- Pathing policy: balanced readability + occasional chokepoints.
- Unknown assets: quarantine only, never auto-place.
- Large maps: per-scene profile values (not one global profile).

## Canonical Filename Invariant (MUST FOLLOW)

The scene agent MUST always target the canonical numbered `.tscn` file for a
scene, never a simplified alias. This prevents producing duplicate placeholder
files alongside the canonical one and silently desyncing the project.

Rules:

1. Canonical filename pattern is `<arc>.<index>_<Name>.tscn` (for example
   `1.2_Corridor.tscn`, `6.1_Classroom.tscn`, `8.6_Epilogue.tscn`).
2. Scenes live under their `Arc_<N>/` folder (or `Endings/`, `Main_Menu/` for
   the special prefixes `8.x` and `0.x`).
3. When generating output for a known scene, the agent MUST:
   - resolve the canonical filename + folder before writing,
   - overwrite the existing placeholder at the canonical path, and
   - never create or overwrite a non-canonical alias such as `Corridor.tscn`.
4. The authoritative resolution map lives in
   [tools/scene_builder/layout_planner.py](../tools/scene_builder/layout_planner.py)
   as `CANONICAL_BY_SCENE_ID` plus the section-number heading parser. The
   blueprint `### <section> \`<file>\` (\`<scene_id>\`)` heading is parsed to
   build the canonical name, and explicit overrides in `CANONICAL_BY_SCENE_ID`
   take precedence when set.
5. If a scene has no canonical entry yet (e.g. library), the planner MUST emit
   an `UNCANONICALIZED_*` flag and an `arc_dir` of `UNRESOLVED` instead of
   silently writing a non-canonical file.
6. The patch-interface `target_scene_path_hint` MUST include the Arc folder, in
   the form `res://scenes/<arc_dir>/<canonical_file>`.

## Runtime Entry Points

- `tools/scene_builder/asset_classifier.py`
- `tools/scene_builder/layout_planner.py`
- `tools/scene_builder/path_validator.py`
- `tools/scene_builder/preview_renderer.py`

## Suggested Commands

```bash
python tools/scene_builder/asset_classifier.py
python tools/scene_builder/layout_planner.py
python tools/scene_builder/path_validator.py
python tools/scene_builder/preview_renderer.py
```

For multi-folder passes, set semicolon-separated folders:

```bash
SCENE_BUILDER_SOURCE_ROOT=<root> SCENE_BUILDER_PRIORITY_DIRS="dir_a;dir_b;dir_c" python tools/scene_builder/asset_classifier.py
```
