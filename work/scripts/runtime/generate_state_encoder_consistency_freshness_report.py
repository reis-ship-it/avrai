#!/usr/bin/env python3
"""Generate/check state encoder consistency + freshness report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/state_encoder_consistency_freshness_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.md"
)


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


def _require_non_negative_number(value: object, field: str) -> float:
    if not isinstance(value, (int, float)) or value < 0:
        _fail(f"{field} must be non-negative number")
    return float(value)


def _require_positive_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value <= 0:
        _fail(f"{field} must be positive integer")
    return int(value)


def _build_summary(cfg: dict) -> dict:
    if str(cfg.get("version", "")).strip() != "v1":
        _fail("config version must be 'v1'")

    evaluation_at_raw = str(cfg.get("evaluation_at", "")).strip()
    if not evaluation_at_raw:
        _fail("evaluation_at is required")
    try:
        generated_at = _parse_ts(evaluation_at_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{evaluation_at_raw}'")

    freshness = cfg.get("freshness_slo")
    if not isinstance(freshness, dict):
        _fail("freshness_slo must be object")
    max_p95_age = _require_non_negative_number(
        freshness.get("max_p95_feature_age_minutes"),
        "freshness_slo.max_p95_feature_age_minutes",
    )
    observed_p95_age = _require_non_negative_number(
        freshness.get("observed_p95_feature_age_minutes"),
        "freshness_slo.observed_p95_feature_age_minutes",
    )
    sampled_snapshots = _require_positive_int(
        freshness.get("sampled_snapshots"),
        "freshness_slo.sampled_snapshots",
    )

    consistency = cfg.get("snapshot_consistency")
    if not isinstance(consistency, dict):
        _fail("snapshot_consistency must be object")
    max_mismatch_rate = _require_non_negative_number(
        consistency.get("max_mismatch_rate_pct"),
        "snapshot_consistency.max_mismatch_rate_pct",
    )
    observed_mismatch_rate = _require_non_negative_number(
        consistency.get("observed_mismatch_rate_pct"),
        "snapshot_consistency.observed_mismatch_rate_pct",
    )
    checked_feature_groups = _require_positive_int(
        consistency.get("checked_feature_groups"),
        "snapshot_consistency.checked_feature_groups",
    )

    atomic = cfg.get("atomic_snapshot")
    if not isinstance(atomic, dict):
        _fail("atomic_snapshot must be object")
    monotonic_passed = atomic.get("monotonic_sequence_passed") is True
    lineage_passed = atomic.get("lineage_completeness_passed") is True
    checked_atomic_snapshots = _require_positive_int(
        atomic.get("checked_snapshots"),
        "atomic_snapshot.checked_snapshots",
    )

    freshness_ok = observed_p95_age <= max_p95_age
    consistency_ok = observed_mismatch_rate <= max_mismatch_rate
    atomic_ok = monotonic_passed and lineage_passed

    errors: list[str] = []
    if not freshness_ok:
        errors.append("feature freshness p95 age exceeded threshold")
    if not consistency_ok:
        errors.append("snapshot consistency mismatch rate exceeded threshold")
    if not monotonic_passed:
        errors.append("atomic snapshot monotonic sequence check failed")
    if not lineage_passed:
        errors.append("atomic snapshot lineage completeness check failed")

    verdict = "PASS" if freshness_ok and consistency_ok and atomic_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "freshness_slo": {
            "max_p95_feature_age_minutes": max_p95_age,
            "observed_p95_feature_age_minutes": observed_p95_age,
            "sampled_snapshots": sampled_snapshots,
            "within_threshold": freshness_ok,
        },
        "snapshot_consistency": {
            "max_mismatch_rate_pct": max_mismatch_rate,
            "observed_mismatch_rate_pct": observed_mismatch_rate,
            "checked_feature_groups": checked_feature_groups,
            "within_threshold": consistency_ok,
        },
        "atomic_snapshot": {
            "monotonic_sequence_passed": monotonic_passed,
            "lineage_completeness_passed": lineage_passed,
            "checked_snapshots": checked_atomic_snapshots,
            "within_threshold": atomic_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    freshness = summary.get("freshness_slo") or {}
    consistency = summary.get("snapshot_consistency") or {}
    atomic = summary.get("atomic_snapshot") or {}

    return (
        "# State Encoder Consistency/Freshness Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max p95 feature age (min):** {freshness.get('max_p95_feature_age_minutes', 0.0):.2f}  \n"
        f"**Observed p95 feature age (min):** {freshness.get('observed_p95_feature_age_minutes', 0.0):.2f}  \n"
        f"**Sampled snapshots:** {freshness.get('sampled_snapshots', 0)}  \n"
        f"**Freshness threshold check:** {freshness.get('within_threshold')}  \n"
        f"**Max mismatch rate (%):** {consistency.get('max_mismatch_rate_pct', 0.0):.2f}  \n"
        f"**Observed mismatch rate (%):** {consistency.get('observed_mismatch_rate_pct', 0.0):.2f}  \n"
        f"**Checked feature groups:** {consistency.get('checked_feature_groups', 0)}  \n"
        f"**Consistency threshold check:** {consistency.get('within_threshold')}  \n"
        f"**Atomic monotonic sequence passed:** {atomic.get('monotonic_sequence_passed')}  \n"
        f"**Atomic lineage completeness passed:** {atomic.get('lineage_completeness_passed')}  \n"
        f"**Checked atomic snapshots:** {atomic.get('checked_snapshots', 0)}  \n"
        f"**Atomic threshold check:** {atomic.get('within_threshold')}  \n"
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
            _fail("state encoder report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("state encoder consistency/freshness JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("state encoder consistency/freshness markdown report out of date")
        print("OK: state encoder consistency/freshness report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
