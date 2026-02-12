# ML Reality and Quantum Readiness - Completion Report

**Date:** February 7, 2026  
**Scope:** 15 implementation items across 5 phases  
**Status:** All items complete

---

## Problem Statement

Four gaps existed in the ML and quantum systems:

1. **Spot data was synthetic** -- training used random noise instead of real venue characteristics, and only 4 of 12 vibe dimensions were inferred (the other 8 defaulted to 0.5)
2. **Two ONNX models were missing** -- `quantum_optimization_model.onnx` and `entanglement_model.onnx` didn't exist on disk despite training scripts being ready
3. **Training labels were simplified** -- the Python formula used 3 components (vibe 50%, context 30%, timing 20%) but the real Dart formula uses 5 components (vibe 40%, life betterment 30%, meaningful connection 15%, context 10%, timing 5%)
4. **No quantum cloud interface** -- no abstraction layer existed to swap classical simulation for cloud quantum hardware

---

## What Was Done

### Phase 1: Real Spot Data Collection Pipeline

**Why:** Models trained on synthetic spot data can't learn real patterns. A cafe, a nightclub, and a museum all looked the same to the model because their "vibes" were random noise correlated with the user. Real venues have real characteristics -- a park is free and open-air, a nightclub has late hours and high energy, a chain restaurant is predictable. The model needs to learn from these real signals.

**How:**

#### 1.1 OSM Bulk Spot Extractor
**File:** `scripts/data_collection/extract_osm_spots.py`

Uses the OpenStreetMap Overpass API (free, no key needed) to download venues in bulk. Covers 10 US cities: NYC, LA, Chicago, Miami, Austin, San Francisco, Seattle, Denver, Nashville, Portland. Extracts name, category, cuisine, opening hours, lat/lon, and all relevant OSM tags. Maps OSM tag vocabulary to AVRAI categories (e.g., `amenity=restaurant` becomes `Food`, `tourism=museum` becomes `Attractions`). Includes deduplication by name + approximate location, chain detection via brand tags, and opening hours parsing (24h, late night, early morning). Targets 50K+ unique venues.

Built-in politeness: configurable delay between city queries, retry logic with exponential backoff for rate limiting.

#### 1.2 Google Places Enrichment
**File:** `scripts/data_collection/enrich_with_google_places.py`

Enriches a subset of OSM spots (~5,000) with Google Places data that OSM doesn't have: star rating, price level, and review count. These three signals are high-value for vibe inference -- a 4.8-star restaurant with 2,000 reviews tells you something very different from an unrated spot with 3 reviews.

Matches OSM venues to Google Places via the Find Place API (name + location proximity within 1km). Has checkpoint/resume support so it can be interrupted and resumed without re-fetching already-enriched spots. Cost estimate: ~$85 for 5,000 lookups (one-time).

#### 1.3 Full 12D Spot Vibe Converter
**File:** `scripts/data_collection/spot_vibe_converter.py`

The core conversion logic. Takes raw spot data (from OSM and/or Google) and infers all 12 vibe dimensions from real characteristics. Before this change, only 4 dimensions were inferred (`exploration_eagerness`, `community_orientation`, `authenticity_preference`, `energy_preference`) and the other 8 defaulted to 0.5. Now all 12 are actively inferred:

| Dimension | Inference Source |
|---|---|
| `exploration_eagerness` | Tourism tags, uniqueness, chain detection |
| `community_orientation` | Community center tags, social facility tags, review count |
| `authenticity_preference` | Heritage/craft tags, chain detection (chains score low) |
| `energy_preference` | Category (bar/club = high, library/spa = low), late hours |
| `social_discovery_style` | Capacity signals, outdoor seating, stadium/sports tags |
| `temporal_flexibility` | Opening hours (24h = high, parks = high, appointment = low) |
| `location_adventurousness` | Tourism attraction type, distance from routine, chain detection |
| `curation_tendency` | Price level, boutique/specialty tags, chain detection |
| `trust_network_reliance` | Review count + rating (high reviews = low trust needed) |
| `novelty_seeking` | "New" tags, uniqueness, popup detection, chain detection |
| `value_orientation` | Price level mapping, free venues (parks, libraries) |
| `crowd_tolerance` | Venue size tags, outdoor/indoor, stadium capacity |

Chain detection is a strong signal across multiple dimensions -- chains score low on exploration, authenticity, novelty, curation, and location adventurousness because they're predictable. This matches intuition: nobody "explores" a Starbucks.

