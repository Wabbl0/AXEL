# AXEL QA Progress Checklist

Manual source of truth for **game completion progress** (not build quality). The `qa agent` scores each run against this file and records results in `AXEL_QA_RUN_LOG.md` under the `progress` object.

Canon: `../core/AI_DOCS.md`. Quality axes remain in `AXEL_QA_REVIEW_RUBRIC.md`.

## How to use

1. Before scoring, read this checklist and mark which milestones are **done** for the current build (evidence required).
2. Sum **completed weights** ÷ **total weight** → `checklist_completion` (0..1).
3. Determine **highest completed gate** → `gate_state` (0–4) and **gate_cap**.
4. Apply formula from rubric §Progress Score (Option 2 default).
5. Log `progress` + `quality` in the analytics JSON payload.

**Do not** mark a milestone done without evidence (passing test, playable scene path, or explicit user confirmation).

---

## Plan doc coverage (traceability)

Use this table to see whether prior plans are reflected in milestones below.

| Source | Covered by | Gaps / notes |
|--------|------------|--------------|
| `scenes/AXEL_SCENES_BLUEPRINT.md` | M1.6–M1.7, M2.9–M2.10, M3.1, M3.3–M3.4, M4.1, M4.5 | Per-scene FX/animation beats (desk shake, backyard state machine, etc.) roll into M3.1 + M3.6 |
| `references/AXEL_notes.md` | M3.15–M3.20, M3.23, M4.6 | Open questions (§11) are design TBD — not separate milestones |
| `combat/AXEL_combat_design.md` | M0.3, M1.4, M3.6–M3.9, M3.13–M3.14, M3.22 | Trinity/SUPER FS naming per `AI_DOCS.md` |
| `combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` | M3.9, M3.21 | Full five-tier families per catalog |
| `references/VISUAL_STYLE_OPTIONS.md` | M2.8, M3.5 | Style choice recorded when applied |
| User scope (2026-05-23) | M3.4–M3.12, M4.4–M4.5 | Maps, assets, anim/VFX, shop, locker hub, audio, menus |
| `exports/Viral Forge/*.md` | §Viral Forge below | Only mechanics/narrative that fit **this** AXEL (school guilt horror), not spin-off products |

**Previously missing from checklist (now added):** global HUD + autoloads, StoryBox/PuzzleInput, scene FX helpers, six-area item pools, exploration→combat triggers, memory guilt penalty, locker/Hole economy rules, run reset loop, synergy framework, true-ending requirements, tutorial, run seed UI.

---

## Viral Forge — relevant vs excluded

Viral Forge documents describe **alternate products** (web ZERO prototype, cosmic Resonance Steam game, heist Tilt). Only ideas that apply to the **current Godot AXEL** (school + combat roguelite) are milestones here.

### Included (mapped to milestones)

| Viral Forge idea | AXEL adaptation | Milestone |
|------------------|-----------------|-----------|
| Cascade “clip” / peak moment | Intrusive guilt win beat, not celebratory jackpot | M3.22 |
| Ante / rising balance target | Encounter chip goal scales through run | M1.4, M3.17 |
| Shop between beats | The Hole + locker shop entry | M3.11, M3.12 |
| Item synergies (tags + triggers) | Combat catalog families | M3.21 |
| RTP tuning per biome/area | Area-clear difficulty + audit band | M3.13, M3.17 |
| 30s first-play tutorial | Onboarding overlay | M4.7 |
| Daily / deterministic seed | Run seed visible for replay/debug | M4.8 |
| Anti-casino / moral framing (Tilt) | Guilt-intrusive copy; no lecture — fits AXEL tone | M4.9 |
| Run summary on game over | Ending / run-end screen with seed + build | M3.20, M4.1 |

### Excluded (do not score as AXEL progress)

- **AXEL: ZERO** as a separate Next.js / Supabase / Vercel web app
- **AXEL: Resonance** cosmic biomes (Nebula, Quasar, …), vector-only art mandate, Steam achievements/leaderboards/workshop
- **AXEL: Tilt** heist casinos, Pressure Gauge “heat” as a standalone mechanic
- Share cards, TikTok meta, streamer outreach, Steam Next Fest, mobile F2P port
- Emoji-only symbol pool, princess/Moon branding (conflicts with `AI_DOCS.md`)

