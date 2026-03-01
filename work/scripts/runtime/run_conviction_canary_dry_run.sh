#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DART_BIN="/opt/homebrew/Caskroom/flutter/3.32.6/flutter/bin/cache/dart-sdk/bin/dart"

INPUT_PATH="configs/runtime/conviction_gate_canary_dry_run_fixture.json"
OUTPUT_MD="docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.md"
OUTPUT_JSON="docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.json"

cd "$ROOT_DIR"

python3 scripts/runtime/check_conviction_canary_dry_run_fixture.py
HOME=/tmp "$DART_BIN" run tool/export_conviction_shadow_telemetry.dart \
  --input "$INPUT_PATH" \
  --output "$OUTPUT_MD" \
  --summary-out "$OUTPUT_JSON"
HOME=/tmp "$DART_BIN" run tool/export_conviction_shadow_telemetry.dart --check \
  --input "$INPUT_PATH" \
  --output "$OUTPUT_MD" \
  --summary-out "$OUTPUT_JSON"

python3 - <<'PY'
import json
from pathlib import Path
p = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.json")
d = json.loads(p.read_text())
print("Canary Dry-Run KPIs")
print(f"- total_decisions: {d.get('total_decisions', 0)}")
print(f"- shadow_bypass_rate: {d.get('shadow_bypass_rate', 0.0)*100:.2f}% ({d.get('shadow_bypass_decisions', 0)}/{d.get('total_decisions', 0)})")
print(f"- enforce_block_rate: {d.get('enforce_block_rate', 0.0)*100:.2f}% ({d.get('enforce_blocked_decisions', 0)}/{d.get('enforce_decisions', 0)})")
print(f"- high_impact_enforce_block_rate: {d.get('high_impact_enforce_block_rate', 0.0)*100:.2f}% ({d.get('high_impact_enforce_blocked_decisions', 0)}/{d.get('high_impact_enforce_decisions', 0)})")
print(f"- top_reason_codes: {', '.join(list((d.get('by_reason') or {}).keys())[:3]) or 'none'}")
PY
