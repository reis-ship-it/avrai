# M31-P12-1 Baseline: Air Gap Compression Contract + Safe Representation Packet Baseline

Date: 2026-03-31
Milestone: M31-P12-1
Master Plan refs: 12.4A.1, 12.4A.2, 12.4A.3, 12.4A.4, 12.4A.6, 12.4A.7

## Scope

Land the first bounded Phase 12.4A implementation slice in shared code: the Air Gap compression contract, safe artifact envelope, bounded compression kernel, and compressed knowledge packet codec.

## Deliverables

1. Baseline doc:
   - `docs/plans/methodology/M31_P12_1_AIR_GAP_COMPRESSION_SAFE_REPRESENTATION_BASELINE.md`
2. Controls:
   - `apps/avrai_app/configs/runtime/air_gap_compression_safe_representation_controls.json`
3. Shared implementation:
   - `shared/avrai_core/lib/contracts/air_gap_compression_contract.dart`
   - `shared/avrai_core/lib/models/air_gap/air_gap_compression_models.dart`
   - `shared/avrai_core/lib/services/air_gap_compression_kernel.dart`
   - `shared/avrai_core/lib/avra_core.dart`
4. Verification:
   - `shared/avrai_core/test/services/air_gap_compression_kernel_test.dart`

## Explicit Objectives

1. define a legal input contract that accepts only already-scrubbed semantic tuples, safe embeddings, truth evidence envelopes, and policy-approved higher-layer artifacts
2. wrap compressed artifacts in a safe envelope that carries artifact type, compression mode, provenance refs, distortion budget posture, and gas/liquid/solid resolution budget
3. provide a bounded kernel that fails closed on raw payload markers and rejects distortion beyond configured budget
4. provide a packet codec so personal/locality/world/universal layers can exchange compressed safe artifacts by default rather than verbose raw-detail bundles

## Guardrails

1. raw payload markers are forbidden inputs and must fail closed
2. compression may not bypass privacy ladder tags, provenance refs, or policy approval for higher-layer artifacts
3. the slice is shared-contract/kernel work only; it does not reopen runtime control-plane authority or admin ownership
4. invariant coverage must prove non-reconstructability at the legal artifact boundary rather than by documentation alone

## Exit Criteria

1. Air Gap compression contract exists in shared code with bounded legal artifact types
2. safe artifact envelope and compression budget profile exist with detail-budget and provenance semantics
3. bounded compression kernel and compressed knowledge packet codec are implemented and exported
4. targeted shared-package analysis and invariant tests pass
