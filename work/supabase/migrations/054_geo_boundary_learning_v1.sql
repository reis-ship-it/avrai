-- Migration: Federated boundary learning tables + aggregation (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Store privacy-bounded boundary contributions (binned geohash cells)
-- - Aggregate into an implicit boundary field (cell probability map)
-- - Rebuild locality polygons from the field (thresholded union of geohash cells)

-- 1) Append-only boundary contributions
CREATE TABLE IF NOT EXISTS public.geo_federated_boundary_updates_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  city_code TEXT NOT NULL,
  locality_code TEXT NOT NULL REFERENCES public.geo_localities_v1(locality_code) ON DELETE CASCADE,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  cells JSONB NOT NULL DEFAULT '[]'::jsonb,
  dp JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_federated_boundary_updates_v1_locality_created_at
  ON public.geo_federated_boundary_updates_v1(locality_code, created_at DESC);

ALTER TABLE public.geo_federated_boundary_updates_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own geo boundary updates" ON public.geo_federated_boundary_updates_v1;
CREATE POLICY "Users can insert own geo boundary updates"
  ON public.geo_federated_boundary_updates_v1
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can select own geo boundary updates" ON public.geo_federated_boundary_updates_v1;
CREATE POLICY "Users can select own geo boundary updates"
  ON public.geo_federated_boundary_updates_v1
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role can manage geo boundary updates" ON public.geo_federated_boundary_updates_v1;
CREATE POLICY "Service role can manage geo boundary updates"
  ON public.geo_federated_boundary_updates_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_federated_boundary_updates_v1 IS
  'Privacy-bounded boundary updates (geohash cell vote counts) for a locality (v1).';

-- 2) Aggregated implicit boundary field
CREATE TABLE IF NOT EXISTS public.geo_federated_boundary_aggregates_v1 (
  city_code TEXT NOT NULL,
  locality_code TEXT NOT NULL REFERENCES public.geo_localities_v1(locality_code) ON DELETE CASCADE,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  field_version INTEGER NOT NULL DEFAULT 1,
  cell_probs JSONB NOT NULL DEFAULT '{}'::jsonb, -- { geohash -> p_inside }
  sample_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (city_code, locality_code, geohash_precision)
);

ALTER TABLE public.geo_federated_boundary_aggregates_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo boundary aggregates" ON public.geo_federated_boundary_aggregates_v1;
CREATE POLICY "Service role can manage geo boundary aggregates"
  ON public.geo_federated_boundary_aggregates_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_federated_boundary_aggregates_v1 IS
  'Aggregated implicit boundary field per locality (v1).';

-- 3) Aggregate updates -> boundary field (service role)
CREATE OR REPLACE FUNCTION public.geo_boundary_aggregate_v1(
  p_city_code TEXT DEFAULT NULL,
  p_locality_code TEXT DEFAULT NULL,
  p_days_back INTEGER DEFAULT 30
)
RETURNS BIGINT AS $$
DECLARE
  v_rows BIGINT := 0;
