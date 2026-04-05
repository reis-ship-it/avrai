-- Place-level attraction override for claimed places.
-- When set, used instead of business-level attraction for compatibility.

ALTER TABLE claimed_places
ADD COLUMN IF NOT EXISTS attraction_override JSONB;
COMMENT ON COLUMN claimed_places.attraction_override IS 'Optional per-place 12D override; when non-null, used instead of business attraction';
