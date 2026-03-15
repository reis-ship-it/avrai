# Reality Model Build Contract

**Date:** March 9, 2026  
**Status:** Explicit beta build contract  
**Scope:** Birmingham beta launch requirements for the reality model, runtime OS interaction, higher-agent behavior, confidence, and user-facing behavior

## 1. Normative Status

This document is explicit for the Birmingham beta build.

If something here conflicts with older exploratory material, this document should be treated as the newer explicit contract for Birmingham beta unless later superseded by another explicit decision.

Primary reference:

- [AVRAI Reality Model Requirements](../../architecture/AVRAI_REALITY_MODEL_REQUIREMENTS_2026-03-09.md)

## 2. Birmingham Beta Shape

The Birmingham beta reality model must be:

1. evaluator-first
2. planner-ready, with limited candidate generation second
3. on-device for the personal agent
4. cautious by default
5. honest about uncertainty
6. able to respond in chat even when uncertain

### 2.1 Epistemic humility and Bayesian update contract

The reality model must never treat simulation, preload, or replay output as reality itself.

Operating rule:

1. simulation and preload outputs are priors
2. live user behavior, live locality evidence, and live admin correction are ground truth
3. recent real-world evidence outranks historical replay and preload assumptions
4. the system must update quickly when reality contradicts simulation
5. the system must be able to say whether a belief came from live evidence, locality consensus, or prior expectation

This is a Bayesian-update contract for beta:

1. prior expectation may shape the first guess
2. live evidence must revise the active belief
3. repeated live contradiction must collapse confidence in the prior
4. no amount of simulated repetition is permission to bluff about current reality

### 2.2 Timing governance kernel authority

The reality model must not own its own ad hoc time.

There must be one source of truth for timing:

1. the timing governance kernel is the timing authority
2. runtime OS, simulation, admin, and engine must read temporal truth through that kernel
3. quantum atomic time may improve the kernel, but may not bypass it
4. replay, Monte Carlo branching, live runtime decisions, and governance inspection must all be temporally coherent under the same authority

The timing governance kernel should be improved where quantum atomic time materially strengthens:

1. causal ordering
2. monotonic sequencing
3. uncertainty windows
4. timezone normalization
5. clock-regression detection
6. branch/run coherence for simulation and replay

## 3. Active Agent Hierarchy

The live agent hierarchy for Birmingham beta day 1 is:

1. personal reality agent
2. locality agents
3. Birmingham city agent
4. top-level reality agent

Missing higher layers such as state, country, region, and global agents are understood as out of scope for day-1 beta.

## 4. Who Talks To The Human

Only the personal agent speaks to the human.

Higher agents may speak only to:

1. lower agents
2. admin

Higher agents must never message the user directly.

## 5. User-Facing Questions The Beta Must Support

The beta build must support these question types:

1. should I go here?
2. will I fit in here?
3. what kind of place is this for someone like me?
4. what group should I spend time with tonight?
5. why do you think this is a good idea?
6. would I like this place?
7. what should I do or where should I go today?
8. is there a spot, group, or event for this vibe?
9. what spots, lists, events, clubs, or communities have this vibe?
10. can you make me a list of things to do or places to go today, tomorrow, this weekend, or in general?

## 6. Mouth Contract

The mouth contract is explicit and non-negotiable.

The mouth:

1. must never lie
2. must never bluff
3. must never hallucinate certainty
4. must never invent reasons
5. must say when the system is uncertain
6. must ask follow-up questions when needed
7. must label low-confidence guesses as low-confidence
8. must never claim to know things about other humans that the system does not have access to

If the user asks about another human, the agent should say it cannot provide information about that person, then pivot into a goal-setting conversation if the user continues.

## 7. Confidence Contract

User-facing confidence thresholds for beta:

1. high confidence: `> 75%`
2. medium confidence: `> 50%` and `<= 75%`
3. low confidence: `<= 50%`

When uncertain:

1. say so directly
2. ask follow-up questions
3. ask no more than 2 at a time
4. ask no more than 5 total before giving the best available bounded answer

## 8. Proactive Messaging Contract

The personal agent may proactively message first only within strict limits.

Rules:

1. maximum 4 independent proactive messages per 24 hours
2. proactive messages are only for asking for human information or following up about events
3. opportunity alerts should be general app notifications, not independent agent messages
4. readiness, belonging cautions, and pattern insights should be available when asked, not generally broadcast first
5. proactive prompts should be delivered as a push notification that opens chat
6. the actual follow-up question should live in chat

## 9. Social Suggestion Gate

The beta must not confidently suggest specific person-to-person meetings as a normal feature.

Explicit gate:

1. direct human match suggestions are effectively disabled unless the match exceeds `99.5%` DNA identity

This should be treated as a very strong caution gate for beta.

Group matching is the intended social-confidence layer for wave 1.

## 10. Candidate Generation Rule

The reality model may generate candidate lists only from options that have already been surfaced.

