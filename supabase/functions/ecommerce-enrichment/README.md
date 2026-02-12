# E-Commerce Data Enrichment API

**Phase 21:** E-Commerce Data Enrichment Integration POC  
**Status:** 🚧 In Development (Section 21.1)  
**Purpose:** Enhance e-commerce recommendation algorithms with SPOTS data

---

## Overview

This Edge Function provides API endpoints for e-commerce platforms to enrich their recommendation algorithms with SPOTS data:

- **Real-World Behavior Data** - Places visited, time spent, return patterns
- **Quantum Personality Profiles** - Quantum state vectors and knot compatibility
- **Community Influence Patterns** - AI2AI network insights

---

## Deployment

### Prerequisites

1. Supabase project with migrations applied:
   - `022_ecommerce_enrichment_api_tables.sql` (API keys, request logs, market segments)

2. Environment variables (set as Supabase secrets):
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

### Deploy

```bash
supabase functions deploy ecommerce-enrichment --no-verify-jwt
```

**Note:** `--no-verify-jwt` is used because we implement custom API key authentication.

---

## API Endpoints

### Base URL
```
Production: https://[project-ref].supabase.co/functions/v1/ecommerce-enrichment
```

### Authentication

All requests require an API key in the Authorization header:

```http
Authorization: Bearer {api_key}
# OR
Authorization: ApiKey {api_key}
```

### Available Endpoints

#### 1. Real-World Behavior Enrichment
```http
POST /real-world-behavior
```

**Status:** ✅ Implemented (Section 21.2)

**Request Example:**
```json
{
  "user_segment": {
    "segment_id": "tech_enthusiasts_25_35_sf",
    "geographic_region": "san_francisco",
    "category_preferences": ["electronics", "tech_accessories"]
  },
  "product_context": {
    "category": "electronics",
    "subcategory": "smartphones",
    "price_range": "premium"
  }
}
```

#### 2. Quantum Personality Enrichment
```http
POST /quantum-personality
```

**Status:** ✅ Implemented (Section 21.2)

**Request Example:**
```json
{
  "user_segment": {
    "segment_id": "tech_enthusiasts_25_35_sf",
    "geographic_region": "san_francisco"
  },
  "product_quantum_state": {
    "category": "electronics",
    "style": "minimalist",
    "price": "premium",
    "features": ["quality", "sustainability"],
    "attributes": {
      "energy_level": 0.7,
      "novelty": 0.8,
      "community_oriented": 0.6
    }
  }
}
```

#### 3. Community Influence Enrichment
```http
POST /community-influence
```

**Status:** ✅ Implemented (Section 21.2)

**Request Example:**
```json
{
  "user_segment": {
    "segment_id": "tech_enthusiasts_25_35_sf",
    "geographic_region": "san_francisco"
  },
  "product_category": "electronics"
}
```

---

## API Key Management

### Generate API Key

Use the Supabase SQL function to generate a new API key:

```sql
SELECT generate_api_key(
    'alibaba',                    -- partner_id
    100,                          -- rate_limit_per_minute
    10000,                        -- rate_limit_per_day
    NULL                          -- expires_at (NULL = no expiration)
);
```

**Important:** Store the returned plaintext API key securely. It cannot be retrieved later.

### API Key Format

POC keys: `spots_poc_{partner_id}_{random_hex}`

Example: `spots_poc_alibaba_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

---

## Rate Limiting

Default limits per API key:
- **Per Minute:** 100 requests
- **Per Day:** 10,000 requests

Rate limits are configurable per API key in the `api_keys` table.

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

### Common Error Codes

- `AUTHENTICATION_FAILED` - Invalid or missing API key
- `API_KEY_EXPIRED` - API key has expired
- `RATE_LIMIT_EXCEEDED` - Rate limit exceeded
- `ENDPOINT_NOT_FOUND` - Endpoint does not exist
- `PROCESSING_ERROR` - Internal server error
- `NOT_IMPLEMENTED` - Endpoint not yet implemented

---

## Development

### Local Development

```bash
# Start Supabase locally
supabase start

# Serve function locally
supabase functions serve ecommerce-enrichment
```

### Testing

```bash
# Test with curl
curl -X POST http://localhost:54321/functions/v1/ecommerce-enrichment/real-world-behavior \
  -H "Authorization: Bearer your_api_key_here" \
  -H "Content-Type: application/json" \
  -d '{"user_segment": {"segment_id": "test_segment"}}'
```

---

## Implementation Status

### ✅ Section 21.1: Foundation & Infrastructure
- [x] API gateway structure
- [x] API key authentication
- [x] Rate limiting
- [x] Request logging
- [x] Error handling
- [x] Database tables (migration 022)

### ✅ Section 21.2: Core Endpoints
- [x] Real-world behavior endpoint
- [x] Quantum personality endpoint
- [x] Community influence endpoint
- [x] Request validation
- [x] Response formatting
- [x] Error handling

### ⏳ Section 21.3: Integration Layer
- [ ] Sample e-commerce connector
- [ ] A/B testing framework
- [ ] Performance optimization

### ⏳ Section 21.4: Validation & Documentation
- [ ] A/B testing
- [ ] API documentation
- [ ] Integration guide

---

## Security

- API keys are hashed (SHA-256) before storage
- Rate limiting prevents abuse
- All requests are logged for audit
- Service role authentication for database access
- CORS headers configured for cross-origin requests

---

## References

- **POC Plan:** `docs/plans/ecommerce_integration/ECOMMERCE_DATA_ENRICHMENT_POC_PLAN.md`
- **Technical Specs:** `docs/plans/ecommerce_integration/TECHNICAL_SPECIFICATIONS_EXPANSION.md`
- **Checklist:** `docs/plans/ecommerce_integration/POC_CHECKLIST.md`
