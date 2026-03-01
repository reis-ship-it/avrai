# Outside Data-Buyer Insights Data Contract (v1)

**Status:** Draft (policy + legal alignment required; v1 pipeline implemented in repo, pending deployment)  
**Audience:** External data buyers (research firms, consultancies, platforms)  
**Goal:** Enable SPOTS to sell **privacy-preserving aggregate insights** while remaining aligned with “Privacy and Control Are Non‑Negotiable” and the promise that SPOTS does **not** sell personal information.

---

## 1) What this contract is (and is not)

### ✅ This contract is
- A **technical and policy contract** describing exactly what SPOTS may provide to outside buyers.
- A **hard boundary**: exported data must be **aggregate-only**, **delayed**, **coarsened**, and **privacy-budgeted**.
- Compatible with any transport/security mode (including Mode 2 offline AI2AI). Mode 2 protects *peer learning and comms*; this contract protects *external monetization outputs*.

### ❌ This contract is not
- A promise to provide raw events, user-level records, “agent-level logs,” or precise locations.
- A method to target individuals, infer identities, or enable surveillance.

---

## 2) Non‑negotiable privacy guarantees (outside buyers)

### G1 — No personal data
The dataset MUST NOT contain:
- Any **direct identifiers**: name, email, phone, address, payment IDs, social handles.
- Any **stable per-person identifier**: `user_id`, `agent_id`, `ai_signature`, device IDs, ad IDs, IPs, session IDs.
- Any raw message content, freeform text, chat transcripts, or embeddings.

### G2 — No trajectories
The dataset MUST NOT contain:
- Location history, visited location lists, per-user sequences, per-agent “paths,” or joinable behavioral traces.
- Any event or record that can be trivially joined into a unique pattern (even without explicit IDs).

### G3 — Coarse + delayed
Outputs MUST be:
- **Coarse geo** (e.g., city or larger; **locality_code** for neighborhood/borough “near precise but not exact” is allowed with **stricter k-min**; or geohash precision that approximates city/large-neighborhood)
- **Coarse time** (hour/day/week; never minute-level)
- **Delayed** (default **≥ 72 hours**; configurable but never real-time for outside buyers)
- **Locality:** When `geo_bucket.type = 'locality_code'`, `geo_bucket.id` is a locality code (e.g. from `geo_localities_v1`). **k-min for locality_code MUST be ≥ 200** (stricter than city-level default).

### G4 — Cell suppression + thresholds
Any metric cell must satisfy:
- **k-min threshold**: minimum cohort size (default **k ≥ 100** unique participants contributing to that cell)
- **Dominance rules**: prevent a small number of entities dominating a cell (e.g., top contributor ≤ 5% of the cell, configurable)
- Suppress (or roll up) any cell that fails rules.

### G5 — Differential privacy (DP) for releases
All numeric outputs MUST be:
- Produced via DP mechanisms (Laplace/Gaussian) with published metadata:
  - epsilon, delta, mechanism, budget window
- Enforced privacy budget (query accounting). When budget is exceeded: deny or further aggregate.

---

## 3) Allowed outputs (what buyers can buy)

Outside buyers can buy only **aggregated insights**, e.g.:
- City-level trend indices (“trend_score”)
- Category-level demand signals (e.g., “coffee”, “live music”, “bookstores”)
- Time-bucketed aggregated engagement rates
- “Door type” performance: spots vs events vs communities (aggregate)
- Seasonality and day-of-week patterns (aggregate)

**No buyer receives a feed of “agents” or “people.”** Buyers receive **market-level signals** only.

---

## 4) Canonical dataset schema (v1)

### 4.1 Dataset identity
- **Dataset name:** `spots_insights_v1`
- **Delivery:** periodic files (e.g., daily) or API endpoint returning precomputed slices
- **Format:** JSON lines, Parquet, or CSV (depending on buyer); schema identical

### 4.2 Record schema (one row = one metric cell)

```json
{
  "schema_version": "1.0",
  "dataset": "spots_insights_v1",

  "time_bucket_start_utc": "2026-01-01T00:00:00Z",
  "time_granularity": "day",
  "reporting_delay_hours": 72,

  "geo_bucket": {
    "type": "city",
    "id": "us-nyc"
  },

  "segment": {
    "door_type": "spot|event|community",
    "category": "coffee|music|sports|art|food|outdoor|tech|community|other",
    "context": "morning|midday|evening|weekend|unknown"
  },

  "metrics": {
    "unique_participants_est": 12850,
    "doors_opened_est": 45120,
    "repeat_rate_est": 0.31,
    "trend_score_est": 0.74
  },

  "privacy": {
    "k_min_enforced": 100,
    "suppressed": false,
    "suppressed_reason": null,
    "dp": {
      "enabled": true,
      "mechanism": "laplace",
      "epsilon": 0.5,
      "delta": 1e-6,
      "budget_window_days": 30
    }
  }
}
```

