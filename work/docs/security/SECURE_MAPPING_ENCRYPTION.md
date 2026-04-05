# Secure Mapping Encryption Documentation

**Date:** December 30, 2025  
**Status:** Active  
**Purpose:** Documentation for secure, encrypted storage of userId ↔ agentId mappings

---

## Overview

The Secure Mapping Encryption system provides **AES-256-GCM encrypted storage** for userId ↔ agentId mappings, ensuring complete anonymity protection. Encryption keys are stored in `FlutterSecureStorage` (Keychain/Keystore), and mappings are stored as encrypted blobs in the database.

---

## Architecture

### **Components**

1. **SecureMappingEncryptionService**
   - Core encryption/decryption logic
   - Key generation and management
   - AES-256-GCM encryption
   - Key rotation support

2. **AgentIdService**
   - Encrypted mapping storage/retrieval
   - In-memory caching (5-minute TTL)
   - Async batched audit logging
   - Key rotation integration

3. **MappingKeyRotationService**
   - Periodic key rotation
   - Batch processing with rate limiting
   - Rotation audit logging

4. **AgentIdMigrationService**
   - Migration from plaintext to encrypted storage
   - Batch processing
   - Verification and error recovery

---

## Encryption Details

### **Algorithm: AES-256-GCM**

**Properties:**
- **Authenticated Encryption:** GCM mode provides authentication
- **256-bit keys:** Maximum security
- **Random IV:** Each encryption uses unique initialization vector
- **Non-deterministic:** Same plaintext produces different ciphertexts

**Implementation:**
- Uses `pointycastle` library for cryptographic operations
- Keys stored in `FlutterSecureStorage` (Keychain/Keystore)
- One key per user (isolated keys)

### **Key Management**

**Key Storage:**
- Keys stored in `FlutterSecureStorage` (device Keychain/Keystore)
- Key format: `mapping_encryption_key_{userId}`
- Keys never leave the device (except for backup/restore)

**Key Generation:**
- 256-bit (32 bytes) cryptographically secure random keys
- Generated on first encryption for each user
- Reused for subsequent encryptions (same user)

**Key Rotation:**
- Periodic rotation (configurable interval)
- Old keys retained for decryption of old data
- New keys used for new encryptions
- Rotation tracked in database

---

## Database Schema

### **Table: `user_agent_mappings_secure`**

```sql
CREATE TABLE IF NOT EXISTS public.user_agent_mappings_secure (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    encrypted_mapping BYTEA NOT NULL,
    encryption_key_id TEXT NOT NULL,
    encryption_algorithm TEXT NOT NULL DEFAULT 'aes256_gcm',
    encryption_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_rotated_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    access_count INTEGER DEFAULT 0,
    rotation_count INTEGER DEFAULT 0,
    CONSTRAINT encryption_algorithm_check CHECK (encryption_algorithm IN ('signal_protocol', 'aes256_gcm')),
    CONSTRAINT encryption_version_check CHECK (encryption_version >= 1)
);
```

**Fields:**
- `user_id`: User ID (primary key, references auth.users)
- `encrypted_mapping`: Encrypted blob (BYTEA)
- `encryption_key_id`: Key identifier (for key rotation)
- `encryption_algorithm`: Algorithm name ('aes256_gcm')
- `encryption_version`: Version number (for future algorithm changes)
- `created_at`: Creation timestamp
- `last_rotated_at`: Last key rotation timestamp
- `last_accessed_at`: Last access timestamp
- `access_count`: Access counter
- `rotation_count`: Rotation counter

### **Table: `agent_mapping_audit_log`**

```sql
CREATE TABLE IF NOT EXISTS public.agent_mapping_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL,
    access_type TEXT NOT NULL,
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    CONSTRAINT access_type_check CHECK (access_type IN ('lookup', 'creation', 'rotation', 'migration'))
);
```

**Fields:**
- `agent_id`: Agent ID (not userId - for privacy)
- `access_type`: Type of access ('lookup', 'creation', 'rotation', 'migration')
- `accessed_at`: Access timestamp
- `ip_address`: Client IP address (optional)
- `user_agent`: Client user agent (optional)

**Privacy Note:** Audit logs use `agentId` (not `userId`) to prevent data leakage.

---

## Access Control (RLS)

### **Row Level Security Policies**

**Users can access own encrypted mapping:**
```sql
CREATE POLICY "Users can access own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR SELECT
    USING ((select auth.uid()) = user_id);
```

**Users can update own mapping (for rotation):**
```sql
CREATE POLICY "Users can update own encrypted mapping"
    ON public.user_agent_mappings_secure
    FOR UPDATE
    USING ((select auth.uid()) = user_id);
```

**Service role can insert mappings:**
```sql
CREATE POLICY "Service role can insert encrypted mappings"
    ON public.user_agent_mappings_secure
    FOR INSERT
    WITH CHECK ((select auth.role()) = 'service_role');
```

