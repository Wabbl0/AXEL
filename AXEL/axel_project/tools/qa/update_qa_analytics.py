#!/usr/bin/env python3
"""Regenerate AXEL QA analytics dashboard from run-log payloads."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]

_QA_PLANS = ROOT / "AXEL/axel_project/plans/qa"
_LEGACY_PLANS = ROOT / "AXEL/axel_project/plans"
RUN_LOG_PATH = _QA_PLANS / "AXEL_QA_RUN_LOG.md" if (_QA_PLANS / "AXEL_QA_RUN_LOG.md").exists() else _LEGACY_PLANS / "AXEL_QA_RUN_LOG.md"
ANALYTICS_PATH = _QA_PLANS / "AXEL_QA_ANALYTICS.md" if _QA_PLANS.exists() else _LEGACY_PLANS / "AXEL_QA_ANALYTICS.md"
ANALYTICS_SVG_PATH = _QA_PLANS / "AXEL_QA_ANALYTICS.svg" if _QA_PLANS.exists() else _LEGACY_PLANS / "AXEL_QA_ANALYTICS.svg"

BEGIN_MARKER = "<!-- QA_ANALYTICS_JSON_BEGIN -->"
END_MARKER = "<!-- QA_ANALYTICS_JSON_END -->"
JSON_BLOCK_PATTERN = re.compile(
    rf"{re.escape(BEGIN_MARKER)}\s*(\{{.*?\}})\s*{re.escape(END_MARKER)}",
    re.DOTALL,
)

# Default when payload omits checklist_total_weight (keep in sync with QA_PROGRESS_CHECKLIST.md).
DEFAULT_CHECKLIST_TOTAL_WEIGHT = 200

# Left axis: expandable project points from milestone weights.
POINTS_SERIES_ORDER = ["ProgressPoints", "ScopeCeiling"]
POINTS_SERIES_COLORS = {
    "ProgressPoints": "#52c41a",
    "ScopeCeiling": "#597ef7",
}
POINTS_SERIES_LABELS = {
    "ProgressPoints": "Progress (pts completed)",
    "ScopeCeiling": "Scope ceiling (checklist total pts)",
}

# Right axis: subjective build quality (fixed 0..5).
QUALITY_SERIES_NAME = "Quality"
QUALITY_SERIES_COLOR = "#ff4d4f"
QUALITY_AXIS_MAX = 5.0

# Secondary axis breakdown + legacy weighted total.
SECONDARY_SERIES_ORDER = ["Total", "S", "N", "I", "E", "C", "R"]
SECONDARY_SERIES_COLORS = {
    "Total": "#ff7875",
    "S": "#40a9ff",
    "N": "#73d13d",
    "I": "#9254de",
    "E": "#faad14",
    "C": "#13c2c2",
    "R": "#eb2f96",
}
SECONDARY_SERIES_LABELS = {
    "Total": "Total (legacy weighted)",
    "S": "S (Style)",
    "N": "N (Narrative)",
    "I": "I (Immersion)",
    "E": "E (Excitement)",
    "C": "C (Clarity)",
    "R": "R (Regression Risk)",
}

POINTS_STROKE_WIDTH = 4
QUALITY_STROKE_WIDTH = 3
QUALITY_AXIS_STROKE_WIDTH = 2
# Right-axis rubric breakdown (0..5); Total is drawn as the bold Quality line.
QUALITY_AXIS_SERIES_ORDER = ["S", "N", "I", "E", "C", "R"]
MARKDOWN_AXIS_ORDER = ["Total", "S", "N", "I", "E", "C", "R"]


def _safe_float(value: Any) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _safe_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def _parse_payloads(text: str) -> list[dict[str, Any]]:
    payloads: list[dict[str, Any]] = []
    for match in JSON_BLOCK_PATTERN.finditer(text):
        raw_json = match.group(1)
        try:
            payload = json.loads(raw_json)
        except json.JSONDecodeError:
            continue
        if isinstance(payload, dict):
            ts_val = _get_timestamp_value(payload)
            if "YYYY-MM-DD" in ts_val or "<" in ts_val or ">" in ts_val:
                continue
            payloads.append(payload)
    return payloads


def _get_timestamp_value(payload: dict[str, Any]) -> str:
    """Return the best available date/time string from a payload, checking both key names."""
    for key in ("timestamp", "run_date"):
        val = payload.get(key)
        if val and isinstance(val, str) and val.strip():
            return val.strip()
    return ""


def _parse_timestamp(value: Any) -> datetime:
    raw = str(value or "").strip()
    if not raw:
        return datetime.min.replace(tzinfo=timezone.utc)
    normalized = raw.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(normalized)
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _sort_payloads(payloads: list[dict[str, Any]]) -> list[dict[str, Any]]:
    indexed = list(enumerate(payloads))
    indexed.sort(key=lambda item: (_parse_timestamp(_get_timestamp_value(item[1])), item[0]))
    return [payload for _, payload in indexed]


def _quality_scores_dict(payload: dict[str, Any]) -> dict[str, Any]:
    quality = payload.get("quality")
    if isinstance(quality, dict) and quality.get("Total") is not None:
        return quality
    scores = payload.get("scores")
    if isinstance(scores, dict):
        return scores
    return {}


def _quality_total_for_payload(payload: dict[str, Any]) -> float:
    q = _quality_scores_dict(payload)
    return round(_safe_float(q.get("Total", 0.0)), 2)


def _progress_score_for_payload(payload: dict[str, Any]) -> float | None:
    progress = payload.get("progress")
    if isinstance(progress, dict) and progress.get("score") is not None:
        return round(_safe_float(progress["score"]), 2)
    return None


def _progress_points_meta(payload: dict[str, Any]) -> tuple[int | None, int]:
    """Return (completed_weight, total_weight) for charting. completed is None if unknown."""
    progress = payload.get("progress")
    total = DEFAULT_CHECKLIST_TOTAL_WEIGHT
    completed: int | None = None
    if isinstance(progress, dict):
        tw = _safe_int(progress.get("checklist_total_weight", 0))
        if tw > 0:
            total = tw
        cw_raw = progress.get("checklist_completed_weight")
        if cw_raw is not None:
            completed = max(0, _safe_int(cw_raw))
        elif progress.get("score") is not None:
            # Legacy 0..5 score → approximate points for continuity.
            completed = round(_safe_float(progress["score"]) / 5.0 * total)
    return completed, total


def _nice_axis_max(max_value: float) -> float:
    """Round up to a readable tick ceiling for the points axis."""
    if max_value <= 0:
        return float(DEFAULT_CHECKLIST_TOTAL_WEIGHT)
    padded = max_value * 1.1
    if padded <= 50:
        return 50.0
    if padded <= 150:
        return float((((int(padded) + 24) // 25) * 25))
    if padded <= 400:
        return float((((int(padded) + 49) // 50) * 50))
    return float((((int(padded) + 99) // 100) * 100))


def _axis_tick_values(axis_max: float, target_ticks: int = 5) -> list[float]:
    if axis_max <= 0:
        return [0.0]
    step = axis_max / max(target_ticks, 1)
    if step <= 0:
        return [0.0, axis_max]
    # Prefer integer steps
    magnitude = 10 ** max(0, int(len(str(int(step))) - 1))
    step = max(magnitude, round(step / magnitude) * magnitude)
    ticks: list[float] = []
    v = 0.0
    while v <= axis_max + 0.001:
        ticks.append(round(v, 2))
        v += step
    if ticks[-1] < axis_max:
        ticks.append(round(axis_max, 2))
    return ticks


def _extract_series(
    payloads: list[dict[str, Any]],
) -> tuple[
    list[str],
    list[dict[str, str]],
    dict[str, list[float | None]],
    list[float | None],
    dict[str, list[float]],
    float,
]:
    labels: list[str] = []
    x_ticks: list[dict[str, str]] = []
    points: dict[str, list[float | None]] = {name: [] for name in POINTS_SERIES_ORDER}
    quality: list[float | None] = []
    markdown_axes: dict[str, list[float]] = {name: [] for name in MARKDOWN_AXIS_ORDER}
    max_observed = 0.0

    for index, payload in enumerate(payloads, start=1):
        timestamp = _get_timestamp_value(payload)
        date_short = timestamp[5:10] if len(timestamp) >= 10 else "?"
        labels.append(f"R{index}")
        scope_short = str(payload.get("scope", ""))[:48]
        if len(str(payload.get("scope", ""))) > 48:
            scope_short += "…"
        x_ticks.append(
            {
                "run": f"R{index}",
                "date": date_short,
                "full_date": timestamp[:10] if timestamp else "undated",
                "scope": scope_short,
            }
        )

        completed, total = _progress_points_meta(payload)
        points["ProgressPoints"].append(float(completed) if completed is not None else None)
        points["ScopeCeiling"].append(float(total))
        if completed is not None:
            max_observed = max(max_observed, float(completed))
        max_observed = max(max_observed, float(total))

        q_total = _quality_total_for_payload(payload)
        quality.append(q_total)

        q = _quality_scores_dict(payload)
        for name in MARKDOWN_AXIS_ORDER:
            markdown_axes[name].append(round(_safe_float(q.get(name, 0.0)), 2))

    axis_max = _nice_axis_max(max_observed)
    return labels, x_ticks, points, quality, markdown_axes, axis_max


def _format_values(values: list[float]) -> str:
    return ", ".join(f"{value:g}" for value in values)


def _format_optional_values(values: list[float | None]) -> str:
    parts: list[str] = []
    for value in values:
        parts.append("null" if value is None else f"{value:g}")
    return ", ".join(parts)


def _render_empty_markdown() -> str:
    now = datetime.now(timezone.utc).isoformat()
    return (
        "# AXEL QA Analytics\n\n"
        "Auto-generated from `AXEL_QA_RUN_LOG.md` by `tools/qa/update_qa_analytics.py`.\n\n"
        f"- Last generated (UTC): `{now}`\n"
        "- Runs parsed: `0`\n\n"
        "## Score interpretation\n\n"
        "- **Progress (points)** — sum of completed milestone weights; Y-axis grows when the checklist expands.\n"
        "- **Scope ceiling** — total possible points that run (`checklist_total_weight`).\n"
        "- **Quality (0–5)** — right axis only; build readiness, not completion.\n\n"
        "## Latest snapshot\n\n"
        "No QA runs parsed yet. Add a run entry with a `QA_ANALYTICS_JSON` payload block.\n\n"
        "## Trend chart\n\n"
        "No data yet.\n"
    )


def _svg_escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def _quadratic_smooth_path_d(points: list[tuple[float, float]]) -> str:
    """Gentle quadratic smoothing through chart points."""
    n = len(points)
    if n < 2:
        return ""
    if n == 2:
        return (
            f"M {points[0][0]:.2f},{points[0][1]:.2f} "
            f"L {points[1][0]:.2f},{points[1][1]:.2f}"
        )
    parts = [f"M {points[0][0]:.2f},{points[0][1]:.2f}"]
    for i in range(1, n - 1):
        cpx, cpy = points[i]
        ex = (points[i][0] + points[i + 1][0]) / 2
        ey = (points[i][1] + points[i + 1][1]) / 2
        parts.append(f"Q {cpx:.2f},{cpy:.2f} {ex:.2f},{ey:.2f}")
    parts.append(f"T {points[-1][0]:.2f},{points[-1][1]:.2f}")
    return " ".join(parts)


def _append_smooth_path(
    lines: list[str],
    points: list[tuple[float, float]],
    color: str,
    stroke_width: int,
    dashed: bool = False,
) -> None:
    if len(points) < 2:
        return
    d = _quadratic_smooth_path_d(points)
    dash = ' stroke-dasharray="6,4"' if dashed else ""
    lines.append(
        f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{stroke_width}"{dash}/>'
    )


def _plot_series_with_gaps(
    lines: list[str],
    values: list[float | None],
    color: str,
    stroke_width: int,
    x_for: Any,
    y_for: Any,
    dashed: bool = False,
) -> None:
    segment: list[tuple[float, float]] = []
    for i, value in enumerate(values):
        if value is None:
            _append_smooth_path(lines, segment, color, stroke_width, dashed)
            segment = []
            continue
        segment.append((x_for(i), y_for(value)))
    _append_smooth_path(lines, segment, color, stroke_width, dashed)


def _legend_text_width(label: str, char_w: float = 6.8) -> float:
    return len(label) * char_w


def _legend_row_extent(items: list[tuple[str, list[str], bool, int]], line_h: float = 14) -> float:
    """Vertical space used below the swatch baseline for a legend row."""
    if not items:
        return 0.0
    max_lines = max(len(label_lines) for _c, label_lines, _d, _s in items)
    return 12.0 + (max_lines - 1) * line_h + 16.0


def _append_centered_legend_items(
    lines: list[str],
    y: float,
    plot_left: float,
    plot_right: float,
    items: list[tuple[str, list[str], bool, int]],
) -> float:
    """items: (color, label_lines, dashed, stroke_width). Returns row height below swatch line."""
    swatch = 32
    gap = 8
    between = 40
    char_w = 6.8
    line_h = 14
    widths: list[float] = []
    for _color, label_lines, _dashed, _sw in items:
        w = swatch + gap + max(_legend_text_width(line, char_w) for line in label_lines)
        widths.append(w)
    total = sum(widths) + between * max(0, len(items) - 1)
    start_x = (plot_left + plot_right) / 2 - total / 2
    x = start_x
    for (color, label_lines, dashed, sw), w in zip(items, widths):
        dash_attr = ' stroke-dasharray="6,4"' if dashed else ""
        lines.append(
            f'<line x1="{x:.2f}" y1="{y}" x2="{x + swatch:.2f}" y2="{y}" '
            f'stroke="{color}" stroke-width="{sw}"{dash_attr}/>'
        )
        text_x = x + swatch + gap
        n_lines = len(label_lines)
        # Anchor text below the swatch line so multi-line labels do not climb into x-axis ticks.
        y0 = y + 12
        for li, line in enumerate(label_lines):
            single_muted = len(label_lines) == 1 and sw <= 3
            weight = ' font-weight="700"' if li == 0 and not single_muted else ""
            fill = "#a6a6a6" if single_muted else ("#d9d9d9" if li == 0 else "#bfbfbf")
            size = "12" if single_muted else ("14" if li == 0 else "12")
            lines.append(
                f'<text x="{text_x:.2f}" y="{y0 + li * line_h:.2f}" fill="{fill}" '
                f'font-family="Segoe UI, Arial, sans-serif" font-size="{size}"{weight}>{line}</text>'
            )
        x += w + between
    return _legend_row_extent(items, line_h)


def _build_svg_chart(
    labels: list[str],
    x_ticks: list[dict[str, str]],
    points: dict[str, list[float | None]],
    quality: list[float | None],
    quality_axes: dict[str, list[float]],
    axis_max_points: float,
) -> str:
    width = 1220
    margin_left = 58
    margin_right = 52
    margin_top = 48
    plot_left = margin_left
    plot_right = width - margin_right - 36
    plot_top = margin_top
    # Footer band below plot: x-axis ticks, primary legend row, rubric row.
    x_run_y_offset = 14
    x_date_y_offset = 28
    legend_after_dates_gap = 10
    legend_row_gap = 18
    legend_footer_pad = 14
    margin_bottom = 148
    height = 708
    plot_bottom = height - margin_bottom
    plot_width = plot_right - plot_left
    plot_height = plot_bottom - plot_top
    right_axis_x = width - margin_right
    right_tick_x = right_axis_x + 8
    right_title_x = right_axis_x + 22
    x_run_y = plot_bottom + x_run_y_offset
    x_date_y = plot_bottom + x_date_y_offset

    count = max(len(labels), 1)
    step_x = 0 if count == 1 else plot_width / (count - 1)
    points_max = max(axis_max_points, 1.0)

    def x_for(idx: int) -> float:
        return plot_left + (idx * step_x)

    def y_points(value: float) -> float:
        clamped = min(max(value, 0.0), points_max)
        return plot_bottom - (clamped / points_max) * plot_height

    def y_quality(value: float) -> float:
        clamped = min(max(value, 0.0), QUALITY_AXIS_MAX)
        return plot_bottom - (clamped / QUALITY_AXIS_MAX) * plot_height

    title_x = (plot_left + plot_right) / 2
    lines: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect x="0" y="0" width="100%" height="100%" fill="#0f1116"/>',
        f'<text x="{title_x:.0f}" y="32" text-anchor="middle" fill="#d9d9d9" '
        f'font-family="Segoe UI, Arial, sans-serif" font-size="24" font-weight="600">'
        f"AXEL QA — Project Points + Quality</text>",
        f'<line x1="{plot_left}" y1="{plot_top}" x2="{plot_left}" y2="{plot_bottom}" stroke="#8c8c8c" stroke-width="2"/>',
        f'<line x1="{plot_left}" y1="{plot_bottom}" x2="{plot_right}" y2="{plot_bottom}" stroke="#8c8c8c" stroke-width="2"/>',
        f'<line x1="{right_axis_x}" y1="{plot_top}" x2="{right_axis_x}" y2="{plot_bottom}" stroke="#8c8c8c" stroke-width="2"/>',
    ]

    for tick in _axis_tick_values(points_max):
        y = y_points(tick)
        lines.append(
            f'<line x1="{plot_left}" y1="{y:.2f}" x2="{plot_right}" y2="{y:.2f}" '
            f'stroke="#2f3540" stroke-width="1"/>'
        )
        label = f"{int(tick)}" if tick == int(tick) else f"{tick:g}"
        lines.append(
            f'<text x="{plot_left - 10}" y="{y + 5:.2f}" text-anchor="end" fill="#bfbfbf" '
            f'font-family="Segoe UI, Arial, sans-serif" font-size="13">{label}</text>'
        )

    lines.append(
        f'<text x="{plot_left - 36}" y="{(plot_top + plot_bottom) / 2:.0f}" text-anchor="middle" '
        f'fill="#8c8c8c" font-family="Segoe UI, Arial, sans-serif" font-size="12" '
        f'transform="rotate(-90 {plot_left - 36} {(plot_top + plot_bottom) / 2:.0f})">Project points</text>'
    )

    axis_mid_y = (plot_top + plot_bottom) / 2
    for q_tick in range(0, 6):
        y = y_quality(float(q_tick))
        lines.append(
            f'<text x="{right_tick_x}" y="{y + 5:.2f}" text-anchor="start" fill="#bfbfbf" '
            f'font-family="Segoe UI, Arial, sans-serif" font-size="13">{q_tick}</text>'
        )

    lines.append(
        f'<text x="{right_title_x}" y="{axis_mid_y:.0f}" text-anchor="middle" '
        f'fill="#8c8c8c" font-family="Segoe UI, Arial, sans-serif" font-size="12" '
        f'transform="rotate(-90 {right_title_x} {axis_mid_y:.0f})">Quality</text>'
    )

    tick_font = 11 if count > 24 else 13
    date_font = 10 if count > 24 else 11
    for idx, tick in enumerate(x_ticks):
        x = x_for(idx)
        run_id = _svg_escape(tick.get("run", labels[idx] if idx < len(labels) else f"R{idx + 1}"))
        date_id = _svg_escape(tick.get("date", "?"))
        lines.append(
            f'<text x="{x:.2f}" y="{x_run_y}" text-anchor="middle" fill="#d9d9d9" '
            f'font-family="Segoe UI, Arial, sans-serif" font-size="{tick_font}" font-weight="600">{run_id}</text>'
        )
        lines.append(
            f'<text x="{x:.2f}" y="{x_date_y}" text-anchor="middle" fill="#9a9a9a" '
            f'font-family="Segoe UI, Arial, sans-serif" font-size="{date_font}">{date_id}</text>'
        )

    # Rubric axes on right (0..5), under everything else
    for name in QUALITY_AXIS_SERIES_ORDER:
        values = quality_axes.get(name, [])
        if not values:
            continue
        color = SECONDARY_SERIES_COLORS[name]
        numeric: list[float | None] = [float(v) for v in values]
        _plot_series_with_gaps(
            lines,
            numeric,
            color,
            QUALITY_AXIS_STROKE_WIDTH,
            x_for,
            y_quality,
            dashed=True,
        )

    # Left axis: scope ceiling then progress
    ceiling = points.get("ScopeCeiling", [])
    if ceiling and not all(v is None for v in ceiling):
        _plot_series_with_gaps(
            lines,
            ceiling,
            POINTS_SERIES_COLORS["ScopeCeiling"],
            POINTS_STROKE_WIDTH - 1,
            x_for,
            y_points,
            dashed=True,
        )

    progress_pts = points.get("ProgressPoints", [])
    if progress_pts and not all(v is None for v in progress_pts):
        _plot_series_with_gaps(
            lines,
            progress_pts,
            POINTS_SERIES_COLORS["ProgressPoints"],
            POINTS_STROKE_WIDTH,
            x_for,
            y_points,
            dashed=False,
        )

    # Weighted Total = Quality (bold, right axis)
    if quality and not all(v is None for v in quality):
        _plot_series_with_gaps(
            lines,
            quality,
            QUALITY_SERIES_COLOR,
            QUALITY_STROKE_WIDTH,
            x_for,
            y_quality,
            dashed=False,
        )

    primary_legend: list[tuple[str, list[str], bool, int]] = []
    if ceiling and not all(v is None for v in ceiling):
        primary_legend.append(
            (
                POINTS_SERIES_COLORS["ScopeCeiling"],
                ["Scope ceiling", "(checklist total pts)"],
                True,
                4,
            )
        )
    if progress_pts and not all(v is None for v in progress_pts):
        primary_legend.append(
            (
                POINTS_SERIES_COLORS["ProgressPoints"],
                ["Progress points"],
                False,
                5,
            )
        )
    if quality and not all(v is None for v in quality):
        primary_legend.append(
            (
                QUALITY_SERIES_COLOR,
                ["Quality / Total", "(0–5)"],
                False,
                5,
            )
        )

    secondary_legend: list[tuple[str, list[str], bool, int]] = [
        (
            SECONDARY_SERIES_COLORS[name],
            [SECONDARY_SERIES_LABELS[name]],
            True,
            3,
        )
        for name in QUALITY_AXIS_SERIES_ORDER
    ]

    secondary_extent = _legend_row_extent(secondary_legend)
    primary_extent = _legend_row_extent(primary_legend)
    legend_primary_y = x_date_y + legend_after_dates_gap
    legend_secondary_y = legend_primary_y + primary_extent + legend_row_gap

    if primary_legend:
        _append_centered_legend_items(
            lines, legend_primary_y, plot_left, plot_right, primary_legend
        )

    if secondary_legend:
        _append_centered_legend_items(
            lines, legend_secondary_y, plot_left, plot_right, secondary_legend
        )

    footer_bottom = legend_secondary_y + secondary_extent + legend_footer_pad
    if primary_legend and not secondary_legend:
        footer_bottom = legend_primary_y + primary_extent + legend_footer_pad
    if footer_bottom + 4 > height:
        height = int(footer_bottom + 4)
        lines[0] = (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}">'
        )

    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def _progress_snapshot_text(payload: dict[str, Any]) -> str:
    completed, total = _progress_points_meta(payload)
    progress = payload.get("progress")
    if completed is None and not isinstance(progress, dict):
        return "not recorded (legacy run)"
    score = progress.get("score") if isinstance(progress, dict) else None
    gate = progress.get("gate_state", "?") if isinstance(progress, dict) else "?"
    cap = progress.get("gate_cap", "?") if isinstance(progress, dict) else "?"
    pts = f"{completed}/{total} pts" if completed is not None else f"?/{total} pts"
    pct = (completed / total * 100.0) if completed is not None and total > 0 else 0.0
    if isinstance(progress, dict) and progress.get("checklist_completion") is not None:
        pct = _safe_float(progress.get("checklist_completion", 0.0)) * 100.0
    extra = f" score={score}" if score is not None else ""
    return f"{pts} ({pct:.0f}%) gate={gate} cap={cap}{extra}"


def _render_canon_audit_section(payloads: list[dict[str, Any]]) -> str:
    runs_with_canon: list[dict[str, Any]] = []
    for payload in payloads:
        canon = payload.get("canon_audit")
        if isinstance(canon, dict) and canon.get("findings_count"):
            runs_with_canon.append(payload)
    if not runs_with_canon:
        return ""

    latest = runs_with_canon[-1]
    canon = latest.get("canon_audit", {})
    if not isinstance(canon, dict):
        return ""

    counts = canon.get("findings_count", {})
    if not isinstance(counts, dict):
        counts = {}
    by_cat = canon.get("by_category", {})
    if not isinstance(by_cat, dict):
        by_cat = {}

    lines: list[str] = [
        "## Canon Consistency Audit (latest)\n",
        f"- Findings: blocker=`{_safe_int(counts.get('blocker'))}` "
        f"major=`{_safe_int(counts.get('major'))}` "
        f"minor=`{_safe_int(counts.get('minor'))}` "
        f"nit=`{_safe_int(counts.get('nit'))}`",
    ]
    if by_cat:
        cat_bits = " ".join(f"{k}={_safe_int(v)}" for k, v in sorted(by_cat.items()))
        lines.append(f"- By category: `{cat_bits}`")

    findings = canon.get("findings", [])
    if isinstance(findings, list) and findings:
        lines.append("\n### Top findings\n")
        for item in findings[:8]:
            if not isinstance(item, dict):
                continue
            lines.append(
                f"- `{item.get('severity', '?')}` | `{item.get('category', '?')}` | "
                f"`{item.get('id', '?')}` — {item.get('evidence', '')}"
            )
        if len(findings) > 8:
            lines.append(f"- … and `{len(findings) - 8}` more (see run log JSON).")
    lines.append("")
    return "\n".join(lines)


def _render_item_balance_section(payloads: list[dict[str, Any]]) -> str:
    runs_with_items: list[dict[str, Any]] = []
    for payload in payloads:
        ib = payload.get("item_balance")
        if isinstance(ib, dict) and ib.get("items_tested", 0) > 0:
            runs_with_items.append(payload)
    if not runs_with_items:
        return ""

    lines: list[str] = [
        "## Item Balance Summary\n",
        f"Runs with item data: `{len(runs_with_items)}`\n",
    ]

    latest = runs_with_items[-1]
    ib = latest.get("item_balance", {})
    items_tested = ib.get("items_tested", 0)
    overpowered = ib.get("items_overpowered", [])
    underpowered = ib.get("items_underpowered", [])
    neutral = ib.get("items_neutral", [])
    insufficient = ib.get("items_insufficient_data", [])

    lines.append(f"- Items tested (latest): `{items_tested}`")
    lines.append(f"- Overpowered: `{', '.join(overpowered) if overpowered else 'none'}`")
    lines.append(f"- Underpowered: `{', '.join(underpowered) if underpowered else 'none'}`")
    lines.append(f"- Neutral: `{len(neutral)}`")
    lines.append(f"- Insufficient data: `{len(insufficient)}`\n")

    item_metrics = latest.get("item_metrics")
    if isinstance(item_metrics, list) and item_metrics:
        lines.append("### Latest per-item deltas\n")
        lines.append("| Item | Label | ΔRTP | CI95 | ΔHit Rate | ΔEnc. Success |")
        lines.append("|------|-------|------|------|-----------|---------------|")
        for im in item_metrics:
            if not isinstance(im, dict):
                continue
            item_id = im.get("item_id", "?")
            label = im.get("label", "?")
            delta_rtp = im.get("delta_rtp", 0.0)
            ci95 = im.get("delta_rtp_ci95", [0.0, 0.0])
            delta_hr = im.get("delta_hit_rate", 0.0)
            delta_es = im.get("delta_encounter_success", 0.0)
            ci_str = f"[{ci95[0]:+.4f}, {ci95[1]:+.4f}]" if isinstance(ci95, list) and len(ci95) == 2 else "n/a"
            lines.append(
                f"| `{item_id}` | **{label}** | `{delta_rtp:+.4f}` | `{ci_str}` | `{delta_hr:+.4f}` | `{delta_es:+.4f}` |"
            )
        lines.append("")

    if len(runs_with_items) >= 2:
        prev_ib = runs_with_items[-2].get("item_balance", {})
        prev_op = set(prev_ib.get("items_overpowered", []))
        prev_up = set(prev_ib.get("items_underpowered", []))
        curr_op = set(overpowered)
        curr_up = set(underpowered)
        new_op = curr_op - prev_op
        new_up = curr_up - prev_up
        resolved_op = prev_op - curr_op
        resolved_up = prev_up - curr_up
        if new_op or new_up or resolved_op or resolved_up:
            lines.append("### Classification changes vs previous\n")
            if new_op:
                lines.append(f"- Newly overpowered: `{', '.join(sorted(new_op))}`")
            if new_up:
                lines.append(f"- Newly underpowered: `{', '.join(sorted(new_up))}`")
            if resolved_op:
                lines.append(f"- No longer overpowered: `{', '.join(sorted(resolved_op))}`")
            if resolved_up:
                lines.append(f"- No longer underpowered: `{', '.join(sorted(resolved_up))}`")
            lines.append("")

    return "\n".join(lines)


def _render_run_index_table(x_ticks: list[dict[str, str]]) -> str:
    if not x_ticks:
        return ""
    rows: list[str] = [
        "## Run index (chart x-axis)\n",
        "| Run | Date | Scope |",
        "|-----|------|-------|",
    ]
    for tick in x_ticks:
        scope = tick.get("scope", "").replace("|", "\\|")
        rows.append(
            f"| `{tick.get('run', '?')}` | `{tick.get('full_date', '?')}` | {scope} |"
        )
    rows.append("")
    return "\n".join(rows)


def _delta_line(name: str, latest_val: float | None, prev_val: float | None) -> str:
    if latest_val is None:
        return f"- `{name}`: `n/a`"
    if prev_val is None:
        return f"- `{name}`: `{latest_val:.2f}` (n/a previous)"
    diff = latest_val - prev_val
    return f"- `{name}`: `{latest_val:.2f}` (`{diff:+.2f}` vs previous)"


def _render_markdown(payloads: list[dict[str, Any]]) -> str:
    if not payloads:
        return _render_empty_markdown()

    labels, x_ticks, points, quality, markdown_axes, axis_max = _extract_series(payloads)
    now = datetime.now(timezone.utc).isoformat()
    latest = payloads[-1]
    previous = payloads[-2] if len(payloads) > 1 else None

    latest_quality = _quality_total_for_payload(latest)
    prev_quality = _quality_total_for_payload(previous) if previous else None
    latest_completed, latest_total = _progress_points_meta(latest)
    prev_completed, prev_total = (
        _progress_points_meta(previous) if previous else (None, DEFAULT_CHECKLIST_TOTAL_WEIGHT)
    )

    latest_mode = str(latest.get("mode", "unknown"))
    latest_scope = str(latest.get("scope", ""))
    latest_trigger = str(latest.get("trigger", ""))

    findings = latest.get("findings_count", {}) if isinstance(latest.get("findings_count", {}), dict) else {}
    categories = latest.get("by_category", {}) if isinstance(latest.get("by_category", {}), dict) else {}
    bugs = latest.get("bugs_or_regressions", [])
    if not isinstance(bugs, list):
        bugs = []

    progress_text = _progress_snapshot_text(latest)

    latest_pts = float(latest_completed) if latest_completed is not None else None
    prev_pts = float(prev_completed) if prev_completed is not None else None

    delta_lines: list[str] = [
        _delta_line("ProgressPoints", latest_pts, prev_pts),
        _delta_line("ScopeCeiling", float(latest_total), float(prev_total)),
        _delta_line("Quality", latest_quality, prev_quality),
    ]
    for name in MARKDOWN_AXIS_ORDER:
        values = markdown_axes.get(name, [])
        latest_val = values[-1] if values else 0.0
        prev_val = values[-2] if len(values) >= 2 else None
        delta_lines.append(_delta_line(name, latest_val, prev_val))

    chart_lines = [
        "```mermaid",
        "xychart-beta",
        '  title "AXEL QA — Project points (auto scale)"',
        f'  x-axis ["{"\", \"".join(labels)}"]',
        f'  y-axis "Points" 0 --> {int(axis_max)}',
        f"  line [{_format_optional_values(points['ProgressPoints'])}]",
        f"  line [{_format_values(points['ScopeCeiling'])}]",
        "```",
    ]
    legend_text = (
        f"SVG: left = project points (0–{int(axis_max)}+); right = Quality + S/N/I/E/C/R (0–5). "
        "Mermaid fallback shows points lines only."
    )

    severity_text = (
        f"blocker={_safe_int(findings.get('blocker'))} "
        f"major={_safe_int(findings.get('major'))} "
        f"minor={_safe_int(findings.get('minor'))} "
        f"nit={_safe_int(findings.get('nit'))}"
    )

    category_keys = ["STYLE", "LORE", "IMMERSION", "TENSION", "CLARITY", "COMBAT", "ARCH", "REGRESSION", "BUG", "TOOL"]
    category_text = " ".join(f"{key}={_safe_int(categories.get(key))}" for key in category_keys)

    bugs_text = "; ".join(str(item) for item in bugs) if bugs else "none"

    item_section = _render_item_balance_section(payloads)
    canon_section = _render_canon_audit_section(payloads)

    item_audit_status = ""
    canon_audit_status = ""
    pt_cmds = latest.get("playtest_commands", {})
    if isinstance(pt_cmds, dict):
        if "item_balance_audit" in pt_cmds:
            item_audit_status = f"- Item balance audit: `{pt_cmds['item_balance_audit']}`\n"
        if "canon_consistency_audit" in pt_cmds:
            canon_audit_status = f"- Canon consistency audit: `{pt_cmds['canon_consistency_audit']}`\n"

    q_band = _quality_scores_dict(latest).get("Band", "?")

    return (
        "# AXEL QA Analytics\n\n"
        "Auto-generated from `AXEL_QA_RUN_LOG.md` by `tools/qa/update_qa_analytics.py`.\n\n"
        f"- Last generated (UTC): `{now}`\n"
        f"- Runs parsed: `{len(payloads)}`\n\n"
        "## Score interpretation\n\n"
        f"- **Progress (points)** — sum of completed milestone weights (left axis, 0–{int(axis_max)}+).\n"
        "- **Scope ceiling** — `checklist_total_weight` for that QA run: the maximum points possible if every milestone in `QA_PROGRESS_CHECKLIST.md` were done. The dashed blue line steps up when you add milestones (e.g. 149 → 200). It is **not** a score — it is the size of the project definition.\n"
        "- **Quality / Total** — weighted rubric score 0–5 (bold red, right axis).\n"
        "- **S, N, I, E, C, R** — rubric axis breakdown 0–5 (dashed, right axis).\n"
        "- **Neither** points nor Quality alone means ship-ready.\n\n"
        "## Latest snapshot\n\n"
        f"- Mode: `{latest_mode}`\n"
        f"- Scope: `{latest_scope}`\n"
        f"- Trigger: `{latest_trigger}`\n"
        f"- **Progress:** `{progress_text}`\n"
        f"- **Quality:** `Total={latest_quality:.2f}` Band=`{q_band}`\n"
        f"- Findings: `{severity_text}`\n"
        f"- Categories: `{category_text}`\n"
        f"- Bugs/problems: `{bugs_text}`\n"
        + item_audit_status
        + canon_audit_status
        + "\n"
        + canon_section
        + "## Latest deltas vs previous run\n\n"
        + "\n".join(delta_lines)
        + "\n\n## Trend chart (project points + quality)\n\n"
        + _render_run_index_table(x_ticks)
        + "![AXEL QA Analytics](AXEL_QA_ANALYTICS.svg)\n\n"
        + "Chart x-axis: `R1`, `R2`, … with `MM-DD` below; full dates and scopes in the run index table.\n\n"
        + "Fallback Mermaid view:\n\n"
        + "\n".join(chart_lines)
        + "\n\n- "
        + legend_text
        + "\n"
        + ("\n" + item_section if item_section else "")
    )


def _collect_all_payloads() -> list[dict[str, Any]]:
    all_payloads: list[dict[str, Any]] = []
    if RUN_LOG_PATH.exists():
        all_payloads.extend(_parse_payloads(RUN_LOG_PATH.read_text(encoding="utf-8")))
    archive_dir = RUN_LOG_PATH.parent / "archive"
    if archive_dir.is_dir():
        for archive_file in sorted(archive_dir.glob("*.md")):
            all_payloads.extend(_parse_payloads(archive_file.read_text(encoding="utf-8")))
    return _sort_payloads(all_payloads)


def main() -> int:
    payloads = _collect_all_payloads()
    rendered = _render_markdown(payloads)
    ANALYTICS_PATH.write_text(rendered, encoding="utf-8")
    if payloads:
        labels, x_ticks, points, quality, quality_axes, axis_max = _extract_series(payloads)
        ANALYTICS_SVG_PATH.write_text(
            _build_svg_chart(labels, x_ticks, points, quality, quality_axes, axis_max),
            encoding="utf-8",
        )
    else:
        ANALYTICS_SVG_PATH.write_text("", encoding="utf-8")
    print(f"Updated analytics: {ANALYTICS_PATH}")
    print(f"Updated analytics chart: {ANALYTICS_SVG_PATH}")
    print(f"Payloads parsed: {len(payloads)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
