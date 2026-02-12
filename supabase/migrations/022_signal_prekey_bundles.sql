-- Signal Protocol Prekey Bundles Table
-- Phase 14: Signal Protocol Implementation - Option 1
-- Stores prekey bundles for X3DH key exchange

CREATE TABLE IF NOT EXISTS signal_prekey_bundles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT NOT NULL,
  prekey_bundle_json JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  consumed BOOLEAN NOT NULL DEFAULT FALSE,
  consumed_at TIMESTAMPTZ,
  
  -- Indexes
  CONSTRAINT signal_prekey_bundles_agent_id_key UNIQUE (agent_id)
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_signal_prekey_bundles_agent_id ON signal_prekey_bundles(agent_id);
CREATE INDEX IF NOT EXISTS idx_signal_prekey_bundles_expires_at ON signal_prekey_bundles(expires_at);
CREATE INDEX IF NOT EXISTS idx_signal_prekey_bundles_consumed ON signal_prekey_bundles(consumed);

-- RLS Policies
ALTER TABLE signal_prekey_bundles ENABLE ROW LEVEL SECURITY;

-- Policy: Agents can read their own prekey bundles
CREATE POLICY "Agents can read own prekey bundles"
  ON signal_prekey_bundles
  FOR SELECT
  USING (auth.uid()::text = agent_id);

-- Policy: Agents can insert their own prekey bundles
CREATE POLICY "Agents can insert own prekey bundles"
  ON signal_prekey_bundles
  FOR INSERT
  WITH CHECK (auth.uid()::text = agent_id);

-- Policy: Agents can update their own prekey bundles (for consumption)
CREATE POLICY "Agents can update own prekey bundles"
  ON signal_prekey_bundles
  FOR UPDATE
  USING (auth.uid()::text = agent_id);

-- Policy: Agents can read other agents' prekey bundles (for X3DH key exchange)
-- This allows agents to fetch prekey bundles for establishing sessions
CREATE POLICY "Agents can read other agents' prekey bundles for key exchange"
  ON signal_prekey_bundles
  FOR SELECT
  USING (
    consumed = FALSE 
    AND expires_at > NOW()
  );

-- Function to automatically clean up expired prekey bundles
CREATE OR REPLACE FUNCTION cleanup_expired_prekey_bundles()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM signal_prekey_bundles
  WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$;

-- Comment on table
COMMENT ON TABLE signal_prekey_bundles IS 'Stores Signal Protocol prekey bundles for X3DH key exchange. Bundles are used once and expire after 7 days.';

COMMENT ON COLUMN signal_prekey_bundles.agent_id IS 'Agent ID (from agentId system)';
COMMENT ON COLUMN signal_prekey_bundles.prekey_bundle_json IS 'JSON representation of Signal PreKeyBundle';
COMMENT ON COLUMN signal_prekey_bundles.consumed IS 'Whether this prekey bundle has been used (one-time prekeys are consumed)';
COMMENT ON COLUMN signal_prekey_bundles.expires_at IS 'When this prekey bundle expires (default: 7 days)';