---

## Migration Process

### **Phase 4: Migration from Plaintext**

**Process:**
1. Read plaintext mappings from `user_agent_mappings` table
2. Encrypt each mapping using `SecureMappingEncryptionService`
3. Write encrypted mapping to `user_agent_mappings_secure` table
4. Verify encryption/decryption round-trip
5. Log migration in audit log

**Verification:**
- All plaintext mappings encrypted
- All encrypted mappings decryptable
- No data loss
- Audit trail complete

**Rollback:**
- Old plaintext table retained during migration period
- Can rollback if issues detected
- Migration script includes verification step

---

## Key Rotation

### **Purpose**

- **Security:** Limit exposure window if key is compromised
- **Best Practice:** Periodic rotation for enhanced security
- **Compliance:** Meet security standards requirements

### **Process**

1. **Identify mappings needing rotation:**
   - Based on rotation interval (configurable)
   - Based on last rotation timestamp

2. **Rotate encryption key:**
   - Generate new key
   - Decrypt with old key
   - Encrypt with new key
   - Update database record

3. **Update metadata:**
   - Update `encryption_key_id`
   - Update `last_rotated_at`
   - Increment `rotation_count`

4. **Audit logging:**
   - Log rotation event
   - Track rotation history

### **Batch Processing**

- Process mappings in batches (configurable size)
- Rate limiting to prevent database overload
- Progress tracking and reporting

---

## Performance Optimizations

### **In-Memory Caching**

**Cache:**
- Decrypted agent IDs cached in memory
- 5-minute TTL (Time To Live)
- Automatic expiration

**Benefits:**
- Fast lookups (< 1ms)
- Reduced database queries
- Reduced encryption/decryption operations

**Cache Invalidation:**
- On key rotation
- On manual cache clear
- On TTL expiration

### **Async Batched Audit Logging**

**Batching:**
- Audit logs queued in memory
- Batched writes to database
- Batch size: 100 entries
- Flush interval: 5 seconds

**Benefits:**
- Non-blocking logging
- Reduced database writes
- Improved performance

---

## Security Guarantees

### **Encryption Guarantees**

1. **Data-at-Rest Encryption:**
   - All mappings encrypted before storage
   - Keys stored in secure device storage
   - No plaintext mappings in database

2. **Key Isolation:**
   - One key per user
   - Keys never shared between users
   - Keys never exposed in logs

3. **Access Control:**
   - RLS policies enforce user isolation
   - Users can only access own mappings
   - Service role for system operations

4. **Audit Trail:**
   - All access logged (using agentId, not userId)
   - Rotation events tracked
   - Migration events tracked

### **Privacy Guarantees**

1. **Anonymity Protection:**
   - userId ↔ agentId mapping encrypted
   - No plaintext mapping in database
   - Keys stored on device only

2. **Audit Log Privacy:**
   - Audit logs use agentId (not userId)
   - Prevents data leakage
   - Maintains audit trail without exposing userId

3. **No Reverse Lookup:**
   - No public API for agentId → userId lookup
   - Only forward lookup (userId → agentId) allowed
   - Reverse lookup requires service role

---

## Best Practices

### **For Developers**

1. **Always use DI:**
   ```dart
   // ✅ GOOD
   final agentIdService = di.sl<AgentIdService>();
   
   // ❌ BAD
   final agentIdService = AgentIdService();
   ```

2. **Never store plaintext mappings:**
   ```dart
   // ✅ GOOD
   await agentIdService.getUserAgentId(userId); // Uses encrypted storage
   
   // ❌ BAD
   await client.from('user_agent_mappings').insert({
     'user_id': userId,
     'agent_id': agentId, // Plaintext!
   });
   ```

3. **Use agentId for privacy-protected operations:**
   ```dart
   // ✅ GOOD
   final agentId = await agentIdService.getUserAgentId(userId);
   // Use agentId for AI2AI network, personality profiles, etc.
   
   // ❌ BAD
   // Using userId in AI2AI network or personality profiles
   ```

### **For Operations**

1. **Key Rotation:**
   - Rotate keys periodically (recommended: every 90 days)
   - Monitor rotation success rate
   - Track rotation history

2. **Audit Logging:**
   - Monitor audit log size
   - Archive old audit logs
   - Review access patterns

3. **Migration:**
   - Run migration during low-traffic period
   - Verify all mappings migrated
   - Monitor for errors

---

## Related Documentation

- [Agent ID System](AGENT_ID_SYSTEM.md) - Agent ID generation and usage
- [Security Analysis](../SECURITY_ANALYSIS.md) - Security recommendations
- [Implementation Plan](../plans/security_implementation/SECURE_AGENT_ID_MAPPING_IMPLEMENTATION_PLAN.md) - Complete implementation plan

---

**Last Updated:** December 30, 2025  
**Status:** Active
