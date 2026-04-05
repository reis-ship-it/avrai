# 16 - Document Conversion Matrix (Master Plan + Related Systems)

## 1) Purpose

Provide explicit conversion mapping so all plan/build/tracking docs align to:
- Reality Engine
- AVRAI Runtime OS
- AVRAI Product App

## 2) Conversion Matrix

| Doc Group | Current Role | Required Update | Owner | Output |
|---|---|---|---|---|
| `docs/MASTER_PLAN.md` | canonical execution architecture | add 3-layer architecture section + new task lane + acceptance criteria | Architecture Council | updated plan refs + new subsection IDs |
| `docs/EXECUTION_BOARD.csv` | execution state source | add separation milestones and gates | Program Mgmt | milestone rows with PRD + refs |
| `docs/EXECUTION_BOARD.md` | generated board | regenerate after CSV updates | Program Mgmt | synced board |
| `docs/STATUS_WEEKLY.md` | weekly deltas | add section for layer-boundary conversion progress | PM + Eng Leads | weekly rollout evidence |
| `docs/MASTER_PLAN_TRACKER.md` | registry | add and maintain remap package references | Docs owner | tracker entries |
| `docs/plans/architecture/ARCHITECTURE_INDEX.md` | architecture nav | add runtime-engine-host canonical links | Architecture owner | aligned navigation |
| `docs/plans/architecture/REPO_HYGIENE_AND_ARCHITECTURE_RULES.md` | architecture policy | add reciprocal forbidden import rules and terminology cleanup | Architecture + CI | enforced policy doc |
| `docs/GITHUB_ENFORCEMENT_SETUP.md` | branch/CI guard policy | include new required checks and PR metadata fields | DevEx | enforceable governance |
| `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md` | PRD-board linkage | include layer-impact metadata + compatibility impact fields | PMO | no-traceability drift |
| `docs/security/RED_TEAM_TEST_MATRIX.md` | security release gate | add runtime OS adapter lanes and cross-layer bypass tests | Security | hardened release gates |
| `docs/plans/architecture/CODEBASE_MASTER_PLAN_MAPPING_*.md/csv` | file mapping | register engine/runtime/app architecture spots and path ownership | Arch tooling owner | mapping alignment |
| CI scripts (`scripts/ci/*`) | guard enforcement | add boundary checks and contract conformance checks | DevEx + Architecture | automated failure on drift |

## 3) Conversion Order (Strict)

1. Canonical terminology + architecture policy docs
2. Master plan section and task updates
3. Execution board milestone and gate updates
4. CI/build enforcement updates
5. Tracking/reporting docs
6. Security matrix updates
7. Mapping artifacts regeneration

## 4) Required Artifacts per Conversion PR

1. updated doc(s)
2. linked milestone ID
3. master plan refs
4. evidence links
5. regenerated derived docs if applicable

