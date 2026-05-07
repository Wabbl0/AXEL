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
SCENES_NEW_PATH = PROJECT_ROOT / "plans/AXEL_SCENES_NEW.md"

PROFILE_BY_SCENE_KEY = {
    "corridor": {"profile": "corridor_large", "player_scale": 0.82, "player_speed": 150.0},
    "classroom": {"profile": "classroom_large", "player_scale": 0.86, "player_speed": 160.0},
    "library": {"profile": "library_large", "player_scale": 0.78, "player_speed": 145.0},
    "default": {"profile": "default", "player_scale": 1.00, "player_speed": 180.0},
}


def _load_asset_catalog() -> Dict[str, object]:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


def _extract_target_scenes() -> List[Dict[str, str]]:
    scenes: List[Dict[str, str]] = []
    text = BLUEPRINT_PATH.read_text(encoding="utf-8")
    for match in re.finditer(r"###\s+\d+\.\d+\s+`([^`]+)`\s+\(`([^`]+)`\)", text):
        tscn_name = match.group(1).strip()
        scene_id = match.group(2).strip()
        lowered = tscn_name.lower()
        if any(key in lowered for key in ("corridor", "classroom", "library")):
            scenes.append({"scene_file": tscn_name, "scene_id": scene_id, "scene_key": lowered})
    if scenes:
        return scenes

    # Fallback to AXEL_SCENES_NEW.md if blueprint headings are not matched.
    backup = SCENES_NEW_PATH.read_text(encoding="utf-8").lower()
    fallback = []
    if "corridor" in backup:
        fallback.append({"scene_file": "Corridor.tscn", "scene_id": "scene_2", "scene_key": "corridor"})
    if "classroom" in backup:
        fallback.append({"scene_file": "Classroom.tscn", "scene_id": "loc_classroom", "scene_key": "classroom"})
    if "library" in backup:
        fallback.append({"scene_file": "Library.tscn", "scene_id": "loc_library", "scene_key": "library"})
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
