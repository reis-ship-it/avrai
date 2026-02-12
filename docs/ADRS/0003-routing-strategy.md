## ADR 0003: Routing Strategy

Status: Proposed
Date: 2025-08-08

Context
- Current routing uses manual `onGenerateRoute` switch-case. As deep linking and guarded routes grow, maintenance becomes harder.

Decision (Proposed)
- Adopt `go_router` for:
  - Declarative route definitions
  - Typed navigation and query parameters
  - Built-in guards (auth, onboarding)
  - Better deep linking and web support

Consequences
- Less boilerplate, clearer route config, easier testing.
- Small refactor to move from `Navigator.pushNamed` to `context.go()` / `context.push()`.

Implementation Plan (High-level)
- Add `go_router` dependency and create `AppRouter` with routes and guards.
- Replace `onGenerateRoute` usage and update navigation calls incrementally.


