-- Migration: Named locality membership views + city rollups (v1)
-- Created: 2026-01-02
-- Purpose:
-- - Expose fuzzy locality membership field as per-cell rows
-- - Provide stable_key -> top-N localities lookup RPC
-- - Provide city rollups that include explicit unassigned/unknown mass
-- - Provide optional primary-city scoping variant for dual city tracking

-- 0) Allow authenticated reads of aggregated boundary fields (non-identifying, global priors).
ALTER TABLE public.geo_federated_boundary_aggregates_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read geo boundary aggregates" ON public.geo_federated_boundary_aggregates_v1;
CREATE POLICY "Authenticated can read geo boundary aggregates"
  ON public.geo_federated_boundary_aggregates_v1
  FOR SELECT
  TO authenticated
  USING (true);

-- 1) View: per-cell locality membership rows
CREATE OR REPLACE VIEW public.geo_locality_memberships_by_cell_v1 AS
SELECT
  a.city_code,
  a.locality_code,
  a.geohash_precision,
  e.key::text AS geohash,
  (e.value)::double precision AS p_inside,
  a.sample_count,
  a.updated_at
FROM public.geo_federated_boundary_aggregates_v1 a,
LATERAL jsonb_each_text(a.cell_probs) AS e
WHERE e.key IS NOT NULL;

COMMENT ON VIEW public.geo_locality_memberships_by_cell_v1 IS
  'Fuzzy locality membership field expanded to per-cell rows (v1).';

-- 2) RPC: stable_key -> top-N locality candidates
CREATE OR REPLACE FUNCTION public.geo_get_top_localities_for_stable_key_v1(
  p_stable_key text,
  p_top_n integer default 3,
  p_min_p double precision default 0.10
)
RETURNS TABLE (
  stable_key text,
  locality_code text,
  p_inside double precision,
  city_code text,
  geohash_precision integer
)
LANGUAGE sql
STABLE
AS $$
  with cell as (
    select
      g.stable_key,
      g.geohash_prefix as geohash,
      g.geohash_precision
    from public.locality_agent_global_v1 g
    where g.stable_key = p_stable_key
    limit 1
  )
  select
    c.stable_key,
    m.locality_code,
    m.p_inside,
    m.city_code,
    m.geohash_precision
  from cell c
  join public.geo_locality_memberships_by_cell_v1 m
    on m.geohash = c.geohash
   and m.geohash_precision = c.geohash_precision
  where m.p_inside >= p_min_p
  order by m.p_inside desc
  limit greatest(p_top_n, 1);
$$;

