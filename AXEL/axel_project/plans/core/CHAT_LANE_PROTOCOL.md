# AXEL Chat Lane Protocol

Token-efficient two-lane workflow. **Authority:** `AI_DOCS.md` §15; routing still uses `AGENT_CONTEXT_ROUTING.md`.

## Lanes

| Lane | Purpose | Model tier | Typical turns |
|------|---------|------------|---------------|
| **A — Discovery** | Questions, scope, options, reviews, plan-only | Cheaper / Auto | 1–3 |
| **B — Implementation** | Edits, tests, changelog, fixes | Premium when needed | 1 chat per scoped task |

**Rule:** Finish scope in Lane A before opening Lane B. Do not re-plan in Lane B unless blocked.

## Lane A (cheap) — do

- Start with domain prefix: `combat:`, `scenes:`, `narrative:`, `vfx:` (or `meta:` for process/docs — see routing §1b).
- One domain per chat; use `unlock <bundle>` only when cross-domain is required.
- Ask clarifying questions; output a compact handoff (below) when ready for implementation.
- Batch reads: one grep/search pass before asking follow-ups.
- Skip QA, changelog, and full `AI_DOCS.md` unless the task is implement-ready.

## Lane B (premium) — do

- First line: domain prefix + `implement:` (e.g. `scenes: implement: …`).
- Paste **Lane B handoff** only — no full prior chat history.
- Load routed min context pack + touch only cited files.
- Implement → verify → changelog → beginner fix bullets (if a fix).
- Progress: one-liner during dense edits; full feed only when blocked.

## Lane B handoff (paste into new chat)

```md
Bundle: <combat|scenes|narrative|visual_style>
Task: <one sentence>
Files: <paths>
Acceptance: <bullet checklist>
Unlocks: <none | unlock narrative, etc.>
Out of scope: <explicit>
```

For large cross-system work, use `PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md` instead.

## When to skip Lane A

- User message already includes prefix, files, and acceptance criteria.
- Trivial single-file fix with obvious scope.
- User says `implement directly` or continues same scoped task in-thread.

## Anti-patterns (burn API)

- Plan + implement in one premium chat when scope was unclear at start.
- Re-reading full `AI_DOCS.md` every turn after routing.
- Full `qa` playtest on every incremental edit.
- Cross-domain doc loads without `unlock`.
- Long exploratory threads on premium model.

## Model selection (user)

| Work type | Suggested model |
|-----------|-----------------|
| Lane A discovery | Auto / Composer |
| Lane B implementation | Premium only when complexity or canon risk is high |
| Meta / docs / governance | Auto unless editing many files |
