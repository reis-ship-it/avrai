# Expertise Ledger + Capabilities (Strict Append-Only) — v1

**Date:** 2026-01-02  
**Status:** DRAFT (ready for implementation)  
**Owner:** Core Architecture  
**Related Master Plan:** Section 29 (6.8) Clubs/Communities; Expertise/Events/Partnerships integration  

---

## 🚪 Doors / Philosophy Alignment

**What doors does this open?**
- **Truth door:** We can explain *why* a user has permissions (expert hosting, partnerships, club leadership) from recorded facts.
- **Reliability door:** Expertise and capabilities become stable across app restarts/devices (local-first + syncable).
- **Learning door:** Outcome-weighted contributions become possible without inventing ad-hoc boosts.

**Core principle:** *Facts first. Capabilities derived. Outcomes weight facts. Trust secures the whole loop.*

---

## Executive Summary

We need a **single source of truth** for expertise-related reality that:

1. Is a **true ledger** (history preserved; tamper-resistant; explainable)
2. Is **modifiable** in the sense that corrections are allowed
3. Supports a single **Capabilities API** so product gates do not drift from scoring logic

This document specifies:
- A **strict append-only ledger** schema (no UPDATE/DELETE; edits are new revisions)
- **Exact Supabase RLS policy shapes** aligned with current patterns (notably `user_id`-based RLS as in `interaction_events`)
- A **minimal Capabilities API** (Dart interface-level contract)
- A **migration path** from today’s `UnifiedUser.expertiseMap` gating to ledger-based gating **without breaking anything**

---

## Terms & Definitions

### Journal vs “modifiable”

**Strict append-only** means:
- Ledger rows are **never updated** and **never deleted** (except service-role emergency operations).
- Any “edit” is expressed as a **new row** that supersedes a previous row.
- The canonical “current state” is obtained by selecting the **latest revision** per logical event.

**Modifiable** means:
- Corrections are possible, but only through **revision events** (amend/void/restate).
- The system retains the *full chain* of revisions for audit/explainability.

### Logical event identity

We distinguish:
- `id`: unique database row id
- `logical_id`: stable identifier for “the same event concept” across revisions
- `revision`: monotonically increasing integer per `logical_id`
- `supersedes_id`: pointer to the immediate prior row (optional but recommended)

---

## Architecture: Data Flow (High-level)

```
User actions + system outcomes
        ↓
Ledger Recorder (local-first; optionally remote sync)
        ↓
Append-only Ledger (truth journal with revision chain)
        ↓
Canonical “current” view (latest revision per logical_id)
        ↓
Capabilities Service (single gatekeeper)
        ↓
Existing product services (events, partnerships, clubs/communities)
```

---

## Ledger Schema (Supabase/Postgres) — v1

### Table: `public.expertise_ledger_events_v1` (append-only journal)

**Design goals:**
- Fast inserts
- Easy to replay/derive snapshots
- RLS-safe without needing plaintext `user_id ↔ agent_id` joins

```sql
-- Expertise Ledger (append-only) — v1
create table if not exists public.expertise_ledger_events_v1 (
  id uuid primary key default gen_random_uuid(),

  -- Ownership for RLS (align with 035_interaction_events_userid_rls_and_drop_plain_mappings.sql)
  owner_user_id uuid not null references auth.users(id) on delete cascade,

  -- Privacy-safe routing identifier (stored but NOT used for RLS)
  owner_agent_id text not null,

  -- Revision chain
  logical_id uuid not null,
  revision int not null check (revision >= 0),
  supersedes_id uuid references public.expertise_ledger_events_v1(id) on delete restrict,

  -- Operation semantics (append-only corrections)
  op text not null check (op in ('assert', 'amend', 'void', 'restate')),

  -- Classification
  event_type text not null,        -- e.g. expert_event_completed, partnership_locked
  entity_type text,               -- event | community | club | partnership | list | review | visit
  entity_id text,                 -- app ids are often text (community_id is text in communities_v1)
  category text,                  -- optional (Coffee, Music, etc.)

  -- Geo scope (align with ExpertiseEvent.cityCode/localityCode)
  city_code text,
  locality_code text,

  -- Core timestamps
  occurred_at timestamptz not null,
  atomic_timestamp_id text,        -- optional: aligns with atomic timing pipeline

  -- Payload
  payload jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

-- Uniqueness of revision numbering per logical event
create unique index if not exists ux_expertise_ledger_logical_revision
  on public.expertise_ledger_events_v1 (logical_id, revision);

-- Fast lookup by owner + time
create index if not exists idx_expertise_ledger_owner_time
  on public.expertise_ledger_events_v1 (owner_user_id, occurred_at desc);

-- Fast lookup by entity
create index if not exists idx_expertise_ledger_entity
  on public.expertise_ledger_events_v1 (entity_type, entity_id, occurred_at desc);

-- Fast lookup by type/category
create index if not exists idx_expertise_ledger_type_category_time
  on public.expertise_ledger_events_v1 (event_type, category, occurred_at desc);
```

