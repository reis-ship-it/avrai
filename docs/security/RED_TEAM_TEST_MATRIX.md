# Red-Team Test Matrix (System Hijack + Data Security)

**Created:** February 19, 2026  
**Status:** Active Security Governance Artifact  
**Purpose:** Canonical offensive-simulation matrix for identifying and containing full-system hijack paths before production rollout.

---

## Scope

This matrix is the authoritative test contract for:
- account/session takeover,
- backend privilege escalation,
- secrets/CI supply-chain compromise,
- federated/AI2AI poisoning and channel hijack,
- encryption lifecycle downgrade gaps,
- BLE/discovery correlation leakage,
- third-party export re-identification risk,
- autonomy/policy hijack without direct infrastructure breach.

Use with:
- `docs/MASTER_PLAN.md` (Phase 2 + 10.9.x),
- `docs/PRD.md` (`PRD-020`, `PRD-021`, `PRD-022`),
- `docs/plans/security_implementation/SECURITY_IMPLEMENTATION_PLAN.md`,
- `docs/GITHUB_ENFORCEMENT_SETUP.md`.

---

## Execution Standard

Each test lane must declare:
1. Attack path and hijack outcome.
2. Preconditions and trust-boundary assumptions.
3. Required preventive controls.
4. Detection/alert expectation.
5. Recovery/rollback behavior.
6. Evidence artifact path.

All `Critical` lanes are release-blocking for autonomous scope expansion.

---

## Matrix

| Lane ID | Attack Surface | Hijack Outcome | Severity | Preconditions | Red-Team Test | Required Controls | Detection + Recovery Expectations | Master Plan Anchors |
|---|---|---|---|---|---|---|---|---|
| RT-001 | Auth/session | Account takeover | Critical | Stolen token/device state | Replay/rotation bypass simulation against session validation endpoints | Short-lived sessions, strict revocation, anomaly lockout, device binding | Detect token reuse anomalies; revoke all sessions; force re-auth and incident logging | 2.1, 10.9.9, 10.9.12 |
| RT-002 | Supabase/RLS | Privilege escalation, data exfiltration | Critical | Weak/missing policy constraints | Policy fuzzing on row-level reads/writes and cross-tenant access | Deny-by-default RLS, service-role isolation, policy regression tests | Block unauthorized query class; emit audit event; quarantine API key/token | 2.1, 9.2.6E, 10.9.7 |
| RT-003 | Secrets/CI | Build/deploy channel takeover | Critical | Exposed long-lived credentials in CI/dev | Attempt artifact tampering and credential replay in pipeline | Secret scanning, OIDC short-lived creds, protected envs, signed artifacts | Detect unsigned artifact or invalid provenance; fail closed in CI | 10.9.11, 10.9.13 |
| RT-004 | Federated updates | Model poisoning / policy drift | Critical | Unsigned or weakly validated update ingestion | Inject adversarial gradients/updates and replay stale signed payloads | Signed update attestation, replay nonce/timestamp checks, outlier/poisoning gates, reputation weighting | Quarantine bad cohort update; disable affected channel kill-switch; auto-rollback candidate | 8.1, 10.9.5, 10.9.10, 10.9.12 |
| RT-005 | Advisory channels | Locality strategy hijack | High | Advisory source credibility drift | Inject anomalous advisory payloads and credibility-spam patterns | Advisory quarantine mode, anomaly detectors, credibility decay, independent rollback | Advisory lane auto-disabled on anomaly threshold; evidence logged with trace IDs | 8.9, 10.9.6, 10.9.9 |
| RT-006 | Signal/PQ lifecycle | Confidentiality downgrade | Critical | Stale sessions or prekey exhaustion | Downgrade/fallback and old-session reuse simulation | PQXDH coverage audit, Kyber rotation/inventory alarms, no insecure fallback | Detect non-PQ session attempts; force rekey; track coverage SLO | 2.4, 2.5.1-2.5.8, 10.9.10 |
| RT-007 | BLE/discovery | Device/user correlation | High | Metadata leakage in discovery handshake | Traffic capture + linkage analysis on broadcast payloads | Rotating anonymized IDs, minimal beacon metadata, PQ-safe handshake tokens | Detect beacon-pattern linkage risk; rotate identities; enforce stricter beacon envelope | 2.5.4, 8.4.5, 10.9.12 |
| RT-008 | Third-party exports | Re-identification via aggregate data | Critical | Weak DP/k-anon enforcement | Join/aux-data attack simulations against export outputs | Epsilon accounting, k-anonymity floor, consent gate hard fail, retention + revocation controls | Reject risky export cells; suspend buyer key; alert compliance and log evidence | 2.2.3, 9.2.6A-9.2.6G, 10.9.9 |
| RT-009 | Autonomy lifecycle | Unsafe autonomous behavior hijack | Critical | Weak promotion/rollback governance | Force invalid self-update path bypassing shadow/canary controls | Immutable policy bounds, staged rollout, dual-signal rollback, human override SLA | Detect policy violation; hard stop promotion; rollback atomic bundle | 7.7, 7.7A, 10.9.3, 10.9.4, 10.9.11 |
| RT-010 | Logging/telemetry | Silent sensitive-data leakage | High | Insufficient redaction/classification | PII leak seeding through logs, traces, crash handlers | Data classification policy, redaction middleware, privacy lint checks | Detect sensitive payload in telemetry; purge, rotate keys/tokens if needed, open incident | 2.1.8, 10.9.9, 10.9.12 |
| RT-011 | Dependency/supply chain | Backdoor injection | High | Unpinned or unverified dependencies | Malicious dependency/update simulation on CI branch | Pinning, integrity/provenance checks, dependency review gates | Block unverified update; quarantine build lane and require signed override | 10.9.11, 10.9.13 |
| RT-012 | Admin/operator | Social/operational hijack | High | Over-privileged roles or weak runbooks | Privilege misuse simulation and break-glass abuse drill | Least privilege, 2-person approval for high-impact actions, audited break-glass path | Enforce human-review SLA; complete postmortem and policy hardening updates | 10.9.18, 10.9.12 |

---

## Evidence Contract

Every red-team cycle must produce:
- `run_id`
- environment (`staging`, `pre-prod`, `production-drill`)
- lanes executed
- pass/fail per lane
- blocked controls and remediation owners
- recurrence-risk classification
- reopen-by-new-milestone mapping if a completed milestone is re-opened

Evidence should be linked in:
- `docs/EXECUTION_BOARD.csv` milestone evidence fields,
- `docs/STATUS_WEEKLY.md` (including reopen event log),
- relevant PR validation notes.

---

## Cadence

- Weekly: Critical lanes (`RT-001`, `RT-002`, `RT-003`, `RT-004`, `RT-006`, `RT-008`, `RT-009`)
- Bi-weekly: High lanes
- Release gate: full matrix pass required before autonomous scope expansion or new third-party data product launch

