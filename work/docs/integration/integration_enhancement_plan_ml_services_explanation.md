# ML Models for Dart Services - What Happened and What It Does

**Plan ID:** `integration_and_enhancement_plan_a81ba5e1`  
**Date:** January 27, 2026

---

## 📋 **What Happened**

### **1. Training Completed** ✅

**Quantum Optimization Model:**
- Trained for 50 epochs on 10,000 unique samples
- Learned to optimize:
  - **Weights:** How much to weight each data source (personality, behavioral, relationship, temporal, contextual)
  - **Threshold:** Optimal compatibility threshold for different use cases
  - **Basis:** Which personality dimensions are most important to measure

**Entanglement Detection Model:**
- Trained for 100 epochs on 10,000 unique samples
- Learned to detect which personality dimensions are "entangled" (correlated) with each other
- Outputs 66 correlation values (one for each pair of the 12 dimensions)

**Result:** Both models are saved as PyTorch files (`.pth`) and ready to use.

---

### **2. ONNX Export Issue** ⚠️

**Problem:** PyTorch 2.10.0 has a bug that prevents exporting these models to ONNX format.

**Solution:** Created a workaround script that uses PyTorch 2.0.0 (which works) to export the models.

**Status:** Models are trained, but ONNX export requires using PyTorch 2.0.0 (documented in guide).

---

### **3. Dart Services Updated** ✅

**Changed:** Updated `QuantumMLOptimizer` to handle the combined model output format.

**Why:** The model outputs all three tasks at once: [weights(5), threshold(1), basis(12)] = 18 values.

**Before:** Services would call the model 3 separate times (inefficient).  
**After:** Services call the model once, cache the result, and parse the combined output.

---

## 🎯 **What the ONNX Export Will Do for Dart Services**

### **Current Behavior (Without ONNX Models)**

**QuantumMLOptimizer:**
- Uses **hardcoded default values**:
  - Weights: Fixed ratios (e.g., 50% personality, 30% behavioral, etc.)
  - Threshold: Fixed values per use case (e.g., 0.6 for matching, 0.5 for recommendation)
  - Basis: Top dimensions by magnitude (simple heuristic)

**QuantumEntanglementMLService:**
- Uses **hardcoded entanglement groups**:
  - Exploration group: exploration_eagerness, location_adventurousness, novelty_seeking
  - Social group: social_discovery_style, community_orientation, trust_network_reliance
  - Temporal group: temporal_flexibility

**Limitation:** These defaults are generic and don't adapt to individual user personalities or contexts.

---

### **Future Behavior (With ONNX Models)**

Once ONNX models are exported and placed in `assets/models/`:

#### **QuantumMLOptimizer - ML-Powered Optimization**

**What Changes:**

1. **Personalized Weights:**
   - **Before:** Everyone gets the same weights (50% personality, 30% behavioral, etc.)
   - **After:** Model analyzes the user's 12 personality dimensions and use case, then predicts optimal weights
   - **Example:** A user with high exploration_eagerness might get higher weights for behavioral data when matching

2. **Context-Aware Thresholds:**
   - **Before:** Fixed threshold of 0.6 for matching, 0.5 for recommendation
   - **After:** Model predicts the optimal threshold based on the user's personality profile
   - **Example:** A user with high authenticity_preference might need a higher threshold (0.7) to ensure genuine matches

3. **Smart Measurement Basis:**
   - **Before:** Always measures top 5 dimensions by magnitude
   - **After:** Model predicts which dimensions are most important for this specific user and use case
   - **Example:** For a user with high social_discovery_style, the model might prioritize measuring community_orientation and trust_network_reliance

**How It Works:**

```dart
// User calls the service
final optimizer = sl<QuantumMLOptimizer>();
await optimizer.initialize(); // Loads ONNX model if available

// Get optimized weights (uses ML if model available, defaults otherwise)
final weights = await optimizer.optimizeSuperpositionWeights(
  state: userQuantumState,
  sources: [personality, behavioral, relationship],
  useCase: QuantumUseCase.matching,
);

// Result: ML-optimized weights like:
// {personality: 0.52, behavioral: 0.31, relationship: 0.12, ...}
// Instead of hardcoded: {personality: 0.5, behavioral: 0.3, ...}
```

