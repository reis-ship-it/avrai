# 3-Prong Shadow Gate Telemetry Weekly Export

**Source input:** `configs/runtime/conviction_gate_canary_dry_run_fixture.json`  
**Export target:** `docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.md`  
**Summary JSON:** `docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.json`  
**Total decisions:** 6  
**Shadow bypass decisions:** 1  
**Shadow bypass rate:** 16.67%  
**Enforce decisions blocked:** 2/3 (66.67%)  
**High-impact enforce blocked:** 2/3 (66.67%)  
**Window:** 2026-02-27T10:00:00.000Z -> 2026-02-27T10:05:00.000Z  

## Mode Volume

| Mode | Decisions |
|------|-----------|
| shadow | 3 |
| enforce | 3 |

## Controller Volume

| Controller | Decisions |
|------------|-----------|
| CheckoutController | 2 |
| PaymentProcessingController | 2 |
| AIRecommendationController | 1 |
| ListCreationController | 1 |

## Top Reason Codes

| Reason Code | Count |
|-------------|-------|
| high_impact_requires_canonical_conviction | 2 |
| policy_checks_failed | 1 |

## Recent Decisions (Last 20)

| Timestamp | Mode | Controller | Subject | Request | Claim State | Bypass | Allowed | Reasons |
|-----------|------|------------|---------|---------|-------------|--------|---------|---------|
| 2026-02-27T10:05:00Z | shadow | ListCreationController | user-control-3 | dryrun-req-006 | canonical | false | true | - |
| 2026-02-27T10:04:00Z | enforce | PaymentProcessingController | user-canary-2 | dryrun-req-005 | canonical | false | true | - |
| 2026-02-27T10:03:00Z | enforce | PaymentProcessingController | user-canary-1 | dryrun-req-004 | canonical | false | false | policy_checks_failed |
| 2026-02-27T10:02:00Z | enforce | CheckoutController | user-canary-1 | dryrun-req-003 | observed | false | false | high_impact_requires_canonical_conviction |
| 2026-02-27T10:01:00Z | shadow | CheckoutController | user-control-2 | dryrun-req-002 | observed | true | true | high_impact_requires_canonical_conviction |
| 2026-02-27T10:00:00Z | shadow | AIRecommendationController | user-control-1 | dryrun-req-001 | canonical | false | true | - |
