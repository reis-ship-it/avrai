-- Business Authentication Tables
-- Creates tables for business login credentials and sessions

-- Business credentials table
CREATE TABLE IF NOT EXISTS business_credentials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP
);

-- Business sessions table
CREATE TABLE IF NOT EXISTS business_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  username VARCHAR(255) NOT NULL,
  login_time TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  access_level VARCHAR(50) DEFAULT 'business',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_business_credentials_business_id ON business_credentials(business_id);
CREATE INDEX IF NOT EXISTS idx_business_credentials_username ON business_credentials(username);
CREATE INDEX IF NOT EXISTS idx_business_sessions_business_id ON business_sessions(business_id);
CREATE INDEX IF NOT EXISTS idx_business_sessions_expires_at ON business_sessions(expires_at);

-- Add hasLoginCredentials flag to business_accounts (if column doesn't exist)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'business_accounts' AND column_name = 'has_login_credentials'
  ) THEN
    ALTER TABLE business_accounts ADD COLUMN has_login_credentials BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Function to update has_login_credentials flag
CREATE OR REPLACE FUNCTION update_business_has_login_credentials()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE business_accounts
  SET has_login_credentials = EXISTS (
    SELECT 1 FROM business_credentials
    WHERE business_id = NEW.business_id AND is_active = true
  )
  WHERE id = NEW.business_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update flag when credentials are added/updated
DROP TRIGGER IF EXISTS trigger_update_business_has_login_credentials ON business_credentials;
CREATE TRIGGER trigger_update_business_has_login_credentials
  AFTER INSERT OR UPDATE OR DELETE ON business_credentials
  FOR EACH ROW
  EXECUTE FUNCTION update_business_has_login_credentials();

