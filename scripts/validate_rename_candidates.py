#!/usr/bin/env python3
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENAME_DOC = ROOT / "docs" / "architecture" / "RENAME_CANDIDATES.md"
EXECUTION_BOARD_CSV = ROOT / "docs" / "EXECUTION_BOARD.csv"
MILESTONE_PATTERN = re.compile(r"^M\d+-P\d+-\d+$")
PHASE_PATTERN = re.compile(r"^P\d+$")
ARCH_REF_HINT_PATTERN = re.compile(
    r"(docs/MASTER_PLAN\.md|docs/architecture/|docs/plans/architecture/)"
)
VALID_STATUS = {"planned", "ready", "done"}
VALID_CATEGORY = {"service", "orchestrator", "class", "method", "feature", "file"}


def fail(msg: str) -> None:
    print(f"RENAME CANDIDATES CHECK FAILED: {msg}")
    sys.exit(1)


def load_execution_board_index() -> tuple[set[str], dict[str, str]]:
    if not EXECUTION_BOARD_CSV.exists():
        fail(f"Missing execution board CSV: {EXECUTION_BOARD_CSV}")
    ids: set[str] = set()
    phase_status: dict[str, str] = {}
    with EXECUTION_BOARD_CSV.open(newline="") as f:
        for row in csv.DictReader(f):
            row_type = row.get("type", "").strip()
            if row_type == "milestone":
                ids.add(row.get("id", "").strip())
            if row_type == "phase":
                phase_id = row.get("id", "").strip()
                if phase_id:
                    phase_status[phase_id] = row.get("status", "").strip()
    return ids, phase_status


def parse_markdown_rows() -> tuple[list[str], list[dict[str, str]]]:
    if not RENAME_DOC.exists():
        fail(f"Missing rename candidates register: {RENAME_DOC}")

    lines = RENAME_DOC.read_text().splitlines()
    header_index = -1
    for i, line in enumerate(lines):
        if line.strip().startswith("| id |"):
            header_index = i
            break

    if header_index < 0:
        fail("Could not find markdown table header starting with '| id |'.")
    if header_index + 1 >= len(lines):
        fail("Malformed markdown table: missing separator row.")

    header_cells = [c.strip() for c in lines[header_index].strip().strip("|").split("|")]
    rows: list[dict[str, str]] = []
    for line in lines[header_index + 2 :]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            break
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) != len(header_cells):
            fail(
                "Malformed markdown row in rename register: "
                f"expected {len(header_cells)} columns, found {len(cells)} in '{line}'"
            )
        rows.append(dict(zip(header_cells, cells)))
    return header_cells, rows


def main() -> None:
    headers, rows = parse_markdown_rows()
    required = {
        "id",
        "category",
        "phase_close_target",
        "status",
        "target_milestone",
        "ideal_architecture_ref",
    }
    missing = required - set(headers)
    if missing:
        fail(f"Rename register is missing required columns: {', '.join(sorted(missing))}")

    milestone_ids, phase_status = load_execution_board_index()
    errors: list[str] = []
    by_phase: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        rename_id = row.get("id", "").strip() or "<unknown>"

        category = row.get("category", "").strip().lower()
        if category not in VALID_CATEGORY:
            errors.append(
                f"{rename_id}: category '{category}' must be one of {sorted(VALID_CATEGORY)}."
            )

        phase_target = row.get("phase_close_target", "").strip()
        if not PHASE_PATTERN.fullmatch(phase_target):
            errors.append(
                f"{rename_id}: phase_close_target '{phase_target}' must match P#."
            )
        elif phase_target not in phase_status:
            errors.append(
                f"{rename_id}: phase_close_target '{phase_target}' not found in docs/EXECUTION_BOARD.csv phase rows."
            )
        else:
            by_phase.setdefault(phase_target, []).append(row)

        status = row.get("status", "").strip().lower()
        if status not in VALID_STATUS:
            errors.append(
                f"{rename_id}: status '{status}' must be one of {sorted(VALID_STATUS)}."
            )

        ideal_arch_ref = row.get("ideal_architecture_ref", "").strip()
        if not ideal_arch_ref:
            errors.append(
                f"{rename_id}: ideal_architecture_ref is required (must point to planned architecture docs)."
            )
            continue
        if not ARCH_REF_HINT_PATTERN.search(ideal_arch_ref):
            errors.append(
                f"{rename_id}: ideal_architecture_ref '{ideal_arch_ref}' must reference docs/MASTER_PLAN.md or architecture docs."
            )

    ready_rows = [r for r in rows if r.get("status", "").strip().lower() == "ready"]
    for row in ready_rows:
        rename_id = row.get("id", "").strip() or "<unknown>"
        target = row.get("target_milestone", "").strip()
        if not target:
            errors.append(f"{rename_id}: status=ready requires non-empty target_milestone.")
            continue
        if not MILESTONE_PATTERN.fullmatch(target):
            errors.append(
                f"{rename_id}: target_milestone '{target}' must match M#-P#-#."
            )
            continue
        if target not in milestone_ids:
            errors.append(
                f"{rename_id}: target_milestone '{target}' not found in docs/EXECUTION_BOARD.csv."
            )

    for phase_id, status in phase_status.items():
        if status.lower() != "done":
            continue
        for row in by_phase.get(phase_id, []):
            rename_id = row.get("id", "").strip() or "<unknown>"
            rename_status = row.get("status", "").strip().lower()
            if rename_status != "done":
                errors.append(
                    f"{rename_id}: phase {phase_id} is Done but rename status is '{rename_status}'. Mark done or retarget phase_close_target."
                )

    if errors:
        fail(";\n".join(errors))

    print(
        "Rename candidates check passed: entries are categorized, architecture-anchored, phase-targeted, and ready entries have valid milestones."
    )


if __name__ == "__main__":
    main()
