#!/usr/bin/env python3
"""Generate/check admin-facing URK kernel catalog markdown from registry."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REGISTRY_PATH = Path("configs/runtime/kernel_registry.json")
OUT_MD = Path("docs/admin/URK_KERNEL_CATALOG.md")


def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load_registry() -> dict:
    if not REGISTRY_PATH.exists():
        fail(f"missing registry: {REGISTRY_PATH}")
    data = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        fail("registry root must be object")
    return data


def render(data: dict) -> str:
    kernels = data.get("kernels")
    if not isinstance(kernels, list):
        fail("registry kernels must be list")

    lines = [
        "# URK Kernel Catalog",
        "",
        "Generated from `configs/runtime/kernel_registry.json`.",
        "",
        "## Kernel Inventory",
        "",
        "| Kernel ID | Runtime Scope | Prong | Privacy Modes | Impact | Lifecycle | Milestone | Purpose |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]

    for kernel in sorted(kernels, key=lambda k: str(k.get("kernel_id", ""))):
        runtime_scope = ", ".join(kernel.get("runtime_scope", []))
        privacy_modes = ", ".join(kernel.get("privacy_modes", []))
        lines.append(
            "| {kernel_id} | {runtime_scope} | {prong_scope} | {privacy_modes} | {impact_tier} | {lifecycle_state} | {milestone_id} | {purpose} |".format(
                kernel_id=kernel.get("kernel_id", ""),
                runtime_scope=runtime_scope,
                prong_scope=kernel.get("prong_scope", ""),
                privacy_modes=privacy_modes,
                impact_tier=kernel.get("impact_tier", ""),
                lifecycle_state=kernel.get("lifecycle_state", ""),
                milestone_id=kernel.get("milestone_id", ""),
                purpose=kernel.get("purpose", ""),
            )
        )

    lines.extend([
        "",
        "## Completeness Checklist",
        "",
        "Each kernel must include: `controls`, `contract`, `test`, `report_generator`, `report_json`, `report_md`, `baseline`.",
        "",
        "Validation command:",
        "",
        "```bash",
        "python3 scripts/runtime/check_urk_kernel_registry.py",
        "```",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    out = render(load_registry())

    if args.check:
        if not OUT_MD.exists():
            fail("kernel catalog missing; run generator")
        if OUT_MD.read_text(encoding="utf-8") != out:
            fail("kernel catalog out of date")
        print("OK: URK kernel catalog is in sync.")
        return 0

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text(out, encoding="utf-8")
    print(f"Updated {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
