# Architecture Documentation Index

**Last Updated:** February 15, 2026  
**Status:** Active Reference  
**Purpose:** Central index for all architecture documentation, with clear navigation and relationships

---

## 🎯 **Quick Navigation**

**Start here based on what you need:**

- **Master Plan multi-app architecture blueprint** → [`MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`](#master-plan-multi-app-architecture-blueprint)
- **Master Plan architecture execution backlog** → [`MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`](#master-plan-architecture-execution-backlog)
- **Master Plan architecture implementation checklist** → [`MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`](#master-plan-architecture-implementation-checklist)
- **Master Plan architecture readiness QA** → [`MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md`](#master-plan-architecture-readiness-qa)
- **Identity unlinkability + access governance contract** → [`IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`](#identity-unlinkability--access-governance-contract)
- **Reality coherence test matrix** → [`REALITY_COHERENCE_TEST_MATRIX.md`](#reality-coherence-test-matrix)
- **External research execution backlog** → [`EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`](#external-research-execution-backlog)
- **Patent risk claim checklist** → [`PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`](#patent-risk-claim-checklist)
- **Phase 10 test suite path normalization map** → [`TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md`](#phase-10-test-suite-path-normalization-map)
- **Phase 10 canonical rename manifest** → [`FILE_FOLDER_RENAME_MANIFEST_PHASE10.md`](#phase-10-canonical-rename-manifest)
- **Master Plan phase execution orchestration** → [`MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md`](#master-plan-phase-execution-orchestration)
- **Feature-by-feature strategy** → [`ONLINE_OFFLINE_STRATEGY.md`](#online-offline-strategy)
- **AI/LLM offline architecture** → [`OFFLINE_CLOUD_AI_ARCHITECTURE.md`](#offline-cloud-ai-architecture)
- **AI2AI network architecture** → [`architecture_ai_federated_p2p.md`](#ai2ai-federated-architecture)
- **Offline AI2AI connections** → [`../offline_ai2ai/`](#offline-ai2ai-documentation)

---

## 📚 **Architecture Documents**

### **Master Plan Multi-App Architecture Blueprint** ⭐ **PRIMARY FOR NEW EXECUTION**

**File:** [`MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`](./MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md)

**What it covers:**
- ✅ Single architecture model for multiple apps sharing one intelligence core
- ✅ Contract-first boundaries for apps, APIs, SDKs, researchers, and admins
- ✅ Learning plane and self-healing plane with immutable safety/compliance boundaries
- ✅ Human + AI editability model (what can and cannot be autonomously changed)
- ✅ Reuse-first migration strategy from existing services/packages (no full rewrite)
- ✅ Cross-stakeholder considerations: users, businesses, event planners, companies, third-party viewers, API callers, admins, researchers

**Use this when:**
- Planning implementation sequencing for `docs/MASTER_PLAN.md`
- Designing shared services used by multiple applications
- Defining how self-healing interacts with safety, compliance, and UX
- Building migration plans that preserve existing system investments

---

### **Master Plan Architecture Execution Backlog** ⭐ **PHASE-BY-PHASE EXECUTION SOURCE**

**File:** [`MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`](./MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md)

**What it covers:**
- ✅ Epics/stories per Master Plan phase (1-15)
- ✅ Owner boundaries and handoff contracts
- ✅ Cross-phase dependency model
- ✅ Direct mapping to Master Plan + Tracker phase registry
- ✅ Prep-only architecture sequencing without scaffolding

**Use this when:**
- Converting architecture into executable work items
- Assigning ownership and preventing boundary drift
- Running phase-based architecture planning reviews

---

### **Master Plan Architecture Implementation Checklist** ⭐ **EXECUTION GATEKEEPER**

**File:** [`MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`](./MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md)

**What it covers:**
- ✅ Global pre-execution controls
- ✅ Phase entry/exit gates for phases 1-15
- ✅ Story-level completion template
- ✅ Tracker sync and cursor-rule compliance checks

**Use this when:**
- Starting any architecture story from the backlog
- Determining if a phase can advance
- Auditing planning/execution discipline

---

### **Master Plan Architecture Readiness QA**

**File:** [`MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md`](./MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md)

**What it covers:**
- ✅ Prep-only audit of architecture readiness across Master Plan, design system, and testing suite grouping
- ✅ Pass/fail matrix with severity-ordered findings
- ✅ Concrete prep-only remediation backlog additions (no scaffolding)

**Use this when:**
- Validating whether architecture prep is actually execution-ready
- Reviewing grouped test-suite integrity and design-test coverage readiness
- Prioritizing Phase 10 hardening prep items

---

### **Identity Unlinkability + Access Governance Contract**

**File:** [`IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`](./IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md)

**What it covers:**
- ✅ Canonical `account_id` / `agent_id` / `world_id` namespace boundaries
- ✅ Access matrix robustness controls (fail-closed, non-bypass, drift detection, break-glass limits)
- ✅ Identity migration contract with bounded dual-read/dual-write and strict cutoff
- ✅ Verification/release gates for unlinkability and access-governance enforcement

**Use this when:**
- Implementing or reviewing any identity/data-sharing contract
- Touching disclosure, admin, research, partner, or export access routes
- Planning or executing `user_id` -> namespace migration work

---

### **Reality Coherence Test Matrix**

**File:** [`REALITY_COHERENCE_TEST_MATRIX.md`](./REALITY_COHERENCE_TEST_MATRIX.md)

**What it covers:**
- ✅ Phase-by-phase coherence test coverage for Phases 1-15
- ✅ Canonical scenario IDs for offline/online, BLE/WiFi arbitration, weather degradation, self-healing, federation, and admin observability
- ✅ Mandatory evidence package and no-go release blockers
- ✅ Cross-link contract for backlog/checklist/orchestration/doc validation

**Use this when:**
- Proving connected behavior across learning, worlds, environments, and transport layers
- Reviewing whether self-learning/self-healing is system-wide and policy-safe
- Enforcing release gating for coherence-critical changes

---

### **External Research Execution Backlog**

**File:** [`EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`](./EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md)

**What it covers:**
- ✅ Consolidated phase-mapped `MPA` story pack from research findings
- ✅ Owners, dependencies, and acceptance criteria for immediate documentation execution
- ✅ Direct mapping to self-learning/self-healing/self-questioning/self-improving and quantum-ready gates

**Use this when:**
- You need actionable Master Plan/doc updates now from research findings
- You want to execute risk-reduction work without code scaffolding
- You need a single backlog pack spanning phases 2, 3, 5, 6, 7, 10, and 11

---

### **Patent Risk Claim Checklist**

**File:** [`PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`](./PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md)

**What it covers:**
- ✅ Element-level status mapping (`Present`, `Absent`, `Unknown`) for high-risk patent families
- ✅ Owner-assigned required actions for claim-sensitive architecture elements
- ✅ Monthly review and escalation rules for phase gate evidence

**Use this when:**
- Reviewing matching/geo-context architecture for claim-sensitive overlaps
- Preparing phase-exit evidence for legal/architecture review
- Prioritizing design-around documentation updates

---

### **Phase 10 Test Suite Path Normalization Map**

**File:** [`TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md`](./TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md)

**What it covers:**
- ✅ Canonical old->new grouped suite path map for domainized integration tests
- ✅ Design golden grouping requirement for suite planning
- ✅ Acceptance gate for zero-missing-reference suite readiness

**Use this when:**
- Normalizing `test/suites/*_suite.sh` without architecture drift
- Closing Phase 10 grouped-testing prep blockers
- Auditing grouped suite references before implementation

---

### **Phase 10 Canonical Rename Manifest**

**File:** [`FILE_FOLDER_RENAME_MANIFEST_PHASE10.md`](./FILE_FOLDER_RENAME_MANIFEST_PHASE10.md)

**What it covers:**
- ✅ Canonical target taxonomy for working and testing paths
- ✅ Required manifest schema for `old_path -> new_path` planning rows
- ✅ Wave-based conversion model with owner boundaries and gates
- ✅ Verification and rollback planning requirements for rename safety

**Use this when:**
- Planning file/folder renames to align with Master Plan architecture boundaries
- Building phase-mapped rename backlogs before any path migration work
- Keeping rename planning synchronized with tracker and phase gates

---

### **Master Plan Phase Execution Orchestration**

**File:** [`MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md`](./MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md)

**What it covers:**
- ✅ GitHub + Cursor phase trigger model with dependency-aware ordering
- ✅ Machine-readable execution contract reference (`docs/plans/master_plan_execution.yaml`)
- ✅ Mandatory doc-link validation and fail-fast behavior
- ✅ UI/UX design contract linkage via `docs/design/DESIGN_REF.md`, `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`, and app-scoped `docs/design/apps/*` folders

**Use this when:**
- Enabling phase trigger automation for Master Plan execution
- Validating all required architecture/design docs are linked before phase runs
- Enforcing consistent phase gating and tracker/checklist synchronization

---

### **Repo Hygiene + Architecture Rules (Guardrails)**

**File:** [`REPO_HYGIENE_AND_ARCHITECTURE_RULES.md`](./REPO_HYGIENE_AND_ARCHITECTURE_RULES.md)

**What it covers:**
- ✅ CI guardrails for package boundaries (`packages/*` must not import the app)
- ✅ CI guardrails for tracked generated artifacts (build outputs, Pods, temp/logs)

---

### **0. Expertise Ledger + Capabilities (Strict Append-Only)**

**File:** [`EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md`](./EXPERTISE_LEDGER_AND_CAPABILITIES_V1.md)

**What it covers:**
- ✅ **Strict append-only ledger** (no UPDATE/DELETE; revisions as new rows)
- ✅ **Exact Supabase RLS policy shapes** aligned with user-owned rows (`auth.uid()`)
- ✅ **Minimal Capabilities API** to prevent gating/scoring drift
- ✅ **Migration path** from `UnifiedUser.expertiseMap` gating → ledger-based gating without breaking anything

**Use this when:**
- You need a single source of truth for expertise, events, communities/clubs, and partnerships
- You want explainable “doors” (capabilities) derived from recorded facts
- You are removing drift between stored expertise strings and computed expertise scores

---

### **0.5 Ledgers (v0) — Shared Append-Only Journal (Many Domains)**

**Index:** [`../ledgers/LEDGERS_V0_INDEX.md`](../ledgers/LEDGERS_V0_INDEX.md)

**What it covers:**
- ✅ A single **append-only journal** schema used as *many logical ledgers* via `domain`
- ✅ A v0 **event catalog** covering expertise/events/communities/clubs/partnerships + payments + moderation + more
- ✅ “Feels like many ledgers” in Supabase via **domain-specific views**

---

### **1. Online/Offline Strategy** ⭐ **MOST COMPREHENSIVE**

**File:** [`ONLINE_OFFLINE_STRATEGY.md`](./ONLINE_OFFLINE_STRATEGY.md)

**What it covers:**
- ✅ **Feature-by-feature analysis** of all 221 features
- ✅ **Decision framework** (speed, accuracy, UX, pricing)
- ✅ **Recommendations** for each feature (offline-first vs online-first)
- ✅ **Real-time requirements** by user type (users, experts, admins)
- ✅ **Implementation strategy** for both approaches
- ✅ **Cost optimization** (83% offline-first = $0 cost)
- ✅ **Speed optimization** (83% instant <50ms)
- ✅ **User type breakdowns** (users: ~95% offline, admins: ~40% online)

**Use this when:**
- Deciding if a feature should be offline-first or online-first
- Understanding why 83% of features are offline-first
- Planning implementation strategy for new features
- Understanding real-time vs cached data requirements
- Optimizing for speed, cost, and user experience

**Key Insights:**
- **83% Offline-First** - Fast, free, reliable
- **17% Online-First** - Security, real-time, AI/LLM
- **Users/Experts:** ~95% offline-first
- **Admins:** ~40% online-first (operational monitoring)

---

### **2. Offline Cloud AI Architecture**

**File:** [`OFFLINE_CLOUD_AI_ARCHITECTURE.md`](./OFFLINE_CLOUD_AI_ARCHITECTURE.md)

**What it covers:**
- ✅ **Hybrid offline/online architecture** for cloud-based AI
- ✅ **LLM service** with connectivity checks
- ✅ **AI command processor** with rule-based fallback
- ✅ **Offline-first data repositories**
- ✅ **What works offline** (CRUD, local search, rule-based AI)
- ✅ **What requires internet** (cloud AI, AI2AI network, sync)
- ✅ **User experience** in online/offline modes
- ✅ **Privacy & security** considerations

**Use this when:**
- Understanding how LLM/AI features work offline
- Implementing AI command processing
- Adding offline fallback for AI features
- Understanding connectivity checks

**Relationship to Strategy:**
- This is the **implementation detail** for the AI/LLM features marked as "Online-First" in `ONLINE_OFFLINE_STRATEGY.md`
- Covers the 4 LLM features (chat, recommendations, search suggestions, universal search)
- Explains how rule-based fallback works offline

---

### **3. AI2AI Federated Architecture**

**File:** [`architecture_ai_federated_p2p.md`](./architecture_ai_federated_p2p.md)

**What it covers:**
- ✅ **AI2AI network architecture** (ai2ai, not p2p)
- ✅ **Federated learning** system
- ✅ **Personality-driven connections**
- ✅ **Privacy-preserving communication**
- ✅ **Network topology** and protocols

**Use this when:**
- Understanding AI2AI network structure
- Implementing personality-based connections
- Understanding federated learning
- Understanding privacy-preserving communication

**Relationship to Strategy:**
- Covers the **AI2AI Network** features (20 features, 15 offline-first, 5 online-first)
- Explains how real-time AI2AI connections work
- Details the offline-first personality learning system

---

### **4. Offline AI2AI Documentation**

**Location:** [`../offline_ai2ai/`](../offline_ai2ai/)

**Files:**
- [`OFFLINE_AI2AI_QUICK_REFERENCE.md`](../offline_ai2ai/OFFLINE_AI2AI_QUICK_REFERENCE.md) - Quick lookup for developers
- [`OFFLINE_AI2AI_TECHNICAL_SPEC.md`](../offline_ai2ai/OFFLINE_AI2AI_TECHNICAL_SPEC.md) - Technical specification
- [`OFFLINE_AI2AI_IMPLEMENTATION_PLAN.md`](../offline_ai2ai/OFFLINE_AI2AI_IMPLEMENTATION_PLAN.md) - Implementation plan
- [`OFFLINE_AI2AI_CHECKLIST.md`](../offline_ai2ai/OFFLINE_AI2AI_CHECKLIST.md) - Implementation checklist

**What it covers:**
- ✅ **Offline AI2AI connections** (Bluetooth, NSD)
- ✅ **Device-to-device communication** without internet
- ✅ **Local personality sharing** and learning
- ✅ **Connection flow** and protocols

**Use this when:**
- Implementing offline device discovery
- Understanding Bluetooth/NSD connections
- Implementing local AI2AI learning
- Understanding offline personality evolution

**Relationship to Strategy:**
- Covers **offline AI2AI connections** (part of AI2AI Network features)
- Implements the offline-first approach for AI2AI discovery
- Details how personality learning works offline

---

## 🔗 **Document Relationships**

### **Strategy → Implementation**

```
ONLINE_OFFLINE_STRATEGY.md (WHAT & WHY)
    ↓
    ├─→ OFFLINE_CLOUD_AI_ARCHITECTURE.md (AI/LLM HOW)
    ├─→ architecture_ai_federated_p2p.md (AI2AI HOW)
    └─→ offline_ai2ai/ (Offline AI2AI HOW)
```

**Flow:**
1. **Strategy** (`ONLINE_OFFLINE_STRATEGY.md`) tells you **WHAT** features should be offline/online and **WHY**
2. **Implementation** docs tell you **HOW** to implement each approach

### **Feature Categories**

| Category | Strategy Doc | Implementation Docs |
|----------|-------------|---------------------|
| **AI/LLM Features** | `ONLINE_OFFLINE_STRATEGY.md` | `OFFLINE_CLOUD_AI_ARCHITECTURE.md` |
| **AI2AI Network** | `ONLINE_OFFLINE_STRATEGY.md` | `architecture_ai_federated_p2p.md`, `offline_ai2ai/` |
| **User Features** | `ONLINE_OFFLINE_STRATEGY.md` | Repository pattern (offline-first) |
| **Admin Features** | `ONLINE_OFFLINE_STRATEGY.md` | Admin services (real-time streams) |

---

## 📖 **How to Use This Documentation**

### **For Planning New Features:**

1. **Check Strategy** → `ONLINE_OFFLINE_STRATEGY.md`
   - Find your feature category
   - See recommendation (offline-first vs online-first)
   - Understand reasoning (speed, accuracy, UX, pricing)

2. **Read Implementation** → Relevant implementation doc
   - For AI/LLM → `OFFLINE_CLOUD_AI_ARCHITECTURE.md`
   - For AI2AI → `architecture_ai_federated_p2p.md` or `offline_ai2ai/`
   - For data features → Repository pattern (offline-first)

3. **Follow Patterns** → See "Implementation Strategy" section in Strategy doc

### **For Understanding Real-Time:**

1. **Strategy Doc** → "What is Real-Time?" section
   - Definition: WebSocket/SSE streams, auto-updates, 200-500ms latency
   - Real-time vs cached comparison

2. **Strategy Doc** → "Real-Time Features by User Type"
   - Users/Experts: 2 features need real-time
   - Admins: 6 features need real-time
   - Why admins need more real-time

3. **Implementation** → See admin services for real-time streams

### **For Optimizing Performance:**

1. **Strategy Doc** → "Speed Optimization" section
   - Current performance metrics
   - Optimization strategies
   - Expected results

2. **Strategy Doc** → "Cost Optimization" section
   - LLM cost reduction (70-90%)
   - Offline-first cost savings (100% for 83% of features)

---

## 🎯 **Key Concepts**

### **Offline-First (83% of features)**
- **Definition:** Start offline, enhance online
- **Speed:** <50ms (instant)
- **Cost:** $0 (free)
- **Reliability:** Works without internet
- **Examples:** CRUD operations, search cache, local analytics

### **Online-First (17% of features)**
- **Definition:** Start online, fallback offline
- **Speed:** 200-500ms (with streaming)
- **Cost:** $0.001-0.01 per call (LLM) or free (Supabase)
- **Needed for:** Security, real-time, AI/LLM, validation
- **Examples:** Payment processing, LLM chat, admin monitoring

### **Real-Time (subset of online-first)**
- **Definition:** WebSocket/SSE streams, auto-updates every 3-30 seconds
- **Latency:** 200-500ms typical
- **Used by:** AI2AI discovery, admin monitoring, live communication
- **Not needed for:** Most user-facing features (cached data is sufficient)

---

## 📊 **Summary Statistics**

**From `ONLINE_OFFLINE_STRATEGY.md`:**

| Metric | Value |
|--------|-------|
| **Total Features** | 221 |
| **Offline-First** | 183 (83%) |
| **Online-First** | 38 (17%) |
| **Users/Experts: Offline** | ~95% |
| **Admins: Online** | ~40% (monitoring) |
| **Speed: Offline** | <50ms (instant) |
| **Speed: Online** | 200-500ms (streaming) |
| **Cost: Offline** | $0 |
| **Cost: Online (LLM)** | $0.001-0.01 per call |

---

## 🔄 **Document Status**

| Document | Status | Last Updated | Completeness |
|----------|--------|--------------|--------------|
| `MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md` | ✅ Active | Feb 15, 2026 | 100% - Architecture blueprint |
| `MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md` | ✅ Active | Feb 15, 2026 | 100% - Phase/owner backlog |
| `MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md` | ✅ Active | Feb 15, 2026 | 100% - Phase gates/checklist |
| `MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md` | ✅ Active | Feb 13, 2026 | 100% - Prep readiness audit |
| `IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md` | ✅ Active | Feb 15, 2026 | 100% - Namespace/access/migration contract |
| `REALITY_COHERENCE_TEST_MATRIX.md` | ✅ Active | Feb 15, 2026 | 100% - Phase-by-phase coherence gate matrix |
| `TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md` | ✅ Active | Feb 13, 2026 | 100% - Path normalization map |
| `FILE_FOLDER_RENAME_MANIFEST_PHASE10.md` | ✅ Active | Feb 13, 2026 | 100% - Rename taxonomy/manifest model |
| `MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md` | ✅ Active | Feb 15, 2026 | 100% - Phase trigger orchestration model |
| `ONLINE_OFFLINE_STRATEGY.md` | ✅ Active | Nov 25, 2025 | 100% - Comprehensive |
| `OFFLINE_CLOUD_AI_ARCHITECTURE.md` | ✅ Active | Jan 2025 | 100% - Complete |
| `architecture_ai_federated_p2p.md` | ✅ Active | Dec 2024 | 100% - Complete |
| `offline_ai2ai/` | ✅ Active | Nov 2025 | 100% - Complete |

---

## 🚀 **Quick Links**

**Strategy & Planning:**
- [`MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`](./MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md) - Multi-app master architecture model
- [`MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`](./MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md) - Phase-by-phase epics/stories + owner boundaries
- [`MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`](./MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md) - Execution gates and readiness checklist
- [`MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md`](./MASTER_PLAN_ARCHITECTURE_READINESS_QA_2026-02-13.md) - Architecture/design/testing readiness audit
- [`IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`](./IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md) - Canonical identity unlinkability + access governance + migration cutoff contract
- [`REALITY_COHERENCE_TEST_MATRIX.md`](./REALITY_COHERENCE_TEST_MATRIX.md) - Canonical phase-by-phase coherence test matrix and release blockers
- [`TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md`](./TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md) - Phase 10 grouped-suite path normalization map
- [`FILE_FOLDER_RENAME_MANIFEST_PHASE10.md`](./FILE_FOLDER_RENAME_MANIFEST_PHASE10.md) - Phase 10 canonical rename manifest and conversion model
- [`MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md`](./MASTER_PLAN_PHASE_EXECUTION_ORCHESTRATION.md) - Phase trigger orchestration model (GitHub + Cursor)
- [`ONLINE_OFFLINE_STRATEGY.md`](./ONLINE_OFFLINE_STRATEGY.md) - Feature-by-feature strategy

**Implementation:**
- [`OFFLINE_CLOUD_AI_ARCHITECTURE.md`](./OFFLINE_CLOUD_AI_ARCHITECTURE.md) - AI/LLM offline architecture
- [`architecture_ai_federated_p2p.md`](./architecture_ai_federated_p2p.md) - AI2AI network architecture
- [`../offline_ai2ai/`](../offline_ai2ai/) - Offline AI2AI documentation

**Related Documentation:**
- [`../ai2ai_system/AI2AI_OPERATIONS_AND_VIEWING_GUIDE.md`](../ai2ai_system/AI2AI_OPERATIONS_AND_VIEWING_GUIDE.md) - AI2AI system operations
- [`../../MASTER_PLAN.md`](../../MASTER_PLAN.md) - Master execution plan
- [`../../plans/feature_matrix/FEATURE_MATRIX.md`](../../plans/feature_matrix/FEATURE_MATRIX.md) - Complete feature list

---

**Last Updated:** February 15, 2026  
**Status:** Active Reference - Use this index to navigate architecture documentation
