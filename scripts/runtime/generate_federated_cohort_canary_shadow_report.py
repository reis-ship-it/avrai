#!/usr/bin/env python3
"""Generate/check federated cohort canary/shadow promotion report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/federated_cohort_canary_shadow_pipeline.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.md"
)


ALLOWED_STAGES = {"shadow", "canary"}


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: str) -> dt.datetime:
    s = raw.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    v = dt.datetime.fromisoformat(s)
    if v.tzinfo is None:
        v = v.replace(tzinfo=dt.timezone.utc)
    return v.astimezone(dt.timezone.utc)


def _load() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing config: {CONFIG_PATH}")
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON config: {exc}")
    if not isinstance(data, dict):
        _fail("config root must be object")
    return data


def _build_summary(cfg: dict) -> dict:
    if str(cfg.get("version", "")).strip() != "v1":
        _fail("config version must be 'v1'")

    eval_raw = str(cfg.get("evaluation_at", "")).strip()
    if not eval_raw:
        _fail("evaluation_at is required")
    try:
        generated_at = _parse_ts(eval_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{eval_raw}'")

    policy = cfg.get("policy")
    canary = cfg.get("canary")
    cohorts = cfg.get("cohorts")

    if not isinstance(policy, dict):
        _fail("policy must be object")
    if not isinstance(canary, dict):
        _fail("canary must be object")
    if not isinstance(cohorts, list) or not cohorts:
        _fail("cohorts must be non-empty list")

    required_stages = policy.get("required_stages")
    if not isinstance(required_stages, list) or not required_stages:
        _fail("policy.required_stages must be non-empty list")
    required_stages_set = {str(v).strip() for v in required_stages}
    if not required_stages_set.issubset(ALLOWED_STAGES):
        _fail("policy.required_stages contains invalid stage")

    min_samples = canary.get("minimum_samples_per_cohort")
    max_regression = canary.get("max_regression_pct")
    if not isinstance(min_samples, int) or min_samples <= 0:
        _fail("canary.minimum_samples_per_cohort must be positive int")
    if not isinstance(max_regression, (int, float)) or max_regression < 0:
        _fail("canary.max_regression_pct must be non-negative number")

    errors: list[str] = []
    stage_coverage = {stage: 0 for stage in ALLOWED_STAGES}
    cohorts_checked = 0
    cohorts_passing = 0

    for idx, raw in enumerate(cohorts, start=1):
        if not isinstance(raw, dict):
            errors.append(f"cohort[{idx}] must be object")
            continue

        cohorts_checked += 1
        cohort_id = str(raw.get("cohort_id", "")).strip()
        stage = str(raw.get("stage", "")).strip()
        samples = raw.get("samples")
        regression_pct = raw.get("regression_pct")
        promotion_blocked = raw.get("promotion_blocked") is True

        if not cohort_id:
            errors.append(f"cohort[{idx}] missing cohort_id")
        if stage not in ALLOWED_STAGES:
            errors.append(f"cohort[{idx}] invalid stage '{stage}'")
            continue

        stage_coverage[stage] += 1

        if not isinstance(samples, int) or samples < min_samples:
            errors.append(
                f"cohort[{idx}] samples below minimum ({samples} < {min_samples})"
            )
        if not isinstance(regression_pct, (int, float)):
            errors.append(f"cohort[{idx}] invalid regression_pct '{regression_pct}'")
            continue
        if float(regression_pct) > float(max_regression):
            errors.append(
                f"cohort[{idx}] regression {float(regression_pct):.2f}% exceeds max {float(max_regression):.2f}%"
            )
        if promotion_blocked:
            errors.append(f"cohort[{idx}] promotion_blocked=true")

        if (
            isinstance(samples, int)
            and samples >= min_samples
            and float(regression_pct) <= float(max_regression)
            and not promotion_blocked
        ):
            cohorts_passing += 1

    missing_required_stages = sorted(
        stage for stage in required_stages_set if stage_coverage.get(stage, 0) == 0
    )
    for stage in missing_required_stages:
        errors.append(f"required stage missing from cohort data: {stage}")

    promotion_policy_enforced = not errors
    verdict = "PASS" if promotion_policy_enforced else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "cohorts_checked": cohorts_checked,
        "cohorts_passing": cohorts_passing,
        "required_stages": sorted(required_stages_set),
        "stage_coverage": stage_coverage,
        "missing_required_stages": missing_required_stages,
        "max_regression_pct": float(max_regression),
        "minimum_samples_per_cohort": int(min_samples),
        "promotion_policy_enforced": promotion_policy_enforced,
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    coverage = summary.get("stage_coverage") or {}
    return (
        "# Federated Cohort Canary/Shadow Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Cohorts checked:** {summary.get('cohorts_checked', 0)}  \n"
        f"**Cohorts passing:** {summary.get('cohorts_passing', 0)}  \n"
        f"**Required stages:** {', '.join(summary.get('required_stages', []))}  \n"
        f"**Stage coverage:** shadow={coverage.get('shadow', 0)}, canary={coverage.get('canary', 0)}  \n"
        f"**Max regression (%):** {summary.get('max_regression_pct', 0.0):.2f}  \n"
        f"**Min samples per cohort:** {summary.get('minimum_samples_per_cohort', 0)}  \n"
        f"**Promotion policy enforced:** {summary.get('promotion_policy_enforced')}  \n"
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

    summary = _build_summary(_load())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("federated cohort report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("federated cohort JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("federated cohort markdown report out of date")
        print("OK: federated cohort canary/shadow report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
