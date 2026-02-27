#!/usr/bin/env python3
"""Validate conviction gate canary rollout config contract."""

from __future__ import annotations

import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/conviction_gate_canary_rollout.json")
REQUIRED_FLAGS = (
    "conviction_gate_production_enforcement",
    "conviction_gate_high_impact_enforcement",
)


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _expect_dict(value, path: str) -> dict:
    if not isinstance(value, dict):
        _fail(f"{path} must be an object")
    return value


def _expect_user_list(value, path: str) -> list[str]:
    if not isinstance(value, list):
        _fail(f"{path} must be a list")
    users = [str(v).strip() for v in value]
    if any(not u for u in users):
        _fail(f"{path} contains empty user id")
    return users


def main() -> int:
    if not CONFIG_PATH.exists():
        _fail(f"missing file: {CONFIG_PATH}")

    try:
        payload = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON in {CONFIG_PATH}: {exc}")

    root = _expect_dict(payload, "root")
    if str(root.get("version", "")).strip() != "v1":
        _fail("version must be 'v1'")

    flags = _expect_dict(root.get("flags"), "flags")
    rollback = _expect_dict(root.get("rollback_profile"), "rollback_profile")

    target_users_sets = []
    for flag_name in REQUIRED_FLAGS:
        cfg = _expect_dict(flags.get(flag_name), f"flags.{flag_name}")
        rb = _expect_dict(rollback.get(flag_name), f"rollback_profile.{flag_name}")

        enabled = cfg.get("enabled")
        if not isinstance(enabled, bool):
            _fail(f"flags.{flag_name}.enabled must be bool")
        rollout = cfg.get("rolloutPercentage")
        if not isinstance(rollout, (int, float)):
            _fail(f"flags.{flag_name}.rolloutPercentage must be number")

        users = _expect_user_list(cfg.get("targetUsers"), f"flags.{flag_name}.targetUsers")
        target_users_sets.append(tuple(users))

        rb_enabled = rb.get("enabled")
        rb_rollout = rb.get("rolloutPercentage")
        rb_users = _expect_user_list(
            rb.get("targetUsers"), f"rollback_profile.{flag_name}.targetUsers"
        )
        if rb_enabled is not False:
            _fail(f"rollback_profile.{flag_name}.enabled must be false")
        if rb_rollout != 0:
            _fail(f"rollback_profile.{flag_name}.rolloutPercentage must be 0")
        if rb_users:
            _fail(f"rollback_profile.{flag_name}.targetUsers must be empty")

        if enabled and not users:
            _fail(f"flags.{flag_name} enabled=true requires non-empty targetUsers")

    if len(set(target_users_sets)) != 1:
        _fail("targetUsers must match across required conviction gate flags")

    print(f"OK: conviction canary rollout config valid ({CONFIG_PATH})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
