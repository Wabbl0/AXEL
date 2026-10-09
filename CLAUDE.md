# AXEL — Claude Code instructions

AXEL is a roguelike with a slot-machine combat mechanic. Godot 4.7.2 (Forward Plus), GDScript, Windows. Horror/noir tone: decaying school, guilt-driven return, dread and memory corruption.

The Godot project is in `AXEL/axel_project` (`project.godot`). Main scene: `res://scenes/Main_Menu/0.1_MainMenu.tscn`.

## First, every session

1. Read `AXEL/axel_project/plans/core/AI_DOCS.md`. It is the canon and wins over every other doc.
2. Then open the matching plan:
   - Rooms, player, spawn, hitboxes, cover-fit: `plans/scenes/SCENE_BUILDING.md`
   - Combat: the combat plans, only when I say the task is combat-related
   - "What did we decide lately?": `git log`. The tail of `plans/core/AI_CHANGELOG.md` only for decisions before 2026-09-30.
   - Anything else in `plans/**/*.md` only when clearly relevant. Skip `plans/archive/`.
3. Ask before large or ambiguous changes. If my request breaks an established rule, remind me. If I confirm, the new request may become canon.

## How to talk to me

- I am a beginner in coding and in Godot.
- Start with a 1–3 sentence answer. Add detail only if needed.
- Use plain words. Explain any needed jargon in one line.
- One idea at a time. For "how do I do X", use numbered steps with one action each.
- After code changes, give a short "what I changed and why" in plain language.
- No long architecture essays and no big code dumps without explanation.
- For "why" or "explain" questions, you may go longer, but use a short analogy.

## Code rules

- NEVER write comments in any script. No `#` and no `##`, in GDScript, tools, tests, shaders, Python or PowerShell.
- Do not add, convert or expand comments. Do not mass-delete existing ones unless I ask.
- Markdown, plans and `.mdc` files may still use `##` headings.
- Input goes through named InputMap actions. Never use raw `KEY_*` or `ui_*` in gameplay code.
- Use `CombatPace`, never `Engine.time_scale`.
- Do not restart the shared music player.
- No machine-absolute paths in shared gameplay code.

## Two layers. Never mix them.

**Narrative / overworld** (`scenes/`): `GameManager` (`exports/GameManager.gd`) holds flags, memories and spawn sides. `AxelWorld` decides when a fight starts. The true ending needs the name item equipped, otherwise Ending 4.

**Combat** (`combat/`): 5×5 grid, deterministic RNG, wins are 3+ lines (no cluster wins), wild spawns on exactly-3 lines. Powers: cigarette, alcohol, bloody hand. Bonus flow: normal spins, then Vice Round, then Free Spins. Fights end at GOAL or when a paid spin cannot be afforded. Start balance 3000. Goal ladder 50/60/70/80/90/110/175/300/550, then ×1.5 (rounded to 5); every fight is a new seed.

- Keep combat deterministic.
- Only `AxelRun` starts a fight. Combat reads no story flags.
- The items catalog is only edited in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- `combat/combat_test.tscn` is a protected scaffold (`%CombatRoot`, `%SpinButton`, etc.). Run `combat_test_scaffold_check.gd` before combat edits.

## Scene and visual rules (highlights from AI_DOCS)

- The Player node is the spawn. Never hardcode spawn Vectors or derive them from another node.
- For door arrivals, always re-measure the live destination InteractArea/ExitTrigger in this session.
- Shared player hitbox is `hitbox_front.tres` (radius only). No per-room player polygons.
- Each room collider needs its own unique `Shape2D` (Make Unique).
- Window stretch stays disabled. Do not retune Player scale per monitor. Cover-fit baseline is 1920×1280.
- No visual offsets on the player, memory glow or `[E]` chip unless I ask.
- Palette: 8-band inverted noir (4 reds, 2 warm greys, 2 blacks). CRT, scanline and glitch are core to the look. Font: VT323.
- Do not change legacy Arc 1 scenes without approval.

## Naming

- Use "Vice", not "Trinity".
- Use "alcohol", not "booze".
- Use "Free Spins", not "SUPER Free Spins".
- Never call the Vice Round "Free Spins".

## Autoloads

The full list is in `project.godot`. `AxelPause` is the only writer of `get_tree().paused`. `AxelCombatDevTools` is debug only. `AxelSaves` uses 3 slots in `user://saves/`.

## Big files. Do not read them whole.

- `plans/core/AI_CHANGELOG.md` is about 800 KB and retired (no new entries after 2026-09-30). Read only the tail, and only for older history.
- `combat_test.gd` (~175 KB), `combat_root.gd` (~100 KB), `axel_world.gd` (~55 KB): search for what you need and read only that part.
- Ignore `exports/*` (except `GameManager.gd`) and the archived HTML prototype unless I say otherwise.

## Searching the project (save tokens)

- When the main model is Opus, do not search the project broadly yourself, and never run an Explore subagent on Opus.
- Before searching, make a quick internal plan: which files or folders the prompt needs, and which cheaper model should look for them.
- Then start Explore subagents with `model: "haiku"` for simple lookups (find a file, a function, a node name) or `model: "sonnet"` for harder questions (trace how a system works across files). Give each helper a narrow question and ask for file paths with line numbers only, no file dumps.
- Use at most 3 helpers per task. Run them in parallel when their questions are independent.
- Skip helpers when the task is small and the file is already known. Open it directly.
- Read the helpers' file list, then do the planning and editing on the main model.
- Helpers only search. They never edit files.

## Checking your work

Run these after any GDScript change. Run from the repo root. Exit code 0 means pass. On Windows use `tools\cmd\godot.cmd` in place of `godot`.

`godot --headless --path AXEL/axel_project -s res://<script>`

Scripts:
- `combat/test/determinism_check.gd`
- `combat/test/powers_check.gd`
- `combat/combat_test_scaffold_check.gd`
- `tools/scene_smoke_check.gd`
- `tools/qa/audio_bus_layout_check.gd`
- `settings_persistence_check.gd`
- `pause_contract_check.gd`
- `menu_nav_check.gd`

Notes:
- In headless scene checks, force `root.size = Vector2i(1920,1280)`.
- Run `--import` once first so `class_name` types resolve.
- After HUD changes, check live UI sizes. Wrapping Labels in Godot 4.7 need `custom_maximum_size`.

## Working style

- For big or risky work, plan first and wait for my approval before editing.
- For small single-issue fixes, one plan file in `plans/playtest/` is enough. Implement it, then run the checks.
- When I say "update docs", update `AI_DOCS.md` and the matching plans. Do not add entries to `AI_CHANGELOG.md`; it is retired.
- Git commits are the change history. Write clear commit messages: what changed and why.

## Commit and push vs. new release

- "Commit and push" means only: git commit, then push. No version bump and no export. Most testing happens inside Godot.
- Make a release build only when I clearly ask for a new release (for example "make a new release"). Then follow the `release-build` skill.