#### Canonical view: “latest revision per logical_id”

```sql
create or replace view public.expertise_ledger_current_v1 as
select distinct on (logical_id)
  *
from public.expertise_ledger_events_v1
order by logical_id, revision desc, created_at desc;
```

**Why a view (not a materialized table)?**
- Keeps ledger strictly append-only
- Avoids needing “mark old row superseded” updates
- “Current state” is derived deterministically

---

## Ledger Event Taxonomy (Minimal Set)

These event types cover the current product graph (events → communities/clubs → partnerships → expertise).

### Events
- `expert_event_created`
- `expert_event_completed`
- `community_event_created`
- `community_event_completed`

**Payload recommendations:**
- attendance metrics (attendeeCount, repeatAttendeesCount)
- quality metrics (engagementScore, diversityMetrics, rating aggregates)
- safety outcomes (if available)
- `city_code`, `locality_code`

### Communities / Clubs
- `community_created_from_event`
- `community_joined`
- `community_left`
- `community_upgraded_to_club`
- `club_role_granted` / `club_role_revoked`

### Partnerships
- `partnership_proposed`
- `partnership_locked`
- `partnership_completed`
- `partnership_disputed`
- `partnership_resolved`

### Classic expertise contributions (optional but recommended)
- `list_created`
- `list_respected`
- `review_written`
- `visit_logged`

---

## Exact RLS Policy Shape (Supabase)

### Why `owner_user_id`-based RLS

Newer migrations moved away from plaintext mapping joins (see `supabase/migrations/035_interaction_events_userid_rls_and_drop_plain_mappings.sql`), and enforce ownership via `user_id = auth.uid()`.

We follow that exact model:
- **RLS enforced by `owner_user_id`**
- `owner_agent_id` stored for privacy-safe ai2ai routing, but not used for RLS joins

### Base policies (strict append-only)

```sql
alter table public.expertise_ledger_events_v1 enable row level security;

-- Read: user can read rows they own
drop policy if exists expertise_ledger_v1_select_own on public.expertise_ledger_events_v1;
create policy expertise_ledger_v1_select_own
  on public.expertise_ledger_events_v1
  for select
  to authenticated
  using ((select auth.uid()) = owner_user_id);

-- Insert: user can insert rows they own
drop policy if exists expertise_ledger_v1_insert_own on public.expertise_ledger_events_v1;
create policy expertise_ledger_v1_insert_own
  on public.expertise_ledger_events_v1
  for insert
  to authenticated
  with check ((select auth.uid()) = owner_user_id);

-- No UPDATE / DELETE policies: strict append-only by default-deny.

-- Service role: internal pipelines can read/insert everything (optional but common)
drop policy if exists expertise_ledger_v1_service_role_all on public.expertise_ledger_events_v1;
create policy expertise_ledger_v1_service_role_all
  on public.expertise_ledger_events_v1
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
```

### Optional: constrain amendments so users cannot “amend someone else’s logical_id”

If you allow clients to insert `amend/void/restate` rows, you should enforce that:
- if `supersedes_id` is non-null, the superseded row is also owned by `auth.uid()`