---

## Hard gates (caps on Progress score)

| Gate | Name | Cap (max Progress) | Unlock condition |
|------|------|-------------------|------------------|
| 0 | Foundation incomplete | **1.5** | Default until Gate 1 milestones complete |
| 1 | Core loop playable | **2.5** | All Gate 1 milestones done |
| 2 | Arc 1 critical path | **3.5** | All Gate 2 milestones done |
| 3 | Content-complete + balance | **4.5** | All Gate 3 milestones done |
| 4 | Release-ready | **5.0** | All Gate 4 milestones done |

`Progress = min(GateCap, ProgressRaw × CoverageFactor × DefectPenalty)` — see rubric.

---

## Required automated checks (coverage)

These map to `playtest_commands` keys. Used for `CoverageFactor` only (not pass=5 on the progress chart).

| Check key | Gate command? | Notes |
|-----------|---------------|-------|
| `princess_check` | yes | Combat invariants |
| `determinism` | yes | Replay stability |
| `scene_smoke` | yes | Scene load smoke |
| `combat_test_scaffold` | yes | Protected combat test scaffold |
| `bot_arc1_exterior` | yes | Arc 1 exterior bot |
| `bot_dialogue_loop` | yes | Dialogue overlay bot |
| `canon_consistency_audit` | no | Metrics (`captured` counts as pass for coverage) |
| `rtp_audit` | no | Metrics only |
| `item_balance_audit` | no | Conditional; `skip` excluded from denominator |
| `item_synergy_smoke` | yes | Conditional when items exist |

`CoverageFactor = 0.5 + 0.5 × (passed_required / total_required)` — required = gate commands that ran (not `skip`).

---

## Milestones (weighted)

**Total weight: 200.** Update weights only via changelog when scope changes. Log `checklist_total_weight: 200` and `checklist_completed_weight` in the QA payload.

**Analytics chart:** Left Y-axis = **project points** (sum of completed milestone weights). **Scope ceiling** (dashed blue) = `checklist_total_weight` — how many points the full checklist is worth that run; the line jumps up when you add milestones. Right Y-axis = Quality 0–5 plus S/N/I/E/C/R breakdown. Bots are not plotted.

### Gate 0 — Foundation (must complete before Gate 1 cap applies)

| ID | Milestone | Wt | Evidence |
|----|-----------|-----|----------|
| M0.1 | Godot project loads; main menu reachable | 3 | `scene_smoke` or manual F5 main menu |
| M0.2 | Combat test scene runs (scaffold intact) | 4 | `combat_test_scaffold=pass` |
| M0.3 | Combat invariants + determinism | 5 | `princess_check=pass`, `determinism=pass` |
| M0.4 | Core AXEL palette/CRT present in active scenes | 3 | Static review or canon audit STYLE=0 blockers |

**Gate 0 subtotal: 15**

### Gate 1 — Core loop playable (cap 2.5)

| ID | Milestone | Wt | Evidence |
|----|-----------|-----|----------|
| M1.1 | Player movement + interaction contract on Arc 1 exterior | 5 | `bot_arc1_exterior=pass` |
| M1.2 | Dialogue overlay (advance/skip) functional | 4 | `bot_dialogue_loop=pass` |
| M1.3 | School exterior → corridor transition works | 5 | Bot or documented manual path |
| M1.4 | Combat encounter loop: spin → resolve → goal (test harness) | 6 | `rtp_audit=captured`, no combat blockers |
| M1.5 | Location HUD / scene identity readable | 3 | Static or canon audit CLARITY |
| M1.6 | **Shared exploration HUD:** location label, memory counter (`x/5`), inventory, home | 3 | `HUD.tscn` or equivalent wired in Arc 1 |
| M1.7 | **GameState + SceneRouter autoloads** (flags, inventory, memories, scene routing) | 4 | `autoload/` + blueprint routers (`check_flashlight`, `check_true_ending`) |

**Gate 1 subtotal: 30** (cumulative through G1: 45)

### Gate 2 — Arc 1 critical path (cap 3.5)

