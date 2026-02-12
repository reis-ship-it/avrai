#!/usr/bin/env python3
"""
Generate higher-touch claim drafts for the retiered Top 10 patents.

Inputs:
  docs/patents/filing_preparation/retiering/YYYY-MM-DD/TOP_10.md

Outputs:
  docs/patents/filing_preparation/claims_drafts/high_touch_top10/YYYY-MM-DD/...

Notes:
- This does NOT modify the specs.
- It produces a single counsel-facing file per patent containing:
  - Claim 1 options (BROAD / MEDIUM / NARROW)
  - Cleaned baseline claims (2..N) from the spec
  - Optional companion independents (system + CRM) tied to Claim 1
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PATENTS_ROOT = PROJECT_ROOT / "docs" / "patents"
STAMP = datetime.now().astimezone().date().isoformat()

RETIER_DIR = PATENTS_ROOT / "filing_preparation" / "retiering" / STAMP
TOP10_PATH = RETIER_DIR / "TOP_10.md"

OUT_DIR = (
    PATENTS_ROOT
    / "filing_preparation"
    / "claims_drafts"
    / "high_touch_top10"
    / STAMP
)


SECTION_RE = re.compile(
    r"^##\s+(?P<name>.+?)\s*$\n(?P<body>.*?)(?=^##\s+\S|\Z)",
    flags=re.M | re.S,
)
CLAIM_NUM_LINE_RE = re.compile(r"^(?P<num>\d+)\.\s+(?P<body>.*)$", flags=re.M)
SUBPART_LINE_RE = re.compile(r"^\s*\(([a-z])\)\s+(.+?)\s*$", flags=re.M)
HR_LINE_RE = re.compile(r"^\s*---\s*$", flags=re.M)


def safe_read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")


def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")


def rel(p: Path) -> str:
    return str(p.relative_to(PROJECT_ROOT))


def extract_title(text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+?)\s*$", text, flags=re.M)
    return m.group(1).strip() if m else fallback


def parse_sections(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in SECTION_RE.finditer(text):
        out[m.group("name").strip()] = m.group("body").strip()
    return out


@dataclass(frozen=True)
class Claim:
    num: int
    text: str


def strip_non_claim_trailing_content(s: str) -> str:
    m = HR_LINE_RE.search(s)
    if m:
        return s[: m.start()].rstrip()
    m2 = re.search(r"^\s*#{2,}\s+\S", s, flags=re.M)
    if m2:
        return s[: m2.start()].rstrip()
    return s.strip()


def clean_claim_text(s: str) -> str:
    s = strip_non_claim_trailing_content(s)
    s = re.sub(r"^\s*#{2,}\s+.+$", "", s, flags=re.M)
    s = "\n".join(line.rstrip() for line in s.splitlines()).strip()
    return s


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
        out.append(Claim(num=n, text=clean_claim_text(chunk)))
    return out


def format_subparts_if_present(s: str) -> str:
    matches = list(SUBPART_LINE_RE.finditer(s))
    if not matches:
        return s.strip().rstrip(".") + "."
    preamble = s[: matches[0].start()].rstrip().rstrip(";").rstrip(".")
    # Avoid double colons like "comprising::" or ":::"
    preamble = preamble.rstrip(":").rstrip()
    subparts = []
    for m in matches:
        letter = m.group(1)
        body = m.group(2).strip().rstrip(";").rstrip(".")
        subparts.append((letter, body))
    out_lines = [preamble + ":"]
    for i, (letter, body) in enumerate(subparts):
        end = "." if i == len(subparts) - 1 else ";"
        out_lines.append(f"  ({letter}) {body}{end}")
    return "\n".join(out_lines).strip()


def strip_numeric_constraints(s: str) -> str:
    s = re.sub(r"\b\d+(\.\d+)?\s*%\b", "a threshold percentage", s)
    s = re.sub(r"\b0\.\d+\b", "a threshold value", s)
    s = re.sub(r"\b\d+\s*(ms|s|sec|seconds|minutes|min|hours|days|m|km)\b", "a threshold interval", s, flags=re.I)
    s = re.sub(r"\[\s*0\s*,\s*1\s*\]", "a bounded range", s)
    return s


def compress_claim_to_high_level(claim1: str) -> str:
    txt = clean_claim_text(claim1)
    txt = strip_numeric_constraints(txt)
    txt = re.sub(r"\([^)]{40,}\)", "", txt)
    matches = list(SUBPART_LINE_RE.finditer(txt))
    if matches:
        preamble = txt[: matches[0].start()].rstrip().rstrip(";").rstrip(".")
        kept = matches[:5]
        out_lines = [preamble + ":"]
        for i, m in enumerate(kept):
            letter = chr(ord("a") + i)
            body = m.group(2).strip().rstrip(";").rstrip(".")
            end = "." if i == len(kept) - 1 else ";"
            out_lines.append(f"  ({letter}) {body}{end}")
        return "\n".join(out_lines).strip()
    clauses = [c.strip() for c in re.split(r";\s*", txt) if c.strip()]
    if len(clauses) >= 3:
        return "; ".join(clauses[:3]).rstrip(";").rstrip(".") + "."
    return txt.rstrip(".") + "."


def narrow_claim_by_inlining_dependents(claim1: str, dependents: list[Claim], max_inline: int = 3) -> str:
    base = clean_claim_text(claim1).rstrip(";").rstrip(".")
    additions: list[str] = []
    for c in dependents[: max_inline * 2]:
        lead = clean_claim_text(c.text).splitlines()[0].strip()
        clause = lead.split(",", 1)[1].strip() if "," in lead else lead
        clause = clause.rstrip(";").rstrip(".")
        clause = re.sub(r"^(the\s+)?(method|system|device)\s+of\s+claim\s+\d+\b", "", clause, flags=re.I).strip(" ,")
        clause = clause.rstrip(":").strip()
        # Skip garbage clauses that appear when a dependent claim lead-in is just "comprising:"
        if not clause:
            continue
        if clause.lower() in {"comprising", "comprising:", "wherein", "further comprising"}:
            continue
        if "comprising:" in clause.lower():
            clause = clause.replace("comprising:", "").strip(" ,")
        # Prevent inlining subpart blocks; keep only the lead-in limitation.
        clause = re.sub(r"\(a\).*", "", clause, flags=re.I).strip(" ,")
        if clause:
            additions.append(clause)
        if len(additions) >= max_inline:
            break
    if not additions:
        return format_subparts_if_present(clean_claim_text(claim1))
    return base + ", wherein " + "; and wherein ".join(additions) + "."


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
    return "method"


def companion_independent_claims(stat_class: str) -> list[str]:
    if stat_class == "method":
        return [
            "A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.",
            "A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.",
        ]
    if stat_class == "system":
        return [
            "A computer-implemented method performed by one or more processors of the system of claim 1.",
            "A non-transitory computer-readable medium storing instructions that, when executed, cause one or more processors to implement operations of the system of claim 1.",
        ]
    return [
        "A system comprising one or more processors and memory storing instructions to implement operations of claim 1.",
        "A computer-implemented method performed by one or more processors to implement operations of claim 1.",
    ]


def load_top10_specs() -> list[Path]:
    if not TOP10_PATH.exists():
        raise SystemExit(
            f"Missing TOP_10.md at {rel(TOP10_PATH)}. Run retier script first."
        )
    txt = safe_read(TOP10_PATH)
    specs = []
    for m in re.finditer(r"^\s*-\s+Spec:\s+`([^`]+)`\s*$", txt, flags=re.M):
        specs.append(PROJECT_ROOT / m.group(1))
    # The TOP_10.md format also uses: \"- Spec: `...`\" on indented lines; match those too:
    for m in re.finditer(r"^\s*-\s+Spec:\s+`([^`]+)`\s*$", txt, flags=re.M):
        specs.append(PROJECT_ROOT / m.group(1))
    # More permissive: \"Spec: `...`\" anywhere on a line
    for m in re.finditer(r"Spec:\s+`([^`]+)`", txt):
        specs.append(PROJECT_ROOT / m.group(1))
    # De-dupe while preserving order
    seen = set()
    out = []
    for p in specs:
        if p not in seen:
            out.append(p)
            seen.add(p)
    return out


def render_high_touch_file(title: str, spec_path: Path, claims: list[Claim]) -> str:
    dependents = [c for c in claims if c.num != 1]
    claim1_orig = claims[0].text if claims else ""
    claim1_medium = format_subparts_if_present(claim1_orig)
    claim1_broad = format_subparts_if_present(compress_claim_to_high_level(claim1_orig))
    claim1_narrow = format_subparts_if_present(narrow_claim_by_inlining_dependents(claim1_orig, dependents, max_inline=3))

    lines: list[str] = []
    lines.append(f"# {title} — High-Touch Claims Draft (Top 10 Priority)")
    lines.append("")
    lines.append(f"**Source spec:** `{rel(spec_path)}`")
    lines.append(f"**Generated:** {STAMP}")
    lines.append("")
    lines.append("> Draft for counsel review. This file does not modify the spec; it provides a polished, counsel-friendly presentation and Claim 1 scope options.")
    lines.append("")

    lines.append("## Claim 1 scope options (choose one posture)")
    lines.append("")
    lines.append("### Option A — BROAD")
    lines.append("")
    lines.append("1. " + claim1_broad.replace("\n", "\n   "))
    lines.append("")
    lines.append("### Option B — MEDIUM (baseline)")
    lines.append("")
    lines.append("1. " + claim1_medium.replace("\n", "\n   "))
    lines.append("")
    lines.append("### Option C — NARROW (fallback)")
    lines.append("")
    lines.append("1. " + claim1_narrow.replace("\n", "\n   "))
    lines.append("")

    lines.append("## Claims 2+ (baseline from spec; cleaned formatting)")
    lines.append("")
    for c in claims:
        if c.num == 1:
            continue
        txt = format_subparts_if_present(c.text)
        lines.append(f"{c.num}. {txt}")
        lines.append("")

    stat = claim1_statutory_class(claim1_orig)
    lines.append("## Optional companion independent claims (counsel may renumber)")
    lines.append("")
    for s in companion_independent_claims(stat):
        lines.append(f"- {s}")
    lines.append("")

    lines.append("## Counsel checklist (quick)")
    lines.append("- Confirm statutory class strategy (method/system/CRM) aligns with filing plan.")
    lines.append("- Check antecedent basis in Claim 1 (a/the transitions) and dependent claims.")
    lines.append("- Remove weak permissive terms in claims (\"may\", \"can\") if present.")
    lines.append("- Ensure every limitation is supported in `## Detailed Description` and drawings.")
    lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    specs = load_top10_specs()
    if not specs:
        raise SystemExit(f"Could not parse spec paths from {rel(TOP10_PATH)}")

    written = 0
    for spec in specs:
        if not spec.exists():
            raise SystemExit(f"Spec not found: {spec}")
        text = safe_read(spec)
        sections = parse_sections(text)
        claims_body = sections.get("Claims")
        if not claims_body:
            continue
        claims = parse_claims(claims_body)
        if not claims:
            continue

        title = extract_title(text, fallback=spec.stem.replace("_", " "))
        out_path = OUT_DIR / spec.parent.relative_to(PATENTS_ROOT) / f"{spec.stem}_claims_high_touch.md"
        write_text(out_path, render_high_touch_file(title, spec, claims))
        written += 1

    index = [
        "# High-Touch Claims Drafts — Retiered Top 10",
        "",
        f"**Generated:** {STAMP}",
        f"**Source Top 10:** `{rel(TOP10_PATH)}`",
        "",
        "## Files",
        "",
    ]
    for p in sorted(OUT_DIR.rglob("*_claims_high_touch.md")):
        index.append(f"- `{rel(p)}`")
    index.append("")
    write_text(OUT_DIR / "INDEX.md", "\n".join(index))

    print(f"Wrote high-touch files: {written}")
    print(f"Output: {rel(OUT_DIR)}")


if __name__ == "__main__":
    main()

