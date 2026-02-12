-- Claimed Places: business–place claims for "claim a place" flow
-- One business can claim many places; one place claimed by at most one business.
-- Used for business dashboard "Events at your places" and device-first knot/string for claimed places.

CREATE TABLE IF NOT EXISTS claimed_places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  google_place_id TEXT NOT NULL,
  claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  verification_method TEXT,
  UNIQUE(google_place_id)
);

CREATE INDEX IF NOT EXISTS idx_claimed_places_business_id ON claimed_places(business_id);
CREATE INDEX IF NOT EXISTS idx_claimed_places_google_place_id ON claimed_places(google_place_id);

COMMENT ON TABLE claimed_places IS 'Business claims on places (google_place_id). One place at most one business.';
COMMENT ON COLUMN claimed_places.verification_method IS 'e.g. email_pin, google_business_profile';
