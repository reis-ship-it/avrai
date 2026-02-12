# Federated Learning

**Master Plan Phase:** 8 (Federated Learning & Group Intelligence)

## Purpose

Infrastructure for federated learning across devices -- model improvements are learned locally and shared as encrypted gradients, never raw data. This enables the world model to improve from collective intelligence while preserving privacy.

## What Belongs Here

- Federated averaging / gradient aggregation
- Differential privacy for gradient sharing
- Model version management and synchronization
- Population prior models (cold-start intelligence)
- Peer model update protocols

## What Will Migrate Here

- `lib/core/p2p/federated_learning.dart` (federated learning logic)
- `lib/core/p2p/node_manager.dart` (node management → AI2AI node management)
- `lib/core/ai/federated_priors_cache.dart` (prior caching)
- `lib/core/ai/cloud_learning.dart` (cloud-based learning coordination)

## Dependencies

- `lib/core/ai2ai/` (communication transport)
- `lib/core/ai/world_model/` (models being federated)
- Privacy infrastructure (`lib/core/services/privacy/`)
