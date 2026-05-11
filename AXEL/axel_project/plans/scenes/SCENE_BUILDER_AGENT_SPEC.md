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
3. `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md`

If conflicts appear, `core/AI_DOCS.md` wins and the conflict must be noted in `core/AI_CHANGELOG.md` when implemented.

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
