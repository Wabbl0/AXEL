# AXEL — Project Analysis

Quick reference for the ideas/experiments folder. Summarizes what the HTML prototype and supporting files establish about the game so we stay consistent while the real build happens in Cursor/Godot.

---

## 1. High-Level Identity

- **Title:** AXEL
- **Prototype form:** Branching text/point-and-click adventure built in a single HTML page (`game.html`) with a landing screen (`index.html`).
- **Target form (per you):** Top-down 2D with 360° movement and a *separate* combat layer. The prototype therefore represents the **story skeleton + investigation loop**, not the moment-to-moment gameplay.
- **Genre signals:** Psychological horror, memory/guilt narrative, puzzle-exploration, with a short "confrontation" finale.

## 2. Aesthetic & Tone

- **Palette:** Strict black background with two reds — `--blood-red: #ff0000` and `--dark-blood: #4a0000`. No other hues. Both uploaded sketches (walk-cycle sprite sheet and top-down terrain doodle) sit in the same red-on-black language.
- **Typography:** `VT323` (pixel CRT) for headings/UI, `Space Mono` for body. Heavy letter-spacing on the title.
- **Screen FX:** Fixed CRT `scanlines` overlay, `glitch-text` animation on memory triggers, `scene-shake` + `scene-image-switch` for jump-scare beats (e.g., the hand at the desk).
- **UI feel:** Command-line/terminal. Status bar reads `LOCATION: …`, `0/5` memories, `INV: …`. Choice buttons are uppercase, bordered, reactive.
- **Mood words the prose uses:** rotting, mold, stale, gaunt, rancid, mummified, nauseating, ghostly. Consistently decay + dread.

## 3. Story & Lore (as implied by prototype)

The protagonist returns, years later, to a **rotting wooden school building** — the scene of their "guilt." A friend named **Axel** was bullied, abandoned by the protagonist when popular kids called, and ultimately died (the ending reveals a **mummified body in the basement**, framed as a suicide). The player originally lied to police about when they last saw him.

The school itself is haunted/decaying — the past "leaking into the present." Progress means **reclaiming fragmented memories** (5 of them) and, critically, **remembering Axel's name** so the truth can be spoken.

Recurring symbols:
- **The lighter with "AXEL" scratched on it** — the proof of identity the protagonist buried.
- **Cigarettes/smoke** — shared ritual between the two friends; appears in the hint mechanic and the epilogue.
- **The basement** — literal and emotional burial; blacked out on the map until the player is ready.
- **The locker** — "sanctuary," and the central hub where the map/choices live.

## 4. Structure (Scene Graph)

Hub-and-spoke:

- `start` → `scene_2` (Corridor) → `scene_3` (Locker = HUB)
- Four spokes from the locker, each hides one memory and/or one item:
  - **Cafeteria** → memory of the betrayal; kitchen side-room contains the **Flashlight**.
  - **Backyard** → memory of Axel writing his name on the lighter → yields the **Name**.
  - **Teachers' Lounge** → memory of lying to the cop → yields the **Key** (labeled "BASEMENT").
  - **Classroom** → code-puzzle on the chalkboard (`if (name == ____)`) which *also* awards the Name if the player types `AXEL`.
- Basement (gated by all prerequisites) → dig with **Shovel** → final input puzzle ("WHO AM I?") → branching endings.

Gating logic (from code):
- Kitchen interaction is locked until the cafeteria memory primes it.
- Backyard choices are locked until the memory sequence plays.
- Teachers' Lounge choices are locked until the key is taken.
- Basement requires **Key** (enter), **Flashlight** (survive the stairs), **Shovel** (dig), **Name** (for true ending).

## 5. Endings (5 total)

1. **Ending 1 — "Fear wins":** Turn away at the door. Nightmares, no truth.
2. **Ending 2 — "No light":** Enter basement without flashlight → fall, die.
3. **Ending 3 — "Hell":** Wrong answer to "WHO AM I?" → fire/damnation.
4. **Ending 4 — "Convicted":** Right name spoken, but no Name item collected → framed for murder.
5. **True Ending:** Correct name + Name item → Axel's spirit released, forgiveness. Epilogue: smoking together in the backyard, "You are free."

## 6. Mechanics Worth Carrying Into Godot

Even though the real game is top-down 2D with 360° movement + separate combat, several prototype systems are load-bearing for tone:

- **Memory counter (x/5)** as a diegetic progression meter — cleaner than an XP bar.
- **Inventory as flags** (Flashlight / Key / Shovel / Name). "Name" as an *item* is the project's strongest design idea — treat intangible things as collectibles.
- **Conditional location locks** tied to emotional readiness, not just keys.
- **Environmental state changes:** scenes visually update once their item is taken (`teacher_no_key.png`, `kitchen_no_flash.png`). The world remembers what you've done.
- **Smoking = hint system.** Lighting a cigarette surfaces the next pending need. Charming, on-theme, and a nice translation target for top-down (maybe a smoke-break animation that surfaces an internal monologue).
- **Two text-input puzzles** where the answer is `AXEL`. Typing the name is itself an act of remembering.
- **Glitch/shake on memory triggers** — signals to the player that a psyche event happened, not just a pickup.

## 7. Open Questions / Decisions to Make

These are things the prototype doesn't answer and will matter in Godot:

- **Where does combat live?** The HTML has zero combat. Is combat the "intrusions" of the rot/guilt (manifestations), separate from exploration? A dream/memory layer? An arena the protagonist enters when overwhelmed?
- **360° movement + top-down** suggests real spatial exploration of the school — is the hub still a locker, or does the whole school become one continuous level?
- **What does Axel look like in-world?** A ghost? A silhouette? The uploaded red-silhouette sprite sheet reads well as either Axel himself or the protagonist's shadow.
- **Is the map still diegetic** (on the locker door) or reinterpreted as an opened inventory screen?
- **Multiple endings:** Do they survive the port, or does the 2D version commit to one canonical arc?

## 8. Files in This Prototype (for reference)

- `index.html` — Title screen + nav (About, Credits, Contact). Loads `styles.css`.
- `game.html` — The entire game: state object, scene graph, UI rendering. Loads `styles_game.css` and Tailwind CDN.
- `styles.css` — Title/marketing site styling (also a filmstrip component, image modal, comment form — these belong to surrounding pages, not the game itself).
- `styles_game.css` — In-game styling only: scanlines, scene area, story box, choice buttons, puzzle input, glitch animation.

## 9. One-Line Pitch (inferred)

> *A top-down 2D horror about a grown-up returning to the rotting school where they abandoned a friend — gathering fragments of memory until they can speak his name over his grave.*

