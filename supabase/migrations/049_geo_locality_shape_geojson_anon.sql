-- Migration: Geo hierarchy - allow anon read of locality shapes (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Enable onboarding/map flows to render locality geometry before authentication

GRANT EXECUTE ON FUNCTION public.geo_get_locality_shape_geojson_v1(TEXT, DOUBLE PRECISION) TO anon;

-- City geohash3 bounds are also safe to expose to anon (used for map overlays pre-auth).
GRANT EXECUTE ON FUNCTION public.geo_list_city_geohash3_bounds_v1(TEXT, INTEGER) TO anon;

