# Success Gates, Fallbacks, And Edge Cases

## Success Signals

### Usage

- average open rate target: 1-2 times per day
- real-world acted-on suggestion target: 0.5x-2x per week

### Positive Outcomes

- save/respect
- click-through
- route/open
- RSVP yes
- real attendance
- meaningful dwell
- return visits
- joining a club/community
- chat reply
- positive AI2AI exchange
- explicit positive user feedback

### Negative Outcomes

- dismiss/hide
- RSVP no
- no-show
- leaving early
- muting or blocking
- unsafe report
- bad vibe or bad chat result
- excessive phone engagement caused by the app

### Strongest Truth Signals

- real-world attendance beats taps
- repeat visits beat one-time saves
- explicit user correction beats model guess

### Meaningful/Fun Signal

- ask the user directly
- combine that answer with pre-existing signals
- keep meaning/fun as an inference, not a permanent absolute fact

## Wave-1 Expansion Gates

Do not expand beyond 25 users unless all of the following are true:

1. no Sev-1 incidents for 14 straight days
2. zero confirmed harmful/illegal/trust-breaking suggestions
3. AI2AI connections are successful for at least 80% of beta time and no cross-platform regression remains open
4. recommendation action rate stays in the target band and at least 50% of testers engage with at least one recommendation weekly
5. personal agents are coherent for at least 80% of testers
6. Birmingham locality outputs stay directionally correct for 14 days
7. all critical admin views work continuously for 14 days without breaking
8. no flagged-item queue is older than 24 hours for 14 days
9. at least 70% of testers would keep using the app weekly
10. at least 60% say it helps them find better places/people/events
11. at least 80% of testers complete a meaningful offline-first flow

## Fallback Matrix

### On-device chat / SLM fails

- fall back to online

### AI2AI BLE/system-wide local exchange fails

- full beta pause if system-wide and unexplained
- single-user/local dropouts are tolerated as non-global incidents

### Background sensing unreliable

- pause only that feature
- if systemic across multiple users, pause globally and alert admin

### Offline recommendation quality weak

- keep place recommendations and discovery alive
- reduce or avoid direct social-match behavior
- prefer safer browse/daily-drop behavior until quality improves

### Admin observability degraded

- stop new learning in the affected scope
- preserve existing state

### Public creation abused/flooded

- quarantine creation until review

### Locality learning unstable

- pause locality learning
- keep on-device personal learning and admin oversight

### Direct user-to-user compatibility looks risky

- pause only that feature

## Edge Cases

### 1. Fully Isolated User

- still learns
- still suggests from on-device truth
- still preserves saved state
- still allows creation
- queues messages and sync work

### 2. Delayed Sync Conflict

- the world can change while the device remains useful
- event cancellation/edit must reconcile cleanly
- changed place vibe becomes the new truth with explanation
- conflicting learnings can coexist until higher-order abstraction resolves them

### 3. Malicious Or Poisoned Relay

- quarantine locally
- share upward to locality/admin
- inspect why/how/when/where/what/who at admin
- reset trust if the agent is false enough to justify reset

### 4. Sparse-Data Wrong Inference

- do not treat sparse data as settled conviction
- require a grounding window before strong place/community/club/event DNA claims

### 5. Safety-Sensitive Social Action

- no casual direct 1:1 meetup suggestion baseline
- use public-place or public-event overlap as the safer default
- only the high-confidence double-opt-in path is allowed for direct contact
