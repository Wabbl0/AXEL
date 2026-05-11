# AXEL: ZERO — Master Build Prompt (Validation Prototype)

For: Fresh Claude Code session, web/Next.js project. Goal: Ship a playable cascading-cluster slot roguelite prototype in 1–2 weeks to validate K-factor before committing to the full AXEL build. Philosophy: Speed > polish. The cascade clip moment + daily seed leaderboard are the validation. Ship ugly, ship fast.

## 1. Project Overview

You are building AXEL: ZERO — a web-playable, emoji-symbol, cascading-cluster slot roguelite.

**Why this will work (wave-riding context):**

- CloverPit shipped 100k copies in 1 day (slot roguelite zeitgeist peaking).
- Balatro proved the "gambling-mechanic-as-deep-strategy" pattern.
- Moon Princess 100's cascade-cluster mechanic has NOT yet been brought to the roguelite frame.
- Sub-genre window: 6–12 weeks before saturation.

**What we're copying (legally safe):** cluster pays (4+ touching symbols), cascading avalanche on win, multiplier wild that ramps within a spin, grid-clear → free spins.

**What we're NOT touching:** Moon Princess naming/visuals, "Trinity" naming, princess/Sailor-Moon aesthetic.

## 2. Context Window Management

Work in segmented sessions. After each phase, run /clear and start fresh from the next phase's checklist.

- Session 1: Core cascade engine (Phase 1)
- Session 2: Run loop + items (Phase 2)
- Session 3: Sharing + leaderboard (Phase 3)
- Session 4: Polish + deploy (Phase 4)

## 3. Tech Stack

- Frontend: Next.js 14 (app router) + TypeScript + Tailwind
- Styling: CSS grid for the 5x5 slot board, CSS animations for cascade
- Backend: Supabase (shared instance sxoztxicojvfwquhtmpk) — table for daily seeds + leaderboard
- Share cards: Vercel OG image generation (@vercel/og)
- Deploy: Vercel
- No paid art: Emoji symbols only

## 4. Reusable Code Reference

- forge/blox-fruit-finder/ — pattern for emoji-quiz Next.js + Supabase + share-card
- forge/viral/templates/ — existing scaffolds
- Shared Supabase patterns: see memory/project_shared_supabase_instance.md

## 5. Segmented TODO List

### PHASE 1 — CORE CASCADE ENGINE (Session 1, ~3 days)

- [ ] Next.js + TS + Tailwind scaffold
- [ ] 5x5 board state (2D array of Symbol)
- [ ] Symbol pool: 6–8 emoji symbols with weights
- [ ] `spin()` — fills board with weighted random symbols
- [ ] `findClusters(board)` — flood-fill, returns all clusters of 4+ touching same-symbol
- [ ] `resolveCascade(board)` — clears winning clusters, cascades remaining symbols down, fills empty cells, repeats until no wins
- [ ] Win calc: per-symbol payout x cluster size x current multiplier
- [ ] Multiplier meter ("Chain Charge"): +1 per cascade step in a spin, resets between spins, max 20x
- [ ] Grid-clear → 3 free spins with multiplier carryover
- [ ] CSS animations for clear (fade), cascade (drop), and multiplier-tick

### PHASE 2 — RUN LOOP + ITEMS (Session 2, ~3 days)

- [ ] Ante system: balance target rises each ante, lose if miss
- [ ] Shop between antes: pick 1 of 3 items
- [ ] ~12 items, each modifying symbol weights, cascade behavior, or multiplier ramp. Examples:
  - "Lucky Cog" — +20% weight on lowest-value symbol
  - "Resonator" — multiplier starts at 2x this spin
  - "Greaser" — cascades that clear >= 3 clusters double next spin's payout
- [ ] Run state: ante, coins, items, current spin
- [ ] Game over screen with seed, items collected, max-multiplier hit
- [ ] CRITICAL: Tune RTP per ante to be sub-casino (~85–92% expected, with high variance) — players FEEL like they're beating it, math is honest

### PHASE 3 — SHARING + LEADERBOARD (Session 3, ~3 days)

- [ ] Daily seed: deterministic PRNG keyed on YYYY-MM-DD
- [ ] Supabase table: `axel_zero_runs(id, date, score, max_multiplier, items, seed, created_at)`
- [ ] Submit run on game-over
- [ ] Leaderboard page: today's top 100
- [ ] Auto-share card via @vercel/og: PNG with score, max multiplier, items, seed. Single "Share" button copies URL.
- [ ] Twitter/X meta tags so URL unfurls beautifully

### PHASE 4 — POLISH + DEPLOY (Session 4, ~2 days)

- [ ] Sound: free pack from freesound — cascade clink, multiplier ramp, grid-clear fanfare
- [ ] Mobile responsive (touch-friendly)
- [ ] Onboarding: 30s tutorial overlay first play
- [ ] Deploy to Vercel, custom domain (e.g. axel-zero.vercel.app or axel.game)
- [ ] Plausible/Umami for K-factor tracking: shares, returns, daily uniques

## 6. Game-Specific Details

**Symbol pool (emoji-only, easy to swap later):**

| Symbol | Rarity | Payout |
|--------|--------|--------|
| :wrench: | common | 1x |
| :coin: | common | 2x |
| :gear: | uncommon | 3x |
| :gem: | rare | 8x |
| :fire: | wild | multiplier |
| :slot_machine: | scatter | grid-clear bonus |

**Cluster pays table:**

| Cluster Size | Multiplier |
|-------------|------------|
| 4 touching | 1x base |
| 5–7 | 2x |
| 8–11 | 5x |
| 12+ | 20x |

Viral hook: Big cascade clears → multiplier hits 10x+ → grid clears → free spins burst. THIS is the moment the share card screenshot captures.

## 7. Critical Reminders

- Do not call this game "Moon Princess Cluster" or anything princess/anime-themed
- Do not name the multiplier meter "Trinity"
- Do not add real-money or premium-IAP framing in this prototype
- Lean hard on the cascade visual moment — this is your TikTok-clip generator
- Auto-share card MUST be one-tap and visually striking
- Ship in 2 weeks max. If polish creeps, cut content, not the loop.

## 8. Launch Checklist

- [ ] Deploy to Vercel
- [ ] Buy domain (axel.game or axel-zero.vercel.app fine for v1)
- [ ] Post on r/incremental_games, r/roguelikes, r/WebGames
- [ ] Tweet with a 6-second cascade clip — screen-record one big cascade
- [ ] Hand-share to 5 streamers who play Balatro/CloverPit
- [ ] Kill criteria: if 14-day K-factor < 0.3, kill and pivot to AXEL: Resonance directly
- [ ] Continue criteria: K > 0.5 → start AXEL: Resonance master prompt
