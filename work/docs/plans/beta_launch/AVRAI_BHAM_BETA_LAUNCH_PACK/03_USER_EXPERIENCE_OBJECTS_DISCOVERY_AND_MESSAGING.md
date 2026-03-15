# User Experience, Objects, Discovery, And Messaging

## Primary User App Structure

- `Daily Drop`: first destination after onboarding, shows one best item from each of the 5 categories
- `Explore`: map/list discovery across `spots`, `lists`, `events`, `clubs`, `communities`
- `Profile`: top-left entry, holds identity surfaces, saved items, knot/DNA surfaces, settings
- `Chat`: top-right entry, holds AI chat, notifications, recent chats, and supported message threads
- Bottom navigation should prioritize `Daily Drop` and `Explore`
- `Explore` should support map/list toggling across all 5 categories
- Re-selecting a category should allow fast access to saved objects for that category
- Category-specific message surfaces may also be accessible from profile/context pages in addition to chat

## Daily Drop Contract

- Exactly 5 items per drop
- Exactly 1 item from each category:
  - `spot`
  - `list`
  - `event`
  - `club`
  - `community`
- If none exist in a category:
  - the system can suggest creation
  - lists may be AI-generated
- Drops refresh around the user’s learned start-of-day
- Old drops disappear when refreshed
- Repetition window: not within 1 week unless justified by new truth
- A good daily drop = the user saves at least one item

## Object Model

### Spot

- Any place where humans can go and do things
- Can originate from users, the model, or future business claims
- Can be public or private
- Users can update lived vibe by going there and behaving there
- Users can save/respect/share
- Admin sees health, vibe/DNA/pheromones, and locality/kernel context

### List

- A collection of spots
- Any user can create
- Public or private
- Users discover through list surfaces, sharing, and AI suggestion
- Learning updates from creation, viewing, saving, sharing, and real-world follow-through
- Admin sees creation, uptake, trust/safety status, and interaction patterns

### Club

- A recurring activity with a place and time
- Any user can create
- Public or private
- Members can join, chat, suggest branches, and participate in club structure
- Leadership is a capability, not a separate account type
- Admin sees agent participation, attendance patterns, club success, and risks

### Community

- A shared-interest social group
- Any user can create
- Usually public, can be private
- Supports conversation, meetups, and community-driven activity
- Can host events
- Admin sees community identity, member agents, growth, vibe, and safety posture

### Event

- A time-bound organized happening at a spot
- Any user can create
- Communities and clubs can also create
- Users can RSVP, learn, attend, cancel, edit, and share based on permissions
- Learning updates from RSVP, attendance, dwell, follow-up, and overlap with other humans
- Admin sees attendance, actual turnout, safety warnings, and learning outcomes

## Messaging Surfaces

### Day-1 Must-Have

- user ↔ personal AI chat
- user ↔ admin chat
- user ↔ matched user direct chat
- club chat
- community chat
- event chat
- club/community leader announcements
- AI/admin summary surfaces in the admin app

### Persistence Rules

- Personal AI chat: persistent for 4 weeks or until context reset
- User/admin chat: persistent for 2 weeks
- Direct matched chat: persistent for 4 weeks
- Club chat: persistent for 4 weeks; pinned message may remain
- Community chat: persistent for 4 weeks; pinned message may remain
- Event chat: ephemeral after the event; pinned leader message allowed until event ends

### Safety And Visibility Rules

- Human chats are treated as human chats, not AI-authored content
- Participants may leave chats
- Matched-user chat begins with privacy-preserving presentation, such as initials before fuller voluntary disclosure
- Admin can see tuples and agent-safe operational context, not direct human identity by default

## Notification Contract

- Daily-drop, context-nudge, and AI2AI-compatibility notifications are capped at 3 per day total
- Human message notifications are not capped
- Default quiet hours start at 10pm-6am and then become personalized by agent learning
- If the model is uncertain, it should prefer higher-level model consultation, then silence/observation, then later daily-drop or explicit user ask
- Low-confidence proactive suggestions are not the beta baseline

## Direct User Matching Rule

- AVRAI beta does not suggest casual 1:1 meetups
- The only allowed direct user-to-user path is an extremely high-confidence compatibility case
- Threshold: about 99.5%+ compatibility
- Flow:
  - both users receive a privacy-preserving prompt
  - both can say yes or no independently
  - if both say yes, in-app chat opens
  - if one says no, the other gets a gentle decline/encouragement response
