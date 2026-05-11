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

# Extra series fed by `playtest_commands.bot_*` keys instead of `scores`.
# Plotted on the same 0..5 axis (pass=5, fail=0). Missing/skip values render
# as gaps (None) so pre-bot historical runs do not look like regressions.
EXTRA_SERIES_ORDER = ["Bots"]
EXTRA_SERIES_COLORS = {
    "Bots": "#ffffff",
}
EXTRA_SERIES_LABELS = {
    "Bots": "Bots (Avg pass-rate)",
}

BOT_STATUS_TO_SCORE = {
    "pass": 5.0,
    "fail": 0.0,
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


def _bot_status_to_score(status: Any) -> float | None:
    """Map a `playtest_commands.bot_*` status string to a 0..5 score, or None for skip/missing."""
    if not isinstance(status, str):
        return None
    return BOT_STATUS_TO_SCORE.get(status.strip().lower())


def _bots_aggregate_for_payload(payload: dict[str, Any]) -> float | None:
    """Mean of all `bot_*` numeric pass/fail values in this payload, or None if none plottable.

    Auto-discovers any key in `playtest_commands` starting with `bot_`, so future
    bots (e.g. `bot_corridor_traversal`) automatically join the aggregate without
    further code changes.
    """
    commands = payload.get("playtest_commands", {})
    if not isinstance(commands, dict):
        return None
    numeric_values: list[float] = []
    for key, value in commands.items():
        if not isinstance(key, str) or not key.lower().startswith("bot_"):
            continue
        score = _bot_status_to_score(value)
        if score is not None:
            numeric_values.append(score)
    if not numeric_values:
        return None
    return round(sum(numeric_values) / len(numeric_values), 2)


def _extract_series(
    payloads: list[dict[str, Any]],
) -> tuple[list[str], dict[str, list[float]], dict[str, list[float | None]]]:
    labels: list[str] = []
    series: dict[str, list[float]] = {name: [] for name in SERIES_ORDER}
    extra_series: dict[str, list[float | None]] = {name: [] for name in EXTRA_SERIES_ORDER}
    for index, payload in enumerate(payloads, start=1):
        timestamp = _get_timestamp_value(payload)
        short_ts = timestamp[:10] if timestamp else "undated"
        short_ts = f"{short_ts}#{index}"
        labels.append(short_ts)

        scores = payload.get("scores", {})
        if not isinstance(scores, dict):
            scores = {}
        for name in SERIES_ORDER:
            series[name].append(round(_safe_float(scores.get(name, 0.0)), 2))

        extra_series["Bots"].append(_bots_aggregate_for_payload(payload))
    return labels, series, extra_series


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


def _build_svg_chart(
    labels: list[str],
    series: dict[str, list[float]],
    extra_series: dict[str, list[float | None]] | None = None,
) -> str:
    extra_series = extra_series or {}
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

    # Extra series (e.g. "Bots") may contain None for skip/missing/pre-bot runs;
    # render as broken polyline (one segment per consecutive non-None span) so
    # historical gaps don't look like flat-zero regressions.
    for name in EXTRA_SERIES_ORDER:
        values = extra_series.get(name, [])
        if not values or all(v is None for v in values):
            continue
        color = EXTRA_SERIES_COLORS[name]
        segment: list[tuple[float, float]] = []
        for i, value in enumerate(values):
            if value is None:
                if len(segment) >= 2:
                    points = " ".join(f"{x:.2f},{y:.2f}" for x, y in segment)
                    lines.append(
                        f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="3" stroke-dasharray="6,4"/>'
                    )
                segment = []
                continue
            segment.append((x_for(i), y_for(value)))
        if len(segment) >= 2:
            points = " ".join(f"{x:.2f},{y:.2f}" for x, y in segment)
            lines.append(
                f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="3" stroke-dasharray="6,4"/>'
            )
        for i, value in enumerate(values):
            if value is None:
                continue
            lines.append(
                f'<circle cx="{x_for(i):.2f}" cy="{y_for(value):.2f}" r="4.5" fill="{color}" stroke="#0f1116" stroke-width="1.5"/>'
            )

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

    legend_x = float(plot_left)
    legend_y += 30
    for name in EXTRA_SERIES_ORDER:
        values = extra_series.get(name, [])
        if not values or all(v is None for v in values):
            continue
        color = EXTRA_SERIES_COLORS[name]
        label = EXTRA_SERIES_LABELS[name]
        lines.append(
            f'<line x1="{legend_x:.2f}" y1="{legend_y}" x2="{legend_x + swatch_width:.2f}" y2="{legend_y}" stroke="{color}" stroke-width="4" stroke-dasharray="6,4"/>'
        )
        lines.append(
            f'<text x="{legend_x + swatch_width + swatch_to_text_gap:.2f}" y="{legend_y + 5}" fill="#d9d9d9" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="600">{label}</text>'
        )
        approx_text_width = len(label) * 7.4
        legend_x += swatch_width + swatch_to_text_gap + approx_text_width + item_gap

    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def _format_bot_commands(payload: dict[str, Any]) -> str:
    commands = payload.get("playtest_commands", {})
    if not isinstance(commands, dict):
        return "no playtest_commands"
    bot_pairs = [
        f"{key}={value}"
        for key, value in commands.items()
        if isinstance(key, str) and key.lower().startswith("bot_")
    ]
    return " ".join(bot_pairs) if bot_pairs else "no bot keys"


def _render_item_balance_section(payloads: list[dict[str, Any]]) -> str:
    """Compact per-item trend summary across runs that contain item_balance data."""
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
        lines.append("| Item | Label | \u0394RTP | CI95 | \u0394Hit Rate | \u0394Enc. Success |")
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

    # Historical item classification trend (top risers/fallers)
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


def _render_markdown(payloads: list[dict[str, Any]]) -> str:
    if not payloads:
        return _render_empty_markdown()

    labels, series, extra_series = _extract_series(payloads)
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

    bots_status_text = _format_bot_commands(latest)

    delta_lines: list[str] = []
    for name in SERIES_ORDER:
        latest_val = _safe_float(latest_scores.get(name, 0.0))
        if previous is None:
            delta_lines.append(f"- `{name}`: `{latest_val:.2f}` (n/a first run)")
            continue
        prev_val = _safe_float(prev_scores.get(name, 0.0))
        diff = latest_val - prev_val
        delta_lines.append(f"- `{name}`: `{latest_val:.2f}` (`{diff:+.2f}` vs previous)")

    for name in EXTRA_SERIES_ORDER:
        values = extra_series.get(name, [])
        latest_val = values[-1] if values else None
        prev_val = values[-2] if len(values) >= 2 else None
        if latest_val is None:
            delta_lines.append(f"- `{name}`: `n/a` (no bot data this run)")
            continue
        if prev_val is None:
            delta_lines.append(f"- `{name}`: `{latest_val:.2f}` (n/a previous bot data)")
            continue
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
    legend_text = (
        "Series order: Total, S, N, I, E, C, R. The dashed `Bots` aggregate "
        "(pass=5, fail=0; gaps for skip/missing) appears in the SVG only — "
        "Mermaid `xychart-beta` cannot render gaps cleanly so it is omitted "
        "from the fallback view."
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

    # Item balance audit status from playtest_commands
    item_audit_status = ""
    pt_cmds = latest.get("playtest_commands", {})
    if isinstance(pt_cmds, dict) and "item_balance_audit" in pt_cmds:
        item_audit_status = f"- Item balance audit: `{pt_cmds['item_balance_audit']}`\n"

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
        f"- Bugs/problems: `{bugs_text}`\n"
        f"- Bots: `{bots_status_text}`\n"
        + item_audit_status
        + "\n"
        "## Latest deltas vs previous run\n\n"
        + "\n".join(delta_lines)
        + "\n\n## Trend chart (Total + S/N/I/E/C/R + Bots)\n\n"
        + "![AXEL QA Score Trends](AXEL_QA_ANALYTICS.svg)\n\n"
        + "Fallback Mermaid view:\n\n"
        + "\n".join(chart_lines)
        + "\n\n- "
        + legend_text
        + "\n"
        + ("\n" + item_section if item_section else "")
    )


def _collect_all_payloads() -> list[dict[str, Any]]:
    """Parse payloads from the main run log and any archived logs under archive/."""
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
        labels, series, extra_series = _extract_series(payloads)
        ANALYTICS_SVG_PATH.write_text(
            _build_svg_chart(labels, series, extra_series), encoding="utf-8"
        )
    else:
        ANALYTICS_SVG_PATH.write_text("", encoding="utf-8")
    print(f"Updated analytics: {ANALYTICS_PATH}")
    print(f"Updated analytics chart: {ANALYTICS_SVG_PATH}")
    print(f"Payloads parsed: {len(payloads)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
