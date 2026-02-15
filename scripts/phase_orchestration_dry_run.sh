#!/usr/bin/env bash
set -euo pipefail

CFG="docs/plans/master_plan_execution.yaml"
PHASE_ID="${1:-}"

if [[ -z "$PHASE_ID" ]]; then
  echo "Usage: $0 <phase_id>"
  exit 1
fi

if [[ ! -f "$CFG" ]]; then
  echo "ERROR: missing $CFG"
  exit 1
fi

if ! [[ "$PHASE_ID" =~ ^[0-9]+$ ]]; then
  echo "ERROR: phase_id must be numeric"
  exit 1
fi

deps="$(awk -v id="$PHASE_ID" '
  $1=="-" && $2=="id:" && $3==id {in_phase=1; next}
  in_phase && $1=="-" && $2=="id:" {in_phase=0}
  in_phase && $1=="depends_on:" {
    gsub(/depends_on:[[:space:]]*/, "", $0)
    gsub(/[[:space:]]/, "", $0)
    print $0
    exit
  }
' "$CFG")"

mp_ref="$(awk -v id="$PHASE_ID" '
  $1=="-" && $2=="id:" && $3==id {in_phase=1; next}
  in_phase && $1=="-" && $2=="id:" {in_phase=0}
  in_phase && $1=="master_plan_ref:" {
    sub(/^[[:space:]]*master_plan_ref:[[:space:]]*/, "", $0)
    gsub(/"/, "", $0)
    print $0
    exit
  }
' "$CFG")"

backlog_scope="$(awk -v id="$PHASE_ID" '
  $1=="-" && $2=="id:" && $3==id {in_phase=1; next}
  in_phase && $1=="-" && $2=="id:" {in_phase=0}
  in_phase && $1=="backlog_scope:" {
    sub(/^[[:space:]]*backlog_scope:[[:space:]]*/, "", $0)
    gsub(/"/, "", $0)
    print $0
    exit
  }
' "$CFG")"

gate="$(awk -v id="$PHASE_ID" '
  $1=="-" && $2=="id:" && $3==id {in_phase=1; next}
  in_phase && $1=="-" && $2=="id:" {in_phase=0}
  in_phase && $1=="checklist_gate:" {
    sub(/^[[:space:]]*checklist_gate:[[:space:]]*/, "", $0)
    gsub(/"/, "", $0)
    print $0
    exit
  }
' "$CFG")"

if [[ -z "$mp_ref" ]]; then
  echo "ERROR: phase '$PHASE_ID' not found in $CFG"
  exit 1
fi

echo "Phase orchestration dry run"
echo "phase_id: $PHASE_ID"
echo "master_plan_ref: $mp_ref"
echo "backlog_scope: $backlog_scope"
echo "checklist_gate: $gate"
echo "depends_on: ${deps:-[]}"
echo "required_docs:"
awk '/^[[:space:]]*- path:[[:space:]]/ {print "  - "$3}' "$CFG" | awk '!seen[$0]++'
