-- Migration: Geo area clustering + split/merge evolution (v1)
-- Created: 2026-01-02
-- Purpose:
-- - Derive evolving “areas” from stable geohash-prefix cells (implicit from usage)
-- - Preserve continuity via stable component hashing (reuse area_id when cluster unchanged)
-- - Record split/merge events for correctness and auditability

-- This is intentionally keyed to *stable* geohash identities (from locality agents),
-- while `area_id` is a dynamic overlay that can evolve as new users/data arrive.

-- 0) Tables

CREATE TABLE IF NOT EXISTS public.geo_area_cluster_runs_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_code TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  mapping_version INTEGER NOT NULL,
  days_back INTEGER NOT NULL DEFAULT 30,
  min_samples INTEGER NOT NULL DEFAULT 3,
  cell_count INTEGER NOT NULL DEFAULT 0,
  cluster_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_runs_v1_city_precision_created_at
  ON public.geo_area_cluster_runs_v1(city_code, geohash_precision, created_at DESC);

ALTER TABLE public.geo_area_cluster_runs_v1 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role can manage geo area cluster runs" ON public.geo_area_cluster_runs_v1;
CREATE POLICY "Service role can manage geo area cluster runs"
  ON public.geo_area_cluster_runs_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_cluster_runs_v1 IS
  'Audit log of geo area clustering rebuild runs (v1). Service role only.';

-- Component registry: maps a deterministic component hash to a reusable area_id.
CREATE TABLE IF NOT EXISTS public.geo_area_cluster_components_v1 (
  city_code TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  component_hash TEXT NOT NULL, -- sha256(sorted stable_keys)
  area_id UUID NOT NULL DEFAULT gen_random_uuid(),
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (city_code, geohash_precision, component_hash)
);

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_components_v1_area_id
  ON public.geo_area_cluster_components_v1(area_id);

ALTER TABLE public.geo_area_cluster_components_v1 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role can manage geo area cluster components" ON public.geo_area_cluster_components_v1;
CREATE POLICY "Service role can manage geo area cluster components"
  ON public.geo_area_cluster_components_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_cluster_components_v1 IS
  'Registry mapping deterministic component hashes to reusable area_ids (v1). Service role only.';