```sql
drop policy if exists expertise_ledger_v1_insert_own_strict on public.expertise_ledger_events_v1;
create policy expertise_ledger_v1_insert_own_strict
  on public.expertise_ledger_events_v1
  for insert
  to authenticated
  with check (
    (select auth.uid()) = owner_user_id
    and (
      supersedes_id is null
      or exists (
        select 1
        from public.expertise_ledger_events_v1 prev
        where prev.id = supersedes_id
          and prev.owner_user_id = (select auth.uid())
          and prev.logical_id = expertise_ledger_events_v1.logical_id
      )
    )
  );
```

### Multi-party visibility (communities, partnerships) — recommended shape

Many ledger events are *legitimately relevant* to multiple users (e.g., partnership lifecycle, community join/leave).

**Strict append-only rule still holds.** We add a separate audience table, also append-only, to grant read access.

```sql
create table if not exists public.expertise_ledger_audience_v1 (
  ledger_row_id uuid not null references public.expertise_ledger_events_v1(id) on delete cascade,
  audience_user_id uuid not null references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by text not null check (granted_by in ('service_role', 'system')),
  primary key (ledger_row_id, audience_user_id)
);

alter table public.expertise_ledger_audience_v1 enable row level security;

-- Audience rows are sensitive; recommend service-role only writes.
create policy expertise_ledger_audience_v1_select_own
  on public.expertise_ledger_audience_v1
  for select
  to authenticated
  using ((select auth.uid()) = audience_user_id);

create policy expertise_ledger_audience_v1_service_role_all
  on public.expertise_ledger_audience_v1
  for all
  using ((select auth.role()) = 'service_role')
  with check ((select auth.role()) = 'service_role');
```

Then expand ledger SELECT policy to include audience grants:

```sql
drop policy if exists expertise_ledger_v1_select_own_or_audience on public.expertise_ledger_events_v1;
create policy expertise_ledger_v1_select_own_or_audience
  on public.expertise_ledger_events_v1
  for select
  to authenticated
  using (
    (select auth.uid()) = owner_user_id
    or exists (
      select 1
      from public.expertise_ledger_audience_v1 aud
      where aud.ledger_row_id = expertise_ledger_events_v1.id
        and aud.audience_user_id = (select auth.uid())
    )
  );
```

**Recommendation:** for multi-party grants, do not let clients mint audience rows directly; use service-role via server functions that validate membership/rights.

---

## Minimal Capabilities API (Dart) — v1

### Goals
- Replace scattered gates (`canHostEvents()`, ad-hoc checks) with a **single gatekeeper**
- Support a **fallback** path so we can migrate without breaking

### Core types

```dart
/// A capability is a “door” the user may open.
enum Capability {
  hostExpertEvent,
  proposePartnership,
  lockPartnership,
  upgradeCommunityToClub,
  performExpertValidation,
}

/// Explainable decision for UI + logs.
class CapabilityDecision {
  final bool allowed;
  final String code; // e.g. "ok", "missing_expertise", "insufficient_outcome_quality"
  final String message; // user-safe summary
  final Map<String, Object?> evidence; // optional: ledger facts ids / derived score snapshot

  const CapabilityDecision({
    required this.allowed,
    required this.code,
    required this.message,
    this.evidence = const {},
  });
}
```

### Service interface (minimal)

```dart
abstract class CapabilitiesService {
  /// Expert-hosted events (category + geo scoped).
  Future<CapabilityDecision> canHostExpertEvent({
    required String userId,
    required String category,
    String? cityCode,
    String? localityCode,
    DateTime? atTime,
  });

  /// Partnerships are downstream of events; gate by event status + expertise + outcomes.
  Future<CapabilityDecision> canProposePartnership({
    required String userId,
    required String eventId,
    DateTime? atTime,
  });

  /// Clubs are structured communities; gate by community growth metrics + leadership rights.
  Future<CapabilityDecision> canUpgradeCommunityToClub({
    required String userId,
    required String communityId,
    DateTime? atTime,
  });

  /// Higher-level gate (regional+), used for expert validation / curation.
  Future<CapabilityDecision> canPerformExpertValidation({
    required String userId,
    required String category,
    DateTime? atTime,
  });
}
```

