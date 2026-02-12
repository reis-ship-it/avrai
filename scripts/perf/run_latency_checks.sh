#!/usr/bin/env bash
set -euo pipefail

# Usage:
# BASE=https://YOUR-PROJECT.supabase.co/functions/v1 \
# SERVICE_ROLE=YOUR_SERVICE_ROLE_JWT \
# SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
# k6 run scripts/perf/k6_api_latency.js
# k6 run scripts/perf/k6_realtime_latency.js

if ! command -v k6 >/dev/null 2>&1; then
  echo "k6 not found. Install from https://k6.io/docs/get-started/installation/" >&2
  exit 1
fi

BASE=${BASE:-""}
SUPABASE_URL=${SUPABASE_URL:-""}
SERVICE_ROLE=${SERVICE_ROLE:-""}
ANON_KEY=${ANON_KEY:-""}

if [[ -z "$BASE" && -z "$SUPABASE_URL" ]]; then
  echo "Set BASE (functions URL) or SUPABASE_URL (project URL) env vars." >&2
  exit 1
fi

echo "Running k6 API latency test..."
VUS=${VUS:-5} ITERATIONS=${ITERATIONS:-20} \
BASE="$BASE" SUPABASE_URL="$SUPABASE_URL" SERVICE_ROLE="$SERVICE_ROLE" ANON_KEY="$ANON_KEY" \
  k6 run scripts/perf/k6_api_latency.js || true

echo
echo "Running k6 Realtime latency test..."
VUS=${VUS:-1} ITERATIONS=${ITERATIONS:-3} \
SUPABASE_URL="$SUPABASE_URL" SUPABASE_REALTIME_URL=${SUPABASE_REALTIME_URL:-"$SUPABASE_URL"} \
ANON_KEY="$ANON_KEY" SERVICE_ROLE="$SERVICE_ROLE" \
  k6 run scripts/perf/k6_realtime_latency.js || true

echo "Done. Review p(95)/p(99) and thresholds above."


