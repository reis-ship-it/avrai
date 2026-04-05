# Phase 2 Rationale: Privacy, Compliance & Legal Infrastructure

**Phase:** 2 | **Tier:** 0 (Blocks business features; legal necessity) | **Duration:** 3-4 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 2  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #4, #15)

---

## Why This Phase Exists

The ML Roadmap (Section 13) identified that GDPR compliance is a **legal requirement**, not a policy decision. The legacy plan incorrectly marked Operations & Compliance as "policy-gated," implying it could wait. It can't. You cannot collect outcome data (Phase 1) or train models on user behavior without privacy infrastructure.

---

## Why Tier 0 and Parallel with Phase 1

Phase 2 runs alongside Phase 1 because:
- Phase 1 starts collecting user behavior data -- that data collection NEEDS consent infrastructure
- Phase 9 (business features) requires compliance before handling payments and partnerships
- Post-quantum cryptography has a deadline driven by adversaries, not by our roadmap

They don't block each other: Phase 1 builds the data pipeline, Phase 2 ensures it's legally and cryptographically sound.

---

## Key Design Decisions

### Why GDPR First, Not "Compliance Later"
Every day of outcome data collection without proper consent infrastructure is a legal liability. GDPR requires:
- Explicit opt-in consent for each data type
- Right to deletion (including episodic memory, quantum states, knot data)
- Right to data export
- Consent revocation with data cleanup

Building Phase 1 outcome collection without Phase 2 consent means the data collected might need to be thrown away if users can't retroactively consent.

### Why Progressive Consent (2.1.6)
Don't dump a wall of consent checkboxes on a new user. Ask for personality learning consent first (it's the core value prop). Defer AI2AI, cross-app, and wearable consent until those features become relevant. This respects the user's attention and gets better consent quality.

### Why Signal Protocol Default Activation (2.4)
Signal Protocol is fully implemented but NOT yet the default. Activating it:
- Provides end-to-end encryption for all 5 chat services
- Enables trust features for the world model (Phase 3.1.14: Signal trust metrics as features)
- Establishes the encrypted transport for AI2AI communication

### Why Post-Quantum NOW (2.5)
"Harvest now, decrypt later" -- adversaries can record encrypted traffic today and decrypt it when quantum computers arrive. Every Signal session established without Kyber KEM is retroactively vulnerable. Phase 2.5 ensures:
- All new sessions use PQXDH (Kyber + X3DH hybrid)
- Old sessions without Kyber get re-keyed within 7 days
- Kyber prekey exhaustion is monitored (silent fallback to non-PQ is prevented)
- BLE discovery, federated gradients, and cloud transport get PQ treatment too

### Why Differential Privacy Budget Tracking (2.2.3)
When you add Laplace noise to protect privacy, you spend "privacy budget" (epsilon). Without tracking cumulative epsilon per user, you can't prove privacy guarantees. Every gradient shared (Phase 8), every vibe signature exchanged (AI2AI), every cloud upload consumes epsilon. Track it from day one.

### Why Zero Trust Credential Infrastructure (2.7)
AVRAI's AI agents use non-human identities and communicate autonomously. In the age of agentic AI, every agent credential is an attack surface. Static credentials (API keys baked into builds, agent IDs stored permanently) violate the core zero trust principle: never trust, always verify. `SecretVaultService` (2.7.1) introduces dynamic credential lifecycle — just-in-time provisioning, automatic rotation, and scoped access grants. This mirrors how a zero trust credential vault works: credentials are checked out when needed, scoped to the minimum required access, and automatically expire. Certificate pinning (2.7.5) closes the gap where all non-Signal HTTP traffic is currently unpinned — a man-in-the-middle could intercept Supabase API calls without it.

### Why Continuous Verification (2.8)
Traditional authentication is a single checkpoint: verify once at login, then trust forever. Zero trust replaces this with continuous re-verification. `ContinuousVerificationService` (2.8.1) re-validates session integrity at regular intervals — detecting device compromise, session token theft, and anomalous behavior. Step-up authentication (2.8.2) ensures that high-impact operations (data export, account deletion, admin actions) require re-authentication even within an active session. Session binding to device fingerprint (2.8.3) prevents stolen session tokens from being usable on a different device. Together, these implement the "assume breach" principle: even if an attacker gets a valid session token, continuous verification limits the damage window.

