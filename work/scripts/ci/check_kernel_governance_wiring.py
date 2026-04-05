#!/usr/bin/env python3
"""
Guard: critical state-changing manager methods must call kernel governance.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


RULES = [
    (
        "lib/core/services/ai_infrastructure/model_version_manager.dart",
        [
            "switchCallingScoreVersion",
            "switchOutcomeVersion",
            "startABTest",
        ],
    ),
    (
        "lib/core/services/ai_infrastructure/model_safety_supervisor.dart",
        [
            "startRolloutCandidate",
            "_evaluateOne",
        ],
    ),
    (
        "lib/core/services/recommendations/agent_happiness_service.dart",
        [
            "recordSignal",
        ],
    ),
]


def _extract_method_body(content: str, method_name: str) -> str:
    pattern = re.compile(
        r"(?:Future<[^>]+>|Future<void>|void|bool|String\??|double\??)\s+"
        + re.escape(method_name)
        + r"\s*\([^)]*\)\s*(?:async\s*)?\{",
        re.MULTILINE,
    )
    match = pattern.search(content)
    if not match:
        raise ValueError(f"method_not_found:{method_name}")

    start = match.end() - 1  # points at '{'
    depth = 0
    for i in range(start, len(content)):
        ch = content[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return content[start + 1 : i]
    raise ValueError(f"method_unterminated:{method_name}")


def main() -> int:
    failures: list[str] = []
    for rel_path, methods in RULES:
        path = Path(rel_path)
        if not path.exists():
            failures.append(f"missing_file:{rel_path}")
            continue
        content = path.read_text(encoding="utf-8")
        for method_name in methods:
            try:
                body = _extract_method_body(content, method_name)
            except ValueError as exc:
                failures.append(f"{rel_path}:{exc}")
                continue
            if "_evaluateGovernance(" not in body:
                failures.append(
                    f"{rel_path}:{method_name}:missing _evaluateGovernance() call"
                )

    if failures:
        print("Kernel governance wiring check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Kernel governance wiring check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