| ID | Milestone | Wt | Evidence |
|----|-----------|-----|----------|
| M2.1 | Locker hub enter/exit (`2.1_LockerHub`) | 5 | Scene smoke + manual/bot |
| M2.2 | At least one memory beat (cafeteria or teachers) wired | 5 | Scene exists + flag/dialogue path |
| M2.3 | Key item gate (flashlight or key) blocks/unblocks as designed | 5 | Plan-aligned static + playtest |
| M2.4 | Arc 1 scenes use canonical numbered filenames | 3 | `canon_consistency_audit` no ARCH blockers |
| M2.5 | No progression blockers on Arc 1 bot path | 5 | Bots pass; no blocker findings |
| M2.6 | World interactable item list defined; Arc 1 pickup/interact placements wired | 4 | Item list doc or `game_data` flags + in-scene nodes |
| M2.7 | Locker hub shell: player can open hub UI (map/items/equip entry points exist) | 5 | Manual F5; UI nodes present even if stubbed |
| M2.8 | Visual style for drawn scenes chosen and applied (shader/filter/noir) on ≥1 Arc 1 scene | 3 | `NoirPaletteOverlay` / `VISUAL_STYLE_OPTIONS.md` choice |
| M2.9 | **StoryBox + PuzzleInput** for board + basement name puzzles | 3 | `6.3` / `7.4` puzzles accept `AXEL` and route correctly |
| M2.10 | **Scanlines + SceneShake/SceneGlitch** helpers on narrative scenes | 2 | `ScanlineOverlay` + shake/glitch on ≥1 story beat |

**Gate 2 subtotal: 40** (cumulative through G2: 85)

### Gate 3 — Content-complete + systems (cap 4.5)

| ID | Milestone | Wt | Evidence |
|----|-----------|-----|----------|
| M3.1 | **All blueprint narrative scenes** implemented (Arc 1–7 + endings + epilogue), not placeholder-only | 6 | Cross-check `AXEL_SCENES_BLUEPRINT.md` scene list |
| M3.2 | Basement arc reachable (7.x chain) | 5 | Manual critical path or bot extension |
| M3.3 | Endings branch (≥3 endings + epilogue path) | 5 | Flag/end state review |
| M3.4 | **Complete map layout:** multi-room per arc (kitchen, teachers lounge, basement depth, etc.) | 7 | Scene graph; sub-room transitions |
| M3.5 | **All drawn assets in-game:** player character, overworld art, grid symbols, full combat UI | 7 | Runtime-visible art; not editor-only |
| M3.6 | **Combat animations** (see §Combat animation scope) | 4 | F6 combat test; determinism still passes |
| M3.7 | **Combat special effects:** item triggers, line wins, cascades, intrusive big-win beats | 4 | VFX distinct per proc; timing safe |
| M3.8 | **Combat item bar UI complete** (slots, equip, rarity) | 3 | Production bar replaces dev-only picker |
| M3.9 | **All catalog items integrated** + balance + synergy smoke | 5 | `AXEL_COMBAT_ITEM_CATALOG_PLAN.md` |
| M3.10 | **All world item placements** per arc (pickups, gates, shop stock) | 4 | Placement audit; no TBD |
| M3.11 | **The Hole / shop:** buy/sell, reroll tickets, surplus upgrades (bet raise) | 5 | `AXEL_notes.md` §5–§6; playable loop |
| M3.12 | **Locker hub complete:** map, inventory, equip loadout, shop entry | 5 | Single hub flow |
| M3.13 | RTP within documented band | 2 | `rtp_snapshot.target_position=within` |
| M3.14 | Item balance: no OP/UP without waiver | 2 | `item_balance` clean or accepted |
| M3.15 | **Six areas:** seed-locked pools (~10 each), 1–3 active draws, passives findable | 6 | `AXEL_notes.md` §2 |
| M3.16 | **Exploration → combat triggers:** item pickup, passive pickup, step-chance curve | 4 | `AXEL_notes.md` §3; pickup uses new item same encounter |
| M3.17 | **Area-clear difficulty** + hidden rarity tier escalation on pickup/clear | 4 | `AXEL_notes.md` §2.3–2.4, §2.5 |
| M3.18 | **Memory system:** 5 memories, guilt hint, forward ~5% payout penalty | 4 | No combat on memory pickup; §7 |
| M3.19 | **Locker rules:** 6 active max, 7th forces swap/Hole; passives exempt | 3 | `AXEL_notes.md` §4 |
| M3.20 | **Run bankruptcy:** 0 currency → run reset; story/memories persist on save | 3 | `AXEL_notes.md` §5.3; True End lock on death |
| M3.21 | **Item synergy tag/trigger framework** (catalog families) | 3 | VF Resonance-style hooks; logged triggers |
| M3.22 | **Peak intrusive cascade moment** (clip-worthy, AXEL tone) | 2 | VF “cascade clip”; pairs M3.7 |
| M3.23 | **50/50 surplus gamble** at safe moments (optional risk sink) | 2 | `AXEL_notes.md` §5.4 |