---

### Phase 2: Training Pipeline Improvements

**Why:** The Python training script calculated calling scores using a simplified 3-component formula that didn't match the actual Dart production formula. The model was learning to predict the wrong thing. Also, the training data generator had no way to use real spot data.

**How:**

#### 2.1 Full 5-Component Calling Score Formula
**File:** `scripts/ml/generate_hybrid_training_data.py` (modified)

Replaced the simplified formula:
```python
# OLD (3 components)
score = vibe * 0.50 + context * 0.30 + timing * 0.20
```

With the full formula matching `lib/core/services/calling_score_calculator.dart`:
```python
# NEW (5 components, matching Dart)
score = (
    vibe_compatibility * 0.40 +
    life_betterment * 0.30 +
    meaningful_connection_prob * 0.15 +
    context_factor * 0.10 +
    timing_factor * 0.05
)
```

Each sub-component also matches the Dart implementation:
- **Life betterment** is computed as `trajectory_potential * 0.40 + meaningful_conn * 0.30 + positive_influence * 0.20 + fulfillment * 0.10`
- **Context factor** uses the multiplicative logic from Dart (proximity, journey alignment, user receptivity, opportunity availability)
- **Timing factor** uses the multiplicative logic from Dart (time of day, day of week, user patterns, opportunity timing)

#### 2.2 Real Spot Support
**File:** `scripts/ml/generate_hybrid_training_data.py` (modified)

Added `--spot-vibes` CLI argument that accepts the output of `spot_vibe_converter.py`. When real spots are provided, the generator selects spots with varying compatibility levels (40% high, 30% medium, 30% low) rather than always generating synthetic spots correlated with the user. This gives the model a realistic distribution of good and bad matches.

Added 4 new input features: `spot_rating`, `spot_price_level`, `spot_popularity` (log-normalized review count), and `distance_km`. These grow the model's input from 39 to 43 features, giving it more real-world signal.

---

### Phase 3: Model Training

**Why:** Two ONNX models were completely missing from disk (the app was falling back to hardcoded rules for quantum optimization and entanglement detection). The calling score and outcome prediction models were trained on 10K samples with the simplified formula.

**How:**

#### 3.1 Generated Missing Models

Ran the existing training scripts that were already in the codebase but had never been executed:

| Model | Architecture | Parameters | Size | Training |
|---|---|---|---|---|
| `quantum_optimization_model.onnx` | 13 -> 64 -> 32 -> 18 | 3,570 | 16KB | 10K synthetic samples, 100 epochs |
| `entanglement_model.onnx` | 12 -> 64 -> 32 -> 66 | 5,090 | 21KB | 10K synthetic samples, 67 epochs (early stopping) |

These use synthetic data for now, which is acceptable because:
- The quantum optimization model learns heuristic weight/threshold patterns -- the relationship between personality dimensions and optimal quantum parameters is consistent regardless of data source
- The entanglement model learns dimension correlation patterns -- which personality dimensions tend to move together

Both can be retrained with better data later without architecture changes.

#### 3.2 Retrained Core Models

Generated 100K training samples using the full 5-component formula, then retrained:

| Model | Architecture | Parameters | Size | Performance |
|---|---|---|---|---|
| `calling_score_model_v2_hybrid.onnx` | 39 -> 128 -> 64 -> 1 | 13,441 | 55KB | Test loss 0.0264, 51 epochs |
| `outcome_prediction_model_v2_hybrid.onnx` | ~45 -> 128 -> 64 -> 32 -> 1 | 16,257 | 65KB | 74.7% test accuracy, 23 epochs |

10x more training data and the correct label formula.

#### 3.3 Model Registry Updates
**File:** `lib/core/ml/model_version_registry.dart` (modified)

Added `v2.0-hybrid` entries for both calling score and outcome prediction models:
- `dataSource: 'hybrid_big_five_v2'`
- `defaultWeight: 0.3` (3x the v1 weight of 0.1, reflecting higher confidence from correct formula + 10x data)
- `status: ModelStatus.staging` (promoted to production after validation)

The v1 models remain registered and available. The weight system means both can run simultaneously for A/B comparison.

---

### Phase 4: Quantum Cloud Architecture

