# MPC Planner

**Master Plan Phase:** 6 (Model-Predictive Control)

## Purpose

Plans sequences of "doors" (recommendations/actions) by simulating future states using the transition predictor and evaluating them with the energy function. This is the "planning" layer of the world model -- it answers "what sequence of doors should I suggest?"

## What Belongs Here

- MPC planning loop (simulate → evaluate → select)
- Action sequence optimization
- Thompson sampling for active uncertainty reduction
- Exploration vs. exploitation balancing
- Door sequence ranking and filtering

## What Will Migrate Here

- `lib/core/ml/real_time_recommendations.dart` (replaced by MPC planning)
- `lib/core/advanced/advanced_recommendation_engine.dart` (replaced)
- Parts of `lib/core/ai/perpetual_list/` (list generation → becomes MPC output)
- `lib/core/ai/decision_coordinator.dart` (decision logic)

## Dependencies

- `lib/core/ai/world_model/state_encoder/` (encodes current state)
- `lib/core/ai/world_model/energy_function/` (evaluates planned states)
- `lib/core/ai/world_model/transition_predictor/` (simulates state changes)
- `lib/core/ai/agent/triggers/` (triggers agent actions from plans)
