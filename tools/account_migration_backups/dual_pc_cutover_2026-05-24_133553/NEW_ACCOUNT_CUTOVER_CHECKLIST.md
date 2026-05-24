# New Account Cutover Checklist (Dual-PC)

## Pre-delete status (already prepared)
- GitHub parity on PC1 is clean (`origin/main...main` = `0 0`).
- Baseline state + governance hashes captured in this run folder.
- Cursor-context backup bundle created with SHA256 manifest.

## Required target commit
- c99e410edd8d3580ae5ba4bc4d09d649bddb341a

## PC1 steps after creating new Cursor account
1. Sign into the new Cursor account.
2. Open `C:\Users\valtt\OneDrive\Godot`.
3. Confirm project opens and indexing finishes.
4. Run a governance check prompt and verify:
   - AI reads `AI_DOCS.md` first for AXEL tasks
   - `scene agent` / `qa` alias behavior is recognized
   - planning asks clarifying questions before assumptions

## PC2 steps before opening in Cursor
1. `git fetch --all --prune`
2. `git checkout main`
3. `git pull --ff-only`
4. Verify commit equals the required target commit

## PC2 new-account validation
1. Sign into the same new Cursor account.
2. Open the same OneDrive folder path.
3. Repeat governance checks from PC1.

## Final hard gate
- Retire/delete old account only after both PCs pass the validation checks.
- If either PC fails, keep old account active and restore from this run backup manifest.
