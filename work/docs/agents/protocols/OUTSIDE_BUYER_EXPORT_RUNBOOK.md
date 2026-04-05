# Outside Buyer Export Runbook (spots_insights_v1)

**Scope:** Outside data buyers only (strictest privacy tier)  
**Contract:** `docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md`  
**Status:** Active (v1 implemented; runbook covers deploy + ops)

---

## What this runbook is for

This is the operational “how to ship and run it” guide for the **outside-buyer insights** pipeline:

- Deploy DB + Edge Function
- Issue outside-buyer API keys
- Generate a **real** export slice that’s contract-compliant
- Monitor budgets and defend against intersection attacks
- Rotate/revoke keys if needed

---

## Non‑negotiables (outside buyers)

- **No stable identifiers** in exports (no `user_id`, `agent_id`, `ai_signature`, device IDs, IPs, session IDs)
- **No trajectories** or joinable traces
- **≥72h delay**
- **k-min + dominance suppression**
- **DP noise + privacy budget accounting**
- **Stable releases**: cached DP releases; repeated requests return the same release (no recompute churn)

## Supported release granularities (cached)

- **day** (default): 72h delay, k-min 100, epsilon 0.5, budget cost 0.5 per day-bucket release
- **week**: 72h delay, k-min 100, epsilon 0.5, budget cost 0.5 per week-bucket release
- **hour** (stricter): 168h delay, k-min 300, epsilon 0.25, budget cost 0.25 per hour-bucket release
  - Hour is intentionally harder to query (smaller max range, fewer filter dimensions).

---

## Implementation map (where the system lives)

### Database (Supabase / Postgres)
- **Initial DP export + budgeting**: `supabase/migrations/030_outside_buyer_insights_v1.sql`
- **Precompute + cache**: `supabase/migrations/031_outside_buyer_insights_cache_v1.sql`
- **Intersection hardening + monitoring**: `supabase/migrations/032_outside_buyer_intersection_hardening_and_monitoring.sql`
- **Hour/week + city_code buckets**: `supabase/migrations/034_outside_buyer_hour_week_and_city_buckets.sql`
- **Security cleanup (remove plaintext mapping dependency)**: `supabase/migrations/035_interaction_events_userid_rls_and_drop_plain_mappings.sql`
- **Scheduled precompute (pg_cron)**: `supabase/migrations/036_outside_buyer_precompute_cron.sql`
- **City-code population pipeline**: `supabase/migrations/037_city_code_population_pipeline.sql`
- **Ops dashboards + cron alerts**: `supabase/migrations/038_outside_buyer_ops_dashboards_and_alerts.sql`
- **Atomic clock server-time RPC**: `supabase/migrations/039_atomic_clock_server_time_rpc.sql`
- **Atomic clock server-time RPC (anon)**: `supabase/migrations/044_atomic_clock_server_time_rpc_anon.sql`
- **Atomic timing policy registry**: `supabase/migrations/040_atomic_timing_policies_v1.sql`
- **Outside-buyer precompute policy hook**: `supabase/migrations/041_outside_buyer_precompute_policy_hook.sql`
- **Geo hierarchy localities registry**: `supabase/migrations/042_geo_hierarchy_localities_v1.sql`
- **Geo hierarchy authenticated read RPCs**: `supabase/migrations/043_geo_hierarchy_public_read_rpcs.sql`
- **Geo hierarchy place-code lookups**: `supabase/migrations/045_geo_lookup_place_codes_v1.sql`
- **Geo locality map shapes (polygons)**: `supabase/migrations/047_geo_locality_shapes_v1.sql`

Key tables/views/functions:
- `public.outside_buyer_privacy_budgets`
- `public.outside_buyer_insights_v1_cache`
- `public.outside_buyer_insights_v1_cache_runs`
- `public.outside_buyer_query_fingerprints`
- `public.city_geohash3_map` (geo bucket mapping for `city_code`)
- `public.city_definitions` (inputs for city-code population)
- `public.geo_localities_v1` (expert geo hierarchy: city → locality → neighborhood)
- `public.atomic_timing_policies_v1` (policy registry; drives cron behavior)
- `public.outside_buyer_privacy_budget_usage_v1` (view)
- `public.outside_buyer_export_request_stats_v1` (view)
- `public.outside_buyer_query_fingerprint_stats_v1` (view)
- `public.outside_buyer_cron_jobs_v1` (view)
- `public.outside_buyer_cache_run_freshness_v1` (view)
- `public.outside_buyer_city_code_coverage_v1` (view)
- `public.outside_buyer_get_spots_insights_v1_cached(...)` (RPC used by Edge Function)
- `public.outside_buyer_run_scheduled_precompute_v1_policy()` (cron entrypoint; reads atomic timing policy)
- `public.geo_list_cities_v1()` / `public.geo_list_city_localities_v1(p_city_code)` (authenticated read for geo hierarchy UI/cache)
- `public.geo_lookup_city_code_v1(...)` / `public.geo_lookup_locality_code_v1(...)` (place name → codes)
- `public.geo_get_locality_shape_geojson_v1(...)` (locality polygon GeoJSON for maps)

### Edge Function
- **Function name:** `outside-buyer-insights`
- **Code:** `supabase/functions/outside-buyer-insights/index.ts`

### Atomic Timing Orchestrator (Option B)

- **Function name:** `atomic-timing-orchestrator`
- **Code:** `supabase/functions/atomic-timing-orchestrator/index.ts`
- **Auth:** `verify_jwt = false` + requires `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`

### Defense-in-depth validation (app/test)
- Validator: `lib/core/services/outside_buyer/outside_buyer_insights_v1_validator.dart`
- Tests: `test/unit/services/outside_buyer_insights_v1_validator_test.dart`

