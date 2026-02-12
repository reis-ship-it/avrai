#!/usr/bin/env python3
"""
Retier SPOTS patents based on in-spec patentability metrics.

This script:
- Reads each main patent spec in docs/patents/
- Extracts numeric patentability scores when present:
  Novelty, Non-Obviousness, Technical Specificity, Problem-Solution Clarity, Prior Art Risk
- Computes a viability score:
    viability = novelty + nonobvious + technical + problem_solution + (10 - prior_art_risk)
  (range: 0..50, higher is better)
- Proposes tiers by thresholds (tuned to current portfolio distribution):
    Tier 1: viability >= 27
    Tier 2: 25 <= viability < 27
    Tier 3: 22 <= viability < 25
    Tier 4: viability < 22
- De-dupes the legacy top-level MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md if the
  category version exists.

Outputs:
  docs/patents/filing_preparation/retiering/YYYY-MM-DD/RETIERING_REPORT.md
  docs/patents/filing_preparation/retiering/YYYY-MM-DD/TOP_10.md
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PATENTS_ROOT = PROJECT_ROOT / "docs" / "patents"
PORTFOLIO_INDEX = PATENTS_ROOT / "PATENT_PORTFOLIO_INDEX.md"

STAMP = datetime.now().astimezone().date().isoformat()
OUT_DIR = PATENTS_ROOT / "filing_preparation" / "retiering" / STAMP


SKIP_NAMES = {
    "DOCUMENTATION_STATUS.md",
    "PATENT_SECTIONS_COMPLETE.md",
    "PATENT_UPDATE_SUMMARY.md",
    "PRIOR_ART_ADDITION_SUMMARY.md",
    "REFERENCES_UPDATE_SUMMARY.md",
    "PHASE_0_PROGRESS_SUMMARY.md",
    "PATENT_30_VALIDATION_PLAN.md",
    "PATENT_30_COMPLETION_CHECKLIST.md",
    "MARKETING_VALIDATION_RESULTS.md",
    "EXPERIMENT_RESULTS.md",
    "TIMEZONE_AWARE_ENHANCEMENT.md",
    "CRITICAL_PATENTABILITY_ANALYSIS.md",
}


def safe_read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")


def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")


def rel(p: Path) -> str:
    return str(p.relative_to(PROJECT_ROOT))


def is_main_patent_doc(p: Path) -> bool:
    if p.name.endswith("_visuals.md"):
        return False
    if p.name in SKIP_NAMES:
        return False
    head = safe_read(p)[:4000]
    return ("**Patent Innovation #" in head) or ("## Patent Overview" in head) or (
        p.name == "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md"
    )


def extract_title(text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+?)\s*$", text, flags=re.M)
    return m.group(1).strip() if m else fallback


def extract_innovation_number(text: str) -> str | None:
    m = re.search(r"^\*\*Patent Innovation #(\d+)\*\*", text, flags=re.M)
    return m.group(1) if m else None


def get_score(text: str, label: str) -> float | None:
    m = re.search(
        rf"{re.escape(label)}\s*Score:\s*(\d+(?:\.\d+)?)\s*/\s*10",
        text,
        flags=re.I,
    )
    return float(m.group(1)) if m else None


def tier_from_viability(v: float) -> int:
    if v >= 27:
        return 1
    if v >= 25:
        return 2
    if v >= 22:
        return 3
    return 4


@dataclass(frozen=True)
class RetierRow:
    viability: float
    new_tier: int
    path: Path
    title: str
    innovation: str | None
    novelty: float
    nonobvious: float
    technical: float
    problem_solution: float
    prior_art_risk: float


def parse_current_tiers_from_index(index_text: str) -> dict[str, int]:
    """
    Heuristic: map \"Title\" -> tier integer, based on patterns like:
      **Title** (Tier 2)
    """
    tiers: dict[str, int] = {}
    for m in re.finditer(r"\*\*(.+?)\*\*\s*\(Tier\s*(\d)\)", index_text):
        tiers[m.group(1).strip()] = int(m.group(2))
    return tiers


def maybe_current_tier(title: str, title_to_tier: dict[str, int]) -> int | None:
    # Exact title match first
    if title in title_to_tier:
        return title_to_tier[title]
    # Fallback: case-insensitive match
    low = title.lower()
    for k, v in title_to_tier.items():
        if k.lower() == low:
            return v
    return None


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Load current tiering from portfolio index (best-effort).
    title_to_tier: dict[str, int] = {}
    if PORTFOLIO_INDEX.exists():
        title_to_tier = parse_current_tiers_from_index(safe_read(PORTFOLIO_INDEX))

    docs = sorted([p for p in PATENTS_ROOT.glob("category_*/*/*.md") if is_main_patent_doc(p)])
    # Include the legacy top-level multi-entity doc, but we will de-dupe it.
    legacy_multi = PATENTS_ROOT / "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md"
    if legacy_multi.exists() and is_main_patent_doc(legacy_multi):
        docs.append(legacy_multi)

    rows: list[RetierRow] = []
    for p in docs:
        txt = safe_read(p)
        title = extract_title(txt, fallback=p.stem.replace("_", " "))
        innovation = extract_innovation_number(txt)

        novelty = get_score(txt, "Novelty") or 0.0
        nonobvious = get_score(txt, "Non-Obviousness") or 0.0
        technical = get_score(txt, "Technical Specificity") or 0.0
        problem_solution = get_score(txt, "Problem-Solution Clarity") or 0.0
        prior_art = get_score(txt, "Prior Art Risk") or 0.0

        viability = novelty + nonobvious + technical + problem_solution + (10.0 - prior_art)
        new_tier = tier_from_viability(viability)

        rows.append(
            RetierRow(
                viability=viability,
                new_tier=new_tier,
                path=p,
                title=title,
                innovation=innovation,
                novelty=novelty,
                nonobvious=nonobvious,
                technical=technical,
                problem_solution=problem_solution,
                prior_art_risk=prior_art,
            )
        )

    # De-dupe: drop legacy multi-entity doc if category version exists.
    category_multi = PATENTS_ROOT / "category_1_quantum_ai_systems" / "08_multi_entity_quantum_entanglement_matching" / "08_multi_entity_quantum_entanglement_matching.md"
    if category_multi.exists():
        rows = [r for r in rows if r.path != legacy_multi]

    rows_sorted = sorted(rows, key=lambda r: (-r.viability, rel(r.path)))
    top10 = rows_sorted[:10]

    # Render report
    lines: list[str] = []
    lines.append("# Patent Retiering Report")
    lines.append("")
    lines.append(f"**Generated:** {STAMP}")
    lines.append("")
    lines.append("## Method")
    lines.append("- **Source**: In-spec `Patentability Assessment` numeric scores where present.")
    lines.append("- **Viability score**:")
    lines.append("  - `viability = Novelty + Non-Obviousness + Technical Specificity + Problem-Solution Clarity + (10 - Prior Art Risk)`")
    lines.append("- **Tier thresholds (tuned to current score distribution)**:")
    lines.append("  - Tier 1: viability ≥ 27")
    lines.append("  - Tier 2: 25 ≤ viability < 27")
    lines.append("  - Tier 3: 22 ≤ viability < 25")
    lines.append("  - Tier 4: viability < 22")
    lines.append("")
    lines.append("> This is a prioritization heuristic for filing viability and is not legal advice.")
    lines.append("")

    lines.append("## Updated Top 10 (recommended priority)")
    for i, r in enumerate(top10, start=1):
        label = f"Patent Innovation #{r.innovation}" if r.innovation else "Patent"
        lines.append(f"{i}. **{r.title}** — {label} — **Tier {r.new_tier}** — viability **{r.viability:.1f}**")
        lines.append(f"   - Spec: `{rel(r.path)}`")
    lines.append("")

    lines.append("## Full retiering table")
    lines.append("")
    lines.append("| Rank | New Tier | Viability | Current Tier* | Patent | Spec |")
    lines.append("|---:|:---:|---:|:---:|---|---|")
    for i, r in enumerate(rows_sorted, start=1):
        cur = maybe_current_tier(r.title, title_to_tier)
        cur_s = str(cur) if cur is not None else "?"
        lines.append(
            f"| {i} | {r.new_tier} | {r.viability:.1f} | {cur_s} | {r.title} | `{rel(r.path)}` |"
        )

    lines.append("")
    lines.append(
        "\\*Current Tier is best-effort from `docs/patents/PATENT_PORTFOLIO_INDEX.md` title matching."
    )
    lines.append("")

    write_text(OUT_DIR / "RETIERING_REPORT.md", "\n".join(lines))

    # TOP_10 as separate file for easy handoff
    top_lines = [
        "# Updated Top 10 Patents (Retiered)",
        "",
        f"**Generated:** {STAMP}",
        "",
    ]
    for i, r in enumerate(top10, start=1):
        top_lines.append(
            f"{i}. **{r.title}** — **Tier {r.new_tier}** — viability **{r.viability:.1f}**"
        )
        top_lines.append(f"   - Spec: `{rel(r.path)}`")
    top_lines.append("")
    write_text(OUT_DIR / "TOP_10.md", "\n".join(top_lines))

    print(f"Wrote: {rel(OUT_DIR / 'RETIERING_REPORT.md')}")
    print(f"Wrote: {rel(OUT_DIR / 'TOP_10.md')}")


if __name__ == "__main__":
    main()
