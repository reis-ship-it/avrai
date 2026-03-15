# AVRAI Reality Model Requirements

**Date:** March 9, 2026  
**Status:** Explicit build-driving requirements  
**Scope:** Reality-model engine, runtime boundary, agent hierarchy, and mouth behavior for Birmingham beta and the target engine direction beyond beta

## 1. Normative Status

This document is not exploratory.

Everything captured here should be treated as explicit for the build of the Birmingham beta launch unless a later explicit decision supersedes it.

This document incorporates requirements clarified through architecture review and direct product intent discussion.

## 2. Core Mission

The AVRAI reality model exists to:

1. learn reality from external human input and behavior
2. build internal understanding of human reality over time
3. share that understanding back outward in ways that help the human understand their own reality
4. help humans understand where they can belong, what they can enjoy, and who they fit well with
5. reduce overthinking by settling decision-making with honest, cautious, contextual guidance

The reality model is therefore not just a scorer.
It is a persistent, human-centered, relational cognition engine.

## 3. Primary Build Direction

### 3.1 Evaluator-first, planner-ready

For Birmingham beta, the reality model must be:

1. evaluator-first
2. ready to support limited planner-generated candidates second
3. able to learn from evaluator outcomes immediately
4. able to support future planning authority without requiring a redesign

The intended sequence is:

1. evaluate surfaced options well
2. learn from outcomes and explicit feedback
3. introduce limited planner-generated candidates
4. expand planning authority only as trust and training quality improve

### 3.2 Eventual authority

The reality model is the intended eventual authority for:

1. recommendation judgment
2. fit evaluation
3. confidence and uncertainty
4. planning signals
5. explanation traces

Formulas and heuristics may remain as fallbacks during beta, but they are not the desired final authority.

## 4. What The Reality Model Must Own

The engine-owned reality model should own:

1. persistent user state
2. state encoding
3. action encoding
4. feature fusion across humans, places, events, groups, businesses, lists, and locality
5. episodic memory
6. semantic memory
7. procedural memory
8. transition prediction
9. energy scoring / fit evaluation
10. planning support
11. uncertainty and confidence
12. explanation traces
13. local model lifecycle
14. knot synthesis and knot-consumption pathways as part of engine cognition

## 5. Core Questions The Beta Reality Model Must Answer

The Birmingham beta reality model must be able to answer all of the following classes of question:

1. should I go here?
2. will I fit in here?
3. what kind of place is this for someone like me?
4. what group should I spend time with tonight?
5. why do you think this is a good idea?
6. would I like this place?
7. what should I do or where should I go today?
8. is there a spot, group, or event for `x`, `y`, or `z` vibe?
9. what spots, lists, events, clubs, or communities have `x`, `y`, `z` vibe?
10. can you make me a list of things to do or places to go today, tomorrow, this weekend, or in general?

If the system does not know enough yet, it must say so honestly and ask follow-up questions.

## 6. Modeled Domain Entities

These entities are required deeply for Birmingham beta v1:

1. human
2. place / spot
3. event
4. group / club / community
5. other individual human as contextual entity
6. list
7. business, treated as place-level actor and protoagent baseline
8. locality

### 6.1 Business protoagents

Businesses without claimed business accounts should still be treated as static protoagents with:

1. priors
2. preferences and fit constraints
3. evolving business-knot baselines

When a human claims a business account later, that protoagent should already have a strong baseline.

## 7. Agent Hierarchy For Birmingham Beta

Day-1 Birmingham beta hierarchy should include exactly these active agent layers:

1. personal reality agent
2. locality agents
3. Birmingham city agent
4. top-level reality agent

These should be understood as the complete active hierarchy for Birmingham beta day 1.

State, country, region, and global layers are intentionally missing from beta and are not required for launch.

### 7.1 Speech authority

Only the personal agent may speak directly to the human.

Higher agents may speak only to:

1. lower agents
2. admin / operator surfaces

Higher agents must never message the user directly.

## 8. App, Runtime OS, And Reality Model Boundary

The boundary is:

`app -> runtime OS -> reality model engine`

### 8.1 App

The app owns:

1. UI
2. user interaction surfaces
3. rendering of chat, lists, explore, and notifications

The app must not own:

1. knot creation
2. engine cognition
3. raw reality-model math

### 8.2 Runtime OS

Runtime OS owns:

1. `who / what / when / where / why / how` kernels
2. governance
3. permissions
4. scheduling
5. transport
6. AI2AI routing
7. notifications
8. execution policy
9. offline / online action gating
10. renderer selection

Runtime OS is the governed execution layer.

### 8.3 Reality model

The reality model owns cognition.

It may decide things such as:

1. I need more information
2. I am uncertain
3. these candidates fit best
4. this deserves a follow-up question
5. this should be surfaced in the daily drop

But it does not bypass runtime governance.

The operating rule is:

1. reality model decides what should happen
2. runtime OS decides whether and how it may happen
3. app presents it

## 8.4 Runtime OS operational learning

Runtime OS should also learn and improve, but only as an operational system, not as a second human-reality brain.

The explicit rule is:

1. reality model learns human reality
2. runtime OS learns execution reality

Runtime OS should be allowed to learn:

1. recovery success and failure patterns
2. transport quality patterns
3. BLE and local Wi-Fi reliability by context
4. queue and retry effectiveness
5. notification timing quality
6. rollout and canary safety
7. resource-budget adaptation
8. device-tier execution behavior

Runtime OS should not be allowed to learn:

1. new safety rules on its own
2. new legal or compliance rules on its own
3. permission boundary changes on its own
4. arbitrary self-modifying behavior without gates

The correct model is:

1. the reality model is the human-reality brain
2. the runtime OS is the governed self-healing body and nervous system

### 8.5 Does the OS have an agent?

The OS may have an operational intelligence layer, but it should not be treated as a user-facing personality agent.

The preferred implementation shape is:

1. recovery kernel
2. learning kernel
3. resource kernel
4. federation kernel
5. human-override kernel

This is agent-like in operational behavior, but not a second conversational self.

### 8.6 OS self-healing and self-improvement

The runtime OS should be:

1. self-healing
2. selectively self-learning
3. selectively self-improving
4. bounded by explicit guardrails, promotion gates, and rollback paths

Any OS component that can adapt production behavior must declare:

1. immutable constraints
2. learnable parameters
3. promotion gates
4. rollback path

### 8.7 Feedback back into core OS

OS/runtime updates and operational learnings should flow back into the AVRAI core OS as bounded improvement signals.

Allowed feedback classes include:

1. signed telemetry
2. failure signatures
3. recovery outcomes
4. resource-budget learnings
5. transport and reliability learnings
6. bounded policy updates
7. model and configuration updates under governance

The OS must not rewrite itself arbitrarily.

## 9. DNA

### 9.1 Definition

For Birmingham beta, DNA is:

1. a lightweight mathematical exchange-safe identity and fit abstraction
2. derived from the fuller local reality model
3. suitable for quick local comparison over BLE, local Wi-Fi, and locality pathways
4. rich enough to carry abstracted pattern, routine, history, and fit information
5. explicitly not direct personal data

DNA includes:

1. persistent user-state trajectory abstractions
2. knot/topology abstractions
3. quantum / vibe abstractions
4. goal tendencies
5. memory-derived abstractions
6. routines
7. readiness tendencies
8. belonging tendencies

DNA does not include direct personal data.

### 9.2 Exchange model

Beta DNA exchange should work like this:

1. quick DNA comparison over BLE or local link
2. if strong similarity or relevance exists, make a note for a richer later sync
3. perform the richer sync later over governed Wi-Fi / AI2AI channels
4. keep the exchanged layer lightweight and bounded
5. delete ephemeral comparison artifacts from peer devices after the learning step completes

