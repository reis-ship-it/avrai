# Ledger System (v0) — Strict Append-Only + Modifiable via Revisions

**Date:** 2026-01-02  
**Status:** DRAFT (ready for implementation)  
**Philosophy:** Doors must be truthful (receipts), not vibes  

---

## Executive Summary

This document defines a **single shared ledger framework** used across multiple SPOTS subsystems:

- Expertise / Events / Communities / Clubs / Partnerships
- Payments / Refunds / Payouts / Revenue splits
- Moderation / Safety actions
- Identity & business verification
- Security events (key rotations, auth events, policy blocks)
- Geo expansion
- Model lifecycle (local LLM / packs)
- Admin exports + outside-buyer ops
- Device capability changes

**Strict append-only** means:
- No UPDATE / DELETE by authenticated users
- Corrections happen by inserting a new revision row (`op = amend|void|restate`)
- “Current truth” is computed as latest revision per logical event

---

## Core design (Journal + Current View)

### Journal
An append-only table where each row is a “receipt”:
- what happened (`event_type`, payload)
- who owns it (`owner_user_id`, `owner_agent_id`)
- what it relates to (`entity_type`, `entity_id`, geo codes)
- revision semantics (`logical_id`, `revision`, `supersedes_id`, `op`)

### Current view
A view that returns only the **latest** row per `logical_id` (max revision).

This keeps “truth” immutable while giving product code an easy, fast “current state” surface.

---

## Operations (the only allowed mutations)

All “mutations” are inserts:

### 1) Assert
Create a new logical event (defaults: `op=assert`, `revision=0`, `logical_id=new uuid`)

### 2) Amend
Correct or update an event’s details by inserting a new revision:
- same `logical_id`
- `revision = previous + 1`
- `supersedes_id = previous row id`
- `op = amend`

### 3) Void
Invalidate an event (e.g., fraud, mistaken record):
- same `logical_id`
- new revision with `op = void`
- payload includes `void_reason`, `voided_by`

### 4) Restate
Re-enable an event after a void (rare, but possible):
- new revision with `op = restate`

---

## Shared schema (Supabase/Postgres)

The v0 schema is implemented in:
- `supabase/migrations/058_ledgers_v0.sql`

The key tables/views are:
- `public.ledger_events_v0` (journal)
- `public.ledger_current_v0` (latest revision per logical_id)
- `public.ledger_audience_v0` (optional multi-party read grants)

---

## RLS model (exact shape)

### Ownership
RLS is enforced by `owner_user_id = auth.uid()` (aligned with:
`supabase/migrations/035_interaction_events_userid_rls_and_drop_plain_mappings.sql`).

### Read access
Two supported shapes:

1. **Owner-only** (default)
   - User can read only their own rows

2. **Owner-or-audience** (for partnerships/communities)
   - User can read rows they own OR rows explicitly shared to them via `ledger_audience_v0`
   - Audience grants should be minted by service-role code (server-side), not directly by clients

### Write access
- Users can insert rows where `owner_user_id = auth.uid()`
- No UPDATE/DELETE policies for authenticated users (append-only)
- Optional strict insert check: if `supersedes_id` is set, it must point to a row owned by the same user and same `logical_id`

---

## Canonical naming

The shared ledger uses:
- `domain` to bucket “which ledger” (expertise, payments, moderation, etc.)
- `event_type` to specify “what happened”

This allows:
- One schema for many ledgers
- Domain-specific filtered views for convenience and performance

---

## Payload rules (v0)

- Payload is JSONB for flexibility.
- v0 payloads should include:
  - `schema_version` (int, default 0)
  - `source` (e.g., `client`, `edge_function`, `service_role_pipeline`)
  - `correlation_id` (optional; useful for tracing multi-step flows)

**Rule:** Always include enough to explain “why this door opened.”

