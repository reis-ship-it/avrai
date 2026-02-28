#!/usr/bin/env python3
"""Validate URK kernel registry completeness and artifact existence."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REGISTRY_PATH = Path("configs/runtime/kernel_registry.json")
ALLOWED_PRONGS = {"model_core", "runtime_core", "governance_core", "cross_prong"}
ALLOWED_RUNTIMES = {
    "user_runtime",
    "event_ops_runtime",
    "business_ops_runtime",
    "expert_services_runtime",
    "shared",
}
ALLOWED_PRIVACY = {"local_sovereign", "private_mesh", "federated_cloud", "multi_mode"}
ALLOWED_IMPACT = {"L1", "L2", "L3", "L4"}
ALLOWED_STATE = {"draft", "shadow", "enforced", "replicated"}
ALLOWED_STATUS = {"backlog", "ready", "in_progress", "done"}
REQUIRED_ARTIFACT_KEYS = {
    "controls",
    "contract",
    "test",
    "report_generator",
    "report_json",
    "report_md",
    "baseline",
}


def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load_registry() -> dict:
    if not REGISTRY_PATH.exists():
        fail(f"missing registry: {REGISTRY_PATH}")
    try:
        data = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover
        fail(f"invalid registry JSON: {exc}")
    if not isinstance(data, dict):
        fail("registry root must be object")
    return data


def check_registry(data: dict) -> tuple[int, int]:
    if data.get("version") != "v1":
        fail("registry version must be v1")

    kernels = data.get("kernels")
    if not isinstance(kernels, list) or not kernels:
        fail("registry kernels must be a non-empty list")

    seen_ids: set[str] = set()
    artifact_count = 0

    for i, kernel in enumerate(kernels):
        if not isinstance(kernel, dict):
            fail(f"kernel index {i} must be object")

        kernel_id = str(kernel.get("kernel_id", "")).strip()
        if not kernel_id:
            fail(f"kernel index {i} missing kernel_id")
        if kernel_id in seen_ids:
            fail(f"duplicate kernel_id '{kernel_id}'")
        seen_ids.add(kernel_id)

        runtime_scope = kernel.get("runtime_scope")
        if not isinstance(runtime_scope, list) or not runtime_scope:
            fail(f"{kernel_id}: runtime_scope must be non-empty list")
        for runtime in runtime_scope:
            if runtime not in ALLOWED_RUNTIMES:
                fail(f"{kernel_id}: invalid runtime_scope value '{runtime}'")

        prong = kernel.get("prong_scope")
        if prong not in ALLOWED_PRONGS:
            fail(f"{kernel_id}: invalid prong_scope '{prong}'")

        privacy_modes = kernel.get("privacy_modes")
        if not isinstance(privacy_modes, list) or not privacy_modes:
            fail(f"{kernel_id}: privacy_modes must be non-empty list")
        for mode in privacy_modes:
            if mode not in ALLOWED_PRIVACY:
                fail(f"{kernel_id}: invalid privacy mode '{mode}'")

        if kernel.get("impact_tier") not in ALLOWED_IMPACT:
            fail(f"{kernel_id}: invalid impact_tier")
        if kernel.get("lifecycle_state") not in ALLOWED_STATE:
            fail(f"{kernel_id}: invalid lifecycle_state")
        if kernel.get("status") not in ALLOWED_STATUS:
            fail(f"{kernel_id}: invalid status")

        artifacts = kernel.get("artifacts")
        if not isinstance(artifacts, dict):
            fail(f"{kernel_id}: artifacts must be object")
        missing_keys = REQUIRED_ARTIFACT_KEYS - set(artifacts.keys())
        if missing_keys:
            fail(f"{kernel_id}: missing artifact keys: {sorted(missing_keys)}")

        for key in sorted(REQUIRED_ARTIFACT_KEYS):
            rel = artifacts.get(key)
            if not isinstance(rel, str) or not rel.strip():
                fail(f"{kernel_id}: artifact '{key}' must be non-empty string path")
            path = Path(rel)
            if not path.exists():
                fail(f"{kernel_id}: artifact '{key}' path missing: {path}")
            artifact_count += 1

        milestone_id = str(kernel.get("milestone_id", "")).strip()
        if not milestone_id.startswith("M"):
            fail(f"{kernel_id}: milestone_id must be execution milestone format")

    return len(kernels), artifact_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary-only", action="store_true")
    args = parser.parse_args()

    kernel_count, artifact_count = check_registry(load_registry())
    print(
        f"URK kernel registry check passed. kernels={kernel_count} artifact_links={artifact_count}"
    )
    if args.summary_only:
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
