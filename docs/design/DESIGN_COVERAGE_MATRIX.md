# Design Coverage Matrix

Last updated: February 14, 2026
Source of truth: `docs/design/DESIGN_REF.md`

Legend:
- `Complete`: Defined with implementation contract and usable references.
- `Partial`: Exists in code/docs but missing full design contract details.
- `Missing`: Not sufficiently specified for build-ready execution.

| Domain | Status | Primary References | Gaps |
|---|---|---|---|
| Page structure (all app scopes) | Complete | `lib/presentation/pages/README.md`, `docs/design/apps/*/README.md` | Need per-feature page specs as work is scoped |
| Portal visual language | Complete | `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`, `lib/presentation/widgets/portal/*` | Ongoing visual QA by surface |
| Tokens (spacing/type/radius/motion) | Complete | `lib/core/theme/tokens/theme_tokens.dart`, `tool/design_guardrails.dart` | Continue enforcing for new code |
| Typography | Complete | `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`, brand book, tokenized presentation layer | None blocking |
| Color/style | Complete | `lib/core/theme/colors.dart`, brand book, portal primitives | None blocking |
| Navigation/transition behavior | Complete | `lib/core/navigation/app_page_transitions.dart`, `lib/core/navigation/app_navigator.dart` | Continue migration from legacy calls where found |
| Knot UI journey | Complete | `docs/design/apps/consumer_app/KNOT_JOURNEY_DESIGN_SPEC.md`, `lib/presentation/widgets/onboarding/knot_birth_experience_widget.dart`, onboarding pages, `docs/MASTER_PLAN.md` | Keep telemetry and flow guards synced with implementation |
| World planes UI journey | Complete | `docs/design/apps/consumer_app/WORLD_PLANES_DESIGN_SPEC.md`, `lib/presentation/pages/world_planes/world_planes_page.dart`, `lib/presentation/widgets/knot/worldsheet_4d_widget.dart`, `docs/MASTER_PLAN.md` | Keep ambient/immersive parity under active QA |
| Accessibility (semantic labels, reduced motion, dynamic text policy) | Complete | `docs/design/ACCESSIBILITY_DESIGN_CONTRACT.md`, `docs/MASTER_PLAN.md` accessibility tasks | Keep page-level audits current |
| Sonic/sound design | Complete | `docs/design/SENSORY_FEEDBACK_GUIDELINES.md`, knot audio services/widgets in code | Continue expanding sound token inventory |
| Haptics design | Complete | `docs/design/SENSORY_FEEDBACK_GUIDELINES.md`, `lib/core/services/device/haptics_service.dart` | Keep event-to-pattern mapping current |
| App-level design packs (consumer/business/admin/research/partner) | Complete | `docs/design/apps/*/FEATURE_DESIGN_PACK.md`, `docs/design/apps/*/README.md` | Add per-feature deep specs as scope grows |

## Build Readiness Summary
- Foundation is strong and centralized.
- Build readiness is `High` for core visual system and page architecture.
- Build readiness is `High` for knot/world-plane experiential detail and sensory policy at design-doc level.
- Remaining risk is implementation parity and ongoing QA, not missing design references.

## Required Next Work for Sustained 100% Design-Prep Coverage
1. Keep `docs/design/MASTER_PLAN_DESIGN_LINKAGE.md` synced when new phase-scoped design specs are added.
2. Add additional per-feature specs under `docs/design/apps/*` as new surfaces ship.
3. Validate implementation parity with guardrails and visual QA on each release cycle.
