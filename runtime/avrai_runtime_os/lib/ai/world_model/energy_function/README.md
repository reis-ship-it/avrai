# Energy Function

**Master Plan Phase:** 4 (Energy-Based Quality Scoring)

## Purpose

Learns a scalar energy (quality/compatibility) score from state vectors. Replaces the old hardcoded calling score formula system. Low energy = high compatibility/quality. This is the "evaluation" layer of the world model -- it answers "how good is this state?"

## What Belongs Here

- Energy function model definition and training
- Compatibility scoring between user and entity states
- Contrastive learning from positive/negative outcomes
- Energy calibration and normalization

## What Will Migrate Here

- `lib/core/services/calling_score_calculator.dart` (replaced, not migrated)
- `lib/core/ml/calling_score_neural_model.dart` (replaced, not migrated)
- `lib/core/ml/user_matching.dart` (replaced by learned matching)
- `lib/core/ai/quantum/location_compatibility_calculator.dart` (location scoring logic)

## Dependencies

- `lib/core/ai/world_model/state_encoder/` (consumes state vectors)
- `lib/core/ai/memory/episodic/` (trains from outcome data)
- ONNX runtime for inference
