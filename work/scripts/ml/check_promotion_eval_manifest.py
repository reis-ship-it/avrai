#!/usr/bin/env python3
"""Validates required replay/adversarial/contradiction eval evidence before promotion."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

DEFAULT_MANIFEST = Path("configs/ml/promotion_eval_manifest.json")
DEFAULT_SUMMARY = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json")

REQUIRED_SUITES = [
    "offline_replay",
    "adversarial_robustness",
    "contradiction_stress",
]
ALLOWED_DECISIONS = {"approve", "hold", "reject"}
ALLOWED_STATUSES = {"pass", "fail", "pending"}


def _fail(errors: list[str], message: str) -> None:
    errors.append(message)


def _as_dict(value, fallback=None):
    if isinstance(value, dict):
        return value
    return fallback if fallback is not None else {}


def validate_manifest(manifest: dict) -> tuple[list[str], dict]:
    errors: list[str] = []
    approvals_attempted = 0

    if manifest.get("manifest_version") != "v1":
        _fail(errors, "manifest_version must be 'v1'.")

    suites = manifest.get("required_suites")
    if not isinstance(suites, list):
        _fail(errors, "required_suites must be a list.")
        suites = []

    suite_names = [str(s) for s in suites]
    if suite_names != REQUIRED_SUITES:
        _fail(
            errors,
            "required_suites must exactly equal " + ", ".join(REQUIRED_SUITES),
        )

    candidates = manifest.get("promotion_candidates")
    if not isinstance(candidates, list) or not candidates:
        _fail(errors, "promotion_candidates must be a non-empty list.")
        candidates = []

    seen_ids: set[str] = set()
    candidate_summaries: list[dict] = []

    for idx, raw_candidate in enumerate(candidates, start=1):
        candidate = _as_dict(raw_candidate)
        cid = str(candidate.get("candidate_id", "")).strip()
        if not cid:
            _fail(errors, f"candidate[{idx}] missing candidate_id.")
            cid = f"<missing:{idx}>"
        if cid in seen_ids:
            _fail(errors, f"candidate_id '{cid}' appears more than once.")
        seen_ids.add(cid)

        decision = str(candidate.get("promotion_decision", "")).strip()
        if decision not in ALLOWED_DECISIONS:
            _fail(
                errors,
                f"candidate '{cid}' has invalid promotion_decision '{decision}'.",
            )

        suites_raw = candidate.get("suite_results")
        if not isinstance(suites_raw, list):
            _fail(errors, f"candidate '{cid}' suite_results must be a list.")
            suites_raw = []

        by_suite: dict[str, dict] = {}
        for row in suites_raw:
            suite_row = _as_dict(row)
            suite_name = str(suite_row.get("suite", "")).strip()
            if not suite_name:
                continue
            if suite_name in by_suite:
                _fail(errors, f"candidate '{cid}' repeats suite '{suite_name}'.")
            by_suite[suite_name] = suite_row
            status = str(suite_row.get("status", "")).strip()
            if status and status not in ALLOWED_STATUSES:
                _fail(
                    errors,
                    f"candidate '{cid}' suite '{suite_name}' has invalid status '{status}'.",
                )

        missing: list[str] = []
        non_passing: list[str] = []
        for suite_name in REQUIRED_SUITES:
            result = by_suite.get(suite_name)
            if result is None:
                missing.append(suite_name)
                continue
            status = str(result.get("status", "")).strip()
            artifact_uri = str(result.get("artifact_uri", "")).strip()
            if status != "pass":
                non_passing.append(suite_name)
            if status == "pass" and not artifact_uri:
                non_passing.append(suite_name)

        if decision == "approve":
            approvals_attempted += 1
            if missing:
                _fail(
                    errors,
                    f"candidate '{cid}' approve decision missing required suites: {', '.join(missing)}.",
                )
            if non_passing:
                _fail(
                    errors,
                    f"candidate '{cid}' approve decision requires pass+artifact for: {', '.join(sorted(set(non_passing)))}.",
                )

        candidate_summaries.append(
            {
                "candidate_id": cid,
                "promotion_decision": decision,
                "missing_required_suites": missing,
                "non_passing_required_suites": sorted(set(non_passing)),
            }
        )

    summary = {
        "manifest_version": manifest.get("manifest_version"),
        "required_suites": REQUIRED_SUITES,
        "approvals_attempted": approvals_attempted,
        "errors": errors,
        "has_errors": bool(errors),
        "candidate_summaries": candidate_summaries,
    }

    return errors, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    parser.add_argument("--summary-out", default=str(DEFAULT_SUMMARY))
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    summary_path = Path(args.summary_out)

    if not manifest_path.exists():
        print(f"ERROR: missing manifest: {manifest_path}", file=sys.stderr)
        return 1

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR: failed to parse manifest JSON: {exc}", file=sys.stderr)
        return 1

    if not isinstance(manifest, dict):
        print("ERROR: manifest root must be an object", file=sys.stderr)
        return 1

    errors, summary = validate_manifest(manifest)
    rendered_summary = json.dumps(summary, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not summary_path.exists():
            print(
                f"ERROR: missing summary output in check mode: {summary_path}",
                file=sys.stderr,
            )
            return 1
        current = summary_path.read_text(encoding="utf-8")
        if current != rendered_summary:
            print(
                "ERROR: promotion eval summary out of date. "
                "Run scripts/ml/check_promotion_eval_manifest.py",
                file=sys.stderr,
            )
            return 1
    else:
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(rendered_summary, encoding="utf-8")

    if errors:
        print("Promotion eval manifest check failed:", file=sys.stderr)
        for err in errors:
            print(f"- {err}", file=sys.stderr)
        return 1

    print("OK: promotion eval manifest is valid.")
    print(f"Summary: {summary_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
