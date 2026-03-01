#!/usr/bin/env python3
"""Generate canonical experiment registry and docs.

Tracks all experiment and training experiment scripts under designated roots,
assigns deterministic canonical names, and records future architecture placement.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
from pathlib import Path
import re
import sys
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[1]

EXPERIMENT_ROOTS = [
    ROOT / "docs/patents/experiments/scripts",
    ROOT / "scripts/ecommerce_experiments",
    ROOT / "scripts/ml",
]

INCLUDE_PATTERNS = [
    re.compile(r".*\.py$"),
    re.compile(r".*\.sh$"),
]

EXCLUDE_BASENAMES = {
    "__init__.py",
}

EXCLUDE_PARTS = {
    "__pycache__",
    "results",
    "venv",
    ".venv",
    "site-packages",
    "dist",
    "build",
    "node_modules",
}

REGISTRY_CSV = ROOT / "configs/experiments/EXPERIMENT_REGISTRY.csv"
REGISTRY_MD = ROOT / "docs/EXPERIMENT_REGISTRY.md"


FIELDNAMES = [
    "experiment_id",
    "legacy_script_path",
    "canonical_script_name",
    "target_architecture_space",
    "target_repo_path",
    "migration_status",
    "owner_model_id",
    "stage_contract",
    "master_plan_refs",
    "execution_milestone_id",
    "tracking_status",
    "notes",
]


def fail(msg: str) -> None:
    print(f"EXPERIMENT REGISTRY GENERATION FAILED: {msg}")
    sys.exit(1)


def source_digest(paths: List[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths, key=lambda p: str(p.relative_to(ROOT))):
        rel = str(path.relative_to(ROOT))
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()[:16]


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def is_candidate(path: Path) -> bool:
    rel = path.relative_to(ROOT)
    if any(part in EXCLUDE_PARTS for part in rel.parts):
        return False
    if path.name in EXCLUDE_BASENAMES:
        return False
    rel_str = str(rel)
    return any(p.match(rel_str) for p in INCLUDE_PATTERNS)


def list_experiment_files() -> List[Path]:
    files: List[Path] = []
    for root in EXPERIMENT_ROOTS:
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if p.is_file() and is_candidate(p):
                files.append(p)
    return sorted(files, key=lambda p: str(p.relative_to(ROOT)))


def normalize_slug(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    slug = re.sub(r"_+", "_", slug)
    return slug


def canonical_script_name(legacy_rel: str) -> str:
    name = Path(legacy_rel).stem
    ext = Path(legacy_rel).suffix

    name = name.replace("run_", "")
    name = name.replace("_experiments", "")
    name = name.replace("_experiment", "")
    name = name.replace("focused_tests", "focused")
    name = normalize_slug(name)

    if not name.startswith("exp_"):
        name = f"exp_{name}"

    if not re.search(r"_v\d+$", name):
        name = f"{name}_v1"

    return f"{name}{ext}"


def architecture_space(legacy_rel: str) -> str:
    if legacy_rel.startswith("docs/patents/experiments/scripts/"):
        return "experiments/patent_validation"
    if legacy_rel.startswith("scripts/ecommerce_experiments/"):
        return "experiments/ecommerce"
    if legacy_rel.startswith("scripts/ml/"):
        return "experiments/model_training"
    return "experiments/misc"


def owner_model(legacy_rel: str) -> str:
    s = legacy_rel.lower()
    if "entanglement" in s:
        return "mdl-quantum-entanglement-v1"
    if "quantum_optimization" in s:
        return "mdl-quantum-optimization-v1"
    if "knot" in s or "worldsheet" in s or "string" in s:
        return "mdl-knot-string-worldsheet-v1"
    if "atomic" in s or "temporal" in s or "patent_30" in s:
        return "mdl-atomic-temporal-sync-v1"
    if "calling_score" in s:
        return "mdl-spot-energy-v1"
    if "outcome_prediction" in s:
        return "mdl-event-energy-v1"
    return "none"


def master_plan_refs_for_space(space: str) -> str:
    if space == "experiments/patent_validation":
        return "7.9.6|7.9.14|1.1E.2"
    if space == "experiments/ecommerce":
        return "9.2.6|7.7"
    if space == "experiments/model_training":
        return "1.6.3|5.2|7.7"
    return "7.9.6"


def stage_contract_for_space(space: str) -> str:
    if space in {"experiments/model_training", "experiments/ecommerce"}:
        return "sim-standard-v1"
    return "exp-staged-v1"


def build_rows(files: List[Path]) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    for file in files:
        legacy_rel = str(file.relative_to(ROOT))
        space = architecture_space(legacy_rel)
        canonical = canonical_script_name(legacy_rel)
        row = {
            "experiment_id": normalize_slug(legacy_rel).replace("_py", "").replace("_sh", ""),
            "legacy_script_path": legacy_rel,
            "canonical_script_name": canonical,
            "target_architecture_space": space,
            "target_repo_path": f"scripts/{space}/{canonical}",
            "migration_status": "planned",
            "owner_model_id": owner_model(legacy_rel),
            "stage_contract": stage_contract_for_space(space),
            "master_plan_refs": master_plan_refs_for_space(space),
            "execution_milestone_id": "M0-P10-1",
            "tracking_status": "tracked",
            "notes": "Generated from canonical experiment scan.",
        }
        rows.append(row)
    return rows


def write_csv(rows: List[Dict[str, str]]) -> None:
    REGISTRY_CSV.parent.mkdir(parents=True, exist_ok=True)
    with REGISTRY_CSV.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)


def render_md(rows: List[Dict[str, str]], source_paths: List[Path]) -> str:
    generated = source_digest(source_paths)
    lines: List[str] = []
    lines.append("# Experiment Registry")
    lines.append("")
    lines.append("Generated file. Do not edit manually.")
    lines.append(f"Generated Source Digest: `{generated}`")
    lines.append("")
    lines.append("## Purpose")
    lines.append("Canonical registry for experiment scripts, deterministic naming, and future architecture placement.")
    lines.append("")

    by_space: Dict[str, List[Dict[str, str]]] = {}
    for row in rows:
        by_space.setdefault(row["target_architecture_space"], []).append(row)

    total = len(rows)
    lines.append(f"Total tracked experiments/scripts: **{total}**")
    lines.append("")

    for space in sorted(by_space.keys()):
        lines.append(f"## {space}")
        lines.append("")
        lines.append("| Experiment ID | Legacy Path | Canonical Name | Owner Model | Stage Contract | Status |")
        lines.append("|---|---|---|---|---|---|")
        for row in sorted(by_space[space], key=lambda r: r["legacy_script_path"]):
            lines.append(
                "| {experiment_id} | `{legacy}` | `{canonical}` | `{owner}` | `{stage}` | {status} |".format(
                    experiment_id=row["experiment_id"],
                    legacy=row["legacy_script_path"],
                    canonical=row["canonical_script_name"],
                    owner=row["owner_model_id"],
                    stage=row["stage_contract"],
                    status=row["migration_status"],
                )
            )
        lines.append("")

    lines.append("## Migration Rules")
    lines.append("")
    lines.append("1. Legacy paths remain executable until wrappers are migrated.")
    lines.append("2. Canonical names are deterministic and must end with `_vN` version suffix.")
    lines.append("3. Each experiment must map to one architecture space and one stage contract.")
    lines.append("4. New experiment scripts must appear in this registry in the same PR.")
    lines.append("")

    lines.append("## Source Inputs")
    lines.append("")
    for p in source_paths:
        lines.append(f"- `{p.relative_to(ROOT)}`")
    lines.append("")

    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate experiment registry artifacts.")
    parser.add_argument("--check", action="store_true", help="Fail if outputs are stale.")
    args = parser.parse_args()

    files = list_experiment_files()
    if not files:
        fail("No experiment files detected.")

    rows = build_rows(files)
    md = render_md(rows, files)

    csv_text = None
    with Path("/tmp/exp_registry_tmp.csv").open("w", encoding="utf-8", newline="") as tmp:
        writer = csv.DictWriter(tmp, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)
    csv_text = Path("/tmp/exp_registry_tmp.csv").read_text(encoding="utf-8")

    if args.check:
        if not REGISTRY_CSV.exists() or not REGISTRY_MD.exists():
            fail("Missing generated registry artifacts. Run generator without --check.")
        current_csv = REGISTRY_CSV.read_text(encoding="utf-8")
        current_md = REGISTRY_MD.read_text(encoding="utf-8")
        if current_csv != csv_text:
            fail("Stale registry CSV: configs/experiments/EXPERIMENT_REGISTRY.csv")
        if current_md != md:
            fail("Stale registry doc: docs/EXPERIMENT_REGISTRY.md")
        print("Experiment registry artifacts are up to date.")
        return

    write_csv(rows)
    REGISTRY_MD.write_text(md, encoding="utf-8")

    print("Generated:")
    print(f"- {REGISTRY_CSV}")
    print(f"- {REGISTRY_MD}")
    print("Artifact hashes:")
    print(f"- {REGISTRY_CSV}: {file_sha256(REGISTRY_CSV)}")
    print(f"- {REGISTRY_MD}: {file_sha256(REGISTRY_MD)}")


if __name__ == "__main__":
    main()
