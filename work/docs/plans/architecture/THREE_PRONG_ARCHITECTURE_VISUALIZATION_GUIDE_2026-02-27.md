# 3-Prong Architecture Visualization Guide (URK + Endpoints + App Surfaces)

**Date:** February 27, 2026  
**Status:** Canonical visualization addendum  
**Purpose:** Provide a clear visual map for external and internal understanding of AVRAI's 3-prong architecture, kernel model, runtime endpoints, and app surface interactions.

**Primary authorities:**
- `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
- `docs/plans/architecture/URK_INTERFACE_CONTRACTS_2026-02-27.md`
- `configs/runtime/kernel_registry.json`

---

## 1. System Map (Top -> Bottom, End-to-End)

```mermaid
flowchart TB
  subgraph Surfaces["App Surfaces and Visualizers"]
    UBE["AVRAI App\n(User/Business/Event modes)"]
    ADM["AVRAI Admin App"]
    TP["3rd-Party App"]
    RES["Research App"]
    VIZ["Visualization Layer\n(User + Admin + Research views)"]
  end

  subgraph API["URK Runtime Endpoint Layer"]
    ING["POST /ingest"]
    PLN["POST /plan"]
    COM["POST /commit"]
    OBS["POST /observe"]
    RCV["POST /recover"]
    LIN["GET /lineage/{decision_id}"]
    OVR["POST /override"]
  end

  subgraph P1["Prong 1: Model Truth"]
    P1A["StateEncoder"]
    P1B["QuantumUncertaintyHead"]
    P1C["KnotTopologyAnalyzer"]
    P1D["PlaneCoherenceProjector"]
    P1E["EnergyFunction"]
    P1F["TransitionPredictor"]
    P1G["MPCPlanner"]
  end

  subgraph P2["Prong 2: Runtime Execution"]
    P2A["TriggerService"]
    P2B["SignalIngestor"]
    P2C["AdapterGateway"]
    P2D["ActionOrchestrator"]
    P2E["ExecutionEngine"]
    P2F["IncidentRouter"]
    P2G["MemoryWriter"]
  end

  subgraph P3["Prong 3: Trust Governance"]
    P3A["PolicyKernel"]
    P3B["PrivacyModePolicy"]
    P3C["ConsentGate"]
    P3D["ConvictionGate"]
    P3E["CanaryRollbackController"]
    P3F["LineageAudit"]
    P3G["HumanOverride"]
    P3H["NoEgressGate"]
  end

  UBE --> ING
  ADM --> ING
  TP --> ING
  RES --> ING

  ING --> PLN --> COM --> OBS
  COM --> RCV
  COM --> LIN
  ADM --> OVR

  PLN --> P1
  ING --> P2
  COM --> P2
  OBS --> P2

  PLN --> P3
  COM --> P3
  OBS --> P3
  OVR --> P3
  LIN --> VIZ
  OBS --> VIZ
```

---

## 2. External Visualization (What Partners and Product Stakeholders See)

```mermaid
flowchart LR
  UBE["AVRAI App\n(User/Business/Event)"]
  ADM["AVRAI Admin App"]
  TP["3rd-Party App"]
  RES["Research App"]

  EP["URK Public Runtime API\n/ingest /plan /commit /observe /recover /lineage /override"]

  DEC["Action and Recommendation Outputs"]
  LINE["Explainability and Lineage Views"]
  REP["Research and Performance Dashboards"]

  UBE --> EP
  TP --> EP
  RES --> EP
  ADM --> EP

  EP --> DEC
  EP --> LINE
  EP --> REP
```

External rule: app surfaces call endpoint contracts; they do not directly call prong internals.

---

## 3. Internal Visualization (How AVRAI Operates Under the Hood)

```mermaid
flowchart TB
  TRG["Trigger Types\nin_app_event | os_background | external_webhook | risk_anomaly | governance_event"]
  MOD["Privacy Mode Resolver\nlocal_sovereign | private_mesh | federated_cloud"]

  TRG --> ING["/ingest"]
  MOD --> ING

  ING --> P2["Prong 2 Runtime Execution"]
  P2 --> PLN["/plan"]
  PLN --> P1["Prong 1 Model Truth"]
  P1 --> CAND["Candidate Actions + Forecasts"]
  CAND --> GOV["Prong 3 Trust Governance"]
  GOV --> COM["/commit"]
  COM --> OBS["/observe"]
  OBS --> MEM["Learning Memory Tuple + Outcome"]
  MEM --> LIN["/lineage"]
  COM --> RCV["/recover"]
  GOV --> OVR["/override"]
```

Internal rule: all production-affecting actions are gated by Prong 3 before commit.

---

## 4. Prong 1 Detail (Model Truth)

```mermaid
flowchart LR
  IN["Normalized Domain Graph + World Snapshot"]
  E1["StateEncoder"]
  E2["QuantumUncertaintyHead"]
  E3["KnotTopologyAnalyzer"]
  E4["PlaneCoherenceProjector"]
  E5["EnergyFunction"]
  E6["TransitionPredictor"]
  E7["MPCPlanner"]
  OUT["Ranked Plan Candidates\n+ uncertainty + expected outcomes"]

  IN --> E1 --> E2 --> E3 --> E4 --> E5 --> E6 --> E7 --> OUT
```

---

## 5. Prong 2 Detail (Runtime Execution)

```mermaid
flowchart LR
  T["TriggerService"]
  S["SignalIngestor"]
  A["AdapterGateway"]
  O["ActionOrchestrator"]
  X["ExecutionEngine"]
  I["IncidentRouter"]
  M["MemoryWriter"]

  T --> S --> A --> O --> X --> M
  X --> I
