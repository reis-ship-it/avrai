#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
STACK_DIR="$PROJECT_ROOT/work/infrastructure/admin_private_control_plane"

echo "=========================================="
echo "Deploy Admin Private Control Plane"
echo "=========================================="

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker is required"
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "❌ supabase CLI is required"
  exit 1
fi

if [ ! -f "$STACK_DIR/.env" ]; then
  echo "❌ Missing $STACK_DIR/.env"
  echo "   Copy $STACK_DIR/.env.example to .env and fill in real values first."
  exit 1
fi

echo ""
echo "Applying governed autoresearch migrations..."
cd "$PROJECT_ROOT/work/supabase"
supabase db push

echo ""
echo "Starting private control-plane stack..."
cd "$STACK_DIR"
docker compose up --build -d

echo ""
echo "Running readiness verification..."
"$PROJECT_ROOT/work/scripts/verify_admin_private_control_plane.sh"

echo ""
echo "✅ Admin private control plane deployed"
