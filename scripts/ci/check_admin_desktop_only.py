#!/usr/bin/env python3
"""Enforce desktop-only platform policy for apps/admin_app."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ADMIN_APP = ROOT / "apps" / "admin_app"

# Admin app must remain desktop-only.
FORBIDDEN_PLATFORM_DIRS = [
    ADMIN_APP / "web",
    ADMIN_APP / "android",
    ADMIN_APP / "ios",
]


def main() -> int:
    violations: list[str] = []

    for path in FORBIDDEN_PLATFORM_DIRS:
        if path.exists():
            violations.append(str(path.relative_to(ROOT)))

    if violations:
        print("[admin-desktop-only] FAILED")
        print("The admin app is desktop-only (macOS/windows/linux).")
        print("Remove these forbidden platform directories:")
        for rel in violations:
            print(f"  - {rel}")
        return 1

    print("[admin-desktop-only] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