### 4.3 Required invariants
- `geo_bucket.id` must never represent < city-scale for outside buyers.
- `unique_participants_est` is DP-noised and may be rounded.
- If `suppressed = true`, `metrics` fields may be omitted or set to null.

---

## 5) Forbidden fields & joins (explicit deny list)

### 5.1 Forbidden fields (hard)
Any appearance of these (or equivalents) is a contract violation:
- `user_id`, `agent_id`, `ai_signature`
- precise GPS: `latitude`, `longitude` (outside buyers)
- `location_history`, `visited_locations`, `current_location` (outside buyers)
- device identifiers: `device_id`, `advertising_id`, `ip_address`
- raw content: `message`, `text`, `transcript`, embeddings/vectors

### 5.2 Forbidden capabilities
Buyer must not be able to:
- Track an individual across time buckets or geo buckets
- Infer attendance at a specific event or venue by a specific person
- Run “micro-targeting” or “surveillance advertising”

---

## 6) Query policy (API or bespoke exports)

### 6.1 Allowed query dimensions (bounded)
- `time_bucket_start_utc` (bounded range; max 90 days per request)
- `geo_bucket` (city-level only; max N cities per request)
- `category`, `door_type`, `context` (enumerated only)

### 6.2 Disallowed query patterns
Automatically deny:
- Highly selective filters that would create small cohorts
- Too-fine time windows
- Too-fine geo areas
- “Intersection attacks” (repeated slicing to narrow a cohort)

### 6.3 Rate limits (outside buyers)
- Strict per-customer rate limits and query budgets
- “Privacy budget” enforced as a first-class quota

---

## 7) Retention, audit, and enforcement

### 7.1 Retention
- Buyer retention default: **12 months**
- After retention: delete or further aggregate (buyer attestation required)

### 7.2 Auditability
- SPOTS logs all exports and queries (who, when, what slice)
- Buyer provides periodic compliance attestations

### 7.3 Breach response
- If buyer violates policy: immediate termination, credential revocation, legal remedies

---

## 8) Relationship to business/admin/internal analytics

This contract is **stricter** than internal admin/business tooling.

**Important:** internal code currently treats `user_id` as “allowed” in admin contexts (see `AdminPrivacyFilter` and admin export). That is NOT acceptable for outside-buyer exports.

---

## 10) Implementation status (as of 2026-01-01)

