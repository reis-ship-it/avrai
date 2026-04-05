#!/usr/bin/env python3
"""Validates required replay/adversarial/contradiction eval evidence before promotion."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

DEFAULT_MANIFEST = Path("apps/avrai_app/configs/ml/promotion_eval_manifest.json")
DEFAULT_SUMMARY = Path(
    "work/docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json"
)

REQUIRED_SUITES = [
    "offline_replay",
    "adversarial_robustness",
    "contradiction_stress",
]
REQUIRED_COMPRESSION_SUITES = [
    "ranking_drift",
    "calibration_drift",
    "contradiction_detection_degradation",
    "uncertainty_honesty_regression",
]
ALLOWED_COMPRESSION_PROFILES = {"compressed_reality_model_v1"}
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
    compression_approvals_attempted = 0

    if manifest.get("manifest_version") != "v2":
        _fail(errors, "manifest_version must be 'v2'.")

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

    compression_suites = manifest.get("required_compression_regression_suites")
    if not isinstance(compression_suites, list):
        _fail(errors, "required_compression_regression_suites must be a list.")
        compression_suites = []

    compression_suite_names = [str(s) for s in compression_suites]
    if compression_suite_names != REQUIRED_COMPRESSION_SUITES:
        _fail(
            errors,
            "required_compression_regression_suites must exactly equal "
            + ", ".join(REQUIRED_COMPRESSION_SUITES),
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

        compression_profile = str(
            candidate.get("compression_rollout_profile", "")
        ).strip()
        if compression_profile and compression_profile not in ALLOWED_COMPRESSION_PROFILES:
            _fail(
                errors,
                f"candidate '{cid}' has invalid compression_rollout_profile '{compression_profile}'.",
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

        compression_missing: list[str] = []
        compression_non_passing: list[str] = []
        compression_budget_exceeded: list[str] = []
        compression_suites_raw = candidate.get("compression_suite_results")
        if compression_profile:
            if not isinstance(compression_suites_raw, list):
                _fail(
                    errors,
                    f"candidate '{cid}' compression_suite_results must be a list when compression_rollout_profile is present.",
                )
                compression_suites_raw = []
        elif compression_suites_raw is not None:
            _fail(
                errors,
                f"candidate '{cid}' declares compression_suite_results without compression_rollout_profile.",
            )
            compression_suites_raw = []

        by_compression_suite: dict[str, dict] = {}
        for row in compression_suites_raw or []:
            suite_row = _as_dict(row)
            suite_name = str(suite_row.get("suite", "")).strip()
            if not suite_name:
                continue
            if suite_name in by_compression_suite:
                _fail(
                    errors,
                    f"candidate '{cid}' repeats compression suite '{suite_name}'.",
                )
            by_compression_suite[suite_name] = suite_row
            status = str(suite_row.get("status", "")).strip()
            if status and status not in ALLOWED_STATUSES:
                _fail(
                    errors,
                    f"candidate '{cid}' compression suite '{suite_name}' has invalid status '{status}'.",
                )

        if compression_profile:
            for suite_name in REQUIRED_COMPRESSION_SUITES:
                result = by_compression_suite.get(suite_name)
                if result is None:
                    compression_missing.append(suite_name)
                    continue
                status = str(result.get("status", "")).strip()
                artifact_uri = str(result.get("artifact_uri", "")).strip()
                observed = result.get("observed_regression")
                budget = result.get("max_allowed_regression")
                if not isinstance(observed, (int, float)) or not isinstance(
                    budget, (int, float)
                ):
                    _fail(
                        errors,
                        f"candidate '{cid}' compression suite '{suite_name}' must declare numeric observed_regression and max_allowed_regression.",
                    )
                    compression_budget_exceeded.append(suite_name)
                    continue
                if observed < 0 or budget < 0:
                    _fail(
                        errors,
                        f"candidate '{cid}' compression suite '{suite_name}' must not use negative regression values.",
                    )
                    compression_budget_exceeded.append(suite_name)
                if status != "pass":
                    compression_non_passing.append(suite_name)
                if status == "pass" and not artifact_uri:
                    compression_non_passing.append(suite_name)
                if observed > budget:
                    compression_budget_exceeded.append(suite_name)
                if status == "pass" and observed > budget:
                    _fail(
                        errors,
                        f"candidate '{cid}' compression suite '{suite_name}' is marked pass but exceeds regression budget.",
                    )

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
            if compression_profile:
                compression_approvals_attempted += 1
                if compression_missing:
                    _fail(
                        errors,
                        f"candidate '{cid}' approve decision missing required compression suites: {', '.join(compression_missing)}.",
                    )
                if compression_non_passing:
                    _fail(
                        errors,
                        f"candidate '{cid}' approve decision requires pass+artifact for compression suites: {', '.join(sorted(set(compression_non_passing)))}.",
                    )
                if compression_budget_exceeded:
                    _fail(
                        errors,
                        f"candidate '{cid}' approve decision exceeds compression regression budget for: {', '.join(sorted(set(compression_budget_exceeded)))}.",
                    )

        candidate_summaries.append(
            {
                "candidate_id": cid,
                "compression_rollout_profile": compression_profile or None,
                "promotion_decision": decision,
                "missing_required_suites": missing,
                "non_passing_required_suites": sorted(set(non_passing)),
                "missing_required_compression_suites": compression_missing,
                "non_passing_required_compression_suites": sorted(
                    set(compression_non_passing)
                ),
                "compression_budget_exceeded_suites": sorted(
                    set(compression_budget_exceeded)
                ),
            }
        )

    summary = {
        "manifest_version": manifest.get("manifest_version"),
        "required_suites": REQUIRED_SUITES,
        "required_compression_regression_suites": REQUIRED_COMPRESSION_SUITES,
        "approvals_attempted": approvals_attempted,
        "compression_approvals_attempted": compression_approvals_attempted,
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
