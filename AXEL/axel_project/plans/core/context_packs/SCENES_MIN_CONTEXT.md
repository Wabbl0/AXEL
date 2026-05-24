# Scenes Min Context

**Prefix:** `scenes:` | **Unlock for:** combat, narrative, visual_style

## Pointers (on demand)

`SCENE_BUILDER_AGENT_SPEC.md` · `AXEL_SCENES_BLUEPRINT.md` · `SCENE_LAYOUT_RULES.md` · one `AXEL_SCENES_ARC*.md` per task · `PLAYTEST_DEBUG_COLLISIONS.md`

**Runtime:** `scenes/Arc_*/*.tscn` · `tools/scene_builder/layout_planner.py`

## Invariants

- Canonical filenames only (e.g. `1.2_Corridor.tscn`) — never `Corridor.tscn` aliases
- Scene complete → purge `tools/scene_builder/output/layout_previews/` temps
- Post-FX: autoload owns stack — no noir/scanline/CRT in overworld `.tscn`
- One arc file per task; `@`-mention `exports/Drawings/*` (index-excluded)

## Hard gates

- **Lock:** no combat catalog/RTP, no `game.html` flags unless unlocked
- **QA:** scene smoke / movement audit opt-in via `qa` only
