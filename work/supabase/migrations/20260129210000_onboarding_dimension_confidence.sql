-- Migration: Add dimension_confidence to onboarding_aggregations
-- Created: 2026-01-29
-- Purpose: Store confidence scores for computed personality dimensions
-- Related to: New onboarding flow with direct dimension measurement

-- Add dimension_confidence column
ALTER TABLE public.onboarding_aggregations
ADD COLUMN IF NOT EXISTS dimension_confidence JSONB DEFAULT NULL;
-- Add comment
COMMENT ON COLUMN public.onboarding_aggregations.dimension_confidence IS 
  'Confidence scores (0.0-1.0) for each dimension, provided by new onboarding flow';
-- Create index for queries that filter by confidence
CREATE INDEX IF NOT EXISTS idx_onboarding_aggregations_has_confidence 
  ON public.onboarding_aggregations((dimension_confidence IS NOT NULL));
