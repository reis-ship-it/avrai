# AI2AI Temporal State Backend Note

Date: 2026-02-28

## Current state
- Admin AI2AI mesh/globe temporal state is computed in the admin client every 1s using `AtomicClockService`.
- Globe lockstep health compares client mesh state to client globe render acknowledgements.
- This state is runtime-only and resets on page/app reload.

## Requested future state
- Move temporal state tracking to an internal backend server (source of truth).
- Admin app should subscribe to backend temporal-state stream instead of deriving all state locally.

## Backend not set up yet
- Internal backend service for this feature is not provisioned yet.

## Implementation note for later
1. Create backend temporal-state stream endpoint/topic for AI2AI mesh.
2. Persist temporal snapshots + lockstep drift events for audit/history.
3. Keep privacy constraints: only agent identity/signatures, no personal user data.
4. Update admin dashboard to read backend state and show connection health to backend source.
