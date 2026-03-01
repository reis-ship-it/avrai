-- Migration: Outside Buyer Entitlements and Key Creation (billing hook)
-- Purpose: Enforce that outside_buyer API keys are only created when an entitlement
--   (billing/contract) exists. Key creation is the single path for issuing keys.
-- Reference: docs/plans/architecture/OUTSIDE_BUYER_PAID_ACCESS.md

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- Entitlements table (billing/contract approval)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.outside_buyer_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', -- 'active' | 'suspended' | 'expired'
  valid_until TIMESTAMPTZ NOT NULL,
  billing_reference TEXT, -- contract id, payment id, or approval reference
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outside_buyer_entitlements_partner_id
  ON public.outside_buyer_entitlements(partner_id);
CREATE INDEX IF NOT EXISTS idx_outside_buyer_entitlements_valid
  ON public.outside_buyer_entitlements(partner_id, status, valid_until)
  WHERE status = 'active';

ALTER TABLE public.outside_buyer_entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage outside_buyer_entitlements"
  ON public.outside_buyer_entitlements
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

COMMENT ON TABLE public.outside_buyer_entitlements IS
  'Entitlements for outside-buyer API key issuance. Key creation requires a valid row (active, valid_until > now()).';

-- ============================================================
-- Key creation RPC (single path for outside_buyer keys)
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_outside_buyer_api_key(
  p_partner_id TEXT,
  p_billing_reference TEXT,
  p_api_key_plain TEXT,
  p_rate_limit_per_minute INTEGER DEFAULT 60,
  p_rate_limit_per_day INTEGER DEFAULT 5000,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_entitlement_id UUID;
  v_key_id UUID;
  v_key_hash TEXT;
BEGIN
  IF p_partner_id IS NULL OR trim(p_partner_id) = '' THEN
    RAISE EXCEPTION 'partner_id is required';
  END IF;
  IF p_api_key_plain IS NULL OR length(trim(p_api_key_plain)) < 16 THEN
    RAISE EXCEPTION 'api_key_plain must be at least 16 characters';
  END IF;

  -- Require valid entitlement (billing hook)
  SELECT id INTO v_entitlement_id
  FROM public.outside_buyer_entitlements
  WHERE partner_id = p_partner_id
    AND status = 'active'
    AND valid_until > NOW()
    AND (p_billing_reference IS NULL OR billing_reference = p_billing_reference)
  ORDER BY valid_until DESC
  LIMIT 1;

  IF v_entitlement_id IS NULL THEN
    RAISE EXCEPTION 'No valid entitlement for partner_id=% (billing_reference=%). Keys are paid-only.',
      p_partner_id, p_billing_reference;
  END IF;

  v_key_hash := encode(digest(p_api_key_plain, 'sha256'), 'hex');

  INSERT INTO public.api_keys (
    partner_id,
    api_key_hash,
    rate_limit_per_minute,
    rate_limit_per_day,
    is_active,
    expires_at,
    metadata
  )
  VALUES (
    'outside_buyer_' || p_partner_id,
    v_key_hash,
    p_rate_limit_per_minute,
    p_rate_limit_per_day,
    true,
    p_expires_at,
    jsonb_build_object('billing_reference', p_billing_reference, 'entitlement_id', v_entitlement_id)
  )
  RETURNING id INTO v_key_id;

  RETURN v_key_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_outside_buyer_api_key(TEXT, TEXT, TEXT, INTEGER, INTEGER, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_outside_buyer_api_key(TEXT, TEXT, TEXT, INTEGER, INTEGER, TIMESTAMPTZ) TO service_role;

COMMENT ON FUNCTION public.create_outside_buyer_api_key(TEXT, TEXT, TEXT, INTEGER, INTEGER, TIMESTAMPTZ) IS
  'Create an outside_buyer API key only when a valid entitlement exists (billing hook). Returns the new api_keys.id. Caller must store the plain key securely; it is not returned.';
