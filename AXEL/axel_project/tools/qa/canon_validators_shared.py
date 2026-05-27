"""Shared combat_test.tscn text checks for pre-commit and QA docs alignment."""
from __future__ import annotations

import re
from dataclasses import dataclass

COMBAT_ROOT_GRID_UNIQUE = (
    "GridManager",
    "GridFrame",
    "GridUI",
    "GridFlashOverlay",
    "PowerIntroLayer",
    "RoundWinningsLabel",
    "EncounterWonLabel",
    "MultiplierLabel",
)

COMBAT_ROOT_INSTANCE_MARKERS = (
    "combat/scenes/combat_root.tscn",
    'instance=ExtResource("2_combat_root")',
)

# UTF-8 text mis-decoded as Windows-1252/latin-1 (common in combat_test.tscn glyphs).
MOJIBAKE_SIGNATURES = (
    "Ã¢",
    "Ã—",
    "â€”",
    "â€¡",
    "â¬",
    "Å’",
    "Å“",
)

NODE_HEADER_RE = re.compile(r'^\[node name="([^"]+)"([^\]]*)\]\s*$')
SECTION_HEADER_PREFIXES = ("[node ", "[sub_resource", "[ext_resource")

ECONOMICS_STACK_NAME = "EconomicsStack"
ECONOMICS_CENTER_NAME = "EconomicsCenter"


@dataclass(frozen=True)
class _SceneNodeBlock:
    name: str
    parent: str
    full_path: str
    start_line: int
    end_line: int  # exclusive


def _parent_is_direct_combat_root(parent: str) -> bool:
    return parent == "CombatRoot" or parent.endswith("/CombatRoot")


def _parse_scene_node_blocks(lines: list[str]) -> list[_SceneNodeBlock]:
    blocks: list[_SceneNodeBlock] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        match = NODE_HEADER_RE.match(stripped)
        if not match:
            i += 1
            continue
        name = match.group(1)
        rest = match.group(2)
        parent_match = re.search(r'parent="([^"]*)"', rest)
        parent = parent_match.group(1) if parent_match else ""
        start = i
        i += 1
        while i < len(lines):
            next_stripped = lines[i].strip()
            if any(next_stripped.startswith(prefix) for prefix in SECTION_HEADER_PREFIXES):
                break
            i += 1
        full_path = f"{parent}/{name}" if parent else name
        blocks.append(_SceneNodeBlock(name, parent, full_path, start, i))
    return blocks


def _paths_to_remove(blocks: list[_SceneNodeBlock]) -> set[str]:
    marked: set[str] = set()
    for block in blocks:
        if block.name in COMBAT_ROOT_GRID_UNIQUE and _parent_is_direct_combat_root(block.parent):
            marked.add(block.full_path)
        else:
            # Catch numbered suffix drift like GridFrame2, GridFrame3, etc.
            for base in COMBAT_ROOT_GRID_UNIQUE:
                if not block.name.startswith(base) or block.name == base:
                    continue
                suffix = block.name[len(base) :]
                if not suffix.isdigit():
                    continue
                n = int(suffix)
                if n >= 2:
                    marked.add(block.full_path)
                    break

    changed = True
    while changed:
        changed = False
        for block in blocks:
            if block.full_path in marked:
                continue
            for removed in marked:
                if block.parent == removed or block.parent.startswith(f"{removed}/"):
                    marked.add(block.full_path)
                    changed = True
                    break
    return marked


def sanitize_duplicate_combat_root_grid(text: str) -> tuple[str, list[str]]:
    """Remove inline CombatRoot grid overrides when combat_root.tscn is instanced.

    Returns (cleaned_text, removed_node_names).
    """
    if not any(marker in text for marker in COMBAT_ROOT_INSTANCE_MARKERS):
        return text, []

    lines = text.splitlines(keepends=True)
    if not lines and text:
        lines = [text]

    blocks = _parse_scene_node_blocks(lines)
    remove_paths = _paths_to_remove(blocks)
    if not remove_paths:
        return text, []

    removed_names: list[str] = []
    for block in blocks:
        if block.full_path in remove_paths:
            removed_names.append(block.name)

    out: list[str] = []
    skip_ranges = {(b.start_line, b.end_line) for b in blocks if b.full_path in remove_paths}
    i = 0
    while i < len(lines):
        if any(start <= i < end for start, end in skip_ranges):
            i += 1
            continue
        out.append(lines[i])
        i += 1

    cleaned = "".join(out)
    if cleaned and not cleaned.endswith("\n") and text.endswith("\n"):
        cleaned += "\n"
    return cleaned, removed_names


def check_mojibake_signatures(text: str) -> list[str]:
    """Detect UTF-8 mojibake left in combat_test.tscn after locale mis-decode rewrites."""
    violations: list[str] = []
    for signature in MOJIBAKE_SIGNATURES:
        if signature in text:
            violations.append(
                f'combat_test.tscn contains mojibake signature {signature!r} '
                "(restore Unicode glyphs; ensure scaffold checker uses UTF-8 decode)"
            )
    return violations


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
        # Any numbered suffix is drift (GridFrame2, GridFrame3, ...).
        pattern = rf'\[node name="{re.escape(name)}([2-9][0-9]*)"'
        for match in re.finditer(pattern, text):
            violations.append(
                f'combat_test.tscn contains duplicate node name "{name}{match.group(1)}"'
            )
    return violations


def sanitize_orphan_economics_stacks(text: str) -> tuple[str, list[str]]:
    """Remove orphan @VBoxContainer@* blocks under EconomicsCenter.

    Returns (cleaned_text, removed_node_names).
    """
    lines = text.splitlines(keepends=True)
    if not lines and text:
        lines = [text]
    blocks = _parse_scene_node_blocks(lines)
    remove_paths: set[str] = set()

    for block in blocks:
        if block.parent == ECONOMICS_CENTER_NAME and block.name.startswith("@VBoxContainer@"):
            remove_paths.add(block.full_path)

    # Remove descendants of removed blocks.
    if remove_paths:
        changed = True
        while changed:
            changed = False
            for block in blocks:
                if block.full_path in remove_paths:
                    continue
                for removed in list(remove_paths):
                    if block.parent == removed or block.parent.startswith(f"{removed}/"):
                        remove_paths.add(block.full_path)
                        changed = True
                        break

    if not remove_paths:
        return text, []

    removed_names = [b.name for b in blocks if b.full_path in remove_paths]
    skip_ranges = {(b.start_line, b.end_line) for b in blocks if b.full_path in remove_paths}

    out: list[str] = []
    i = 0
    while i < len(lines):
        if any(start <= i < end for start, end in skip_ranges):
            i += 1
            continue
        out.append(lines[i])
        i += 1

    cleaned = "".join(out)
    if cleaned and not cleaned.endswith("\n") and text.endswith("\n"):
        cleaned += "\n"
    return cleaned, removed_names


def check_orphan_economics_stacks(text: str) -> list[str]:
    violations: list[str] = []
    if re.search(rf'\[node name=\"@VBoxContainer@\d+\"[^\]]*parent=\"{re.escape(ECONOMICS_CENTER_NAME)}\"', text):
        for match in re.finditer(r'\[node name="(@VBoxContainer@[^"]+)"[^\]]*parent="EconomicsCenter"', text):
            violations.append(f'combat_test.tscn contains orphan economics stack "{match.group(1)}"')
    return violations
