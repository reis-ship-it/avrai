# Predictive Proactive Outreach - Database Schema (Vectorless Architecture)

**Created:** January 6, 2026  
**Status:** ✅ Complete  
**Migration:** `supabase/migrations/067_predictive_proactive_outreach_v1.sql`  
**Architecture:** Vectorless - JSONB for complex structures, scalar cache for compatibility

---

## 🎯 **Architecture Overview**

### **Vectorless Approach**

This schema uses a **vectorless architecture** optimized for:
- **Topological knot theory** (not vector-based)
- **Quantum state calculations** (mathematical structures, not embeddings)
- **Statistical compatibility** (scalar scores, not vector similarity)
- **Predictive calculations** (temporal interpolation, not vector search)

### **Key Principles**

1. **JSONB for Complex Structures**
   - Personality profiles, quantum states, knot data stored as JSONB
   - Fast queries with GIN indexes
   - No embedding generation overhead

2. **Scalar Cache for Compatibility**
   - Pre-calculated compatibility scores (0.0-1.0)
   - Fast lookups without vector similarity search
   - Component scores (knot, quantum, location, timing) stored separately

3. **Predictive Signals Cache**
   - Pre-calculated predictions (string, quantum, fabric)
   - JSONB for complex prediction data
   - Time-based expiration

4. **No Vector Embeddings**
   - No pgvector extension
   - No embedding generation
   - No vector similarity search

---

## 📊 **Database Tables**

### **1. outreach_queue**

Stores proactive outreach messages queued for silent delivery.

**Key Features:**
- Silent delivery (no push notifications)
- Shown when user opens app
- Supports scheduling for optimal timing
- Tracks delivery and response status

**Columns:**
- `id` - UUID primary key
- `type` - Outreach type (community_invitation, event_call, etc.)
- `target_user_id` - Target user (FK to auth.users)
- `source_id` - Source entity ID (community, event, business, etc.)
- `source_type` - Source entity type
- `compatibility_score` - Scalar compatibility (0.0-1.0)
- `string_prediction_score` - Knot evolution string prediction
- `quantum_trajectory_score` - Temporal quantum compatibility
- `fabric_stability_score` - Fabric stability prediction
- `from_agent_id` / `to_agent_id` - AI2AI identifiers
- `optimal_timing` - When to deliver (if scheduled)
- `status` - pending, scheduled, delivered, seen, accepted, rejected, etc.
- `metadata` - JSONB for additional data

**Indexes:**
- `idx_outreach_queue_target_user` - Fast lookup by user and status
- `idx_outreach_queue_optimal_timing` - Scheduled delivery queries
- `idx_outreach_queue_source` - Source-based queries
- `idx_outreach_queue_compatibility` - High-compatibility outreach

**RLS Policies:**
- Users can view/update their own outreach
- Service role can manage all outreach

---

### **2. outreach_history**

Tracks all outreach sent to prevent duplicates and manage frequency.

**Key Features:**
- Prevents duplicate outreach (one per user-source-type per day)
- Tracks response rates
- Used for frequency management

**Columns:**
- `id` - UUID primary key
- `target_user_id` - Target user (FK to auth.users)
- `source_id` - Source entity ID
- `source_type` - Source entity type
- `type` - Outreach type
- `sent_at` - When outreach was sent
- `status` - sent, accepted, rejected, ignored
- `compatibility_score` - Compatibility at time of outreach
- `from_agent_id` / `to_agent_id` - AI2AI identifiers

**Unique Constraint:**
- `unique_outreach_per_day` - Prevents duplicate outreach on same day

**Indexes:**
- `idx_outreach_history_target` - User's outreach history
- `idx_outreach_history_source` - Source's outreach history
- `idx_outreach_history_recent` - Recent outreach queries

**RLS Policies:**
- Users can view their own outreach history
- Service role can manage all history

---

### **3. compatibility_cache**

Caches compatibility scores (scalar values) for fast lookups.

**Key Features:**
- Vectorless: stores scalar scores, not embeddings
- Component scores (knot, quantum, location, timing) stored separately
- Future compatibility predictions cached
- TTL-based expiration

**Columns:**
- `id` - UUID primary key
- `source_id` / `target_id` - Entity IDs
- `source_type` / `target_type` - Entity types
- `compatibility_score` - Combined score (0.0-1.0)
- `knot_compatibility` - Topological knot compatibility
- `quantum_fidelity` - Quantum fidelity score
- `location_compatibility` - Location match score
- `timing_compatibility` - Timing match score
- `vibe_alignment` - Vibe alignment score
- `future_compatibility` - Predicted future score
- `future_compatibility_time` - When prediction is for
- `compatibility_trajectory` - JSONB time series
- `fabric_stability_improvement` - Group fabric improvement
- `evolution_trend` - improving, stable, declining
- `expires_at` - Cache expiration time

**Unique Constraint:**
- `unique_compatibility_cache` - One entry per source-target pair

