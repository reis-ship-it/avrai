-- Phase 26: Multi-Device Sync - Add recipient_device_id to dm_message_blobs
-- Enables per-device encrypted message storage

-- Add recipient_device_id column
ALTER TABLE dm_message_blobs 
ADD COLUMN IF NOT EXISTS recipient_device_id TEXT;
-- Set default for existing rows (legacy single-device)
UPDATE dm_message_blobs 
SET recipient_device_id = 'legacy' 
WHERE recipient_device_id IS NULL;
-- Make column required going forward
ALTER TABLE dm_message_blobs 
ALTER COLUMN recipient_device_id SET NOT NULL;
-- Create index for device-specific lookups
CREATE INDEX IF NOT EXISTS idx_dm_blobs_device 
ON dm_message_blobs(message_id, recipient_device_id);
-- Create index for fetching all blobs for a device
CREATE INDEX IF NOT EXISTS idx_dm_blobs_recipient_device 
ON dm_message_blobs(to_user_id, recipient_device_id);
-- Add composite unique constraint (message + device)
-- This allows same message_id with different device_ids
ALTER TABLE dm_message_blobs 
DROP CONSTRAINT IF EXISTS dm_message_blobs_pkey CASCADE;
ALTER TABLE dm_message_blobs 
ADD CONSTRAINT dm_message_blobs_pkey 
PRIMARY KEY (message_id, recipient_device_id);
-- Comment for documentation
COMMENT ON COLUMN dm_message_blobs.recipient_device_id IS 
  'Phase 26: Device ID this blob is encrypted for. Each device gets its own encrypted copy.';
-- ============================================================
-- Create device_bypass_audit table for secure bypass logging
-- ============================================================

CREATE TABLE IF NOT EXISTS device_bypass_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  action TEXT NOT NULL,
  reason TEXT,
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Create indexes
CREATE INDEX idx_bypass_audit_user ON device_bypass_audit(user_id);
CREATE INDEX idx_bypass_audit_created ON device_bypass_audit(created_at);
-- Enable RLS
ALTER TABLE device_bypass_audit ENABLE ROW LEVEL SECURITY;
-- Only the user and admins can view their bypass audit
CREATE POLICY "Users can view own bypass audit"
  ON device_bypass_audit FOR SELECT
  USING (auth.uid() = user_id);
-- Only system can insert (via service role or edge function)
CREATE POLICY "System can insert bypass audit"
  ON device_bypass_audit FOR INSERT
  WITH CHECK (auth.uid() = user_id);
COMMENT ON TABLE device_bypass_audit IS 
  'Phase 26: Audit log for secure device bypass operations (lost/stolen device recovery)';
