#!/usr/bin/env python3
"""Regenerate AXEL QA analytics dashboard from run-log payloads."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[4]
RUN_LOG_PATH = ROOT / "AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md"
ANALYTICS_PATH = ROOT / "AXEL/axel_project/plans/AXEL_QA_ANALYTICS.md"
ANALYTICS_SVG_PATH = ROOT / "AXEL/axel_project/plans/AXEL_QA_ANALYTICS.svg"

BEGIN_MARKER = "<!-- QA_ANALYTICS_JSON_BEGIN -->"
END_MARKER = "<!-- QA_ANALYTICS_JSON_END -->"
JSON_BLOCK_PATTERN = re.compile(
    rf"{re.escape(BEGIN_MARKER)}\s*(\{{.*?\}})\s*{re.escape(END_MARKER)}",
    re.DOTALL,
)

SERIES_ORDER = ["Total", "S", "N", "I", "E", "C", "R"]
SERIES_COLORS = {
    "Total": "#ff4d4f",
    "S": "#40a9ff",
    "N": "#73d13d",
    "I": "#9254de",
    "E": "#faad14",
    "C": "#13c2c2",
    "R": "#eb2f96",
}
SERIES_LABELS = {
    "Total": "Total (Weighted)",
    "S": "S (Style)",
    "N": "N (Narrative)",
    "I": "I (Immersion)",
    "E": "E (Excitement)",
    "C": "C (Clarity)",
    "R": "R (Regression Risk)",
}


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
            timestamp = str(payload.get("timestamp", ""))
            if "YYYY-MM-DD" in timestamp or "<" in timestamp or ">" in timestamp:
                continue
            payloads.append(payload)
    return payloads


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
    indexed.sort(key=lambda item: (_parse_timestamp(item[1].get("timestamp")), item[0]))
    return [payload for _, payload in indexed]


def _extract_series(payloads: list[dict[str, Any]]) -> tuple[list[str], dict[str, list[float]]]:
    labels: list[str] = []
    series: dict[str, list[float]] = {name: [] for name in SERIES_ORDER}
    for index, payload in enumerate(payloads, start=1):
        timestamp = str(payload.get("timestamp", "")).strip()
        short_ts = timestamp[:10] if timestamp else "undated"
        short_ts = f"{short_ts}#{index}"
        labels.append(short_ts)

        scores = payload.get("scores", {})
        if not isinstance(scores, dict):
            scores = {}
        for name in SERIES_ORDER:
            series[name].append(round(_safe_float(scores.get(name, 0.0)), 2))
    return labels, series


def _format_values(values: list[float]) -> str:
    # Mermaid xychart-beta is more reliable with plain numerics than quoted/annotated values.
    return ", ".join(f"{value:g}" for value in values)


def _render_empty_markdown() -> str:
    now = datetime.now(timezone.utc).isoformat()
    return (
        "# AXEL QA Analytics\n\n"
        "Auto-generated from `AXEL_QA_RUN_LOG.md` by `tools/qa/update_qa_analytics.py`.\n\n"
        f"- Last generated (UTC): `{now}`\n"
        "- Runs parsed: `0`\n\n"
        "## Latest snapshot\n\n"
        "No QA runs parsed yet. Add a run entry with a `QA_ANALYTICS_JSON` payload block.\n\n"
        "## Trend chart (Total + S/N/I/E/C/R)\n\n"
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


def _build_svg_chart(labels: list[str], series: dict[str, list[float]]) -> str:
    width = 1200
    height = 700
    plot_left = 110
    plot_right = 980
    plot_top = 80
    plot_bottom = 520
    plot_width = plot_right - plot_left
    plot_height = plot_bottom - plot_top

    count = max(len(labels), 1)
    step_x = 0 if count == 1 else plot_width / (count - 1)

    def x_for(idx: int) -> float:
        return plot_left + (idx * step_x)

    def y_for(score: float) -> float:
        clamped = min(max(score, 0.0), 5.0)
        return plot_bottom - (clamped / 5.0) * plot_height

    lines: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect x="0" y="0" width="100%" height="100%" fill="#0f1116"/>',
        '<text x="110" y="42" fill="#d9d9d9" font-family="Segoe UI, Arial, sans-serif" font-size="30" font-weight="600">AXEL QA Score Trends</text>',
        f'<line x1="{plot_left}" y1="{plot_top}" x2="{plot_left}" y2="{plot_bottom}" stroke="#8c8c8c" stroke-width="2"/>',
        f'<line x1="{plot_left}" y1="{plot_bottom}" x2="{plot_right}" y2="{plot_bottom}" stroke="#8c8c8c" stroke-width="2"/>',
    ]

    for y_tick in range(0, 6):
        y = y_for(float(y_tick))
        lines.append(f'<line x1="{plot_left}" y1="{y:.2f}" x2="{plot_right}" y2="{y:.2f}" stroke="#2f3540" stroke-width="1"/>')
        lines.append(
            f'<text x="{plot_left - 18}" y="{y + 5:.2f}" text-anchor="end" fill="#bfbfbf" font-family="Segoe UI, Arial, sans-serif" font-size="16">{y_tick}</text>'
        )

    for idx, label in enumerate(labels):
        x = x_for(idx)
        lines.append(
            f'<text x="{x:.2f}" y="{plot_bottom + 28}" text-anchor="middle" fill="#bfbfbf" font-family="Segoe UI, Arial, sans-serif" font-size="14">{_svg_escape(label)}</text>'
        )

    for name in SERIES_ORDER:
        values = series.get(name, [])
        if not values:
            continue
        color = SERIES_COLORS[name]
        points = " ".join(f"{x_for(i):.2f},{y_for(v):.2f}" for i, v in enumerate(values))
        lines.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="3"/>')
        for i, value in enumerate(values):
            lines.append(f'<circle cx="{x_for(i):.2f}" cy="{y_for(value):.2f}" r="3.5" fill="{color}"/>')

    legend_x = float(plot_left)
    legend_y = 620
    swatch_width = 24
    swatch_to_text_gap = 8
    item_gap = 20
    for name in SERIES_ORDER:
        color = SERIES_COLORS[name]
        label = SERIES_LABELS[name]
        lines.append(
            f'<line x1="{legend_x:.2f}" y1="{legend_y}" x2="{legend_x + swatch_width:.2f}" y2="{legend_y}" stroke="{color}" stroke-width="4"/>'
        )
        lines.append(
            f'<text x="{legend_x + swatch_width + swatch_to_text_gap:.2f}" y="{legend_y + 5}" fill="#d9d9d9" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="600">{label}</text>'
        )
        approx_text_width = len(label) * 7.4
        legend_x += swatch_width + swatch_to_text_gap + approx_text_width + item_gap

    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def _render_markdown(payloads: list[dict[str, Any]]) -> str:
    if not payloads:
        return _render_empty_markdown()

    labels, series = _extract_series(payloads)
    now = datetime.now(timezone.utc).isoformat()
    latest = payloads[-1]
    previous = payloads[-2] if len(payloads) > 1 else None

    latest_scores = latest.get("scores", {}) if isinstance(latest.get("scores", {}), dict) else {}
    prev_scores = previous.get("scores", {}) if isinstance(previous, dict) and isinstance(previous.get("scores", {}), dict) else {}

    latest_mode = str(latest.get("mode", "unknown"))
    latest_scope = str(latest.get("scope", ""))
    latest_trigger = str(latest.get("trigger", ""))

    findings = latest.get("findings_count", {}) if isinstance(latest.get("findings_count", {}), dict) else {}
    categories = latest.get("by_category", {}) if isinstance(latest.get("by_category", {}), dict) else {}
    bugs = latest.get("bugs_or_regressions", [])
    if not isinstance(bugs, list):
        bugs = []

    delta_lines: list[str] = []
    for name in SERIES_ORDER:
        latest_val = _safe_float(latest_scores.get(name, 0.0))
        if previous is None:
            delta_lines.append(f"- `{name}`: `{latest_val:.2f}` (n/a first run)")
            continue
        prev_val = _safe_float(prev_scores.get(name, 0.0))
        diff = latest_val - prev_val
        delta_lines.append(f"- `{name}`: `{latest_val:.2f}` (`{diff:+.2f}` vs previous)")

    chart_lines = [
        "```mermaid",
        "xychart-beta",
        '  title "AXEL QA Score Trends"',
        f'  x-axis ["{"\", \"".join(labels)}"]',
        '  y-axis "Score" 0 --> 5',
    ]
    for name in SERIES_ORDER:
        chart_lines.append(f"  line [{_format_values(series[name])}]")
    chart_lines.append("```")
    legend_text = "Series order: Total, S, N, I, E, C, R."

    severity_text = (
        f"blocker={_safe_int(findings.get('blocker'))} "
        f"major={_safe_int(findings.get('major'))} "
        f"minor={_safe_int(findings.get('minor'))} "
        f"nit={_safe_int(findings.get('nit'))}"
    )

    category_keys = ["STYLE", "LORE", "IMMERSION", "TENSION", "CLARITY", "COMBAT", "ARCH", "REGRESSION", "BUG", "TOOL"]
    category_text = " ".join(f"{key}={_safe_int(categories.get(key))}" for key in category_keys)

    bugs_text = "; ".join(str(item) for item in bugs) if bugs else "none"

    return (
        "# AXEL QA Analytics\n\n"
        "Auto-generated from `AXEL_QA_RUN_LOG.md` by `tools/qa/update_qa_analytics.py`.\n\n"
        f"- Last generated (UTC): `{now}`\n"
        f"- Runs parsed: `{len(payloads)}`\n\n"
        "## Latest snapshot\n\n"
        f"- Mode: `{latest_mode}`\n"
        f"- Scope: `{latest_scope}`\n"
        f"- Trigger: `{latest_trigger}`\n"
        f"- Findings: `{severity_text}`\n"
        f"- Categories: `{category_text}`\n"
        f"- Bugs/problems: `{bugs_text}`\n\n"
        "## Latest deltas vs previous run\n\n"
        + "\n".join(delta_lines)
        + "\n\n## Trend chart (Total + S/N/I/E/C/R)\n\n"
        + "![AXEL QA Score Trends](AXEL_QA_ANALYTICS.svg)\n\n"
        + "Fallback Mermaid view:\n\n"
        + "\n".join(chart_lines)
        + "\n\n- "
        + legend_text
        + "\n"
    )


def main() -> int:
    text = RUN_LOG_PATH.read_text(encoding="utf-8") if RUN_LOG_PATH.exists() else ""
    payloads = _sort_payloads(_parse_payloads(text))
    rendered = _render_markdown(payloads)
    ANALYTICS_PATH.write_text(rendered, encoding="utf-8")
    if payloads:
        labels, series = _extract_series(payloads)
        ANALYTICS_SVG_PATH.write_text(_build_svg_chart(labels, series), encoding="utf-8")
    else:
        ANALYTICS_SVG_PATH.write_text("", encoding="utf-8")
    print(f"Updated analytics: {ANALYTICS_PATH}")
    print(f"Updated analytics chart: {ANALYTICS_SVG_PATH}")
    print(f"Payloads parsed: {len(payloads)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