**Technical Flow:**
1. Service loads ONNX model from `assets/models/quantum_optimization_model.onnx`
2. User's personality (12 dimensions) + use case → Model input (13 values)
3. Model runs inference → Outputs 18 values: [weights(5), threshold(1), basis(12)]
4. Service caches the output (avoids calling model 3 times)
5. Each method (`optimizeWeights`, `optimizeThreshold`, `predictBasis`) extracts its portion from the cached output
6. If model unavailable → Falls back to defaults (graceful degradation)

---

#### **QuantumEntanglementMLService - ML-Powered Entanglement Detection**

**What Changes:**

1. **Learned Entanglement Patterns:**
   - **Before:** Hardcoded groups (exploration, social, temporal)
   - **After:** Model learns complex entanglement patterns from training data
   - **Example:** Model might discover that `authenticity_preference` and `curation_tendency` are entangled (correlated) even though they're not in the hardcoded groups

2. **Personalized Correlations:**
   - **Before:** Same entanglement groups for everyone
   - **After:** Model predicts correlation strengths for each user based on their personality profile
   - **Example:** A user with high exploration_eagerness might have stronger correlations between exploration dimensions than a user with low exploration_eagerness

**How It Works:**

```dart
// User calls the service
final entanglementService = sl<QuantumEntanglementMLService>();
await entanglementService.initialize(); // Loads ONNX model if available

// Detect entanglement patterns (uses ML if model available, hardcoded otherwise)
final entanglements = await entanglementService.detectEntanglementPatterns(
  profile: userPersonalityProfile,
);

// Result: ML-detected entanglements like:
// {'exploration_eagerness:location_adventurousness': 0.45,
//  'authenticity_preference:curation_tendency': 0.38,
//  ...}
// Instead of hardcoded groups only
```

**Technical Flow:**
1. Service loads ONNX model from `assets/models/entanglement_model.onnx`
2. User's personality (12 dimensions) → Model input (12 values)
3. Model runs inference → Outputs 66 correlation values (one per dimension pair)
4. Service parses correlations into map: `{'dim1:dim2': correlationStrength}`
5. Only correlations above threshold (0.2) are included
6. If model unavailable → Falls back to hardcoded groups (graceful degradation)

---

## 🔄 **Complete Flow Example**

### **Scenario: User Matching**

**Without ML Models (Current):**
```
1. User has personality profile
2. QuantumMLOptimizer uses hardcoded weights: {personality: 0.5, behavioral: 0.3, ...}
3. QuantumEntanglementMLService uses hardcoded groups: {exploration, social, temporal}
4. Matching happens with generic defaults
```

**With ML Models (After ONNX Export):**
```
1. User has personality profile
2. QuantumMLOptimizer loads ONNX model
3. Model analyzes user's 12 dimensions + use case (matching)
4. Model predicts optimal weights: {personality: 0.52, behavioral: 0.31, ...}
5. Model predicts optimal threshold: 0.63 (instead of hardcoded 0.6)
6. Model predicts important dimensions: [exploration_eagerness, social_discovery_style, ...]
7. QuantumEntanglementMLService loads ONNX model
8. Model detects personalized entanglements: {exploration:location: 0.45, ...}
9. Matching happens with ML-optimized, personalized values
```

**Result:** More accurate, personalized matching that adapts to each user's unique personality profile.

---

## 📊 **Performance Impact**

**Before (Hardcoded):**
- Fast (no computation)
- Generic (same for everyone)
- Not adaptive

**After (ML Models):**
- Still fast (ONNX inference is optimized)
- Personalized (adapts to each user)
- Adaptive (learns from training data)
- Graceful fallback (uses defaults if model unavailable)

---

## ✅ **Benefits**

1. **Personalization:** Each user gets optimized values based on their personality
2. **Accuracy:** ML models learn from 10,000 training examples
3. **Adaptability:** Models can be retrained with real user data to improve over time
4. **Graceful Degradation:** Services work with or without models (fallback to defaults)

---

## 🚀 **Next Steps**

1. **Export ONNX Models:**
   - Use PyTorch 2.0.0 (see guide: `docs/integration/integration_enhancement_plan_onnx_export_guide.md`)
   - Place models in `assets/models/`

2. **Models Auto-Load:**
   - Services automatically detect and load ONNX models on first use
   - If models unavailable, services use defaults (no breaking changes)

3. **Test:**
   - Verify models load correctly
   - Test that ML predictions are used
   - Verify fallback behavior

---

**Last Updated:** January 27, 2026
