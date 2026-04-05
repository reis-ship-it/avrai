#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STACK_DIR="$PROJECT_ROOT/infrastructure/admin_private_control_plane"

echo "=========================================="
echo "Verify Admin Private Control Plane"
echo "=========================================="

if [ ! -f "$STACK_DIR/.env" ]; then
  echo "❌ Missing $STACK_DIR/.env"
  exit 1
fi

set -a
source "$STACK_DIR/.env"
set +a

GATEWAY_PORT="${ADMIN_CONTROL_PLANE_PORT:-7443}"
BROKER_PORT="${RESEARCH_EGRESS_BROKER_PORT:-8091}"
OPA_URL="${ADMIN_CONTROL_PLANE_OPA_URL:-http://127.0.0.1:8181}"
SUPABASE_REST_URL="${SUPABASE_URL%/}/rest/v1"

if ! command -v curl >/dev/null 2>&1; then
  echo "❌ curl is required"
  exit 1
fi

echo ""
echo "Checking compose services..."
docker compose -f "$STACK_DIR/docker-compose.yml" ps

echo ""
echo "Checking gateway health..."
curl -fsS "http://127.0.0.1:${GATEWAY_PORT}/health" >/dev/null
echo "✅ gateway healthy"

echo ""
echo "Checking broker health..."
curl -fsS "http://127.0.0.1:${BROKER_PORT}/health" >/dev/null
echo "✅ broker healthy"

echo ""
echo "Checking OPA health..."
curl -fsS "${OPA_URL%/}/health?plugins" >/dev/null
echo "✅ OPA healthy"

if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo ""
  echo "Checking required Supabase tables..."
  for table in \
    admin_research_runs \
    admin_control_plane_sessions \
    admin_control_plane_audit_events \
    admin_control_plane_policy_decisions \
    admin_research_quarantined_payloads; do
    curl -fsS \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
      "${SUPABASE_REST_URL}/${table}?select=id&limit=1" >/dev/null
    echo "✅ ${table}"
  done
else
  echo ""
  echo "⚠️  Skipping Supabase REST verification because SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing."
fi

echo ""
echo "✅ Verification complete"
