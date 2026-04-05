-- Canonical place representation rollout.
-- This migration also repairs historical schema drift observed on the
-- linked AVRAI project, where 087/088 were marked applied without the
-- underlying business/claimed-place tables being present.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS public.business_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  description TEXT,
  website TEXT,
  location TEXT,
  phone TEXT,
  logo_url TEXT,
  business_type TEXT NOT NULL DEFAULT 'Unknown',
  categories JSONB NOT NULL DEFAULT '[]'::jsonb,
  required_expertise JSONB NOT NULL DEFAULT '[]'::jsonb,
  preferred_communities JSONB NOT NULL DEFAULT '[]'::jsonb,
  expert_preferences JSONB,
  patron_preferences JSONB,
  preferred_location TEXT,
  min_expert_level INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verification JSONB,
  stripe_connect_account_id TEXT,
  connected_expert_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  pending_connection_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  members JSONB NOT NULL DEFAULT '[]'::jsonb,
  owner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  shared_agent_id TEXT,
  attraction_dimensions JSONB,
  has_login_credentials BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_business_accounts_created_by
  ON public.business_accounts(created_by);
CREATE INDEX IF NOT EXISTS idx_business_accounts_owner_id
  ON public.business_accounts(owner_id);
CREATE INDEX IF NOT EXISTS idx_business_accounts_business_type
  ON public.business_accounts(business_type);
CREATE INDEX IF NOT EXISTS idx_business_accounts_verified
  ON public.business_accounts(is_verified);
CREATE OR REPLACE FUNCTION public.update_business_accounts_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_business_accounts_updated_at
  ON public.business_accounts;
CREATE TRIGGER trg_business_accounts_updated_at
BEFORE UPDATE ON public.business_accounts
FOR EACH ROW
EXECUTE FUNCTION public.update_business_accounts_updated_at();
ALTER TABLE public.business_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners can read business_accounts"
  ON public.business_accounts;
CREATE POLICY "Owners can read business_accounts"
  ON public.business_accounts
  FOR SELECT
  USING (
    (select auth.uid()) IS NOT NULL
    AND (
      created_by = (select auth.uid())
      OR owner_id = (select auth.uid())
    )
  );
DROP POLICY IF EXISTS "Owners can insert business_accounts"
  ON public.business_accounts;
CREATE POLICY "Owners can insert business_accounts"
  ON public.business_accounts
  FOR INSERT
  WITH CHECK (
    (select auth.uid()) IS NOT NULL
    AND (
      created_by = (select auth.uid())
      OR owner_id = (select auth.uid())
    )
  );
DROP POLICY IF EXISTS "Owners can update business_accounts"
  ON public.business_accounts;
CREATE POLICY "Owners can update business_accounts"
  ON public.business_accounts
  FOR UPDATE
  USING (
    (select auth.uid()) IS NOT NULL
    AND (
      created_by = (select auth.uid())
      OR owner_id = (select auth.uid())
    )
  )
  WITH CHECK (
    (select auth.uid()) IS NOT NULL
    AND (
      created_by = (select auth.uid())
      OR owner_id = (select auth.uid())
    )
  );
DROP POLICY IF EXISTS "Service role can manage business_accounts"
  ON public.business_accounts;
CREATE POLICY "Service role can manage business_accounts"
  ON public.business_accounts
  FOR ALL
  USING ((select auth.role()) = 'service_role')
  WITH CHECK ((select auth.role()) = 'service_role');
COMMENT ON TABLE public.business_accounts IS
  'User-owned business accounts. Reified here to repair historical staging drift before canonical-place rollout.';
CREATE TABLE IF NOT EXISTS public.claimed_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.business_accounts(id) ON DELETE CASCADE,
  google_place_id TEXT NOT NULL,
  claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  verification_method TEXT,
  attraction_override JSONB,
  UNIQUE(google_place_id)
);
CREATE INDEX IF NOT EXISTS idx_claimed_places_business_id
  ON public.claimed_places(business_id);
CREATE INDEX IF NOT EXISTS idx_claimed_places_google_place_id
  ON public.claimed_places(google_place_id);
COMMENT ON TABLE public.claimed_places IS
  'Business claims on places (google_place_id). One place at most one business.';
