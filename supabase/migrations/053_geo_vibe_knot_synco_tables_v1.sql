-- Migration: Geo vibe/knot/synco tables (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Store learned geo-level vibe signatures (time-aware) and knot signatures
-- - Store audience-tiered “synchopated” summaries
-- - Support tiered third-party access via Edge Functions (not direct table reads)

-- 1) Federated vibe contributions (privacy-bounded, binned)
CREATE TABLE IF NOT EXISTS public.geo_federated_vibe_updates_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  geo_id TEXT NOT NULL,
  geo_level TEXT NOT NULL, -- locality|city|region|nation|country
  city_code TEXT, -- optional routing hint
  geohash_precision INTEGER NOT NULL DEFAULT 7,
  time_bucket JSONB NOT NULL DEFAULT '{}'::jsonb,
  signals JSONB NOT NULL DEFAULT '[]'::jsonb,
  dp JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_federated_vibe_updates_v1_geo_id_created_at
  ON public.geo_federated_vibe_updates_v1(geo_id, created_at DESC);

ALTER TABLE public.geo_federated_vibe_updates_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own geo vibe updates" ON public.geo_federated_vibe_updates_v1;
CREATE POLICY "Users can insert own geo vibe updates"
  ON public.geo_federated_vibe_updates_v1
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can select own geo vibe updates" ON public.geo_federated_vibe_updates_v1;
CREATE POLICY "Users can select own geo vibe updates"
  ON public.geo_federated_vibe_updates_v1
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role can manage geo vibe updates" ON public.geo_federated_vibe_updates_v1;
CREATE POLICY "Service role can manage geo vibe updates"
  ON public.geo_federated_vibe_updates_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_federated_vibe_updates_v1 IS
  'Privacy-bounded, binned geo vibe updates contributed by devices (v1).';

-- 2) Canonical geo vibe signatures (learned + time-aware)
CREATE TABLE IF NOT EXISTS public.geo_vibe_signatures_v1 (
  geo_id TEXT PRIMARY KEY,
  geo_level TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  base_vibe DOUBLE PRECISION[] NOT NULL DEFAULT ARRAY[]::double precision[],
  time_modulations JSONB NOT NULL DEFAULT '{}'::jsonb,
  confidence JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT NOT NULL DEFAULT 'seed_v1',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_vibe_signatures_v1_updated_at
  ON public.geo_vibe_signatures_v1(updated_at DESC);

ALTER TABLE public.geo_vibe_signatures_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo vibe signatures" ON public.geo_vibe_signatures_v1;
CREATE POLICY "Service role can manage geo vibe signatures"
  ON public.geo_vibe_signatures_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_vibe_signatures_v1 IS
  'Canonical geo vibe signatures across levels (v1). Not directly readable by third parties; served via tiered APIs/packs.';

-- 3) Geo knot signatures (topological invariants)
CREATE TABLE IF NOT EXISTS public.geo_knot_signatures_v1 (
  geo_id TEXT PRIMARY KEY,
  geo_level TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  knot_invariants JSONB NOT NULL DEFAULT '{}'::jsonb,
  knot_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_knot_signatures_v1_updated_at
  ON public.geo_knot_signatures_v1(updated_at DESC);

ALTER TABLE public.geo_knot_signatures_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo knot signatures" ON public.geo_knot_signatures_v1;
CREATE POLICY "Service role can manage geo knot signatures"
  ON public.geo_knot_signatures_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_knot_signatures_v1 IS
  'Geo knot signatures (topological invariants) per geo entity (v1). Served via tiered APIs/packs.';

-- 4) Synchopated summaries (audience-tiered)
CREATE TABLE IF NOT EXISTS public.geo_synco_summaries_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  geo_id TEXT NOT NULL,
  geo_level TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  audience TEXT NOT NULL,
  summary_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  summary_text TEXT,
  llm_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_geo_synco_summaries_v1_geo_id_audience
  ON public.geo_synco_summaries_v1(geo_id, audience);

ALTER TABLE public.geo_synco_summaries_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage geo synco summaries" ON public.geo_synco_summaries_v1;
CREATE POLICY "Service role can manage geo synco summaries"
  ON public.geo_synco_summaries_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.geo_synco_summaries_v1 IS
  'Audience-tiered synchopated summaries (v1). Served via packs and tiered APIs.';

-- 5) Third-party API key registry (tiered paywall)
CREATE TABLE IF NOT EXISTS public.api_keys_v1 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_hash TEXT NOT NULL UNIQUE,
  label TEXT,
  tier TEXT NOT NULL DEFAULT 'general', -- general|full|everything
  is_active BOOLEAN NOT NULL DEFAULT true,
  rate_limit_per_min INTEGER NOT NULL DEFAULT 60,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMPTZ
);

ALTER TABLE public.api_keys_v1 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage api_keys_v1" ON public.api_keys_v1;
CREATE POLICY "Service role can manage api_keys_v1"
  ON public.api_keys_v1
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');

COMMENT ON TABLE public.api_keys_v1 IS
  'Third-party API keys (hashed) with tier and rate limit (v1). Service role only.';

