-- Migration: Geo hierarchy - import real polygons + point lookup (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Enable replacing circle-generated locality shapes with real polygons (GeoJSON import)
-- - Enable automatic locality/city resolution from a lat/lon point (for onboarding + maps)

-- Spatial index for fast point-in-polygon checks
CREATE INDEX IF NOT EXISTS idx_geo_locality_shapes_v1_geom_gist
  ON public.geo_locality_shapes_v1
  USING GIST ((geom::geometry));

-- Import/override a locality shape from GeoJSON (service role).
-- Accepts GeoJSON object types:
-- - Polygon / MultiPolygon
-- - Feature { geometry: ... }
-- - FeatureCollection { features: [ { geometry: ... }, ... ] } (uses first feature)
CREATE OR REPLACE FUNCTION public.upsert_geo_locality_shape_geojson_v1(
  p_locality_code TEXT,
  p_geojson JSONB,
  p_source TEXT DEFAULT 'import_geojson_v1'
)
RETURNS VOID AS $$
DECLARE
  v_type TEXT;
  v_geom_json JSONB;
  v_geom geometry;
BEGIN
  IF p_locality_code IS NULL OR trim(p_locality_code) = '' THEN
    RAISE EXCEPTION 'locality_code required';
  END IF;
  IF p_geojson IS NULL THEN
    RAISE EXCEPTION 'geojson required';
  END IF;

  v_type := COALESCE(p_geojson->>'type', '');

  IF v_type = 'FeatureCollection' THEN
    v_geom_json := p_geojson->'features'->0->'geometry';
  ELSIF v_type = 'Feature' THEN
    v_geom_json := p_geojson->'geometry';
  ELSE
    v_geom_json := p_geojson;
  END IF;

  IF v_geom_json IS NULL THEN
    RAISE EXCEPTION 'geojson geometry missing for locality_code=%', p_locality_code;
  END IF;

  v_geom := ST_SetSRID(ST_GeomFromGeoJSON(v_geom_json::text), 4326);
  -- Keep polygons only, normalize to multipolygon
  v_geom := ST_Multi(ST_CollectionExtract(v_geom, 3));

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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.upsert_geo_locality_shape_geojson_v1(TEXT, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_geo_locality_shape_geojson_v1(TEXT, JSONB, TEXT) TO service_role;

COMMENT ON FUNCTION public.upsert_geo_locality_shape_geojson_v1(TEXT, JSONB, TEXT)
IS 'Import/override locality shapes from GeoJSON (v1).';

-- Point → locality lookup (anon/authenticated safe; returns only codes and display_name).
CREATE OR REPLACE FUNCTION public.geo_lookup_locality_by_point_v1(
  p_lat DOUBLE PRECISION,
  p_lon DOUBLE PRECISION
)
RETURNS TABLE (
  locality_code TEXT,
  city_code TEXT,
  display_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    gl.locality_code,
    gl.city_code,
    gl.display_name
  FROM public.geo_locality_shapes_v1 s
  JOIN public.geo_localities_v1 gl
    ON gl.locality_code = s.locality_code
  WHERE ST_Contains(
    s.geom::geometry,
    ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)
  )
  -- Prefer the smallest containing locality (neighborhood over borough over city-locality)
  ORDER BY gl.is_neighborhood DESC, ST_Area(s.geom::geometry) ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_lookup_locality_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_lookup_locality_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO anon;
GRANT EXECUTE ON FUNCTION public.geo_lookup_locality_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_lookup_locality_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO service_role;

COMMENT ON FUNCTION public.geo_lookup_locality_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION)
IS 'Lookup locality_code by point using geo_locality_shapes_v1 (v1).';

-- Point → city_code lookup using geohash3 map (fast).
CREATE OR REPLACE FUNCTION public.geo_lookup_city_code_by_point_v1(
  p_lat DOUBLE PRECISION,
  p_lon DOUBLE PRECISION
)
RETURNS TEXT AS $$
DECLARE
  v_geohash3 TEXT;
  v_city TEXT;
BEGIN
  v_geohash3 := ST_GeoHash(ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326), 3);
  SELECT m.city_code INTO v_city
  FROM public.city_geohash3_map m
  WHERE m.geohash3_id = v_geohash3
  LIMIT 1;
  RETURN v_city;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.geo_lookup_city_code_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.geo_lookup_city_code_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO anon;
GRANT EXECUTE ON FUNCTION public.geo_lookup_city_code_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.geo_lookup_city_code_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION) TO service_role;

COMMENT ON FUNCTION public.geo_lookup_city_code_by_point_v1(DOUBLE PRECISION, DOUBLE PRECISION)
IS 'Lookup city_code by point using city_geohash3_map (v1).';