---

## Deployment (production Supabase)

### 1) Apply migrations

Apply DB migrations including:
- `030_outside_buyer_insights_v1.sql`
- `031_outside_buyer_insights_cache_v1.sql`
- `032_outside_buyer_intersection_hardening_and_monitoring.sql`
- `034_outside_buyer_hour_week_and_city_buckets.sql`
- `035_interaction_events_userid_rls_and_drop_plain_mappings.sql`
- `036_outside_buyer_precompute_cron.sql`
- `037_city_code_population_pipeline.sql`
- `038_outside_buyer_ops_dashboards_and_alerts.sql`
- `039_atomic_clock_server_time_rpc.sql`
- `040_atomic_timing_policies_v1.sql`
- `041_outside_buyer_precompute_policy_hook.sql`
- `042_geo_hierarchy_localities_v1.sql`
- `043_geo_hierarchy_public_read_rpcs.sql`

### 2) Deploy Edge Function

Deploy `outside-buyer-insights` with service role access.

### 3) Verify required base tables exist

The pipeline assumes these already exist (from earlier migrations):
- `public.api_keys` + `public.api_request_logs` (Phase 21 infra)
- `public.audit_logs`
- `public.interaction_events`
- `public.spots` (optional: only for category enrichment)

---

## Issuing an outside-buyer API key

### Requirements
- `api_keys.partner_id` **must start with** `outside_buyer_` (enforced in Edge Function).

### Recommended issuance (SQL)
Use the existing helper function created for API keys:

```sql
select public.generate_api_key('outside_buyer_acme');
```

Store the returned plaintext API key securely (it is not recoverable from the hash).

---

## Calling the endpoint

### Endpoint
- `POST /functions/v1/outside-buyer-insights`
- `GET /functions/v1/outside-buyer-insights?...`

### Required headers
- `Authorization: Bearer <API_KEY>`

### Minimal POST request body

```json
{
  "time_bucket_start_utc": "2025-12-20T00:00:00Z",
  "time_bucket_end_utc": "2025-12-21T00:00:00Z"
}
```

### Optional filters (bounded)
- `geo_bucket_ids` (max 50)
- `door_types`
- `categories`
- `contexts`

### Important operational notes
- Cached releases support: **hour/day/week** (see “Supported release granularities” above).
- **End time must be ≥72h old** (enforced).
- Query shape budget is enforced via **distinct query fingerprints/day** (intersection defense).
- **Hour** is stricter: requires `geo_bucket_type = city_code` and `geo_bucket_ids` scoped to city codes (max 10).

---

## Automated precompute (cron)

### What runs automatically

Migration `036_outside_buyer_precompute_cron.sql` enables `pg_cron` and schedules:
- `cron.jobname = outside_buyer_precompute_v1_hourly`
- command: `select public.outside_buyer_run_scheduled_precompute_v1_policy();` (policy-driven)

### How to verify cron health

```sql
select *
from public.outside_buyer_cron_jobs_v1
where jobname = 'outside_buyer_precompute_v1_hourly';
```

### How to run precompute manually (service role)

```sql
select public.outside_buyer_run_scheduled_precompute_v1(
  p_include_hour := true,
  p_include_day := true,
  p_include_week := true
);
```

### How to adjust precompute behavior (policy)

The hourly cron entrypoint reads:
- `public.atomic_timing_policies_v1.policy_key = 'outside_buyer_precompute_v1'`

Update example (service role):

```sql
update public.atomic_timing_policies_v1
set payload = jsonb_set(payload, '{hour_buckets}', '12'::jsonb, true),
    updated_at = now()
where policy_key = 'outside_buyer_precompute_v1';
```

---

## City-code mapping operations

### Add / update a city bucket

```sql
select public.upsert_city_definition('us-la', 'Los Angeles', 34.0522, -118.2437, 45, 5);
select public.populate_city_geohash3_map_from_definitions();
```

### Inspect coverage

```sql
select *
from public.outside_buyer_city_code_coverage_v1;
```

---

## How to interpret results

Each returned element is a **single metric cell** row:
- `metrics.*_est` values are **DP-noised** estimates.
- If `privacy.suppressed = true`, metrics fields will be `null`.
- `privacy.dp.*` describes the mechanism and parameters used.

---

## Monitoring + alerting

### Privacy budget usage

Query:

```sql
select *
from public.outside_buyer_privacy_budget_usage_v1
order by updated_at desc;
```

### Export request/error rates

```sql
select *
from public.outside_buyer_export_request_stats_v1
order by day_utc desc;
```

### Intersection defense stats

```sql
select *
from public.outside_buyer_query_fingerprint_stats_v1
order by day_utc desc;
```

### Alerts

The Edge Function calls `outside_buyer_maybe_alert_budget(...)` on successful requests.
Alerts are written to `audit_logs` with:
- `type = 'outside_buyer_privacy_budget'`

---

## Key rotation / revocation

### Rotate
1. Issue a new key via `generate_api_key('outside_buyer_acme')`
2. Update the buyer’s integration to use the new key
3. Disable the old key:

```sql
update public.api_keys
set is_active = false
where partner_id = 'outside_buyer_acme'
  and is_active = true;
```

### Emergency revoke
Immediately set `is_active = false` for the compromised key row.

---

## Incident response (intersection attack / abuse)

Signals:
- Rapid growth in `outside_buyer_query_fingerprints` distinct count
- Frequent `QUERY_BUDGET_EXCEEDED` responses
- Budget burn far faster than expected

Actions:
- Revoke the key (above)
- Preserve evidence: export logs from `api_request_logs` + relevant `audit_logs`
- Consider raising the minimum aggregation level (fewer filter dimensions) temporarily

