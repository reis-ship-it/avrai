#!/usr/bin/env python3
"""
Generate broad/medium/narrow claim-set variants per patent.

Design goals:
- Do NOT modify existing patent specs.
- Produce counsel-friendly drafts that keep numbering stable relative to the current spec.
- Vary ONLY Claim 1 (independent) for broad/narrow; keep Claims 2..N as-is to avoid
  dependency rewrite risk in bulk generation.
- Include optional companion statutory-class independents (system / CRM) as an appendix,
  without renumbering the main claim set.

Output folder:
  docs/patents/filing_preparation/claims_drafts/YYYY-MM-DD/...
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PATENTS_ROOT = PROJECT_ROOT / "docs" / "patents"
OUTPUT_ROOT = (
    PATENTS_ROOT
    / "filing_preparation"
    / "claims_drafts"
    / date.today().isoformat()
)


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


SECTION_RE = re.compile(
    r"^##\s+(?P<name>.+?)\s*$\n(?P<body>.*?)(?=^##\s+\S|\Z)",
    flags=re.M | re.S,
)

CLAIM_NUM_LINE_RE = re.compile(r"^(?P<num>\d+)\.\s+(?P<body>.*)$", flags=re.M)
FIG_HEADING_RE = re.compile(r"^###\s+FIG\.\s*\d+\s+[—-]\s+.+$", flags=re.M)
SUBPART_LINE_RE = re.compile(r"^\s*\(([a-z])\)\s+(.+?)\s*$", flags=re.M)
HR_LINE_RE = re.compile(r"^\s*---\s*$", flags=re.M)


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
    return (
        ("**Patent Innovation #" in head)
        or ("## Patent Overview" in head)
        or (p.name == "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md")
    )


def parse_sections(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in SECTION_RE.finditer(text):
        out[m.group("name").strip()] = m.group("body").strip()
    return out


def extract_title(text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+?)\s*$", text, flags=re.M)
    return m.group(1).strip() if m else fallback


@dataclass(frozen=True)
class Claim:
    num: int
    text: str


def parse_claims(claims_body: str) -> list[Claim]:
    matches = list(CLAIM_NUM_LINE_RE.finditer(claims_body))
    if not matches:
        return []
    out: list[Claim] = []
    for i, m in enumerate(matches):
        n = int(m.group("num"))
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(claims_body)
        chunk = claims_body[start:end].strip()
        chunk = re.sub(rf"^{re.escape(str(n))}\.\s*", "", chunk, count=1)
        out.append(Claim(num=n, text=chunk.strip()))
    return out


def strip_non_claim_trailing_content(s: str) -> str:
    """
    Claims sections in these specs sometimes include a trailing '---' and additional
    headings (e.g., Atomic Timing Integration) after the last claim. Remove anything
    starting at the first horizontal rule or markdown heading that follows the claim
    text.
    """
    # Stop at the first standalone horizontal rule line.
    m = HR_LINE_RE.search(s)
    if m:
        return s[: m.start()].rstrip()
    # Stop at a markdown heading (defensive).
    m2 = re.search(r"^\s*#{2,}\s+\S", s, flags=re.M)
    if m2:
        return s[: m2.start()].rstrip()
    return s.strip()


def clean_claim_text(s: str) -> str:
    s = strip_non_claim_trailing_content(s)
    # Remove accidental headings inside claim text (defensive).
    s = re.sub(r"^\s*#{2,}\s+.+$", "", s, flags=re.M)
    # Collapse trailing whitespace but preserve intentional newlines.
    s = "\n".join(line.rstrip() for line in s.splitlines()).strip()
    return s


def format_subparts_if_present(s: str) -> str:
    """
    If claim contains (a)(b)(c) subparts, normalize formatting:
    - keep preamble as-is up to first subpart
    - ensure each subpart ends with ';' except last ends with '.'
    """
    matches = list(SUBPART_LINE_RE.finditer(s))
    if not matches:
        return s.strip()

    preamble = s[: matches[0].start()].rstrip()
    subparts = []
    for m in matches:
        letter = m.group(1)
        body = m.group(2).strip().rstrip(";").rstrip(".")
        subparts.append((letter, body))

    out_lines = [preamble.rstrip()]
    for i, (letter, body) in enumerate(subparts):
        end = "." if i == len(subparts) - 1 else ";"
        out_lines.append(f"({letter}) {body}{end}")

    return "\n".join(out_lines).strip()


def claim1_statutory_class(claim1: str) -> str:
    lead = claim1.strip().splitlines()[0][:250]
    if re.search(r"\bmethod\b", lead, flags=re.I):
        return "method"
    if re.search(r"\bsystem\b", lead, flags=re.I):
        return "system"
    if re.search(r"\bdevice\b", lead, flags=re.I):
        return "device"
    if re.search(r"\bnon[-\s]?transitory\b", lead, flags=re.I):
        return "crm"
    # Default to method for drafts (most robust mapping)
    return "method"


def strip_numeric_constraints(s: str) -> str:
    # Replace explicit numeric thresholds with generic words.
    s = re.sub(r"\b\d+(\.\d+)?\s*%\b", "a threshold percentage", s)
    s = re.sub(r"\b0\.\d+\b", "a threshold value", s)
    s = re.sub(r"\b\d+\s*(ms|s|sec|seconds|minutes|min|hours|days|m|km)\b", "a threshold interval", s, flags=re.I)
    # Replace hard-coded ranges like [0, 1]
    s = re.sub(r"\[\s*0\s*,\s*1\s*\]", "a bounded range", s)
    return s


def compress_claim_to_high_level(claim1: str) -> str:
    """
    Create a broad-ish claim 1 by removing excessive detail while keeping the core steps.
    Works on the existing claim 1 text to preserve invention-specific nouns.
    """
    txt = clean_claim_text(claim1)
    txt = strip_numeric_constraints(txt)
    # Drop overly long parentheticals (keep short ones)
    txt = re.sub(r"\([^)]{40,}\)", "", txt)
    # If claim has subparts, keep only the first 3-5 subparts (broad posture).
    matches = list(SUBPART_LINE_RE.finditer(txt))
    if matches:
        preamble = txt[: matches[0].start()].rstrip()
        subparts = []
        for m in matches[:5]:
            subparts.append((m.group(1), m.group(2).strip()))
        # Re-letter sequentially (a,b,c,...) to avoid gaps if we truncate.
        out_lines = [preamble.rstrip()]
        for i, (_, body) in enumerate(subparts):
            letter = chr(ord("a") + i)
            body = body.rstrip(";").rstrip(".")
            end = "." if i == len(subparts) - 1 else ";"
            out_lines.append(f"({letter}) {body}{end}")
        return "\n".join(out_lines).strip()

    # Otherwise: keep the first 2-3 semicolon-separated clauses.
    clauses = [c.strip() for c in re.split(r";\s*", txt) if c.strip()]
    if len(clauses) >= 3:
        return "; ".join(clauses[:3]).rstrip(";").rstrip(".") + "."
    return txt.rstrip(".") + "."


def narrow_claim_by_inlining_dependents(claim1: str, dependents: list[Claim], max_inline: int = 3) -> str:
    """
    Create a narrow claim 1 by inlining 2-3 dependent limitations as additional constraints.
    This is intentionally conservative: it reuses existing dependent language.
    """
    base = clean_claim_text(claim1).rstrip(";").rstrip(".")
    additions: list[str] = []

    for c in dependents[: max_inline * 2]:
        lead = clean_claim_text(c.text).strip().splitlines()[0]
        # Take the portion after the first comma as the limiting clause.
        if "," in lead:
            clause = lead.split(",", 1)[1].strip()
        else:
            # If no comma, use whole line.
            clause = lead.strip()
        clause = clause.rstrip(";").rstrip(".")
        # Avoid re-adding \"The method of claim 1\" lead-ins.
        clause = re.sub(r"^(the\s+)?(method|system|device)\s+of\s+claim\s+\d+\b", "", clause, flags=re.I).strip(" ,")
        if not clause:
            continue
        # Avoid very generic fluff
        if clause.lower() in {"wherein"}:
            continue
        additions.append(clause)
        if len(additions) >= max_inline:
            break

    if not additions:
        return format_subparts_if_present(clean_claim_text(claim1)).rstrip(".") + "."

    # Add as appended \"wherein\" constraints. Keep it readable.
    out = base + ", wherein " + "; and wherein ".join(additions) + "."
    return out


def companion_independent_claims(stat_class: str) -> str:
    """
    Provide optional companion independents that tie back to claim 1,
    without renumbering the main set.
    """
    if stat_class == "method":
        return (
            "### Optional companion independent claims (for counsel)\n\n"
            "- **System claim (optional):** A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.\n"
            "- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.\n"
        )
    if stat_class == "system":
        return (
            "### Optional companion independent claims (for counsel)\n\n"
            "- **Method claim (optional):** A computer-implemented method performed by one or more processors of the system of claim 1.\n"
            "- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed, cause one or more processors to implement operations of the system of claim 1.\n"
        )
    return (
        "### Optional companion independent claims (for counsel)\n\n"
        "- **System claim (optional):** A system comprising one or more processors and memory storing instructions to implement operations of claim 1.\n"
        "- **Method claim (optional):** A computer-implemented method performed by one or more processors to implement operations of claim 1.\n"
    )


def render_claim_set(
    *,
    variant_name: str,
    title: str,
    spec_path: Path,
    claims: list[Claim],
    claim1_override: str | None,
) -> str:
    lines: list[str] = []
    lines.append(f"# {title} — Claims Draft ({variant_name})")
    lines.append("")
    lines.append(f"**Source spec:** `{rel(spec_path)}`")
    lines.append(f"**Generated:** {date.today().isoformat()}")
    lines.append("")
    lines.append("> **NOTE:** Draft for counsel review. This file does not change the underlying spec; it proposes an alternative Claim 1 scope posture.")
    lines.append("")
    lines.append("## Claims")
    lines.append("")

    for c in claims:
        txt = clean_claim_text(c.text)
        if c.num == 1 and claim1_override is not None:
            txt = clean_claim_text(claim1_override.strip())
        txt = format_subparts_if_present(txt)
        # Ensure each claim ends with a period for cleanliness (non-limiting; counsel can revise).
        txt = txt.strip()
        if not txt.endswith("."):
            txt += "."
        lines.append(f"{c.num}. {txt}")
        lines.append("")

    stat = claim1_statutory_class((claim1_override or claims[0].text) if claims else "")
    lines.append("## Appendix")
    lines.append("")
    lines.append(companion_independent_claims(stat))
    lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    main_docs = sorted(
        [p for p in PATENTS_ROOT.glob("category_*/*/*.md") if is_main_patent_doc(p)],
        key=lambda x: str(x),
    )
    extra = PATENTS_ROOT / "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md"
    if extra.exists() and is_main_patent_doc(extra):
        main_docs.append(extra)

    written = 0
    for main_doc in main_docs:
        text = safe_read(main_doc)
        sections = parse_sections(text)
        claims_body = sections.get("Claims")
        if not claims_body:
            continue
        claims = [Claim(num=c.num, text=clean_claim_text(c.text)) for c in parse_claims(claims_body)]
        if not claims:
            continue

        title = extract_title(text, fallback=main_doc.stem.replace("_", " "))
        dependents = [c for c in claims if c.num != 1]

        # medium = as-is
        medium_claim1 = None

        # broad = compressed + numeric stripping
        broad_claim1 = compress_claim_to_high_level(claims[0].text)

        # narrow = inline a few dependent limitations into claim 1
        narrow_claim1 = narrow_claim_by_inlining_dependents(claims[0].text, dependents, max_inline=3)

        # Write files, keeping category folder structure for readability.
        base_name = main_doc.stem
        rel_dir = main_doc.parent.relative_to(PATENTS_ROOT) if "category_" in str(main_doc.parent) else Path(base_name)
        out_dir = OUTPUT_ROOT / rel_dir
        broad_path = out_dir / f"{base_name}_claims_broad.md"
        medium_path = out_dir / f"{base_name}_claims_medium.md"
        narrow_path = out_dir / f"{base_name}_claims_narrow.md"

        write_text(
            broad_path,
            render_claim_set(
                variant_name="BROAD",
                title=title,
                spec_path=main_doc,
                claims=claims,
                claim1_override=broad_claim1,
            ),
        )
        written += 1

        write_text(
            medium_path,
            render_claim_set(
                variant_name="MEDIUM (current spec claims)",
                title=title,
                spec_path=main_doc,
                claims=claims,
                claim1_override=medium_claim1,
            ),
        )
        written += 1

        write_text(
            narrow_path,
            render_claim_set(
                variant_name="NARROW",
                title=title,
                spec_path=main_doc,
                claims=claims,
                claim1_override=narrow_claim1,
            ),
        )
        written += 1

    # Index
    index_lines = [
        "# Claims Drafts — Scope Variants",
        "",
        f"**Generated:** {date.today().isoformat()}",
        "",
        "Per patent, this folder contains three draft variants:",
        "- **BROAD**: higher-level Claim 1 (fewer hard constraints)",
        "- **MEDIUM**: current spec claims as a baseline",
        "- **NARROW**: Claim 1 inlines 2–3 dependent limitations as fallback posture",
        "",
        "## Files",
        "",
    ]

    for p in sorted(OUTPUT_ROOT.rglob("*_claims_*.md")):
        index_lines.append(f"- `{rel(p)}`")
    index_lines.append("")
    write_text(OUTPUT_ROOT / "INDEX.md", "\n".join(index_lines))

    print(f"Wrote claim draft files: {written}")
    print(f"Output: {rel(OUTPUT_ROOT)}")


if __name__ == "__main__":
    main()