It may not create recommendations from nothing.

## 11. Lists Contract

AI-generated lists in beta:

1. may mix intents
2. must include a dominant explanation for the list itself
3. must be savable
4. must expire after 24 hours if unsaved
5. must inform the user in the AI-generated list tab that unsaved lists expire
6. must be editable by the human
7. must teach the model through those edits

## 12. Runtime OS Interaction Contract

The reality model does not replace the OS.

The relationship is:

1. reality model decides what should happen
2. runtime OS decides whether and how it may happen
3. app renders it

For beta, the personal agent may request runtime OS actions such as:

1. sending a follow-up chat
2. creating an AI-generated list from surfaced options
3. adding items to daily-drop style suggestion surfaces
4. triggering runtime-governed notifications
5. queuing a question for later

The personal agent may not:

1. autonomously open arbitrary pages
2. bypass governance
3. create options from nothing

### 12.1 Runtime OS operational learning contract

For Birmingham beta, runtime OS should also be allowed to learn and improve operationally.

This must remain bounded.

Runtime OS may learn:

1. recovery patterns
2. transport reliability patterns
3. BLE and local Wi-Fi quality patterns
4. queue and retry effectiveness
5. notification timing quality
6. device-budget adaptation
7. rollout and rollback quality

Runtime OS may not:

1. invent new safety rules
2. modify governance boundaries on its own
3. change permission rules on its own
4. self-modify outside promotion gates and rollback paths

The beta rule is:

1. reality model learns human reality
2. runtime OS learns execution reality
3. neither may overrule fresh live ground truth with stale preload or simulation assumptions

### 12.2 OS agent rule

The OS may have an operational intelligence layer, but it is not a user-facing personality agent.

Operational intelligence should be expressed through kernel-governed behavior such as:

1. recovery logic
2. learning logic
3. resource logic
4. federation logic
5. human-override logic

### 12.3 Feedback into core OS

Operational learning should feed back into the AVRAI core OS as bounded improvement signals such as:

1. failure signatures
2. recovery outcomes
3. reliability learnings
4. bounded policy updates
5. configuration updates
6. rollout health learnings

## 13. DNA Contract

For beta, DNA is:

1. lightweight
2. mathematical
3. fast enough for BLE and local Wi-Fi exchange
4. rich enough to carry abstracted patterns, routines, history, and fit signals
5. never direct personal data

Expected exchange flow:

1. quick local DNA comparison
2. if strong similarity or relevance exists, mark a richer later exchange
3. later governed sync over better connectivity
4. keep exchanged artifacts ephemeral and bounded

## 14. Inputs In Scope

Reality-model learning inputs in scope for beta include:

1. location history
2. event attendance
3. place saves and list behavior
4. explicit likes and dislikes
5. chat text
6. calendar
7. health and wearable signals
8. Bluetooth and proximity encounters
9. business interactions
10. user-consented social and platform bridges such as Spotify, Apple, Google, Instagram, and Facebook
11. user-consented on-device emails, texts, and notifications

All inputs must pass through the air gap.

## 15. Inputs Out Of Scope

Out of scope by default:

1. journal text
2. bank statements
3. financial information
4. any data the user has not expressly permitted on device
5. legal-history prompts
6. employment prompts
7. requests for invasive personal data

If the user chooses to explicitly provide out-of-scope information into the app itself, it may still pass through the air gap under explicit consent, except for forbidden questioning behavior.

The reality model must never ask for:

1. personal legal history
2. illegal activity history
3. invasive personal data

## 16. Product Gates

The beta reality model should be considered trustworthy enough to lead over formulas only when:

1. high-confidence group and community suggestions produce positive outcomes at `>= 80%`
2. high-confidence place and event suggestions outperform formula fallback on outcome quality
3. the model asks clarifying follow-ups instead of bluffing in low-confidence cases
4. offline fit evaluation and explanation remain usable with acceptable latency
5. explicit user corrections measurably improve later recommendations
6. users report that AVRAI helps them decide without pressure or confusion
7. no specific-human suggestion behavior appears outside the extreme caution gate

## 17. Build Priority

For Birmingham beta, prioritize:

1. human -> place fit
2. human -> event fit
3. human -> group / community / club fit
4. locality-aware fit
5. list generation from surfaced options
6. uncertainty honesty

## 18. Admin To OS Direct Chat

The beta should include a direct admin-to-OS chat service.

This chat is intended for operational discussion, not end-user conversation.

Admin should be able to use this chat to discuss:

1. security
2. health
3. operational value
4. recovery state
5. drift
6. reliability
7. kernel status
8. transport quality
9. rollout and rollback behavior
10. any other useful operational concern

This chat should be:

1. auditable
2. governed
3. separate from user chat
4. able to explain why the OS made operational decisions
7. explicit-goal handling
8. correction-driven learning

Defer broader person-specific social authority until group-fit quality is proven.
