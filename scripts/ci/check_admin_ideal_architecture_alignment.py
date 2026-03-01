#!/usr/bin/env python3
"""Guardrail: admin dashboard/security work must stay aligned to ideal architecture."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

REQUIRED_FILES = [
    ROOT / "docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md",
    ROOT / "docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_ALIGNMENT_AUDIT_2026-02-28.md",
    ROOT / "docs/plans/architecture/ADMIN_PRIVATE_SERVER_SECURITY_IMPLEMENTATION_CHECKLIST_2026-02-28.md",
    ROOT / "docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md",
    ROOT / "configs/runtime/admin_private_server_security_foundation_controls.json",
    ROOT / "configs/runtime/admin_private_server_security_zero_trust_access_controls.json",
    ROOT / "configs/runtime/admin_private_server_security_private_mesh_controls.json",
    ROOT / "configs/runtime/admin_private_server_security_mtls_policy_controls.json",
    ROOT / "configs/runtime/admin_private_server_security_privacy_redaction_controls.json",
    ROOT / "configs/runtime/admin_private_server_security_audit_incident_controls.json",
    ROOT / "scripts/ci/check_admin_desktop_only.py",
]

FORBIDDEN_ADMIN_PLATFORM_DIRS = [
    ROOT / "apps/admin_app/web",
    ROOT / "apps/admin_app/android",
    ROOT / "apps/admin_app/ios",
]

REQUIRED_BOARD_EVIDENCE_TOKENS = [
    "docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md",
    "docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_ALIGNMENT_AUDIT_2026-02-28.md",
    "docs/plans/architecture/ADMIN_PRIVATE_SERVER_SECURITY_IMPLEMENTATION_CHECKLIST_2026-02-28.md",
    "docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md",
    "configs/runtime/admin_private_server_security_foundation_controls.json",
    "configs/runtime/admin_private_server_security_zero_trust_access_controls.json",
    "configs/runtime/admin_private_server_security_private_mesh_controls.json",
    "configs/runtime/admin_private_server_security_mtls_policy_controls.json",
    "configs/runtime/admin_private_server_security_privacy_redaction_controls.json",
    "configs/runtime/admin_private_server_security_audit_incident_controls.json",
]


def _fail(message: str) -> int:
    print("[admin-ideal-architecture-alignment] FAILED")
    print(message)
    return 1


def _check_required_files() -> list[str]:
    missing: list[str] = []
    for path in REQUIRED_FILES:
        if not path.exists():
            missing.append(str(path.relative_to(ROOT)))
    return missing


def _check_forbidden_platform_dirs() -> list[str]:
    present: list[str] = []
    for path in FORBIDDEN_ADMIN_PLATFORM_DIRS:
        if path.exists():
            present.append(str(path.relative_to(ROOT)))
    return present


def _check_bootstrap_desktop_guard() -> list[str]:
    issues: list[str] = []
    bootstrap = ROOT / "lib/apps/admin_app/bootstrap/admin_bootstrap.dart"
    if not bootstrap.exists():
        return [str(bootstrap.relative_to(ROOT)) + " missing"]
    text = bootstrap.read_text(encoding="utf-8")
    required_fragments = [
        "_ensureDesktopOnlyTarget()",
        "kIsWeb",
        "TargetPlatform.macOS",
        "TargetPlatform.windows",
        "TargetPlatform.linux",
    ]
    for frag in required_fragments:
        if frag not in text:
            issues.append(f"missing bootstrap guard fragment: {frag}")
    return issues


def _check_execution_board_alignment() -> list[str]:
    issues: list[str] = []
    board = ROOT / "docs/EXECUTION_BOARD.csv"
    if not board.exists():
        return ["docs/EXECUTION_BOARD.csv missing"]
    with board.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    for milestone in ("M27-P10-3", "M28-P10-3"):
        row = next((r for r in rows if r.get("id") == milestone), None)
        if row is None:
            issues.append(f"{milestone} missing in docs/EXECUTION_BOARD.csv")
            continue
        evidence = row.get("evidence", "")
        for token in REQUIRED_BOARD_EVIDENCE_TOKENS:
            if token not in evidence:
                issues.append(f"{milestone} evidence missing token: {token}")
    return issues


def main() -> int:
    issues: list[str] = []

    missing_files = _check_required_files()
    if missing_files:
        issues.append("Missing required files:")
        issues.extend([f"  - {x}" for x in missing_files])

    forbidden_dirs = _check_forbidden_platform_dirs()
    if forbidden_dirs:
        issues.append("Forbidden admin platform directories present:")
        issues.extend([f"  - {x}" for x in forbidden_dirs])

    issues.extend(_check_bootstrap_desktop_guard())
    issues.extend(_check_execution_board_alignment())

    if issues:
        return _fail("\n".join(issues))

    print("[admin-ideal-architecture-alignment] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
