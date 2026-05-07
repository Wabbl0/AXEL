# AXEL AI Docs

Persistent guidance for AI agents working in this repository. This file is the canonical memory layer for consistency across chats.

## 1) Purpose

- Keep implementation decisions consistent across exploration, narrative, and combat work.
- Prevent drift between design intent, code behavior, and visual/lore direction.
- Provide a stable hierarchy for conflict resolution when multiple docs differ.

## 2) Scope

Applies to changes in:

- `AXEL/axel_project/plans/*`
- `AXEL/axel_project/combat/*`
- `AXEL/axel_project/exports/*`
- `AXEL/html/*`
- `AXEL/axel_project/scenes/*`
- `AXEL/axel_project/scripts/*`

## 3) Canonical Source Hierarchy

When two sources conflict, resolve in this order:

1. This file: `AXEL/axel_project/plans/AI_DOCS.md`
2. `AXEL/axel_project/plans/AXEL_combat_implementation.md`
3. `AXEL/axel_project/plans/AXEL_combat_design.md`
4. `AXEL/axel_project/plans/AXEL_notes.md`
5. Prototype style/lore evidence in `AXEL/html/game.html`, `AXEL/html/styles_game.css`, `AXEL/html/styles.css`
6. Exported references in `AXEL/axel_project/exports/*` and `AXEL/axel_project/exports/moon_princess_files/*`

If you intentionally choose a lower-priority source for a task, record the reason in `AI_CHANGELOG.md`.

## 4) Architecture Split (Do Not Blur Layers)

### Narrative/prototype layer

- `AXEL/html/game.html` + `AXEL/axel_project/exports/game_data.json` define choice-based story flow, flags, memories, and ending logic.
- `AXEL/axel_project/exports/GameManager.gd` is the narrative runner model/reference.

### Combat layer

- `AXEL/axel_project/combat/scripts/combat_root.gd` orchestrates combat state and spin lifecycle.
- Combat is Moon Princess inspired, but implemented as native Godot scripts/resources.
- Files in `AXEL/axel_project/exports/moon_princess_files/*` are reference captures only, not authoritative runtime logic.

## 5) Combat Invariants

Keep these rules stable unless explicitly asked to redesign:

- Combat grid is 5x5 and driven through deterministic RNG patterns.
- Wins are line-based row/column runs of 3+ contiguous symbols (no flood-fill cluster wins for main resolution).
- Wild spawn rule: only winning lines of exactly 3 can spawn a wild in the middle cell.
- Multiplier progression is tied to cascade/drop progression, not arbitrary per-line increments.
- `combat_root.gd` remains the orchestration point for spin -> resolve -> cascade -> power -> checks.
- Princess/premium alias map is fixed:
  - `cigarette` -> Storm
  - `booze`/`alcohol` -> Star
  - `bloody hand` -> Love
- Terminology lock from notes:
  - Regular Free Spins = Trinity Run
  - SUPER Free Spins = later bonus mode
  - If a request says only "Free Spins", clarify intended mode before changing behavior.

## 6) Style and Tone Canon

Primary style direction:

- Palette baseline: black + blood red (`#ff0000`) + dark blood (`#4a0000`).
- CRT/scanline/glitch/shake aesthetics are core identity, not optional decoration.
- Typography center: VT323 (Space Mono may be used for supporting text where explicitly needed).
- UI and narrative mood: dread, guilt, memory corruption, morally uneasy wins.
- Big wins should read as unsettling/intrusive, not purely celebratory.

Known source conflict guidance:

- If symbol gameplay needs additional colors for readability, keep broader UI frame in AXEL palette and note exceptions.
- If any title strings differ (for example AXEL vs GUILT in legacy exports), prefer current project naming in active gameplay files and document transitional naming in changelog entries.

## 7) Lore/World Consistency

Keep these narrative anchors coherent across edits:

- Setting: decaying school, guilt-driven return, locker as hub/sanctuary.
- Core progression motifs: memories, key items (Flashlight/Key/Shovel/Name), basement confrontation.
- Axel identity reveal and ending logic remain central to branching outcomes.
- Cigarettes/lighter ritual and memory cues are recurring thematic devices.

## 8) Implementation Guardrails

- Treat plans as design truth; treat code as behavior truth; reconcile both before changing mechanics.
- Avoid introducing machine-absolute paths in shared gameplay code.
- Keep deterministic behavior for systems intended to be replayable/testable.
- Prefer additive, scoped changes over broad rewrites.
- When changing one subsystem, verify cross-effects on:
  - story flags/memories/endings
  - combat goals/economy
  - style/thematic presentation

## 9) Agent Workflow Requirements

For substantive AXEL requests:

1. Read this file first.
2. Check relevant source docs for the touched subsystem.
3. For long or multi-step work, provide a live progress feed in chat while executing.
4. Live progress feed should include:
   - current step
   - command/tool in use
   - files being checked/read
   - result/status so far
   - next step
   - stuck/not stuck
5. Implement changes.
6. Verify behavior (tests or explicit manual checks).
7. Append one entry to `AXEL/axel_project/plans/AI_CHANGELOG.md` if change was implemented.

## 10) Consistency Checklist (Quick)

Before finishing:

- [ ] Terminology and mechanics match current canon.
- [ ] No architecture-layer mixing without intent.
- [ ] Style/lore choices align with AXEL identity.
- [ ] Conflicts were resolved using hierarchy and documented.
- [ ] Implemented request was appended to `AI_CHANGELOG.md`.
