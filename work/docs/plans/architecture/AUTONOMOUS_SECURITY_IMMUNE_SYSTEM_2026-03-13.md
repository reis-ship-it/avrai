# AVRAI Autonomous Security Immune System

**Date:** March 13, 2026  
**Status:** Active architecture spec  
**Purpose:** Define the security-kernel doctrine for AVRAI as an autonomous security immune system: continuous sandboxed red-teaming, human-in-the-loop policy promotion, privacy-preserving admin oversight, and signed propagation of preventative and interventional countermeasures across the mesh and recursive governance hierarchy.

---

## 1. Core Thesis

AVRAI should behave like a living immune system, not a passive perimeter.

The system should be:
- continuously probing itself in isolated sandboxes,
- learning exploit patterns before they are used in production,
- containing suspicious behavior with bounded blast radius,
- preserving memory of solved attacks,
- and propagating validated countermeasures quickly across the mesh and governance hierarchy.

The metaphor is deliberate:
- **Prevention** is immune readiness.
- **Detection** is screening and diagnosis.
- **Containment** is triage and quarantine.
- **Countermeasure rollout** is vaccination or preventative medicine.
- **Recovery** is intervention, stabilization, and anti-relapse care.

The goal is not to claim literal invulnerability. The goal is to make AVRAI progressively harder to hack, faster to defend, and more resilient under novel attack pressure than a system that only waits for human responders.

---

## 2. Why "Immune System" Is Better Than "Panopticon"

The panopticon image is useful for vigilance, but dangerous as architecture.

A true panopticon implies:
- one watcher,
- maximal central visibility,
- and concentration of trust.

That conflicts with AVRAI's privacy and governance philosophy. A single all-seeing watcher becomes the best attack surface in the system and risks violating the Air Gap and user-agency constraints.

An immune-system architecture is better because it implies:
- distributed sensing,
- specialized responders,
- memory of prior threats,
- bounded interventions,
- and escalation only when necessary.

So the implementation target is:

**Constitutional security kernel + autonomous sandbox red-team + immune memory + HiTL promotion gates**

not:

**one omniscient super-agent with unlimited authority**

---

## 3. Success Condition

The autonomous security immune system is successful when:

1. AVRAI is under continuous internal adversarial pressure in sandboxes, replay lanes, and shadow lanes.
2. Novel attack paths are detected, classified, and converted into signed countermeasure bundles quickly.
3. Production protections are promoted through explicit governance and human approval rules.
4. Countermeasures propagate across personal, locality, world, and universal strata without violating privacy or creating broadcast storms.
5. The system becomes more robust after incidents instead of only returning to the previous fragile state.

---

## 4. Non-Goals

This architecture does **not** promise:

- literal "unhackability,"
- an excuse to bypass privacy boundaries,
- unrestricted inspection of raw user conversations,
- self-authorizing policy mutation by the security AI,
- or silent expansion of surveillance scope.

If AVRAI ever becomes "secure" only by centralizing all raw truth into one watcher, it will have violated both the Air Gap philosophy and the no-unilateral-control principle.

---

## 5. Hard Invariants

These are fail-closed and non-self-modifying:

1. **The security kernel cannot bypass the Air Gap.** Raw external payloads remain prohibited from persistence and routine cross-stratum centralization.
2. **Autonomous red-team agents run in sandbox, replay, shadow, or canary environments only.** They do not get unrestricted production mutation authority.
3. **The security AI may recommend policy changes, but may not silently rewrite kernel law.**
4. **High-impact security actions require HiTL.** This includes global quarantine, privilege-model changes, surveillance-scope expansion, and broad production blocking rules.
5. **Observation and intervention channels stay separate.** Watching a system does not itself grant the right to mutate it.
6. **All countermeasure bundles are signed, versioned, scoped, and reversible.**
7. **Peer-agent watchdog signals are advisory, not sovereign.** Personal agents can raise concern signals about counterpart behavior, but the kernel decides and logs any punitive or blocking action.
8. **No security control may silently override user agency in domains where explicit recourse is required.**
9. **False-positive control is a first-class requirement.** A security system that panics constantly is itself a reliability failure.
10. **The immune system must remain bounded.** No infinite red-team loops, no runaway simulation budgets, no unbounded propagation fan-out.

---

## 6. Core Architecture

### 6.1 Constitutional Security Kernel

This is the minimal mandatory enforcement layer.

Responsibilities:
- capability checks,
- governance-path separation,
- attestation verification,
- tool/action gating,
- quarantine and rollback execution,
- break-glass enforcement,
- signed manifest validation,
- and fail-closed emergency freeze behavior.

The constitutional kernel should be small, deterministic, and difficult to bypass. It is not the place for speculative reasoning.

### 6.2 Sandbox Orchestrator

