# State Encoder

**Master Plan Phase:** 3 (State Encoder JEPA)

## Purpose

Encodes user state, entity state, and context into dense vector representations using Joint Embedding Predictive Architecture (JEPA). This is the "perception" layer of the world model -- it turns raw signals (behavior, location, time, social context) into a unified state vector that the rest of the world model operates on.

## What Belongs Here

- User state encoder (behavior → embedding)
- Entity state encoder (spot/event/community → embedding)
- Context encoder (time, weather, social signals → embedding)
- JEPA training and inference logic
- State vector models and types

## What Will Migrate Here

- `lib/core/ai/personality_learning.dart` (personality state encoding)
- `lib/core/ai/continuous_learning/engines/personality_learning_engine.dart`
- `lib/core/ai/continuous_learning/engines/behavior_learning_engine.dart`
- `lib/core/ai/continuous_learning/engines/preference_learning_engine.dart`
- Parts of `lib/core/ai/comprehensive_data_collector.dart` (signal collection)

## Dependencies

- `lib/core/ai/memory/episodic/` (reads past outcomes for training)
- ONNX runtime (`lib/core/ml/`) for inference
