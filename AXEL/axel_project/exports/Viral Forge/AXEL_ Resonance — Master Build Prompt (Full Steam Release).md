# AXEL: Resonance — Master Build Prompt (Full Steam Release)

For: Fresh Claude Code session, after AXEL: ZERO validates K-factor. Goal: Ship a Steam-quality cascading-cluster slot roguelite with cosmic/neon aesthetic in 3–4 weeks. Philosophy: Beat CloverPit + Slots & Daggers to the cascading-cluster lane.

## 1. Project Overview

AXEL: Resonance — a Steam-shippable roguelite where you run through cosmic biomes (Nebula → Quasar → Void → Supercluster), each ante a cascading-cluster slot spin with biome-specific items. Visual peak: the "supernova" max-multiplier moment.

**Why this wins:**

- Cluster-cascade-in-roguelite niche unoccupied (CloverPit = 1-armed bandit; LBL = single-spin; Cascadou = cards)
- Vector visuals = no art-team bottleneck → solo-buildable
- Cosmic aesthetic differentiates from CloverPit-grunge and Slots & Daggers-fantasy
- Genre is rising/peak (6–12 week window)

Legal: Mechanics from Moon Princess 100 are SAFE (industry-standard since 2016). All naming/visuals/themes are original.

## 2. Context Window Management

- Session 1: Cascade engine + vector renderer (Phase 1)
- Session 2: Run loop + biome system (Phase 2)
- Session 3: Items + balance (Phase 3)
- Session 4: Steam integration + meta (Phase 4)
- Session 5: Polish + launch (Phase 5)

## 3. Tech Stack

- Engine: Godot 4 (lighter than Unity, free, great for 2D, easy Steam export)
- Alternative: Web → Tauri/Electron desktop wrap (faster if you're web-native)
- Rendering: Vector + GPU particles (Godot's GPUParticles2D)
- Save: Local JSON
- Steamworks: GodotSteam plugin for achievements + leaderboards
- Audio: Free packs (freesound, GameDev Market subscription)

## 4. Reusable Code Reference

- AXEL: ZERO cascade engine (port the algorithms, re-render with vectors)
- Biome content authoring: pattern from any Hades-clone tutorial

## 5. Segmented TODO List

### PHASE 1 — VECTOR CASCADE ENGINE (Session 1, ~5 days)

- [ ] Godot project setup, scene graph
- [ ] Port findClusters / resolveCascade from AXEL: ZERO
- [ ] Vector symbol rendering (parametric shapes + glow shader)
- [ ] Particle system for cascade events
- [ ] Resonance Field meter (ramps within a spin, visual glow intensifies)
- [ ] "Supernova" max-multiplier moment: full-screen visual when multiplier hits cap during a cascade

### PHASE 2 — BIOMES + RUN LOOP (Session 2, ~5 days)

- [ ] Biome data structure: symbol pool override, item pool, RTP target, ante curve
- [ ] 4 biomes: Nebula, Quasar, Void, Supercluster
- [ ] Run map: biome → 4–6 antes → shop → next biome
- [ ] Boss ante per biome (higher target, special modifier)
- [ ] Game state: items, deck, biome history

### PHASE 3 — ITEMS + BALANCE (Session 3, ~5 days)

- [ ] ~40 items across biomes (10 per biome + 5 universal x 2 rarity)
- [ ] Synergy framework: items declare tags + triggers; engine matches at spin events
- [ ] RTP tuning per biome: target ~85–92% with rising variance
- [ ] Difficulty curve playtest
- [ ] Daily seed mode (reuse from ZERO if extant)

### PHASE 4 — STEAM + META (Session 4, ~4 days)

- [ ] GodotSteam integration
- [ ] Achievements (~20)
- [ ] Steam leaderboards (daily seed)
- [ ] Steam Cloud save
- [ ] Workshop NOT in v1 (cut scope)
- [ ] Steam Capsule art (vector design, no commission)
- [ ] Trailer (60s, cascade-heavy)

### PHASE 5 — POLISH + LAUNCH (Session 5, ~4 days)

- [ ] Sound design pass
- [ ] Music: commission 4 biome tracks or use royalty-free
- [ ] Tutorial
- [ ] Settings menu, keybinds
- [ ] Steam page copy
- [ ] Launch + 20% launch discount

## 6. Game-Specific Details

**Symbol pool per biome:** 6 symbols, biome-themed (Nebula = stars/dust, Quasar = beams/photons, etc.)

**Resonance Field meter:** 1x → 2x → 5x → 10x → SUPERNOVA (25x + full-screen visual + bonus)

**Grid-clear:** Triggers 3 free spins with carryover Resonance + biome-specific bonus

**Pricing:** $9.99 launch, $12.99 regular (matches Slots & Daggers, LBL post-EA)

**Target reviews:** 90%+ positive in first 30 days

## 7. Critical Reminders

- No princess theming. No "Moon" references. No "Trinity" naming.
- No real-money or simulated-cash framing in marketing
- Lead with cascade clip in trailer and Steam page video
- Daily seed leaderboard = retention/competition driver
- Ship at 3–4 weeks even if 80% polished. Patch after launch.

## 8. Launch Checklist

- [ ] Steam page live 2 weeks before release (for wishlists)
- [ ] Submit to Steam Next Fest if timing allows
- [ ] Outreach to Northernlion, Olexa, Retromation (Balatro/CloverPit-friendly streamers)
- [ ] Post-launch: weekly patch cadence for first 8 weeks
- [ ] Mobile F2P port: scoped after 3 months IF Steam K > 0.5
