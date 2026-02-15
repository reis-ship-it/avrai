Deployment notes

Set the following secrets for both functions:

- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
- SERVICE_CALL_SECRET

Deploy:

```
supabase functions deploy coordinator --no-verify-jwt
supabase functions deploy rooms-agent --no-verify-jwt
```

Call (backend-only) with header `x-service-key: $SERVICE_CALL_SECRET`.

Endpoints:

- coordinator
  - GET /
  - POST /profile-summary { recipient_id, summary }
  - POST /dm { recipient_id, payload }
- rooms-agent
  - GET /
  - POST /create { metadata }
  - POST /join { room_id, agent_id, world_id, membership_proof }
  - POST /post { room_id, sender_agent_id, world_id, payload }

Identity contract (Master Plan Phase 2.7):

Canonical contract reference:
- `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`
- `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`

- `account_id`: auth/legal/billing identity (never sent to `rooms-agent` payloads).
- `agent_id`: learning and social interaction pseudonym (allowed in payloads).
- `world_id`: context/scope boundary for a specific interaction surface.

Practical migration from legacy payloads:

1. Keep compatibility support for legacy `{ user_id }` payloads for a short migration window.
2. At the edge, map legacy `user_id` to `account_id`, then resolve `agent_id` + `world_id` in a secure mapping service.
3. Rewrite payloads before function execution to the new shape (`agent_id`, `world_id`).
4. Emit migration audit events for every rewritten request.
5. Keep dual-read/dual-write only for a bounded window (target 14 days, hard max 30 days) while running parity checks.
6. Enforce strict cutoff: reject legacy `user_id` payloads after cutoff date (no silent fallback).
7. Remove compatibility adapters in the next release wave after cutoff verification.

Cross-system coherence requirement:
- Any function behavior affecting offline/online mode, transport, federation, disclosure, or migration cutover must map tests/evidence to applicable `RCM-*` scenarios in `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`.
