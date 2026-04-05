# Phase 9 Rationale: Business Operations & Monetization

**Phase:** 9 | **Tier:** Parallel (depends on Phase 2 compliance) | **Duration:** 6-8 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 9  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #12, #14)

---

## Why This Phase Exists

The world model is the intelligence layer. Phase 9 is the business layer -- the features that generate revenue. It runs in PARALLEL with the intelligence phases because:
- Business-critical services (payments, reservations, verification) are already production-ready
- Revenue features don't need the full world model to launch
- Compliance infrastructure (Phase 2) is the only hard dependency

---

## Key Design Decisions

### Why 15 Services Are "Preserve As-Is" (9.1)
Payment, reservation, encryption, legal, verification, fraud detection, audit logging, and ledger services are production-ready and independent of the world model. They don't contain scoring formulas to replace. Touching them creates risk for zero intelligence gain.

### Why Business Features Run in Parallel
Services Marketplace, Brand Discovery, Event Partnership, Expert Communication -- these can launch with existing formulas while the world model is being built. When the energy function is ready (Phase 4), these features upgrade automatically through the formula replacement schedule.

### Why the World Model Improves Business Features (9.3)
The connection is indirect but powerful:
- Better expert-business matching (Phase 4.2.9, 4.4.8) → higher partnership conversion
- Better event recommendations (Phase 4.2.8) → higher ticket sales
- Better reservation matching (Phase 4.2.6) → lower no-show rates
- Better data insights → higher-value aggregate data products

Revenue grows as the world model improves, not just as business features ship.

### Why Third-Party Data Pipeline (9.2.6A-9.2.6G)
The original one-line "DP export" task was expanded into seven detailed tasks because:

- **Expansion rationale**: A single "export" step hides critical failure modes. Splitting into 9.2.6A (k-anonymity enforcement), 9.2.6B (per-product epsilon calibration), 9.2.6C (buyer ethics review), 9.2.6D (revenue attribution), 9.2.6E-G (pipeline stages) ensures each compliance checkpoint is explicit and auditable.

- **k-anonymity floor of 50 users per cell**: Sparse localities (small towns, niche interests) can enable re-identification when cells contain few users. A floor of 50 prevents adversaries from inferring individuals from small cells. Below 50, the cell is suppressed or merged.

- **Per-product epsilon calibration**: Different product types (event analytics vs. expert matching vs. aggregate trend reports) have different sensitivity and utility tradeoffs. A one-size-fits-all epsilon either over-spends privacy budget (wasting utility) or under-protects (risking re-identification). Per-product calibration allocates privacy budget where it matters most.

- **Buyer ethics review**: Reject use cases that enable surveillance, re-identification, or individual targeting. AVRAI sells aggregate insights to open doors, not to enable tracking. Mandatory review gates bad actors before contract execution.

- **Revenue attribution tracking**: Knowing which data products drive revenue informs AVRAI's product roadmap. High-value products get prioritized; low-value ones get deprecated. This closes the loop between compliance (Phase 2) and business (Phase 9).

- **Connections**: Phase 2.2.3 (epsilon accounting) supplies the privacy budget; Phase 2.1.3 (consent verification) ensures export is only over consented data. The pipeline depends on both.

---

## Common Pitfalls

1. **Blocking business features on the world model**: Phase 9 runs in parallel specifically to avoid this. Ship business features with existing formulas; upgrade to energy functions when available.
2. **Forgetting compliance dependency**: Phase 2 provides refund policy, tax compliance, and fraud prevention. Ship business features without these and you have legal exposure.

---

**Last Updated:** February 10, 2026 (v12 gap fill)
