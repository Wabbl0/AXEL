---
name: release-build
description: AXEL release steps (version bump, Windows/Mac export, cleanup, commit, push). Use only when the user clearly asks for a new release. A plain "commit and push" is not a release.
---

# AXEL release build

Do this only when the user clearly asks for a new release (for example "make a new release"). A plain "commit and push" only commits and pushes, with no version bump and no export. Never after an ordinary edit or commit.

1. Bump the version. Small playtest fixes bump the last number (0.0.3 → 0.0.4). Bigger changes bump the middle number (0.0.x → 0.1.0). Ask the user if it's unclear which one.
2. In `AXEL/axel_project/export_presets.cfg`, update all six version spots: both `export_path` names (`AXEL_x.y.z.exe`, `AXEL_x.y.z.zip`), Windows `file_version` and `product_version` (`x.y.z.0`), and Mac `short_version` and `version` (`x.y.z`).
3. Export both builds from the repo root:
   - `tools\cmd\godot.cmd --headless --path AXEL/axel_project --export-release "Windows Desktop" ../out/export/windows/AXEL_x.y.z.exe`
   - `tools\cmd\godot.cmd --headless --path AXEL/axel_project --export-release "macOS" ../out/export/mac/AXEL_x.y.z.zip`
4. After both new files exist, delete the previous version's `.exe` and `.zip` in `AXEL/out/export/`.
5. Commit the code changes and the version bump, then push.