**Indexes:**
- `idx_compatibility_cache_source` - Source-based lookups
- `idx_compatibility_cache_target` - Target-based lookups
- `idx_compatibility_cache_score` - High-compatibility queries
- `idx_compatibility_cache_future` - Future compatibility queries
- `idx_compatibility_cache_expires` - Expired entry cleanup

**RLS Policies:**
- Users can view compatibility cache entries involving them
- Service role can manage all cache

---

### **4. predictive_signals_cache**

Caches predictive signals (string predictions, quantum trajectories, etc.).

**Key Features:**
- Vectorless: stores pre-calculated predictions, not embeddings
- JSONB for complex prediction data
- Time-based expiration
- Supports multiple signal types

**Columns:**
- `id` - UUID primary key
- `entity_id` / `entity_type` - Entity being predicted
- `signal_type` - Type of prediction (knot_evolution_string, quantum_trajectory, etc.)
- `prediction_data` - JSONB storing prediction results
- `prediction_time` - When prediction was made
- `target_time` - What time prediction is for
- `confidence` - Prediction confidence (0.0-1.0)
- `expires_at` - Cache expiration time

**Signal Types:**
- `knot_evolution_string` - Knot evolution string prediction
- `quantum_trajectory` - Quantum compatibility trajectory
- `fabric_stability` - Fabric stability prediction
- `evolution_patterns` - Evolution pattern analysis
- `compatibility_trajectory` - Compatibility over time
- `optimal_timing` - Optimal outreach timing

**Unique Constraint:**
- `unique_predictive_signal` - One prediction per entity-signal-type-target_time

**Indexes:**
- `idx_predictive_signals_entity` - Entity-based lookups
- `idx_predictive_signals_target_time` - Future predictions
- `idx_predictive_signals_expires` - Expired entry cleanup

**RLS Policies:**
- Users can view predictive signals for their own entities
- Service role can manage all cache

---

### **5. outreach_processing_jobs**

Tracks background job processing for outreach.

**Key Features:**
- Monitors job execution
- Tracks success/failure rates
- Supports retry logic

**Columns:**
- `id` - UUID primary key
- `job_type` - high_priority, medium_priority, low_priority, incremental, event_driven
- `status` - pending, processing, completed, failed, cancelled
- `started_at` / `completed_at` - Job timing
- `processing_time_ms` - Execution time
- `items_processed` / `items_succeeded` / `items_failed` - Job results
- `outreach_created` - Number of outreach messages created
- `error_message` / `error_stack` - Error details
- `retry_count` - Retry attempts

**Indexes:**
- `idx_outreach_jobs_type_status` - Job type and status queries
- `idx_outreach_jobs_failed` - Failed jobs needing retry

**RLS Policies:**
- Service role only (background jobs)

---

## 🔧 **Helper Functions**

### **cleanup_expired_outreach_cache()**

Cleans up expired cache entries.

```sql
SELECT cleanup_expired_outreach_cache();
-- Returns: number of deleted entries
```

**What it does:**
- Deletes expired compatibility cache entries
- Deletes expired predictive signals cache entries
- Marks expired outreach queue entries as 'expired'

**When to run:**
- Daily cleanup job
- Before cache queries to free space

---

### **get_pending_outreach_count(p_user_id UUID)**

Gets count of pending outreach for a user.

```sql
SELECT get_pending_outreach_count('user-uuid-here');
-- Returns: integer count
```

**What it does:**
- Counts pending/scheduled/delivered outreach
- Excludes expired outreach
- Fast lookup for UI display

---

### **has_recent_outreach(p_target_user_id, p_source_id, p_type, p_lookback_days)**

Checks if recent outreach exists (for duplicate prevention).

```sql
SELECT has_recent_outreach('user-uuid', 'source-id', 'event_call', 30);
-- Returns: boolean
```

**What it does:**
- Checks outreach history for duplicates
- Configurable lookback period (default 30 days)
- Used before creating new outreach

---

## 📈 **Performance Characteristics**

### **Query Performance**

| Operation | Expected Time | Index Used |
|-----------|---------------|-------------|
| Get pending outreach | <10ms | `idx_outreach_queue_target_user` |
| Compatibility lookup | <5ms | `idx_compatibility_cache_source` |
| Predictive signal lookup | <10ms | `idx_predictive_signals_entity` |
| Check recent outreach | <5ms | `idx_outreach_history_recent` |
| High-compatibility queries | <20ms | `idx_compatibility_cache_score` |

### **Cache Hit Rates**

**Target Performance:**
- Compatibility cache: >90% hit rate
- Predictive signals cache: >80% hit rate
- Outreach history: >95% hit rate (duplicate prevention)

### **Storage Estimates**

**Per 1M users:**
- Outreach queue: ~50GB (assuming 5 pending per user)
- Outreach history: ~100GB (assuming 10 outreach per user per month)
- Compatibility cache: ~200GB (assuming 100 cached pairs per user)
- Predictive signals cache: ~50GB (assuming 5 signals per user)

