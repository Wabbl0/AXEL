# Web build on GitHub (plan, 2026-10-15)

**Status: steps 1–6 built 2026-10-15 (not committed). Waiting on: user browser + phone playtest, one-time Pages setting, step 8 details from the laptop.**

## Done 2026-10-15

- Web templates installed (only the `web_*` files from the official 4.7.2 package).
- `Web` preset in `export_presets.cfg`, threads off, ETC2/ASTC on for phones. First export: `index.pck` 71 MB + `index.wasm` 40 MB; zip 73 MB. Boots in Chromium (WebGL 2, single-threaded), no game errors in the console.
- Compatibility look: main menu, `1.3_LockerHub`, `combat_test` match Forward Plus (screenshots after the entry glitch settles). `run_quiet.ps1` / `capture_scene.ps1` got an optional `-Renderer`.
- Web-only: Quit hidden (main menu, pause menu, death screen), `back` on the main menu does not quit, window mode + resolution options hidden, `_apply_window_mode()` skipped.
- `.github/workflows/web-pages.yml`: on release published (or by hand with a tag), downloads `*_web.zip` from the release and deploys it to Pages.
- `release-build` skill exports + zips the web build to `AXEL/out/export/web_zip/AXEL_x.y.z_web.zip`; `CLAUDE.md` upload step attaches it and adds the play link to the notes.
- `AI_DOCS.md` "How to work": web build rule.

Goal: every GitHub Release also gets a version you can play in the browser, at a fixed link (`https://wabbl0.github.io/AXEL/`), next to the Windows `.exe` and Mac `.zip`.

## Facts found

| Topic | Now |
|---|---|
| Web export templates | Not installed (`%APPDATA%/Godot/export_templates/4.7.2.stable/` has only Windows, Linux, Mac) |
| Renderer | Forward Plus. Browsers only run **Compatibility** (WebGL 2). The web build switches to it automatically, so the look can differ |
| Build size | Windows `.exe` 177 MB, so the web `.pck` is likely 100+ MB. Git refuses files over 100 MB |
| Releases | GitHub Releases only hold downloads. They cannot run a game. A playable page needs GitHub Pages |
| Quit | `MainMenu.gd`, `pause_menu.gd`, `axel_run.gd` call `get_tree().quit()`. In a browser that freezes the page |
| Window mode | `AxelSettings` sets fullscreen/borderless. Means nothing in a browser |

## Plan

### 1. Make the web export work locally

1. Install the full 4.7.2 export templates (adds `web_nothreads_release.zip` and friends).
2. Add an export preset `Web`, **threads off** (`variant/thread_support=false`). Threads need special server headers (COOP/COEP) that GitHub Pages cannot send; without threads no headers are needed.
3. Export path `../out/export/web/index.html`.
4. Export and test with Godot's "Run in browser" (Remote Debug). Check: main menu, one room, one fight, save/load, audio after the first click.

### 2. Compatibility look check

1. Open the project with `--rendering-method gl_compatibility` and compare the CRT, scanline, glitch, memory glow, highlight glow and death shatter against Forward Plus (screenshots with `capture_scene.ps1`).
2. Fix what breaks with web-only tweaks (`OS.has_feature("web")`), not by changing the desktop look.

### 3. Small web-only code fixes

- Hide Quit buttons on web (main menu, pause menu). `axel_run.gd:641` quit path goes back to the main menu on web instead.
- Hide the window-mode setting on web; `_apply_window_mode()` does nothing on web.
- Check saves: `user://saves/` lives in the browser (IndexedDB). They survive reloads but not "clear site data". Say so in the release notes.

### 4. Size

Measure the web `.pck`. If it is large, find the biggest files (likely audio and full-screen art) and see what the web build can leave out or compress. A ~100 MB first load is slow but works.

### 5. Hosting: release asset + GitHub Pages via Actions

No big files in git:

1. Release build exports the web folder and zips it to `AXEL/out/export/web_zip/AXEL_x.y.z_web.zip`.
2. "Commit and push" uploads that zip with the `.exe` and `.zip` (third file in `gh release create`).
3. A new workflow `.github/workflows/web-pages.yml` runs **on release published**: downloads `*_web.zip` from the release, unzips it, deploys it with `actions/upload-pages-artifact` + `actions/deploy-pages`. Godot does not run on GitHub; only the files are copied.
4. One-time: repo Settings → Pages → Source = "GitHub Actions" (the user does this).
5. Release notes get a line: "Play in browser: https://wabbl0.github.io/AXEL/".

### 6. Docs and tools

- `release-build` skill: third export (`Web`), zip it, delete the old web zip.
- `CLAUDE.md` "GitHub Release upload": three files instead of two; missing web zip = skip upload and tell the user (same rule as now).
- `AI_DOCS.md`: web build exists, threads off, Compatibility renderer, no Quit on web.

### 7. Phone browsers

Emulated iPhone test done 2026-10-15 (`2026-10-15_web_phone_touch.md`): touch mode was off on phone browsers, fixed in 2.0.1. Real-phone test still open.

- Test on a real phone (Android Chrome, iPhone Safari): portrait UI, touch move stick, combat buttons, first-tap audio.
- Watch memory and load time on phones; the `.pck` size (step 4) matters most here.
- Fullscreen on tap if the browser allows it (iPhone Safari does not).

### 8. Feedback bar (all future releases)

From the other laptop; that plan was never pushed (searched every branch and all history on 2026-10-15). **The details come from the other computer; do not build this until they are merged in.**

Known so far:
- A bar at the bottom of the screen, **always visible**, in every build (Windows, Mac, Web).
- It links to an **in-game questionnaire** that helps development and gathers play data.

To settle with the laptop plan: where the answers are sent (and that it works offline / on web), what is asked, what play data is attached, opt-in/privacy text, and how the bar fits the portrait layouts and the 1920×1280 cover-fit without covering gameplay or the `[E]` chip.

## Decisions (user, 2026-10-15)

| Topic | Decision |
|---|---|
| Repo | Public, so GitHub Pages is free |
| Phones | Yes, phone browsers are a target too |
| Saves | Web saves are separate from desktop saves. OK |

## Not in this plan

- itch.io (would also work and handles threads, but the user asked for GitHub).
- Running the Godot export inside GitHub Actions.

## Checks

Standard CLAUDE.md set after the code fixes, plus a manual browser playtest of step 1.4 (desktop and phone) before the first web release.
