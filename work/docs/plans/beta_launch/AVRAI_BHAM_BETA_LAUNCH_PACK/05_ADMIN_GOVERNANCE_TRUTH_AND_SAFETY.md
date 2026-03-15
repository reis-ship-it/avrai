# Admin, Governance, Truth, And Safety

## Admin App Boundary

- The admin app is separate from the user app
- Access is only through the secure admin app
- Admin is required on day 1

## Day-1 Admin Surfaces

- live Birmingham map
- AI2AI exchange map/layer
- user-agent health list
- single-agent detail view
- locality-agent detail view
- kernel health dashboard
- flagged content / flagged agent queue
- creation moderation queue
- iOS vs Android health dashboard
- beta feedback inbox
- reality-model chat
- learning/recommendation audit trail
- event/list/community/club explorer
- notifications / incidents center
- direct OS operations chat

## Direct Admin To OS Chat

Admin should have a direct chat service with the runtime OS.

This chat exists so admin can discuss and inspect:

- security
- health
- operational value
- drift
- recovery
- reliability
- kernel status
- transport quality
- rollback and rollout behavior

This is not a social chat surface.
It is an operational control and inspection surface.

### Rules

- the chat is separate from end-user chat
- the chat must be auditable
- the chat must be governance-bounded
- the OS may explain what it believes is happening operationally
- the OS may explain why it took a recovery or fallback action
- the OS may not bypass human admin authority

## Admin Visibility Rule

- Admin sees agents, kernels, tuples, operational math, projections, success rates, and locality/reality-model learning
- Admin does not see direct human identity by default
- Beta consent explicitly covers this agent-level visibility

### Never Visible By Default

- names
- phone numbers
- addresses
- social handles
- linked account identity

### Break-Glass Rule

- Break-glass exists only for dangerous, malicious, illegal, hacking, or trust-breaking situations
- AI cannot break glass
- Human admin is the final authority

## Governance Versus Behavior Truth

### Governance Truth

Highest authority for:

- safety
- quarantine
- rollback
- abuse/trust decisions
- policy constraints

Order of authority:

1. human admin / reality-model governance
2. lower governance layers according to the model hierarchy

### Behavior Truth

Highest authority for learning what the human actually likes or does:

1. the human’s direct real-world behavior
2. direct same-place/same-time nearby exchange
3. relayed agent-safe AI2AI information
4. locality priors
5. preload/simulation priors

Simulation and preload are priors, not reality claims.

If fresh live evidence conflicts with historical replay or preload:

1. the live evidence should take precedence
2. the older prior should be downgraded or replaced
3. admin should be able to inspect that override path

Strong reality-model convictions may flow downward as learned lenses or constraints. They do not automatically force a user-facing behavior change unless safety or governance requires it.

## Runtime OS Learning Rule

The runtime OS should be allowed to self-heal, self-learn, and self-improve operationally within explicit boundaries.

The OS may learn from:

- recovery outcomes
- failure signatures
- transport reliability
- resource pressure
- drift and health signals
- queue and retry behavior
- rollout and rollback outcomes

The OS may not autonomously redefine:

- safety policy
- legal policy
- permission boundaries
- governance hierarchy

The intended split is:

- reality model learns human reality
- runtime OS learns execution reality
- governance decides when live truth overrides stale priors

## Geography Seeding Rule

At launch there is one master human admin app.

If AVRAI boots in a geography without seeded locality agents:

1. the reality model should escalate upward
2. the runtime OS should request permission to attach fresh locality intake sources
3. the human admin must approve the seeding
4. the raw intake should be used to seed locality agents, not to create a permanent unconstrained world database
5. the seeding request, authorization, source provenance, and resulting locality-agent bootstrap state must remain auditable

## Public Creation And Moderation

- Public lists/clubs/communities/events go live immediately
- The system can flag/pause dangerous, illegal, harmful, or trust-breaking creations
- If paused, the creator should be able to explain via admin chat
- Admin may quarantine or remove users, agents, spots, lists, clubs, communities, or events as needed

## Quarantine Rules For Relay And Agent Truth

Relay or learned information should be quarantined when it is:

- malicious or a hacking attempt
- impossible or internally contradictory
- too far outside locality context without support
- duplicated/spammy
- safety-risky or suspicious enough to require admin review

Suspicious cases should be flagged to admin so governance can learn what is acceptable versus unacceptable suspicious behavior.

## Agent Falsity Rule

An agent is considered materially false when its shared outward truth is false at meaningful scale in external kernel comparison.

Operational beta rule:

- peer/locality consensus can place an agent in quarantine
- human admin review can rollback or reset
- direct human report through admin chat counts as valid evidence
- about 30% of externally checkable shared information being false is a reset-grade threshold

Examples include:

- invented places
- invented clubs/communities/events/lists
- fabricated outward knowledge shared through the network

If reset happens:

- trust for the false agent drops to zero
- the failed kernels/mind state should still be studied in admin to understand why/how it failed

## Strong Conviction Rule

- Sparse data is allowed
- Strong conviction from sparse data is not
- For places/clubs/communities/events, grounded vibe/DNA should require:
  - about 2 weeks of consistent real-world behavior, or
  - 3 real events/meetups/outings

Even after grounding, vibe/DNA remains allowed to keep adapting.
