## ADR 0002: ai2ai Orchestrator Decomposition and Unified Logging

Status: Accepted
Date: 2025-08-08

Context
- `VibeConnectionOrchestrator` had grown large. Logging was inconsistent across core.

Decision
- Decompose orchestrator into `DiscoveryManager`, `ConnectionManager`, and `RealtimeCoordinator` while keeping API stable.
- Use `AppLogger` across ai2ai and bootstrap for consistent, filterable logs.

Consequences
- Smaller, testable components; clearer responsibilities.
- Uniform logs improve diagnostics and observability.

Implementation Notes
- Components live in `lib/core/ai2ai/orchestrator_components.dart` and are composed in orchestrator.
- Realtime coordination funnels listener setup/teardown.
- `AppLogger` wraps developer.log with levels and tags.


