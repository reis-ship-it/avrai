#!/usr/bin/env python3
import csv
import json
import re
import subprocess
from pathlib import Path
from collections import Counter, defaultdict

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "plans" / "architecture" / "generated"
OUT_DIR.mkdir(parents=True, exist_ok=True)
CSV_PATH = OUT_DIR / "codebase_master_plan_mapping_2026-02-15.csv"
MD_PATH = ROOT / "docs" / "plans" / "architecture" / "CODEBASE_MASTER_PLAN_MAPPING_2026-02-15.md"

TRACK_PREFIXES = (
    "lib/", "packages/", "native/", "scripts/", "supabase/", "test/", "tool/",
    "assets/", "android/", "ios/", "macos/", "linux/", "windows/", "web/"
)

Rule = tuple[str, dict]

rules: list[Rule] = [
    (r"^lib/core/services/places/.*_new\.dart$", {
        "domain": "places-location-intelligence",
        "disposition": "keep_update",
        "phase_refs": "1.1D,10.7.2g",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "New Places API implementation is actively referenced by DI and sync services."
    }),
    (r"(^|/)\\.DS_Store$", {
        "domain": "repo-hygiene",
        "disposition": "delete_candidate",
        "phase_refs": "10.7.2m,REPO_HYGIENE",
        "action": "delete",
        "confidence": "high",
        "rationale": "OS metadata artifact; not source code."
    }),
    (r"^lib/core/crypto/signal/", {
        "domain": "security-signal",
        "disposition": "keep_update",
        "phase_refs": "2.4,2.5,7.7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Core Signal Protocol and cryptographic transport required by architecture."
    }),
    (r"^native/signal_ffi/", {
        "domain": "security-signal-ffi",
        "disposition": "keep_update",
        "phase_refs": "2.4,2.5,10.2",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Native signal integration and wrappers required for encrypted AI2AI messaging."
    }),
    (r"^lib/core/services/security/", {
        "domain": "security-services",
        "disposition": "keep_update",
        "phase_refs": "2.1,2.2,2.5",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Privacy/compliance/security services are hard architecture invariants."
    }),
    (r"^lib/core/services/", {
        "domain": "core-services-general",
        "disposition": "keep_update",
        "phase_refs": "1,2,3,4,5,6,7,8,9,10",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Core service layer is actively used across phases; refine at subsection execution time."
    }),
    (r"^supabase/sql/", {
        "domain": "data-platform-sql",
        "disposition": "keep_update",
        "phase_refs": "1.1,2.1,8.1,9.2.6",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Schema and migration layer for episodic/outcome/federated/business pipelines."
    }),
    (r"^lib/core/ai/", {
        "domain": "world-model-ai-core",
        "disposition": "keep_update",
        "phase_refs": "1,3,4,5,6,7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Core world-model/agent orchestration surfaces."
    }),
    (r"^lib/core/ai2ai/", {
        "domain": "ai2ai-network",
        "disposition": "keep_update",
        "phase_refs": "3.7,8,7.4",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "AI2AI networking and federated communication are core architecture layers."
    }),
    (r"^lib/core/cloud/", {
        "domain": "cloud-integration",
        "disposition": "keep_update",
        "phase_refs": "7.7,8.1,9.2.6",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Cloud integration required for sync, federated aggregation, and business data lanes."
    }),
    (r"^lib/core/controllers/", {
        "domain": "workflow-controllers",
        "disposition": "keep_update",
        "phase_refs": "1.2,10.1,7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Controllers orchestrate user/business workflows and outcome capture."
    }),
    (r"^lib/core/config/|^lib/core/constants/|^lib/core/theme/", {
        "domain": "config-and-theme",
        "disposition": "keep_update",
        "phase_refs": "7.5,10.3,10.4",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Configuration and UI system resources remain active across current phases."
    }),
    (r"^lib/core/advanced/", {
        "domain": "legacy-advanced-services",
        "disposition": "refactor_planned",
        "phase_refs": "4.2,10.2",
        "action": "refactor",
        "confidence": "medium",
        "rationale": "Advanced scoring logic likely overlaps with formula replacement roadmap."
    }),
    (r"^lib/core/models/", {
        "domain": "core-models",
        "disposition": "keep_update",
        "phase_refs": "3.1,3.4,10.7.3",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Model layer is a direct dependency for state/action encoders and entity expansion."
    }),
    (r"^lib/core/crypto/", {
        "domain": "crypto-core",
        "disposition": "keep_update",
        "phase_refs": "2.4,2.5",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Cryptographic primitives and session handling are required for security architecture."
    }),
    (r"^lib/core/monitoring/", {
        "domain": "monitoring-observability",
        "disposition": "keep_update",
        "phase_refs": "7.7,7.7A,8.8",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Monitoring and operational telemetry are required for gated self-improvement."
    }),
    (r"^lib/core/legal/", {
        "domain": "legal-domain",
        "disposition": "keep_update",
        "phase_refs": "2.1,10.1",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Legal policy artifacts support compliance and user-facing requirements."
    }),
    (r"^lib/core/p2p/", {
        "domain": "legacy-p2p",
        "disposition": "refactor_planned",
        "phase_refs": "methodology,10.2",
        "action": "refactor+review",
        "confidence": "low",
        "rationale": "Architecture principle is ai2ai-not-p2p; legacy p2p modules require targeted review."
    }),
    (r"^lib/core/deployment/|^lib/core/sync/", {
        "domain": "deployment-sync",
        "disposition": "keep_update",
        "phase_refs": "7.7,7.8",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Deployment and sync paths underpin model lifecycle and multi-device reconciliation."
    }),
    (r"^lib/core/utils/", {
        "domain": "core-utils",
        "disposition": "keep_review",
        "phase_refs": "10.2,10.7",
        "action": "keep+review",
        "confidence": "medium",
        "rationale": "Utility modules should be retained but normalized during cleanup/reorg."
    }),
    (r"^lib/core/ml/", {
        "domain": "ml-legacy-and-transition",
        "disposition": "refactor_planned",
        "phase_refs": "10.8.1,4,5",
        "action": "refactor",
        "confidence": "high",
        "rationale": "Master Plan explicitly schedules ml->ai consolidation and stub cleanup."
    }),
    (r"^lib/core/services/places/", {
        "domain": "places-location-intelligence",
        "disposition": "keep_update",
        "phase_refs": "1.7,3.5,1.1D",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Location intelligence and organic discovery are active plan components."
    }),
    (r"^lib/core/services/analytics/", {
        "domain": "analytics-outcome-observability",
        "disposition": "keep_update",
        "phase_refs": "1.2,1.4,7.7A",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Outcome tracking and monitoring are required for learning loops."
    }),
    (r"^lib/core/services/infrastructure/", {
        "domain": "infra-orchestration",
        "disposition": "keep_update",
        "phase_refs": "7.4,7.5,7.7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Feature flags, model/version control, and orchestrators are plan-critical."
    }),
    (r"^lib/core/services/quantum/", {
        "domain": "quantum-service-integration",
        "disposition": "keep_update",
        "phase_refs": "5,8,11.4",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Quantum services are active integration surfaces and future-ready architecture."
    }),
    (r"^packages/avrai_quantum/", {
        "domain": "quantum-package",
        "disposition": "keep_update",
        "phase_refs": "10.8.2,11.4",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Package-level quantum implementation aligned with deferred consolidation decisions."
    }),
    (r"^lib/core/services/recommendations/", {
        "domain": "recommendation-transition",
        "disposition": "refactor_planned",
        "phase_refs": "4.2,6.1",
        "action": "refactor",
        "confidence": "high",
        "rationale": "Formula-based recommendation services are targeted for energy/MPC replacement."
    }),
    (r"^lib/core/services/expertise/", {
        "domain": "expertise-domain",
        "disposition": "keep_update",
        "phase_refs": "4.3,9",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Expert/business pathways are preserved and integrated with world model scoring."
    }),
    (r"^lib/core/services/onboarding/", {
        "domain": "cold-start-onboarding",
        "disposition": "keep_update",
        "phase_refs": "1.5,10.1",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Cold-start and onboarding quality are explicitly tracked in phase plan."
    }),
    (r"^lib/core/services/lists/", {
        "domain": "lists-entity",
        "disposition": "keep_update",
        "phase_refs": "1.2,3.4,10.1.6",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "List-as-entity evolution and outcome capture are core roadmap items."
    }),
    (r"^lib/domain/usecases/search/|^lib/presentation/widgets/search/|^lib/presentation/widgets/common/universal_ai_search\.dart$", {
        "domain": "search-retrieval",
        "disposition": "keep_update",
        "phase_refs": "1.1D,7.7A,10.1.6A",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Search stack aligns to hybrid retrieval and gated self-improving search."
    }),
    (r"^lib/presentation/", {
        "domain": "presentation",
        "disposition": "keep_update",
        "phase_refs": "10.1,10.3,10.4",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "UI layer retained; feature completion, localization, and accessibility planned."
    }),
    (r"^test/", {
        "domain": "testing-quality",
        "disposition": "keep_update",
        "phase_refs": "10.6,methodology",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Regression and coverage gates required for refactor and rollout safety."
    }),
    (r"^lib/data/", {
        "domain": "data-layer",
        "disposition": "keep_update",
        "phase_refs": "1.1,1.2,2.1,10.7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Repositories/datasources/storage are required for memory and outcomes."
    }),
    (r"^lib/domain/", {
        "domain": "domain-layer",
        "disposition": "keep_review",
        "phase_refs": "10.8.3",
        "action": "keep+review",
        "confidence": "high",
        "rationale": "Master Plan defers domain-layer consolidation decision until later phase."
    }),
    (r"^lib/injection_container.*\.dart$|^lib/app\.dart$|^lib/main.*\.dart$", {
        "domain": "app-composition-root",
        "disposition": "keep_update",
        "phase_refs": "7,10.7",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Composition roots and app entrypoint are required integration anchors."
    }),
    (r"^lib/supabase_.*\.dart$", {
        "domain": "supabase-integration-entrypoints",
        "disposition": "keep_update",
        "phase_refs": "1.1,2.1,8.1,9",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Supabase integration entrypoints are part of active backend architecture."
    }),
    (r"^scripts/", {
        "domain": "tooling-ops",
        "disposition": "keep_review",
        "phase_refs": "10.2,methodology",
        "action": "keep+review",
        "confidence": "medium",
        "rationale": "Scripts aid migration/validation; review stale one-offs before long-term retention."
    }),
    (r"^tool/", {
        "domain": "tooling-dev",
        "disposition": "keep_review",
        "phase_refs": "methodology",
        "action": "keep+review",
        "confidence": "medium",
        "rationale": "Developer tooling retained unless superseded by unified pipelines."
    }),
    (r"^assets/", {
        "domain": "assets",
        "disposition": "keep_review",
        "phase_refs": "10.1,10.7",
        "action": "keep+review",
        "confidence": "low",
        "rationale": "Asset retention depends on active feature surfaces and bundle budget."
    }),
    (r"^(android|ios|macos|linux|windows|web)/", {
        "domain": "platform-runtime",
        "disposition": "keep_update",
        "phase_refs": "7.5,11.2",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Platform targets remain active with tiered capability and expansion plans."
    }),
    (r"^packages/", {
        "domain": "package-modules",
        "disposition": "keep_update",
        "phase_refs": "packaging,10.7,10.8",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Package modules are part of modular architecture and must stay aligned to boundaries."
    }),
    (r"^native/", {
        "domain": "native-modules",
        "disposition": "keep_update",
        "phase_refs": "2.4,11.2",
        "action": "keep+update",
        "confidence": "medium",
        "rationale": "Native components support platform/security/performance integrations."
    }),
    (r"^supabase/", {
        "domain": "supabase-infra",
        "disposition": "keep_update",
        "phase_refs": "1.1,2.1,8.1,9",
        "action": "keep+update",
        "confidence": "high",
        "rationale": "Backend configuration and SQL are part of active roadmap execution."
    }),
]

