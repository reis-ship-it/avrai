# M9-P10-2 URK Kernel Registry + Admin Catalog Baseline

## Objective
Establish a single source of truth for kernel definitions and completeness validation, and generate a clean admin-facing catalog from that registry.

## Baseline Artifacts
- Registry: `configs/runtime/kernel_registry.json`
- Registry validator: `scripts/runtime/check_urk_kernel_registry.py`
- Catalog generator/check: `scripts/runtime/generate_urk_kernel_catalog.py`
- Admin catalog: `docs/admin/URK_KERNEL_CATALOG.md`

## Pass Contract
1. Registry schema and enum constraints validate.
2. Every kernel lists required artifact paths and all referenced files exist.
3. Admin catalog generation is deterministic and check-clean.

## CI Wiring
- `Execution Board Guard` runs registry validator and catalog check.
