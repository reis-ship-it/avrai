# 06 - Glossary and Boundary Rules

## Glossary

- Reality Engine
  - Independent cognition and planning system.

- AVRAI Runtime OS
  - Downloadable runtime substrate that coexists with native device OS and provides transport/security/policy/scheduling capabilities to the engine.

- AVRAI Product App
  - User-facing host application for workflows and UX.

- Device OS
  - Native host OS (iOS, Android, macOS, Windows, Linux).

- Capability Profile
  - Runtime-declared set of currently available operational capabilities used by engine planning.

## Boundary Rules

1. Engine must never import product presentation/workflow modules.
2. Engine must never import app composition roots (service locators/bootstrap from app layer).
3. Runtime owns device API interactions and permission-conditioned behavior.
4. Product must call engine through runtime and adapter contracts.
5. All cross-layer contracts must be versioned and compatibility-tested.
6. Observability must include engine/runtime/host version IDs for every adaptive decision.

## What Is Allowed to Be Coupled

Allowed coupling:
- Engine -> Runtime contracts
- Runtime -> Device OS APIs
- Product -> Runtime contracts

Disallowed coupling:
- Engine -> Product implementation
- Product -> Device privileged operations bypassing runtime policy

## Truthful Independence Statement

The Reality Engine is independent from AVRAI product UX and workflows.
It is intentionally dependent on AVRAI Runtime OS contracts when running in AVRAI deployment environments.