REVOKE ALL ON FUNCTION public.geo_get_top_localities_for_stable_key_v1(text, integer, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_get_top_localities_for_stable_key_v1(text, integer, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_get_top_localities_for_stable_key_v1(text, integer, double precision) TO service_role;

COMMENT ON FUNCTION public.geo_get_top_localities_for_stable_key_v1(text, integer, double precision) IS
  'Return top-N locality membership candidates for a stable geohash cell (v1).';

-- 3) City rollup: locality breakdown + explicit unassigned/unknown bucket
CREATE OR REPLACE FUNCTION public.geo_city_vibe_rollup_v1(
  p_city_code text,
  p_geohash_precision integer default 7,
  p_threshold double precision default 0.60,
  p_days_back integer default 30
)
RETURNS TABLE (
  city_code text,
  locality_code text, -- null means unassigned/unknown
  weight_mass double precision,
  vector12 jsonb,
  cell_count integer
)
LANGUAGE sql
STABLE
AS $$
  with cells as (
    select
      g.stable_key,
      g.geohash_prefix as geohash,
      g.geohash_precision,
      g.vector12,
      g.updated_at
    from public.locality_agent_global_v1 g
    where g.city_code = p_city_code
      and g.geohash_precision = p_geohash_precision
      and g.updated_at >= now() - (greatest(p_days_back, 1) || ' days')::interval
  ),
  probs as (
    select
      c.stable_key,
      m.locality_code,
      m.p_inside
    from cells c
    join public.geo_locality_memberships_by_cell_v1 m
      on m.geohash = c.geohash
     and m.geohash_precision = c.geohash_precision
     and m.city_code = p_city_code
    where m.p_inside >= p_threshold
  ),
  sum_p as (
    select
      stable_key,
      least(1.0, sum(p_inside)) as assigned_mass,
      sum(p_inside) as raw_sum_p
    from probs
    group by stable_key
  ),
  weights as (
    -- Locality weights within assigned mass
    select
      p_city_code as city_code,
      p.locality_code,
      c.stable_key,
      c.vector12,
      (p.p_inside / nullif(sp.raw_sum_p, 0.0)) * sp.assigned_mass as weight
    from cells c
    join probs p on p.stable_key = c.stable_key
    join sum_p sp on sp.stable_key = c.stable_key

    union all

    -- Unassigned remainder per cell
    select
      p_city_code as city_code,
      null::text as locality_code,
      c.stable_key,
      c.vector12,
      greatest(0.0, 1.0 - coalesce(sp.assigned_mass, 0.0)) as weight
    from cells c
    left join sum_p sp on sp.stable_key = c.stable_key
  ),
  dims as (
    -- Expand each weighted cell contribution into (idx, weighted_value)
    select
      w.city_code,
      w.locality_code,
      idx,
      sum(w.weight * (w.vector12 ->> (idx - 1))::double precision) as weighted_sum
    from weights w
    cross join generate_series(1, 12) as idx
    group by w.city_code, w.locality_code, idx
  ),
  assembled as (
    select
      d.city_code,
      d.locality_code,
      jsonb_agg(d.weighted_sum order by d.idx) as vector12
    from dims d
    group by d.city_code, d.locality_code
  ),
  masses as (
    select
      w.city_code,
      w.locality_code,
      sum(w.weight) as weight_mass,
      (select count(*) from cells)::int as cell_count
    from weights w
    group by w.city_code, w.locality_code
  )
  select
    a.city_code,
    a.locality_code,
    m.weight_mass,
    a.vector12,
    m.cell_count
  from assembled a
  join masses m
    on m.city_code = a.city_code
   and (m.locality_code is not distinct from a.locality_code)
  order by m.weight_mass desc;
$$;

REVOKE ALL ON FUNCTION public.geo_city_vibe_rollup_v1(text, integer, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_rollup_v1(text, integer, double precision, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_rollup_v1(text, integer, double precision, integer) TO service_role;

COMMENT ON FUNCTION public.geo_city_vibe_rollup_v1(text, integer, double precision, integer) IS
  'City rollup: locality-weighted contributions + explicit unassigned bucket (v1).';

-- 4) Convenience RPC: returns one city vector combining locality + unassigned rows
CREATE OR REPLACE FUNCTION public.geo_city_vibe_total_v1(
  p_city_code text,
  p_geohash_precision integer default 7,
  p_threshold double precision default 0.60,
  p_days_back integer default 30,
  p_default_value double precision default 0.5
)
RETURNS TABLE (
  city_code text,
  vector12 jsonb,
  cell_count integer
)
LANGUAGE sql
STABLE
AS $$
  with idx as (
    select generate_series(1, 12) as i
  ),
  roll as (
    select * from public.geo_city_vibe_rollup_v1(
      p_city_code,
      p_geohash_precision,
      p_threshold,
      p_days_back
    )
  ),
  base as (
    select
      p_city_code as city_code,
      coalesce(max(r.cell_count), 0) as cell_count
    from roll r
  ),
  sums as (
    select
      i.i as idx,
      coalesce(sum((r.vector12 ->> (i.i - 1))::double precision), 0.0) as weighted_sum
    from idx i
    left join roll r on true
    group by i.i
  ),
  assembled as (
    select
      b.city_code,
      b.cell_count,
      case
        when b.cell_count > 0
          then jsonb_agg((s.weighted_sum / b.cell_count) order by s.idx)
        else jsonb_agg(p_default_value order by s.idx)
      end as vector12
    from base b
    join sums s on true
    group by b.city_code, b.cell_count
  )
  select a.city_code, a.vector12, a.cell_count
  from assembled a;
$$;

REVOKE ALL ON FUNCTION public.geo_city_vibe_total_v1(text, integer, double precision, integer, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_total_v1(text, integer, double precision, integer, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_total_v1(text, integer, double precision, integer, double precision) TO service_role;

COMMENT ON FUNCTION public.geo_city_vibe_total_v1(text, integer, double precision, integer, double precision) IS
  'Convenience: return one city vector by combining locality + unassigned rows (v1).';

-- 5) Optional “primary city” scoping views + rollup variant
CREATE OR REPLACE VIEW public.geo_primary_city_by_stable_key_v1 AS
SELECT
  m.stable_key,
  m.reported_city_code,
  m.inferred_city_code,
  m.primary_city_code,
  m.updated_at
FROM public.geo_area_cluster_memberships_v1 m;

COMMENT ON VIEW public.geo_primary_city_by_stable_key_v1 IS
  'Projection of primary_city_code = COALESCE(inferred_city_code, reported_city_code, city_code) by stable_key (v1).';

CREATE OR REPLACE VIEW public.locality_agent_cells_by_primary_city_v1 AS
SELECT
  g.stable_key,
  g.geohash_prefix as geohash,
  g.geohash_precision,
  g.vector12,
  coalesce(p.primary_city_code, g.city_code) as primary_city_code,
  p.reported_city_code,
  p.inferred_city_code,
  g.updated_at
FROM public.locality_agent_global_v1 g
LEFT JOIN public.geo_primary_city_by_stable_key_v1 p
  ON p.stable_key = g.stable_key;

COMMENT ON VIEW public.locality_agent_cells_by_primary_city_v1 IS
  'Locality agent cell vectors annotated with primary_city_code (v1).';

CREATE OR REPLACE FUNCTION public.geo_city_vibe_total_by_primary_city_v1(
  p_city_code text,
  p_geohash_precision integer default 7,
  p_threshold double precision default 0.60,
  p_days_back integer default 30,
  p_default_value double precision default 0.5
)
RETURNS TABLE (
  city_code text,
  vector12 jsonb,
  cell_count integer
)
LANGUAGE sql
STABLE
AS $$
  with idx as (
    select generate_series(1, 12) as i
  ),
  cells as (
    select
      c.stable_key,
      c.geohash,
      c.geohash_precision,
      c.vector12,
      c.updated_at
    from public.locality_agent_cells_by_primary_city_v1 c
    where c.primary_city_code = p_city_code
      and c.geohash_precision = p_geohash_precision
      and c.updated_at >= now() - (greatest(p_days_back, 1) || ' days')::interval
  ),
  probs as (
    select
      c.stable_key,
      m.locality_code,
      m.p_inside
    from cells c
    join public.geo_locality_memberships_by_cell_v1 m
      on m.geohash = c.geohash
     and m.geohash_precision = c.geohash_precision
     and m.city_code = p_city_code
    where m.p_inside >= p_threshold
  ),
  sum_p as (
    select
      stable_key,
      least(1.0, sum(p_inside)) as assigned_mass,
      sum(p_inside) as raw_sum_p
    from probs
    group by stable_key
  ),
  weights as (
    -- Locality weights within assigned mass
    select
      p_city_code as city_code,
      p.locality_code,
      c.stable_key,
      c.vector12,
      (p.p_inside / nullif(sp.raw_sum_p, 0.0)) * sp.assigned_mass as weight
    from cells c
    join probs p on p.stable_key = c.stable_key
    join sum_p sp on sp.stable_key = c.stable_key

    union all

    -- Unassigned remainder per cell
    select
      p_city_code as city_code,
      null::text as locality_code,
      c.stable_key,
      c.vector12,
      greatest(0.0, 1.0 - coalesce(sp.assigned_mass, 0.0)) as weight
    from cells c
    left join sum_p sp on sp.stable_key = c.stable_key
  ),
  base as (
    select
      p_city_code as city_code,
      (select count(*) from cells)::int as cell_count
  ),
  sums as (
    select
      i.i as idx,
      coalesce(sum(w.weight * (w.vector12 ->> (i.i - 1))::double precision), 0.0) as weighted_sum
    from idx i
    left join weights w on true
    group by i.i
  ),
  assembled as (
    select
      b.city_code,
      b.cell_count,
      case
        when b.cell_count > 0
          then jsonb_agg((s.weighted_sum / b.cell_count) order by s.idx)
        else jsonb_agg(p_default_value order by s.idx)
      end as vector12
    from base b
    join sums s on true
    group by b.city_code, b.cell_count
  )
  select a.city_code, a.vector12, a.cell_count
  from assembled a;
$$;

REVOKE ALL ON FUNCTION public.geo_city_vibe_total_by_primary_city_v1(text, integer, double precision, integer, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_total_by_primary_city_v1(text, integer, double precision, integer, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_city_vibe_total_by_primary_city_v1(text, integer, double precision, integer, double precision) TO service_role;

COMMENT ON FUNCTION public.geo_city_vibe_total_by_primary_city_v1(text, integer, double precision, integer, double precision) IS
  'Convenience: return one city vector using primary_city_code scoping (v1).';

