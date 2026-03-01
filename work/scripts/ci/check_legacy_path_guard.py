#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "configs" / "runtime" / "legacy_path_guard.json"


def fail(message: str) -> None:
    print(f"LEGACY-PATH GUARD FAILED: {message}")
    sys.exit(1)


def run_git(args: list[str]) -> str:
    proc = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        fail(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout.strip()


def load_config(path: Path) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Could not parse config {path}: {exc}")
    if not isinstance(raw, dict):
        fail(f"Config must be a JSON object: {path}")
    return raw


def get_diff_base(base_ref: str, head_ref: str) -> str:
    candidates = [f"origin/{base_ref}", base_ref]
    for candidate in candidates:
        proc = subprocess.run(
            ["git", "rev-parse", "--verify", candidate],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            return run_git(["merge-base", candidate, head_ref])
    fail(f"Could not resolve base ref `{base_ref}` or `origin/{base_ref}`")
    return ""


def parse_changed_files(base_sha: str, head_ref: str) -> list[tuple[str, str]]:
    output = run_git(["diff", "--name-status", f"{base_sha}...{head_ref}"])
    changed: list[tuple[str, str]] = []
    for line in output.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        code = status[0]
        if code == "R" and len(parts) >= 3:
            path = parts[2]
        elif len(parts) >= 2:
            path = parts[1]
        else:
            continue
        changed.append((code, path))
    return changed


def starts_with_any(path: str, roots: list[str]) -> bool:
    return any(path.startswith(root) for root in roots)


def has_shim_marker(path: Path, marker: str) -> bool:
    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        return False
    return marker in content


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Block new legacy-path code unless explicitly marked as migration shim "
            "or allowlisted."
        )
    )
    parser.add_argument(
        "--config",
        default=str(DEFAULT_CONFIG),
        help="Path to guard config JSON.",
    )
    parser.add_argument(
        "--base-ref",
        default=os.environ.get("GITHUB_BASE_REF", "main"),
        help="Base branch/ref for diff (default: GITHUB_BASE_REF or main).",
    )
    parser.add_argument(
        "--head-ref",
        default="HEAD",
        help="Head ref for diff (default: HEAD).",
    )
    args = parser.parse_args()

    config_path = Path(args.config)
    config = load_config(config_path)

    legacy_roots = config.get("legacy_roots", [])
    allowlisted = set(config.get("allowlisted_legacy_paths", []))
    strict_blocked_roots = config.get("strict_blocked_roots", [])
    shim_marker = str(config.get("shim_marker", "MIGRATION_SHIM:"))
    shim_extensions = set(config.get("shim_extensions", [".dart"]))

    if not isinstance(legacy_roots, list) or not legacy_roots:
        fail("Config must include non-empty `legacy_roots` list.")
    if not isinstance(strict_blocked_roots, list):
        fail("Config `strict_blocked_roots` must be a list when provided.")

    base_sha = get_diff_base(args.base_ref, args.head_ref)
    changed = parse_changed_files(base_sha, args.head_ref)

    violations: list[str] = []
    legacy_touches: list[str] = []

    for code, rel in changed:
        rel = rel.replace("\\", "/")
        if not starts_with_any(rel, legacy_roots):
            continue
        if rel in allowlisted:
            continue

        legacy_touches.append(f"{code}:{rel}")
        if code == "D":
            # Deleting legacy files is allowed and desirable.
            continue

        if starts_with_any(rel, strict_blocked_roots):
            violations.append(
                f"{rel} (strict blocked legacy root: only deletion is allowed)"
            )
            continue

        abs_path = ROOT / rel
        ext = abs_path.suffix
        if ext in shim_extensions and has_shim_marker(abs_path, shim_marker):
            continue

        if code == "A":
            violations.append(
                f"{rel} (new legacy file must be target-path placement or include shim marker `{shim_marker}`)"
            )
        else:
            violations.append(
                f"{rel} (legacy file change requires shim marker `{shim_marker}` or allowlist entry)"
            )

    if violations:
        fail(
            "Detected disallowed legacy-path additions/changes:\n"
            + "\n".join(f"- {v}" for v in sorted(set(violations)))
            + "\n\nAllowed patterns:\n"
            + "1) Move code to target roots (`apps/`, `runtime/`, `engine/`, `shared/`).\n"
            + f"2) Temporary shim in legacy path with marker `{shim_marker}`.\n"
            + f"3) Add explicit temporary exception to {config_path.as_posix()}."
        )

    if legacy_touches:
        print("LEGACY-PATH GUARD: Legacy paths touched (allowed):")
        for item in sorted(legacy_touches):
            print(f"- {item}")
    else:
        print("LEGACY-PATH GUARD: No legacy-path changes in this diff.")

    print("LEGACY-PATH GUARD: OK")


if __name__ == "__main__":
    main()
