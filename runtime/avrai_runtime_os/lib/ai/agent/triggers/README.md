# Agent Triggers

**Master Plan Phase:** 6 (MPC Planner) and Phase 7 (Agent Architecture)

## Purpose

Determines when the AI agent should proactively act -- surface a recommendation, send a notification, or initiate a conversation. Trigger conditions are based on MPC planner output, context changes, and uncertainty thresholds.

## What Belongs Here

- Trigger condition models and evaluation
- Context change detection (location change, time-based, social)
- Notification priority and timing logic
- Proactive vs. reactive decision logic
- User attention/availability estimation

## What Will Migrate Here

- `lib/core/ai/perpetual_list/engines/trigger_engine.dart`
- Parts of `lib/core/ai/scope_classifier.dart` (context classification)
- Parts of `lib/core/ai/bypass_intent_detector.dart` (intent detection)

## Dependencies

- `lib/core/ai/world_model/mpc_planner/` (triggers based on plan quality)
- `lib/core/ai/world_model/transition_predictor/` (uncertainty drives triggers)