### Why Data Transparency (2.1.8-2.1.8C)
**"What My AI Knows" page:** Users need to see what data their AI uses to make recommendations. This builds trust, supports informed consent, and aligns with GDPR spirit -- not just the letter. Knowing "my AI knows I prefer jazz on weekends" is different from abstract legalese. The page surfaces categories (personality data, visit history, preferences, mesh signals) without exposing raw records.

**"Why this recommendation?" — template-based, not LLM-generated:** Two reasons. First, **privacy**: an LLM could hallucinate or leak private data in free-form explanations. Templates pull only from verified feature values. Second, **speed**: templates are instant; LLM inference adds latency and cost. The "why" is shown inline with the recommendation; it must be sub-100ms.

**Data correction mechanism:** If a user sees "my AI thinks I love late-night spots" and that's wrong, they need a way to correct it. The correction closes the transparency-learning feedback loop: show data → user corrects → model learns. Without correction, transparency is one-way and the model can't improve from user feedback on its understanding.

**Connection to Phase 4.6.1:** Feature attribution (which features drove this score?) provides the raw data for explanations. The templates consume attribution outputs to produce human-readable "why" text. Phase 2 builds the UI and correction flow; Phase 4.6.1 supplies the attribution inputs.

---

## Pre-Flight Checklist for Phases That Depend on Phase 2

**Before starting Phase 3 (State Encoders):**
- [ ] Signal Protocol is the default for all chat services (2.4.1-2.4.4)
- [ ] `SignalProtocolService.getSessionStats()` API exists (2.4.6) -- required by state encoder feature 3.1.14
- [ ] Consent infrastructure allows opt-in for personality learning and outcome tracking

**Before starting Phase 6 (MPC Planner / Agent):**
- [ ] `SecretVaultService` is operational with JIT credential provisioning (2.7.1-2.7.2)
- [ ] Certificate pinning is active for Supabase and external API endpoints (2.7.5)
- [ ] `ContinuousVerificationService` is running with configurable verification interval (2.8.1)

**Before starting Phase 8 (Federated Learning):**
- [ ] Differential privacy (Laplace noise) is implemented for gradient sharing (2.2.1)
- [ ] Privacy budget tracking (epsilon accounting) is active (2.2.3)
- [ ] Post-quantum protection covers BLE mesh (2.5.4) and federated gradients (2.5.5)

**Before starting Phase 9 (Business Operations):**
- [ ] Compliance infrastructure (refund policy, tax compliance, fraud prevention) is in place (2.3)
- [ ] GDPR consent covers business data collection scenarios

---

## Common Pitfalls

1. **Treating consent as a checkbox**: Consent UX must be clear about what each consent covers. "We collect data" is not valid consent under GDPR.
2. **Forgetting consent-revocation world model handling (2.1.9)**: When a user revokes outcome tracking consent, their episodic memory must be purged. But DP guarantees mean existing model weights are safe.
3. **Assuming TLS is enough for cloud transport (2.5.6)**: TLS 1.3 uses ECDHE, which is quantum-vulnerable. Application-layer encryption is needed until PQ-TLS is available from Supabase.
4. **Treating zero trust as a perimeter problem**: Zero trust is NOT "build a better firewall." It's "assume the firewall is already breached and design accordingly." Credential rotation (2.7.3), continuous verification (2.8.1), and session binding (2.8.3) are the defense-in-depth controls that limit damage when (not if) a breach occurs.
5. **Hardcoding credentials during development**: Developers under time pressure will embed API keys in source code. CI gate (2.7.4) catches this automatically. No exceptions.

---

**Last Updated:** March 5, 2026 -- Version 1.2 (added zero trust credential infrastructure 2.7, continuous verification 2.8, updated pre-flight checklist and pitfalls. Previous: 1.1 v12 gap fill)
