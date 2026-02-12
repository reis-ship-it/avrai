-- Migration: Locality agents (global priors + privacy-bounded updates) (v1)
-- Created: 2026-01-02
-- Purpose:
-- - Store privacy-bounded locality agent updates contributed by devices
-- - Aggregate into global locality priors keyed by stable geohash-prefix identity

-- 1) Append-only update stream (device contributions)
CREATE TABLE IF NOT EXISTS public.locality_agent_updates_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  stable_key TEXT NOT NULL, -- e.g. gh7:dr5regw
  geohash_prefix TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  city_code TEXT,
  occurred_at TIMESTAMPTZ NOT NULL,
  source TEXT NOT NULL DEFAULT 'unknown',
  dwell_minutes INTEGER,
  quality_score DOUBLE PRECISION,
  is_repeat_visit BOOLEAN,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_locality_agent_updates_v1_stable_key_created_at
  ON public.locality_agent_updates_v1(stable_key, created_at DESC);

ALTER TABLE public.locality_agent_updates_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own locality agent updates" ON public.locality_agent_updates_v1;
CREATE POLICY "Users can insert own locality agent updates"
  ON public.locality_agent_updates_v1
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can select own locality agent updates" ON public.locality_agent_updates_v1;
CREATE POLICY "Users can select own locality agent updates"
  ON public.locality_agent_updates_v1
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role can manage locality agent updates" ON public.locality_agent_updates_v1;
CREATE POLICY "Service role can manage locality agent updates"
  ON public.locality_agent_updates_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.locality_agent_updates_v1 IS
  'Privacy-bounded locality agent updates keyed by stable geohash identity (v1).';

-- 2) Global (shared) priors (downloadable by authenticated app clients)
CREATE TABLE IF NOT EXISTS public.locality_agent_global_v1 (
  stable_key TEXT PRIMARY KEY, -- gh7:dr5regw
  geohash_prefix TEXT NOT NULL,
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  city_code TEXT,
  vector12 JSONB NOT NULL DEFAULT '[]'::jsonb, -- length 12 array aligned to VibeConstants.coreDimensions order
  confidence12 JSONB NOT NULL DEFAULT '[]'::jsonb, -- length 12, 0..1
  sample_count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_locality_agent_global_v1_updated_at
  ON public.locality_agent_global_v1(updated_at DESC);

ALTER TABLE public.locality_agent_global_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read locality agent global priors" ON public.locality_agent_global_v1;
CREATE POLICY "Authenticated can read locality agent global priors"
  ON public.locality_agent_global_v1
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Service role can manage locality agent global priors" ON public.locality_agent_global_v1;
CREATE POLICY "Service role can manage locality agent global priors"
  ON public.locality_agent_global_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.locality_agent_global_v1 IS
  'Global (shared) locality priors keyed by stable geohash identity (v1).';

-- 3) Optional dynamic area clustering labels (service-managed)
CREATE TABLE IF NOT EXISTS public.geo_area_clusters_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stable_key TEXT NOT NULL,
  area_id UUID NOT NULL DEFAULT gen_random_uuid(),
  area_version INTEGER NOT NULL DEFAULT 1,
  label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_area_clusters_v1_stable_key
  ON public.geo_area_clusters_v1(stable_key);

ALTER TABLE public.geo_area_clusters_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo area clusters" ON public.geo_area_clusters_v1;
CREATE POLICY "Service role can manage geo area clusters"
  ON public.geo_area_clusters_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_area_clusters_v1 IS
  'Dynamic area cluster labels mapping stable geohash keys to evolving area identities (v1).';

-- 4) Aggregate updates -> global priors (service role)
CREATE OR REPLACE FUNCTION public.locality_agent_aggregate_v1(
  p_stable_key TEXT DEFAULT NULL,
  p_days_back INTEGER DEFAULT 30
)
RETURNS BIGINT AS $$
DECLARE
  v_rows BIGINT := 0;
