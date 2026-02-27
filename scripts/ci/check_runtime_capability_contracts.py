#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CAP_DIR = ROOT / "configs" / "runtime" / "capabilities"

EXPECTED_FILES = ("ios", "android", "macos", "windows", "linux", "web")
REQUIRED_TOP_LEVEL = ("os", "coexisting_runtime_os", "contract_version", "degradation_tier", "capabilities")
REQUIRED_CAPS = (
    "ble",
    "wifi_direct",
    "p2p_mesh",
    "background_execution",
    "local_model_inference",
    "secure_storage",
    "notifications",
    "deep_linking",
)
VALID_BACKGROUND = ("full", "restricted", "none")
VALID_TIERS = ("full", "standard", "minimal")


def fail(msg: str) -> None:
    print(f"RUNTIME CAPABILITY CONTRACT CHECK FAILED: {msg}")
    sys.exit(1)


def load_json(path: Path) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Invalid JSON in {path}: {exc}")
    if not isinstance(raw, dict):
        fail(f"Contract must be an object: {path}")
    return raw


def validate_contract(os_name: str, contract: dict, path: Path) -> None:
    for key in REQUIRED_TOP_LEVEL:
        if key not in contract:
            fail(f"Missing `{key}` in {path}")

    if contract["os"] != os_name:
        fail(f"`os` mismatch in {path}: expected `{os_name}`")

    if not isinstance(contract["coexisting_runtime_os"], bool):
        fail(f"`coexisting_runtime_os` must be boolean in {path}")

    if not isinstance(contract["contract_version"], str) or not contract["contract_version"].strip():
        fail(f"`contract_version` must be non-empty string in {path}")

    if contract["degradation_tier"] not in VALID_TIERS:
        fail(f"`degradation_tier` invalid in {path}: {contract['degradation_tier']}")

    caps = contract["capabilities"]
    if not isinstance(caps, dict):
        fail(f"`capabilities` must be object in {path}")

    for key in REQUIRED_CAPS:
        if key not in caps:
            fail(f"Missing capability `{key}` in {path}")

    bool_caps = ("ble", "wifi_direct", "p2p_mesh", "local_model_inference", "secure_storage", "notifications", "deep_linking")
    for key in bool_caps:
        if not isinstance(caps[key], bool):
            fail(f"`capabilities.{key}` must be boolean in {path}")

    if caps["background_execution"] not in VALID_BACKGROUND:
        fail(
            f"`capabilities.background_execution` invalid in {path}: {caps['background_execution']}",
        )


def main() -> None:
    if not CAP_DIR.exists():
        fail(f"Missing capability contracts dir: {CAP_DIR}")

    for os_name in EXPECTED_FILES:
        path = CAP_DIR / f"{os_name}.json"
        if not path.exists():
            fail(f"Missing runtime capability contract: {path}")
        contract = load_json(path)
        validate_contract(os_name, contract, path)

    print("OK: Runtime capability contracts are valid for all supported OS targets.")


if __name__ == "__main__":
    main()
