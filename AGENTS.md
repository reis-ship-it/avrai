# AGENTS.md -- Agent Operating Guide

This file is the entry point for any coding agent working in this repository.
Read this first, then follow the pointers to deeper docs as needed.

## Repository Structure

```
AVRAI/                          # Monorepo root
├── apps/
│   ├── avrai_app/              # Main Flutter app (package: avrai)
│   │   ├── lib/                # App source code
│   │   └── test/               # Unit, integration, widget tests
│   └── admin_app/              # Admin desktop app
├── engine/                     # Core business logic (no app dependencies)
│   ├── avrai_ai/
│   ├── avrai_ml/
│   ├── avrai_knot/
│   ├── avrai_quantum/
│   └── reality_engine/
├── runtime/                    # Networking, data, OS services
│   ├── avrai_data/
│   ├── avrai_network/
│   └── avrai_runtime_os/
├── shared/
│   └── avrai_core/             # Shared models and utilities
├── work/
│   ├── docs/                   # All documentation (plans, rationale, status)
│   ├── scripts/                # CI scripts, automation, tools
│   └── tools/                  # Dart tool scripts
├── scripts -> work/scripts     # Symlink for CI compatibility
├── .cursorrules                # Detailed Cursor agent rules
└── melos.yaml                  # Monorepo workspace config
```

## Key Commands

```bash
melos bootstrap              # Install all dependencies
melos exec --dir-exists=test -c 4 -- flutter test  # Run all package tests
melos analyze                # Run flutter analyze on all packages
melos check:architecture     # Validate package dependency boundaries
melos check:repo_hygiene     # Verify no generated artifacts in git
dart format --set-exit-if-changed .  # Check formatting
```

## Branch Conventions

- `main` -- production branch (protected)
- `develop` -- integration branch
- `agent/<task-description>` -- agent work branches
- `auto-fix/<date>` -- automated fix branches

## Before Opening a PR

1. All tests pass: `melos exec --dir-exists=test -c 4 -- flutter test`
2. Analysis clean: `flutter analyze --fatal-infos`
3. Formatting clean: `dart format --set-exit-if-changed .`
4. Architecture boundaries: `melos check:architecture`
5. No `print()` statements (use `developer.log()`)
6. No direct `Colors.*` (use `AppColors`/`AppTheme`)

## Critical Rules

- Package name is `avrai`, NOT `spots` (legacy name)
- App code lives at `apps/avrai_app/`, not at root
- Architecture is ai2ai only (never p2p)
- Intelligence-first: learned functions > hardcoded formulas
- "Doors, not badges" philosophy (no gamification)

## Deeper Documentation

- **Master Plan:** `work/docs/MASTER_PLAN.md`
- **Philosophy:** `work/docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
- **Rationale:** `work/docs/plans/rationale/FOUNDATIONAL_DECISIONS.md`
- **Status:** `work/docs/agents/status/status_tracker.md`
- **Test Guide:** `work/docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`
- **ML Roadmap:** `work/docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
