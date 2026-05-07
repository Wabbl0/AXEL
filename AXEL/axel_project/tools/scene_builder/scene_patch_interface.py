#!/usr/bin/env python3
"""Convert approved draft layouts into scene patch instructions."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

PROJECT_ROOT = Path("AXEL/axel_project")
APPROVAL_PATH = PROJECT_ROOT / "tools/scene_builder/output/approved_drafts.json"
DRAFT_DIR = PROJECT_ROOT / "tools/scene_builder/output/layout_drafts"
PATCH_OUT_PATH = PROJECT_ROOT / "tools/scene_builder/output/scene_patch_instructions.json"


def _load_approval() -> Dict[str, object]:
    if APPROVAL_PATH.exists():
        return json.loads(APPROVAL_PATH.read_text(encoding="utf-8"))
    return {"approved_scene_ids": []}


def _instruction_from_draft(draft: Dict[str, object]) -> Dict[str, object]:
    node_instructions: List[Dict[str, object]] = []
    for idx, item in enumerate(draft["placements"], start=1):
        node_instructions.append(
            {
                "node_name": f"AutoProp_{idx:03d}_{item['asset_id']}",
                "asset_id": item["asset_id"],
                "asset_class": item["class_label"],
                "node_type": "Sprite2D",
                "transform": {
                    "position": [item["x"], item["y"]],
                    "rotation": item["rotation"],
                    "scale": [item["scale"], item["scale"]],
                    "z_index": item["z"],
                },
                "tag": item["tag"],
            }
        )

    return {
        "scene_id": draft["scene_id"],
        "target_scene_path_hint": f"res://scenes/{draft['scene_file']}",
        "player_profile": draft["player"],
        "operations": [
            {
                "op": "ensure_group_node",
                "group_name": "AutoDraftLayout",
            },
            {
                "op": "set_player_profile",
                "scale": draft["player"]["scale"],
                "speed": draft["player"]["speed"],
            },
            {
                "op": "add_or_replace_props",
                "nodes": node_instructions,
            },
        ],
    }


def main() -> None:
    approval = _load_approval()
    approved_ids = set(approval.get("approved_scene_ids", []))
    drafts = []
    for draft_file in sorted(DRAFT_DIR.glob("*_draft.json")):
        draft = json.loads(draft_file.read_text(encoding="utf-8"))
        if draft["scene_id"] in approved_ids:
            drafts.append(_instruction_from_draft(draft))

    payload = {
        "approved_scene_ids": sorted(approved_ids),
        "instruction_count": len(drafts),
        "instructions": drafts,
        "notes": [
            "Generated only for approved scene IDs.",
            "This file is a patch interface contract and does not modify scenes directly.",
        ],
    }
    PATCH_OUT_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"wrote {PATCH_OUT_PATH.as_posix()} with {len(drafts)} scene instruction sets")


if __name__ == "__main__":
    main()
