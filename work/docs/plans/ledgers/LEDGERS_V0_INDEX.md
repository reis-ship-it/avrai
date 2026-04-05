# Ledgers (v0) — Index

**Date:** 2026-01-02  
**Status:** DRAFT (ready for implementation)  
**Purpose:** Single entry point for all v0 ledgers (strict append-only journals + canonical views)  

---

## Why ledgers exist in SPOTS

SPOTS is a “doors” system. Doors must be **truthful** and **explainable**:
- “Why can I host expert events?”
- “Why can this partnership be locked?”
- “Why did I get refunded?”
- “Why was this account banned / unbanned?”

A **ledger** gives receipts:
- Append-only history (no silent rewrites)
- Explicit corrections via revisions (amend/void/restate)
- A single canonical “current state” view derived from revisions

---

## v0 Ledger System

- **Core spec (schema + RLS + operations):** `LEDGER_SYSTEM_V0.md`
- **Domain event catalog (what events exist per system):** `LEDGER_EVENT_CATALOG_V0.md`

---

## Implementation (Supabase)

This v0 ledger system is backed by:
- `supabase/migrations/058_ledgers_v0.sql`

---

## How to query receipts (developer quick reference)

### Query a single run (correlation id)

Use this for proof runs, device smokes, and any multi-step workflow where you want an ordered audit trail.

```sql
select
  occurred_at,
  domain,
  event_type,
  entity_type,
  entity_id,
  payload
from public.ledger_events_v0
where payload->>'correlation_id' = '<RUN_ID>'
order by occurred_at asc, created_at asc;
```

### Query “current truth” for a logical event

If a receipt was amended/voided/restated, `ledger_current_v0` returns only the latest revision.

```sql
select
  id,
  logical_id,
  revision,
  op,
  occurred_at,
  domain,
  event_type,
  entity_type,
  entity_id,
  payload
from public.ledger_current_v0
where logical_id = '<LOGICAL_ID>';
```

### Query receipts for an entity (across revisions)

```sql
select
  occurred_at,
  domain,
  event_type,
  logical_id,
  revision,
  op,
  payload
from public.ledger_events_v0
where entity_type = '<ENTITY_TYPE>'
  and entity_id = '<ENTITY_ID>'
order by occurred_at asc, revision asc;
```

### Notes (audit gating)

- Runtime “audit receipts” are intentionally opt-in and correlation-id driven via:
  - `--dart-define=SPOTS_LEDGER_AUDIT=true`
  - `--dart-define=SPOTS_LEDGER_AUDIT_CORRELATION_ID=<RUN_ID>`
- The best-effort emitter is `lib/core/services/ledgers/ledger_audit_v0.dart`.

---

## Related architecture docs

- `docs/plans/architecture/EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`

