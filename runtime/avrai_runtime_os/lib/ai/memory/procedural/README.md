# Procedural Memory

**Master Plan Phase:** 6+ (Advanced World Model)

## Purpose

Stores learned skills and patterns -- "how to" knowledge that the AI has acquired through experience. Reusable action templates, learned heuristics, and behavioral patterns that can be applied across contexts.

## What Belongs Here

- Learned action templates (e.g., "how to plan a weekend trip")
- Pattern libraries (e.g., "user prefers X before Y")
- Skill models that the MPC planner can invoke
- Meta-learning outputs (learning strategies that worked)

## What Will Migrate Here

- Parts of `lib/core/ai/continuous_learning/` (learned patterns)
- `lib/core/ai/ai_self_improvement_system.dart` (improvement patterns)

## Dependencies

- `lib/core/ai/world_model/mpc_planner/` (planner uses procedural skills)
- `lib/core/ai/memory/episodic/` (skills extracted from episodes)