**Repo implementation (v1 enforcement + ops hardening):**
- **DB migrations**:
  - `supabase/migrations/030_outside_buyer_insights_v1.sql`
    - Privacy budget accounting: `public.outside_buyer_privacy_budgets`
    - DP export RPC (legacy/on-demand): `public.outside_buyer_get_spots_insights_v1(...)` (service-role only)
  - `supabase/migrations/031_outside_buyer_insights_cache_v1.sql`
    - Stable releases via cache:
      - `public.outside_buyer_insights_v1_cache`
      - `public.outside_buyer_insights_v1_cache_runs`
    - Cached export RPC (used by Edge Function):
      - `public.outside_buyer_get_spots_insights_v1_cached(...)`
      - `public.outside_buyer_precompute_spots_insights_v1_day(...)`
    - **Geo coarsening:** `geohash3` / `city_code` (see 034 + 037)
    - **Granularity:** stable cached releases
  - `supabase/migrations/032_outside_buyer_intersection_hardening_and_monitoring.sql`
    - Intersection hardening:
      - `public.outside_buyer_query_fingerprints`
      - `public.outside_buyer_record_query_fingerprint(...)`
    - Monitoring:
      - `public.outside_buyer_privacy_budget_usage_v1` (view)
      - `public.outside_buyer_export_request_stats_v1` (view)
      - `public.outside_buyer_query_fingerprint_stats_v1` (view)
    - Budget alert helper:
      - `public.outside_buyer_maybe_alert_budget(...)` (writes to `audit_logs`)
  - `supabase/migrations/034_outside_buyer_hour_week_and_city_buckets.sql`
    - Adds cached **hour/day/week** releases (hour uses stricter defaults)
    - Adds `city_code` geo bucket type via `public.city_geohash3_map` (geohash3 → city code)
    - Extends cached RPC: `public.outside_buyer_get_spots_insights_v1_cached(...)` accepts `p_time_granularity`
  - `supabase/migrations/035_interaction_events_userid_rls_and_drop_plain_mappings.sql`
    - Removes `user_agent_mappings` plaintext dependency from `interaction_events` RLS (ownership via `user_id`)
  - `supabase/migrations/036_outside_buyer_precompute_cron.sql`
    - Enables `pg_cron` + schedules hourly cache precompute:
      - `public.outside_buyer_run_scheduled_precompute_v1(...)`
      - cron job: `outside_buyer_precompute_v1_hourly`
  - `supabase/migrations/037_city_code_population_pipeline.sql`
    - Adds `public.city_definitions` + population helpers:
      - `public.populate_city_geohash3_map_circle(...)`
      - `public.populate_city_geohash3_map_from_definitions()`
  - `supabase/migrations/038_outside_buyer_ops_dashboards_and_alerts.sql`
    - Ops dashboards + alerts:
      - `public.outside_buyer_cron_jobs_v1` (view)
      - `public.outside_buyer_cache_run_freshness_v1` (view)
      - `public.outside_buyer_city_code_coverage_v1` (view)
      - `public.outside_buyer_maybe_alert_cron_stale(...)` (writes to `audit_logs`)
  - `supabase/migrations/039_atomic_clock_server_time_rpc.sql`
    - Atomic clock helper RPC:
      - `public.get_server_time()` (used for client/server atomic time sync)
  - `supabase/migrations/044_atomic_clock_server_time_rpc_anon.sql`
    - Allows `anon` to call `public.get_server_time()` (startup sync before login)
  - `supabase/migrations/040_atomic_timing_policies_v1.sql`
    - Timing policy registry (drives scheduling behavior):
      - `public.atomic_timing_policies_v1`
      - `public.atomic_timing_get_policy_v1(...)`
  - `supabase/migrations/041_outside_buyer_precompute_policy_hook.sql`
    - Policy-driven cron entrypoint:
      - `public.outside_buyer_run_scheduled_precompute_v1_policy()`
  - `supabase/migrations/042_geo_hierarchy_localities_v1.sql`
    - Geo hierarchy mapping (expert system alignment):
      - `public.geo_localities_v1` (city → locality → neighborhood)
      - `public.geo_list_city_localities_v1(...)`
  - `supabase/migrations/043_geo_hierarchy_public_read_rpcs.sql`
    - Authenticated geo reads (UI/offline caching):
      - `public.geo_list_cities_v1()`
  - `supabase/migrations/045_geo_lookup_place_codes_v1.sql`
    - Place-name → code resolution (first-class geo):
      - `public.geo_lookup_city_code_v1(...)`
      - `public.geo_lookup_locality_code_v1(...)`
  - `supabase/migrations/046_geo_city_geohash3_bounds_v1.sql`
    - Map integration helper (city_code visualization):
      - `public.geo_list_city_geohash3_bounds_v1(...)`
  - `supabase/migrations/047_geo_locality_shapes_v1.sql`
    - Map integration helper (locality polygons):
      - `public.geo_locality_definitions_v1`
      - `public.geo_locality_shapes_v1`
      - `public.geo_get_locality_shape_geojson_v1(...)`
- **Edge function**: `supabase/functions/outside-buyer-insights/index.ts`
  - API-key auth via `public.api_keys` (outside-buyer scope enforced via `partner_id` prefix `outside_buyer_*`)
  - Uses cached release path: `outside_buyer_get_spots_insights_v1_cached`
  - Enforces: hour/day/week profiles, `city_code` or `geohash3`, contract-default DP + k-min parameters per granularity, query-fingerprint budget
  - Logs to `audit_logs` + `api_request_logs`
- **Edge function**: `supabase/functions/atomic-timing-orchestrator/index.ts`
  - Central job runner (Option B) for timing-driven backend execution
  - Intended to be invoked via Supabase Scheduled Edge Functions (cron)
- **Buyer export runbook**:
  - `docs/agents/protocols/OUTSIDE_BUYER_EXPORT_RUNBOOK.md`
- **Defense-in-depth validator + tests (Dart)**:
  - `lib/core/services/outside_buyer/outside_buyer_insights_v1_validator.dart`
  - `test/unit/services/outside_buyer_insights_v1_validator_test.dart`

**Deployment status (Supabase):**
- ✅ Migrations applied + Edge Function deployed to project `SPOTS_` (ref `nfzlwgbvezwwrutqpedy`)
- ✅ Sample export executed and deny-list verified (no stable identifiers in response)

## 9) Implementation checklist (engineering)

- [ ] Create a dedicated **OutsideBuyerExport** path (do not reuse admin export code).
- [ ] Enforce schema validation: **deny-list scan** + structural checks.
- [ ] Enforce k-min + dominance + suppression.
- [ ] Implement DP aggregation + budgeting + query accounting.
- [ ] Add 72h+ delay and bucket coarsening.
- [ ] Add automated red-team tests (re-identification attempts).

---

## Appendix A — Buyer tiers (all important, different strictness)

### A1) Outside data buyers (this doc)
**Strictest:** aggregate-only + DP + delayed + coarse geo/time + no stable IDs.

### A2) First-party businesses using SPOTS
Can be less strict *only for their own properties*, but still:
- no personal data
- no location histories per person
- strong access control + auditing

### A3) Partnerships (expert/business)
Operational dashboards can include more detail about the **partnership object**, but never expose attendee-level identity. Use aggregated outcomes.

