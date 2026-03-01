-- Migration: Geo hierarchy - city geohash3 tile bounds RPC (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Support map rendering of `city_code` buckets directly in-app.
-- - Returns bounding boxes for each geohash3 tile mapped to a city_code.
--
-- Notes:
-- - Uses PostGIS `ST_GeomFromGeoHash` to derive tile geometry.
-- - Returns min/max lat/lon so the client can render rectangles without GeoJSON parsing.

CREATE OR REPLACE FUNCTION public.geo_list_city_geohash3_bounds_v1(
  p_city_code TEXT,
  p_limit INTEGER DEFAULT 5000
)
RETURNS TABLE (
  geohash3_id TEXT,
  min_lat DOUBLE PRECISION,
  min_lon DOUBLE PRECISION,
  max_lat DOUBLE PRECISION,
  max_lon DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.geohash3_id,
    ST_YMin(ST_GeomFromGeoHash(m.geohash3_id)) AS min_lat,
    ST_XMin(ST_GeomFromGeoHash(m.geohash3_id)) AS min_lon,
    ST_YMax(ST_GeomFromGeoHash(m.geohash3_id)) AS max_lat,
    ST_XMax(ST_GeomFromGeoHash(m.geohash3_id)) AS max_lon
  FROM public.city_geohash3_map m
  WHERE m.city_code = p_city_code
  ORDER BY m.geohash3_id
  LIMIT GREATEST(p_limit, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_list_city_geohash3_bounds_v1(TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_list_city_geohash3_bounds_v1(TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_list_city_geohash3_bounds_v1(TEXT, INTEGER) TO service_role;

COMMENT ON FUNCTION public.geo_list_city_geohash3_bounds_v1(TEXT, INTEGER)
IS 'Map helper: list geohash3 tile bounds for a city_code (v1).';