**Why:** The current quantum math is all classical simulation (inner products, tensor products running on regular CPU). For small groups (2-4 people), this is fine. For N-way group entanglement with N >= 5, the state space grows as 2^N and classical simulation becomes exponentially expensive. Cloud quantum hardware (IBM Quantum, AWS Braket) handles this natively. The codebase needed an abstraction layer so the rest of the code doesn't care which backend is doing the math.

**How:**

#### 4.1 QuantumComputeBackend Interface
**File:** `lib/core/ai/quantum/quantum_compute_backend.dart`

Abstract interface defining 4 core operations:
- `calculateFidelity()` -- compatibility between two quantum states
- `createEntangledState()` -- N-way entanglement (the quantum advantage case)
- `detectEntanglementPatterns()` -- which personality dimensions correlate
- `optimizeSuperpositionWeights()` -- optimal weights for data source combination

Plus `isQuantumHardware`, `backendName`, `initialize()`, `dispose()`.

Also defines `EntangledQuantumState` as the return type for entanglement operations -- carries entity IDs, entanglement strength, pairwise fidelities, and the combined state vector.

#### 4.2 Classical Backend
**File:** `lib/core/ai/quantum/backends/classical_quantum_backend.dart`

Wraps the existing quantum-inspired math. No behavior change from before -- it's the same inner products and tensor products, just behind an interface.

- `calculateFidelity()`: normalized inner product, |<A|B>|^2
- `createEntangledState()`: pairwise fidelities + averaged state vectors (simplified tensor product). Entanglement strength is the geometric mean of pairwise fidelities -- punishes weak links
- `detectEntanglementPatterns()`: delegates to `QuantumEntanglementMLService` ONNX model if available, falls back to hardcoded correlation groups
- `optimizeSuperpositionWeights()`: delegates to `QuantumMLOptimizer` ONNX model if available, falls back to equal weights

#### 4.3 Cloud Backend (Stub)
**File:** `lib/core/ai/quantum/backends/cloud_quantum_backend.dart`

Implements the interface but throws `UnimplementedError` for all operations. The value is in the documentation -- every method has detailed comments explaining:
- Which IBM Quantum / AWS Braket API would be called
- The quantum circuit structure (SWAP test for fidelity, CNOT/CZ for entanglement)
- Qubit requirements (8 qubits for pairwise, N*4 for N-way)
- State encoding method (amplitude encoding)

This means when it's time to implement real quantum, the mapping is already documented. There's no guesswork about what circuit to build.

#### 4.4 Backend Selection
**File:** `lib/core/ai/quantum/quantum_compute_provider.dart`

Simple selection logic: cloud quantum only when ALL three conditions are met:
1. Entity count >= 5 (classical handles small groups fine)
2. Device is online (cloud quantum needs network)
3. `cloud_quantum_compute` feature flag is enabled (safety gate)

Otherwise, classical backend always runs. This means zero behavior change for existing users until the feature flag is explicitly turned on.

#### 4.5 Service Integration
**Files:** `lib/core/services/group_matching_service.dart`, `lib/core/controllers/quantum_matching_controller.dart`, `lib/injection_container_quantum.dart` (all modified)

Added `QuantumComputeProvider` as an optional dependency to both `GroupMatchingService` and `QuantumMatchingController`. The provider is registered in the DI container and passed through.

The existing `QuantumEntanglementService` calls remain unchanged -- the provider is wired in alongside, not replacing. This is a backward-compatible addition that enables future routing without breaking anything today.

---

### Phase 5: Model Loading Diagnostics

**Why:** There was no way to tell at runtime whether an ONNX model actually loaded or if the app silently fell back to rule-based logic. For debugging and monitoring, you need to know which models are active.

**How:**

Added public `isUsingOnnx` and `getDiagnostics()` to all 4 ONNX model services:

| Service | File |
|---|---|
| `CallingScoreNeuralModel` | `lib/core/ml/calling_score_neural_model.dart` |
| `OutcomePredictionModel` | `lib/core/ml/outcome_prediction_model.dart` |
| `QuantumEntanglementMLService` | `lib/core/ai/quantum/quantum_entanglement_ml_service.dart` |
| `QuantumMLOptimizer` | `lib/core/ai/quantum/quantum_ml_optimizer.dart` |

`getDiagnostics()` returns a map with model name, loaded status, ONNX vs fallback status, version, and load time. This can be surfaced in an admin/debug UI to verify production model loading.

---

## File Changes Summary

### New Files (7)

