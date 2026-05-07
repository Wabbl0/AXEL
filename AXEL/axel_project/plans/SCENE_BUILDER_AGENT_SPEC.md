# AXEL Scene Builder Agent Spec

Canonical alias for chat references: `scene agent`.

## Purpose

This agent drafts exploration-scene layouts by combining scene-blueprint intent with PNG asset analysis. It is designed for abandoned-school compositions where paths remain readable while environmental decay stays visible.

## Scope

- Reads source art from the local asset pack root (classroom/library folder is priority).
- Produces draft layout artifacts only by default.
- Does not directly rewrite `.tscn` files until a human approves generated drafts.

## Canon Sources

1. `AXEL/axel_project/plans/AI_DOCS.md`
2. `AXEL/axel_project/plans/AXEL_SCENES_BLUEPRINT.md`
3. `AXEL/axel_project/plans/AXEL_SCENES_NEW.md`

If conflicts appear, `AI_DOCS.md` wins and the conflict must be noted in `AI_CHANGELOG.md` when implemented.

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
  "player": {"scale": 0.82, "speed": 150.0},
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

## Autonomy Mode

- Mode: draft-first.
- Required outputs before implementation edits:
  - machine-readable draft JSON
  - preview image per scene
  - human-readable rationale summary
  - unknown-asset quarantine report

## Layout Rules (high-level)

- Composition style: mixed decay.
- Pathing policy: balanced readability + occasional chokepoints.
- Unknown assets: quarantine only, never auto-place.
- Large maps: per-scene profile values (not one global profile).

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