fallback = {
    "domain": "unclassified",
    "disposition": "review_required",
    "phase_refs": "10.2",
    "action": "review",
    "confidence": "low",
    "rationale": "No deterministic mapping rule matched; needs manual architecture review."
}


def classify(path: str) -> dict:
    for pattern, data in rules:
        if re.search(pattern, path):
            return data
    return fallback


def _read_text(path: str) -> str:
    full = ROOT / path
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
    return any(p in content for p in patterns)


def _is_di_provider(path: str) -> bool:
    return path.startswith("lib/injection_container") and path.endswith(".dart")


def _injection_contract(path: str, meta: dict) -> dict:
    spot = derive_spot(path)
    provider = _is_di_provider(path)
    consumer = _uses_getit(path) or (
        path.startswith(("lib/core/services/", "lib/core/ai/", "lib/presentation/"))
        and path.endswith(".dart")
    )
    if meta.get("disposition") == "refactor_planned" and path.startswith("lib/") and path.endswith(".dart"):
        consumer = True

    if provider:
        mode = "provider"
        provides = [f"di:provider:{path}", f"di:spot:{spot}"]
        consumes = []
    elif consumer:
        mode = "consumer"
        provides = []
        consumes = [f"di:spot:{spot}", "di:bootstrap:lib/injection_container.dart"]
    else:
        mode = "none"
        provides = []
        consumes = []

    return {
        "mode": mode,
        "roots": [
            "lib/injection_container.dart",
            "lib/injection_container_core.dart",
            "lib/injection_container_ai.dart",
            "lib/injection_container_device_sync.dart",
        ],
        "provides": provides,
        "consumes": consumes,
        "required_validation": [
            "flutter analyze",
            "Architecture Placement Guard / architecture-placement",
        ] if mode != "none" else [],
        "notes": f"deterministic injection contract for {meta['domain']}",
    }


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


