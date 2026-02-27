#!/usr/bin/env python3
"""Validate master-plan sign-off registry structure and approval consistency."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

REGISTRY_PATH = Path("configs/runtime/master_plan_signoff_registry.json")
REQUIRED_ROLES = {
    "Product",
    "Platform/OS Engineering",
    "ML Research",
    "Reliability/SRE",
    "Security/Compliance",
    "Governance/Executive",
}


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: str) -> dt.datetime:
    value = raw.strip()
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", default=str(REGISTRY_PATH))
    args = parser.parse_args()

    path = Path(args.path)
    if not path.exists():
        _fail(f"missing sign-off registry: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON in sign-off registry: {exc}")

    if not isinstance(data, dict):
        _fail("sign-off registry root must be JSON object")
    if str(data.get("version", "")).strip() != "v1":
        _fail("sign-off registry version must be 'v1'")

    signoffs = data.get("signoffs")
    if not isinstance(signoffs, list) or not signoffs:
        _fail("signoffs must be non-empty list")

    seen: set[str] = set()
    approved_count = 0

    for idx, raw in enumerate(signoffs, start=1):
        if not isinstance(raw, dict):
            _fail(f"signoff[{idx}] must be object")

        role = str(raw.get("role", "")).strip()
        if not role:
            _fail(f"signoff[{idx}] missing role")
        if role in seen:
            _fail(f"duplicate role in sign-off registry: {role}")
        seen.add(role)

        approved = raw.get("approved")
        if not isinstance(approved, bool):
            _fail(f"signoff[{idx}] approved must be boolean")

        approved_by = raw.get("approved_by")
        approved_at = raw.get("approved_at")

        if approved:
            approved_count += 1
            if not isinstance(approved_by, str) or not approved_by.strip():
                _fail(f"signoff[{idx}] approved role requires non-empty approved_by")
            if not isinstance(approved_at, str) or not approved_at.strip():
                _fail(f"signoff[{idx}] approved role requires non-empty approved_at")
            try:
                _parse_ts(approved_at)
            except Exception:
                _fail(f"signoff[{idx}] approved_at must be ISO timestamp")
        else:
            if approved_by not in (None, ""):
                _fail(f"signoff[{idx}] pending role must not set approved_by")
            if approved_at not in (None, ""):
                _fail(f"signoff[{idx}] pending role must not set approved_at")

    missing_roles = sorted(REQUIRED_ROLES - seen)
    extra_roles = sorted(seen - REQUIRED_ROLES)

    if missing_roles:
        _fail(f"missing required roles: {', '.join(missing_roles)}")
    if extra_roles:
        _fail(f"unexpected roles present: {', '.join(extra_roles)}")

    print(
        "OK: master-plan sign-off registry valid "
        f"({approved_count}/{len(REQUIRED_ROLES)} roles approved)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
