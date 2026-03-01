# SPOTS Session Report — ONNX Runtime Integration

Date/Time: 2025-08-08 12:18:49 CDT

## Summary
- Implemented a universal ONNX Runtime backend for on-device inference with cross-platform orchestration.
- Added two orchestration strategies (device-first and edge-prefetch) with config-driven switching.
- Bootstrapped model loading from assets with optional remote download fallback.
- Added a UI smoke test button to validate ONNX inference flow.

## Changes Made
1. Inference Abstraction
   - Added `lib/core/ml/inference_backend.dart` defining `InferenceBackend`, `ModelMetadata`, and types.
   - Added `lib/core/ml/inference_orchestrator.dart` with `OrchestrationStrategy` and `InferenceOrchestrator` (device-first and edge-prefetch supported).

2. ONNX Runtime Backend (Real)
   - Implemented `lib/core/ml/onnx_backend_stub.dart` using `package:onnxruntime`:
     - Loads model from assets or bytes.
     - Creates `OrtSession`, maps Dart inputs to `OrtValueTensor`, returns outputs.
     - Proper resource release for native objects.
   - Added dependency: `onnxruntime: ^1.4.1` in `pubspec.yaml`.
   - Registered assets directory: `assets/models/`.

3. Configuration
   - Extended `lib/core/services/config_service.dart` with:
     - `inferenceBackend`, `orchestrationStrategy` (defaults: onnx, device_first)
     - Model config: `modelAssetPath`, `modelInputName`, `modelOutputName`, `modelInputShape`, `modelDownloadUrl`.

4. Dependency Injection
   - Updated `lib/injection_container.dart`:
     - Registers `InferenceBackend` (ONNX) and `InferenceOrchestrator` based on config.
     - Adds bootstrap to initialize model from asset or optional URL via `ModelBootstrapper`.

5. Bootstrapper
   - Added `lib/core/services/model_bootstrapper.dart` to load a model from assets or download by URL.

6. UI Smoke Test
   - Updated `lib/presentation/pages/supabase_test_page.dart`:
     - Adds “Run ONNX Smoke Test” button to execute a simple inference and show a SnackBar with timing or error.

## How It Works
- On app start, DI constructs the ONNX backend and orchestration (device-first by default).
- `ModelBootstrapper` attempts to load `assets/models/default.onnx` (configurable). If missing and a `modelDownloadUrl` is set, it downloads and initializes from bytes.
- Inference calls go through `InferenceOrchestrator.run(inputs)`; if device inference fails and a cloud fallback is provided, it’s used.

## What You Need To Provide
- Place a valid ONNX model at `assets/models/default.onnx` (or set `modelAssetPath` in `ConfigService`).
- If your model uses specific tensor names/shapes, set:
  - `modelInputName`, `modelOutputName`, `modelInputShape` in `ConfigService` and pass `ModelMetadata` when initializing if strict shapes are desired.
- Optionally: set `modelDownloadUrl` to fetch the model at startup.

## Follow-ups (Optional)
- Configure execution providers per platform (NNAPI/Core ML/CPU) if exposed by the plugin for extra perf.
- Add a real cloud fallback (Supabase Edge/Cloud Run) and switch the TODO stub in DI.
- Add background prefetch data sources for the edge-prefetch strategy.

## Files Touched
- `lib/core/ml/inference_backend.dart` (add)
- `lib/core/ml/inference_orchestrator.dart` (add)
- `lib/core/ml/onnx_backend_stub.dart` (replace with real ONNX runtime)
- `lib/core/services/config_service.dart` (extend)
- `lib/core/services/model_bootstrapper.dart` (add)
- `lib/injection_container.dart` (wire backend, orchestrator, bootstrap)
- `lib/presentation/pages/supabase_test_page.dart` (UI smoke test)
- `pubspec.yaml` (add onnxruntime dep, assets/models)
- `assets/models/default.onnx` (placeholder created; replace with a real model)

## Current Status
- Build is clean; no linter errors in modified files.
- On-device inference path is live and guarded; app runs even without a real model.
- UI smoke test available to validate inference once a real model is present.