The full local reality model stays richer and more private than the exchanged DNA layer.

## 10. Knot Ownership

Knot creation and knot math are engine-owned.

Explicit ownership rule:

1. app does not create knots
2. runtime OS does not own knot math
3. engine owns knot synthesis
4. reality model consumes knot outputs as part of broader cognition

Recommended implementation shape:

1. knot remains a modular engine representation
2. reality model requests knot synthesis and updates
3. reality model consumes knot-derived topology and features

## 11. Memory Requirements

All of the following are required in the reality model:

1. episodic memory
2. semantic memory
3. procedural memory
4. explanation memory
5. affective-state memory
6. persistent user identity and change over time inside engine

Memory should support both:

1. lightweight continuous updates
2. deeper consolidation windows

## 12. Offline And Online Requirements

All core personal-agent cognition should function offline for the user:

1. fit judgments
2. recommendation ranking
3. self-explanations
4. list creation from surfaced options
5. memory updates
6. planning support

Offline behavior should still log for later sync upward when the user reconnects.

Cloud or backend infrastructure may support:

1. relay
2. aggregation
3. backup
4. admin oversight
5. higher-agent hosting

But cloud must not become the cognitive authority for the personal agent.

## 13. Mouth Behavior Invariants

The mouth, whether online AI or offline SLM, must never act like the brain.

These are explicit invariants:

1. never lie
2. never bluff
3. never hallucinate certainty
4. never invent reasons the brain did not produce
5. explicitly say when uncertainty is present
6. ask follow-up questions when needed
7. label low-confidence guesses as low-confidence
8. never fabricate information about other humans

If the brain is unclear, the mouth must make uncertainty explicit and seek clarification.

This is a first-class documented invariant.

## 14. Online AI And Offline SLM Role

The reality model is the brain.

The offline SLM and online AI are the mouth.

For Birmingham beta:

1. the mouth may verbalize, summarize, clarify, and parse ambiguous intent
2. the mouth may not produce substantive judgments on its own
3. the mouth may not override the reality model
4. the mouth may not independently decide fit

## 15. Goal Handling

Goals are first-class.

The explicit rule is:

1. direct user-stated goals outrank inferred goals
2. passive behavior may challenge interpretation, but not overrule the user in-session
3. if explicit and passive signals conflict, the agent should ask the user directly
4. higher agents may learn from conflict-resolution patterns and share them back down

## 16. Fit Logic

Fit should be:

1. user-centered
2. bidirectional where appropriate
3. omnidirectional where possible behind the scenes
4. always presented from the human’s perspective

Beta priority is any connection between a human and:

1. place
2. event
3. group / club / community
4. list
5. business
6. locality

Group matching is the confidence-first social starting point.

Specific-human matching is intentionally delayed.

### 16.1 Specific-human gate

No specific human-to-human suggestion should occur in beta unless the match exceeds an extreme caution threshold.

The explicit threshold for a direct human match suggestion is:

1. `99.5%` DNA identity or stronger

This should be treated as an effective near-disable gate for beta.

## 17. Confidence And Uncertainty Contract

User-facing confidence buckets for Birmingham beta are:

1. high confidence: `> 75%`
2. medium confidence: `> 50%` and `<= 75%`
3. low confidence: `<= 50%`

If uncertainty is high:

1. the system should say it is uncertain
2. ask follow-up questions
3. continue up to 5 total questions
4. ask no more than 2 questions at a time
5. still provide a response in chat if the human is engaging

## 18. Proactive Behavior

The personal agent may proactively message the user first, but only under strict limits.

Rules:

1. no more than 4 independent proactive messages per 24 hours
2. proactive messages in beta are only for asking for human information or follow-up about events
3. opportunity alerts should generally be app notifications, not independent agent messages
4. readiness, belonging cautions, and pattern insights should be available when asked, not usually proactively announced

