# 10 - Security, Privacy, and Trust Architecture

## 1) Security Responsibility Split

### Runtime OS
- key management,
- secure transport sessions,
- attestation,
- policy kernel enforcement,
- privileged capability mediation.

### Engine
- trust-aware planning,
- uncertainty-aware outputs,
- contradiction handling,
- evidence linkage.

### Product
- user-visible security controls,
- consent/recourse UX,
- operational review surfaces.

## 2) Threat Model Categories

1. Transport channel poisoning
2. Federated/advisory update tampering
3. Identity/session hijack
4. Policy bypass attempts
5. Cross-layer privilege escalation
6. Cross-OS inconsistency exploitation

## 3) Required Control Patterns

1. Signed update and payload attestation.
2. Participant reputation weighting.
3. Scoped kill switches by learning channel.
4. Runtime fail-closed policy checks.
5. Deterministic ledgering for incidents and remediations.
6. Periodic red-team matrix execution with release gating.

## 4) Trust and Adoption Distinction

Maintain separate confidence channels:
- model confidence (truth likelihood)
- adoption confidence (will user/system trust and act)

Use pilot/conservative routing when channels diverge.

## 5) Privacy Layers

1. On-device protected stores for sensitive state.
2. Runtime-level key isolation and rotation.
3. Federated/third-party output minimization and DP controls.
4. Explicit retention windows and purge workflows.

## 6) Recourse Safety

High-impact outputs must support:
- challenge assumption,
- conservative variant,
- uncertainty view,
- reversible pilot mode.

## 7) Cross-OS Security Baseline

Each OS adapter must provide evidence for:
1. secure key storage implementation,
2. transport confidentiality/integrity,
3. lifecycle hardening for background/foreground transitions,
4. policy enforcement consistency.

## 8) Auditability

Mandatory fields for all high-impact decisions:
- engine/runtime/host/policy versions,
- evidence IDs,
- assumptions,
- blocked alternatives and reason,
- applied guardrails.

