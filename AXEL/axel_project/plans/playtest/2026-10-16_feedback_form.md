# In-game feedback form (2026-10-16)

## What it is

A see-through bar with rolling text sits at the bottom of the screen. Clicking or tapping anywhere on it opens a feedback form inside the game. Answers go to one Google Sheet, which has tabs for the answers, game data and charts that update by themselves. All written comments also go into a separate Google Doc. Every answer is stamped with the game version, so releases can be compared.

- **The bar shows only on menus:**
  - the title screen
  - the pause menu's main page (not Options, Guide or Dev Tools)
  - the loss screen, once the GONE / IT TAKES YOU line is up
- **The bar is hidden during gameplay, fights, dialogue and endings.**
- **The form's sections:**
  - 1. Overall enjoyment, 1–5. This is the only required question.
  - 2. One word.
  - 3. Combat fun, 1–5.
  - 4. Difficulty.
  - 5. Atmosphere, 1–5.
  - 6. Story clarity.
  - 7. How far you got.
  - 8. Bugs.
  - 9. Bug text.
  - 10. Smoothness.
  - 11. Play again.
  - 12. Free comments.
  - About you (optional): age 10–110, gender M / F / Non-binary, written occupation. There is no name field.
- **The game-data checkbox** is ticked by default. It sends:
  - run seed, balance, fights won, items, Dread, tickets
  - visited rooms, memories, story flags, playtime
  - the last 60 fights, with seed, goal, result, spins, bets and balance
  - the last 300 spins, with seed, bet, payout, cascades, wilds, power, Free Spins / Vice flag and balance before and after

  The spin list lives only in memory for the current session. Save files do not change.

## Files

- `scripts/autoload/axel_feedback.gd`: the `AxelFeedback` autoload. It holds the bar (layer 255), the sender, the outbox and `ENDPOINT_URL` / `TOKEN`.
- `scenes/ui/feedback_form.gd`: the form (layer 260).
- `scripts/core/feedback_spin_log.gd`: the fight and spin recorder. `AxelRun._wire_combat_root()` starts it, and it only listens to CombatRoot signals.
- `tools/feedback/Code.gs`: the Google Apps Script.
- Checks:
  - `tools/qa/feedback_check.gd` (headless)
  - `tools/qa/feedback_form_capture.gd` (screenshots, through `run_quiet.ps1`)
- `project.godot` has `config/version`, and the release-build skill bumps it.

## How sending works

- Each form is first saved to `user://feedback_outbox/`, then POSTed to the Apps Script link.
- A sent form is deleted from the outbox.
- A failed send stays there and is retried 4 seconds after the next launch.
- Headless runs never send.
- Rows from debug builds are marked `debug = yes`. The Charts tab hides them unless "Include debug builds" is ticked.
- The script skips duplicate ids, so a retry never makes a double row.

## One-time setup (you do this once)

Beginner version in Finnish: `2026-10-16_feedback_setup_fi.md`.

1. Open https://sheets.google.com and make a new blank spreadsheet. Name it `AXEL Feedback`.
2. In the menu, click **Extensions → Apps Script**.
3. Delete the example code. Paste everything from `AXEL/axel_project/tools/feedback/Code.gs`, then click the save icon.
4. In the function list at the top, pick **setup** and click **Run**. Google asks for permission; click your account → Advanced → "Go to project" → Allow.
5. Go back to the sheet. It now has the tabs **Charts, Responses, Comments, GameData, Fights, Spins**. A new Google Doc, **AXEL Feedback Comments**, sits next to the sheet in Drive.
6. In Apps Script, click **Deploy → New deployment**. Under the gear, pick **Web app**.
7. Set **Execute as: Me** and **Who has access: Anyone**, then click **Deploy**.
8. Copy the **Web app URL**. It ends with `/exec`.
9. In `scripts/autoload/axel_feedback.gd`, paste it between the quotes of `const ENDPOINT_URL := ""`.
10. Play from the editor and send one test form. A new row appears in **Responses**, the charts update, and the Doc gets an entry.

The token in `Code.gs` (`TOKEN`) and in `axel_feedback.gd` (`TOKEN`) must match. Change both if you ever want a new one.

If you change `Code.gs` later, use **Deploy → Manage deployments → edit (pencil) → Version: New version**. That keeps the same URL.

## Getting the Excel file

In the sheet, click **File → Download → Microsoft Excel (.xlsx)**. Each tab becomes a sheet, and the charts come along.

## Charts tab

- **B1:** pick a version, or **All**.
- **B2:** tick it to include debug builds.
- One table plus one chart per choice question, and one for age group.
- Average scores per version, drawn as a line chart.
- The top 20 one-word answers.

## Not built

- The bar cannot be reached with a keyboard or gamepad. It is mouse and touch only.
- Endings do not show the bar.
