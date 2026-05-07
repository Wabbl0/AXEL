# AXEL Simulated QA Review Rubric

Scoring reference for the **Simulated QA Reviewer** skill (`.cursor/skills/axel-simulated-qa/SKILL.md`). Canon order: `AI_DOCS.md` wins on conflicts.

## Axes (0–5 each)

Use **integers 0–5**. Anchor meanings:

| Score | Meaning |
| ----- | ------- |
| 0 | Broken / fundamentally wrong for AXEL |
| 1 | Severe misalignment or player-hostile |
| 2 | Major issues; playable but damaging to identity or flow |
| 3 | Acceptable; noticeable gaps |
| 4 | Strong; minor polish only |
| 5 | Excellent; exemplifies intent |

### 1) Style / tone fidelity (`S`) — weight **0.22**

- Black + blood red (`#ff0000`) + dark blood (`#4a0000`) baseline; exceptions documented if needed for readability.
- CRT / scanline / glitch / shake as **core identity**, not optional chrome.
- Typography: VT323 primary; Space Mono only where appropriate.
- Mood: dread, guilt, memory corruption; wins feel **morally uneasy or intrusive**, not purely celebratory.

### 2) Narrative / lore consistency (`N`) — weight **0.20**

- Decaying school, guilt-driven return, locker as hub/sanctuary.
- Memories, items (Flashlight / Key / Shovel / Name), basement arc coherence.
- Axel identity / endings / ritual motifs (lighter, cigarettes) stay coherent with plans and prototype where applicable.

### 3) Player immersion continuity (`I`) — weight **0.18**

- Pacing, UI chrome, diegetic hooks (e.g. memory counter, location read) support sustained focus.
- FX and copy signal “psyche event” vs generic feedback.

### 4) Excitement / tension progression (`E`) — weight **0.15**

- Curiosity and unease build; hub-and-spoke or combat beats do not flatten into noise.
- Peaks feel earned; cheap jump-scares or tone whiplash reduce this score.

### 5) Clarity / friction (`C`) — weight **0.15**

- Player understands goals, gates, and feedback without lore dumps or opaque UI.
- Friction that **serves** dread is fine; friction from bugs or confusion is not.

### 6) Regression risk vs prior intent (`R`) — weight **0.10**

- Likelihood this change breaks flags, combat invariants, scene graph, or documented blueprint intent.

## Weighted total

```
Total = 0.22*S + 0.20*N + 0.18*I + 0.15*E + 0.15*C + 0.10*R
```

Round **Total** to **two decimal places**. Optionally map to letter band:

| Total   | Band   |
| ------- | ------ |
| ≥ 4.50  | A      |
| ≥ 3.75  | B      |
| ≥ 3.00  | C      |
| ≥ 2.00  | D      |
| < 2.00  | F      |

## Violation taxonomy (categories)

Use these `category` labels in findings and analytics:

| Code | Category | Typical evidence |
| ---- | -------- | ---------------- |
| `STYLE` | Palette / CRT / typography | Wrong hues, missing scanlines where blueprint requires them |
| `LORE` | World / plot / items | Contradicts anchors or ending logic |
| `IMMERSION` | Pacing / diegesis / FX | Breaks mood or reads as generic |
| `TENSION` | Peaks / cheap tricks | Whiplash, unmotivated scare, flat middle |
| `CLARITY` | UX / goals / feedback | Confusing gates, unclear affordances |
| `COMBAT` | Grid / RNG / invariants | Violates `AI_DOCS.md` §5 |
| `ARCH` | Layer mixing | Narrative vs combat boundaries blurred without intent |
| `REGRESSION` | Prior spec / flags | Blueprint or state machine drift |
| `TOOL` | Pipeline / drafts | `layout_validation`, quarantine, approval gates only (when reviewing scene_builder output) |

## Severity definitions

| Severity | Meaning |
| -------- | ------- |
| **blocker** | Ship-stop: breaks canon, progression, or combat invariants |
| **major** | Material player confusion or identity damage |
| **minor** | Polish or consistency issue |
| **nit** | Optional improvement |

## Analytics snapshot (minimum)

In every QA report, include:

- Count of findings per **severity**
- Count of findings per **category**
- One line **confidence**: e.g. `static review`, `draft JSON + validation only`, `would need playtest`

## Player Experience Review (qualitative)

Not scored separately; it **must** accompany the numeric axes and speak to how a player would feel about **consistency**, **immersion**, and **excitement** in one cohesive voice.
