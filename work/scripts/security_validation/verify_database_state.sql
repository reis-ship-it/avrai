-- Security Validation: Database State Verification
-- 
-- Verifies database state for secure agent ID mappings:
-- - No plaintext mappings exist
-- - All mappings are encrypted
-- - Encryption metadata is correct
-- 
-- Usage: Run this script against your Supabase database
-- 
-- Expected Results:
-- - user_agent_mappings table is empty or doesn't exist
-- - All mappings in user_agent_mappings_secure are encrypted
-- - Encryption metadata is consistent

-- ============================================
-- 1. Check for plaintext mappings
-- ============================================
-- Note: This table should be empty after migration
SELECT 
    COUNT(*) as plaintext_count,
    'user_agent_mappings' as table_name
FROM user_agent_mappings;

-- Expected: plaintext_count = 0 (or table doesn't exist)

-- ============================================
-- 2. Verify secure table exists and has data
-- ============================================
SELECT 
    COUNT(*) as secure_count,
    'user_agent_mappings_secure' as table_name
FROM user_agent_mappings_secure;

-- Expected: secure_count > 0 (if users exist)

-- ============================================
-- 3. Verify encryption metadata
-- ============================================
SELECT 
    encryption_algorithm,
    encryption_version,
    COUNT(*) as count,
    MIN(created_at) as earliest_created,
    MAX(created_at) as latest_created
FROM user_agent_mappings_secure
GROUP BY encryption_algorithm, encryption_version
ORDER BY encryption_algorithm, encryption_version;

-- Expected:
-- - encryption_algorithm = 'aes256_gcm'
-- - encryption_version = 1
-- - All rows should have consistent metadata

-- ============================================
-- 4. Verify encrypted_mapping is BYTEA (not text)
-- ============================================
SELECT 
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'user_agent_mappings_secure' 
  AND column_name = 'encrypted_mapping';

-- Expected:
-- - data_type = 'bytea'
-- - character_maximum_length = NULL

-- ============================================
-- 5. Verify encrypted data is not readable text
-- ============================================
-- Sample a few encrypted mappings to verify they're binary
SELECT 
    user_id,
    LENGTH(encrypted_mapping::text) as encrypted_length,
    encryption_key_id,
    encryption_algorithm,
    created_at
FROM user_agent_mappings_secure
LIMIT 5;

-- Expected:
-- - encrypted_length should be reasonable (not 0, not extremely large)
-- - encrypted_mapping should be binary data (not readable text)
-- - encryption_key_id should be present

-- ============================================
-- 6. Verify no NULL encrypted mappings
-- ============================================
SELECT 
    COUNT(*) as null_count
FROM user_agent_mappings_secure
WHERE encrypted_mapping IS NULL;

-- Expected: null_count = 0

-- ============================================
-- 7. Verify encryption key IDs are present
-- ============================================
SELECT 
    COUNT(*) as missing_key_id_count
FROM user_agent_mappings_secure
WHERE encryption_key_id IS NULL OR encryption_key_id = '';

-- Expected: missing_key_id_count = 0

-- ============================================
-- 8. Check for audit logs
-- ============================================
SELECT 
    COUNT(*) as audit_log_count,
    action,
    COUNT(DISTINCT user_id) as unique_users
FROM agent_mapping_audit_log
GROUP BY action
ORDER BY action;

-- Expected:
-- - audit_log_count > 0 (if mappings have been accessed)
-- - Actions: 'accessed', 'created', 'rotated'

-- ============================================
-- 9. Verify migration status
-- ============================================
-- Compare counts (if old table still exists)
SELECT 
    (SELECT COUNT(*) FROM user_agent_mappings) as old_table_count,
    (SELECT COUNT(*) FROM user_agent_mappings_secure) as new_table_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM user_agent_mappings) = 0 
        THEN '✅ Migration complete'
        WHEN (SELECT COUNT(*) FROM user_agent_mappings) = (SELECT COUNT(*) FROM user_agent_mappings_secure)
        THEN '⚠️  Migration pending (counts match)'
        ELSE '❌ Migration incomplete (counts differ)'
    END as migration_status;

-- Expected: migration_status = '✅ Migration complete'

-- ============================================
-- 10. Verify table structure
-- ============================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_agent_mappings_secure'
ORDER BY ordinal_position;

-- Expected columns:
-- - user_id (UUID, NOT NULL, PRIMARY KEY)
-- - encrypted_mapping (BYTEA, NOT NULL)
-- - encryption_key_id (TEXT, NOT NULL)
-- - encryption_algorithm (TEXT, NOT NULL, DEFAULT 'aes256_gcm')
-- - encryption_version (INTEGER, NOT NULL, DEFAULT 1)
-- - created_at (TIMESTAMPTZ, DEFAULT NOW())
-- - last_rotated_at (TIMESTAMPTZ, NULLABLE)
-- - last_accessed_at (TIMESTAMPTZ, NULLABLE)
-- - access_count (INTEGER, DEFAULT 0)
-- - rotation_count (INTEGER, DEFAULT 0)
