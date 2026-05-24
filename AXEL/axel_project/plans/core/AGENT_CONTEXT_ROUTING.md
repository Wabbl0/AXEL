# AXEL Agent Context Routing

Lightweight contract for new-chat context selection. Goal: load only the minimum canon needed for the active domain, reducing agent/API token use while preserving cohesion.

**Authority:** Routing behavior is defined here. Always-on governance (`.cursor/rules/axel-ai-docs-governance.mdc`) points agents to this file. Global hierarchy and hard conflict gate remain in `AI_DOCS.md` §3 and §10.

## 1) Bundles

| Bundle ID | Status | Context pack | Fast-path prefix |
|-----------|--------|--------------|------------------|
| `combat` | **Active** | `plans/core/context_packs/COMBAT_MIN_CONTEXT.md` | `combat:` |
| `scenes` | **Active** | `plans/core/context_packs/SCENES_MIN_CONTEXT.md` | `scenes:` |
| `narrative` | **Active** | `plans/core/context_packs/NARRATIVE_MIN_CONTEXT.md` | `narrative:` |
| `visual_style` | **Active** | `plans/core/context_packs/VISUAL_STYLE_MIN_CONTEXT.md` | `vfx:` (alias → `visual_style`) |
| `meta_process` | **Active** | None — `AI_DOCS.md` §3 + §15 + `CHAT_LANE_PROTOCOL.md` only | `meta:` |
| `qa_tools` | Reserved | See `AI_DOCS.md` §11–§12 + `.cursor/skills/axel-simulated-qa/SKILL.md` | — |

## 1b) Meta-process routing (no domain pack)

**Use when:** Agent workflow, API/token usage, governance/rules, routing docs, changelog policy, Cursor setup, git/process — **not** gameplay implementation in a domain.

**Fast-path:** `meta:` at message start → skip bundle classification and domain pack load.

**Keywords (any one → confident meta):** API usage, token budget, context routing, governance rule, agent process, chat lane, handoff, `.cursor/rules`, optimization, meta-process.

**Locks:** No domain packs unless user `unlock <bundle>`. No combat/scene/narrative/vfx implementation unless unlocked. Changelog only if docs/rules were edited.

**Not meta:** grid/spin/RTP, `.tscn` layout, flags/endings, shaders/CRT — route to domain bundles (§4–§7).

## 2) Startup flow (every new chat)

1. Check **fast-path prefix** on first line (§3, §1b). If `meta:`, apply §1b only. If domain prefix, load matching pack and skip keyword classification.
2. Else read `AI_DOCS.md` §3 (hierarchy) and classify the **first user message** (§1b, §4–§7).
3. On confident match: read the matching `*_MIN_CONTEXT.md` and apply that bundle’s strict lock.
4. On **low confidence**: stop substantive work; ask bundle question (§10). Do not assume a domain.
5. On **explicit unlock**: user may say `unlock scenes`, `unlock narrative`, `unlock visual_style`, `unlock combat`, or `unlock qa_tools` — load only named bundle(s) in addition to the primary bundle.

**After routing:** Prefer pack pointers over loading full unrelated `AI_DOCS.md` sections (e.g. skip §5 when scenes-locked, skip §6–§7 when combat-locked).

## 3) Prefix fast-path (manual override)

| Prefix | Bundle loaded |
|--------|---------------|
| `meta:` | `meta_process` (§1b — no domain pack) |
| `combat:` | `combat` |
| `scenes:` | `scenes` |
| `narrative:` | `narrative` |
| `vfx:` | `visual_style` |

Prefix must appear at the start of the first user message (optional leading whitespace). No `visual_style:` prefix — use `vfx:` only.

## 4) Keyword classification — `combat`

**Strong** (any one → confident): `res://combat/`, `combat_root`, `combat_test`, grid, reel, spin, cascade, symbol, wild, bankroll, stake, RTP, Trinity Run, SUPER Free Spins, item catalog, `C1`, equip, combat scaffold.

**Weak** (≥2, or 1 weak + combat path): balance/economy/tuning in combat context, deterministic seed for combat test.

**Not combat:** scene ids (`1.1`, schoolyard, corridor), flags/memories/endings, overworld post-FX unless combat UI.

## 5) Keyword classification — `scenes`

**Strong** (any one → confident): `scene agent`, scene builder, `scenes/Arc_`, `.tscn` composition, `1.1`/`1.2`/schoolyard/corridor/locker hub layout, path band, background swap, canonical filename invariant, `layout_planner`, `SCENE_BUILDER`.

