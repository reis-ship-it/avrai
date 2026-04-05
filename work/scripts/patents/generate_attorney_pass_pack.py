#!/usr/bin/env python3
"""
Generate an attorney-review pack for SPOTS patent specs.

This script is intentionally conservative:
- It does NOT modify the patent specs or visuals.
- It generates per-patent review notes (heuristic flags) to accelerate counsel review:
  - claim dependency map
  - potential antecedent-basis flags (heuristic)
  - potential indefiniteness/clarity flags
  - heuristic written-description support scan (claims terms vs Detailed Description)
  - prior-art positioning hooks extracted from document content

Usage:
  python3 scripts/patents/generate_attorney_pass_pack.py

Output:
  docs/patents/filing_preparation/attorney_pass/YYYY-MM-DD/...
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PATENTS_ROOT = PROJECT_ROOT / "docs" / "patents"
OUTPUT_ROOT = (
    PATENTS_ROOT
    / "filing_preparation"
    / "attorney_pass"
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
CLAIM_LINE_RE = re.compile(r"^(?P<num>\d+)\.\s+(?P<body>.*)$", flags=re.M)
FIG_LIST_RE = re.compile(
    r"^##\s+Figures\s*$\n(?P<body>.*?)(?=^##\s+\S|\Z)",
    flags=re.M | re.S,
)
FIG_BULLET_RE = re.compile(
    r"^- \*\*FIG\.\s*(?P<num>\d+)\*\*:\s*(?P<cap>.*?)\.?\s*$",
    flags=re.M,
)


WORD_RE = re.compile(r"[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*")


def count_words(s: str) -> int:
    return len(WORD_RE.findall(s))


def safe_read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")


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


def paired_visuals_path(main_doc: Path) -> Path | None:
    if main_doc.name == "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md":
        return None
    return main_doc.with_name(main_doc.stem + "_visuals.md")


def parse_sections(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in SECTION_RE.finditer(text):
        name = m.group("name").strip()
        body = m.group("body").strip()
        out[name] = body
    return out


def extract_title(text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+?)\s*$", text, flags=re.M)
    return m.group(1).strip() if m else fallback


def extract_innovation_number(text: str) -> str | None:
    m = re.search(r"^\*\*Patent Innovation #(\d+)\*\*", text, flags=re.M)
    return m.group(1) if m else None


@dataclass(frozen=True)
class Claim:
    num: int
    text: str


def parse_claims(claims_body: str) -> list[Claim]:
    # A simple (but stable) parser: treat each "N." as claim header.
    matches = list(CLAIM_LINE_RE.finditer(claims_body))
    if not matches:
        return []
    out: list[Claim] = []
    for i, m in enumerate(matches):
        n = int(m.group("num"))
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(claims_body)
        chunk = claims_body[start:end].strip()
        # Remove the leading "N." line label from the chunk while preserving remainder.
        chunk = re.sub(rf"^{re.escape(str(n))}\.\s*", "", chunk, count=1)
        out.append(Claim(num=n, text=chunk.strip()))
    return out


def claim_dependency_map(claims: list[Claim]) -> dict[int, list[int]]:
    """
    Returns mapping: claim -> referenced claim(s), based on phrases like:
      - "The method of claim 1, ..."
      - "The system of claim 3, ..."
    """
    refs: dict[int, list[int]] = {}
    for c in claims:
        # Pull all explicit "claim X" references in the first sentence/lead-in.
        lead = c.text.split("\n", 1)[0][:300]
        nums = [int(x) for x in re.findall(r"\bclaim\s+(\d+)\b", lead, flags=re.I)]
        # Remove self-reference if present.
        nums = [n for n in nums if n != c.num]
        refs[c.num] = sorted(set(nums))
    return refs


def claim_type_from_claim1(claim1_text: str) -> str | None:
    lead = claim1_text.strip()[:300]
    if re.search(r"\bmethod\b", lead, flags=re.I):
        return "method"
    if re.search(r"\bsystem\b", lead, flags=re.I):
        return "system"
    if re.search(r"\bdevice\b", lead, flags=re.I):
        return "device"
    if re.search(r"\bnon[-\s]?transitory\b", lead, flags=re.I):
        return "non-transitory computer-readable medium"
    return None


def extract_terms_from_definitions(definitions_body: str) -> list[str]:
    # Match bullets like: - **“Term”** means ...
    terms = []
    for m in re.finditer(r'^\s*-\s+\*\*“([^”]+)”\*\*\s+means\b', definitions_body, flags=re.M | re.I):
        terms.append(m.group(1).strip())
    return sorted(set(terms), key=str.lower)


def extract_candidate_noun_phrases(text: str, max_terms: int = 60) -> list[str]:
    """
    Heuristic term extraction for support scans:
    - pull CamelCase / snake_case / key technical tokens
    - pull quoted terms
    """
    tokens: set[str] = set()

    # quoted terms
    for m in re.finditer(r"“([^”]{2,60})”", text):
        tokens.add(m.group(1).strip())

    # snake_case and identifiers
    for m in re.finditer(r"\b[a-z]+(?:_[a-z0-9]+){1,}\b", text):
        tokens.add(m.group(0))

    # CamelCase-ish (avoid screaming caps blocks)
    for m in re.finditer(r"\b[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]+)+\b", text):
        tokens.add(m.group(0))

    # key phrases (very small list; keep conservative)
    for phrase in [
        "atomic timestamp",
        "atomic time",
        "differential privacy",
        "epsilon",
        "entropy",
        "AI2AI",
        "privacy-preserving",
        "zero-knowledge",
        "consensus",
        "quantum state",
        "inner product",
        "Bures distance",
        "Laplace noise",
    ]:
        if phrase.lower() in text.lower():
            tokens.add(phrase)

    # Normalize/truncate
    out = sorted(tokens, key=str.lower)
    return out[:max_terms]


def antecedent_basis_flags(claims: list[Claim]) -> list[str]:
    """
    VERY heuristic: flags 'the X' where X appears to be a concrete noun and
    does not appear introduced as 'a/an X' in the same claim or claim 1.

    This is a triage aid for counsel; not a definitive legal analysis.
    """
    if not claims:
        return []

    claim1 = claims[0].text
    introduced = set()
    for m in re.finditer(r"\b(?:a|an)\s+([a-z][a-z0-9_-]{2,40})\b", claim1, flags=re.I):
        introduced.add(m.group(1).lower())

    flags: list[str] = []
    for c in claims:
        local_intro = set(introduced)
        for m in re.finditer(r"\b(?:a|an)\s+([a-z][a-z0-9_-]{2,40})\b", c.text, flags=re.I):
            local_intro.add(m.group(1).lower())

        # Candidate definite terms: the <token>
        for m in re.finditer(r"\bthe\s+([a-z][a-z0-9_-]{2,40})\b", c.text, flags=re.I):
            term = m.group(1).lower()
            if term in {"method", "system", "device", "apparatus", "medium"}:
                continue
            if term not in local_intro:
                # Avoid over-flagging very generic words
                if term in {"data", "value", "values", "information", "user"}:
                    continue
                flags.append(f"Claim {c.num}: definite term “the {term}” may lack antecedent basis (heuristic).")
    # De-dup but preserve order
    seen = set()
    out = []
    for f in flags:
        if f not in seen:
            out.append(f)
            seen.add(f)
    return out


def clarity_flags(claims: list[Claim]) -> dict[str, int]:
    needles = {
        "and/or": r"\band/or\b",
        "approximately/about": r"\b(approximately|about)\b",
        "may/can": r"\b(may|can)\b",
        "etc.": r"\betc\.\b",
        "e.g.": r"\be\.g\.\b",
    }
    counts = {k: 0 for k in needles}
    for c in claims:
        for k, pat in needles.items():
            counts[k] += len(re.findall(pat, c.text, flags=re.I))
    return counts


def support_scan(claims: list[Claim], detailed_description: str) -> list[str]:
    """
    Heuristic support scan: pull salient tokens from claims and check whether they appear
    in the Detailed Description section.
    """
    dd = detailed_description.lower()
    combined = "\n\n".join(c.text for c in claims)
    candidates = extract_candidate_noun_phrases(combined, max_terms=80)
    missing = []
    for t in candidates:
        needle = t.lower()
        if needle not in dd:
            # allow epsilon to be described as ε
            if needle == "epsilon" and ("ε" in detailed_description):
                continue
            missing.append(t)
    # keep it short and high signal
    return missing[:30]


def prior_art_hooks(text: str) -> list[str]:
    t = text.lower()
    hooks: list[str] = []
    candidates = [
        ("offline-first", ["offline"]),
        ("AI2AI agent exchange (privacy-preserving)", ["ai2ai"]),
        ("differential privacy budget (ε) + noise calibration", ["differential privacy", "epsilon", "ε"]),
        ("entropy validation as an acceptance criterion", ["entropy"]),
        ("atomic-time / atomic timestamp integration", ["atomic timestamp", "atomic time", "atomic clock"]),
        ("consensus-based inference from peer agents", ["consensus"]),
        ("quantum-state representation + compatibility computation", ["quantum state", "inner product", "bures"]),
        ("zero-knowledge / anonymized signature exchange", ["zero-knowledge", "anonymized", "signature"]),
    ]
    for label, keys in candidates:
        if any(k in t for k in keys):
            hooks.append(label)
    return hooks


def write_markdown(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def render_pass_doc(
    *,
    title: str,
    main_doc: Path,
    visuals_doc: Path | None,
    sections: dict[str, str],
    claims: list[Claim],
) -> str:
    innovation = extract_innovation_number(safe_read(main_doc))
    abstract_wc = count_words(sections.get("Abstract", ""))

    dep_map = claim_dependency_map(claims)
    claim1_type = claim_type_from_claim1(claims[0].text) if claims else None

    definitions_terms = extract_terms_from_definitions(sections.get("Definitions", "")) if "Definitions" in sections else []
    antecedent_flags = antecedent_basis_flags(claims)
    clarity = clarity_flags(claims)
    support_missing = support_scan(claims, sections.get("Detailed Description", "")) if "Detailed Description" in sections else []
    hooks = prior_art_hooks(safe_read(main_doc))

    lines: list[str] = []
    lines.append(f"# Attorney Pass — {title}")
    lines.append("")
    if innovation:
        lines.append(f"**Patent Innovation #{innovation}**")
        lines.append("")
    lines.append(f"**Source spec:** `{rel(main_doc)}`")
    if visuals_doc is not None:
        lines.append(f"**Source visuals:** `{rel(visuals_doc)}`")
    lines.append(f"**Generated:** {date.today().isoformat()}")
    lines.append("")
    lines.append("> **NOTE:** This document is a *heuristic triage aid* for legal review. It is not legal advice and may contain false positives.")
    lines.append("")

    lines.append("## Snapshot")
    lines.append(f"- **Abstract word count**: {abstract_wc}")
    lines.append(f"- **Independent claim type (heuristic)**: {claim1_type or 'unknown'}")
    if hooks:
        lines.append("- **Distinctive hooks present (auto-detected)**:")
        for h in hooks:
            lines.append(f"  - {h}")
    else:
        lines.append("- **Distinctive hooks present (auto-detected)**: none detected (may be false negative)")
    lines.append("")

    lines.append("## Claim dependency map (auto-parsed)")
    if not claims:
        lines.append("- No claims parsed.")
    else:
        for c in claims:
            refs = dep_map.get(c.num, [])
            if refs:
                lines.append(f"- Claim {c.num} → depends on claim(s): {', '.join(str(r) for r in refs)}")
            else:
                lines.append(f"- Claim {c.num} → no explicit claim reference detected in lead-in")
    lines.append("")

    lines.append("## Potential antecedent basis flags (heuristic)")
    if antecedent_flags:
        for f in antecedent_flags[:40]:
            lines.append(f"- {f}")
        if len(antecedent_flags) > 40:
            lines.append(f"- … ({len(antecedent_flags) - 40} more)")
    else:
        lines.append("- None flagged by heuristic.")
    lines.append("")

    lines.append("## Potential indefiniteness / clarity flags (counts)")
    for k, v in clarity.items():
        lines.append(f"- **{k}**: {v}")
    lines.append("")

    lines.append("## Written description support scan (heuristic)")
    if "Detailed Description" not in sections:
        lines.append("- Missing `## Detailed Description` section in spec (unexpected).")
    elif not claims:
        lines.append("- No claims parsed; support scan skipped.")
    elif support_missing:
        lines.append("Terms present in claims that were **not found** in `## Detailed Description` (heuristic):")
        for t in support_missing:
            lines.append(f"- `{t}`")
    else:
        lines.append("- No missing claim terms detected by heuristic scan.")
    lines.append("")

    lines.append("## Definitions coverage")
    if definitions_terms:
        lines.append("Defined terms detected in `## Definitions`:")
        for t in definitions_terms:
            lines.append(f"- `{t}`")
    else:
        lines.append("- No definition terms detected (or Definitions section absent).")
    lines.append("")

    lines.append("## Counsel notes (fill-in)")
    lines.append("- **Center-of-gravity**: (what we want claim 1 to own)")
    lines.append("- **Narrowing fallback**: (if prior art requires narrowing)")
    lines.append("- **Enablement risk**: (any step that is underspecified)")
    lines.append("- **Prior art search terms**: (keywords counsel should search)")
    lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    main_docs = sorted(
        [p for p in PATENTS_ROOT.glob("category_*/*/*.md") if is_main_patent_doc(p)],
        key=lambda x: str(x),
    )

    # Optional top-level doc (no visuals pairing expected).
    extra = PATENTS_ROOT / "MULTI_ENTITY_QUANTUM_ENTANGLEMENT_MATCHING.md"
    if extra.exists() and is_main_patent_doc(extra):
        main_docs.append(extra)

    generated = 0
    for main_doc in main_docs:
        text = safe_read(main_doc)
        sections = parse_sections(text)
        title = extract_title(text, fallback=main_doc.stem.replace("_", " "))

        visuals = paired_visuals_path(main_doc)
        if visuals is not None and not visuals.exists():
            visuals = None

        claims_body = sections.get("Claims", "")
        claims = parse_claims(claims_body)

        out_path = OUTPUT_ROOT / main_doc.relative_to(PATENTS_ROOT)
        out_path = out_path.with_suffix("")  # drop .md
        out_path = out_path.with_name(out_path.name + "_attorney_pass.md")
        out_path = out_path.with_suffix(".md")

        content = render_pass_doc(
            title=title,
            main_doc=main_doc,
            visuals_doc=visuals,
            sections=sections,
            claims=claims,
        )
        write_markdown(out_path, content)
        generated += 1

    index_lines = [
        "# Attorney Pass Pack",
        "",
        f"**Generated:** {date.today().isoformat()}",
        "",
        "This folder contains per-patent attorney pass notes (heuristic triage aids).",
        "",
        "## Files",
        "",
    ]
    for p in sorted(OUTPUT_ROOT.rglob("*_attorney_pass.md")):
        index_lines.append(f"- `{rel(p)}`")
    index_lines.append("")
    write_markdown(OUTPUT_ROOT / "INDEX.md", "\n".join(index_lines))

    print(f"Generated attorney pass docs: {generated}")
    print(f"Output: {rel(OUTPUT_ROOT)}")


if __name__ == "__main__":
    main()
