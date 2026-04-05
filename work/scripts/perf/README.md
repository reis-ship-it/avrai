SPOTS Latency Checkup Toolkit

This folder contains ready-to-run scripts to measure latency across Supabase Edge Functions and Realtime.

Prereqs
- Install k6: https://k6.io/docs/get-started/installation/
- Environment variables:
  - BASE = https://YOUR-PROJECT.supabase.co/functions/v1
  - SUPABASE_URL = https://YOUR-PROJECT.supabase.co
  - SERVICE_ROLE (preferred) or ANON_KEY

Quick start
  cd scripts/perf
  bash run_latency_checks.sh

Direct commands
  BASE=... SERVICE_ROLE=... k6 run scripts/perf/k6_api_latency.js
  SUPABASE_URL=... ANON_KEY=... k6 run scripts/perf/k6_realtime_latency.js

Env knobs
- VUS (default 1), ITERATIONS (default 1)
- ROOM_NICHE, ROOM_TOPIC, PAYLOAD_BYTES for API test
- REALTIME_CHANNEL (default ai2ai-network), DURATION_MS for WS test

DB -> Realtime E2E probe (optional)
- Migration supabase/migrations/009_latency_probe.sql creates public.latency_probe and publishes it to supabase_realtime.
- Insert a row via REST with send_ts in payload; subscribe to table via Realtime to compute end-to-end.

Apply migration
  SUPABASE_DB_PASSWORD=... supabase db push --yes

Reading results
- k6 prints p50/p95/p99 for metrics; thresholds fail the run if breached.
- Start point: API p95 < 400ms per op (create/join/post); Realtime: handshake p95 < 400ms; ping RTT p95 < 250ms same region

