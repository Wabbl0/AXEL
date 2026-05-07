#!/usr/bin/env python3
"""Validate draft placements for path readability and profile consistency."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

PROJECT_ROOT = Path("AXEL/axel_project")
DRAFT_DIR = PROJECT_ROOT / "tools/scene_builder/output/layout_drafts"
VALIDATION_PATH = PROJECT_ROOT / "tools/scene_builder/output/layout_validation.json"
MIN_MAIN_ROUTE_WIDTH = 280
MAX_ROUTE_OCCUPANCY = 0.22

PROFILE_RULES = {
    "corridor_large": {"max_scale": 0.85, "max_speed": 155.0},
    "classroom_large": {"max_scale": 0.89, "max_speed": 165.0},
    "library_large": {"max_scale": 0.80, "max_speed": 150.0},
    "default": {"max_scale": 1.0, "max_speed": 180.0},
}


def _occupancy_ratio(draft: Dict[str, object]) -> float:
    path = draft["path_band"]
    placements = draft["placements"]
    path_area = max(1, (path["x1"] - path["x0"]) * (path["y1"] - path["y0"]))
    # Approximate each blocking prop footprint as 48x48 for first pass.
    blocking = [
        p
        for p in placements
        if p["tag"] in ("decay_cluster", "edge_clutter", "wall_row", "highlight_candidate")
        and path["x0"] <= p["x"] <= path["x1"]
        and path["y0"] <= p["y"] <= path["y1"]
    ]
    used_area = len(blocking) * (48 * 48)
    return float(used_area) / float(path_area)


def _route_width(path_band: Dict[str, int]) -> int:
    return int(path_band["x1"] - path_band["x0"])


def _profile_ok(draft: Dict[str, object]) -> List[str]:
    profile = draft.get("profile", "default")
    player = draft["player"]
    limit = PROFILE_RULES.get(profile, PROFILE_RULES["default"])
    notes: List[str] = []
    if player["scale"] > limit["max_scale"]:
        notes.append(
            f"player scale {player['scale']} exceeds {limit['max_scale']} for profile {profile}"
        )
    if player["speed"] > limit["max_speed"]:
        notes.append(
            f"player speed {player['speed']} exceeds {limit['max_speed']} for profile {profile}"
        )
    return notes


def validate_draft(path: Path) -> Dict[str, object]:
    draft = json.loads(path.read_text(encoding="utf-8"))
    notes: List[str] = []
    route_width = _route_width(draft["path_band"])
    if route_width < MIN_MAIN_ROUTE_WIDTH:
        notes.append(f"main route width {route_width} < {MIN_MAIN_ROUTE_WIDTH}")
    occupancy = _occupancy_ratio(draft)
    if occupancy > MAX_ROUTE_OCCUPANCY:
        notes.append(f"path occupancy {occupancy:.3f} > {MAX_ROUTE_OCCUPANCY:.3f}")
    notes.extend(_profile_ok(draft))

    return {
        "scene_id": draft["scene_id"],
        "draft_file": path.name,
        "route_width": route_width,
        "route_occupancy": round(occupancy, 4),
        "path_clear": len(notes) == 0,
        "notes": notes,
    }


def main() -> None:
    results = []
    for draft_file in sorted(DRAFT_DIR.glob("*_draft.json")):
        results.append(validate_draft(draft_file))
    payload = {
        "min_main_route_width": MIN_MAIN_ROUTE_WIDTH,
        "max_route_occupancy": MAX_ROUTE_OCCUPANCY,
        "results": results,
        "all_valid": all(item["path_clear"] for item in results) if results else False,
    }
    VALIDATION_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"validated {len(results)} drafts -> {VALIDATION_PATH.as_posix()}")


if __name__ == "__main__":
    main()
