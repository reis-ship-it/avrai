## ADR 0001: Single Integration Boundary via spots_network

Status: Accepted
Date: 2025-08-08

Context
- The app previously mixed direct Supabase usage with an abstraction package. We need a clear seam to swap backends, unify error handling, and simplify tests.

Decision
- Use `packages/spots_network` as the single integration boundary.
- App and features depend only on `AuthBackend`, `DataBackend`, and `RealtimeBackend` interfaces provided by `BackendInterface`.
- Concrete backend (Supabase) is initialized in DI via `BackendFactory.create(BackendConfig.supabase(...))`.

Consequences
- Presentation, domain, and repositories do not import vendor SDKs.
- Initialization is centralized; tests can mock interfaces.
- Easier future backend swaps and component-specific backends if needed.

Implementation Notes
- DI exposes `BackendInterface`, `AuthBackend`, `DataBackend`, `RealtimeBackend`.
- ai2ai realtime service uses `RealtimeBackend`.
- Remote data sources use `DataBackend`/`AuthBackend`.