COMMENT ON COLUMN public.claimed_places.verification_method IS
  'e.g. email_pin, google_business_profile';
COMMENT ON COLUMN public.claimed_places.attraction_override IS
  'Optional per-place 12D override; when non-null, used instead of business attraction';
ALTER TABLE public.spots
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS website TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS google_place_id TEXT,
  ADD COLUMN IF NOT EXISTS apple_map_id TEXT,
  ADD COLUMN IF NOT EXISTS external_sync_metadata JSONB;
UPDATE public.spots
SET metadata = '{}'::jsonb
WHERE metadata IS NULL;
CREATE INDEX IF NOT EXISTS idx_spots_google_place_id
  ON public.spots(google_place_id);
CREATE INDEX IF NOT EXISTS idx_spots_apple_map_id
  ON public.spots(apple_map_id);
CREATE TABLE IF NOT EXISTS public.spot_aliases (
  canonical_spot_id UUID NOT NULL REFERENCES public.spots(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  external_id TEXT NOT NULL,
  name TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  website TEXT,
  category TEXT,
  confidence_score DOUBLE PRECISION DEFAULT 1.0 NOT NULL,
  last_seen_at TIMESTAMP WITH TIME ZONE,
  is_primary_alias BOOLEAN DEFAULT FALSE NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
  PRIMARY KEY (provider, external_id)
);
CREATE INDEX IF NOT EXISTS idx_spot_aliases_canonical_spot_id
  ON public.spot_aliases(canonical_spot_id);
INSERT INTO public.spot_aliases (
  canonical_spot_id,
  provider,
  external_id,
  name,
  address,
  latitude,
  longitude,
  phone_number,
  website,
  category,
  confidence_score,
  last_seen_at,
  is_primary_alias,
  metadata
)
SELECT
  s.id,
  'google_places',
  s.google_place_id,
  s.name,
  s.address,
  s.latitude,
  s.longitude,
  s.phone_number,
  s.website,
  s.category,
  1.0,
  s.updated_at,
  TRUE,
  jsonb_build_object('backfilled_from', 'spots.google_place_id')
FROM public.spots s
WHERE s.google_place_id IS NOT NULL
  AND btrim(s.google_place_id) <> ''
ON CONFLICT (provider, external_id) DO NOTHING;
INSERT INTO public.spot_aliases (
  canonical_spot_id,
  provider,
  external_id,
  name,
  address,
  latitude,
  longitude,
  phone_number,
  website,
  category,
  confidence_score,
  last_seen_at,
  is_primary_alias,
  metadata
)
SELECT
  s.id,
  'apple_places',
  s.apple_map_id,
  s.name,
  s.address,
  s.latitude,
  s.longitude,
  s.phone_number,
  s.website,
  s.category,
  1.0,
  s.updated_at,
  TRUE,
  jsonb_build_object('backfilled_from', 'spots.apple_map_id')
FROM public.spots s
WHERE s.apple_map_id IS NOT NULL
  AND btrim(s.apple_map_id) <> ''
ON CONFLICT (provider, external_id) DO NOTHING;
INSERT INTO public.spot_aliases (
  canonical_spot_id,
  provider,
  external_id,
  name,
  address,
  latitude,
  longitude,
  phone_number,
  website,
  category,
  confidence_score,
  last_seen_at,
  is_primary_alias,
  metadata
)
SELECT
  s.id,
  s.external_sync_metadata ->> 'sourceProvider',
  s.external_sync_metadata ->> 'externalId',
  s.name,
  s.address,
  s.latitude,
  s.longitude,
  s.phone_number,
  s.website,
  s.category,
  0.9,
  s.updated_at,
  FALSE,
  jsonb_build_object('backfilled_from', 'spots.external_sync_metadata')
FROM public.spots s
WHERE s.external_sync_metadata IS NOT NULL
  AND s.external_sync_metadata ->> 'sourceProvider' IS NOT NULL
  AND btrim(s.external_sync_metadata ->> 'sourceProvider') <> ''
  AND s.external_sync_metadata ->> 'externalId' IS NOT NULL
  AND btrim(s.external_sync_metadata ->> 'externalId') <> ''
ON CONFLICT (provider, external_id) DO NOTHING;
ALTER TABLE public.claimed_places
  ADD COLUMN IF NOT EXISTS canonical_spot_id UUID REFERENCES public.spots(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS claim_source_provider TEXT,
  ADD COLUMN IF NOT EXISTS claim_source_external_id TEXT;
ALTER TABLE public.claimed_places
  ALTER COLUMN google_place_id DROP NOT NULL;
UPDATE public.claimed_places cp
SET canonical_spot_id = sa.canonical_spot_id,
    claim_source_provider = COALESCE(cp.claim_source_provider, sa.provider),
    claim_source_external_id = COALESCE(cp.claim_source_external_id, sa.external_id)
FROM public.spot_aliases sa
WHERE cp.canonical_spot_id IS NULL
  AND cp.google_place_id IS NOT NULL
  AND sa.provider = 'google_places'
  AND sa.external_id = cp.google_place_id;
WITH orphan_claims AS (
  SELECT
    cp.id AS claim_id,
    cp.google_place_id,
    gen_random_uuid() AS canonical_id
  FROM public.claimed_places cp
  WHERE cp.canonical_spot_id IS NULL
    AND cp.google_place_id IS NOT NULL
    AND btrim(cp.google_place_id) <> ''
)
INSERT INTO public.spots (
  id,
  name,
  description,
  latitude,
  longitude,
  category,
  metadata
)
SELECT
  canonical_id,
  'Legacy claimed place',
  '',
  0,
  0,
  'place',
  jsonb_build_object(
    'source', 'google_places',
    'place_truth_v1', jsonb_build_object(
      'mergedProviders', jsonb_build_array('google_places'),
      'mergeConfidence', 0.0,
      'ambiguousMatch', TRUE,
      'fields', jsonb_build_object()
    ),
    'legacy_claim_id', claim_id
  )
FROM orphan_claims
ON CONFLICT (id) DO NOTHING;
WITH orphan_claims AS (
  SELECT
    cp.id AS claim_id,
    cp.google_place_id,
    s.id AS canonical_id
  FROM public.claimed_places cp
  JOIN public.spots s
    ON s.metadata ->> 'legacy_claim_id' = cp.id::text
  WHERE cp.canonical_spot_id IS NULL
    AND cp.google_place_id IS NOT NULL
    AND btrim(cp.google_place_id) <> ''
)
INSERT INTO public.spot_aliases (
  canonical_spot_id,
  provider,
  external_id,
  confidence_score,
  is_primary_alias,
  metadata
)
SELECT
  canonical_id,
  'google_places',
  google_place_id,
  0.5,
  TRUE,
  jsonb_build_object('backfilled_from', 'claimed_places')
FROM orphan_claims
ON CONFLICT (provider, external_id) DO NOTHING;
WITH orphan_claims AS (
  SELECT
    cp.id AS claim_id,
    cp.google_place_id,
    s.id AS canonical_id
  FROM public.claimed_places cp
  JOIN public.spots s
    ON s.metadata ->> 'legacy_claim_id' = cp.id::text
  WHERE cp.canonical_spot_id IS NULL
    AND cp.google_place_id IS NOT NULL
    AND btrim(cp.google_place_id) <> ''
)
UPDATE public.claimed_places cp
SET canonical_spot_id = orphan_claims.canonical_id,
    claim_source_provider = COALESCE(cp.claim_source_provider, 'google_places'),
    claim_source_external_id = COALESCE(cp.claim_source_external_id, cp.google_place_id)
FROM orphan_claims
WHERE cp.id = orphan_claims.claim_id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_claimed_places_canonical_spot_id_unique
  ON public.claimed_places(canonical_spot_id)
  WHERE canonical_spot_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS public.place_corrections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_spot_id UUID NOT NULL REFERENCES public.spots(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
  created_by TEXT,
  field_name TEXT,
  suggested_value TEXT,
  related_spot_id UUID REFERENCES public.spots(id) ON DELETE SET NULL,
  alias_provider TEXT,
  alias_external_id TEXT,
  notes TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_place_corrections_canonical_spot_id
  ON public.place_corrections(canonical_spot_id);
CREATE INDEX IF NOT EXISTS idx_place_corrections_status
  ON public.place_corrections(status);
