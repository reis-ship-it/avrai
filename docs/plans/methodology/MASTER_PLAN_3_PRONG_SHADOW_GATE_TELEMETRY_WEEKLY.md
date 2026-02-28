# 3-Prong Shadow Gate Telemetry Weekly Export

**Status:** No runtime export available yet.
**Expected input:** `runtime_exports/conviction_gate_shadow_decisions.json`
**Summary JSON:** `docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_WEEKLY.json`
**Note:** Input file does not exist.

## How To Populate

1. Export persisted decisions from storage key `conviction_gate_shadow_decisions_v1` into JSON list format.
2. Save to the expected input path or pass `--input <path>` when running the exporter.
3. Run `dart run tool/export_conviction_shadow_telemetry.dart` to regenerate this report.
