# External Research Addendum: arXiv 2501.02305

**Date:** February 16, 2026  
**Status:** Active research reference  
**Source:** https://arxiv.org/abs/2501.02305  
**PDF:** https://arxiv.org/pdf/2501.02305  
**Paper:** "Optimal Bounds for Open Addressing Without Reordering"

---

## Summary (Why It Matters to AVRAI)

This paper advances open-addressing hash-table bounds under a "no reordering" constraint. It does not change cryptographic hash choices; it improves lookup/insert probe complexity in hash-table internals.

For AVRAI, this is relevant to deterministic, append-only, or high-churn indexing lanes where low-probe behavior and predictable latency matter.

---

## AVRAI Mapping

| Paper Concept | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| Better probe bounds in open addressing | Faster deterministic key lookup in local journals and failure-signature indexes | `docs/MASTER_PLAN.md` Phase 1.1E, 7.7.10, 7.7.11 |
| Performance without reordering | Preserve append-only/history semantics while improving lookup efficiency | `docs/MASTER_PLAN.md` Phase 1.1E |
| Tight lower/upper bounds guidance | Benchmark-gated decision to keep built-ins vs custom internals | `docs/MASTER_PLAN.md` Phase 7.9.17 |

---

## Recommended AVRAI Use (Profile-Gated)

1. Keep current cryptographic primitives unchanged (SHA-256, Ed25519, PQXDH).  
2. Profile hot paths first (dedupe caches, failure-signature indexes, deterministic journal lookup).  
3. Only if profiling proves hash-table probe overhead is material:
   - implement a narrow custom open-addressing table in one subsystem,
   - benchmark against Dart `Map/Set`,
   - ship behind feature flag + rollback.

---

## Not Recommended

- Full replacement of all map/set usage in AVRAI.
- Using this paper to justify cryptography changes (it is not a cryptography paper).

---

## Success Criteria

- Lower p95/p99 lookup latency in targeted hot paths.
- Reduced CPU use in high-churn lookup loops.
- No regression in correctness, determinism, or rollback reliability.
