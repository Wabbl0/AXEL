# AXEL Canon Consistency Audit

Machine-readable visual/gameplay drift checks for default `qa agent` runs. Canon hierarchy: `../core/AI_DOCS.md` §3–§7; movement profiles: `../scenes/SCENE_LAYOUT_RULES.md`; scene intent: `../scenes/AXEL_SCENES_BLUEPRINT.md`.

## Command

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/qa/canon_consistency_audit.gd
```

- **Exit code:** always `0` (warn + recommend).
- **Stdout marker:** single line `CANON_AUDIT_JSON <json>` (parse after prefix).
- **Implementation:** `test/qa/canon_consistency_audit.gd` + `test/qa/qa_canon_validators.gd`.

## Scope (default)

| Scene | Checks |
| ----- | ------ |
| `res://combat/combat_test.tscn` | Scaffold unique nodes, duplicate CombatRoot grid stack, 5×5 GridUI cell count, scanline overlay |
| `res://scenes/Arc_1/1.1_SchoolExterior.tscn` | Player/camera/door contract, speed/scale profile |
| `res://scenes/Arc_1/1.2_Corridor.tscn` | Player/overlay contract, `corridor_large` speed/scale profile |

## Enforcement model

| Layer | Behavior |
| ----- | -------- |
| `canon_consistency_audit.gd` | Reports findings; never blocks QA by itself |
| `combat_test_scaffold_check.gd` | Hard gate: duplicate grid + missing scaffold → exit 1 |
| `check_combat_test_scaffold.py` | Pre-commit: missing markers + duplicate grid in `.tscn` text; `--staged` auto-strips inline CombatRoot grid overrides then re-validates |

## `CANON_AUDIT_JSON` schema (v1)

```json
{
  "schema_version": 1,
  "audit": "canon_consistency",
  "findings": [
    {
      "id": "combat.grid_duplicate",
      "severity": "major",
      "category": "COMBAT",
      "scene": "res://combat/combat_test.tscn",
      "evidence": "CombatRoot has 2× GridUI (expected 1)",
      "recommendation": "Remove duplicate grid/overlay nodes under CombatRoot; keep a single GridUI/GridManager stack."
    }
  ],
  "findings_count": { "blocker": 0, "major": 1, "minor": 0, "nit": 0 },
  "by_category": { "COMBAT": 1 },
  "scenes_audited": ["..."]
}
```

### Finding fields

| Field | Required | Notes |
| ----- | -------- | ----- |
| `id` | yes | Stable slug, e.g. `movement.speed_profile` |
| `severity` | yes | `blocker` \| `major` \| `minor` \| `nit` |
| `category` | yes | Rubric taxonomy: `STYLE`, `LORE`, `COMBAT`, `CLARITY`, `REGRESSION`, `BUG`, etc. |
| `scene` | yes | `res://` path |
| `evidence` | yes | One-line fact for Technical findings |
| `recommendation` | yes | Actionable fix for Recommendations section |

## Severity mapping (warn + recommend)

| Severity | Typical signals | QA report |
| -------- | ----------------- | --------- |
| `blocker` | Scene missing, load/instantiate failure | Technical finding; separate gate may also fail |
| `major` | Duplicate combat grid, missing movement contract, scaffold node missing | Technical finding + recommendation |
| `minor` | Speed/scale profile drift, missing scanline, grid cell count | Technical finding + recommendation |
| `nit` | FallbackBody + sprite both visible | Optional polish recommendation |

Do **not** downgrade confidence tier solely because audit found issues. Only gate command failures or skip policy change confidence.

## QA run-log payload (`canon_audit`)

When ingesting audit output into `AXEL_QA_RUN_LOG.md`:

```json
"canon_audit": {
  "schema_version": 1,
  "findings_count": { "blocker": 0, "major": 7, "minor": 2, "nit": 0 },
  "by_category": { "COMBAT": 7, "CLARITY": 1, "STYLE": 1 },
  "findings": [
    { "id": "combat.grid_duplicate", "severity": "major", "category": "COMBAT", "evidence": "..." }
  ]
},
"playtest_commands": {
  "canon_consistency_audit": "pass"
}
```

`playtest_commands.canon_consistency_audit` is always `pass` when the command ran (exit 0). Findings live under `canon_audit`, not as command failure.

## Recommendations contract

When `canon_audit.findings` is non-empty, include **≥3** recommendations total (skill minimum), with at least one combat- and one movement-scoped bullet when both areas have findings. Each bullet: **evidence → impact → fix**.

Example:

- Duplicate `GridUI` under instanced `CombatRoot` → double grid render / wrong hit areas → remove override nodes; keep `combat_root.tscn` instance only.

## Related files

- `test/qa/README.md` — quick run instructions
- `plans/qa/AXEL_QA_REVIEW_RUBRIC.md` §Playtest-mode — default command list
- `.cursor/skills/axel-simulated-qa/SKILL.md` — agent output format