-- Current membership mapping (stable_key → area overlay)
CREATE TABLE IF NOT EXISTS public.geo_area_cluster_memberships_v1 (
  stable_key TEXT PRIMARY KEY, -- gh7:dr5regw
  city_code TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  component_hash TEXT NOT NULL,
  area_id UUID NOT NULL,
  mapping_version INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_memberships_v1_city_precision_area
  ON public.geo_area_cluster_memberships_v1(city_code, geohash_precision, area_id);

ALTER TABLE public.geo_area_cluster_memberships_v1 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated can read geo area cluster memberships" ON public.geo_area_cluster_memberships_v1;
CREATE POLICY "Authenticated can read geo area cluster memberships"
  ON public.geo_area_cluster_memberships_v1
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Service role can manage geo area cluster memberships" ON public.geo_area_cluster_memberships_v1;
CREATE POLICY "Service role can manage geo area cluster memberships"
  ON public.geo_area_cluster_memberships_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_cluster_memberships_v1 IS
  'Current mapping from stable geohash keys to evolving area_id overlays (v1).';

-- Split/merge event log
CREATE TABLE IF NOT EXISTS public.geo_area_cluster_events_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_code TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  mapping_version INTEGER NOT NULL,
  event_type TEXT NOT NULL, -- split|merge
  old_area_ids UUID[] NOT NULL DEFAULT ARRAY[]::uuid[],
  new_area_ids UUID[] NOT NULL DEFAULT ARRAY[]::uuid[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_events_v1_city_precision_created_at
  ON public.geo_area_cluster_events_v1(city_code, geohash_precision, created_at DESC);

ALTER TABLE public.geo_area_cluster_events_v1 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role can manage geo area cluster events" ON public.geo_area_cluster_events_v1;
CREATE POLICY "Service role can manage geo area cluster events"
  ON public.geo_area_cluster_events_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_cluster_events_v1 IS
  'Split/merge events emitted by geo area clustering rebuilds (v1). Service role only.';

-- 1) Rebuild function (service role)
--
-- Implementation:
-- - Select eligible geohash cells from locality_agent_global_v1
-- - Create cell polygons via ST_GeomFromGeoHash
-- - Cluster touching/intersecting polygons via ST_ClusterDBSCAN(eps=0, minpoints=1)
-- - Compute deterministic component_hash = sha256(sorted stable_keys)
-- - Upsert component registry to reuse area_id for unchanged clusters
-- - Rewrite memberships for city/precision and log split/merge events
CREATE OR REPLACE FUNCTION public.geo_area_cluster_rebuild_v1(
  p_city_code TEXT,
  p_geohash_precision INTEGER DEFAULT 7,
  p_days_back INTEGER DEFAULT 30,
  p_min_samples INTEGER DEFAULT 3
)
RETURNS BIGINT AS $$
DECLARE
  v_mapping_version INTEGER;
  v_clusters BIGINT := 0;
BEGIN
  IF p_city_code IS NULL OR length(p_city_code) = 0 THEN
    RAISE EXCEPTION 'p_city_code is required';
  END IF;

  IF p_geohash_precision < 3 OR p_geohash_precision > 9 THEN
    RAISE EXCEPTION 'p_geohash_precision out of range (3..9)';
  END IF;

  v_mapping_version :=
    COALESCE((
      SELECT MAX(r.mapping_version)
      FROM public.geo_area_cluster_runs_v1 r
      WHERE r.city_code = p_city_code
        AND r.geohash_precision = p_geohash_precision
    ), 0) + 1;

  -- Snapshot old mapping for split/merge diffing.
  WITH old_map AS (
    SELECT stable_key, area_id AS old_area_id
    FROM public.geo_area_cluster_memberships_v1
    WHERE city_code = p_city_code
      AND geohash_precision = p_geohash_precision
  ),
  eligible AS (
    SELECT
      g.stable_key,
      g.geohash_prefix,
      g.geohash_precision,
      g.city_code,
      g.sample_count,
      g.updated_at,
      ST_GeomFromGeoHash(g.geohash_prefix) AS geom
    FROM public.locality_agent_global_v1 g
    WHERE g.city_code = p_city_code
      AND g.geohash_precision = p_geohash_precision
      AND g.sample_count >= GREATEST(p_min_samples, 1)
      AND g.updated_at >= NOW() - (GREATEST(p_days_back, 1) || ' days')::interval
  ),
  clustered AS (
    SELECT
      e.stable_key,
      e.geohash_prefix,
      e.geohash_precision,
      e.city_code,
      e.geom,
      ST_ClusterDBSCAN(e.geom, 0.0, 1) OVER () AS cluster_id
    FROM eligible e
  ),
  components AS (
    SELECT
      c.cluster_id,
      c.city_code,
      c.geohash_precision,
      ARRAY_AGG(c.stable_key ORDER BY c.stable_key) AS stable_keys,
      COUNT(*)::int AS cell_count
    FROM clustered c
    GROUP BY c.cluster_id, c.city_code, c.geohash_precision
  ),
  hashed AS (
    SELECT
      city_code,
      geohash_precision,
      encode(
        digest(array_to_string(stable_keys, ','), 'sha256'),
        'hex'
      ) AS component_hash,
      stable_keys,
      cell_count
    FROM components
  ),
  up_components AS (
    INSERT INTO public.geo_area_cluster_components_v1(
      city_code, geohash_precision, component_hash, area_id, first_seen_at, last_seen_at
    )
    SELECT
      h.city_code,
      h.geohash_precision,
      h.component_hash,
      gen_random_uuid(),
      NOW(),
      NOW()
    FROM hashed h
    ON CONFLICT (city_code, geohash_precision, component_hash) DO UPDATE SET
      last_seen_at = NOW()
    RETURNING city_code, geohash_precision, component_hash, area_id
  ),
  resolved_components AS (
    SELECT
      h.city_code,
      h.geohash_precision,
      h.component_hash,
      COALESCE(uc.area_id, c.area_id) AS area_id,
      h.stable_keys,
      h.cell_count
    FROM hashed h
    LEFT JOIN up_components uc
      ON uc.city_code = h.city_code
     AND uc.geohash_precision = h.geohash_precision
     AND uc.component_hash = h.component_hash
    LEFT JOIN public.geo_area_cluster_components_v1 c
      ON c.city_code = h.city_code
     AND c.geohash_precision = h.geohash_precision
     AND c.component_hash = h.component_hash
  ),
  new_map AS (
    SELECT
      sk AS stable_key,
      rc.city_code,
      rc.geohash_precision,
      rc.component_hash,
      rc.area_id
    FROM resolved_components rc,
    LATERAL unnest(rc.stable_keys) AS sk
  ),
  rewritten AS (
    DELETE FROM public.geo_area_cluster_memberships_v1 m
    WHERE m.city_code = p_city_code
      AND m.geohash_precision = p_geohash_precision
    RETURNING 1
  ),
  inserted AS (
    INSERT INTO public.geo_area_cluster_memberships_v1(
      stable_key, city_code, geohash_precision, component_hash, area_id, mapping_version, updated_at
    )
    SELECT
      n.stable_key,
      n.city_code,
      n.geohash_precision,
      n.component_hash,
      n.area_id,
      v_mapping_version,
      NOW()
    FROM new_map n
    ON CONFLICT (stable_key) DO UPDATE SET
      city_code = EXCLUDED.city_code,
      geohash_precision = EXCLUDED.geohash_precision,
      component_hash = EXCLUDED.component_hash,
      area_id = EXCLUDED.area_id,
      mapping_version = EXCLUDED.mapping_version,
      updated_at = NOW()
    RETURNING 1
  ),
  splits AS (
    SELECT
      o.old_area_id,
      array_agg(DISTINCT n.area_id) AS new_area_ids
    FROM old_map o
    JOIN new_map n ON n.stable_key = o.stable_key
    GROUP BY o.old_area_id
    HAVING COUNT(DISTINCT n.area_id) > 1
  ),
  merges AS (
    SELECT
      n.area_id AS new_area_id,
      array_agg(DISTINCT o.old_area_id) AS old_area_ids
    FROM new_map n
    JOIN old_map o ON o.stable_key = n.stable_key
    GROUP BY n.area_id
    HAVING COUNT(DISTINCT o.old_area_id) > 1
  ),
  log_splits AS (
    INSERT INTO public.geo_area_cluster_events_v1(
      city_code, geohash_precision, mapping_version, event_type, old_area_ids, new_area_ids
    )
    SELECT
      p_city_code,
      p_geohash_precision,
      v_mapping_version,
      'split',
      ARRAY[s.old_area_id],
      s.new_area_ids
    FROM splits s
    RETURNING 1
  ),
  log_merges AS (
    INSERT INTO public.geo_area_cluster_events_v1(
      city_code, geohash_precision, mapping_version, event_type, old_area_ids, new_area_ids
    )
    SELECT
      p_city_code,
      p_geohash_precision,
      v_mapping_version,
      'merge',
      m.old_area_ids,
      ARRAY[m.new_area_id]
    FROM merges m
    RETURNING 1
  ),
  run AS (
    INSERT INTO public.geo_area_cluster_runs_v1(
      city_code, geohash_precision, mapping_version, days_back, min_samples, cell_count, cluster_count
    )
    SELECT
      p_city_code,
      p_geohash_precision,
      v_mapping_version,
      p_days_back,
      p_min_samples,
      (SELECT COUNT(*) FROM eligible)::int,
      (SELECT COUNT(*) FROM resolved_components)::int
    RETURNING 1
  )
  SELECT COUNT(*)::bigint INTO v_clusters FROM resolved_components;

  RETURN v_clusters;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER) TO service_role;

COMMENT ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER)
IS 'Rebuild geo area clusters (split/merge aware) from locality_agent_global_v1 cells (v1). Service role only.';

