#!/usr/bin/env bash
set -euo pipefail

CFG="docs/plans/master_plan_execution.yaml"

if [[ ! -f "$CFG" ]]; then
  echo "ERROR: missing $CFG"
  exit 1
fi

missing=0

# Validate all declared path refs exist.
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ ! -e "$path" ]]; then
    echo "ERROR: referenced path does not exist: $path"
    missing=$((missing+1))
  fi
done < <(awk '/^[[:space:]]*- path:[[:space:]]/ {print $3}' "$CFG")

# Validate phase IDs are exactly 1..N (contiguous, ordered).
mapfile_ids="$(awk '/^[[:space:]]*- id:[[:space:]]*[0-9]+/ {print $3}' "$CFG" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
phase_count="$(awk '/^[[:space:]]*- id:[[:space:]]*[0-9]+/ {n++} END {print n+0}' "$CFG")"
max_id="$(awk '/^[[:space:]]*- id:[[:space:]]*[0-9]+/ {last=$3} END {print last+0}' "$CFG")"
expected_ids="$(seq 1 "$phase_count" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
if [[ "$phase_count" -eq 0 || "$max_id" -ne "$phase_count" || "$mapfile_ids" != "$expected_ids" ]]; then
  echo "ERROR: phase IDs in $CFG are not exactly 1..N in order"
  echo "Found:    $mapfile_ids"
  echo "Expected: $expected_ids"
  missing=$((missing+1))
fi

# Ensure each phase has required contract keys.
for key in master_plan_ref backlog_scope checklist_gate; do
  count="$(awk -v key="$key" '
    /^[[:space:]]*- id:[[:space:]]*[0-9]+/ {phase=1}
    phase && $1 ~ (key ":") {hits++}
    END {print hits+0}
  ' "$CFG")"
  if [[ "$count" -lt "$phase_count" ]]; then
    echo "ERROR: key '$key' is missing in one or more phase_build_contracts entries"
    missing=$((missing+1))
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Validation failed with $missing error(s)."
  exit 1
fi

echo "master_plan_execution.yaml validation passed."