BEGIN
  WITH updates AS (
    SELECT u.city_code, u.locality_code, u.geohash_precision, u.cells
    FROM public.geo_federated_boundary_updates_v1 u
    WHERE (p_city_code IS NULL OR u.city_code = p_city_code)
      AND (p_locality_code IS NULL OR u.locality_code = p_locality_code)
      AND u.created_at >= NOW() - (GREATEST(p_days_back, 1) || ' days')::interval
  ),
  cells AS (
    SELECT
      u.city_code,
      u.locality_code,
      u.geohash_precision,
      (c->>'geohash')::text AS geohash,
      COALESCE((c->>'inside_votes')::int, 0) AS inside_votes,
      COALESCE((c->>'outside_votes')::int, 0) AS outside_votes
    FROM updates u,
    LATERAL jsonb_array_elements(u.cells) AS c
    WHERE (c->>'geohash') IS NOT NULL
  ),
  agg AS (
    SELECT
      city_code,
      locality_code,
      geohash_precision,
      geohash,
      SUM(GREATEST(inside_votes, 0)) AS inside_sum,
      SUM(GREATEST(outside_votes, 0)) AS outside_sum
    FROM cells
    GROUP BY city_code, locality_code, geohash_precision, geohash
  ),
  probs AS (
    SELECT
      city_code,
      locality_code,
      geohash_precision,
      jsonb_object_agg(
        geohash,
        to_jsonb(
          (inside_sum::double precision + 1.0) /
          (inside_sum::double precision + outside_sum::double precision + 2.0)
        )
      ) AS cell_probs,
      COUNT(*)::int AS distinct_cells,
      SUM((inside_sum + outside_sum))::int AS total_votes
    FROM agg
    GROUP BY city_code, locality_code, geohash_precision
  ),
  up AS (
    INSERT INTO public.geo_federated_boundary_aggregates_v1(
      city_code, locality_code, geohash_precision, field_version, cell_probs, sample_count, updated_at
    )
    SELECT
      p.city_code,
      p.locality_code,
      p.geohash_precision,
      1,
      p.cell_probs,
      GREATEST(p.total_votes, 0),
      NOW()
    FROM probs p
    ON CONFLICT (city_code, locality_code, geohash_precision) DO UPDATE SET
      field_version = public.geo_federated_boundary_aggregates_v1.field_version + 1,
      cell_probs = EXCLUDED.cell_probs,
      sample_count = EXCLUDED.sample_count,
      updated_at = NOW()
    RETURNING 1
  )
  SELECT COUNT(*)::bigint INTO v_rows FROM up;

  RETURN v_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.geo_boundary_aggregate_v1(TEXT, TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_boundary_aggregate_v1(TEXT, TEXT, INTEGER) TO service_role;

COMMENT ON FUNCTION public.geo_boundary_aggregate_v1(TEXT, TEXT, INTEGER)
IS 'Aggregate geo_federated_boundary_updates_v1 into a per-locality implicit boundary field (v1).';

-- 4) Rebuild locality shapes from boundary field (service role)
CREATE OR REPLACE FUNCTION public.geo_rebuild_locality_shape_from_boundary_field_v1(
  p_city_code TEXT,
  p_locality_code TEXT,
  p_geohash_precision INTEGER DEFAULT 7,
  p_threshold DOUBLE PRECISION DEFAULT 0.60,
  p_source TEXT DEFAULT 'federated_v1'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_cell_probs JSONB;
  v_geom geometry;
BEGIN
  SELECT a.cell_probs INTO v_cell_probs
  FROM public.geo_federated_boundary_aggregates_v1 a
  WHERE a.city_code = p_city_code
    AND a.locality_code = p_locality_code
    AND a.geohash_precision = p_geohash_precision;

  IF v_cell_probs IS NULL OR v_cell_probs = '{}'::jsonb THEN
    RETURN FALSE;
  END IF;

  WITH cells AS (
    SELECT
      key AS geohash,
      (value::double precision) AS p
    FROM jsonb_each_text(v_cell_probs)
  ),
  selected AS (
    SELECT ST_GeomFromGeoHash(geohash) AS geom
    FROM cells
    WHERE p >= p_threshold
  ),
  merged AS (
    SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom
    FROM selected
  )
  SELECT
    ST_Multi(
      ST_CollectionExtract(
        ST_MakeValid((merged.geom)),
        3
      )
    )
  INTO v_geom
  FROM merged;

  IF v_geom IS NULL THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.geo_locality_shapes_v1(locality_code, geom, source, computed_at)
  VALUES (
    p_locality_code,
    v_geom::geography,
    p_source,
    NOW()
  )
  ON CONFLICT (locality_code) DO UPDATE SET
    geom = EXCLUDED.geom,
    source = EXCLUDED.source,
    computed_at = NOW();

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.geo_rebuild_locality_shape_from_boundary_field_v1(TEXT, TEXT, INTEGER, DOUBLE PRECISION, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_rebuild_locality_shape_from_boundary_field_v1(TEXT, TEXT, INTEGER, DOUBLE PRECISION, TEXT) TO service_role;

COMMENT ON FUNCTION public.geo_rebuild_locality_shape_from_boundary_field_v1(TEXT, TEXT, INTEGER, DOUBLE PRECISION, TEXT)
IS 'Derive and upsert a locality polygon from the implicit boundary field (v1).';