**Total: ~400GB for 1M users**

---

## 🔒 **Security & Privacy (Signal Protocol)**

### **Encryption - Signal Protocol Integration**

1. **Message Payloads**
   - Stored as JSONB (plaintext in database)
   - **Encrypted at transmission time using Signal Protocol** (via AI2AIOutreachCommunicationService)
   - Uses `HybridEncryptionService` which tries Signal Protocol first, falls back to AES-256-GCM
   - No user data in payloads (anonymous only)
   - Perfect forward secrecy via Signal Protocol Double Ratchet
   - X3DH key exchange for session establishment

2. **Signal Protocol Integration**
   - All AI2AI outreach messages encrypted with Signal Protocol
   - Routes through `AnonymousCommunicationProtocol` (Signal Protocol ready)
   - Encryption happens at transmission time, not storage time
   - Session keys managed by Signal Protocol service
   - Encryption type tracked in `outreach_queue.metadata.encryption_type`

### **Row Level Security (RLS)**

All tables have RLS enabled with policies:
- Users can only see their own data
- Service role can manage all data
- No cross-user data leakage

### **Privacy Protection**

- Uses `agent_id` for AI2AI communication (not `user_id`)
- User data encrypted in transit using Signal Protocol
- Outreach history prevents tracking across users
- Cache entries expire automatically

---

## 🚀 **Usage Examples**

### **1. Queue Outreach**

```sql
INSERT INTO public.outreach_queue (
    type,
    target_user_id,
    source_id,
    source_type,
    compatibility_score,
    string_prediction_score,
    quantum_trajectory_score,
    from_agent_id,
    to_agent_id,
    reasoning,
    optimal_timing,
    status
) VALUES (
    'community_invitation',
    'user-uuid',
    'community-uuid',
    'community',
    0.85,
    0.82,
    0.88,
    'community-agent-id',
    'user-agent-id',
    'High compatibility, improving trajectory',
    NOW() + INTERVAL '2 days',
    'scheduled'
);
```

### **2. Get Pending Outreach**

```sql
SELECT *
FROM public.outreach_queue
WHERE target_user_id = 'user-uuid'
  AND status IN ('pending', 'scheduled', 'delivered')
  AND (expires_at IS NULL OR expires_at > NOW())
ORDER BY compatibility_score DESC, created_at DESC
LIMIT 20;
```

### **3. Cache Compatibility**

```sql
INSERT INTO public.compatibility_cache (
    source_id,
    source_type,
    target_id,
    target_type,
    compatibility_score,
    knot_compatibility,
    quantum_fidelity,
    location_compatibility,
    timing_compatibility,
    expires_at
) VALUES (
    'user-1-id',
    'user',
    'user-2-id',
    'user',
    0.75,
    0.70,
    0.80,
    0.75,
    0.70,
    NOW() + INTERVAL '6 hours'
)
ON CONFLICT (source_id, target_id, source_type, target_type)
DO UPDATE SET
    compatibility_score = EXCLUDED.compatibility_score,
    calculated_at = NOW(),
    expires_at = EXCLUDED.expires_at;
```

### **4. Check for Duplicates**

```sql
SELECT has_recent_outreach(
    'target-user-uuid',
    'source-id',
    'event_call',
    30  -- 30 day lookback
);
-- Returns: true if duplicate, false if OK to send
```

---

## 🔄 **Maintenance**

### **Daily Cleanup**

```sql
-- Run daily to clean up expired entries
SELECT cleanup_expired_outreach_cache();
```

### **Cache Warming**

```sql
-- Pre-calculate compatibility for active users
-- Run during low-traffic hours
-- Batch process in chunks of 1000 users
```

### **Monitoring**

```sql
-- Check cache hit rates
SELECT 
    COUNT(*) FILTER (WHERE expires_at > NOW()) as active_entries,
    COUNT(*) FILTER (WHERE expires_at <= NOW()) as expired_entries,
    COUNT(*) as total_entries
FROM public.compatibility_cache;

-- Check outreach queue size
SELECT 
    status,
    COUNT(*) as count
FROM public.outreach_queue
GROUP BY status;

-- Check job success rates
SELECT 
    job_type,
    COUNT(*) FILTER (WHERE status = 'completed') as succeeded,
    COUNT(*) FILTER (WHERE status = 'failed') as failed,
    AVG(processing_time_ms) as avg_time_ms
FROM public.outreach_processing_jobs
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY job_type;
```

---

## 📚 **Related Documentation**

- **Implementation Plan:** `docs/plans/predictive_outreach/PREDICTIVE_PROACTIVE_OUTREACH_PLAN.md`
- **Architecture:** Vectorless approach optimized for knot/quantum calculations
- **Migration File:** `supabase/migrations/067_predictive_proactive_outreach_v1.sql`

---

**Last Updated:** January 6, 2026  
**Status:** ✅ Complete - Ready for Implementation
