# Semantic Memory

**Master Plan Phase:** 1 (Data Foundation) and Phase 3 (State Encoder)

## Purpose

Stores shared knowledge -- structured facts about the world that aren't tied to specific episodes. Entity facts (spot hours, event details), user preferences (explicit likes/dislikes), and relationship data.

## What Belongs Here

- Structured facts storage and retrieval
- Entity knowledge base (spot metadata, community info)
- User explicit preference store
- Fact extraction from conversations and interactions
- Knowledge graph operations

## What Will Migrate Here

- `lib/core/ai/structured_facts.dart` (fact models)
- `lib/core/ai/structured_facts_extractor.dart` (fact extraction)
- `lib/core/ai/facts_index.dart` (fact indexing)
- `lib/core/ai/facts_local_store.dart` (fact persistence)

## Dependencies

- Local storage (`lib/data/datasources/local/`)
- `lib/core/ai/world_model/state_encoder/` (facts feed into state encoding)
