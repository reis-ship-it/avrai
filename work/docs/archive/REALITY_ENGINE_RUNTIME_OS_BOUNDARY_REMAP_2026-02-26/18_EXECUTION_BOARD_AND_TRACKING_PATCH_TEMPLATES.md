# 18 - Execution Board and Tracking Patch Templates

## 1) CSV Milestone Row Template (Separation Lane)

Use this template in `docs/EXECUTION_BOARD.csv`:

```csv
milestone,Mx-P10-x,10,Reality Engine Runtime Boundary Guard,0,Ready,ARCH,GOV,"REL;SEC;QA",PMO,none,"PRD-021;PRD-022;PRD-033","10.10.1;10.9.1",lib/core/ai,baseline,none,4,5,20,Critical,Week X-Y,Boundary check enforced and green,
```

## 2) Suggested Milestone Set

1. Boundary guard implementation
2. Contract registry and versioning
3. Engine extraction module pass
4. Runtime capability profile integration
5. Cross-OS adapter conformance
6. Headless engine smoke + degraded mode tests
7. Runtime/app artifact split and rollback drill

## 3) STATUS_WEEKLY Template Addendum

Add section:
- `Boundary Conversion Progress`

Fields:
1. milestones advanced
2. forbidden import count trend
3. contract conformance status
4. capability matrix status
5. blockers and ownership

## 4) MASTER_PLAN_TRACKER Entry Template

| Plan Name | Date | Status | Priority | Timeline | File Path |
|---|---|---|---|---|---|
| Runtime/Engine Separation Conversion Program | YYYY-MM-DD | Active | CRITICAL | 90-day staged | `...` |

## 5) PR Template Additions

Required fields:
1. layer impact (`engine/runtime/app/cross`)
2. contract change (`none/minor/major`)
3. compatibility impact (`N-only`, `N/N-1`)
4. degraded mode impact (`yes/no`)
5. rollback impact (`engine/runtime/app/both`)

