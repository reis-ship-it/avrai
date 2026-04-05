# Phase 7.1: Security Validation Checklist

**Date:** 2025-12-30  
**Status:** Ready for Execution  
**Environment:** Staging/Production

---

## 🔒 **SECURITY VALIDATION CHECKLIST**

### **1. No Plaintext Storage** ✅

**Code Verification:**
- [x] No references to `user_agent_mappings` (old plaintext table) in code
- [x] All storage uses `user_agent_mappings_secure` table
- [x] No plaintext fallback code paths

**Database Verification:**
- [ ] **TODO:** Query database to verify no plaintext mappings exist:
  ```sql
  SELECT COUNT(*) FROM user_agent_mappings;
  -- Should return 0 or be empty table
  ```
- [ ] **TODO:** Verify all mappings in secure table:
  ```sql
  SELECT COUNT(*) FROM user_agent_mappings_secure;
  -- Should match expected count
  ```
- [ ] **TODO:** Verify encrypted_mapping is BYTEA (not text):
  ```sql
  SELECT column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name = 'user_agent_mappings_secure' 
    AND column_name = 'encrypted_mapping';
  -- Should return: encrypted_mapping | bytea
  ```

---

### **2. All Mappings Encrypted** ✅

**Code Verification:**
- [x] `AgentIdService` requires `SecureMappingEncryptionService`
- [x] All new mappings encrypted before storage
- [x] Encryption uses AES-256-GCM via `pointycastle`

**Database Verification:**
- [ ] **TODO:** Verify encryption metadata:
  ```sql
  SELECT 
    encryption_algorithm,
    encryption_version,
    COUNT(*) as count
  FROM user_agent_mappings_secure
  GROUP BY encryption_algorithm, encryption_version;
  -- Should show: aes256_gcm | 1 | [count]
  ```
- [ ] **TODO:** Verify encrypted_mapping is not readable:
  ```sql
  SELECT 
    user_id,
    encrypted_mapping,
    encryption_key_id
  FROM user_agent_mappings_secure
  LIMIT 1;
  -- encrypted_mapping should be binary data, not readable text
  ```

---

### **3. Access Control Enforced (RLS)** ✅

**Code Verification:**
- [x] RLS policies in migration file
- [x] Users can only access their own mappings
- [x] Service role can access all mappings

**Database Verification:**
- [ ] **TODO:** Verify RLS is enabled:
  ```sql
  SELECT tablename, rowsecurity 
  FROM pg_tables 
  WHERE tablename = 'user_agent_mappings_secure';
  -- Should return: user_agent_mappings_secure | true
  ```
- [ ] **TODO:** List RLS policies:
  ```sql
  SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
  FROM pg_policies 
  WHERE tablename = 'user_agent_mappings_secure';
  -- Should show policies for SELECT, INSERT, UPDATE
  ```

**Functional Testing:**
- [ ] **TODO:** Test user can only access their own mapping:
  ```dart
  // Test: User A cannot access User B's mapping
  // Should throw exception or return null
  ```
- [ ] **TODO:** Test service role can access all mappings:
  ```dart
  // Test: Service role can access any mapping
  // Should succeed
  ```

---

### **4. Key Management Secure** ✅

**Code Verification:**
- [x] Keys stored in `FlutterSecureStorage` (hardware-backed)
- [x] Keys never logged or exposed
- [x] Key rotation service implemented

**Device Verification:**
- [ ] **TODO:** Verify keys stored in iOS Keychain (iOS devices)
- [ ] **TODO:** Verify keys stored in Android Keystore (Android devices)
- [ ] **TODO:** Verify keys not accessible via file system
- [ ] **TODO:** Test key rotation process:
  ```dart
  // Test: Rotate key for user
  await mappingKeyRotationService.rotateKeyForUser(userId);
  // Verify: New key_id in database
  // Verify: Old mapping can still be decrypted (re-encrypted)
  ```

---

### **5. Audit Logging Working** ✅

**Code Verification:**
- [x] Audit log table created
- [x] Async batched logging implemented
- [x] Logs access, creation, rotation events

**Database Verification:**
- [ ] **TODO:** Verify audit log table exists:
  ```sql
  SELECT COUNT(*) FROM agent_mapping_audit_log;
  -- Should return count of audit events
  ```
