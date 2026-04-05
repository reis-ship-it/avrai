#!/usr/bin/env python3
from __future__ import annotations

import csv
from collections import defaultdict

from architecture_placement_common import (
    LEGACY_BOARD_ALIASES,
    REGISTRY_TRACK_PREFIXES,
    WORK_ROOT,
    derive_spot,
    tracked_files,
)

REGISTRY_CSV = WORK_ROOT / "docs" / "plans" / "architecture" / "ARCHITECTURE_SPOTS_REGISTRY.csv"


def derive_metadata(spot: str) -> tuple[str, str, str]:
    if spot in LEGACY_BOARD_ALIASES:
        return LEGACY_BOARD_ALIASES[spot]

    if spot == "apps/avrai_app":
        return ("apps-prong", "10.10.9,10.10.11,10.10.12", "current primary AVRAI app package root")
    if spot == "apps/admin_app":
        return ("admin-app-prong", "10.9.22,10.9.23,10.9.24,10.9.25,10.10.12", "current admin app package root")
    if spot.startswith("apps/") and "/configs/runtime" in spot:
        return ("apps-prong", "10.10.3,10.10.9,10.10.12", "runtime control packs and app-prong configuration surfaces")
    if spot.startswith("apps/") and "/configs/" in spot:
        return ("apps-prong", "10.10.9,10.10.12", "app-prong configuration surface")
    if spot.startswith("apps/"):
        return ("apps-prong", "10.10.9,10.10.11,10.10.12", "current app-prong package root")
    if spot == "runtime/avrai_runtime_os":
        return ("runtime-os-prong", "1,2,6,7,8,9,10.10", "current runtime OS package root")
    if spot == "runtime/avrai_network":
        return ("runtime-network-prong", "3.7,8,11,10.10", "current network/backends package root")
    if spot == "runtime/avrai_data":
        return ("data-runtime", "1.1,1.2,9,10.10", "current data-runtime package root")
    if spot == "engine/reality_engine":
        return ("reality-engine", "1,3,4,5,12.4,12.4B", "current reality-engine package root")
    if spot == "engine/avrai_ai":
        return ("ai-engine", "6,10.10", "current AI-engine package root")
    if spot == "engine/spots_knot":
        return ("legacy-knot-engine", "10.10,11.4", "legacy knot engine package still present in the repository during migration")
    if spot == "engine/avrai_ml":
        return ("ml-engine", "4,5,10.10", "current ML-engine package root")
    if spot == "engine/avrai_knot":
        return ("knot-engine", "10.10,11.4", "current knot-engine package root")
    if spot == "engine/avrai_quantum":
        return ("quantum-engine", "10.10,11.4", "current quantum-engine package root")
    if spot == "shared/avrai_core":
        return ("shared-core", "10.10.9,10.10.11,10.10.12,12", "shared contracts, schemas, and primitive types package root")
    if spot.startswith("configs/"):
        return ("runtime-configs", "10.2,10.9,methodology", "configuration and control-pack root")
    if spot.startswith("design/"):
        return ("design-system", "10.3,methodology", "design contracts and token artifacts")
    if spot == "docs/plans/architecture":
        return ("architecture-docs", "10.10,12,methodology", "architecture authority and execution companion docs")
    if spot == "docs":
        return ("docs", "methodology", "documentation root spot")
    if spot.startswith("examples/"):
        return ("examples", "methodology", "reference and example implementation spot")
    if spot.startswith("infrastructure/"):
        return ("infra-ops", "10.9,methodology", "supporting infrastructure and control-plane operations spot")
    if spot.startswith("integration_test/"):
        return ("integration-test", "10.2,methodology", "integration test harness spot")
    if spot.startswith("release_artifacts/"):
        return ("release-artifacts", "methodology", "generated or checked-in release artifact spot")
    if spot.startswith("scripts/"):
        return ("tooling-ops", "10.2,methodology", "tooling and validation scripts spot")
    if spot.startswith("supabase/sql"):
        return ("data-platform-sql", "1.1,2.1,8.1,9.2.6", "Supabase SQL schema and data-platform spot")
    if spot.startswith("supabase/"):
        return ("supabase-infra", "1.1,2.1,8.1,9", "Supabase infrastructure and migration spot")
    if spot.startswith("tool/"):
        return ("tooling-dev", "methodology", "developer tooling spot")
    return ("unknown", "", "architecture spot for file placement")


def main() -> None:
    spot_files: defaultdict[str, list[str]] = defaultdict(list)

    for path in tracked_files(REGISTRY_TRACK_PREFIXES):
        spot_files[derive_spot(path)].append(path)

    rows = []
    for spot in sorted(spot_files):
        domain, phase_refs, notes = derive_metadata(spot)
        rows.append(
            {
                "spot_key": spot,
                "file_count": str(len(spot_files[spot])),
                "primary_domain": domain,
                "phase_refs": phase_refs,
                "status": "active",
                "notes": notes,
            }
        )

    present = {row["spot_key"] for row in rows}
    for spot, (domain, phase_refs, notes) in sorted(LEGACY_BOARD_ALIASES.items()):
        if spot in present:
            continue
        rows.append(
            {
                "spot_key": spot,
                "file_count": "0",
                "primary_domain": domain,
                "phase_refs": phase_refs,
                "status": "active",
                "notes": notes,
            }
        )

    with REGISTRY_CSV.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["spot_key", "file_count", "primary_domain", "phase_refs", "status", "notes"],
        )
        writer.writeheader()
        writer.writerows(sorted(rows, key=lambda row: row["spot_key"]))


if __name__ == "__main__":
    main()
