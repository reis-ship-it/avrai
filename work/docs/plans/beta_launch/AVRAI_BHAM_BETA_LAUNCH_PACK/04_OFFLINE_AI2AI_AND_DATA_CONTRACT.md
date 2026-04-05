# Offline, AI2AI, And Data Contract

## Offline Definition

In this beta, `offline` means **not dependent on internet/service**.

Offline-first therefore includes:

- on-device kernels and personal-agent learning
- BLE exchange
- local Wi-Fi bridge/relay
- true peer propagation and store-and-forward over local network paths
- later wide-area online sync as a secondary assist

This is an `ai2ai-only` transport model, not direct human p2p.

## Transport Model

### Day-1 Local Transport Paths

- BLE
- local Wi-Fi
- nearby relay/store-and-forward through other devices
- wormholes as backup for longer-range message delivery

### Relay Rules

- Intermediate devices may relay data they did not originate
- User-to-user chat may travel through nearby agents when internet is unavailable
- All inbound data must pass through air-gap intake
- All outbound data must pass through air-gap export
- If a device is only relaying, export may pass directly from intake after policy checks

## What May Be Relayed

- spot updates
- event/club/community/list metadata
- place vibes/DNA/pheromones
- locality priors and updates
- chat messages
- compatibility signals
- admin receipts
- kernel summaries
- tuples and other learned agent-safe information

## What Must Never Be Relayed Raw

- direct human private data
- names, numbers, addresses, social handles
- direct linked account identity
- any payload that has not been air-gap filtered for device-to-device movement

## Intermediate Device Storage Rule

- Relay payloads live only long enough to reach the next path
- After successful relay, only tuple-like learning consequences may remain locally
- Intermediate relay payloads are not meant to persist as user-visible retained content

## Must Live On Device

- Birmingham place graph priors and evolving place knowledge
- map data/tiles needed for Birmingham usage
- saved spots/lists/clubs/communities/events
- chats and message history
- kernel state
- learning history and tuples
- AI2AI receipts
- offline SLM/model pack
- locality priors and DNA/vibe baselines

Daily-drop candidates should be remembered for learning and continuity, but do not need to remain a long-lived user-visible archive.

## Isolated Single-Device Contract

If a user has no internet, no nearby peers, and no local relay path, the device must still:

- continue personal learning
- serve recommendations from on-device kernels and routines
- show local map/discovery from what the device knows
- preserve and use saved objects
- support offline AI chat if the SLM is installed
- allow creation
- queue outbound messages and updates for later transport

When connectivity returns, the system should sync:

- agent state consequences
- locality updates
- tuples and learning receipts
- queued creation and messaging
- AI2AI/admin-visible receipts

## Conflict Resolution

### World Change While Offline

- canceled events become canceled for the user on sync
- edited events apply on sync
- place vibe changes become the new truth, but the app should note that the vibe changed and why/how if available
- if the change is older than 1 year, the system should also surface that time context when relevant

### Conflicting Agent Learnings

- conflicting learnings can coexist as parallel knowledge
- personal agents continue doing what is best for their own human
- conflicts should rise upward to locality and above for abstraction or conviction formation
- resolved higher-order convictions may flow back down as learned lenses
