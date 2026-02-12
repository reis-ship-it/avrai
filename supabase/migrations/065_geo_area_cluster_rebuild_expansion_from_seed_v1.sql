-- Migration: Geo area clustering rebuild - expansion-from-seed behavior (v1)
-- Created: 2026-01-02
-- Purpose:
-- - Allow cross-city area continuity by clustering *across* city boundaries
-- - Preserve persistent per-city views via seed scoping + dual city tracking fields
-- - Reuse stable area_id via deterministic component_hash
-- - Log split/merge events for auditability

-- Global component registry (NOT keyed by city) so cross-city merges reuse the same area_id.
CREATE TABLE IF NOT EXISTS public.geo_area_cluster_components_global_v1 (
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  component_hash TEXT NOT NULL, -- sha256(sorted stable_keys)
  area_id UUID NOT NULL DEFAULT gen_random_uuid(),
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (geohash_precision, component_hash)
);

CREATE INDEX IF NOT EXISTS idx_geo_area_cluster_components_global_v1_area_id
  ON public.geo_area_cluster_components_global_v1(area_id);

ALTER TABLE public.geo_area_cluster_components_global_v1 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role can manage geo area cluster components global" ON public.geo_area_cluster_components_global_v1;
CREATE POLICY "Service role can manage geo area cluster components global"
  ON public.geo_area_cluster_components_global_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_cluster_components_global_v1 IS
  'Global registry mapping deterministic component hashes to reusable area_ids (v1). Service role only.';

-- Rebuild function (service role).
--
-- Key behavior:
-- - Seed scope is a city_code (per-city view stays persistent)
-- - Clustering runs across all eligible cells within the seed city geohash3 tiles
--   (tiles are larger than the city boundary, so this naturally captures cross-city neighbors)
-- - “Expansion-from-seed”: we keep only clusters that contain at least one seed-city cell,
--   but the cluster may include cells whose reported/inferred city differs.
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
  IF p_city_code IS NULL OR length(trim(p_city_code)) = 0 THEN
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

  -- Cluster + apply expansion-from-seed within the seed city's geohash3 tiles.
  WITH seed_tiles AS (
    SELECT m.geohash3_id
    FROM public.city_geohash3_map m
    WHERE m.city_code = p_city_code
  ),
  eligible AS (
    SELECT
      g.stable_key,
      g.geohash_prefix,
      g.geohash_precision,
      g.city_code AS reported_city_code,
      g.sample_count,
      g.updated_at,
      ST_GeomFromGeoHash(g.geohash_prefix) AS geom
    FROM public.locality_agent_global_v1 g
    WHERE g.geohash_precision = p_geohash_precision
      AND g.sample_count >= GREATEST(p_min_samples, 1)
      AND g.updated_at >= NOW() - (GREATEST(p_days_back, 1) || ' days')::interval
      AND left(g.geohash_prefix, 3) IN (SELECT geohash3_id FROM seed_tiles)
  ),
  clustered AS (
    SELECT
      e.stable_key,
      e.geohash_prefix,
      e.geohash_precision,
      e.reported_city_code,
      e.geom,
      ST_ClusterDBSCAN(e.geom, 0.0, 1) OVER () AS cluster_id
    FROM eligible e
  ),
  seed_cluster_ids AS (
    SELECT DISTINCT c.cluster_id
    FROM clustered c
    WHERE c.reported_city_code = p_city_code
  ),
  components AS (
    SELECT
      c.cluster_id,
      ARRAY_AGG(c.stable_key ORDER BY c.stable_key) AS stable_keys,
      COUNT(*)::int AS cell_count
    FROM clustered c
    WHERE c.cluster_id IN (SELECT cluster_id FROM seed_cluster_ids)
    GROUP BY c.cluster_id
  ),
  hashed AS (
    SELECT
      encode(
        digest(array_to_string(stable_keys, ','), 'sha256'),
        'hex'
      ) AS component_hash,
      stable_keys,
      cell_count
    FROM components
  ),
  up_components AS (
    INSERT INTO public.geo_area_cluster_components_global_v1(
      geohash_precision, component_hash, area_id, first_seen_at, last_seen_at
    )
    SELECT
      p_geohash_precision,
      h.component_hash,
      gen_random_uuid(),
      NOW(),
      NOW()
    FROM hashed h
    ON CONFLICT (geohash_precision, component_hash) DO UPDATE SET
      last_seen_at = NOW()
    RETURNING geohash_precision, component_hash, area_id
  ),
  resolved_components AS (
    SELECT
      h.component_hash,
      c.area_id,
      h.stable_keys,
      h.cell_count
    FROM hashed h
    JOIN public.geo_area_cluster_components_global_v1 c
      ON c.geohash_precision = p_geohash_precision
     AND c.component_hash = h.component_hash
  ),
  new_map AS (
    SELECT
      sk AS stable_key,
      p_geohash_precision AS geohash_precision,
      rc.component_hash,
      rc.area_id
    FROM resolved_components rc,
    LATERAL unnest(rc.stable_keys) AS sk
  ),
  old_map AS (
    SELECT m.stable_key, m.area_id AS old_area_id
    FROM public.geo_area_cluster_memberships_v1 m
    JOIN new_map n ON n.stable_key = m.stable_key
    WHERE m.geohash_precision = p_geohash_precision
  ),
  inferred_city AS (
    SELECT
      e.stable_key,
      m.city_code AS inferred_city_code
    FROM eligible e
    LEFT JOIN public.city_geohash3_map m
      ON m.geohash3_id = left(e.geohash_prefix, 3)
  ),
  upserted AS (
    INSERT INTO public.geo_area_cluster_memberships_v1(
      stable_key,
      city_code,
      geohash_precision,
      component_hash,
      area_id,
      mapping_version,
      updated_at,
      reported_city_code,
      inferred_city_code
    )
    SELECT
      n.stable_key,
      COALESCE(ic.inferred_city_code, e.reported_city_code, p_city_code) AS city_code,
      n.geohash_precision,
      n.component_hash,
      n.area_id,
      v_mapping_version,
      NOW(),
      e.reported_city_code,
      ic.inferred_city_code
    FROM new_map n
    JOIN eligible e ON e.stable_key = n.stable_key
    LEFT JOIN inferred_city ic ON ic.stable_key = n.stable_key
    ON CONFLICT (stable_key) DO UPDATE SET
      city_code = EXCLUDED.city_code,
      geohash_precision = EXCLUDED.geohash_precision,
      component_hash = EXCLUDED.component_hash,
      area_id = EXCLUDED.area_id,
      mapping_version = EXCLUDED.mapping_version,
      reported_city_code = EXCLUDED.reported_city_code,
      inferred_city_code = EXCLUDED.inferred_city_code,
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
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions;

REVOKE ALL ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER) TO service_role;

COMMENT ON FUNCTION public.geo_area_cluster_rebuild_v1(TEXT, INTEGER, INTEGER, INTEGER)
IS 'Rebuild geo area clusters with expansion-from-seed behavior (v1). Service role only.';

