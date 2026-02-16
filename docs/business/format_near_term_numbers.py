#!/usr/bin/env python3
"""Apply uniform formatting and add total rows to AVRAI_BUDGET_NEAR-TERM.numbers.

Run after update_near_term_numbers.py. Uses docs/business/AVRAI_BUDGET_NEAR-TERM.numbers.
"""

from pathlib import Path
from numbers_parser import Document
from numbers_parser.cell import RGB, Alignment, Style

BUDGET_PATH = Path(__file__).parent / "AVRAI_BUDGET_NEAR-TERM.numbers"

# Reusable styles (match AVRAI_BUDGET.xlsx: dark header, light section, total row)
def _add_styles(doc):
    return {
        "header": doc.add_style(
            name="NearTerm Header",
            bg_color=RGB(26, 26, 46),
            font_color=RGB(255, 255, 255),
            bold=True,
            font_size=11.0,
            font_name="Helvetica Neue",
            alignment=Alignment("center", "middle"),
            text_wrap=True,
        ),
        "section": doc.add_style(
            name="NearTerm Section",
            bg_color=RGB(232, 234, 246),
            font_color=RGB(26, 26, 46),
            bold=True,
            font_size=12.0,
            font_name="Helvetica Neue",
            text_wrap=True,
        ),
        "total": doc.add_style(
            name="NearTerm Total",
            bg_color=RGB(197, 202, 233),
            font_color=RGB(26, 26, 46),
            bold=True,
            font_size=11.0,
            font_name="Helvetica Neue",
            text_wrap=True,
        ),
        "title": doc.add_style(
            name="NearTerm Title",
            font_color=RGB(26, 26, 46),
            bold=True,
            font_size=16.0,
            font_name="Helvetica Neue",
        ),
        "subtitle": doc.add_style(
            name="NearTerm Subtitle",
            font_color=RGB(102, 102, 102),
            font_size=11.0,
            font_name="Helvetica Neue",
        ),
    }


def _apply_style_to_row(table, row_index, style, num_cols):
    for c in range(num_cols):
        table.set_cell_style(row_index, c, style)


def _cell_text(table, row, col):
    val = table.cell(row, col).value
    return (val or "").strip() if isinstance(val, str) else ""


def apply_formatting(doc, styles):
    """Apply header/section/total styles by row content."""
    for sheet in doc.sheets:
        table = sheet.tables[0]
        nrows, ncols = table.num_rows, table.num_cols
        for r in range(nrows):
            text = _cell_text(table, r, 0)
            text_lower = text.lower()
            # Title row (AVRAI — ...)
            if "AVRAI —" in text and r <= 1:
                _apply_style_to_row(table, r, styles["title"], ncols)
            # Subtitle (February 2026...)
            elif "2026" in text and r <= 2 and len(text) > 20:
                _apply_style_to_row(table, r, styles["subtitle"], ncols)
            # Column headers
            elif any(x in text_lower for x in ("item", "category", "role", "phase")) and "total" not in text_lower and r < 20:
                _apply_style_to_row(table, r, styles["header"], ncols)
            # Section headers (ONE-TIME —, RECURRING —, PRE-SEED, SEED)
            elif "—" in text or ("pre-seed" in text_lower and "personnel" in text_lower) or ("seed" in text_lower and "personnel" in text_lower and "total" not in text_lower):
                _apply_style_to_row(table, r, styles["section"], ncols)
            # Total rows
            elif "total" in text_lower or "subtotal" in text_lower or "contingency" in text_lower:
                _apply_style_to_row(table, r, styles["total"], ncols)


def add_all_costs_total(doc, styles):
    """Add TOTAL ONE-TIME row at bottom of All Costs sheet."""
    table = doc.sheets[1].tables[0]
    # One-time subtotal rows: Legal 13, IP 24, Design 30, Security 36, Hardware 49, Beta 56
    subtotal_rows = [13, 24, 30, 36, 49, 56]
    base = sum(_num(table.cell(r, 1).value) for r in subtotal_rows)
    low = sum(_num(table.cell(r, 2).value) for r in subtotal_rows)
    high = sum(_num(table.cell(r, 3).value) for r in subtotal_rows)
    table.add_row()
    last = table.num_rows - 1
    table.write(last, 0, "TOTAL ONE-TIME (Legal + IP + Design + Security + Hardware + Beta)")
    table.write(last, 1, round(base, 0))
    table.write(last, 2, round(low, 0))
    table.write(last, 3, round(high, 0))
    table.write(last, 4, "")
    table.write(last, 5, "Sum of section subtotals above.")
    for c in range(6):
        table.set_cell_style(last, c, styles["total"])


def _num(v):
    if v is None:
        return 0
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0


def main():
    if not BUDGET_PATH.exists():
        print(f"ERROR: Not found: {BUDGET_PATH}")
        return 1
    doc = Document(str(BUDGET_PATH))
    styles = _add_styles(doc)
    apply_formatting(doc, styles)
    add_all_costs_total(doc, styles)
    doc.save(str(BUDGET_PATH))
    print(f"Formatted and added totals: {BUDGET_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
