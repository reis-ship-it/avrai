#!/usr/bin/env python3
"""Approve/revoke roles in the master-plan sign-off registry."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

REGISTRY_PATH = Path("configs/runtime/master_plan_signoff_registry.json")


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace(
        "+00:00", "Z"
    )


def _load_registry(path: Path) -> dict:
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
        _fail("signoff registry signoffs must be non-empty list")
    return data


def _find_entry(data: dict, role: str) -> dict:
    signoffs = data.get("signoffs")
    assert isinstance(signoffs, list)
    for raw in signoffs:
        if isinstance(raw, dict) and str(raw.get("role", "")).strip() == role:
            return raw
    _fail(f"role not found in sign-off registry: {role}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("role", help="Role to update (exact match)")
    parser.add_argument("--approve", action="store_true", help="Mark role approved")
    parser.add_argument("--revoke", action="store_true", help="Mark role unapproved")
    parser.add_argument("--by", help="Approver identity (required for --approve)")
    parser.add_argument(
        "--at",
        help="Approval timestamp in ISO-8601 UTC (default: now, for --approve)",
    )
    parser.add_argument(
        "--notes",
        help="Optional note to write to role notes field",
    )
    parser.add_argument("--path", default=str(REGISTRY_PATH))
    args = parser.parse_args()

    if args.approve == args.revoke:
        _fail("specify exactly one of --approve or --revoke")

    path = Path(args.path)
    data = _load_registry(path)
    entry = _find_entry(data, args.role)

    if args.approve:
        if not args.by or not args.by.strip():
            _fail("--by is required for --approve")
        approved_at = args.at.strip() if args.at else _utc_now_iso()
        # validate format quickly by parsing
        try:
            _ = dt.datetime.fromisoformat(approved_at.replace("Z", "+00:00"))
        except Exception:
            _fail("--at must be ISO-8601 timestamp")

        entry["approved"] = True
        entry["approved_by"] = args.by.strip()
        entry["approved_at"] = approved_at
    else:
        entry["approved"] = False
        entry["approved_by"] = None
        entry["approved_at"] = None

    if args.notes is not None:
        entry["notes"] = args.notes

    data["updated_at"] = dt.datetime.now(dt.timezone.utc).date().isoformat()

    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    action = "approved" if args.approve else "revoked"
    print(f"OK: {action} sign-off role '{args.role}' in {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
