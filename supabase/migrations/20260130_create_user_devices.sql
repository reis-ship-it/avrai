-- Phase 26: Multi-Device Sync - User Devices Table
-- Creates the user_devices table for tracking linked devices

-- Create user_devices table
CREATE TABLE IF NOT EXISTS user_devices (
  device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_int_id INTEGER NOT NULL,
  device_name TEXT NOT NULL,
  platform TEXT NOT NULL,
  device_model TEXT,
  os_version TEXT,
  app_version TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'revoked')),
  push_token TEXT,
  public_key TEXT,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_current_device BOOLEAN DEFAULT FALSE,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Ensure unique device_int_id per user
  UNIQUE(user_id, device_int_id)
);

-- Create indexes
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_status ON user_devices(status);
CREATE INDEX idx_user_devices_last_seen ON user_devices(last_seen_at);

-- Enable RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own devices
CREATE POLICY "Users can view own devices"
  ON user_devices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices"
  ON user_devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices"
  ON user_devices FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices"
  ON user_devices FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_user_devices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_devices_updated_at
  BEFORE UPDATE ON user_devices
  FOR EACH ROW
  EXECUTE FUNCTION update_user_devices_updated_at();

-- Create device_link_requests table for pairing
CREATE TABLE IF NOT EXISTS device_link_requests (
  request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requesting_device_id UUID NOT NULL,
  approving_device_id UUID,
  link_method TEXT NOT NULL CHECK (link_method IN ('same_account', 'numeric_code', 'push_approval', 'secure_bypass')),
  code_hash TEXT,
  ephemeral_public_key TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '5 minutes',
  resolved_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX idx_device_link_requests_user_id ON device_link_requests(user_id);
CREATE INDEX idx_device_link_requests_status ON device_link_requests(status);
CREATE INDEX idx_device_link_requests_expires ON device_link_requests(expires_at);

-- Enable RLS
ALTER TABLE device_link_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own link requests"
  ON device_link_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own link requests"
  ON device_link_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own link requests"
  ON device_link_requests FOR UPDATE
  USING (auth.uid() = user_id);

-- Comment for documentation
COMMENT ON TABLE user_devices IS 'Phase 26: Multi-device sync - tracks all devices linked to a user account';
COMMENT ON TABLE device_link_requests IS 'Phase 26: Multi-device sync - tracks device pairing requests';