REFACTOR_DEPENDENCY_POLICY = {
    "recommendation-transition": {
        "order": 20,
        "depends_on": [
            "spot:lib/core/ai",
            "spot:lib/core/models",
            "spot:lib/core/services/analytics",
            "spot:test/unit/services",
        ],
    },
    "legacy-advanced-services": {
        "order": 30,
        "depends_on": [
            "spot:lib/core/services/recommendations",
            "spot:lib/core/ai",
            "spot:test/unit/services",
        ],
    },
    "ml-legacy-and-transition": {
        "order": 40,
        "depends_on": [
            "spot:lib/core/ai",
            "spot:lib/core/models",
            "spot:lib/core/services/recommendations",
            "spot:test/unit/ml",
            "spot:test/integration/ai",
        ],
    },
    "legacy-p2p": {
        "order": 50,
        "depends_on": [
            "spot:lib/core/ai2ai",
            "spot:lib/core/crypto",
            "spot:lib/core/services/security",
            "spot:test/unit/ai2ai",
        ],
    },
}


def strict_dependency_graph(path: str, meta: dict) -> str:
    domain = meta["domain"]
    disposition = meta["disposition"]
    phase_refs = [ref.strip() for ref in meta["phase_refs"].split(",") if ref.strip()]
    is_refactor = disposition == "refactor_planned" or "refactor" in meta["action"]
    policy = REFACTOR_DEPENDENCY_POLICY.get(domain, None)

    if is_refactor:
        if policy:
            order = policy["order"]
            depends_on = policy["depends_on"]
        else:
            order = 60
            depends_on = ["spot:test/_root"]
        lane = f"refactor:{domain}"
    else:
        order = 0
        depends_on = []
        lane = f"steady:{domain}"

    graph = {
        "graph_version": "v1",
        "node_id": f"file:{path}",
        "change_class": disposition,
        "change_line": "refactor" if is_refactor else "steady",
        "lane": lane,
        "order": order,
        "depends_on": depends_on,
        "spot": f"spot:{derive_spot(path)}",
        "phase_refs": phase_refs,
        "required_checks": [
            "Execution Board Guard / execution-board-check",
            "Architecture Placement Guard / architecture-placement",
            "PRD Traceability Guard / traceability",
        ],
        "injections": _injection_contract(path, meta),
        "notes": "strict dependency graph for deterministic move/refactor sequencing",
    }
    return json.dumps(graph, sort_keys=True, separators=(",", ":"))


