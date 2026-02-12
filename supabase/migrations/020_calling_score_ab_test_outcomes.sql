-- Migration: Calling Score A/B Test Outcomes
-- Phase 12 Section 2.3: A/B Testing Framework
-- Tracks A/B test outcomes for comparing formula-based vs hybrid calling scores

CREATE TABLE IF NOT EXISTS calling_score_ab_test_outcomes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT NOT NULL,
  opportunity_id TEXT NOT NULL,
  test_group TEXT NOT NULL CHECK (test_group IN ('formulaBased', 'hybrid')),
  calling_score DOUBLE PRECISION NOT NULL CHECK (calling_score >= 0.0 AND calling_score <= 1.0),
  is_called BOOLEAN NOT NULL,
  outcome_type TEXT CHECK (outcome_type IN ('positive', 'negative', 'neutral')),
  outcome_score DOUBLE PRECISION CHECK (outcome_score >= 0.0 AND outcome_score <= 1.0),
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_ab_test_outcomes_agent_id ON calling_score_ab_test_outcomes(agent_id);
CREATE INDEX IF NOT EXISTS idx_ab_test_outcomes_test_group ON calling_score_ab_test_outcomes(test_group);
CREATE INDEX IF NOT EXISTS idx_ab_test_outcomes_timestamp ON calling_score_ab_test_outcomes(timestamp);
CREATE INDEX IF NOT EXISTS idx_ab_test_outcomes_outcome_type ON calling_score_ab_test_outcomes(outcome_type);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_ab_test_outcomes_group_timestamp ON calling_score_ab_test_outcomes(test_group, timestamp);

-- RLS Policies
ALTER TABLE calling_score_ab_test_outcomes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own outcomes (via agent_id)
CREATE POLICY "Users can view their own A/B test outcomes"
  ON calling_score_ab_test_outcomes
  FOR SELECT
  USING (
    agent_id = (
      SELECT agent_id FROM agent_ids 
      WHERE user_id = auth.uid()
      LIMIT 1
    )
  );

-- Policy: Service role can insert/update/delete (for backend services)
CREATE POLICY "Service role can manage A/B test outcomes"
  ON calling_score_ab_test_outcomes
  FOR ALL
  USING (auth.role() = 'service_role');

-- Comments
COMMENT ON TABLE calling_score_ab_test_outcomes IS 'A/B test outcomes for comparing formula-based vs hybrid calling scores (Phase 12 Section 2.3)';
COMMENT ON COLUMN calling_score_ab_test_outcomes.agent_id IS 'Anonymized agent ID for privacy protection';
COMMENT ON COLUMN calling_score_ab_test_outcomes.test_group IS 'A/B test group: formulaBased or hybrid';
COMMENT ON COLUMN calling_score_ab_test_outcomes.calling_score IS 'Calculated calling score (0.0-1.0)';
COMMENT ON COLUMN calling_score_ab_test_outcomes.is_called IS 'Whether user was "called" (score >= 0.70)';
COMMENT ON COLUMN calling_score_ab_test_outcomes.outcome_type IS 'Outcome type: positive, negative, or neutral';
COMMENT ON COLUMN calling_score_ab_test_outcomes.outcome_score IS 'Outcome score (0.0-1.0)';