| File | Purpose |
|---|---|
| `scripts/data_collection/extract_osm_spots.py` | OSM bulk venue downloader |
| `scripts/data_collection/enrich_with_google_places.py` | Google Places enrichment |
| `scripts/data_collection/spot_vibe_converter.py` | 12D vibe dimension converter |
| `lib/core/ai/quantum/quantum_compute_backend.dart` | Abstract quantum interface |
| `lib/core/ai/quantum/backends/classical_quantum_backend.dart` | Classical implementation |
| `lib/core/ai/quantum/backends/cloud_quantum_backend.dart` | Cloud quantum stub |
| `lib/core/ai/quantum/quantum_compute_provider.dart` | Backend selector |

### Modified Files (8)

| File | Change |
|---|---|
| `scripts/ml/generate_hybrid_training_data.py` | Full 5-component formula, real spot support, new features |
| `lib/core/models/spot_vibe.dart` | All 12 dimensions actively inferred, chain detection |
| `lib/core/ml/model_version_registry.dart` | v2.0-hybrid entries for calling score + outcome prediction |
| `lib/core/ml/calling_score_neural_model.dart` | Added `getDiagnostics()` |
| `lib/core/ml/outcome_prediction_model.dart` | Added `getDiagnostics()` |
| `lib/core/ai/quantum/quantum_entanglement_ml_service.dart` | Added `isUsingOnnx`, `getDiagnostics()` |
| `lib/core/ai/quantum/quantum_ml_optimizer.dart` | Added `isUsingOnnx`, `getDiagnostics()` |
| `lib/core/services/group_matching_service.dart` | Added `QuantumComputeProvider` dependency |
| `lib/core/controllers/quantum_matching_controller.dart` | Added `QuantumComputeProvider` dependency |
| `lib/injection_container_quantum.dart` | Registered backends + provider in DI |

### Generated Artifacts (4 ONNX models)

| File | Size | Status |
|---|---|---|
| `assets/models/quantum_optimization_model.onnx` | 16KB | New -- was missing |
| `assets/models/entanglement_model.onnx` | 21KB | New -- was missing |
| `assets/models/calling_score_model_v2_hybrid.onnx` | 55KB | New -- trained on 100K samples |
| `assets/models/outcome_prediction_model_v2_hybrid.onnx` | 65KB | New -- 74.7% accuracy |

---

## How to Use the Pipeline

### Collect Real Spot Data
```bash
# 1. Download venues from OpenStreetMap (free, ~5 min per city)
python scripts/data_collection/extract_osm_spots.py --cities nyc la chicago

# 2. Enrich with Google Places (optional, ~$85 for 5K spots)
export GOOGLE_PLACES_API_KEY=your_key
python scripts/data_collection/enrich_with_google_places.py --limit 5000

# 3. Convert to 12D vibe dimensions
python scripts/data_collection/spot_vibe_converter.py
```

### Retrain Models on Real Data
```bash
# Generate training data with real spots
python scripts/ml/generate_hybrid_training_data.py \
  data/raw/big_five_spots.json \
  --spot-vibes data/processed/real_spot_vibes_12d.json \
  --output data/calling_score_training_data_v2_real.json \
  --num-samples 100000

# Train v2-real models
python scripts/ml/train_calling_score_model.py \
  --data-path data/calling_score_training_data_v2_real.json \
  --output-path assets/models/calling_score_model_v2_real.onnx

python scripts/ml/train_outcome_prediction_model.py \
  --data-path data/calling_score_training_data_v2_real.json \
  --output-path assets/models/outcome_prediction_model_v2_real.onnx
```

### Verify Model Loading
All 4 ONNX services expose `isUsingOnnx` and `getDiagnostics()`. At runtime:
```dart
final diagnostics = callingScoreModel.getDiagnostics();
// { model: 'calling_score', isUsingOnnx: true, modelVersion: 'v2.0-hybrid', ... }
```

---

## What's Next

1. **Run the data pipeline** -- Execute `extract_osm_spots.py` to collect real venue data, then retrain models on real spots for v2-real weights
2. **Promote v2 models** -- After validation, increase `defaultWeight` from 0.3 to 0.7+ in the model version registry
3. **Cloud quantum validation** -- When ready, connect `CloudQuantumBackend` to IBM Quantum or AWS Braket and run validation experiments behind the `cloud_quantum_compute` feature flag
4. **A/B testing** -- Use the existing A/B testing infrastructure to compare v1 vs v2 model performance on real users