def rel_bucket(path: str) -> str:
    parts = path.split("/")
    if len(parts) >= 3 and parts[0] in {"lib", "packages", "test", "scripts", "native", "supabase", "assets"}:
        return "/".join(parts[:3])
    if len(parts) >= 2:
        return "/".join(parts[:2])
    return path


def main() -> None:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    files = [line.strip() for line in out.splitlines() if line.strip()]
    files = [f for f in files if f.startswith(TRACK_PREFIXES)]

    rows = []
    for f in files:
        meta = classify(f)
        rows.append({
            "file": f,
            "bucket": rel_bucket(f),
            "domain": meta["domain"],
            "disposition": meta["disposition"],
            "phase_refs": meta["phase_refs"],
            "action": meta["action"],
            "confidence": meta["confidence"],
            "rationale": meta["rationale"],
            "dependency_graph": strict_dependency_graph(f, meta),
        })

    rows.sort(key=lambda r: r["file"])

    with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "file",
                "bucket",
                "domain",
                "disposition",
                "phase_refs",
                "action",
                "confidence",
                "rationale",
                "dependency_graph",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    disp_counts = Counter(r["disposition"] for r in rows)
    domain_counts = Counter(r["domain"] for r in rows)
    bucket_counts = Counter(r["bucket"] for r in rows)

    delete_examples = [r["file"] for r in rows if r["disposition"] == "delete_candidate"][:25]
    unclassified_examples = [r["file"] for r in rows if r["disposition"] == "review_required"][:40]

    with MD_PATH.open("w", encoding="utf-8") as f:
        f.write("# Codebase -> Master Plan File Mapping (2026-02-15)\n\n")
        f.write("**Purpose:** File-level architecture mapping for keep/update/refactor/delete decisions aligned to `docs/MASTER_PLAN.md`.\n")
        f.write("**Coverage:** All tracked non-doc files under runtime/source/tooling roots (`lib/`, `packages/`, `native/`, `scripts/`, `supabase/`, `test/`, `tool/`, `assets/`, platform dirs).\n")
        f.write(f"**Total mapped files:** {len(rows)}\n")
        f.write(f"**Generated artifact:** `{CSV_PATH.relative_to(ROOT)}`\n")
        f.write("**Method:** Deterministic path-to-phase rules with explicit confidence values and strict per-file dependency-graph payloads (`dependency_graph`).\n\n")

        f.write("## Disposition Summary\n\n")
        f.write("| Disposition | File Count |\n|---|---:|\n")
        for k, v in sorted(disp_counts.items(), key=lambda kv: (-kv[1], kv[0])):
            f.write(f"| {k} | {v} |\n")

        f.write("\n## Domain Summary\n\n")
        f.write("| Domain | File Count |\n|---|---:|\n")
        for k, v in sorted(domain_counts.items(), key=lambda kv: (-kv[1], kv[0])):
            f.write(f"| {k} | {v} |\n")

        f.write("\n## Highest-Volume Buckets (Top 40)\n\n")
        f.write("| Bucket | File Count |\n|---|---:|\n")
        for k, v in bucket_counts.most_common(40):
            f.write(f"| {k} | {v} |\n")

        f.write("\n## Delete Candidates\n\n")
        if delete_examples:
            for p in delete_examples:
                f.write(f"- `{p}`\n")
        else:
            f.write("- None identified by deterministic rules.\n")

        f.write("\n## Manual Review Required (Sample)\n\n")
        if unclassified_examples:
            for p in unclassified_examples:
                f.write(f"- `{p}`\n")
            remaining = max(0, len([r for r in rows if r["disposition"] == "review_required"]) - len(unclassified_examples))
            if remaining:
                f.write(f"- ... plus {remaining} more (see CSV).\n")
        else:
            f.write("- None.\n")

        f.write("\n## Operational Use\n\n")
        f.write("1. Use the CSV as the execution source when scheduling keep/update/refactor/delete actions.\n")
        f.write("2. Any `delete_candidate` or `review_required` entry must be validated against runtime references (`rg`, DI registrations, imports) before deletion.\n")
        f.write("3. Refactor execution should follow phased dependencies in `docs/MASTER_PLAN.md` (notably 10.2, 10.7, 10.8).\n")


if __name__ == "__main__":
    main()
