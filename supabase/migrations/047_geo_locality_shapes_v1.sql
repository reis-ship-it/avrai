-- Migration: Geo hierarchy - locality shapes for maps (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Store map-renderable locality geometry keyed by canonical `locality_code`
-- - Provide authenticated read via GeoJSON RPC for in-app maps overlays
--
-- MVP approach:
-- - Store approximate locality shapes as circles (center + radius_km)
-- - Generate polygons via PostGIS `ST_Buffer` on geography
-- - This is compatible with later upgrades (replace circles with real polygons)

-- Definitions: locality center + radius (km)
CREATE TABLE IF NOT EXISTS public.geo_locality_definitions_v1 (
  locality_code TEXT PRIMARY KEY REFERENCES public.geo_localities_v1(locality_code) ON DELETE CASCADE,
  center_lat DOUBLE PRECISION NOT NULL,
  center_lon DOUBLE PRECISION NOT NULL,
  radius_km DOUBLE PRECISION NOT NULL DEFAULT 10,
  source TEXT NOT NULL DEFAULT 'manual_circle_v1',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Shapes: computed geometry (multi-polygon) in WGS84
CREATE TABLE IF NOT EXISTS public.geo_locality_shapes_v1 (
  locality_code TEXT PRIMARY KEY REFERENCES public.geo_localities_v1(locality_code) ON DELETE CASCADE,
  geom GEOGRAPHY(MULTIPOLYGON, 4326) NOT NULL,
  source TEXT NOT NULL DEFAULT 'generated_from_definitions_v1',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.geo_locality_definitions_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geo_locality_shapes_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo_locality_definitions_v1" ON public.geo_locality_definitions_v1;
CREATE POLICY "Service role can manage geo_locality_definitions_v1"
  ON public.geo_locality_definitions_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

DROP POLICY IF EXISTS "Service role can manage geo_locality_shapes_v1" ON public.geo_locality_shapes_v1;
CREATE POLICY "Service role can manage geo_locality_shapes_v1"
  ON public.geo_locality_shapes_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

-- Upsert a locality definition (service role)
CREATE OR REPLACE FUNCTION public.upsert_geo_locality_definition_v1(
  p_locality_code TEXT,
  p_center_lat DOUBLE PRECISION,
  p_center_lon DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 10,
  p_source TEXT DEFAULT 'manual_circle_v1'
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.geo_locality_definitions_v1(
    locality_code, center_lat, center_lon, radius_km, source, created_at, updated_at
  )
  VALUES (
    p_locality_code, p_center_lat, p_center_lon, p_radius_km, p_source, NOW(), NOW()
  )
  ON CONFLICT (locality_code) DO UPDATE SET
    center_lat = EXCLUDED.center_lat,
    center_lon = EXCLUDED.center_lon,
    radius_km = EXCLUDED.radius_km,
    source = EXCLUDED.source,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.upsert_geo_locality_definition_v1(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_geo_locality_definition_v1(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT) TO service_role;

COMMENT ON FUNCTION public.upsert_geo_locality_definition_v1(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT)
IS 'Upsert locality definition (center+radius) used to generate locality shapes (v1).';

-- Compute shapes from definitions (service role)
CREATE OR REPLACE FUNCTION public.populate_geo_locality_shapes_v1(
  p_locality_code TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
  v_rows BIGINT := 0;
BEGIN
  WITH defs AS (
    SELECT d.locality_code, d.center_lat, d.center_lon, d.radius_km
    FROM public.geo_locality_definitions_v1 d
    WHERE p_locality_code IS NULL OR d.locality_code = p_locality_code
  ),
  computed AS (
    SELECT
      defs.locality_code,
      -- Create a circle buffer on geography (meters), then cast to multipolygon geography.
      ST_Multi(
        ST_Buffer(
          ST_SetSRID(ST_MakePoint(defs.center_lon, defs.center_lat), 4326)::geography,
          (defs.radius_km * 1000.0)
        )::geometry
      )::geography AS geom
    FROM defs
  ),
  up AS (
    INSERT INTO public.geo_locality_shapes_v1(locality_code, geom, source, computed_at)
    SELECT locality_code, geom, 'generated_from_definitions_v1', NOW()
    FROM computed
    ON CONFLICT (locality_code) DO UPDATE SET
      geom = EXCLUDED.geom,
      source = EXCLUDED.source,
      computed_at = NOW()
    RETURNING 1
  )
  SELECT COUNT(*)::bigint INTO v_rows FROM up;

  RETURN v_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.populate_geo_locality_shapes_v1(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.populate_geo_locality_shapes_v1(TEXT) TO service_role;

COMMENT ON FUNCTION public.populate_geo_locality_shapes_v1(TEXT)
IS 'Generate locality shapes from geo_locality_definitions_v1 (v1).';

-- Authenticated read: return GeoJSON (simplified) for a locality_code
CREATE OR REPLACE FUNCTION public.geo_get_locality_shape_geojson_v1(
  p_locality_code TEXT,
  p_simplify_tolerance DOUBLE PRECISION DEFAULT 0.002
)
RETURNS JSONB AS $$
DECLARE
  v_geom geometry;
  v_geojson JSONB;
BEGIN
  SELECT (s.geom::geometry) INTO v_geom
  FROM public.geo_locality_shapes_v1 s
  WHERE s.locality_code = p_locality_code;

  IF v_geom IS NULL THEN
    RETURN NULL;
  END IF;

  v_geojson := ST_AsGeoJSON(
    ST_SimplifyPreserveTopology(v_geom, GREATEST(p_simplify_tolerance, 0.0))
  )::jsonb;

  RETURN v_geojson;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_get_locality_shape_geojson_v1(TEXT, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_get_locality_shape_geojson_v1(TEXT, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_get_locality_shape_geojson_v1(TEXT, DOUBLE PRECISION) TO service_role;

COMMENT ON FUNCTION public.geo_get_locality_shape_geojson_v1(TEXT, DOUBLE PRECISION)
IS 'Map helper: return simplified GeoJSON polygon for locality_code (v1).';

-- Seed: NYC boroughs (approximate circles, good enough for MVP overlays)
SELECT public.upsert_geo_locality_definition_v1('us-nyc-brooklyn', 40.6782, -73.9442, 18, 'seed_nyc_v1');
SELECT public.upsert_geo_locality_definition_v1('us-nyc-manhattan', 40.7831, -73.9712, 12, 'seed_nyc_v1');
SELECT public.upsert_geo_locality_definition_v1('us-nyc-queens', 40.7282, -73.7949, 18, 'seed_nyc_v1');
SELECT public.upsert_geo_locality_definition_v1('us-nyc-bronx', 40.8448, -73.8648, 14, 'seed_nyc_v1');
SELECT public.upsert_geo_locality_definition_v1('us-nyc-staten_island', 40.5795, -74.1502, 12, 'seed_nyc_v1');

SELECT public.populate_geo_locality_shapes_v1(NULL);