### Capability evaluation rule shape (v1)

**Input:** canonical ledger view (`expertise_ledger_current_v1`) + optionally last-N history from journal  
**Output:** `CapabilityDecision` with explanation + evidence

**Important:** v1 should be permissive (fallback-friendly) and deterministic.

---

## Migration Path: `expertiseMap` → ledger-based gating (no breakages)

### Why migration is needed

Today many gates rely on `UnifiedUser.expertiseMap` and helpers like `canHostEvents()` and `hasExpertiseIn()` (see `lib/core/models/unified_user.dart`). Some services enforce gates directly (e.g., `ExpertiseEventService.createEvent`, `PartnershipService.checkPartnershipEligibility`).

We will migrate in phases to avoid breaking:
- production flows
- tests
- old UI that expects `expertiseMap`

### Phase 0 — Schema + repositories (no behavior change)

1. Add Supabase tables/views for `expertise_ledger_events_v1` and `expertise_ledger_current_v1`
2. Add a local-first repository (local store + optional sync) **without changing gates**

### Phase 1 — Dual-write (still read `expertiseMap`)

Instrument existing flows to emit ledger rows:
- Expert event created/completed
- Community event completed + community created
- Partnership proposed/locked/completed/disputed
- Community join/leave
- Club upgrade + role changes

**Key rule:** dual-write must be best-effort and must never block the UX.

### Phase 2 — Introduce CapabilitiesService (read ledger, fallback to `expertiseMap`)

Implement `CapabilitiesService` with a strict policy:
- Prefer ledger-derived decisions when enough facts exist
- Fallback to current `expertiseMap` gates when ledger is incomplete

This makes the ledger “real” without breaking: gates still open exactly as they do today when the ledger is empty.

### Phase 3 — Route gates through CapabilitiesService (keep fallback)

Replace direct checks in key services with CapabilitiesService decisions:
- `ExpertiseEventService.createEvent()` → `canHostExpertEvent`
- `PartnershipService.checkPartnershipEligibility()` → `canProposePartnership` (plus business verification checks)
- `ClubService.upgradeToClub()` → `canUpgradeCommunityToClub` (or keep existing criteria but route through capability)

**Compatibility contract:** for an initial period, CapabilitiesService must emulate existing behavior using fallback.

### Phase 4 — Backfill + materialize derived caches (still keep `expertiseMap`)

Create a background “materializer” that:
- derives expertise snapshots from ledger facts
- writes them into `expertiseMap` as a cache for old UI and for cross-service compatibility

This reduces drift while still supporting legacy code paths.

### Phase 5 — Flip the default (ledger first, expertiseMap as cache)

At this point:
- All gates consult ledger-derived capability decisions first
- `expertiseMap` is treated as a stale-but-available cache
- Tests should assert capability results, not raw `expertiseMap` strings

### Phase 6 — Deprecate direct `expertiseMap` gating

When metrics show coverage is sufficient:
- remove direct checks where feasible
- keep `expertiseMap` only for display (pins/UX), sourced from ledger-derived snapshots

---

## Implementation Notes / Non-Goals (v1)

### v1 non-goals
- Full trust/anti-gaming scoring
- Full outcome-weighting across all contribution types
- Server-side aggregation jobs (materialized views) beyond the canonical “current” view

### v1 must-haves
- Strict append-only semantics (no UPDATE/DELETE for authenticated users)
- Deterministic revision chain per `logical_id`
- CapabilitiesService with fallback so nothing breaks

---

## Appendix A: How this aligns with existing Supabase patterns

- **Immutable audit:** `audit_logs` explicitly disallows updates/deletes (`supabase/migrations/010_audit_log_table.sql`)
- **User ownership RLS:** `interaction_events.user_id` policy uses `(select auth.uid()) = user_id` (`supabase/migrations/035_interaction_events_userid_rls_and_drop_plain_mappings.sql`)
- **Community membership RLS:** user-owned membership rows (`supabase/migrations/057_communities_v1_memberships_and_vibe_contributions.sql`)

Ledger should follow the same “ownership first” strategy.

