#!/usr/bin/env python3
"""Pre-commit guard: block stripped combat_test.tscn (missing required scaffold nodes)."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

_TOOLS_QA_DIR = Path(__file__).resolve().parent
if str(_TOOLS_QA_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_QA_DIR))

from canon_validators_shared import (
    check_duplicate_grid_overrides,
    check_orphan_economics_stacks,
    check_mojibake_signatures,
    sanitize_duplicate_combat_root_grid,
    sanitize_orphan_economics_stacks,
)

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


def _decode_utf8(data: bytes, context: str) -> str:
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        print(
            f"BLOCKED: {context} is not valid UTF-8 ({exc}).",
            file=sys.stderr,
        )
        raise SystemExit(1) from exc


def _run_git_bytes(args: list[str]) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        args,
        capture_output=True,
        cwd=REPO_ROOT,
    )


def _staged_scene_text() -> str | None:
    listed = _run_git_bytes(["git", "diff", "--cached", "--name-only", "--", SCENE_REL])
    if listed.returncode != 0:
        return None
    names = _decode_utf8(listed.stdout, "git diff --cached --name-only").splitlines()
    if SCENE_REL not in names:
        return None
    blob = _run_git_bytes(["git", "show", f":{SCENE_REL}"])
    if blob.returncode != 0:
        return None
    return _decode_utf8(blob.stdout, f"staged {SCENE_REL}")


def _git_add_scene() -> None:
    subprocess.run(
        ["git", "add", "--", SCENE_REL],
        cwd=REPO_ROOT,
        check=False,
    )


def _try_autofix_staged_grid_duplicates(text: str) -> tuple[str, list[str]]:
    """Sanitize staged text; write working tree + restage when fixes apply."""
    cleaned, removed = sanitize_duplicate_combat_root_grid(text)
    if not removed:
        return text, removed
    SCENE_PATH.parent.mkdir(parents=True, exist_ok=True)
    SCENE_PATH.write_text(cleaned, encoding="utf-8", newline="\n")
    _git_add_scene()
    print(
        "combat_test scaffold check: auto-fixed duplicate CombatRoot grid overrides "
        f"({len(removed)} node block(s) removed)."
    )
    for name in removed:
        print(f"  - removed inline node: {name}")
    return cleaned, removed


def _try_autofix_staged_orphan_economics_stacks(text: str) -> tuple[str, list[str]]:
    """Sanitize staged text; write working tree + restage when fixes apply."""
    cleaned, removed = sanitize_orphan_economics_stacks(text)
    if not removed:
        return text, removed
    SCENE_PATH.parent.mkdir(parents=True, exist_ok=True)
    SCENE_PATH.write_text(cleaned, encoding="utf-8", newline="\n")
    _git_add_scene()
    print(
        "combat_test scaffold check: auto-fixed orphan EconomicsCenter stacks "
        f"({len(removed)} node block(s) removed)."
    )
    for name in removed:
        print(f"  - removed orphan node: {name}")
    return cleaned, removed


def _validate_scene_text(text: str) -> int:
    missing = check_scene_text(text)
    mojibake_violations = check_mojibake_signatures(text)
    grid_violations = check_duplicate_grid_overrides(text)
    economics_violations = check_orphan_economics_stacks(text)
    if mojibake_violations:
        print(
            "BLOCKED: combat_test.tscn contains mojibake (corrupted Unicode).\n"
            "Restore glyphs from combat_test_scaffold_baseline.tscn / combat_test.gd constants.\n"
            "If pre-commit rewrote the file, ensure check_combat_test_scaffold.py decodes git blobs as UTF-8.\n"
            "Violations:",
            file=sys.stderr,
        )
        for item in mojibake_violations:
            print(f"  - {item}", file=sys.stderr)
        return 1
    if grid_violations:
        print(
            "BLOCKED: combat_test.tscn has duplicate CombatRoot grid overrides.\n"
            "Keep combat_root.tscn instance only; remove inline Grid* nodes under CombatRoot "
            "(including numbered suffix drift like GridFrame2/GridFrame3).\n"
            "Violations:",
            file=sys.stderr,
        )
        for item in grid_violations:
            print(f"  - {item}", file=sys.stderr)
        return 1
    if economics_violations:
        print(
            "BLOCKED: combat_test.tscn has orphan EconomicsCenter VBox stacks.\n"
            "These are usually created by @tool preview drift; keep a single EconomicsStack under EconomicsCenter.\n"
            "Violations:",
            file=sys.stderr,
        )
        for item in economics_violations:
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
    return 0


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

    grid_violations = check_duplicate_grid_overrides(text)
    if grid_violations and use_staged:
        text, _removed = _try_autofix_staged_grid_duplicates(text)
        restaged = _staged_scene_text()
        if restaged is not None:
            text = restaged

    economics_violations = check_orphan_economics_stacks(text)
    if economics_violations and use_staged:
        text, _removed = _try_autofix_staged_orphan_economics_stacks(text)
        restaged = _staged_scene_text()
        if restaged is not None:
            text = restaged

    result = _validate_scene_text(text)
    if result == 0:
        print("combat_test scaffold check OK.")
    return result


if __name__ == "__main__":
    sys.exit(main())
