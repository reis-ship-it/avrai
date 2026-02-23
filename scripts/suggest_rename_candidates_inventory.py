#!/usr/bin/env python3
"""Suggest or autofill untracked rename candidates from Service/Orchestrator names.

This is an advisory inventory tool (non-blocking). It helps keep
docs/architecture/RENAME_CANDIDATES.md complete as phases progress.
"""

from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENAME_DOC = ROOT / "docs" / "architecture" / "RENAME_CANDIDATES.md"
LIB_ROOT = ROOT / "lib"

CLASS_PATTERN = re.compile(
    r"^\s*class\s+([A-Za-z_]\w*(?:Service|Orchestrator))\b",
    re.MULTILINE,
)
RENAME_ID_PATTERN = re.compile(r"^REN-(\d+)$")


def _parse_markdown_table_context() -> tuple[list[str], int, int, list[str]]:
    if not RENAME_DOC.exists():
        raise FileNotFoundError(f"Missing rename register: {RENAME_DOC}")

    lines = RENAME_DOC.read_text().splitlines()
    header_idx = -1
    for idx, line in enumerate(lines):
        if line.strip().startswith("| id |"):
            header_idx = idx
            break
    if header_idx < 0:
        raise ValueError("Could not find rename register table header '| id |'.")

    body_start = header_idx + 2
    body_end = body_start
    for idx in range(body_start, len(lines)):
        if not lines[idx].strip().startswith("|"):
            body_end = idx
            break
    else:
        body_end = len(lines)

    headers = [c.strip() for c in lines[header_idx].strip().strip("|").split("|")]
    return lines, body_start, body_end, headers


def parse_rename_register_current_names() -> set[str]:
    lines, body_start, body_end, headers = _parse_markdown_table_context()
    if "current_name" not in headers:
        return set()
    current_name_idx = headers.index("current_name")

    covered: set[str] = set()
    for line in lines[body_start:body_end]:
        stripped = line.strip()
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) <= current_name_idx:
            continue
        raw = cells[current_name_idx].strip().strip("`")
        if not raw:
            continue
        # Support method entries like ClassName.methodName.
        covered.add(raw.split(".", 1)[0])
    return covered


def _next_rename_id(lines: list[str], body_start: int, body_end: int, headers: list[str]) -> int:
    if "id" not in headers:
        return 1
    id_idx = headers.index("id")
    max_id = 0
    for line in lines[body_start:body_end]:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) <= id_idx:
            continue
        raw = cells[id_idx].strip().strip("`")
        match = RENAME_ID_PATTERN.fullmatch(raw)
        if match:
            max_id = max(max_id, int(match.group(1)))
    return max_id + 1


def _markdown_row(headers: list[str], values: dict[str, str]) -> str:
    cells = [values.get(header, "").strip() for header in headers]
    return "| " + " | ".join(cells) + " |"


def append_candidates_to_register(
    untracked: dict[str, list[str]],
    *,
    phase_close_target: str,
    ideal_architecture_ref: str,
    limit: int | None,
) -> int:
    lines, body_start, body_end, headers = _parse_markdown_table_context()
    required_headers = {
        "id",
        "current_name",
        "proposed_name",
        "category",
        "phase_close_target",
        "scope",
        "reason",
        "trigger",
        "ideal_architecture_ref",
        "target_milestone",
        "compatibility_plan",
        "status",
        "added_on",
        "refs",
    }
    missing = required_headers - set(headers)
    if missing:
        raise ValueError(
            "Rename register missing required columns for autofill: "
            + ", ".join(sorted(missing))
        )

    items = sorted(untracked.items(), key=lambda kv: kv[0])
    if limit is not None:
        items = items[:limit]

    next_id = _next_rename_id(lines, body_start, body_end, headers)
    new_rows: list[str] = []
    for name, paths in items:
        category = "orchestrator" if name.endswith("Orchestrator") else "service"
        references = ", ".join(f"`{p}`" for p in sorted(paths))
        row_values = {
            "id": f"REN-{next_id:03d}",
            "current_name": f"`{name}`",
            "proposed_name": "",
            "category": category,
            "phase_close_target": phase_close_target,
            "scope": references,
            "reason": "Autofilled inventory candidate; align naming to planned architecture.",
            "trigger": "Phase-close rename review for target phase.",
            "ideal_architecture_ref": ideal_architecture_ref,
            "target_milestone": "",
            "compatibility_plan": "TBD during rename design (alias/shim + callsite migration).",
            "status": "planned",
            "added_on": date.today().isoformat(),
            "refs": references,
        }
        new_rows.append(_markdown_row(headers, row_values))
        next_id += 1

    if not new_rows:
        return 0

    output_lines = lines[:body_end] + new_rows + lines[body_end:]
    RENAME_DOC.write_text("\n".join(output_lines) + "\n")
    return len(new_rows)


def find_service_orchestrator_classes() -> dict[str, list[str]]:
    found: dict[str, list[str]] = {}
    for path in LIB_ROOT.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for class_name in CLASS_PATTERN.findall(text):
            rel = path.relative_to(ROOT).as_posix()
            found.setdefault(class_name, []).append(rel)
    return found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--fail-on-untracked",
        action="store_true",
        help="Exit with non-zero code when untracked candidates are found.",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Append untracked candidates to docs/architecture/RENAME_CANDIDATES.md.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Maximum number of candidates to append when --apply is used.",
    )
    parser.add_argument(
        "--phase-close-target",
        default="P10",
        help="Default phase_close_target for autofilled rows (default: P10).",
    )
    parser.add_argument(
        "--ideal-arch-ref",
        default="`docs/MASTER_PLAN.md` (TBD phase refs)",
        help="Default ideal_architecture_ref value for autofilled rows.",
    )
    args = parser.parse_args()

    covered = parse_rename_register_current_names()
    discovered = find_service_orchestrator_classes()

    untracked = {
        name: sorted(paths)
        for name, paths in discovered.items()
        if name not in covered
    }

    if not untracked:
        print(
            "Rename inventory check: all discovered *Service/*Orchestrator classes are tracked in the rename register."
        )
        return 0

    if args.apply:
        appended = append_candidates_to_register(
            untracked,
            phase_close_target=args.phase_close_target,
            ideal_architecture_ref=args.ideal_arch_ref,
            limit=args.limit,
        )
        print(
            f"Rename inventory autofill complete: appended {appended} candidate row(s) to {RENAME_DOC}."
        )
        return 0

    print("Rename inventory suggestions (not yet tracked):")
    for name in sorted(untracked):
        category = "orchestrator" if name.endswith("Orchestrator") else "service"
        print(f"- {name} [{category}]")
        for path in untracked[name]:
            print(f"  - {path}")

    return 1 if args.fail_on_untracked else 0


if __name__ == "__main__":
    raise SystemExit(main())