Push notification should open chat, and the actual follow-up should live in chat.

## 19. Autonomous Action Boundary

The personal agent may autonomously request runtime OS actions if they directly help the human fulfill AVRAI’s purpose and remain within governance.

Allowed classes include:

1. send follow-up chat
2. create AI-generated candidate lists from surfaced options
3. add items to daily-drop style suggestion surfaces
4. trigger notification pathways through runtime OS
5. queue a question for later

Not allowed:

1. opening arbitrary pages as an autonomous action
2. creating options from nothing
3. bypassing runtime governance

## 20. Candidate Generation Rule

The reality model may create candidate lists only from already surfaced options.

It may not generate options from nothing.

This is both:

1. a beta planning boundary
2. a philosophical rule aligned with the requirement that the system not act as if it can create from nothing

## 21. Lists

AI-generated lists:

1. may mix intents
2. should carry a dominant explanation for the list itself
3. should be savable
4. should expire after 24 hours if unsaved
5. should warn the user in the AI-generated list tab that unsaved lists expire
6. should be editable by the user
7. should teach the model through those edits

## 22. Language And Implementation Recommendation

The recommended implementation split is:

1. Rust for the core shipped cognition engine
2. Dart for package contracts, runtime integration, facades, and app-facing APIs
3. Python for research, training, distillation, and model production tooling

Explicit recommendation:

1. `engine/reality_engine` should remain the package boundary
2. the deepest shipped cognition core should move toward Rust behind that package
3. Dart should remain the integration shell, not the final home for the deepest engine core

## 23. Higher-Agent Data Flow

Higher agents may receive anything that has passed through the air gap and been transformed into bounded learning signals, including:

1. DNA abstractions
2. predictions
3. conflicts
4. solutions
5. situations
6. kernel truths
7. success and failure patterns
8. learned behaviors
9. routine commonalities

Hard rule:

1. no direct human personal data may be shared upward

Recommended practical form:

1. privacy-bounded summaries
2. bounded abstractions
3. no raw private text
4. no direct identity leakage

Higher agents may send downward:

1. kernel adjustments
2. reality-model truths
3. pattern advisories
4. locality priors
5. conflict-resolution heuristics
6. confidence adjustments
7. opportunity candidates
8. success and failure patterns
9. learned behaviors
10. hard and soft priors
11. conviction challenges
12. model updates

## 24.1 Admin to OS direct chat

Admin should have a direct chat service with the runtime OS.

This chat is not a user-facing social chat surface.
It is an operational and governance conversation surface for:

1. security
2. health
3. recovery state
4. operational value
5. drift and reliability
6. kernel status
7. transport quality
8. rollout and rollback discussion
9. any other operational area useful for safely running the system

The admin-to-OS chat service should help admin inspect and discuss:

1. what the OS believes is happening operationally
2. why certain recovery or fallback actions were taken
3. what health, drift, or reliability risks the OS sees
4. what operational improvements may be worth applying

This chat should be bounded by governance, auditability, and explicit authority rules.

## 24. Higher-Agent Hosting

For Birmingham beta:

1. personal agent runs on device
2. locality, city, and top-level reality agents should run on controlled private infrastructure
3. admin app should act as control plane, not the cognition host itself
4. Supabase may be used temporarily as relay, auth, audit, and sync support
5. Supabase should not be treated as the long-term cognitive authority host

## 25. Beta Trust And Safety Direction

The preferred failure mode order is:

1. too cautious
2. too exploratory
3. too optimistic
4. too restrictive
5. too confident
6. too vague

This preference order should shape:

1. confidence thresholds
2. proactive messaging
3. social-fit gates
4. mouth behavior

## 26. Success Sentence

The Birmingham beta reality model succeeds when:

it consistently helps people understand where they can belong, what they can enjoy, and who they fit well with, while learning the patterns of behavior.
