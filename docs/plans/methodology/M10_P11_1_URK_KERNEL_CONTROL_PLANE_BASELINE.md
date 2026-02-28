# M10-P11-1 URK Kernel Control Plane Baseline

## Summary

Implements URK kernel control-plane APIs for admin/runtime operations:

1. `listKernels`
2. `getKernelState`
3. `setKernelState` (transition-guarded)
4. `getKernelHealth`
5. `getKernelLineage`

This baseline upgrades the URK admin console from static registry display to live control-plane runtime data with persisted state and lineage.

## Scope

1. Service: `lib/core/services/admin/urk_kernel_control_plane_service.dart`
2. Tests: `test/unit/services/admin/urk_kernel_control_plane_service_test.dart`
3. Controls: `configs/runtime/urk_kernel_control_plane_controls.json`
4. Report generator: `scripts/runtime/generate_urk_kernel_control_plane_report.py`
5. Generated reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.md`
6. Admin console integration:
   - `lib/presentation/pages/admin/urk_kernel_console_page.dart`

## Exit Criteria

1. Kernel state/health/lineage query coverage meets threshold.
2. Unauthorized state changes remain at or below threshold.
3. Invalid transition attempts remain at or below threshold.
4. Admin console renders live control-plane state and allows guarded state transitions.
5. Report checks and unit tests pass in CI.
