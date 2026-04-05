from __future__ import annotations

import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
WORK_ROOT = REPO_ROOT / "work"

# The placement guard should enforce the actively owned code and tooling roots.
PLACEMENT_TRACK_PREFIXES = (
    "apps/",
    "runtime/",
    "engine/",
    "shared/",
    "work/scripts/",
    "work/tools/",
    "work/supabase/",
)

# The registry is broader because the execution board and architecture docs
# reference supporting spots beyond the strict placement-guard scope.
REGISTRY_TRACK_PREFIXES = (
    "apps/",
    "runtime/",
    "engine/",
    "shared/",
    "work/configs/",
    "work/design/",
    "work/docs/",
    "work/examples/",
    "work/infrastructure/",
    "work/integration_test/",
    "work/release_artifacts/",
    "work/scripts/",
    "work/tools/",
    "work/supabase/",
)

LEGACY_BOARD_ALIASES = {
    "lib/_root": (
        "legacy-monolith-root",
        "10.10,10.2",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/ai": (
        "legacy-world-model-core",
        "1,3,6",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/ai2ai": (
        "legacy-ai2ai-core",
        "3.7,8",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/cloud": (
        "legacy-cloud-integration",
        "11,9.2.6",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/controllers": (
        "legacy-workflow-controllers",
        "7,10.1",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/ml": (
        "legacy-ml-transition",
        "4,5,10.8.1",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/models": (
        "legacy-core-models",
        "3.1,3.4",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services": (
        "legacy-core-services",
        "1,2,7,9,10",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/admin": (
        "legacy-admin-services",
        "10.9.22,10.9.25",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/business": (
        "legacy-business-services",
        "9,10.1",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/expertise": (
        "legacy-expertise-services",
        "4.3,9",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/locality_agents": (
        "legacy-locality-services",
        "3.5,8.9",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/quantum": (
        "legacy-quantum-services",
        "5,8,11.4",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/security": (
        "legacy-security-services",
        "2.1,2.5",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/core/services/user": (
        "legacy-user-services",
        "1.2,10.1",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
    "lib/presentation": (
        "legacy-presentation",
        "10.1,10.3,10.4",
        "legacy alias retained for historical execution-board compatibility after 3-prong migration",
    ),
}


def tracked_files(prefixes: tuple[str, ...]) -> list[str]:
    out = subprocess.check_output(["git", "ls-files"], cwd=REPO_ROOT, text=True)
    files = [line.strip() for line in out.splitlines() if line.strip()]
    return [
        path
        for path in files
        if path.startswith(prefixes) and (REPO_ROOT / path).exists()
    ]


def normalize_path(path: str) -> str:
    if path.startswith("work/configs/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/design/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/docs/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/examples/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/infrastructure/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/integration_test/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/release_artifacts/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/scripts/"):
        return path.replace("work/", "", 1)
    if path.startswith("work/tools/"):
        return path.replace("work/", "", 1).replace("tools/", "tool/", 1)
    if path.startswith("work/supabase/"):
        return path.replace("work/", "", 1)
    return path


def derive_spot(path: str) -> str:
    logical_path = normalize_path(path)
    parts = logical_path.split("/")

    if logical_path.startswith("apps/") and len(parts) >= 2:
        if len(parts) >= 4 and parts[2] == "configs" and parts[3] == "runtime":
            return f"apps/{parts[1]}/configs/runtime"
        if len(parts) >= 4 and parts[2] == "configs":
            return f"apps/{parts[1]}/configs/{parts[3]}"
        return f"apps/{parts[1]}"

    if logical_path.startswith("runtime/") and len(parts) >= 2:
        return f"runtime/{parts[1]}"

    if logical_path.startswith("engine/") and len(parts) >= 2:
        return f"engine/{parts[1]}"

    if logical_path.startswith("shared/") and len(parts) >= 2:
        return f"shared/{parts[1]}"

    if logical_path.startswith("configs/"):
        return f"configs/{parts[1]}" if len(parts) >= 3 else "configs/_root"

    if logical_path.startswith("design/") and len(parts) >= 2:
        return f"design/{parts[1]}"

    if logical_path.startswith("docs/plans/architecture/"):
        return "docs/plans/architecture"

    if logical_path.startswith("docs/"):
        return "docs"

    if logical_path.startswith("examples/") and len(parts) >= 2:
        return f"examples/{parts[1]}"

    if logical_path.startswith("infrastructure/") and len(parts) >= 2:
        return f"infrastructure/{parts[1]}"

    if logical_path.startswith("integration_test/"):
        return "integration_test/_root"

    if logical_path.startswith("scripts/") and len(parts) >= 3:
        return f"scripts/{parts[1]}"

    if logical_path.startswith("scripts/"):
        return "scripts/_root"

    if logical_path.startswith("supabase/") and len(parts) >= 3:
        return f"supabase/{parts[1]}"

    if logical_path.startswith("supabase/"):
        return "supabase/_root"

    if logical_path.startswith("tool/") and len(parts) >= 3:
        return f"tool/{parts[1]}"

    if logical_path.startswith("tool/"):
        return "tool/_root"

    if logical_path.startswith("release_artifacts/") and len(parts) >= 2:
        return f"release_artifacts/{parts[1]}"

    if logical_path.startswith("assets/") and len(parts) >= 2:
        return f"assets/{parts[1]}"

    if logical_path.startswith("lib/core/services/") and len(parts) >= 5:
        return f"lib/core/services/{parts[3]}"

    if logical_path.startswith("lib/core/") and len(parts) >= 4:
        return f"lib/core/{parts[2]}"

    if logical_path.startswith("lib/presentation/") and len(parts) >= 4:
        return f"lib/presentation/{parts[2]}"

    if logical_path.startswith("lib/data/") and len(parts) >= 4:
        return f"lib/data/{parts[2]}"

    if logical_path.startswith("lib/domain/") and len(parts) >= 4:
        return f"lib/domain/{parts[2]}"

    if logical_path.startswith("lib/"):
        if len(parts) >= 2 and parts[1].endswith(".dart"):
            return "lib/_root"
        if len(parts) >= 2:
            return f"lib/{parts[1]}"

    if logical_path.startswith("packages/") and len(parts) >= 2:
        return f"packages/{parts[1]}"

    if logical_path.startswith("native/") and len(parts) >= 2:
        return f"native/{parts[1]}"

    if logical_path.startswith("test/") and len(parts) >= 4:
        return f"test/{parts[1]}/{parts[2]}"

    if logical_path.startswith("test/"):
        return "test/_root"

    if parts and parts[0] in {"android", "ios", "macos", "linux", "windows", "web"}:
        return f"{parts[0]}/{parts[1]}" if len(parts) >= 2 else f"{parts[0]}/_root"

    return "unknown/_root"