The sandbox orchestrator creates isolated environments for:
- protocol fuzzing,
- AI2AI poisoning attempts,
- memory corruption drills,
- prompt/tool jailbreak attempts,
- mesh attestation spoofing,
- update-channel attacks,
- operator abuse drills,
- replay-based incident reconstruction,
- and digital-twin attack simulation.

It owns:
- environment templates,
- attack budgets,
- scenario scheduling,
- evidence capture,
- and cleanup guarantees.

### 6.3 Autonomous Red-Team Agent Farm

These are specialized attacker agents.

Example attacker roles:
- prompt-injection attacker,
- tool-misuse attacker,
- mesh spoofing attacker,
- privilege-escalation attacker,
- conversation-manipulation attacker,
- data-exfiltration attacker,
- poisoning attacker,
- collusion attacker,
- admin-runbook attacker,
- and simulation-gap attacker.

Each attacker has:
- explicit scope,
- explicit tool/capability budget,
- a measurable objective,
- and a deterministic evidence trail.

### 6.4 Immune Memory

AVRAI should persist redacted, reusable security memory:
- threat signatures,
- exploit preconditions,
- affected surfaces,
- successful containment actions,
- false-positive lessons,
- rollout evidence,
- and recurrence-risk tags.

This memory is the "antibody library" of the platform.

Immune memory should support both:
- **preventative defense**: block known exploit classes before impact,
- and **interventional defense**: recognize active incident shape and route the right containment action quickly.

### 6.5 Policy Promotion Gate

All meaningful production hardening passes through a promotion gate:
- shadow validation,
- replay validation,
- counterfactual harm check,
- privacy/redaction check,
- false-positive check,
- operator review,
- signed approval,
- staged rollout,
- rollback TTL.

The security AI can draft the prescription. Humans still sign the medication order.

### 6.6 Containment and Intervention Plane

When the immune system detects credible risk, it needs bounded interventions:
- lane disable,
- scoped kill switch,
- runtime or cluster quarantine,
- attestation revocation,
- trust-anchor rotation,
- forced shadow-only mode,
- rollback to safe bundle,
- elevated inspection ladder,
- mandatory dual approval before re-enable.

These are "medicine" actions: not normal behavior, not silent, always logged.

### 6.7 Admin App HiTL Cockpit

The admin app is the governed human-control surface for this system.

It should expose:
- live red-team campaigns,
- sandbox fleet health,
- attack graph explorer,
- immune memory ledger,
- countermeasure promotion queue,
- containment queue,
- vaccination rollout status,
- false-positive review lane,
- and break-glass controls.

The admin app is not a backdoor. It is an audited clinical console.

### 6.8 Recursive Governance Hierarchy

The immune system should operate across existing AVRAI strata:
- personal,
- locality,
- world,
- universal.

Pattern:
- personal level detects highly local anomalies and peer behavior concerns,
- locality level aggregates neighborhood or cohort attack trends,
- world level reasons over cross-locality attack classes,
- universal level governs signed countermeasure doctrines and emergency freezes.

Higher strata should see compressed truth by default, not routine raw detail.

---

## 7. Runtime Operating Model

### 7.1 Preventative Security

AVRAI should continuously run preventative campaigns against:
- agent tool boundaries,
- AI2AI transport and trust lanes,
- mesh attestation and revocation paths,
- conversation and memory boundaries,
- learning/update channels,
- admin/operator paths,
- export and telemetry leakage paths,
- supply chain and packaging surfaces.

Outputs:
- updated threat signatures,
- strengthened deny rules,
- revised anomaly thresholds,
- new replay tests,
- candidate countermeasure bundles.

### 7.2 Interventional Security

When an incident or precursor signal appears:

1. Detect and classify.
2. Match against immune memory.
3. Run accelerated sandbox replay against the suspected exploit chain.
4. Compute recommended containment scope.
5. If below the autonomy threshold, execute approved bounded containment.
6. If above the threshold, route to HiTL immediately with evidence pack.
7. After containment, produce a signed immune-memory update and promotion candidate.

### 7.3 Continuous Attack Pressure

The red-team system should always be active, but not always equally aggressive.

Suggested cadence:
- continuous low-intensity probing,
- scheduled daily/weekly scenario suites,
- event-triggered surge campaigns after major code or model changes,
- incident-triggered replay campaigns,
- release-blocking full-lane drills before autonomy expansion.

### 7.4 Digital Twins

Digital twins are especially useful here.

Each major runtime surface should have a sandbox twin:
- agent twin,
- mesh twin,
- locality twin,
- admin-control twin,
- model/update twin,
- conversation-policy twin.

The red-team should attack the twin first. The immune system learns there before production sees the same pattern.

---

## 8. Admin App Requirements

The admin app should grow a dedicated autonomous-security area with at least these surfaces:

1. **Live Campaigns**
   - active attacker agents,
   - target scope,
   - scenario type,
   - risk score,
   - current result.

2. **Sandbox Fleet**
   - sandbox templates,
   - runtime health,
   - isolation guarantees,
   - replay status,
   - budget usage.

3. **Attack Graph Explorer**
   - entry point,
   - privilege transitions,
   - data movement path,
   - blast radius,
   - blocked vs unblocked edges.

4. **Immune Memory Ledger**
   - threat signature,
   - first-seen timestamp,
   - last-seen timestamp,
   - recurrence score,
   - associated countermeasure bundle,
   - false-positive history.

5. **Containment Queue**
   - proposed quarantine/rollback/disable actions,
   - confidence,
   - urgency,
   - affected strata,
   - required approvals.

6. **Policy Promotion Gate**
   - shadow results,
   - replay proof,
   - privacy review,
   - false-positive estimate,
   - rollout plan,
   - rollback TTL.

7. **Vaccination Status**
   - which runtimes/strata have received which signed countermeasure bundle,
   - drift and noncompliance status,
   - lagging nodes,
   - revocation state.

8. **HiTL Postmortem**
   - incident timeline,
   - what was attempted,
   - what broke,
   - what prevented spread,
   - what changed afterward.

All admin views must preserve privacy ladders and default to redacted, need-to-know presentation.

---

## 9. Mesh and Hierarchy Propagation: "Vaccination"

The propagation model should behave like immunization, not arbitrary broadcast.

### 9.1 What Propagates

Not everything should propagate. AVRAI should propagate:
- threat signatures,
- signed revocation lists,
- scoped deny rules,
- prompt/tool refusal patterns,
- quarantine heuristics,
- replay tests,
- countermeasure bundles,
- and rollout policies.

AVRAI should **not** routinely propagate:
- raw private conversation content,
- raw personal memory,
- unredacted incident payloads,
- or unrestricted forensics data.

### 9.2 Countermeasure Bundle

Each propagated fix should be a signed bundle with:
- bundle ID,
- threat class,
- evidence refs,
- applicable strata,
- scope,
- expiration/review window,
- false-positive guardrails,
- rollout sequence,
- rollback plan,
- and provenance of human approvals.

### 9.3 Propagation Flow

1. Sandbox or incident discovers exploit.
2. HiTL validates diagnosis and proposed fix.
3. Signed countermeasure bundle is created.
4. Bundle is shadow-tested and canary-tested.
5. Bundle propagates by hierarchy and mesh scope.
6. Nodes confirm receipt, validation, and activation.
7. Drift monitor detects nodes that lag, reject, or diverge.

This is the immune-system equivalent of:
- a flu shot,
- allergy medicine,
- preventative care,
- and emergency intervention when symptoms have already started.

### 9.4 Storm Control

Immune propagation must stay bounded:
- dedupe windows,
- severity thresholds,
- locality scoping first,
- global rollout only when evidence supports it,
- mandatory false-positive review when a protection spreads broadly.

Otherwise the cure becomes the outage.

---

## 10. Personal Agents Watching Each Other

Personal agents can contribute to safety, but they must do so carefully.

Allowed role:
- emit signed concern signals,
- share redacted protocol anomalies,
- detect counterpart manipulation patterns,
- flag coercive or obviously policy-unsafe interaction attempts,
- raise mesh trust suspicion.

Forbidden role:
- unilateral punishment,
- unilateral deplatforming,
- unrestricted sharing of conversation detail,
- reputation blacklisting without kernel/governance review.

The design rule is:

**peer watch is sensing, not sovereignty**

Peer-agent observations enrich the immune system. They do not replace the security kernel or human governance.

---

## 11. AVRAI Security AI vs Raspberry Pi 4 LLM Workers

### 11.1 AVRAI Security AI

This should be the main strategist/orchestrator.

Responsibilities:
- generate attack hypotheses,
- prioritize scenario campaigns,
- correlate evidence across incidents,
- propose countermeasure bundles,
- estimate blast radius,
- recommend rollout strategy,
- and draft operator review packs.

This system needs stronger reasoning, longer context, and better cross-surface synthesis than edge hardware can reliably provide.

### 11.2 Raspberry Pi 4 LLM Workers

Pi 4 nodes are useful as expendable scouts and swarm workers.

Best roles:
- low-cost replay executors,
- protocol fuzzers,
- prompt-attack canaries,
- lightweight adversarial swarm nodes,
- mesh-edge attacker emulators,
- and always-on household or lab test anchors.

Poor roles:
- central policy authority,
- global promotion gate,
- or sole security reasoner.

### 11.3 Recommended Hierarchy

- **AVRAI Security AI** = central strategist and evidence synthesizer
- **Pi 4 workers** = distributed attacker/scout fleet
- **Security kernel** = constitutional enforcement layer
- **Admin HiTL** = clinical authority for production promotion

