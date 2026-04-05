#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

MODE="${1:-}"
if [[ "${MODE}" != "" && "${MODE}" != "--delete" && "${MODE}" != "--dry-run" ]]; then
  echo "Usage: $0 [--dry-run|--delete]" >&2
  exit 1
fi

if [[ "${MODE}" == "" ]]; then
  MODE="--dry-run"
fi

readonly RETAINED_FILES=(
  "runtime_exports/training_kernel/bham_2023_reality_model_datasets_episodes.jsonl"
  "runtime_exports/training_kernel/latest_replay_simulation_training_manifest.json"
  "runtime_exports/training_kernel/latest_training_kernel_state.json"
)

readonly DELETE_PATHS=(
  "runtime_exports/.DS_Store"
  "runtime_exports/local"
  "runtime_exports/recovery"
  "runtime_exports/replay_storage_staging"
  "runtime_exports/replay_storage_partitions"
  "runtime_exports/live_receipt_exports"
  "runtime_exports/conviction_gate_shadow_decisions.json"
  "runtime_exports/training_kernel/latest_batch_execution_result.json"
  "runtime_exports/training_kernel/latest_batch_execution_result.md"
  "runtime_exports/training_kernel/latest_replay_simulation_training_manifest.md"
  "runtime_exports/training_kernel/latest_replay_simulation_training_manifest_pre_closeout.json"
  "runtime_exports/training_kernel/latest_training_kernel_state.md"
)

print_size() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    du -sh "${path}" 2>/dev/null || true
  else
    echo "missing  ${path}"
  fi
}

echo "Retaining canonical training artifacts:"
for path in "${RETAINED_FILES[@]}"; do
  print_size "${path}"
done

echo
echo "Generated artifacts selected for cleanup:"
for path in "${DELETE_PATHS[@]}"; do
  print_size "${path}"
done

if [[ "${MODE}" == "--dry-run" ]]; then
  echo
  echo "Dry run only. Re-run with --delete to remove the generated artifacts."
  exit 0
fi

echo
echo "Deleting generated artifacts..."
for path in "${DELETE_PATHS[@]}"; do
  if [[ -e "${path}" ]]; then
    rm -rf "${path}"
  fi
done

echo
echo "Remaining runtime_exports contents:"
find runtime_exports -maxdepth 2 -mindepth 1 2>/dev/null | sort || true
