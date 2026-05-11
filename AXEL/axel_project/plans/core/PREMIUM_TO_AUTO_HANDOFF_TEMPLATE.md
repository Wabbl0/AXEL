# Premium-to-Auto Handoff Template

Use this template for substantive AXEL planning responses that are intended for later execution by auto models.

## 1) Inferred Intent

- User-stated request:
- Inferred underlying goal:
- Assumptions inferred from current project state:

## 2) Canon and Guideline Alignment

- Alignment status: PASS / CONFLICT
- Sources checked:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md` (if combat touched)
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md` (if combat touched)
  - `AXEL/axel_project/plans/references/AXEL_notes.md` (if lore/style touched)
- Relevant invariants:
- Conflict details (if any):

## 3) Hard Conflict Gate (Only if conflict exists)

- Do not continue planning/execution until user picks one option.
- Present 2-4 options with trade-offs:
  1. Strict-canon path:
  2. Adapted variant:
  3. Explicit override path:
  4. Optional defer/no-change path:
- User-selected option:

## 4) Project Correlation and Impact Map

- Systems/subsystems affected:
- Reusable pipelines/agents involved (`scene agent`, `qa agent`, others):
- Candidate files likely to change:
  - `path/to/file_a`
  - `path/to/file_b`
- Cross-system side effects to monitor:

## 5) Auto-Model Implementation Tasks

Write ordered, executable steps that can be followed with minimal interpretation.

1.
2.
3.

## 6) Validation and Acceptance Checks

- Automated checks/tests:
- Manual verification:
- Acceptance criteria:
  - [ ]
  - [ ]

## 7) Risks and Fallback

- Key risks:
- Mitigations:
- Rollback/fallback path:

## 8) Explicit Blockers and Open Decisions

- Blocker 1:
- Blocker 2:

## 9) Ready-to-Execute Handoff Summary

- Scope boundary:
- Files expected to be touched:
- Verification required before completion:
- Post-implementation logging reminder:
  - Append implementation entry to `AXEL/axel_project/plans/core/AI_CHANGELOG.md`.
