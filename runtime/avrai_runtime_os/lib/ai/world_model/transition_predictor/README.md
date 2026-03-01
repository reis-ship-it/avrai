# Transition Predictor

**Master Plan Phase:** 5 (State Transition Prediction)

## Purpose

Predicts how the world state changes over time and in response to actions. Given a current state and a proposed action, it predicts the next state. This is the "imagination" layer of the world model -- it answers "what happens if I do X?"

## What Belongs Here

- Transition model definition and training
- Action-conditioned state prediction
- Temporal pattern learning (seasonal, time-of-day)
- Uncertainty estimation (knows what it doesn't know)
- Taste drift detection

## What Will Migrate Here

- `lib/core/ml/predictive_analytics.dart` (replaced by learned prediction)
- `lib/core/ml/preference_learning.dart` (preference change prediction)
- `lib/core/ai/continuous_learning/engines/interaction_learning_engine.dart`
- `lib/core/ai/continuous_learning/engines/location_intelligence_engine.dart`

## Dependencies

- `lib/core/ai/world_model/state_encoder/` (encodes current state)
- `lib/core/ai/world_model/energy_function/` (evaluates predicted states)
- `lib/core/ai/memory/episodic/` (trains from state transition history)
