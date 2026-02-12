-- Migration: City-code geo bucket population pipeline (geohash3 → city_code)
-- Created: 2026-01-01
-- Purpose:
-- - Provide a repeatable, DB-native way to populate `public.city_geohash3_map`
-- - Make `geo_bucket_type=city_code` usable beyond initial hand-seeded samples
--
-- Approach (MVP, privacy-safe):
-- - Define cities with a center + radius (km)
-- - Generate a grid of points, convert each to geohash3 via PostGIS `ST_GeoHash`
-- - Insert distinct geohash3 IDs for that city_code
--
-- Notes:
-- - This is an approximation (circle coverage), but works well at geohash3 granularity.
-- - For higher fidelity later: replace circle with polygons/tiles; keep same table contract.

CREATE TABLE IF NOT EXISTS public.city_definitions (
  city_code TEXT PRIMARY KEY, -- ex: 'us-sf', 'us-nyc'
  display_name TEXT,
  center_lat DOUBLE PRECISION NOT NULL,
  center_lon DOUBLE PRECISION NOT NULL,
  radius_km DOUBLE PRECISION NOT NULL DEFAULT 30,
  step_km DOUBLE PRECISION NOT NULL DEFAULT 5,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_city_definitions_updated_at
  ON public.city_definitions(updated_at DESC);

ALTER TABLE public.city_definitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage city_definitions" ON public.city_definitions;
CREATE POLICY "Service role can manage city_definitions"
  ON public.city_definitions
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Upsert helper (keeps updated_at fresh)
CREATE OR REPLACE FUNCTION public.upsert_city_definition(
  p_city_code TEXT,
  p_display_name TEXT,
  p_center_lat DOUBLE PRECISION,
  p_center_lon DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 30,
  p_step_km DOUBLE PRECISION DEFAULT 5
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.city_definitions(city_code, display_name, center_lat, center_lon, radius_km, step_km, created_at, updated_at)
  VALUES (p_city_code, p_display_name, p_center_lat, p_center_lon, p_radius_km, p_step_km, NOW(), NOW())
  ON CONFLICT (city_code) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    center_lat = EXCLUDED.center_lat,
    center_lon = EXCLUDED.center_lon,
    radius_km = EXCLUDED.radius_km,
    step_km = EXCLUDED.step_km,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.upsert_city_definition(TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_city_definition(TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO service_role;

COMMENT ON TABLE public.city_definitions IS 'Admin-defined city buckets used to populate city_geohash3_map (geohash3 → city_code).';

-- Core populator: insert geohash3 IDs covering a city circle.
CREATE OR REPLACE FUNCTION public.populate_city_geohash3_map_circle(
  p_city_code TEXT,
  p_center_lat DOUBLE PRECISION,
  p_center_lon DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION,
  p_step_km DOUBLE PRECISION DEFAULT 5
) RETURNS BIGINT AS $$
DECLARE
  v_lat_delta DOUBLE PRECISION;
  v_lon_delta DOUBLE PRECISION;
  v_lat_step DOUBLE PRECISION;
  v_lon_step DOUBLE PRECISION;
  v_radius_m DOUBLE PRECISION := p_radius_km * 1000.0;
  v_inserted BIGINT := 0;
BEGIN
  -- Degrees-per-km approximations (good enough at geohash3 resolution)
  v_lat_delta := p_radius_km / 111.32;
  v_lat_step := GREATEST(p_step_km / 111.32, 0.0001);

  -- Longitude degrees shrink with latitude
  v_lon_delta := p_radius_km / (111.32 * GREATEST(cos(radians(p_center_lat)), 0.2));
  v_lon_step := GREATEST(p_step_km / (111.32 * GREATEST(cos(radians(p_center_lat)), 0.2)), 0.0001);

  WITH params AS (
    SELECT
      p_city_code::text AS city_code,
      p_center_lat::double precision AS center_lat,
      p_center_lon::double precision AS center_lon,
      v_radius_m::double precision AS radius_m,
      (p_center_lat - v_lat_delta)::double precision AS min_lat,
      (p_center_lat + v_lat_delta)::double precision AS max_lat,
      (p_center_lon - v_lon_delta)::double precision AS min_lon,
      (p_center_lon + v_lon_delta)::double precision AS max_lon,
      v_lat_step::double precision AS lat_step,
      v_lon_step::double precision AS lon_step
  ),
  grid AS (
    SELECT (lat_n::double precision) AS lat, (lon_n::double precision) AS lon
    FROM params,
      generate_series(min_lat::numeric, max_lat::numeric, lat_step::numeric) AS lat_n,
      generate_series(min_lon::numeric, max_lon::numeric, lon_step::numeric) AS lon_n
  ),
  inside AS (
    SELECT
      (ST_GeoHash(ST_SetSRID(ST_MakePoint(grid.lon, grid.lat), 4326), 3)) AS geohash3_id
    FROM grid, params
    WHERE ST_DWithin(
      ST_SetSRID(ST_MakePoint(grid.lon, grid.lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(params.center_lon, params.center_lat), 4326)::geography,
      params.radius_m
    )
  ),
  ins AS (
    INSERT INTO public.city_geohash3_map(city_code, geohash3_id, created_at)
    SELECT p_city_code, geohash3_id, NOW()
    FROM inside
    WHERE geohash3_id IS NOT NULL AND length(geohash3_id) = 3
    GROUP BY geohash3_id
    ON CONFLICT DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*)::bigint INTO v_inserted FROM ins;

  RETURN v_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.populate_city_geohash3_map_circle(
  TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.populate_city_geohash3_map_circle(
  TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION
) TO service_role;

COMMENT ON FUNCTION public.populate_city_geohash3_map_circle(
  TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION
) IS 'Populate city_geohash3_map by approximating a city as a circle (center+radius) and inserting distinct geohash3 tiles.';

-- Populate from city_definitions (all cities)
CREATE OR REPLACE FUNCTION public.populate_city_geohash3_map_from_definitions()
RETURNS BIGINT AS $$
DECLARE
  v_row RECORD;
  v_total BIGINT := 0;
  v_inserted BIGINT;
BEGIN
  FOR v_row IN
    SELECT city_code, center_lat, center_lon, radius_km, step_km
    FROM public.city_definitions
    ORDER BY city_code
  LOOP
    v_inserted := public.populate_city_geohash3_map_circle(
      v_row.city_code,
      v_row.center_lat,
      v_row.center_lon,
      v_row.radius_km,
      v_row.step_km
    );
    v_total := v_total + COALESCE(v_inserted, 0);
  END LOOP;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.populate_city_geohash3_map_from_definitions() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.populate_city_geohash3_map_from_definitions() TO service_role;

-- Seed definitions for initial cities (safe defaults at geohash3 resolution)
SELECT public.upsert_city_definition('us-sf', 'San Francisco Bay Area', 37.7749, -122.4194, 35, 5);
SELECT public.upsert_city_definition('us-nyc', 'New York City', 40.7128, -74.0060, 35, 5);

-- Optional: eagerly populate tiles for the seeded cities (idempotent)
SELECT public.populate_city_geohash3_map_from_definitions();

