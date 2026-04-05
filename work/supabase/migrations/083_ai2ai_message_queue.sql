-- AI2AI Message Queue Table
-- Phase 4: Secure Encrypted Private AI2AI Network Implementation
-- Stores encrypted messages for AI2AI network routing with persistent queue

CREATE TABLE IF NOT EXISTS ai2ai_message_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id TEXT NOT NULL,
  sender_agent_id TEXT NOT NULL,
  target_agent_id TEXT NOT NULL,
  encrypted_payload TEXT NOT NULL,
  message_type TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  routing_hops JSONB, -- Array of hop node IDs: ["hop1", "hop2", ...]
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'delivered', 'failed', 'expired'
  delivery_attempts INT NOT NULL DEFAULT 0,
  last_delivery_attempt TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT ai2ai_message_queue_message_id_key UNIQUE (message_id),
  CONSTRAINT ai2ai_message_queue_status_check CHECK (status IN ('pending', 'delivered', 'failed', 'expired'))
);
-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_target_agent_id ON ai2ai_message_queue(target_agent_id);
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_sender_agent_id ON ai2ai_message_queue(sender_agent_id);
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_status ON ai2ai_message_queue(status);
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_expires_at ON ai2ai_message_queue(expires_at);
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_timestamp ON ai2ai_message_queue(timestamp);
CREATE INDEX IF NOT EXISTS idx_ai2ai_message_queue_pending ON ai2ai_message_queue(target_agent_id, status) WHERE status = 'pending';
-- RLS Policies
ALTER TABLE ai2ai_message_queue ENABLE ROW LEVEL SECURITY;
-- Policy: Agents can read their own messages (as target)
-- Uses user_agent_mappings to verify agent_id matches current user
CREATE POLICY "Agents can read own messages"
  ON ai2ai_message_queue
  FOR SELECT
  USING (
    (select auth.uid()) IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.user_agent_mappings
      WHERE user_id = (select auth.uid())
        AND agent_id = ai2ai_message_queue.target_agent_id
    )
  );
-- Policy: Agents can insert messages (as sender)
-- Uses user_agent_mappings to verify agent_id matches current user
CREATE POLICY "Agents can insert messages"
  ON ai2ai_message_queue
  FOR INSERT
  WITH CHECK (
    (select auth.uid()) IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.user_agent_mappings
      WHERE user_id = (select auth.uid())
        AND agent_id = ai2ai_message_queue.sender_agent_id
    )
  );
-- Policy: Agents can update their own messages (as target, for delivery status)
-- Uses user_agent_mappings to verify agent_id matches current user
CREATE POLICY "Agents can update own messages"
  ON ai2ai_message_queue
  FOR UPDATE
  USING (
    (select auth.uid()) IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.user_agent_mappings
      WHERE user_id = (select auth.uid())
        AND agent_id = ai2ai_message_queue.target_agent_id
    )
  );
-- Policy: Agents can delete their own messages (as target, after processing)
-- Uses user_agent_mappings to verify agent_id matches current user
CREATE POLICY "Agents can delete own messages"
  ON ai2ai_message_queue
  FOR DELETE
  USING (
    (select auth.uid()) IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM public.user_agent_mappings
      WHERE user_id = (select auth.uid())
        AND agent_id = ai2ai_message_queue.target_agent_id
    )
  );
-- Function to automatically mark expired messages
CREATE OR REPLACE FUNCTION mark_expired_ai2ai_messages()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE ai2ai_message_queue
  SET status = 'expired',
      updated_at = NOW()
  WHERE expires_at < NOW()
    AND status = 'pending';
END;
$$;
-- Function to cleanup expired messages (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_expired_ai2ai_messages()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM ai2ai_message_queue
  WHERE status = 'expired'
    AND updated_at < NOW() - INTERVAL '7 days';
END;
$$;
-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ai2ai_message_queue_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;
CREATE TRIGGER ai2ai_message_queue_updated_at_trigger
  BEFORE UPDATE ON ai2ai_message_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_ai2ai_message_queue_updated_at();
-- Comment on table
COMMENT ON TABLE ai2ai_message_queue IS 'Persistent queue for AI2AI network messages. Stores encrypted messages for routing and delivery.';
COMMENT ON COLUMN ai2ai_message_queue.encrypted_payload IS 'Base64-encoded encrypted message payload (E2E encrypted with Signal Protocol)';
COMMENT ON COLUMN ai2ai_message_queue.routing_hops IS 'JSON array of routing node IDs for multi-hop routing: ["node1", "node2", ...]';
COMMENT ON COLUMN ai2ai_message_queue.status IS 'Message status: pending (awaiting delivery), delivered (successfully delivered), failed (delivery failed), expired (TTL expired)';
