#!/usr/bin/env python3
import csv
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPING_CSV = ROOT / "docs" / "plans" / "architecture" / "generated" / "codebase_master_plan_mapping_2026-02-15.csv"
REGISTRY_CSV = ROOT / "docs" / "plans" / "architecture" / "ARCHITECTURE_SPOTS_REGISTRY.csv"

TRACK_PREFIXES = (
    "lib/", "packages/", "native/", "scripts/", "supabase/", "test/", "tool/",
    "assets/", "android/", "ios/", "macos/", "linux/", "windows/", "web/"
)


def tracked_files() -> list[str]:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    files = [line.strip() for line in out.splitlines() if line.strip()]
    return [f for f in files if f.startswith(TRACK_PREFIXES)]


def derive_spot(path: str) -> str:
    p = path.split("/")
    if path.startswith("lib/core/services/") and len(p) >= 5:
        return f"lib/core/services/{p[3]}"
    if path.startswith("lib/core/") and len(p) >= 4:
        return f"lib/core/{p[2]}"
    if path.startswith("lib/presentation/") and len(p) >= 4:
        return f"lib/presentation/{p[2]}"
    if path.startswith("lib/data/") and len(p) >= 4:
        return f"lib/data/{p[2]}"
    if path.startswith("lib/domain/") and len(p) >= 4:
        return f"lib/domain/{p[2]}"
    if path.startswith("lib/"):
        if len(p) >= 2 and p[1].endswith(".dart"):
            return "lib/_root"
        if len(p) >= 2:
            return f"lib/{p[1]}"
    if path.startswith("packages/") and len(p) >= 2:
        return f"packages/{p[1]}"
    if path.startswith("native/") and len(p) >= 2:
        return f"native/{p[1]}"
    if path.startswith("test/") and len(p) >= 4:
        return f"test/{p[1]}/{p[2]}"
    if path.startswith("test/"):
        return "test/_root"
    if path.startswith("scripts/") and len(p) >= 3:
        return f"scripts/{p[1]}"
    if path.startswith("scripts/"):
        return "scripts/_root"
    if path.startswith("supabase/") and len(p) >= 2:
        return f"supabase/{p[1]}"
    if path.startswith("tool/") and len(p) >= 2:
        return f"tool/{p[1]}"
    if path.startswith("assets/") and len(p) >= 2:
        return f"assets/{p[1]}"
    if p and p[0] in {"android", "ios", "macos", "linux", "windows", "web"}:
        return f"{p[0]}/{p[1]}" if len(p) >= 2 else f"{p[0]}/_root"
    return "unknown/_root"


def read_mapping() -> dict[str, tuple[str, str]]:
    if not MAPPING_CSV.exists():
        raise SystemExit(f"Missing mapping CSV: {MAPPING_CSV}")
    result = {}
    with MAPPING_CSV.open() as f:
        for row in csv.DictReader(f):
            result[row["file"]] = (row["domain"], row["phase_refs"])
    return result


def main() -> None:
    files = tracked_files()
    mapping = read_mapping()

    spot_files: defaultdict[str, list[str]] = defaultdict(list)
    spot_domain_counts: defaultdict[str, Counter] = defaultdict(Counter)
    spot_phase_counts: defaultdict[str, Counter] = defaultdict(Counter)

    for f in files:
        spot = derive_spot(f)
        spot_files[spot].append(f)
        domain, phase_refs = mapping.get(f, ("unknown", ""))
        if domain:
            spot_domain_counts[spot][domain] += 1
        if phase_refs:
            spot_phase_counts[spot][phase_refs] += 1

    rows = []
    for spot in sorted(spot_files):
        rows.append({
            "spot_key": spot,
            "file_count": str(len(spot_files[spot])),
            "primary_domain": spot_domain_counts[spot].most_common(1)[0][0] if spot_domain_counts[spot] else "unknown",
            "phase_refs": spot_phase_counts[spot].most_common(1)[0][0] if spot_phase_counts[spot] else "",
            "status": "active",
            "notes": "architecture spot for file placement",
        })

    with REGISTRY_CSV.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["spot_key", "file_count", "primary_domain", "phase_refs", "status", "notes"])
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
