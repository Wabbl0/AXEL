#!/usr/bin/env python3
"""Scan and classify PNG assets for scene layout drafting."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install pillow") from exc


DEFAULT_SOURCE_ROOT = Path(
    r"C:/Users/valtt/Pictures/itch.io/moderninteriors-win/1_Interiors/48x48/"
    r"Theme_Sorter_Shadowless_Singles_48x48"
)
DEFAULT_PRIORITY_FOLDER = "5_Classroom_and_Library_Singles_Shadowless_48x48"
OUTPUT_DIR = Path("AXEL/axel_project/tools/scene_builder/output")
CATALOG_PATH = OUTPUT_DIR / "asset_catalog.json"
QUARANTINE_PATH = OUTPUT_DIR / "unassigned_assets.json"
CONFIDENCE_THRESHOLD = 0.70


CLASS_KEYWORDS: Dict[str, Tuple[str, ...]] = {
    "locker": ("locker",),
    "desk": ("desk", "table", "teacher_table"),
    "cabinet": ("cabinet", "cupboard", "drawer"),
    "shelf": ("shelf", "bookcase", "bookshelf"),
    "chair": ("chair", "stool", "seat"),
    "debris": ("debris", "rubble", "trash", "broken", "garbage"),
    "wall_decal": ("graffiti", "poster", "board", "sign"),
    "floor_misc": ("box", "bucket", "crate"),
}

ROLE_BY_CLASS = {
    "locker": "wall_prop",
    "desk": "floor_anchor",
    "cabinet": "wall_prop",
    "shelf": "floor_anchor",
    "chair": "floor_anchor",
    "debris": "floor_clutter",
    "wall_decal": "wall_prop",
    "floor_misc": "floor_clutter",
    "unknown": "unassigned",
}


@dataclass
class CandidateScore:
    label: str
    score: float


def _alpha_metrics(image: Image.Image) -> Tuple[float, Tuple[int, int, int, int]]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    histogram = alpha.histogram()
    total = sum(histogram)
    non_zero = total - histogram[0]
    coverage = float(non_zero) / float(total) if total else 0.0
    bbox = alpha.getbbox() or (0, 0, image.width, image.height)
    return coverage, bbox


def _score_from_keywords(stem: str) -> List[CandidateScore]:
    stem_l = stem.lower()
    scores = []
    for label, keys in CLASS_KEYWORDS.items():
        score = 0.0
        for key in keys:
            if key in stem_l:
                score += 0.55
        scores.append(CandidateScore(label=label, score=score))
    return scores


def _apply_geometry_hints(
    scores: List[CandidateScore], width: int, height: int, coverage: float
) -> List[CandidateScore]:
    ratio = float(width) / float(height) if height else 1.0
    score_map = {item.label: item.score for item in scores}

    if ratio < 0.72:
        score_map["locker"] = score_map.get("locker", 0.0) + 0.28
        score_map["cabinet"] = score_map.get("cabinet", 0.0) + 0.15
    elif ratio > 1.65:
        score_map["desk"] = score_map.get("desk", 0.0) + 0.22
        score_map["shelf"] = score_map.get("shelf", 0.0) + 0.12

    if coverage < 0.28:
        score_map["wall_decal"] = score_map.get("wall_decal", 0.0) + 0.25
        score_map["debris"] = score_map.get("debris", 0.0) + 0.10
    elif coverage > 0.72:
        score_map["desk"] = score_map.get("desk", 0.0) + 0.12
        score_map["cabinet"] = score_map.get("cabinet", 0.0) + 0.12

    return [CandidateScore(label=k, score=v) for k, v in score_map.items()]


def _normalize_scores(scores: List[CandidateScore]) -> List[CandidateScore]:
    ordered = sorted(scores, key=lambda item: item.score, reverse=True)
    max_score = ordered[0].score if ordered else 1.0
    if max_score <= 0.0:
        return [CandidateScore(label="unknown", score=0.0)]
    normalized = [
        CandidateScore(label=item.label, score=min(1.0, item.score / max_score))
        for item in ordered
    ]
    return normalized


def classify_png(path: Path) -> Dict[str, object]:
    with Image.open(path) as image:
        coverage, bbox = _alpha_metrics(image)
        width, height = image.size

    seed_scores = _score_from_keywords(path.stem)
    adjusted = _apply_geometry_hints(seed_scores, width, height, coverage)
    ranked = _normalize_scores(adjusted)
    top = ranked[0]

    label = top.label if top.score >= 0.01 else "unknown"
    confidence = round(float(top.score), 4)
    role = ROLE_BY_CLASS.get(label, "unassigned")

    return {
        "id": path.stem.lower(),
        "source_path": str(path.as_posix()),
        "filename": path.name,
        "width": width,
        "height": height,
        "alpha_coverage": round(coverage, 4),
        "bbox": list(map(int, bbox)),
        "aspect_ratio": round((float(width) / float(height)) if height else 0.0, 4),
        "class_label": label,
        "confidence": confidence,
        "placement_role": role,
        "top_candidates": [
            {"label": item.label, "score": round(float(item.score), 4)}
            for item in ranked[:3]
        ],
    }


def iter_pngs(source_root: Path) -> List[Path]:
    return sorted(source_root.rglob("*.png"))


def _scan_roots_from_env(source_root: Path) -> List[Path]:
    raw_dirs = os.environ.get("SCENE_BUILDER_PRIORITY_DIRS", "").strip()
    if raw_dirs:
        names = [part.strip() for part in raw_dirs.split(";") if part.strip()]
        roots = [source_root / name for name in names]
        existing = [root for root in roots if root.exists()]
        return existing if existing else [source_root]

    priority_dir = source_root / os.environ.get(
        "SCENE_BUILDER_PRIORITY_DIR", DEFAULT_PRIORITY_FOLDER
    )
    return [priority_dir] if priority_dir.exists() else [source_root]


def main() -> None:
    source_root = Path(
        os.environ.get("SCENE_BUILDER_SOURCE_ROOT", str(DEFAULT_SOURCE_ROOT))
    )
    scan_roots = _scan_roots_from_env(source_root)

    png_paths: List[Path] = []
    for root in scan_roots:
        png_paths.extend(iter_pngs(root))
    png_paths = sorted({path.as_posix(): path for path in png_paths}.values(), key=lambda p: p.as_posix())
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    catalog: List[Dict[str, object]] = []
    quarantine: List[Dict[str, object]] = []
    for png_path in png_paths:
        record = classify_png(png_path)
        if record["confidence"] < CONFIDENCE_THRESHOLD:
            record["placement_role"] = "unassigned"
            quarantine.append(record)
        catalog.append(record)

    payload = {
        "source_root": str(source_root.as_posix()),
        "scan_roots": [str(root.as_posix()) for root in scan_roots],
        "confidence_threshold": CONFIDENCE_THRESHOLD,
        "asset_count": len(catalog),
        "assets": catalog,
    }
    CATALOG_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    quarantine_payload = {
        "unassigned_count": len(quarantine),
        "assets": quarantine,
    }
    QUARANTINE_PATH.write_text(json.dumps(quarantine_payload, indent=2), encoding="utf-8")
    print(
        f"wrote {CATALOG_PATH.as_posix()} ({len(catalog)} assets), "
        f"{len(quarantine)} quarantined"
    )


if __name__ == "__main__":
    main()
