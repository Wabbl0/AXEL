"""One-off helper: convert the artist background-list markdown into a PDF.

Renders directly with reportlab (not xhtml2pdf) so table column widths are
explicit and fixed instead of auto-calculated - xhtml2pdf's auto-fit
algorithm intermittently corrupts column widths for some tables (words
end up one-per-line instead of wrapping normally), which is the bug this
script works around.

Usage: python md_to_pdf.py <input.md> <output.pdf>
"""
import re
import sys

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    HRFlowable,
)

RED = colors.HexColor("#b30000")
DARK = colors.HexColor("#1a1a1a")
HEADER_BG = colors.HexColor("#2a2a2a")
ROW_ALT = colors.HexColor("#f4f4f4")
BORDER = colors.HexColor("#999999")

# Emoji glyphs aren't in the base PDF fonts (they'd render as empty boxes).
# The status emoji are always followed by a plain word ("Drawn" / "Needed"),
# so we just drop the emoji itself; the star marking memory scenes becomes "*".
EMOJI_SUBS = {
    "✅ ": "",
    "❌ ": "",
    "⭐": "*",
}

TITLE_STYLE = ParagraphStyle("Title", fontName="Helvetica-Bold", fontSize=18, textColor=RED, spaceAfter=10)
H2_STYLE = ParagraphStyle("H2", fontName="Helvetica-Bold", fontSize=13, textColor=RED, spaceBefore=16, spaceAfter=6)
BODY_STYLE = ParagraphStyle("Body", fontName="Helvetica", fontSize=10, textColor=DARK, leading=14, spaceAfter=6)
CELL_STYLE = ParagraphStyle("Cell", fontName="Helvetica", fontSize=9, textColor=DARK, leading=12)
CELL_HEAD_STYLE = ParagraphStyle("CellHead", fontName="Helvetica-Bold", fontSize=9, textColor=colors.white, leading=12)
LIST_STYLE = ParagraphStyle("List", fontName="Helvetica", fontSize=10, textColor=DARK, leading=14, spaceAfter=3, leftIndent=12)

COL_WIDTH_FRACTIONS = {
    3: [0.16, 0.50, 0.34],
    4: [0.15, 0.19, 0.12, 0.54],
}


def clean_inline(text):
    text = text.strip()
    for emoji, sub in EMOJI_SUBS.items():
        text = text.replace(emoji, sub)
    text = text.replace("&", "&amp;")
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`(.+?)`", r"<font face='Helvetica-Bold'>\1</font>", text)
    return text


def parse_table_row(line):
    inner = line.strip().strip("|")
    return [cell.strip() for cell in inner.split("|")]


def is_separator_row(cells):
    return all(re.fullmatch(r":?-+:?", c) for c in cells if c != "")


def build_table(rows, usable_width):
    col_count = len(rows[0])
    fractions = COL_WIDTH_FRACTIONS.get(col_count)
    if not fractions:
        fractions = [1.0 / col_count] * col_count
    col_widths = [usable_width * f for f in fractions]

    table_data = []
    for r_idx, row in enumerate(rows):
        style = CELL_HEAD_STYLE if r_idx == 0 else CELL_STYLE
        table_data.append([Paragraph(clean_inline(cell), style) for cell in row])

    t = Table(table_data, colWidths=col_widths, repeatRows=1)
    style_cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
        ("GRID", (0, 0), (-1, -1), 0.6, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for r_idx in range(1, len(table_data)):
        if r_idx % 2 == 0:
            style_cmds.append(("BACKGROUND", (0, r_idx), (-1, r_idx), ROW_ALT))
    t.setStyle(TableStyle(style_cmds))
    return t


def parse_markdown(md_text, usable_width):
    lines = md_text.split("\n")
    flowables = []
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        if stripped == "---":
            flowables.append(Spacer(1, 6))
            flowables.append(HRFlowable(width="100%", color=BORDER, thickness=0.6))
            flowables.append(Spacer(1, 6))
            i += 1
            continue

        if stripped.startswith("# "):
            flowables.append(Paragraph(clean_inline(stripped[2:]), TITLE_STYLE))
            i += 1
            continue

        if stripped.startswith("## "):
            flowables.append(Paragraph(clean_inline(stripped[3:]), H2_STYLE))
            i += 1
            continue

        if stripped.startswith("|"):
            table_lines = []
            while i < n and lines[i].strip().startswith("|"):
                table_lines.append(lines[i].strip())
                i += 1
            rows = [parse_table_row(l) for l in table_lines]
            if len(rows) > 1 and is_separator_row(rows[1]):
                rows.pop(1)
            flowables.append(build_table(rows, usable_width))
            flowables.append(Spacer(1, 10))
            continue

        if re.match(r"^\d+\.\s", stripped):
            flowables.append(Paragraph(clean_inline(stripped), LIST_STYLE))
            i += 1
            continue

        flowables.append(Paragraph(clean_inline(stripped), BODY_STYLE))
        i += 1

    return flowables


def main():
    if len(sys.argv) != 3:
        print("Usage: python md_to_pdf.py <input.md> <output.pdf>")
        sys.exit(1)

    src_path, out_path = sys.argv[1], sys.argv[2]
    md_text = open(src_path, "r", encoding="utf-8").read()

    doc = SimpleDocTemplate(
        out_path,
        pagesize=A4,
        leftMargin=1.6 * cm,
        rightMargin=1.6 * cm,
        topMargin=1.6 * cm,
        bottomMargin=1.6 * cm,
        title="AXEL Background Art List",
    )
    usable_width = A4[0] - doc.leftMargin - doc.rightMargin

    flowables = parse_markdown(md_text, usable_width)
    doc.build(flowables)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