BEGIN
  WITH updates AS (
    SELECT
      u.stable_key,
      u.geohash_prefix,
      u.geohash_precision,
      u.city_code,
      u.occurred_at,
      u.source,
      u.dwell_minutes,
      u.quality_score,
      u.is_repeat_visit
    FROM public.locality_agent_updates_v1 u
    WHERE (p_stable_key IS NULL OR u.stable_key = p_stable_key)
      AND u.created_at >= NOW() - (GREATEST(p_days_back, 1) || ' days')::interval
  ),
  agg AS (
    SELECT
      stable_key,
      max(geohash_prefix) AS geohash_prefix,
      max(geohash_precision) AS geohash_precision,
      max(city_code) AS city_code,
      COUNT(*)::int AS sample_count,
      avg(COALESCE(quality_score, 0.0)) / 1.5 AS q,
      avg(COALESCE(dwell_minutes, 0.0)) / 60.0 AS d,
      avg(CASE WHEN COALESCE(is_repeat_visit, false) THEN 1.0 ELSE 0.0 END) AS repeat_rate,
      avg(CASE WHEN source IN ('bluetooth', 'ai2ai') THEN 1.0 ELSE 0.0 END) AS bt_rate,
      avg(CASE WHEN extract(hour from occurred_at) >= 21 OR extract(hour from occurred_at) <= 2 THEN 1.0 ELSE 0.0 END) AS night_rate
    FROM updates
    GROUP BY stable_key
  ),
  vec AS (
    SELECT
      stable_key,
      geohash_prefix,
      geohash_precision,
      city_code,
      sample_count,
      NOW() AS updated_at,
      jsonb_build_array(
        -- Order must match VibeConstants.coreDimensions
        LEAST(1.0, GREATEST(0.0, 0.5 + (1.0 - repeat_rate) * 0.10 + q * 0.05)), -- exploration_eagerness
        LEAST(1.0, GREATEST(0.0, 0.5 + bt_rate * 0.10)),                          -- community_orientation
        LEAST(1.0, GREATEST(0.0, 0.5 + d * 0.10 + q * 0.05)),                      -- authenticity_preference
        LEAST(1.0, GREATEST(0.0, 0.5 + bt_rate * 0.08)),                           -- social_discovery_style
        LEAST(1.0, GREATEST(0.0, 0.5 + night_rate * 0.08)),                        -- temporal_flexibility
        0.5,                                                                        -- location_adventurousness (requires homebase distance; leave neutral in v1)
        LEAST(1.0, GREATEST(0.0, 0.5 + bt_rate * 0.03)),                           -- curation_tendency
        LEAST(1.0, GREATEST(0.0, 0.5 + bt_rate * 0.08)),                           -- trust_network_reliance
        LEAST(1.0, GREATEST(0.0, 0.5 + night_rate * 0.05)),                        -- energy_preference
        LEAST(1.0, GREATEST(0.0, 0.5 + (1.0 - repeat_rate) * 0.10)),               -- novelty_seeking
        LEAST(1.0, GREATEST(0.0, 0.5 + q * 0.05)),                                 -- value_orientation
        LEAST(1.0, GREATEST(0.0, 0.5 + night_rate * 0.05))                         -- crowd_tolerance
      ) AS vector12,
      jsonb_build_array(
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0)),
        LEAST(1.0, GREATEST(0.0, sample_count / 50.0))
      ) AS confidence12
    FROM agg
  ),
  up AS (
    INSERT INTO public.locality_agent_global_v1(
      stable_key, geohash_prefix, geohash_precision, city_code,
      vector12, confidence12, sample_count, updated_at, created_at
    )
    SELECT
      stable_key, geohash_prefix, geohash_precision, city_code,
      vector12, confidence12, sample_count, updated_at, NOW()
    FROM vec
    ON CONFLICT (stable_key) DO UPDATE SET
      geohash_prefix = EXCLUDED.geohash_prefix,
      geohash_precision = EXCLUDED.geohash_precision,
      city_code = EXCLUDED.city_code,
      vector12 = EXCLUDED.vector12,
      confidence12 = EXCLUDED.confidence12,
      sample_count = EXCLUDED.sample_count,
      updated_at = NOW()
    RETURNING 1
  )
  SELECT COUNT(*)::bigint INTO v_rows FROM up;

  RETURN v_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.locality_agent_aggregate_v1(TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.locality_agent_aggregate_v1(TEXT, INTEGER) TO service_role;

COMMENT ON FUNCTION public.locality_agent_aggregate_v1(TEXT, INTEGER)
IS 'Aggregate locality_agent_updates_v1 into locality_agent_global_v1 priors (v1).';