```

---

## 6. Prong 3 Detail (Trust Governance)

```mermaid
flowchart LR
  P["PolicyKernel"]
  PM["PrivacyModePolicy"]
  C["ConsentGate"]
  V["ConvictionGate"]
  CR["CanaryRollbackController"]
  L["LineageAudit"]
  H["HumanOverride"]
  N["NoEgressGate\n(local_sovereign hard stop)"]
  D["Decision: allow | block | canary | rollback | escalate"]

  P --> PM --> C --> V --> CR --> L --> D
  PM --> N --> D
  H --> D
```

---

## 7. Endpoint Interaction Sequence (Canonical Request Lifecycle)

```mermaid
sequenceDiagram
  participant APP as App Surface
  participant API as URK Endpoint Layer
  participant P2 as Prong 2 Runtime
  participant P1 as Prong 1 Model
  participant P3 as Prong 3 Governance
  participant VIZ as Visualizers

  APP->>API: POST /runtime/{id}/ingest (RuntimeRequestEnvelope)
  API->>P2: normalizeToDomainGraph()
  APP->>API: POST /runtime/{id}/plan
  API->>P1: world state + scoring + MPC
  P1-->>API: ranked candidates + uncertainty
  API->>P3: policy + consent + conviction + privacy checks
  P3-->>API: allow/block/canary
  APP->>API: POST /runtime/{id}/commit
  API->>P2: execute action
  APP->>API: POST /runtime/{id}/observe
  API->>P2: write memory tuple + outcomes
  APP->>API: GET /runtime/{id}/lineage/{decision_id}
  API->>P3: fetch provenance + audit chain
  API-->>VIZ: explainability, lineage, outcome dashboards
  APP->>API: POST /runtime/{id}/recover (if incident)
  APP->>API: POST /runtime/{id}/override (admin/governance)
```

---

## 8. Runtime and Kernel Coverage by App Surface

```mermaid
flowchart TB
  subgraph Apps["App Surfaces"]
    UBE["AVRAI App\n(User/Business/Event)"]
    ADM["AVRAI Admin App"]
    TP["3rd-Party App"]
    RES["Research App"]
  end

  subgraph RuntimeTypes["Runtime Types"]
    EV["event_ops_runtime"]
    BUS["business_ops_runtime"]
    EXP["expert_services_runtime"]
    CUS["custom_runtime (future)"]
  end

  subgraph Kernels["Shared Kernel Layer (examples)"]
    K1["urk_stage_e_cross_runtime_conformance"]
    K2["urk_kernel_promotion_lifecycle"]
    K3["urk_learning_update_governance"]
    K4["urk_reality_world_state_coherence"]
    K5["urk_reality_temporal_truth"]
  end

  UBE --> EV
  UBE --> BUS
  UBE --> EXP
  ADM --> EV
  ADM --> BUS
  ADM --> EXP
  TP --> BUS
  TP --> EXP
  RES --> EV
  RES --> EXP
  RES --> CUS

  EV --> K1
  BUS --> K1
  EXP --> K1
  CUS --> K1

  K1 --> K2
  K2 --> K3
  K3 --> K4
  K4 --> K5
```

---

## 9. How the 3 Prongs Work Together

```mermaid
flowchart LR
  P1["Prong 1\nModel Truth"]
  P2["Prong 2\nRuntime Execution"]
  P3["Prong 3\nTrust Governance"]

  P2 -->|"build state + triggers"| P1
  P1 -->|"candidate plans + forecasts"| P3
  P3 -->|"gated decision"| P2
  P2 -->|"observed outcomes"| P1
  P2 -->|"lineage records"| P3
```

Operational invariant:
1. Prong 1 proposes,
2. Prong 3 permits or denies,
3. Prong 2 executes and records outcomes,
4. outcome feedback re-enters Prong 1 and Prong 3.

---

## 10. Architecture Visualization Working Guideline (New)

Use this when adding or updating architecture diagrams:

1. Maintain two views for every major subsystem:
   - External view (surfaces + endpoints),
   - Internal view (prongs + kernels + gates).
2. Always represent the seven canonical endpoints: `ingest`, `plan`, `commit`, `observe`, `recover`, `lineage`, `override`.
3. Any action path that can affect users/businesses/events must visually pass through Prong 3 gating.
4. Show privacy mode resolution explicitly in flow diagrams (`local_sovereign`, `private_mesh`, `federated_cloud`).
5. Keep prong boundaries strict:
   - Prong 1 = modeling/planning truth,
   - Prong 2 = orchestration/execution,
   - Prong 3 = policy/trust/governance.
6. Include lineage/explainability outputs in every end-to-end system map.
7. For kernel visuals, distinguish:
   - runtime-scoped kernels (`event/business/expert/custom`),
   - shared governance kernels (`promotion`, `conformance`, `learning governance`).
8. Update references in `ARCHITECTURE_INDEX.md` whenever a new canonical diagram guide is added.

---

## 11. Suggested Diagram Set for Ongoing Operations

1. `System map` (Section 1) for leadership and cross-functional alignment.
2. `External visualization` (Section 2) for product, partners, and API consumers.
3. `Internal visualization` (Section 3) for platform/runtime/ML teams.
4. `Per-prong details` (Sections 4-6) for implementation handoffs.
5. `Endpoint sequence` (Section 7) for integration and QA contract tests.
6. `Runtime-kernel coverage` (Section 8) for governance and rollout planning.
