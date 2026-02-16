# ML Simulation Experiment Log

Generated Source Digest: `b5f85adfbac0e773`

## Purpose
This file is generated. It summarizes the latest simulation stage status and auto-improvement backlog.

## Latest Stage Status

| Model ID | Stage | Status | Metric | Value | Threshold | Direction | Follow-up | Follow-up Status |
|---|---|---|---|---|---|---|---|---|
| mdl-atomic-temporal-sync-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-atomic-temporal-sync-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-atomic-temporal-sync-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-brand-sponsor-energy-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-brand-sponsor-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-brand-sponsor-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-business-energy-v1 | offline_replay | pass | auc | 0.79 | 0.72 | gte | - | none |
| mdl-business-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-business-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-community-energy-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-community-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-community-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-event-energy-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-event-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-event-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-knot-string-worldsheet-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-knot-string-worldsheet-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-knot-string-worldsheet-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-list-curation-energy-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-list-curation-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-list-curation-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-locality-advisory-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-locality-advisory-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-locality-advisory-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-quantum-entanglement-v1 | offline_replay | pass | auc | 0.76 | 0.72 | gte | - | none |
| mdl-quantum-entanglement-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-quantum-entanglement-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-quantum-optimization-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-quantum-optimization-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-quantum-optimization-v1 | limited_rollout | pending | - | - | - | - | - | - |
| mdl-spot-energy-v1 | offline_replay | pending | pending | - | - | - | - | none |
| mdl-spot-energy-v1 | shadow | pending | - | - | - | - | - | - |
| mdl-spot-energy-v1 | limited_rollout | pending | - | - | - | - | - | - |

## Auto-Improvement Backlog

| Run ID | Model ID | Stage | Failure Metric | Value | Threshold | Suggested Action | Follow-up ID | Follow-up Status |
|---|---|---|---|---|---|---|---|---|
| - | - | - | - | - | - | - | - | - |

## Writing Pattern

Use this exact decision line for each stage:

`<model_id> <stage> <pass_or_fail> <metric>=<value> threshold=<threshold> action=<next_action>`

