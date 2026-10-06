# Guide makeover plan

## Context
The pause-menu Guide (`scenes/ui/guide_panel.gd`, text in `scenes/ui/guide_pages.gd`) is mostly long, left-aligned walls of plain text. Only Payouts and Compendium have pictures. You asked for: centered text, bold key words, more images, plus my own ideas.

## The big change: Label -> RichTextLabel
A plain `Label` cannot bold single words. A `RichTextLabel` can (it reads tags like `[b]word[/b]`).
- `_add_text()` builds a `RichTextLabel` with `bbcode_enabled`, `fit_content = true`, `scroll_active = false`, wrapped in `[center]...[/center]`.
- Bold font = `FontVariation` on VT323 with `variation_embolden = 0.8` (same trick `axel_tutorial.gd:825` uses for card titles), set as the `bold_font` theme override.
- Bold words are also drawn in `MenuLook.ACCENT` red, so they pop on the noir palette.
- Keep width rules from `_apply_layout()` (`custom_minimum_size` + `custom_maximum_size`, needed in Godot 4.7).
- `page_body_text()` returns `get_parsed_text()` so `tools/qa/guide_panel_check.gd` keeps working (no tags, no `{`).

## Text changes (`guide_pages.gd`)
- Mark key words with `[b]...[/b]`: GOAL, BALANCE, bet, Wild, cascade, multiplier, skull meter, Vice Round, Free Spins, the three power names, RTP, rarity names, etc. Roughly 3–6 per page, not whole sentences.
- Break each page into short chunks with a small heading per chunk (bold red, e.g. "BETS", "MULTIPLIER"), instead of one long string. Each page becomes a list of blocks: `{"text": ...}` or `{"image": ...}`, so images can sit between paragraphs.
- Inline symbol pictures in text with `[img=40]res://combat/art/grid_symbols/cigarette.png[/img]` next to power names and "Wild".
- Wording stays the same unless a sentence needs splitting. Naming rules kept (Vice, alcohol, Free Spins).

## New images per page
Built from art that already exists, no new drawings needed:

| Page | Image |
|---|---|
| The Fight | Crop of the GOAL panel and bet panel from `exports/Drawings/axel_combat_goal.png` / `axel_combat_bets.png` |
| Matching | Small demo board made from `grid_symbols/*.png`: one row of 3 lit up, then the same row with a Wild left in the middle (before -> after) |
| Payouts | Existing paytable (centered, header row bold) |
| Bets & Multiplier | Crops of `axel_combat_bets.png` and `axel_combat_multiplier.png`; a small "x1 -> x2 -> x3" strip |
| Skull Meter & Powers | `axel_skull_1/2/3.png` in a row (1 part, 2 parts, full) + the three power symbol icons with their name under each |
| Vice Round | Bloody Hand -> Alcohol -> Cigarette icons with arrows (the firing order) |
| Free Spins | The three vice icons with "4 / 5 / 8 spins" under each (locked page shows a dim, greyed skull instead) |
| Odds | A row of 10 small squares, 4 lit red (the "4 in 10 spins win" idea) |
| Items | The 5 rarity glyphs in a row with names, plus a crop of `axel_combat_items.png` |
| Compendium | Unchanged grid, but rarity headings centered |

Crops: the HUD drawings are big full plates. I will measure each panel's box in this session and use an `AtlasTexture` region so only that panel shows. Nearest filtering to keep the pixel look.

## My extra recommendations
1. **Thin red frame** around the scroll area (same `StyleBoxFlat` style as the compendium ring), so the page reads as a "page", not floating text.
2. **Page dots** under the page title (10 small squares, current one red) in place of only "3 / 10". Keeps the count label too.
3. **Short divider line** between chunks (a dim red 2px bar), to break long pages.
4. **Slightly smaller body text** (32 -> 30 px) with more line spacing, so pages need less scrolling now that pictures take space.
5. Keep the CRT/glitch look: no new animation for now (can add a small glitch on page flip later if you want).

## Files
- `scenes/ui/guide_panel.gd` — RichTextLabel text, block builder, image helpers (`_add_image_row`, `_add_demo_board`, `_add_crop`), frame, dots, dividers.
- `scenes/ui/guide_pages.gd` — page data as blocks, bold tags, image block ids.
- `tools/qa/guide_panel_check.gd` — add: every page has at least one image, body text has no leftover `[b]` tags, nothing runs off a 1920×1280 window.
- `plans/core/AI_DOCS.md` — one line on the new Guide look (only if you say "update docs").
- `plans/playtest/2026-10-06_guide_look_plan.md` — copy of this plan.
- No comments in any script.

## Verification
From the repo root (`tools\cmd\godot.cmd` on Windows):
1. `--import` once.
2. `-s res://tools/qa/guide_panel_check.gd`
3. The standard list from CLAUDE.md: `scene_smoke_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`, `settings_persistence_check.gd`, `audio_bus_layout_check.gd`, plus the combat checks (determinism, powers, scaffold) to confirm nothing else moved.
4. You check it in game: Esc -> Guide, flip all pages at 1920×1280 and a smaller window.