**Gate 3 subtotal: 95** (cumulative through G3: 180)

### Gate 4 — Release-ready (cap 5.0)

| ID | Milestone | Wt | Evidence |
|----|-----------|-----|----------|
| M4.1 | Full narrative critical path start → true ending | 3 | Manual playthrough sign-off |
| M4.2 | No open blocker/major QA findings | 2 | Latest run `findings_count` |
| M4.3 | Pre-commit QA gates green | 1 | CI/local script pass |
| M4.4 | **Sound effects** for whole game | 4 | Combat, UI, overworld, story beats |
| M4.5 | **Title, end credits, options, about** | 4 | Main menu + epilogue + settings |
| M4.6 | **True ending requirements** enforced (no death this run, all memories, correct passives) | 3 | `AXEL_notes.md` §9 |
| M4.7 | **First-play tutorial** (~30s onboarding overlay) | 2 | VF ZERO Phase 4 analogue |
| M4.8 | **Run / daily seed exposed** in UI for replay | 1 | VF ZERO retention hook; combat seed queue |
| M4.9 | **Moral framing** in copy/UI (guilt/intrusion, not casino glam) | 2 | VF Tilt narrative angle; `AI_DOCS.md` tone |

**Gate 4 subtotal: 20** (total: **200**)

---

## Combat animation scope (M3.6)

| Beat | Intent | Typical implementation |
|------|--------|------------------------|
| Spin start | Anticipation / unease | Grid dim + reel stagger |
| Symbol land | Readability | Per-cell settle bounce |
| Line win | Payline clarity | Highlight → win popup lob (`symbol_slot`) |
| Cascade / drop | Gravity beat | Column tween + multiplier tick |
| Trinity / premium | Identity moment | Princess collapse / symbol FX |
| Item proc | Item identity | One-shot on effect fire (M3.7) |

---

## Combat VFX scope (M3.7 / M3.22)

- Item-trigger bursts; line-win glitch/shake (uneasy, not celebratory)
- Multiplier / encounter goal pulse
- **Peak moment (M3.22):** one recognizable “chain broke through” beat suitable for capture — still on-brand for guilt horror

---

## Locker hub scope (M2.7 → M3.12)

| Phase | Includes |
|-------|----------|
| M2.7 shell | Enter hub; stubs for map / items / equip / shop |
| M3.12 complete | Map discovery, inventory, equip → combat loadout, shop/The Hole entry |

---

## Current baseline (2026-05-23)

| Gate | Status | Notes |
|------|--------|-------|
| 0 | Mostly done | Combat scaffold + invariants |
| 1 | Partial | Bots pass; M1.6–M1.7 autoloads/HUD incomplete vs blueprint |
| 2 | Early | Locker exists; M2.9–M2.10 narrative UI/FX partial |
| 3 | Not started | Most blueprint scenes placeholder; notes §2–§7 systems largely unbuilt |
| 4 | Not started | M4.6–M4.9 not started |

**Expected Progress band today:** ~**1.4–2.0** (Gate 1 partial only) when Quality ≈ 3.5–3.9.

---

## Defect penalty (from findings)

```
DefectPenalty = 1.0 - min(0.35, 0.12×blockers + 0.05×majors)
```

Blockers should also prevent marking dependent milestones complete.