**Weak** (≥2): overworld, player scale/speed, interact area, movement scene, `exports/Drawings` (layout ref; file may be `@`-mentioned — excluded from index).

**Not scenes:** spin/RTP/items, `game.html` flag logic, global shader matrix unless scene-specific FX task.

## 6) Keyword classification — `narrative`

**Strong** (any one → confident): flags, memories, endings, epilogue, `game.html`, `game_data.json`, `GameManager`, GameState, SceneRouter, true ending, branching choices, `hasFlashlight`/`hasKey`/`hasName`/`knowsName`/`hasShovel`, guilt/Axel identity, basement confrontation.

**Weak** (≥2): story flow, inventory narrative, memory scenes, locker hub story beat.

**Not narrative:** combat grid/items, scene-builder layout drafts, style-sweep harness.

## 7) Keyword classification — `visual_style`

**Strong** (any one → confident): `AxelPostFxStack`, post-FX, scanline, CRT, noir palette, glitch, vignette, shader tuning (overworld), `AXEL_DISABLE_POST_FX`, style sweep, `AXEL_STYLE_VARIANT`, production FX under `scenes/fx/`.

**Weak** (≥2): VT323/typography canon tied to UI presentation, line_contrast, overlay stack.

**Not visual_style:** combat balance, arc dialogue authoring, scene layout composition (unless user ties FX to a specific `.tscn`).

## 8) Confidence rules (all bundles)

| Result | Condition | Action |
|--------|-----------|--------|
| **Confident** | ≥1 strong signal for one bundle, and no equally strong competing bundle | Load that pack; apply strict lock (§9) |
| **Low confidence** | No bundle reaches confident threshold | Ask bundle question (§10) |
| **Cross-domain** | Strong signals for 2+ bundles | Primary = first-mentioned or highest-signal bundle; **do not** auto-load second — ask for `unlock <bundle>` |
| **Tie** | Equal strong signals, unclear primary | Ask user to pick bundle or use a prefix |

## 9) Strict bundle locks

### `combat` lock
- No `plans/scenes/*`, scene-builder output, `game.html` unless `unlock scenes` / `unlock narrative`.
- No full default QA playtest unless user requests `qa` / `run qa`.

### `scenes` lock
- No `plans/combat/*`, item catalog, RTP tuning unless `unlock combat`.
- No `game.html` / full flag-endings flow unless `unlock narrative`.
- Load one arc file at a time from `AXEL_SCENES_ARC*.md`.

### `narrative` lock
- No combat tuning, scene-builder internals unless `unlock combat` / `unlock scenes`.
- `AXEL/html/pictures/**` is index-excluded — `@`-mention when visual prototype reference is needed.

### `visual_style` lock
- Do not embed noir/scanline/CRT in overworld `.tscn` (autoload owns stack).
- Do not apply global stack to `res://combat/*`.
- No combat economy or arc dialogue unless unlocked.

**Always apply (all bundles):** `AI_DOCS.md` §3 hierarchy, §10 hard conflict gate, changelog on implement.

## 10) Clarification prompt (low confidence)

> Which area should this chat focus on?
> - **Meta / process** — agent workflow, API usage, rules (`meta:`)
> - **Combat** — grid, spins, items (`combat:`)
> - **Scenes** — layout, `.tscn`, scene agent (`scenes:`)
> - **Narrative** — flags, memories, endings (`narrative:`)
> - **Visual FX** — post-FX, shaders, CRT (`vfx:`)
> - Or reply `unlock <bundle>` to add a second domain to the current primary bundle.

## 11) Escalation (deep dive)

1. Load only the canonical doc cited in the active pack.
2. Do not load unrelated domains “for background.”
3. Cross-domain work requires explicit `unlock <bundle>` before loading that domain’s docs.

## 12) Indexing note (`.cursorignore`)

Aggressive exclusions reduce token/index noise. Key intentional exclusions: `logs/**`, `.godot/**`, `**/*.import`, tool preview outputs, `exports/Drawings/**`, `AXEL/html/pictures/**`. Canonical sources remain indexed: `plans/*`, `combat/*`, `scenes/*`, `scripts/*`, `AXEL/html/game.html`, `exports/game_data.json`, `exports/GameManager.gd`.

## 13) Adding future bundles

1. Add `context_packs/<BUNDLE>_MIN_CONTEXT.md`.
2. Register triggers, lock rules, and optional prefix in this file.
3. Update governance rule pointer (one line).
4. Record in `AI_CHANGELOG.md`.
