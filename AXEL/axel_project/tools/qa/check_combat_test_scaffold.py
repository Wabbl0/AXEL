#!/usr/bin/env python3
"""Pre-commit guard: block stripped combat_test.tscn (missing required scaffold nodes)."""
from __future__ import annotations

import sys
from pathlib import Path

_TOOLS_QA_DIR = Path(__file__).resolve().parent
if str(_TOOLS_QA_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_QA_DIR))

from canon_validators_shared import check_duplicate_grid_overrides  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[4]
SCENE_REL = "AXEL/axel_project/combat/combat_test.tscn"
SCENE_PATH = REPO_ROOT / SCENE_REL

REQUIRED_EXT = "combat/scenes/combat_root.tscn"

REQUIRED_NODE_MARKERS = [
    '[node name="CombatRoot"',
    '[node name="MetaBox"',
    '[node name="SeedSpinBox"',
    '[node name="SpinButton"',
    '[node name="BankrollLabel"',
    '[node name="GoalBox"',
    '[node name="GoalLabel"',
    '[node name="StakeSelector"',
    '[node name="BetMinusButton"',
    '[node name="BetLabel"',
    '[node name="BetPlusButton"',
    '[node name="MultiplierReadout"',
]


def check_scene_text(text: str) -> list[str]:
    missing: list[str] = []
    for marker in REQUIRED_NODE_MARKERS:
        if marker not in text:
            missing.append(marker)
    if REQUIRED_EXT not in text:
        missing.append(REQUIRED_EXT)
    return missing


def _staged_scene_text() -> str | None:
    import subprocess

    listed = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--", SCENE_REL],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    if SCENE_REL not in listed.stdout.splitlines():
        return None
    blob = subprocess.run(
        ["git", "show", f":{SCENE_REL}"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    if blob.returncode != 0:
        return None
    return blob.stdout


def main() -> int:
    use_staged = "--staged" in sys.argv
    text: str | None = None
    if use_staged:
        text = _staged_scene_text()
        if text is None:
            print("combat_test scaffold check: skipped (scene not staged).")
            return 0
    elif SCENE_PATH.is_file():
        text = SCENE_PATH.read_text(encoding="utf-8")
    else:
        print(f"combat_test scaffold check: scene not found at {SCENE_PATH}", file=sys.stderr)
        return 1
    missing = check_scene_text(text)
    grid_violations = check_duplicate_grid_overrides(text)
    if grid_violations:
        print(
            "BLOCKED: combat_test.tscn has duplicate CombatRoot grid overrides.\n"
            "Keep combat_root.tscn instance only; remove inline Grid* nodes under CombatRoot.\n"
            "Violations:",
            file=sys.stderr,
        )
        for item in grid_violations:
            print(f"  - {item}", file=sys.stderr)
        return 1
    if missing:
        print(
            "BLOCKED: combat_test.tscn is missing required scaffold nodes.\n"
            "Restore from git: git checkout bab7ec5 -- AXEL/axel_project/combat/combat_test.tscn\n"
            "Missing markers:",
            file=sys.stderr,
        )
        for item in missing:
            print(f"  - {item}", file=sys.stderr)
        return 1
    print("combat_test scaffold check OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
