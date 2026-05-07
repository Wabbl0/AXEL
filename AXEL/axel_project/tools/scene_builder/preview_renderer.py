#!/usr/bin/env python3
"""Render lightweight layout previews and human review notes."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

try:
    from PIL import Image, ImageDraw
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install pillow") from exc


PROJECT_ROOT = Path("AXEL/axel_project")
DRAFT_DIR = PROJECT_ROOT / "tools/scene_builder/output/layout_drafts"
PREVIEW_DIR = PROJECT_ROOT / "tools/scene_builder/output/layout_previews"
VALIDATION_PATH = PROJECT_ROOT / "tools/scene_builder/output/layout_validation.json"
QUARANTINE_PATH = PROJECT_ROOT / "tools/scene_builder/output/unassigned_assets.json"
REVIEW_NOTES_PATH = PROJECT_ROOT / "tools/scene_builder/output/review_notes.md"

ROLE_COLOR = {
    "wall_row": (120, 0, 0, 255),
    "highlight_candidate": (255, 255, 255, 255),
    "focal_graffiti": (180, 0, 0, 255),
    "decay_cluster": (170, 0, 0, 255),
    "edge_clutter": (95, 0, 0, 255),
}


def _draw_draft(draft: Dict[str, object], out_path: Path) -> None:
    image = Image.new("RGBA", (1280, 720), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)

    path = draft["path_band"]
    draw.rectangle(
        [(path["x0"], path["y0"]), (path["x1"], path["y1"])],
        outline=(255, 0, 0, 255),
        width=2,
    )

    for item in draft["placements"]:
        x = int(item["x"])
        y = int(item["y"])
        role = item.get("tag", "edge_clutter")
        color = ROLE_COLOR.get(role, (120, 0, 0, 255))
        draw.rectangle([(x - 18, y - 18), (x + 18, y + 18)], fill=color)

    image.save(out_path)


def _validation_map() -> Dict[str, Dict[str, object]]:
    if not VALIDATION_PATH.exists():
        return {}
    payload = json.loads(VALIDATION_PATH.read_text(encoding="utf-8"))
    return {item["scene_id"]: item for item in payload.get("results", [])}


def _quarantine_summary() -> str:
    if not QUARANTINE_PATH.exists():
        return "- Quarantined assets: none (file not generated)."
    payload = json.loads(QUARANTINE_PATH.read_text(encoding="utf-8"))
    count = payload.get("unassigned_count", 0)
    if count == 0:
        return "- Quarantined assets: 0."
    sample = payload.get("assets", [])[:8]
    lines = [f"- Quarantined assets: {count}.", "- Sample unassigned:"]
    for asset in sample:
        lines.append(f"  - `{asset['filename']}` ({asset['confidence']})")
    return "\n".join(lines)


def _write_review_notes(drafts: List[Dict[str, object]]) -> None:
    validations = _validation_map()
    lines = [
        "# Scene Builder Draft Review Notes",
        "",
        "## Composition rationale",
        "- Base institutional structure is established before decay disruption.",
        "- Clutter is biased to edge bands to keep a readable main route.",
        "- Mixed-decay mode uses selective asymmetry instead of full collapse.",
        "",
        "## Scene checks",
    ]
    for draft in drafts:
        result = validations.get(draft["scene_id"], {})
        lines.append(f"- `{draft['scene_id']}` profile `{draft['profile']}`")
        lines.append(f"  - Path clear: `{result.get('path_clear', False)}`")
        lines.append(f"  - Route occupancy: `{result.get('route_occupancy', 'n/a')}`")
        notes = result.get("notes", [])
        if notes:
            for note in notes:
                lines.append(f"  - Note: {note}")
    lines += ["", "## Quarantine", _quarantine_summary(), ""]
    REVIEW_NOTES_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    drafts = []
    for draft_file in sorted(DRAFT_DIR.glob("*_draft.json")):
        draft = json.loads(draft_file.read_text(encoding="utf-8"))
        drafts.append(draft)
        out_name = draft_file.name.replace("_draft.json", "_preview.png")
        _draw_draft(draft, PREVIEW_DIR / out_name)
    _write_review_notes(drafts)
    print(f"rendered {len(drafts)} previews to {PREVIEW_DIR.as_posix()}")


if __name__ == "__main__":
    main()