- [ ] **TODO:** Verify audit logs are being written:
  ```sql
  SELECT 
    action,
    COUNT(*) as count
  FROM agent_mapping_audit_log
  GROUP BY action
  ORDER BY count DESC;
  -- Should show: accessed, created, rotated
  ```
- [ ] **TODO:** Test audit log query performance:
  ```sql
  EXPLAIN ANALYZE
  SELECT * FROM agent_mapping_audit_log
  WHERE user_id = '[test_user_id]'
  ORDER BY created_at DESC
  LIMIT 100;
  -- Should complete in < 100ms
  ```

---

### **6. No Personal Data Leakage** ✅

**Code Verification:**
- [x] Only `agentId` stored (not `userId` in plaintext)
- [x] `userId` only used for RLS access control
- [x] No `userId` in audit logs (only `agentId`)

**Code Review:**
- [ ] **TODO:** Review all code paths for potential `userId` leakage
- [ ] **TODO:** Verify third-party services only receive `agentId`
- [ ] **TODO:** Check API responses don't expose `userId`
- [ ] **TODO:** Verify logs don't contain `userId` in plaintext

---

### **7. Migration Completed Successfully** ✅

**Code Verification:**
- [x] Migration service implemented
- [x] Migration script exists
- [x] Batch processing and verification implemented

**Migration Execution:**
- [ ] **TODO:** Run migration in staging environment:
  ```dart
  // Run migration script
  dart scripts/migrate_agent_id_mappings.dart
  ```
- [ ] **TODO:** Verify all plaintext mappings migrated:
  ```sql
  -- Before migration
  SELECT COUNT(*) FROM user_agent_mappings;
  
  -- After migration
  SELECT COUNT(*) FROM user_agent_mappings_secure;
  -- Counts should match
  ```
- [ ] **TODO:** Test migration rollback process:
  ```dart
  // Test: Rollback migration if needed
  // Verify: Old table still accessible
  // Verify: New table can be dropped safely
  ```

---

### **8. Performance Acceptable** ✅

**Code Verification:**
- [x] In-memory caching (5 minute TTL) implemented
- [x] Async batched audit logging
- [x] Encryption/decryption operations optimized

**Performance Testing:**
- [ ] **TODO:** Benchmark encryption speed:
  ```dart
  // Test: Encrypt mapping
  final stopwatch = Stopwatch()..start();
  await encryptionService.encryptMapping(userId: userId, agentId: agentId);
  stopwatch.stop();
  // Should be < 100ms
  ```
- [ ] **TODO:** Benchmark decryption speed:
  ```dart
  // Test: Decrypt mapping
  final stopwatch = Stopwatch()..start();
  await encryptionService.decryptMapping(...);
  stopwatch.stop();
  // Should be < 100ms
  ```
- [ ] **TODO:** Test cache hit/miss performance:
  ```dart
  // Test: Cache hit (should be < 1ms)
  // Test: Cache miss (should be < 100ms with decryption)
  ```
- [ ] **TODO:** Load test with high concurrent access:
  ```dart
  // Test: 100 concurrent users accessing mappings
  // Should handle gracefully without performance degradation
  ```

---

## 📊 **VALIDATION SUMMARY**

| Category | Code Status | Database Status | Functional Status |
|----------|-------------|-----------------|-------------------|
| No Plaintext Storage | ✅ | ⏳ Pending | ⏳ Pending |
| All Mappings Encrypted | ✅ | ⏳ Pending | ⏳ Pending |
| Access Control (RLS) | ✅ | ⏳ Pending | ⏳ Pending |
| Key Management | ✅ | ⏳ Pending | ⏳ Pending |
| Audit Logging | ✅ | ⏳ Pending | ⏳ Pending |
| No Data Leakage | ✅ | ⏳ Pending | ⏳ Pending |
| Migration Complete | ✅ | ⏳ Pending | ⏳ Pending |
| Performance | ✅ | ⏳ Pending | ⏳ Pending |

---

## 🚀 **NEXT STEPS**

1. **Execute Database Verification** - Run SQL queries to verify database state
2. **Execute Functional Testing** - Test RLS policies, key rotation, audit logging
3. **Execute Performance Testing** - Benchmark encryption/decryption, cache performance
4. **Generate Validation Report** - Document all findings and results

---

**Status:** Ready for Execution  
**Assigned To:** [To be assigned]  
**Target Completion:** [To be set]