---

## 12. Threat Classes

The autonomous immune system should continuously cover at least:

- prompt injection and jailbreak paths,
- tool misuse and action-gateway bypass,
- AI2AI poisoning and collusion,
- mesh attestation spoofing and route hijack,
- memory poisoning and persistence corruption,
- rollback or update-path abuse,
- secrets and CI supply-chain compromise,
- telemetry and log exfiltration,
- operator privilege abuse,
- policy-ladder bypass,
- dream/simulation exploit mismatch,
- and low-signal precursor patterns that imply a future exploit chain.

This aligns directly with the canonical red-team matrix and should expand with new lanes, not replace them.

---

## 13. Metrics and Release Gates

Required immune-system metrics:

- time to detect (`TTD`),
- time to contain (`TTC`),
- time to heal (`TTH`),
- recurrence rate,
- false-positive rate,
- blast-radius containment score,
- replay coverage,
- exploit-to-countermeasure conversion time,
- countermeasure propagation latency,
- % of fleet protected by signed bundle,
- red-team lane pass rate,
- and ratio of prevented incidents to externally discovered incidents.

Release and autonomy gates should require:
- green critical red-team lanes,
- signed bundle verification,
- replay proof for new protections,
- false-positive bounds,
- rollback drill success,
- and HiTL signoff for high-impact promotions.

---

## 14. Cross-Phase Wiring

This doctrine is not a separate product lane. It is a cross-phase authority that should guide existing plan sections.

| Area | Master Plan Anchors | Required Effect |
|---|---|---|
| Learning-channel adversarial hardening | `10.9.10`, `10.9.20` | Continuous offensive simulation, signed update integrity, scoped kill switches |
| Universal break-to-learning | `10.9.12`, `1.1E.14-1.1E.18` | Immune memory, first-occurrence triage, dwell budgets, kernel freeze paths |
| High-impact oversight | `10.9.18`, `10.9.24`, `10.9.25` | Admin HiTL review, intervention console, policy reasoning traceability |
| Admin command center | `10.9.22-10.9.25` | Live campaigns, attack graph, containment queue, vaccination status |
| Autonomous research lane | `7.9`, `7.9.31`, `7.9.37-7.9.39` | Synthetic stress suites, bounded red-team autonomy, storm suppression |
| Federated propagation | `8.1.10-8.1.11`, `8.1.14`, `8.1.18-8.1.19` | Signed countermeasure rollout, bounded fan-out, contradiction quarantine |
| Cognitive kernel / AVRAI OS | `12.1`, `12.3`, `12.6` | Constitutional security kernel, governance channels, headless sandbox nodes |
| Privacy and Air Gap | `2.1`, philosophy `5.1-5.3` | No raw-data panopticon; redacted evidence and permission ladders only |

---

## 15. Implementation Doctrine

When implementation starts, follow this order:

1. Strengthen the constitutional kernel and signed-manifest path.
2. Build sandbox orchestration and replay evidence capture.
3. Add autonomous red-team agents inside bounded simulation environments.
4. Add immune memory and countermeasure bundle format.
5. Add admin app review and containment surfaces.
6. Add signed propagation and vaccination-status tracking.
7. Only then widen autonomous containment scope.

Do not start with "AI that can change security policy by itself." That is the wrong order and a likely self-own.

---

## 16. Naming Guidance

Preferred umbrella term:

**Autonomous Security Immune System**

Valid sub-terms:
- security kernel,
- red-team control plane,
- immune memory,
- vaccination bundle,
- containment prescription,
- security AI.

Avoid framing it as:
- omniscient watcher,
- unrestricted panopticon,
- or self-governing security sovereign.

---

## 17. Future-Reference Update Rules

If AVRAI changes any of the following, this document should be reviewed:
- security kernel authority boundaries,
- sandbox orchestration model,
- admin command-center security surfaces,
- red-team promotion policy,
- mesh propagation rules,
- privacy ladder for incident inspection,
- or Pi/edge-worker role in the security fleet.

Companion documents that should stay aligned:
- `docs/MASTER_PLAN.md`
- `docs/MASTER_PLAN_TRACKER.md`
- `docs/security/RED_TEAM_TEST_MATRIX.md`
- `docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md`
- `docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md`
- `docs/plans/rationale/PHASE_12_OS_RATIONALE.md`

---

## 18. Final Doctrine

AVRAI should not wait passively to be attacked.

It should maintain a governed internal adversary, learn from pressure, preserve the memory of solved failures, and distribute validated protections quickly across its mesh and hierarchy.

In short:

**always testing, always learning, always bounded, always reversible**

That is how AVRAI becomes progressively harder to break without becoming the kind of centralized surveillance system it exists to avoid.
