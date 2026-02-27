#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BASELINE = (
    ROOT / "scripts" / "ci" / "baselines" / "engine_runtime_boundary_baseline.json"
)

DEFAULT_PROTECTED_ROOTS = (
    "lib/core/ai/",
    "lib/core/ai2ai/",
    "lib/core/ml/",
    "lib/core/services/",
    "packages/",
)

FORBIDDEN_URI_PATTERNS = (
    re.compile(r"^package:avrai/presentation/"),
    re.compile(r"^package:avrai/app\.dart$"),
    re.compile(r"^package:avrai/main\.dart$"),
    re.compile(r"^package:avrai/injection_container(_.*)?\.dart$"),
)

IMPORT_RE = re.compile(
    r"""^\s*(import|export)\s+(['"])([^'"]+)\2""",
)


def fail(msg: str) -> None:
    print(f"ENGINE/RUNTIME BOUNDARY CHECK FAILED: {msg}")
    sys.exit(1)


def to_rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def is_protected_file(rel_path: str, roots: tuple[str, ...]) -> bool:
    return any(rel_path.startswith(root) for root in roots)


def is_forbidden_uri(uri: str) -> bool:
    if any(pattern.search(uri) for pattern in FORBIDDEN_URI_PATTERNS):
        return True

    # Also block relative imports that reach app presentation roots.
    if "presentation/" in uri and (uri.startswith("../") or uri.startswith("./")):
        return True

    return False


def find_violations(roots: tuple[str, ...]) -> set[str]:
    violations: set[str] = set()

    for path in ROOT.rglob("*.dart"):
        if not path.is_file():
            continue
        rel = to_rel(path)
        if not is_protected_file(rel, roots):
            continue
        if "/build/" in rel:
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
            if is_forbidden_uri(uri):
                violations.add(f"{rel}|{uri}")

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
    path.write_text(
        json.dumps(sorted(entries), indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate engine/runtime files do not import app presentation/composition roots.",
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
    parser.add_argument(
        "--protected-root",
        action="append",
        dest="protected_roots",
        help="Protected source root (repeatable). Defaults to core engine/runtime roots.",
    )
    args = parser.parse_args()

    protected_roots = tuple(args.protected_roots) if args.protected_roots else DEFAULT_PROTECTED_ROOTS
    baseline_path = Path(args.baseline)

    current = find_violations(protected_roots)
    if args.update_baseline:
        write_baseline(baseline_path, current)
        print(
            f"Updated engine/runtime boundary baseline: {baseline_path} ({len(current)} entries)",
        )
        return

    baseline = read_baseline(baseline_path)
    new_violations = sorted(current - baseline)
    resolved = sorted(baseline - current)

    if new_violations:
        fail(
            "New boundary violations detected.\n"
            + "\n".join(f"- {v}" for v in new_violations)
            + "\n\nFix imports or (temporary) update baseline:\n"
            + "  python3 scripts/ci/check_engine_runtime_boundary.py --update-baseline",
        )

    if resolved:
        print("NOTE: Baseline entries resolved and can be pruned:")
        for entry in resolved:
            print(f"- {entry}")

    print("OK: No new engine/runtime boundary violations.")


if __name__ == "__main__":
    main()
