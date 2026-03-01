# Outside Buyer API: Paid Access and Rate Limits

**Status:** Active reference  
**Purpose:** Document that third-party access to the outside-buyer insights API is paid-only and how rate limits and API keys are enforced.

---

## Paid Access

- **Third-party access to the outside-buyer insights API is paid-only.** API keys for this API are issued only to data buyers who have completed billing/entitlement (e.g. contract, payment, or approved partnership). Key issuance is tied to a billing/entitlement hook (see **Billing hook** below).
- **API key auth:** All requests to the `outside-buyer-insights` Edge Function require a valid API key in the `Authorization` header (`Bearer {api_key}` or `ApiKey {api_key}`). Keys are stored in `api_keys`; only keys with `partner_id` prefix `outside_buyer_*` are accepted for this endpoint.
- **Scope:** Keys with `partner_id` starting with `outside_buyer_` are the only keys that can call the outside-buyer insights API. Other keys receive `UNAUTHORIZED_KEY_SCOPE`.

### Billing hook (entitlement table + RPC)

- **Entitlements table:** `outside_buyer_entitlements` (migration `086_outside_buyer_entitlements_and_key_creation.sql`) stores partner_id, status, valid_until, billing_reference. Only rows with `status = 'active'` and `valid_until > NOW()` are considered valid.
- **Key creation RPC:** `create_outside_buyer_api_key(p_partner_id, p_billing_reference, p_api_key_plain, ...)` is the **only** supported path to create an outside_buyer key. It checks for a valid entitlement row; if none exists, it raises and no key is created. Callable only by `service_role`.
- **Ops workflow:** 1) Create entitlement row (after contract/payment); 2) Call RPC with partner_id, billing_reference, and a generated API key (min 16 chars); 3) Store the plain key securely for the buyer; it is not returned by the RPC. Key creation fails when entitlement is missing or expired, enforcing paid-only access.

---

## Rate Limits

- **Per key:** Rate limits are enforced per API key using `api_request_logs`. Defaults (configurable per key in `api_keys`): `rate_limit_per_minute` (e.g. 60), `rate_limit_per_day` (e.g. 5000). When exceeded, the Edge Function returns `429 RATE_LIMIT_EXCEEDED`.
- **Query policy:** Time range, geo scope, and filter dimensions are bounded (e.g. max 90 days per request for day granularity, max 50 geo_bucket_ids, max filter dimensions per granularity). See [OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md](OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md).

---

## Logging and Audit

- Every request is logged to `api_request_logs` (api_key_id, endpoint, method, response_status, processing_time_ms). Exports and query fingerprints are used for intersection-attack hardening and privacy-budget accounting; see the contract doc and runbook.
