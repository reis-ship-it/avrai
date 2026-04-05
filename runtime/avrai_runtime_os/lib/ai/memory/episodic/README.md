# Episodic Memory

**Master Plan Phase:** 1 (Data Foundation) and ongoing

## Purpose

Stores concrete outcomes and interaction episodes -- "what happened when the user went to this spot?" This is the ground truth the world model trains on. Every recommendation outcome, every visit, every dismissal is an episode.

## What Belongs Here

- Episode models (visit outcome, recommendation outcome, interaction record)
- Episode storage and retrieval (local SQLite + sync)
- Outcome logging (accepted/dismissed/visited/rated)
- Training data preparation for world model components
- Episode compaction (summarize old episodes to save space)

## What Will Migrate Here

- `lib/core/ai/event_logger.dart` (event/outcome logging)
- `lib/core/ai/interaction_events.dart` (interaction tracking)
- `lib/core/services/calling_score_data_collector.dart` (data collection logic, not scoring)
- `lib/core/services/calling_score_training_data_preparer.dart` (data prep logic)

## Dependencies

- Local storage (`lib/data/datasources/local/`)
- Sync infrastructure (`lib/core/sync/`)
