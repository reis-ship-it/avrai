#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import sys

from architecture_placement_common import (
    PLACEMENT_TRACK_PREFIXES,
    WORK_ROOT,
    derive_spot,
    tracked_files,
)
from generate_master_plan_file_mapping import build_rows

SPOTS_CSV = WORK_ROOT / "docs" / "plans" / "architecture" / "ARCHITECTURE_SPOTS_REGISTRY.csv"


def fail(message: str) -> None:
    print(f"ARCHITECTURE PLACEMENT CHECK FAILED: {message}")
    sys.exit(1)


def validate_dependency_graph(path: str, row: dict[str, str]) -> str | None:
    raw = row.get("dependency_graph", "").strip()
    if not raw:
        return "missing dependency_graph payload"

    try:
        graph = json.loads(raw)
    except json.JSONDecodeError as exc:
        return f"invalid dependency_graph JSON ({exc})"

    required_keys = {
        "graph_version",
        "node_id",
        "change_class",
        "change_line",
        "lane",
        "order",
        "depends_on",
        "spot",
        "phase_refs",
        "required_checks",
        "injections",
        "notes",
    }
    missing_keys = sorted(required_keys - set(graph.keys()))
    if missing_keys:
        return f"dependency_graph missing keys: {', '.join(missing_keys)}"

    if graph["graph_version"] != "v1":
        return f"unsupported dependency_graph version: {graph['graph_version']}"

    expected_node_id = f"file:{path}"
    if graph["node_id"] != expected_node_id:
        return f"node_id mismatch: expected {expected_node_id}, found {graph['node_id']}"

    if graph["change_class"] != row.get("disposition"):
        return "change_class must exactly match disposition"

    if graph["change_line"] != "steady":
        return "current placement guard only allows steady dependency graphs"

    if not isinstance(graph["order"], int) or graph["order"] != 0:
        return "steady entries must have order=0"

    if not isinstance(graph["depends_on"], list):
        return "depends_on must be a list"
    if any(not isinstance(item, str) for item in graph["depends_on"]):
        return "depends_on entries must be strings"

    expected_spot = f"spot:{derive_spot(path)}"
    if graph["spot"] != expected_spot:
        return f"spot mismatch: expected {expected_spot}, found {graph['spot']}"

    if not isinstance(graph["phase_refs"], list):
        return "phase_refs must be a list"

    if not isinstance(graph["required_checks"], list) or not graph["required_checks"]:
        return "required_checks must be a non-empty list"

    injections = graph["injections"]
    if not isinstance(injections, dict):
        return "injections must be an object"

    required_injection_keys = {"mode", "roots", "provides", "consumes", "required_validation", "notes"}
    missing_injection_keys = sorted(required_injection_keys - set(injections.keys()))
    if missing_injection_keys:
        return f"injections missing keys: {', '.join(missing_injection_keys)}"

    if injections["mode"] not in {"provider", "consumer", "none"}:
        return "injections.mode must be provider|consumer|none"

    for key in ("roots", "provides", "consumes", "required_validation"):
        if not isinstance(injections[key], list):
            return f"injections.{key} must be a list"
        if any(not isinstance(item, str) for item in injections[key]):
            return f"injections.{key} entries must be strings"

    return None


def main() -> None:
    if not SPOTS_CSV.exists():
        fail(f"Missing spots registry: {SPOTS_CSV}")

    tracked = sorted(tracked_files(PLACEMENT_TRACK_PREFIXES))
    mapping_rows = {row["file"]: row for row in build_rows()}

    missing_in_mapping = [path for path in tracked if path not in mapping_rows]
    if missing_in_mapping:
        sample = "\n".join(missing_in_mapping[:20])
        fail(
            "Tracked files are missing from the on-demand architecture mapping. "
            "Update scripts/generate_master_plan_file_mapping.py or the placement scope.\n"
            f"Sample:\n{sample}"
        )

    bad_dispositions = {"review_required", "delete_candidate"}
    offenders = [path for path in tracked if mapping_rows[path].get("disposition") in bad_dispositions]
    if offenders:
        sample = "\n".join(offenders[:20])
        fail(
            "Files have forbidden unresolved dispositions (review_required/delete_candidate). "
            "Update placement rules or move the files before merge.\n"
            f"Sample:\n{sample}"
        )

    graph_errors = []
    for path in tracked:
        error = validate_dependency_graph(path, mapping_rows[path])
        if error:
            graph_errors.append((path, error))

    if graph_errors:
        sample = "\n".join(f"{path} -> {error}" for path, error in graph_errors[:20])
        fail(
            "Strict dependency graph validation failed for generated mapping rows. "
            "Resolve malformed per-file dependency metadata in scripts/generate_master_plan_file_mapping.py.\n"
            f"Sample:\n{sample}"
        )

    allowed_spots = set()
    with SPOTS_CSV.open() as handle:
        for row in csv.DictReader(handle):
            allowed_spots.add(row["spot_key"])

    missing_spots = []
    for path in tracked:
        spot = derive_spot(path)
        if spot not in allowed_spots:
            missing_spots.append((path, spot))

    if missing_spots:
        sample = "\n".join(f"{path} -> {spot}" for path, spot in missing_spots[:20])
        fail(
            "File path falls into an unregistered architecture spot. "
            "Create the spot in docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv, regenerate artifacts, and commit.\n"
            f"Sample:\n{sample}"
        )

    print(
        "Architecture placement check passed: every tracked monorepo file in the enforced scope is mapped and assigned to a registered architecture spot."
    )


if __name__ == "__main__":
    main()
