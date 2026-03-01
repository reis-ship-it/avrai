# Ideal Codebase Architecture (3-Prongs + Endpoints + Security)

```mermaid
flowchart TB
  %% ---------- SURFACES ----------
  subgraph S["Product Surfaces"]
    UBE["AVRAI App\n(User / Business / Event)"]
    ADM["AVRAI Admin App"]
    TP["3rd-Party App"]
    RES["Research App"]
    VIZ["User/Admin/Research Visualizers"]
  end

  %% ---------- API ----------
  subgraph E["Canonical Runtime Endpoints"]
    ING["POST /runtime/{id}/ingest"]
    PLN["POST /runtime/{id}/plan"]
    COM["POST /runtime/{id}/commit"]
    OBS["POST /runtime/{id}/observe"]
    RCV["POST /runtime/{id}/recover"]
    LIN["GET /runtime/{id}/lineage/{decision_id}"]
    OVR["POST /runtime/{id}/override"]
  end

  %% ---------- PRONG 2 ----------
  subgraph P2["Prong 2: Runtime Execution (runtime/avrai_runtime_os)"]
    T["TriggerService"]
    SI["SignalIngestor"]
    AG["AdapterGateway"]
    AO["ActionOrchestrator"]
    EX["ExecutionEngine"]
    IR["IncidentRouter"]
    MW["MemoryWriter"]
  end

  %% ---------- PRONG 1 ----------
  subgraph P1["Prong 1: Model Truth (engine/reality_engine)"]
    SE["StateEncoder"]
    QU["QuantumUncertaintyHead"]
    KT["KnotTopologyAnalyzer"]
    PC["PlaneCoherenceProjector"]
    EF["EnergyFunction"]
    TPD["TransitionPredictor"]
    MPC["MPCPlanner"]
  end

  %% ---------- PRONG 3 ----------
  subgraph P3["Prong 3: Trust Governance (runtime policy lane)"]
    PK["PolicyKernel"]
    PMP["PrivacyModePolicy"]
    CG["ConsentGate"]
    CV["ConvictionGate"]
    CR["CanaryRollbackController"]
    LA["LineageAudit"]
    HO["HumanOverride"]
    NEG["NoEgressGate\n(local_sovereign hard fail)"]
  end

  %% ---------- SECURITY ----------
  subgraph SEC["Security + Compliance Plane (cross-cutting)"]
    ID["Identity/AgentID + Key Mgmt"]
    ENC["E2E Encryption / Payload Validation"]
    DP["Differential Privacy + Minimization"]
    COMP["Audit, Legal, Retention, Compliance"]
  end

  %% ---------- SHARED ----------
  subgraph SH["Shared Contracts (shared/avrai_core)"]
    SC["Schemas / Envelopes / Primitives / Clock"]
  end

  %% ---------- RUNTIME TYPES ----------
  subgraph RT["Runtime Types"]
    EV["event_ops_runtime"]
    BU["business_ops_runtime"]
    EXR["expert_services_runtime"]
    CU["custom_runtime"]
  end

  %% ---------- FLOW ----------
  UBE --> ING
  ADM --> ING
  TP --> ING
  RES --> ING
  ADM --> OVR

  ING --> T --> SI --> AG --> AO
  AO --> PLN
  PLN --> SE --> QU --> KT --> PC --> EF --> TPD --> MPC
  MPC --> PK
  PK --> PMP --> CG --> CV --> CR --> COM
  PMP --> NEG
  OVR --> HO --> PK

  COM --> EX --> OBS --> MW
  EX --> RCV --> IR
  COM --> LIN
  LIN --> LA --> VIZ
  OBS --> VIZ

  ING -. uses .-> SC
  PLN -. uses .-> SC
  COM -. uses .-> SC
  OBS -. uses .-> SC
  LIN -. uses .-> SC
  RCV -. uses .-> SC
  OVR -. uses .-> SC

  EV --> ING
  BU --> ING
  EXR --> ING
  CU --> ING

  ID --- ING
  ID --- COM
  ENC --- ING
  ENC --- COM
  DP --- OBS
  COMP --- LIN
```

## Dependency Rule (Non-Negotiable)

1. `apps/* -> runtime/* -> engine/* -> shared/*`
2. No direct `apps/* -> engine/*` imports.
3. No `engine/* -> runtime/*` or `engine/* -> apps/*` imports.
