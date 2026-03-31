#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
from pathlib import Path

from architecture_placement_common import (
    PLACEMENT_TRACK_PREFIXES,
    REPO_ROOT,
    WORK_ROOT,
    derive_spot,
    normalize_path,
    tracked_files,
)

OUT_DIR = WORK_ROOT / "docs" / "plans" / "architecture" / "generated"
OUT_DIR.mkdir(parents=True, exist_ok=True)
MD_PATH = WORK_ROOT / "docs" / "plans" / "architecture" / "CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md"
LOCAL_EXPORT_COMMAND = (
    "python3 scripts/generate_master_plan_file_mapping.py "
    "--emit-csv /tmp/codebase_master_plan_mapping_2026-02-15.csv"
)
FIELDNAMES = [
    "file",
    "bucket",
    "domain",
    "disposition",
    "phase_refs",
    "action",
    "confidence",
    "rationale",
    "dependency_graph",
]

Rule = tuple[str, dict[str, str]]

RULES: list[Rule] = [
    (
        r"^apps/admin_app/configs/runtime/",
        {
            "domain": "admin-runtime-config",
            "disposition": "keep_update",
            "phase_refs": "10.9.22,10.9.23,10.9.24,10.9.25,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Admin runtime control packs govern oversight, safety, and bounded autonomy surfaces.",
        },
    ),
    (
        r"^apps/avrai_app/configs/runtime/",
        {
            "domain": "apps-runtime-config",
            "disposition": "keep_update",
            "phase_refs": "10.10.3,10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "App runtime control packs define active app-prong execution and contract-consumer behavior.",
        },
    ),
    (
        r"^apps/.+/configs/",
        {
            "domain": "apps-config",
            "disposition": "keep_update",
            "phase_refs": "10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "App-prong configuration artifacts remain active package-owned surfaces under 3-prong execution.",
        },
    ),
    (
        r"^apps/admin_app/lib/(bootstrap|di)/|^apps/admin_app/lib/(injection_container|main).*\.dart$",
        {
            "domain": "admin-bootstrap",
            "disposition": "keep_update",
            "phase_refs": "10.10.3,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Admin bootstrap and DI composition define the admin app boundary to runtime and engine packages.",
        },
    ),
    (
        r"^apps/admin_app/lib/",
        {
            "domain": "admin-oversight-surface",
            "disposition": "keep_update",
            "phase_refs": "10.9.22,10.9.23,10.9.24,10.9.25,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Admin app UI, navigation, theme, and services are the active oversight surfaces for governance and operations.",
        },
    ),
    (
        r"^apps/avrai_app/lib/(bootstrap|di|background|configs)/|^apps/avrai_app/lib/(app|main|injection_container).*\.dart$",
        {
            "domain": "apps-bootstrap",
            "disposition": "keep_update",
            "phase_refs": "7,10.10.3,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "User-app bootstrap and DI composition are active integration anchors in the apps prong.",
        },
    ),
    (
        r"^apps/avrai_app/lib/(presentation|apps/consumer_app|theme|services)/",
        {
            "domain": "user-app-surface",
            "disposition": "keep_update",
            "phase_refs": "10.1,10.3,10.4,10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "User-facing UI, theme, and app-shell surfaces remain active within the apps prong.",
        },
    ),
    (
        r"^apps/.+/(test|integration_test|integration_test_driver)/",
        {
            "domain": "app-testing-quality",
            "disposition": "keep_update",
            "phase_refs": "10.6,methodology",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "App test roots provide regression safety for app-prong migrations and feature completion.",
        },
    ),
    (
        r"^apps/.+",
        {
            "domain": "app-package-root",
            "disposition": "keep_update",
            "phase_refs": "10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "medium",
            "rationale": "Tracked files under app packages remain part of the active apps-prong ownership surface.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/services/transport/legacy/",
        {
            "domain": "runtime-transport-legacy",
            "disposition": "keep_review",
            "phase_refs": "10.2,10.10.9",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Legacy transport adapters remain mapped while transport behavior converges under runtime OS ownership.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/services/transport/(ble|mesh|compatibility)/",
        {
            "domain": "runtime-transport",
            "disposition": "keep_update",
            "phase_refs": "2.4,2.5,7.4,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Transport implementations belong to runtime OS and are active AI2AI/BLE/mesh execution surfaces.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/services/security/",
        {
            "domain": "runtime-security",
            "disposition": "keep_update",
            "phase_refs": "2.1,2.5,10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime OS security services enforce the active privacy, policy, and bounded-autonomy perimeter.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/controllers/",
        {
            "domain": "runtime-orchestration",
            "disposition": "keep_update",
            "phase_refs": "7,10.9.12,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime controllers own trigger routing, orchestration, and receipt-producing activation flow.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/ai/memory/",
        {
            "domain": "runtime-memory",
            "disposition": "keep_update",
            "phase_refs": "1,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime memory services are the active package surface for episodic, semantic, and procedural memory execution.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/ai/world_model/",
        {
            "domain": "runtime-world-model",
            "disposition": "keep_update",
            "phase_refs": "3,4,5,6,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime OS contains the seeded world-model execution roots for encoding, energy, prediction, and planning.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/(ai/ai2ai_learning|ai2ai|kernel/ai2ai)/",
        {
            "domain": "runtime-ai2ai",
            "disposition": "keep_update",
            "phase_refs": "7.4,8,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime OS owns active ai2ai learning, chat, discovery, locality, and kernel execution surfaces.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/services/business/",
        {
            "domain": "business-runtime",
            "disposition": "keep_update",
            "phase_refs": "9,10.1,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Business-facing runtime services remain active package-owned surfaces for monetization and operations.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/services/prediction/",
        {
            "domain": "prediction-runtime",
            "disposition": "keep_update",
            "phase_refs": "5,6,10.10.9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Prediction runtime services support the active planner and transition-model execution path.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/lib/",
        {
            "domain": "runtime-os-prong",
            "disposition": "keep_update",
            "phase_refs": "1,2,6,7,8,9,10.10",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Remaining runtime OS library files belong to the active runtime-prong package surface.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/test/",
        {
            "domain": "runtime-testing-quality",
            "disposition": "keep_update",
            "phase_refs": "10.6,methodology",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime package tests provide regression safety for policy, transport, and world-model execution changes.",
        },
    ),
    (
        r"^runtime/avrai_runtime_os/",
        {
            "domain": "runtime-package-root",
            "disposition": "keep_update",
            "phase_refs": "10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "medium",
            "rationale": "Tracked runtime OS package files remain active parts of the 3-prong package root.",
        },
    ),
    (
        r"^runtime/avrai_network/native/signal_ffi/",
        {
            "domain": "security-signal-ffi",
            "disposition": "keep_update",
            "phase_refs": "2.4,2.5,11.2",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Signal FFI remains an active native security/network integration surface.",
        },
    ),
    (
        r"^runtime/avrai_network/native/.+/(target|tmp_ios_build)/",
        {
            "domain": "runtime-network-native-artifacts",
            "disposition": "keep_review",
            "phase_refs": "10.2,methodology",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Tracked native build artifacts remain mapped for determinism but should stay under review for hygiene follow-up.",
        },
    ),
    (
        r"^runtime/avrai_network/native/",
        {
            "domain": "runtime-network-native",
            "disposition": "keep_update",
            "phase_refs": "2.4,3.7,8,11,10.10",
            "action": "keep+update",
            "confidence": "medium",
            "rationale": "Runtime network native kernels and wrappers remain active package-owned execution surfaces.",
        },
    ),
    (
        r"^runtime/avrai_network/lib/",
        {
            "domain": "runtime-network-prong",
            "disposition": "keep_update",
            "phase_refs": "3.7,8,11,10.10",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime network library code owns backends, clients, interfaces, and network contracts in the current monorepo.",
        },
    ),
    (
        r"^runtime/avrai_network/test/",
        {
            "domain": "runtime-testing-quality",
            "disposition": "keep_update",
            "phase_refs": "10.6,methodology",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Runtime network tests provide regression safety for backends and transport integrations.",
        },
    ),
    (
        r"^runtime/avrai_network/",
        {
            "domain": "runtime-package-root",
            "disposition": "keep_update",
            "phase_refs": "10.10.9,10.10.12",
            "action": "keep+update",
            "confidence": "medium",
            "rationale": "Tracked runtime network package files remain part of the active 3-prong package root.",
        },
    ),
    (
        r"^engine/reality_engine/lib/contracts/",
        {
            "domain": "reality-engine-contracts",
            "disposition": "keep_update",
            "phase_refs": "10.10.11,12.4B",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Reality-engine contracts define shared truth and compression interfaces used by runtime and admin surfaces.",
        },
    ),
    (
        r"^engine/reality_engine/lib/memory/air_gap/",
        {
            "domain": "reality-air-gap",
            "disposition": "keep_update",
            "phase_refs": "2.6,12.4A,12.4B",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Air-gap and compressed-memory logic are active reality-engine responsibilities.",
        },
    ),
    (
        r"^engine/reality_engine/lib/",
        {
            "domain": "reality-engine",
            "disposition": "keep_update",
            "phase_refs": "1,3,4,5,12.4,12.4B",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Reality engine remains the core model-truth package for state, memory, training, trajectory, and serving logic.",
        },
    ),
    (
        r"^engine/avrai_ai/",
        {
            "domain": "ai-engine",
            "disposition": "keep_update",
            "phase_refs": "6,10.10",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "AVRAI AI package is an active engine-prong surface for agent-specific services.",
        },
    ),
    (
        r"^engine/avrai_ml/",
        {
            "domain": "ml-engine",
            "disposition": "keep_update",
            "phase_refs": "4,5,10.10",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "AVRAI ML package remains a declared engine package even where implementation is still sparse.",
        },
    ),
    (
        r"^engine/avrai_knot/",
        {
            "domain": "knot-engine",
            "disposition": "keep_update",
            "phase_refs": "10.10,11.4",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Knot logic remains an active engine-prong package under the 3-prong split.",
        },
    ),
    (
        r"^engine/spots_knot/",
        {
            "domain": "legacy-knot-engine",
            "disposition": "keep_review",
            "phase_refs": "10.10,11.4",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Legacy knot package remains mapped during migration and should stay under explicit review.",
        },
    ),
    (
        r"^engine/avrai_quantum/",
        {
            "domain": "quantum-engine",
            "disposition": "keep_update",
            "phase_refs": "5,8,11.4,10.10",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Quantum package remains an active engine-prong integration surface.",
        },
    ),
    (
        r"^shared/avrai_core/",
        {
            "domain": "shared-core",
            "disposition": "keep_update",
            "phase_refs": "10.10.9,10.10.11,10.10.12,12",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Shared contracts, schemas, and primitives belong in avrai_core under the current package boundary model.",
        },
    ),
    (
        r"^scripts/runtime/",
        {
            "domain": "tooling-runtime",
            "disposition": "keep_review",
            "phase_refs": "10.2,methodology",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Runtime report and control-pack tooling remains active but should stay explicitly reviewed as tooling rather than product code.",
        },
    ),
    (
        r"^scripts/(ci|ml|security|security_validation|smoke|setup|autopilot|perf|deploy|geo|git|supabase)/",
        {
            "domain": "tooling-ops",
            "disposition": "keep_review",
            "phase_refs": "10.2,methodology",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Operational tooling remains mapped for deterministic validation and automation coverage.",
        },
    ),
    (
        r"^scripts/",
        {
            "domain": "tooling-ops",
            "disposition": "keep_review",
            "phase_refs": "10.2,methodology",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Tracked scripts remain part of the operational tooling surface and should stay under explicit review.",
        },
    ),
    (
        r"^tool/",
        {
            "domain": "tooling-dev",
            "disposition": "keep_review",
            "phase_refs": "methodology",
            "action": "keep+review",
            "confidence": "medium",
            "rationale": "Developer helper tools remain tracked and must stay mapped even when they are one-off utilities.",
        },
    ),
    (
        r"^supabase/sql/",
        {
            "domain": "data-platform-sql",
            "disposition": "keep_update",
            "phase_refs": "1.1,2.1,8.1,9.2.6",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Supabase SQL remains an active schema and data-platform authority surface.",
        },
    ),
    (
        r"^supabase/functions/",
        {
            "domain": "supabase-functions",
            "disposition": "keep_update",
            "phase_refs": "1.1,2.1,8.1,9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Supabase functions remain active backend execution surfaces and must stay mapped.",
        },
    ),
    (
        r"^supabase/",
        {
            "domain": "supabase-infra",
            "disposition": "keep_update",
            "phase_refs": "1.1,2.1,8.1,9",
            "action": "keep+update",
            "confidence": "high",
            "rationale": "Supabase migrations and config remain active infrastructure lanes.",
        },
    ),
]

FALLBACK = {
    "domain": "unclassified-monorepo-surface",
    "disposition": "keep_review",
    "phase_refs": "10.2,10.10",
    "action": "keep+review",
    "confidence": "low",
    "rationale": "No explicit monorepo rule matched; keep mapped and review the placement rule when this surface becomes active.",
}

INJECTION_ROOTS = [
    "apps/avrai_app/lib/di/registrars/app_service_registrar.dart",
    "apps/avrai_app/lib/di/registrars/runtime_service_registrar.dart",
    "apps/avrai_app/lib/di/registrars/engine_service_registrar.dart",
    "apps/admin_app/lib/di/registrars/app_service_registrar.dart",
    "apps/admin_app/lib/di/registrars/runtime_service_registrar.dart",
    "apps/admin_app/lib/di/registrars/engine_service_registrar.dart",
]


def classify(path: str) -> dict[str, str]:
    logical_path = normalize_path(path)
    for pattern, data in RULES:
        if re.search(pattern, logical_path):
            return data
    return FALLBACK


def _read_text(path: str) -> str:
    full = REPO_ROOT / path
    if not full.exists() or full.suffix != ".dart":
        return ""
    try:
        return full.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def _uses_getit(path: str) -> bool:
    content = _read_text(path)
    if not content:
        return False
    patterns = (
        "GetIt.instance",
        "GetIt.I<",
        "GetIt.I.",
        "import 'package:get_it/get_it.dart'",
        'import "package:get_it/get_it.dart"',
    )
    return any(pattern in content for pattern in patterns)


def _is_di_provider(path: str) -> bool:
    logical_path = normalize_path(path)
    return bool(
        re.search(r"^apps/.+/lib/(di/registrars|bootstrap)/", logical_path)
        or re.search(r"^apps/.+/lib/injection_container.*\.dart$", logical_path)
    )


def _injection_contract(path: str, meta: dict[str, str]) -> dict[str, object]:
    logical_path = normalize_path(path)
    spot = derive_spot(path)
    provider = _is_di_provider(path)
    consumer = logical_path.endswith(".dart") and logical_path.startswith(("apps/", "runtime/", "engine/", "shared/"))
    if _uses_getit(path):
        consumer = True

    if provider:
        mode = "provider"
        provides = [f"di:file:{logical_path}", f"di:spot:{spot}"]
        consumes: list[str] = []
    elif consumer:
        mode = "consumer"
        provides = []
        consumes = [f"di:spot:{spot}", "di:root:apps-prong"]
    else:
        mode = "none"
        provides = []
        consumes = []

    return {
        "mode": mode,
        "roots": INJECTION_ROOTS,
        "provides": provides,
        "consumes": consumes,
        "required_validation": (
            [
                "melos analyze",
                "melos check:architecture",
                "Architecture Placement Guard / architecture-placement",
            ]
            if mode != "none"
            else []
        ),
        "notes": f"deterministic injection contract for {meta['domain']}",
    }


def strict_dependency_graph(path: str, meta: dict[str, str]) -> str:
    graph = {
        "graph_version": "v1",
        "node_id": f"file:{path}",
        "change_class": meta["disposition"],
        "change_line": "steady",
        "lane": f"steady:{meta['domain']}",
        "order": 0,
        "depends_on": [],
        "spot": f"spot:{derive_spot(path)}",
        "phase_refs": [item.strip() for item in meta["phase_refs"].split(",") if item.strip()],
        "required_checks": [
            "Execution Board Guard / execution-board-check",
            "Architecture Placement Guard / architecture-placement",
            "PRD Traceability Guard / traceability",
        ],
        "injections": _injection_contract(path, meta),
        "notes": "strict dependency graph for deterministic monorepo placement validation",
    }
    return json.dumps(graph, sort_keys=True, separators=(",", ":"))


def mapping_bucket(path: str) -> str:
    logical_path = normalize_path(path)
    parts = logical_path.split("/")

    if logical_path.startswith("apps/"):
        if len(parts) >= 4 and parts[2] in {"lib", "configs"}:
            return "/".join(parts[:4])
        if len(parts) >= 3:
            return "/".join(parts[:3])
        return logical_path

    if logical_path.startswith(("runtime/", "engine/", "shared/")):
        if len(parts) >= 4 and parts[2] in {"lib", "native", "test"}:
            return "/".join(parts[:4])
        if len(parts) >= 3:
            return "/".join(parts[:3])
        return logical_path

    if logical_path.startswith(("scripts/", "supabase/")):
        return "/".join(parts[:2]) if len(parts) >= 2 else logical_path

    if logical_path.startswith("tool/"):
        return "tool/_root"

    return logical_path


def build_rows() -> list[dict[str, str]]:
    rows = []
    for path in sorted(tracked_files(PLACEMENT_TRACK_PREFIXES)):
        meta = classify(path)
        rows.append(
            {
                "file": path,
                "bucket": mapping_bucket(path),
                "domain": meta["domain"],
                "disposition": meta["disposition"],
                "phase_refs": meta["phase_refs"],
                "action": meta["action"],
                "confidence": meta["confidence"],
                "rationale": meta["rationale"],
                "dependency_graph": strict_dependency_graph(path, meta),
            }
        )
    return rows


def write_csv(rows: list[dict[str, str]], csv_path: Path) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=FIELDNAMES,
        )
        writer.writeheader()
        writer.writerows(rows)


def write_summary_markdown(rows: list[dict[str, str]]) -> None:
    disposition_counts = Counter(row["disposition"] for row in rows)
    domain_counts = Counter(row["domain"] for row in rows)
    bucket_counts = Counter(row["bucket"] for row in rows)
    review_examples = [row["file"] for row in rows if row["disposition"] == "keep_review"][:40]

    with MD_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Codebase -> Master Plan File Mapping (2026-02-15)\n\n")
        handle.write("**Purpose:** File-level architecture mapping for the current 3-prong monorepo.\n")
        handle.write(
            "**Coverage:** All tracked files under `apps/`, `runtime/`, `engine/`, `shared/`, "
            "`work/scripts/`, `work/tools/`, and `work/supabase/`.\n"
        )
        handle.write(f"**Total mapped files:** {len(rows)}\n")
        handle.write(
            "**Full inventory export:** generate on demand with "
            f"`{LOCAL_EXPORT_COMMAND}`.\n"
        )
        handle.write(
            "**Method:** Deterministic path-to-domain rules with per-file dependency-graph payloads aligned to current package ownership.\n\n"
        )

        handle.write("## Disposition Summary\n\n")
        handle.write("| Disposition | File Count |\n|---|---:|\n")
        for disposition, count in sorted(disposition_counts.items(), key=lambda item: (-item[1], item[0])):
            handle.write(f"| {disposition} | {count} |\n")

        handle.write("\n## Domain Summary\n\n")
        handle.write("| Domain | File Count |\n|---|---:|\n")
        for domain, count in sorted(domain_counts.items(), key=lambda item: (-item[1], item[0])):
            handle.write(f"| {domain} | {count} |\n")

        handle.write("\n## Highest-Volume Buckets (Top 40)\n\n")
        handle.write("| Bucket | File Count |\n|---|---:|\n")
        for bucket, count in bucket_counts.most_common(40):
            handle.write(f"| {bucket} | {count} |\n")

        handle.write("\n## Explicit Review Buckets (Sample)\n\n")
        if review_examples:
            for path in review_examples:
                handle.write(f"- `{path}`\n")
            remaining = max(0, sum(row["disposition"] == "keep_review" for row in rows) - len(review_examples))
            if remaining:
                handle.write(
                    f"- ... plus {remaining} more "
                    f"(generate a local CSV export with `{LOCAL_EXPORT_COMMAND}`).\n"
                )
        else:
            handle.write("- None.\n")

        handle.write("\n## Operational Use\n\n")
        handle.write(
            "1. `validate_architecture_placement.py` generates the full per-file mapping in memory for build enforcement.\n"
        )
        handle.write("2. `keep_review` rows are still valid placements; they indicate tooling or legacy surfaces that remain tracked and intentionally visible.\n")
        handle.write(
            "3. Regenerate this summary alongside the spot registry before merging package-placement changes; only emit a CSV locally when full inventory inspection is needed.\n"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate the codebase-to-master-plan mapping summary and optional local CSV export.",
    )
    parser.add_argument(
        "--emit-csv",
        dest="emit_csv",
        help="Optional local path for a full CSV export. Omit to avoid creating a large artifact.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    rows = build_rows()
    if args.emit_csv:
        write_csv(rows, Path(args.emit_csv).expanduser())
    write_summary_markdown(rows)


if __name__ == "__main__":
    main()
