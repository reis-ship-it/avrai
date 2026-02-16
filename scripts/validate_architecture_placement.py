#!/usr/bin/env python3
import csv
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPING_CSV = ROOT / "docs" / "plans" / "architecture" / "generated" / "codebase_master_plan_mapping_2026-02-15.csv"
SPOTS_CSV = ROOT / "docs" / "plans" / "architecture" / "ARCHITECTURE_SPOTS_REGISTRY.csv"

TRACK_PREFIXES = (
    "lib/", "packages/", "native/", "scripts/", "supabase/", "test/", "tool/",
    "assets/", "android/", "ios/", "macos/", "linux/", "windows/", "web/"
)


def tracked_files() -> list[str]:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    files = [line.strip() for line in out.splitlines() if line.strip()]
    return [f for f in files if f.startswith(TRACK_PREFIXES)]


def derive_spot(path: str) -> str:
    p = path.split("/")
    if path.startswith("lib/core/services/") and len(p) >= 5:
        return f"lib/core/services/{p[3]}"
    if path.startswith("lib/core/") and len(p) >= 4:
        return f"lib/core/{p[2]}"
    if path.startswith("lib/presentation/") and len(p) >= 4:
        return f"lib/presentation/{p[2]}"
    if path.startswith("lib/data/") and len(p) >= 4:
        return f"lib/data/{p[2]}"
    if path.startswith("lib/domain/") and len(p) >= 4:
        return f"lib/domain/{p[2]}"
    if path.startswith("lib/"):
        if len(p) >= 2 and p[1].endswith(".dart"):
            return "lib/_root"
        if len(p) >= 2:
            return f"lib/{p[1]}"
    if path.startswith("packages/") and len(p) >= 2:
        return f"packages/{p[1]}"
    if path.startswith("native/") and len(p) >= 2:
        return f"native/{p[1]}"
    if path.startswith("test/") and len(p) >= 4:
        return f"test/{p[1]}/{p[2]}"
    if path.startswith("test/"):
        return "test/_root"
    if path.startswith("scripts/") and len(p) >= 3:
        return f"scripts/{p[1]}"
    if path.startswith("scripts/"):
        return "scripts/_root"
    if path.startswith("supabase/") and len(p) >= 2:
        return f"supabase/{p[1]}"
    if path.startswith("tool/") and len(p) >= 2:
        return f"tool/{p[1]}"
    if path.startswith("assets/") and len(p) >= 2:
        return f"assets/{p[1]}"
    if p and p[0] in {"android", "ios", "macos", "linux", "windows", "web"}:
        return f"{p[0]}/{p[1]}" if len(p) >= 2 else f"{p[0]}/_root"
    return "unknown/_root"


def fail(msg: str) -> None:
    print(f"ARCHITECTURE PLACEMENT CHECK FAILED: {msg}")
    sys.exit(1)


def validate_dependency_graph(path: str, row: dict) -> str | None:
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

    if not isinstance(graph["order"], int) or graph["order"] < 0:
        return "order must be a non-negative integer"

    if not isinstance(graph["depends_on"], list):
        return "depends_on must be a list"
    if any(not isinstance(item, str) for item in graph["depends_on"]):
        return "depends_on entries must be strings"

    if not isinstance(graph["required_checks"], list) or not graph["required_checks"]:
        return "required_checks must be a non-empty list"

    if not isinstance(graph["phase_refs"], list):
        return "phase_refs must be a list"

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

    is_refactor = row.get("disposition") == "refactor_planned" or "refactor" in (row.get("action") or "")
    if is_refactor:
        if graph["order"] <= 0:
            return "refactor entries must have order > 0"
        if len(graph["depends_on"]) == 0:
            return "refactor entries must declare at least one dependency"
        if graph["change_line"] != "refactor":
            return "refactor entries must have change_line=refactor"
        if injections["mode"] == "none":
            return "refactor entries must declare injections mode provider|consumer"
    else:
        if graph["order"] != 0:
            return "non-refactor entries must have order=0"
        if graph["change_line"] != "steady":
            return "non-refactor entries must have change_line=steady"

    return None


def main() -> None:
    if not MAPPING_CSV.exists():
        fail(f"Missing mapping CSV: {MAPPING_CSV}")
    if not SPOTS_CSV.exists():
        fail(f"Missing spots registry: {SPOTS_CSV}")

    tracked = tracked_files()

    mapping_rows = {}
    with MAPPING_CSV.open() as f:
        for row in csv.DictReader(f):
            mapping_rows[row["file"]] = row

    missing_in_mapping = [f for f in tracked if f not in mapping_rows]
    if missing_in_mapping:
        sample = "\n".join(missing_in_mapping[:20])
        fail(
            "New files are not mapped in architecture mapping CSV. "
            "Run: python3 scripts/generate_master_plan_file_mapping.py and commit updates.\n"
            f"Sample:\n{sample}"
        )

    bad_dispositions = {"review_required", "delete_candidate"}
    offenders = [f for f in tracked if mapping_rows[f].get("disposition") in bad_dispositions]
    if offenders:
        sample = "\n".join(offenders[:20])
        fail(
            "Files have non-actionable dispositions (review_required/delete_candidate). "
            "Resolve mapping rules or file placement first.\n"
            f"Sample:\n{sample}"
        )

    graph_errors = []
    for f in tracked:
        err = validate_dependency_graph(f, mapping_rows[f])
        if err:
            graph_errors.append((f, err))

    if graph_errors:
        sample = "\n".join([f"{f} -> {e}" for f, e in graph_errors[:20]])
        fail(
            "Strict dependency graph validation failed for mapping rows. "
            "Regenerate mapping and resolve malformed/missing per-file dependency graph metadata.\n"
            f"Sample:\n{sample}"
        )

    allowed_spots = set()
    with SPOTS_CSV.open() as f:
        for row in csv.DictReader(f):
            allowed_spots.add(row["spot_key"])

    missing_spots = []
    for f in tracked:
        spot = derive_spot(f)
        if spot not in allowed_spots:
            missing_spots.append((f, spot))

    if missing_spots:
        sample = "\n".join([f"{f} -> {s}" for f, s in missing_spots[:20]])
        fail(
            "File path falls into an unregistered architecture spot. "
            "Create a new spot in docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv "
            "(or place file into an existing spot), regenerate mapping artifacts, and commit.\n"
            f"Sample:\n{sample}"
        )

    print("Architecture placement check passed: every tracked file is mapped and assigned to a registered architecture spot.")


if __name__ == "__main__":
    main()
