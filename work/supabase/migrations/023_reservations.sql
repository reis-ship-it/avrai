-- Migration: Reservations Table
-- Created: 2026-01-01
-- Purpose: Store reservations for spots, businesses, and events
-- Phase 15: Reservation System Implementation with Quantum Integration
--
-- **Dual Identity System:**
-- - Uses agent_id (privacy-protected internal tracking)
-- - Optional user_data (shared with business/host if user consents)
--
-- **Quantum Integration:**
-- - Stores quantum_state for matching and compatibility calculations
-- - Uses atomic_timestamp for precise queue ordering

-- Create reservations table
CREATE TABLE IF NOT EXISTS public.reservations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Dual Identity System (Phase 15)
    agent_id TEXT NOT NULL, -- Privacy-protected internal tracking
    user_data JSONB, -- Optional user data (shared with business/host if user consents)
    
    -- Reservation Details
    type TEXT NOT NULL CHECK (type IN ('spot', 'business', 'event')),
    target_id TEXT NOT NULL, -- Spot ID, Business ID, or Event ID
    
    -- Reservation Time
    reservation_time TIMESTAMPTZ NOT NULL,
    
    -- Party Details
    party_size INTEGER NOT NULL CHECK (party_size > 0),
    ticket_count INTEGER NOT NULL DEFAULT 1 CHECK (ticket_count > 0),
    special_requests TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'noShow')),
    
    -- Pricing
    ticket_price DOUBLE PRECISION,
    deposit_amount DOUBLE PRECISION,
    
    -- Seating
    seat_id TEXT,
    
    -- Cancellation Policy
    cancellation_policy JSONB, -- CancellationPolicy model as JSON
    
    -- Modification Tracking
    modification_count INTEGER NOT NULL DEFAULT 0 CHECK (modification_count >= 0 AND modification_count <= 3),
    last_modified_at TIMESTAMPTZ,
    
    -- Dispute Information
    dispute_status TEXT NOT NULL DEFAULT 'none' CHECK (dispute_status IN ('none', 'submitted', 'underReview', 'resolved')),
    dispute_reason TEXT CHECK (dispute_reason IN ('injury', 'illness', 'death', 'other')),
    dispute_description TEXT,
    
    -- Quantum Integration (Phase 15)
    atomic_timestamp JSONB, -- AtomicTimestamp model as JSON (for queue ordering)
    quantum_state JSONB, -- QuantumEntityState model as JSON (for matching)
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reservations_agent_id ON public.reservations(agent_id);
CREATE INDEX IF NOT EXISTS idx_reservations_type ON public.reservations(type);
CREATE INDEX IF NOT EXISTS idx_reservations_target_id ON public.reservations(target_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON public.reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_reservation_time ON public.reservations(reservation_time);
CREATE INDEX IF NOT EXISTS idx_reservations_agent_status ON public.reservations(agent_id, status);
CREATE INDEX IF NOT EXISTS idx_reservations_type_target ON public.reservations(type, target_id);
CREATE INDEX IF NOT EXISTS idx_reservations_created_at ON public.reservations(created_at DESC);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_reservations_agent_type_time ON public.reservations(agent_id, type, reservation_time);

-- Enable RLS (Row Level Security)
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own reservations (via agentId lookup)
-- Note: This requires user_agent_mappings table for full implementation
-- For now, service role handles all operations
CREATE POLICY "Users can view own reservations" ON public.reservations
    FOR SELECT USING (true); -- TODO: Implement agentId lookup when user_agent_mappings exists

-- Policy: Service role can manage all reservations
CREATE POLICY "Service role can manage all reservations" ON public.reservations
    FOR ALL USING ((select auth.role()) = 'service_role');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reservations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER reservations_updated_at_trigger
    BEFORE UPDATE ON public.reservations
    FOR EACH ROW
    EXECUTE FUNCTION update_reservations_updated_at();

-- Add comment to table
COMMENT ON TABLE public.reservations IS 'Reservations for spots, businesses, and events with quantum integration';
COMMENT ON COLUMN public.reservations.agent_id IS 'Privacy-protected internal tracking (not userId)';
COMMENT ON COLUMN public.reservations.user_data IS 'Optional user data (shared with business/host if user consents)';
COMMENT ON COLUMN public.reservations.atomic_timestamp IS 'Atomic timestamp for queue ordering (first-come-first-served)';
COMMENT ON COLUMN public.reservations.quantum_state IS 'Quantum state for matching and compatibility calculations';
