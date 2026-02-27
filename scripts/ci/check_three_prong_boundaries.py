#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BASELINE = (
    ROOT / "scripts" / "ci" / "baselines" / "three_prong_boundaries_baseline.json"
)

IMPORT_RE = re.compile(r"""^\s*(import|export)\s+(['"])([^'"]+)\2""")


RULES = (
    {
        "name": "engine_no_app_composition_imports",
        "roots": ("lib/core/ai/", "lib/core/ml/"),
        "forbidden_patterns": (
            r"^package:avrai/presentation/",
            r"^package:avrai/app\.dart$",
            r"^package:avrai/main\.dart$",
            r"^package:avrai/injection_container(_.*)?\.dart$",
        ),
        "forbidden_relative_contains": ("presentation/",),
    },
    {
        "name": "runtime_no_presentation_imports",
        "roots": ("lib/core/services/", "lib/core/ai2ai/", "lib/bootstrap/"),
        "forbidden_patterns": (r"^package:avrai/presentation/",),
        "forbidden_relative_contains": ("presentation/",),
    },
    {
        "name": "app_no_engine_internal_imports",
        "roots": ("lib/presentation/",),
        "forbidden_patterns": (
            r"^package:avrai/core/ai/continuous_learning/",
            r"^package:avrai/core/ai2ai/discovery/",
            r"^package:avrai/core/ai2ai/routing/",
            r"^package:avrai/core/ai2ai/resilience/",
            r"^package:avrai/core/ai2ai/telemetry/",
            r"^package:avrai/bootstrap/",
        ),
        "forbidden_relative_contains": (
            "/core/ai/continuous_learning/",
            "/core/ai2ai/discovery/",
            "/core/ai2ai/routing/",
            "/core/ai2ai/resilience/",
            "/core/ai2ai/telemetry/",
            "/bootstrap/",
        ),
    },
)


def fail(msg: str) -> None:
    print(f"THREE-PRONG BOUNDARY CHECK FAILED: {msg}")
    sys.exit(1)


def to_rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def is_rule_target(rel_path: str, roots: tuple[str, ...]) -> bool:
    return any(rel_path.startswith(root) for root in roots)


def is_forbidden(uri: str, rule: dict) -> bool:
    for p in rule["forbidden_patterns"]:
        if re.search(p, uri):
            return True

    if uri.startswith("../") or uri.startswith("./"):
        for needle in rule["forbidden_relative_contains"]:
            if needle in uri:
                return True
    return False


def find_violations() -> set[str]:
    violations: set[str] = set()

    for path in ROOT.rglob("*.dart"):
        if not path.is_file():
            continue
        rel = to_rel(path)
        if "/build/" in rel:
            continue

        active_rules = [r for r in RULES if is_rule_target(rel, r["roots"])]
        if not active_rules:
            continue

        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except Exception as exc:
            fail(f"Could not read {rel}: {exc}")

        for line in lines:
            stripped = line.lstrip()
            if stripped.startswith("//"):
                continue

            match = IMPORT_RE.match(stripped)
            if not match:
                continue

            uri = match.group(3)
            for rule in active_rules:
                if is_forbidden(uri, rule):
                    violations.add(f"{rule['name']}|{rel}|{uri}")

    return violations


def read_baseline(path: Path) -> set[str]:
    if not path.exists():
        return set()
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Could not parse baseline {path}: {exc}")
    if not isinstance(raw, list):
        fail(f"Baseline {path} must be a JSON list.")
    return {entry for entry in raw if isinstance(entry, str)}


def write_baseline(path: Path, entries: set[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(sorted(entries), indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate 3-prong architecture import boundaries with baseline support.",
    )
    parser.add_argument(
        "--baseline",
        default=str(DEFAULT_BASELINE),
        help="Baseline JSON allowlist path.",
    )
    parser.add_argument(
        "--update-baseline",
        action="store_true",
        help="Write current violations into baseline.",
    )
    args = parser.parse_args()

    baseline_path = Path(args.baseline)
    current = find_violations()

    if args.update_baseline:
        write_baseline(baseline_path, current)
        print(f"Updated baseline: {baseline_path} ({len(current)} entries)")
        return

    baseline = read_baseline(baseline_path)
    new_violations = sorted(current - baseline)
    resolved = sorted(baseline - current)

    if new_violations:
        fail(
            "New 3-prong boundary violations detected.\n"
            + "\n".join(f"- {v}" for v in new_violations)
            + "\n\nFix imports or (temporary) update baseline:\n"
            + "  python3 scripts/ci/check_three_prong_boundaries.py --update-baseline"
        )

    if resolved:
        print("NOTE: Baseline entries resolved and can be pruned:")
        for entry in resolved:
            print(f"- {entry}")

    print("OK: No new 3-prong boundary violations.")


if __name__ == "__main__":
    main()
