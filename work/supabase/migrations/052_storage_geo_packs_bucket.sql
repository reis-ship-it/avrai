-- Migration: Storage - geo packs bucket (v1)
-- Created: 2026-01-01
-- Purpose:
-- - Host offline-first city packs (polygons + vibes + knots + synco summaries)
-- - Packs must be readable pre-auth (onboarding), so bucket is public.
-- - Writes should be restricted to service role (or CI/admin tooling).

INSERT INTO storage.buckets (id, name, public)
VALUES ('geo-packs', 'geo-packs', true)
ON CONFLICT (id) DO NOTHING;

-- Policies: public read is handled by bucket public=true, but keep an explicit SELECT policy.
-- Drop-if-exists to avoid migration reapply failures.
DROP POLICY IF EXISTS "Anyone can view geo packs" ON storage.objects;
CREATE POLICY "Anyone can view geo packs" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'geo-packs');

DROP POLICY IF EXISTS "Service role can manage geo packs" ON storage.objects;
CREATE POLICY "Service role can manage geo packs" ON storage.objects
  FOR ALL
  USING ((select auth.role()) = 'service_role' AND bucket_id = 'geo-packs')
  WITH CHECK ((select auth.role()) = 'service_role' AND bucket_id = 'geo-packs');

