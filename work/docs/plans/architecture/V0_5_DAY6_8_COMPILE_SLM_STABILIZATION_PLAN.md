# v0.5 Day 6-8 Compile + SLM Stabilization Plan

## Goal

Run an independent hardening lane that removes remaining compile and analyzer blockers related to SLM integration, runtime-layer boundaries, and launch-path reliability, without changing v0.5 feature scope.

## Why This Exists

The primary v0.5 beta readiness stream is already in physical validation and trust-surface work. A parallel stabilization lane prevents low-level compile/lint regressions from delaying release gates while preserving the current execution cadence.

## Scope

- Fix launch-blocking compile errors in SLM-adjacent services.
- Close runtime architecture boundary violations that break package discipline.
- Resolve analyzer debt in files touched by the SLM integration and nearby critical chat/onboarding flows.
- Produce explicit acceptance evidence for go/no-go readiness.

## Out of Scope

- New feature development.
- New transport protocol capabilities.
- Large refactors unrelated to current analyzer failures.
- Model-quality tuning beyond basic deterministic fallback behavior.

## Independent Workstream

### Section 0.5.6.8.1 - Compile Blocker Closure

1. Fix Spotify ingestion API mismatch in `runtime/avrai_runtime_os/lib/services/social_media/spotify_ecosystem_integration_service.dart`:
   - Align `audioFeatures` retrieval with the actual SDK contract.
   - Ensure feature aggregation path handles null/empty feature entries safely.
2. Verify onboarding SLM synthesis path compiles and uses current `LLMService` API:
   - `runtime/avrai_runtime_os/lib/services/onboarding/initial_dna_synthesis_service.dart`
   - `runtime/avrai_runtime_os/lib/services/user/aspirational_intent_parser.dart`
   - `runtime/avrai_runtime_os/lib/services/user/personality_agent_chat_service.dart`

### Section 0.5.6.8.2 - Runtime Boundary Cleanup

1. Remove app-layer dependency usage from runtime services (for example launcher dependencies in runtime code).
2. Replace with runtime-safe contract pattern:
   - runtime returns intent/URI/data
   - app/presentation layer performs platform UI actions

### Section 0.5.6.8.3 - Analyzer Debt Burn-Down (Targeted)

1. Clear deprecation/style issues in touched launch-path files (chat, onboarding, runtime services, key tests).
2. Remove duplicate/unused imports in touched files.
3. Modernize deprecated test channel mocks in unit tests where flagged.

### Section 0.5.6.8.4 - Safety and Regression Checks

1. Re-run repository analyzer and confirm zero issues.
2. Validate SLM fallback behavior:
   - malformed output -> safe fallback path
   - empty output -> safe fallback path
3. Validate no behavior regression in:
   - onboarding initialization
   - personality chat path
   - nightly digestion prompt chain execution

### Section 0.5.6.8.5 - Evidence + Exit Criteria

This lane is complete only when all conditions are true:

- `flutter analyze --no-pub` reports zero issues at repo root.
- SLM-adjacent compile path is clean (onboarding DNA synthesis, aspirational parsing, chat integration).
- Runtime layering check passes for touched files (no app-only package dependency violations).
- A short evidence report is published in release artifacts documenting:
  - exact fixes
  - final analyzer output summary
  - residual risks (if any)

## Deliverables

- Updated source files in touched scope with compile/analyzer closure.
- Zero-issue analyzer snapshot for v0.5 readiness.
- Release note addendum entry recording stabilization completion.

## Rollback Strategy

- Keep each fix cluster isolated by file group (SLM path, Spotify path, test modernization).
- If regressions occur, revert only the affected cluster and preserve completed clusters.
- Do not block the main v0.5 stream unless a compile blocker reappears in release paths.

