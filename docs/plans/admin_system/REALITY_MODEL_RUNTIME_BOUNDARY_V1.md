# Reality Model Runtime Boundary (v1)

Date: 2026-02-28

## Decision
- Admin app remains control-plane UI only.
- Reality model runtime should execute in internal backend services (or dedicated host) and not as an in-app process.

## Enforcement path
1. Admin UI emits control requests through backend APIs/services only.
2. Backend executes model control actions and writes immutable audit entries.
3. Admin UI reads projected state and audit trails; it does not directly mutate runtime internals.

## Current implementation status
- `ResearchActivityService` now includes control-action audit recording.
- Internal backend adapter writes to `admin_research_control_actions`.
- Migration `090_admin_research_governance_extensions_v1.sql` provisions the audit table.

## Why this boundary
- Better isolation for safety and privacy.
- Independent scaling and fault domains.
- Stronger forensic trail for oversight and compliance.

## Next hardening steps
1. Enforce signed control commands with request IDs and replay protection.
2. Add backend-side policy engine for allow/deny checks before execution.
3. Add alerting on suspicious control patterns (high-frequency changes, repeated rejects).
