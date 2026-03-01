#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] REST smoke test (no Flutter)"
dart run scripts/supabase/test_supabase_connection.dart || {
  echo "REST smoke failed (non-fatal). Continuing..." >&2
}

echo "[2/3] Verify Supabase setup (tables, buckets, policies)"
dart run scripts/supabase/verify_supabase_setup.dart

echo "[3/3] Flutter smoke test (optional if env present)"
if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ANON_KEY:-}" ]]; then
  flutter test test/ci/supabase_flutter_smoke_test.dart
else
  echo "SUPABASE_URL or SUPABASE_ANON_KEY not set; skipping Flutter smoke"
fi

echo "✅ All Supabase checks complete"


