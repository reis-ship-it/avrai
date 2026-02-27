# 21 - Doc-by-Doc Checklist and Acceptance Criteria

## 1) Core Plan Docs

### `docs/MASTER_PLAN.md`
- [ ] 3-layer architecture statement added
- [ ] 10.10 section added
- [ ] task refs added
- [ ] acceptance criteria and gate language added

### `docs/EXECUTION_BOARD.csv`
- [ ] separation milestones added
- [ ] refs and PRD ids populated
- [ ] risk and gates populated

### `docs/EXECUTION_BOARD.md`
- [ ] regenerated and synced

### `docs/STATUS_WEEKLY.md`
- [ ] boundary conversion section added

### `docs/MASTER_PLAN_TRACKER.md`
- [ ] remap package entry added

## 2) Architecture Docs

### `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- [ ] links to separation package included

### `docs/plans/architecture/REPO_HYGIENE_AND_ARCHITECTURE_RULES.md`
- [ ] terminology corrected (`avrai` naming)
- [ ] reciprocal boundary rules added

### `docs/plans/architecture/CODEBASE_MASTER_PLAN_MAPPING_*`
- [ ] architecture spots updated for engine/runtime/app ownership
- [ ] mapping artifacts regenerated

## 3) Governance and Build Docs

### `docs/GITHUB_ENFORCEMENT_SETUP.md`
- [ ] new guard checks listed
- [ ] branch protection updates specified

### `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
- [ ] layer-impact metadata rules added
- [ ] compatibility and rollback fields added

## 4) Security Docs

### `docs/security/RED_TEAM_TEST_MATRIX.md`
- [ ] runtime adapter lanes added
- [ ] cross-layer bypass tests added

## 5) Acceptance Definition

The conversion is accepted when:
1. all checklist items are complete,
2. CI guards are green,
3. evidence links exist for each milestone,
4. no unresolved terminology contradictions remain.

