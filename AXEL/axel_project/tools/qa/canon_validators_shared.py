"""Shared combat_test.tscn text checks for pre-commit and QA docs alignment."""
from __future__ import annotations

import re

COMBAT_ROOT_GRID_UNIQUE = (
    "GridManager",
    "GridFrame",
    "GridUI",
    "GridFlashOverlay",
    "PowerIntroLayer",
    "RoundWinningsLabel",
    "EncounterWonLabel",
)

COMBAT_ROOT_INSTANCE_MARKERS = (
    "combat/scenes/combat_root.tscn",
    'instance=ExtResource("2_combat_root")',
)


def check_duplicate_grid_overrides(text: str) -> list[str]:
    """Flag grid nodes parented under CombatRoot while combat_root.tscn is instanced.

    Instancing already provides one grid stack; sibling overrides duplicate at runtime.
    """
    if not any(marker in text for marker in COMBAT_ROOT_INSTANCE_MARKERS):
        return []
    violations: list[str] = []
    for name in COMBAT_ROOT_GRID_UNIQUE:
        pattern = rf'\[node name="{re.escape(name)}"[^\]]*parent="[^"]*CombatRoot"'
        if re.search(pattern, text):
            violations.append(
                f'combat_test.tscn defines "{name}" under CombatRoot while instancing combat_root.tscn '
                f"(runtime duplicate grid)"
            )
    for name in COMBAT_ROOT_GRID_UNIQUE:
        dup = f"{name}2"
        if re.search(rf'\[node name="{re.escape(dup)}"', text):
            violations.append(f'combat_test.tscn contains duplicate node name "{dup}"')
    return violations
