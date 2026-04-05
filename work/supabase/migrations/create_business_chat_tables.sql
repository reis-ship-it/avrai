-- Business Chat Tables
-- Creates tables for business-expert and business-business messaging
-- Signal Protocol ready - includes encrypted_content and encryption_type fields

-- Business-Expert Messages
CREATE TABLE IF NOT EXISTS business_expert_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL,
  sender_type VARCHAR(20) NOT NULL, -- 'business' or 'expert'
  sender_id UUID NOT NULL, -- business_id or user_id
  recipient_type VARCHAR(20) NOT NULL,
  recipient_id UUID NOT NULL,
  content TEXT NOT NULL, -- Plaintext (for AES-256-GCM)
  encrypted_content BYTEA, -- Encrypted content (for Signal Protocol future)
  encryption_type VARCHAR(50) DEFAULT 'aes256gcm', -- 'aes256gcm' or 'signal_protocol'
  message_type VARCHAR(50) DEFAULT 'text', -- 'text', 'partnership_proposal', 'file'
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_be_conversation_id ON business_expert_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_be_sender ON business_expert_messages(sender_type, sender_id);
CREATE INDEX IF NOT EXISTS idx_be_recipient ON business_expert_messages(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_be_created_at ON business_expert_messages(created_at DESC);

-- Business-Expert Conversations
CREATE TABLE IF NOT EXISTS business_expert_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  expert_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vibe_compatibility_score DECIMAL(3,2), -- 0.00 to 1.00
  connection_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'connected', 'blocked'
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(business_id, expert_id)
);

CREATE INDEX IF NOT EXISTS idx_be_conv_business ON business_expert_conversations(business_id);
CREATE INDEX IF NOT EXISTS idx_be_conv_expert ON business_expert_conversations(expert_id);
CREATE INDEX IF NOT EXISTS idx_be_conv_status ON business_expert_conversations(connection_status);

-- Business-Business Messages
CREATE TABLE IF NOT EXISTS business_business_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL,
  sender_business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  recipient_business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  content TEXT NOT NULL, -- Plaintext (for AES-256-GCM)
  encrypted_content BYTEA, -- Encrypted content (for Signal Protocol future)
  encryption_type VARCHAR(50) DEFAULT 'aes256gcm', -- 'aes256gcm' or 'signal_protocol'
  message_type VARCHAR(50) DEFAULT 'text', -- 'text', 'event_partnership_proposal', 'file'
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bb_conversation_id ON business_business_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_bb_sender ON business_business_messages(sender_business_id);
CREATE INDEX IF NOT EXISTS idx_bb_recipient ON business_business_messages(recipient_business_id);
CREATE INDEX IF NOT EXISTS idx_bb_created_at ON business_business_messages(created_at DESC);

-- Business-Business Conversations
CREATE TABLE IF NOT EXISTS business_business_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_1_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  business_2_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  vibe_compatibility_score DECIMAL(3,2), -- 0.00 to 1.00
  connection_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'connected', 'blocked'
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(business_1_id, business_2_id)
);

CREATE INDEX IF NOT EXISTS idx_bb_conv_business1 ON business_business_conversations(business_1_id);
CREATE INDEX IF NOT EXISTS idx_bb_conv_business2 ON business_business_conversations(business_2_id);
CREATE INDEX IF NOT EXISTS idx_bb_conv_status ON business_business_conversations(connection_status);

-- Multi-Party Event Partnerships
CREATE TABLE IF NOT EXISTS multi_party_event_partnerships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES expertise_events(id) ON DELETE CASCADE,
  partnership_type VARCHAR(50) DEFAULT 'business_business', -- 'business_business', 'business_expert_business'
  business_ids UUID[] NOT NULL, -- Array of business IDs participating
  expert_ids UUID[], -- Array of expert IDs (if applicable)
  revenue_split JSONB, -- Revenue distribution among parties
  status VARCHAR(50) DEFAULT 'proposed', -- 'proposed', 'negotiating', 'approved', 'locked', 'active', 'completed'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mp_event ON multi_party_event_partnerships(event_id);
CREATE INDEX IF NOT EXISTS idx_mp_status ON multi_party_event_partnerships(status);
CREATE INDEX IF NOT EXISTS idx_mp_business_ids ON multi_party_event_partnerships USING GIN(business_ids);

