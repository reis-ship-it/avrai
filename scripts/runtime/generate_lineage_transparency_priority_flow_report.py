#!/usr/bin/env python3
"""Generate/check lineage transparency priority-flow coverage report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/lineage_transparency_priority_flows.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.md"
)
ALLOWED_STATUS = {"implemented", "in_progress", "planned"}


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _load_config() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing lineage transparency config: {CONFIG_PATH}")
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON in lineage transparency config: {exc}")
    if not isinstance(data, dict):
        _fail("lineage transparency config root must be object")
    return data


def _build_summary(data: dict) -> dict:
    if str(data.get("version", "")).strip() != "v1":
        _fail("lineage transparency config version must be 'v1'")

    required_fields = data.get("required_fields")
    if not isinstance(required_fields, list) or not required_fields:
        _fail("required_fields must be non-empty list")

    flows = data.get("priority_flows")
    if not isinstance(flows, list) or not flows:
        _fail("priority_flows must be non-empty list")

    total = 0
    implemented = 0
    in_progress = 0
    planned = 0
    fully_covered = 0
    errors: list[str] = []

    for idx, raw in enumerate(flows, start=1):
        if not isinstance(raw, dict):
            errors.append(f"flow[{idx}] must be object")
            continue
        total += 1

        flow_id = str(raw.get("flow_id", "")).strip()
        if not flow_id:
            errors.append(f"flow[{idx}] missing flow_id")

        status = str(raw.get("status", "")).strip()
        if status not in ALLOWED_STATUS:
            errors.append(f"flow[{idx}] invalid status '{status}'")
        elif status == "implemented":
            implemented += 1
        elif status == "in_progress":
            in_progress += 1
        elif status == "planned":
            planned += 1

        req_change = raw.get("requires_change_summary") is True
        req_lineage = raw.get("requires_lineage_ref") is True
        req_claim_count = raw.get("requires_influencing_claims_count") is True
        req_last = raw.get("requires_last_changed_at") is True

        if req_change and req_lineage and req_claim_count and req_last:
            fully_covered += 1
        else:
            errors.append(
                "flow[{}] must require change_summary+lineage_ref+"
                "influencing_claims_count+last_changed_at".format(idx)
            )

    coverage_ratio = (implemented / total) if total else 0.0
    contract_ok = (fully_covered == total) and not errors
    verdict = "PASS" if contract_ok and implemented > 0 else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "total_flows": total,
        "implemented_flows": implemented,
        "in_progress_flows": in_progress,
        "planned_flows": planned,
        "implemented_coverage_ratio": coverage_ratio,
        "contract_ok": contract_ok,
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    return (
        "# 3-Prong Lineage Transparency Priority Flow Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Total flows:** {summary.get('total_flows', 0)}  \n"
        f"**Implemented flows:** {summary.get('implemented_flows', 0)}  \n"
        f"**In progress flows:** {summary.get('in_progress_flows', 0)}  \n"
        f"**Planned flows:** {summary.get('planned_flows', 0)}  \n"
        f"**Implemented coverage ratio:** {summary.get('implemented_coverage_ratio', 0.0):.2f}  \n"
        f"**Contract OK:** {summary.get('contract_ok')}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Validation Errors\n\n"
        + (
            "- None\n"
            if not summary.get("errors")
            else "\n".join(f"- {e}" for e in summary.get("errors", [])) + "\n"
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    summary = _build_summary(_load_config())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("lineage transparency report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("lineage transparency JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("lineage transparency markdown report out of date")
        print("OK: lineage transparency priority flow report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
