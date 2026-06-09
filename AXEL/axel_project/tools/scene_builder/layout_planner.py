#!/usr/bin/env python3
"""Generate draft placement plans from asset catalog and blueprint context."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple

PROJECT_ROOT = Path("AXEL/axel_project")
CATALOG_PATH = PROJECT_ROOT / "tools/scene_builder/output/asset_catalog.json"
DRAFT_DIR = PROJECT_ROOT / "tools/scene_builder/output/layout_drafts"
BLUEPRINT_PATH = PROJECT_ROOT / "plans/AXEL_SCENES_BLUEPRINT.md"
SCENES_DIR = PROJECT_ROOT / "plans/scenes"

PROFILE_BY_SCENE_KEY = {
    "corridor": {"profile": "corridor_large", "player_scale": 3.0, "player_speed": 362.0},
    "classroom": {"profile": "classroom_large", "player_scale": 0.86, "player_speed": 160.0},
    "library": {"profile": "library_large", "player_scale": 0.78, "player_speed": 145.0},
    "default": {"profile": "default", "player_scale": 1.00, "player_speed": 180.0},
}

# Canonical filename + Arc folder resolution per scene_id.
# This is the authoritative mapping. The planner MUST emit canonical numbered
# filenames (e.g. `1.2_Corridor.tscn`) that overwrite the matching placeholder,
# never simplified aliases (e.g. `Corridor.tscn`).
CANONICAL_BY_SCENE_ID: Dict[str, Dict[str, str]] = {
    "scene_2": {"scene_file": "1.2_Corridor.tscn", "arc_dir": "Arc_1"},
    "loc_classroom": {"scene_file": "6.1_Classroom.tscn", "arc_dir": "Arc_6"},
    "loc_desk": {"scene_file": "6.2_ClassroomDesk.tscn", "arc_dir": "Arc_6"},
    "loc_board": {"scene_file": "6.3_ClassroomBoard.tscn", "arc_dir": "Arc_6"},
    "loc_board_success": {"scene_file": "6.4_ClassroomBoardSuccess.tscn", "arc_dir": "Arc_6"},
}


def _load_asset_catalog() -> Dict[str, object]:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


def _arc_dir_from_section(section: str) -> str:
    # `1.2` -> `Arc_1`; `8.6` -> `Endings`; `0.1` -> `Main_Menu`.
    if section.startswith("0."):
        return "Main_Menu"
    if section.startswith("8."):
        return "Endings"
    major = section.split(".", 1)[0]
    return f"Arc_{major}"


def _canonical_filename(section: str, raw_name: str) -> str:
    # Avoid double-prefixing if blueprint already includes the section number.
    return raw_name if raw_name.startswith(f"{section}_") else f"{section}_{raw_name}"


def _resolve_canonical(scene_id: str, section: str, raw_name: str) -> Dict[str, str]:
    override = CANONICAL_BY_SCENE_ID.get(scene_id)
    if override:
        return {
            "scene_file": override["scene_file"],
            "arc_dir": override["arc_dir"],
        }
    return {
        "scene_file": _canonical_filename(section, raw_name),
        "arc_dir": _arc_dir_from_section(section),
    }


def _extract_target_scenes() -> List[Dict[str, str]]:
    scenes: List[Dict[str, str]] = []
    text = BLUEPRINT_PATH.read_text(encoding="utf-8")
    for match in re.finditer(r"###\s+(\d+\.\d+)\s+`([^`]+)`\s+\(`([^`]+)`\)", text):
        section = match.group(1).strip()
        raw_name = match.group(2).strip()
        scene_id = match.group(3).strip()
        lowered = raw_name.lower()
        if not any(key in lowered for key in ("corridor", "classroom", "library")):
            continue
        canonical = _resolve_canonical(scene_id, section, raw_name)
        scenes.append({
            "scene_file": canonical["scene_file"],
            "arc_dir": canonical["arc_dir"],
            "scene_id": scene_id,
            "scene_key": lowered,
        })
    if scenes:
        return scenes

    # Fallback to per-arc scene docs if blueprint headings are not matched.
    # Scans AXEL_SCENES_ARC*.md files under plans/scenes/.
    # Fallback ALSO emits canonical numbered filenames so the agent can never
    # regress to non-canonical scene targets like `Corridor.tscn`.
    backup = ""
    for arc_file in sorted(SCENES_DIR.glob("AXEL_SCENES_ARC*.md")):
        backup += arc_file.read_text(encoding="utf-8").lower()
    fallback: List[Dict[str, str]] = []
    if "corridor" in backup:
        canonical = CANONICAL_BY_SCENE_ID["scene_2"]
        fallback.append({
            "scene_file": canonical["scene_file"],
            "arc_dir": canonical["arc_dir"],
            "scene_id": "scene_2",
            "scene_key": "corridor",
        })
    if "classroom" in backup:
        canonical = CANONICAL_BY_SCENE_ID["loc_classroom"]
        fallback.append({
            "scene_file": canonical["scene_file"],
            "arc_dir": canonical["arc_dir"],
            "scene_id": "loc_classroom",
            "scene_key": "classroom",
        })
    if "library" in backup:
        # Library has no canonical numbered scene yet; flag for human triage
        # rather than silently writing a non-canonical filename.
        fallback.append({
            "scene_file": "UNCANONICALIZED_Library.tscn",
            "arc_dir": "UNRESOLVED",
            "scene_id": "loc_library",
            "scene_key": "library",
        })
    return fallback


def _scene_profile(scene_key: str) -> Dict[str, object]:
    for key, profile in PROFILE_BY_SCENE_KEY.items():
        if key in scene_key:
            return profile
    return PROFILE_BY_SCENE_KEY["default"]


def _asset_groups(assets: List[Dict[str, object]]) -> Dict[str, List[Dict[str, object]]]:
    groups: Dict[str, List[Dict[str, object]]] = {
        "wall_prop": [],
        "floor_anchor": [],
        "floor_clutter": [],
        "focal_candidates": [],
    }
    for item in assets:
        role = item.get("placement_role")
        if role in groups:
            groups[role].append(item)
        if item.get("class_label") in ("locker", "desk", "wall_decal"):
            groups["focal_candidates"].append(item)
    return groups


def _base_path_band(scene_key: str) -> Dict[str, int]:
    if "corridor" in scene_key:
        return {"x0": 320, "x1": 960, "y0": 430, "y1": 660}
    return {"x0": 280, "x1": 1000, "y0": 380, "y1": 670}


def _grid_positions(x_start: int, y: int, count: int, step: int = 48) -> List[Tuple[int, int]]:
    return [(x_start + idx * step, y) for idx in range(count)]


def _build_placements(scene_key: str, groups: Dict[str, List[Dict[str, object]]]) -> List[Dict[str, object]]:
    placements: List[Dict[str, object]] = []
    wall_assets = groups["wall_prop"][:]
    floor_assets = groups["floor_anchor"][:]
    clutter_assets = groups["floor_clutter"][:]

    # Wall line first: keeps recognizability before adding decay clusters.
    if wall_assets:
        row = _grid_positions(448, 284, min(9, len(wall_assets)))
        for idx, (x, y) in enumerate(row):
            asset = wall_assets[idx % len(wall_assets)]
            placements.append(
                {
                    "asset_id": asset["id"],
                    "class_label": asset["class_label"],
                    "x": x,
                    "y": y,
                    "z": 2,
                    "rotation": 0.0,
                    "scale": 1.0,
                    "tag": "wall_row" if idx != (len(row) // 2) else "highlight_candidate",
                }
            )

    # Floor anchors form mixed-decay clusters.
    cluster_points = [(300, 470), (1040, 500), (360, 590), (900, 610)]
    for idx, point in enumerate(cluster_points):
        if not floor_assets:
            break
        asset = floor_assets[idx % len(floor_assets)]
        placements.append(
            {
                "asset_id": asset["id"],
                "class_label": asset["class_label"],
                "x": point[0],
                "y": point[1],
                "z": 3,
                "rotation": -0.06 if idx % 2 == 0 else 0.08,
                "scale": 1.0,
                "tag": "decay_cluster",
            }
        )

    # Debris/trash follows edge-first rule to preserve center lane readability.
    edge_points = [(220, 565), (1060, 575), (330, 645), (940, 640), (120, 520), (1160, 520)]
    for idx, point in enumerate(edge_points):
        if not clutter_assets:
            break
        asset = clutter_assets[idx % len(clutter_assets)]
        placements.append(
            {
                "asset_id": asset["id"],
                "class_label": asset["class_label"],
                "x": point[0],
                "y": point[1],
                "z": 3,
                "rotation": 0.1 if idx % 2 == 0 else -0.1,
                "scale": 1.0,
                "tag": "edge_clutter",
            }
        )

    if "corridor" in scene_key:
        graffiti = next((a for a in wall_assets if a["class_label"] == "wall_decal"), None)
        if graffiti:
            placements.append(
                {
                    "asset_id": graffiti["id"],
                    "class_label": graffiti["class_label"],
                    "x": 640,
                    "y": 180,
                    "z": 4,
                    "rotation": 0.0,
                    "scale": 1.0,
                    "tag": "focal_graffiti",
                }
            )
    return placements


def main() -> None:
    catalog_payload = _load_asset_catalog()
    assets = [
        item
        for item in catalog_payload.get("assets", [])
        if item.get("placement_role") != "unassigned"
    ]
    groups = _asset_groups(assets)
    scenes = _extract_target_scenes()

    DRAFT_DIR.mkdir(parents=True, exist_ok=True)
    for scene in scenes:
        scene_key = scene["scene_key"]
        profile = _scene_profile(scene_key)
        placements = _build_placements(scene_key, groups)
        draft_payload = {
            "scene_id": scene["scene_id"],
            "scene_file": scene["scene_file"],
            "arc_dir": scene.get("arc_dir", ""),
            "scene_key": scene_key,
            "profile": profile["profile"],
            "player": {
                "scale": profile["player_scale"],
                "speed": profile["player_speed"],
            },
            "path_band": _base_path_band(scene_key),
            "composition_mode": "mixed_decay",
            "path_policy": "balanced",
            "placements": placements,
            "notes": [
                "Institutional base shape is preserved first, then disturbed via clustered decay.",
                "Edge-first clutter placement keeps the central route readable.",
            ],
        }
        out_name = f"{scene['scene_id']}_draft.json"
        (DRAFT_DIR / out_name).write_text(json.dumps(draft_payload, indent=2), encoding="utf-8")
    print(f"wrote drafts for {len(scenes)} scenes to {DRAFT_DIR.as_posix()}")


if __name__ == "__main__":
    main()
