## Geo Area Evolution (v1) — SQL validation queries

Purpose: quick “smoke” queries to validate **area evolution correctness** and **dual city tracking** after applying migrations and running `geo_area_cluster_rebuild_v1(...)`.

### Preconditions
- Migrations applied:
  - `supabase/migrations/062_geo_area_cluster_evolution_v1.sql`
  - `supabase/migrations/064_geo_area_cluster_dual_city_tracking_v1.sql`
  - `supabase/migrations/065_geo_area_cluster_rebuild_expansion_from_seed_v1.sql`
- Data exists in `public.locality_agent_global_v1` with `geohash_precision=7` and `sample_count >= 3`.

### 1) Sanity: latest run + recent events

```sql
select *
from public.geo_area_cluster_runs_v1
order by created_at desc
limit 10;
```

```sql
select *
from public.geo_area_cluster_events_v1
order by created_at desc
limit 50;
```

### 2) Determinism (best-effort): run twice, diff membership mapping

This uses temp tables because `geo_area_cluster_memberships_v1` stores the **latest** mapping only.

```sql
-- Pick a seed city code (example: 'nyc') and precision.
create temp table _map_before as
select stable_key, area_id, component_hash, primary_city_code, reported_city_code, inferred_city_code
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7;

-- Rebuild
select public.geo_area_cluster_rebuild_v1('nyc', 7, 30, 3);

create temp table _map_after as
select stable_key, area_id, component_hash, primary_city_code, reported_city_code, inferred_city_code
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7;

-- Show diffs (should be empty if the input dataset is unchanged).
select
  coalesce(a.stable_key, b.stable_key) as stable_key,
  b.area_id as before_area_id,
  a.area_id as after_area_id,
  b.component_hash as before_component_hash,
  a.component_hash as after_component_hash
from _map_after a
full join _map_before b using (stable_key)
where a.area_id is distinct from b.area_id
   or a.component_hash is distinct from b.component_hash
order by stable_key
limit 200;
```

### 3) Dual city tracking: coverage and disagreements

```sql
select
  count(*) as total,
  count(*) filter (where reported_city_code is not null) as has_reported,
  count(*) filter (where inferred_city_code is not null) as has_inferred,
  count(*) filter (
    where reported_city_code is not null
      and inferred_city_code is not null
      and reported_city_code is distinct from inferred_city_code
  ) as disagreements
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7;
```

```sql
select
  stable_key,
  reported_city_code,
  inferred_city_code,
  primary_city_code,
  updated_at
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7
  and reported_city_code is not null
  and inferred_city_code is not null
  and reported_city_code is distinct from inferred_city_code
order by updated_at desc
limit 100;
```

### 4) Cross-city merges: find area_ids spanning multiple primary cities

```sql
select
  area_id,
  count(*) as cell_count,
  count(distinct primary_city_code) as primary_city_count,
  array_agg(distinct primary_city_code) as primary_cities
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7
group by area_id
having count(distinct primary_city_code) > 1
order by primary_city_count desc, cell_count desc
limit 50;
```

### 5) Per-city view stability: slice by primary city

```sql
select
  primary_city_code,
  count(*) as cell_count
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7
group by primary_city_code
order by cell_count desc;
```

```sql
-- Inspect the current mapping for a specific city (example: 'nyc')
select
  stable_key,
  area_id,
  component_hash,
  reported_city_code,
  inferred_city_code,
  primary_city_code,
  updated_at
from public.geo_area_cluster_memberships_v1
where geohash_precision = 7
  and primary_city_code = 'nyc'
order by updated_at desc
limit 200;
```

