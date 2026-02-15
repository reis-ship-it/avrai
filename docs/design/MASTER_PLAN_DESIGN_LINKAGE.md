# Master Plan Design Linkage

Status: Canonical mapping of design docs to Master Plan phases and architecture backlog IDs.
Last updated: February 15, 2026

## 1. Purpose
This document ensures every design artifact maps to:
- specific `docs/MASTER_PLAN.md` phase/section references, and
- concrete architecture execution backlog IDs (`MPA-Px-Ex-Sx`).

## 2. Required Linkage Rule
Every new UI/UX spec must include:
1. Master Plan phase/section links.
2. Architecture backlog epic/story links.
3. Gap note if no explicit story exists yet.

## 3. Design Artifact Mapping

| Design Artifact | Master Plan References | Architecture Backlog References | Notes |
|---|---|---|---|
| `docs/design/apps/consumer_app/KNOT_JOURNEY_DESIGN_SPEC.md` | 1.5A, 1.5B, 6.4.5, 7.1.2, 10.4.5, 10.4.7, 10.4.8 | MPA-P6-E2-S2, MPA-P7-E1-S2, MPA-P10-E2-S4, MPA-P10-E3, MPA-P10-E5-S6 | Tracked architecture story: `MPA-P10-E2-S4` |
| `docs/design/apps/consumer_app/WORLD_PLANES_DESIGN_SPEC.md` | 4.5B, 6.4.5, 7.1.2, 10.1, 10.6 | MPA-P4-E3-S1, MPA-P6-E2-S2, MPA-P7-E1-S2, MPA-P10-E2-S5, MPA-P10-E5-S6 | Tracked architecture story: `MPA-P10-E2-S5` |
| `docs/design/apps/consumer_app/FEATURE_DESIGN_PACK.md` | 1, 4.5B, 6.4.5, 7.1.2, 10.x | MPA-P6-E2, MPA-P7-E1, MPA-P10-E2, MPA-P10-E3, MPA-P10-E5 | Cross-journey convergence pack |
| `docs/design/apps/business_app/FEATURE_DESIGN_PACK.md` | 9.4A-9.4H, 9.5, 10.3, 10.4E | MPA-P9-E1, MPA-P9-E2, MPA-P10-E3, MPA-P10-E5-S6 | Business workflow design contract |
| `docs/design/apps/admin_desktop_app/FEATURE_DESIGN_PACK.md` | 12.1, 12.2, 12.4A-12.4F, 10.3 | MPA-P12-E1, MPA-P12-E2, MPA-P12-E3, MPA-P10-E3 | Admin/operator control surfaces |
| `docs/design/apps/research_portal/FEATURE_DESIGN_PACK.md` | 14.1-14.7, 12.4C-F, 10.3 | MPA-P14-E1, MPA-P14-E2, MPA-P14-E3, MPA-P10-E3 | Research-facing design contract |
| `docs/design/apps/partner_sdk_examples/FEATURE_DESIGN_PACK.md` | 12.3, 13.1, 11.1 | MPA-P11-E1, MPA-P12-E1, MPA-P13-E1, MPA-P10-E5-S6 | Third-party UX contract |
| `docs/design/DESIGN_REF.md` (Access Governance Contracts) | 2.6, 12.1.5, 14.6, 15.8 | MPA-P10-E5-S6 | Cross-app access-plane contract: P3 never user-facing, role/tier/purpose gating for non-user planes |
| `docs/design/DESIGN_REF.md` (Reality Coherence UX Contracts) | 2.8, 10.11, 1-15 phase gates | MPA-P2-E4-S3, MPA-P10-E5-S1, MPA-P10-E5-S6 | Requires degraded/recovery state coverage aligned to `RCM-UX-019` and `RCM-UX-020` in `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` |

## 4. Explicit Architecture Stories (Tracking Status)
1. Knot journey state-machine + telemetry contract (`MPA-P10-E2-S4`).
2. World planes ambient/immersive/fallback contract (`MPA-P10-E2-S5`).
3. Access-governance UX state contract (`MPA-P10-E2-S6`): purpose-bound access states, denial states, and audit context components for admin/research/partner surfaces.

## 5. Implementation Workflow
1. Author design spec in `docs/design/apps/<app>/...`.
2. Add mapping row in this file.
3. Link spec from app README and `docs/design/DESIGN_REF.md`.
4. Record progression in `docs/agents/status/status_tracker.md` when implementation starts/completes.
