# AVRAI ML System: Deep Analysis and Improvement Roadmap

**Date:** February 8, 2026 (updated February 9, 2026 with LeCun World Model Framework analysis and concrete World Model creation blueprint)
**Scope:** Complete inventory of all ML models, quantum/knot systems, federated learning, privacy infrastructure, gaps, improvement paths, alignment with LeCun's World Model architecture, and full blueprint for building the on-device World Model agent

---

## Table of Contents

1. [Model Inventory](#1-model-inventory)
2. [How Each Model Works](#2-how-each-model-works)
3. [Current Testing and Validation](#3-current-testing-and-validation)
4. [Industry Comparison](#4-industry-comparison)
5. [LeCun's World Model Framework & AVRAI Alignment](#5-lecuns-world-model-framework--avrai-alignment)
6. [Spot / Community / Event Models for Users](#6-spot--community--event-models-for-users)
7. [Improving Models Now (With Quantum, String Theory, and World Models in Mind)](#7-improving-models-now)
8. [Improving Model Testing With Synthetic Data](#8-improving-model-testing)
9. [Competitive Models Using Real Data + Privacy](#9-competitive-models-with-privacy)
10. [Cross-Domain Learning as Hierarchical World Model](#10-cross-domain-learning-as-hierarchical-world-model)
11. [Gaps You're Not Seeing](#11-gaps)
12. [Privacy Infrastructure Audit](#12-privacy-infrastructure)
13. [Federated Learning Infrastructure](#13-federated-learning)
14. [Quantum and Knot Theory Systems](#14-quantum-and-knot-theory)
15. [Building the World Model: Complete Blueprint](#15-building-the-world-model)
16. [On-Device AI Agent Architecture](#16-on-device-ai-agent-architecture)
17. [Priority Roadmap](#17-priority-roadmap)

---

## 1. Model Inventory

### 1.1 Production ONNX Models (4 models, on-device)

| Model | Architecture | Params | Size | Input | Output | Training Data |
|---|---|---|---|---|---|---|
| Calling Score | 39->128->64->1 | 13,441 | ~10KB | User 12D + Spot 12D + Context 10D + Timing 5D | Score 0.0-1.0 | 100K hybrid (Big Five + synthetic) |
| Outcome Prediction | 45->128->64->32->1 | 16,257 | ~13KB | Same 39D + History 6D | Probability 0.0-1.0 | 100K hybrid |
| Quantum Optimization | 13->64->32->3 heads (5+1+12) | ~3,500 | ~17KB | Personality 12D + Use Case 1D | Weights + Threshold + Basis | 10K synthetic heuristic |
| Entanglement Detection | 12->64->32->66 | 5,090 | ~9KB | Personality 12D | 66 pairwise correlations | 10K synthetic heuristic |

### 1.2 Rule-Based ML Services (operational but no neural network)

| Service | What It Does | Status |
|---|---|---|
| SpotVibe | Infers 12D vibe from spot category, tags, description, rating | Fully functional, keyword heuristics |
| OnnxDimensionScorer | Scores 12D personality from onboarding data | Rule-based + federated bias overlay. ONNX model placeholder (TODO) |
| InferenceOrchestrator | Coordinates device-first scoring + optional LLM expansion | Functional, uses OnnxDimensionScorer |
| EventRecommendationService | Recommends events to users | Functional, weighted formula + optional knot compatibility |
| EventMatchingService | Scores expert-user event match | Functional, weighted signals |
| CommunityService | Recommends communities, calculates compatibility | Functional, quantum fidelity + knot topology |
| VibeCompatibilityService | Canonical compatibility scoring (quantum + knot + weave) | Fully functional |

### 1.3 Stub/Placeholder ML Services (not functional)

| Service | Status |
|---|---|
| PatternRecognitionSystem | Returns hardcoded values. Not connected to any flow. |
| PredictiveAnalytics | Returns hardcoded values. Not connected to any flow. |
| PreferenceLearningEngine | Returns hardcoded values. Not connected to any flow. |
| SocialContextAnalyzer | Returns hardcoded values (e.g., optimal group size = 4). Not connected. |
| FeedbackProcessor | Structure exists but `_savePreferences`, `_applyModelUpdates` are stubs. Not connected to learning pipeline. |

### 1.4 Model Versions

**Calling Score:**

| Version | Test Loss | Samples | Formula | Status |
|---|---|---|---|---|
| v1.0-hybrid | 0.0267 | 10K | Simplified 3-component | Staging (active default) |
| v1.1-hybrid | 0.0257 | 10K | Simplified 3-component, batch=128 | Staging |
| v2.0-hybrid | 0.0271 | 100K | Full 5-component | Staging |

**Outcome Prediction:**

| Version | Test Accuracy | Samples | Status |
|---|---|---|---|
| v1.0-hybrid | 88.07% | 10K | Staging (active default) |
| v2.0-hybrid | 75.16% | 100K | Staging |

Note: v2 accuracy dropped because the full 5-component labels are harder to predict than the simplified formula. The model learns a more nuanced task but hasn't caught up yet. More training data and potentially a larger architecture would help.

---

## 2. How Each Model Works

### 2.1 Calling Score Model

This is your spot recommendation engine. Given a user and a spot, it predicts "should this user be called to this spot right now?"

**Input features (39 total):**

| Index | Feature | Source |
|---|---|---|
| 0-11 | User personality dimensions (12D) | PersonalityLearning profile |
| 12-23 | Spot vibe dimensions (12D) | SpotVibe inference from spot metadata |
| 24 | Location proximity | CallingContext |
| 25 | Journey alignment | CallingContext |
| 26 | User receptivity | CallingContext |
| 27 | Opportunity availability | CallingContext |
| 28 | Network effects | CallingContext |
| 29 | Community patterns | CallingContext |
| 30 | Vibe compatibility (cosine similarity of user + spot) | Computed from features 0-23 |
| 31 | Energy match (1 - abs(user - spot)) | Computed from energy_preference |
| 32 | Community match | Computed from community_orientation |
| 33 | Novelty match | Computed from novelty_seeking |
| 34 | Optimal time of day | TimingFactors |
| 35 | Optimal day of week | TimingFactors |
| 36 | User patterns | TimingFactors |
| 37 | Opportunity timing | TimingFactors |
| 38 | Timing alignment (average of timing signals) | Computed from features 34-37 |

**Training label:** The full 5-component calling score formula:

```
score = 0.40 * vibe_compatibility
      + 0.30 * life_betterment
      + 0.15 * meaningful_connection_probability
      + 0.10 * context_factor
      + 0.05 * timing_factor
```

Each sub-component is itself a weighted formula matching the Dart production code in `calling_score_calculator.dart`.

**In the app:** `CallingScoreCalculator` runs the formula as primary. Optionally blends in the ONNX neural prediction at 30% weight (behind A/B test flag): `finalScore = 0.70 * formulaScore + 0.30 * neuralScore`. If ONNX isn't loaded, formula-only runs. The calling threshold is 0.70 -- above that, the user gets recommended the spot.

### 2.2 Outcome Prediction Model

This gates whether to even show a recommendation. If the predicted outcome is likely negative, don't recommend.

**Input features (45 total):**

Same 39 features as calling score, plus:

| Index | Feature | Source |
|---|---|---|
| 39 | Past positive rate | User history |
| 40 | Past negative rate | User history |
| 41 | Average engagement | User history |
| 42 | Interaction count | User history |
| 43 | Time since last positive | User history |
| 44 | Activity level | User history |

**Training label:** Binary -- 1.0 if outcome_type == 'positive' or outcome_score >= 0.7, else 0.0. Uses class-weighted BCELoss because the dataset is imbalanced (~35% positive, ~65% negative).

**In the app:** `OutcomePredictionService.shouldCall()` returns true if predicted probability > 0.7. This filters the calling score results -- only recommend if the model thinks the user will have a good experience.

### 2.3 Quantum Optimization Model

Given a user's personality and a use case (matching, recommendation, compatibility, prediction, analysis), this outputs optimal parameters for quantum state operations.

**What it outputs:**
- **5 superposition weights:** How much to weight personality vs. behavioral vs. relationship vs. temporal vs. contextual data when combining quantum states. Normalized to sum to 1.0.
- **1 compatibility threshold:** What fidelity score counts as "compatible" for this use case and personality.
- **12 basis importances:** Which personality dimensions matter most for this use case. Used to select the measurement basis (which dimensions to "measure" in quantum terms).

**In the app:** `QuantumMLOptimizer.optimizeSuperpositionWeights()`, `getOptimalThreshold()`, and `getOptimalBasis()` are called by the quantum vibe engine and compatibility service.

### 2.4 Entanglement Detection Model

Given a user's personality profile, predicts which dimension pairs are correlated. For example, someone high on `exploration_eagerness` probably also scores high on `location_adventurousness` -- these dimensions are "entangled."

**What it outputs:** 66 correlation values (one for each unique pair of 12 dimensions, C(12,2)=66). Values above 0.2 are returned as active entanglement pairs.

**In the app:** `QuantumEntanglementMLService.detectEntanglementPatterns()` replaces the hardcoded entanglement groups in the quantum vibe engine. Instead of static groups (exploration group, social group, temporal group), the model produces profile-specific correlations.

---

## 3. Current Testing and Validation

### 3.1 What Exists

- **Train/val/test splits:** 70/15/15 with stratified sampling for classification (outcome prediction)
- **Early stopping:** Patience of 10 epochs on validation loss for all models
- **Hyperparameter search:** Grid search over learning rate, batch size, architecture, dropout for calling score model. Best result: v1.1-hybrid (batch=128) at +3.75% improvement
- **Knot theory validation:** 18 scripts in `scripts/knot_validation/` testing quantum-only vs. quantum+knot matching with ROC curves, paired t-tests, Cohen's d, cross-validation
- **Data validation:** `dataset_base.py` validates dimension presence, range [0.0, 1.0], and completeness

### 3.2 What Doesn't Exist

- **No real-world A/B tests.** Infrastructure built (`CallingScoreABTestingService`) but never run with real users.
- **No calibration testing.** Does a prediction of 0.7 actually mean 70% success rate? Nobody knows.
- **No stratified evaluation.** Average accuracy hides performance variation across user types and spot categories.
- **No round-trip consistency tests.** Python training feature extraction and Dart inference feature extraction have never been verified against each other on the same inputs.
- **No adversarial testing.** Edge cases (all-zero user, all-one spot, exact inverse) haven't been tested.
- **No outcome correlation tracking.** When the model predicts 0.9 and the user visits, does the outcome tend to be positive? There's no pipeline to close this loop.
- **No model monitoring.** No drift detection, no prediction distribution tracking, no alerting.

---

## 4. Industry Comparison

### 4.1 Model Architecture Comparison

| Approach | Who Uses It | Complexity | Your Models |
|---|---|---|---|
| Collaborative filtering | Netflix (early), Amazon | Low | Not used |
| Matrix factorization | Amazon, Spotify | Medium | Not used |
| **MLP on feature vectors** | Many production baselines | Low-Medium | **This is you** |
| Wide & Deep | Google Play Store | Medium | Not used |
| Two-tower (user/item embeddings) | YouTube, Pinterest, TikTok | High | Not used, would be natural next step |
| Transformer-based | Spotify (recent), Google Search | Very High | Not used |
| Graph neural networks | Pinterest PinSage, LinkedIn | High | Not used |
| Reinforcement learning | TikTok, Kuaishou | Very High | Not used |
| **JEPA / Joint-Embedding Predictive** | **Meta AI (I-JEPA, V-JEPA, DINO-WM)** | **Very High** | **Not used -- see Section 5 for applicability to AVRAI** |
| **World Model + MPC** | **Meta AMI architecture, DeepMind MuZero** | **Very High** | **Not used -- this is the paradigm shift (Section 5)** |
| **Energy-Based Models** | **Meta research (VICReg, SIGReg, Barlow Twins)** | **High** | **Not used -- could replace fixed formulas (Section 5)** |

### 4.2 What Makes Your System Unique

Most recommendation systems in industry DON'T have:

- **Quantum-inspired state representation.** Your personality profiles are quantum states (complex amplitudes with phase, not just floats). Superposition, interference, entanglement, and decoherence add mathematical richness that flat vectors don't have. This means your system can capture interference patterns (two traits that amplify each other) and entanglement (traits that are correlated differently for different people).

- **Topological knot invariants.** No other recommendation system uses Jones polynomials and crossing numbers for compatibility scoring. This is genuinely novel and has mathematical grounding -- knot invariants are topological properties that are preserved under continuous deformations, meaning they capture something fundamental about personality structure.

- **On-device federated learning.** Most recommendation systems are cloud-only. Your architecture computes everything on-device first and only aggregates anonymized gradients. This is architecturally aligned with where the industry is going (Apple, Google both moving toward on-device ML).

- **AI2AI mesh learning.** Devices learning from each other's anonymized personality deltas through proximity connections is unique. No major recommendation system does this.

### 4.3 Honest Assessment

Your MLPs are a reasonable starting point. They're fast (microsecond inference), tiny (10-65KB), and interpretable. But they're also the simplest possible neural network. The quantum/knot math adds significant sophistication to the compatibility scoring, but the actual learned ML component (predicting whether a user should visit a spot) is basic.

The gap isn't in the math -- your quantum fidelity calculations, superposition, and knot topology are mathematically grounded. The gap is in **what the neural networks learn from.** Right now: synthetic spots, synthetic context, synthetic timing, synthetic history. Industry-competitive models learn from millions of real user interactions.

---

## 5. LeCun's World Model Framework & AVRAI Alignment

**Source:** Yann LeCun, "Training World Models," World Model Workshop 2026, MILA Montreal, February 4, 2026. 85 slides covering the AMI (Advanced Machine Intelligence) architecture, JEPA, Energy-Based Models, and Model-Predictive Control.

This section evaluates AVRAI's ML architecture against LeCun's framework -- which represents the current frontier of thinking about how intelligent systems should be built. The framework identifies fundamental architectural paradigms that AVRAI either already aligns with, partially aligns with, or is missing entirely.

### 5.1 The Framework in Brief

LeCun's core argument: current AI architectures (including LLMs) are missing something fundamental. Cats and dogs can plan complex actions, 10-year-olds can clear a dinner table zero-shot, 17-year-olds learn to drive in 20 hours -- yet AI systems that pass the bar exam can't do any of this. The missing piece is a **world model** that enables planning.

**Six principles:**

1. **World Models over static scorers.** An intelligent system needs a model that predicts: "given my current state and an action I might take, what will the world look like next?" Formally: `state(t+1) = Pred(state(t), action)`. This enables forward simulation and planning, not just reactive scoring.

2. **JEPA (Joint-Embedding Predictive Architecture) over generative models.** Don't predict raw observations (pixels, tokens, raw feature vectors). Predict in an *abstract representation space* where irrelevant details are stripped away. A good representation contains exactly the information needed for prediction and nothing else. This is how traditional science works: find the right state variables, then predict how they evolve.

3. **Energy-Based Models (EBM) over probabilistic models.** Instead of computing probabilities (which require intractable partition functions in high dimensions), compute an energy score. Low energy = compatible pair, high energy = incompatible pair. EBMs are more flexible in both the scoring function and the loss function. Probabilistic models are a special case of EBMs (Gibbs-Boltzmann distribution), but EBMs don't require normalization.

4. **Model-Predictive Control (MPC) over Reinforcement Learning.** Don't learn policies through trial-and-error rewards. Instead, use the world model to simulate forward, optimize an action *sequence* to minimize a cost function, execute the first action, then re-plan. This is identical to how classical control systems work, but with a trained world model instead of a hand-crafted dynamics model.

5. **Hierarchical planning.** Different levels of abstraction for different time horizons. Lower levels make short-term detailed predictions ("walk to the street"). Higher levels make long-term abstract predictions ("get to the airport"). Each level feeds into the one above it. This maps directly to the observation that physics works at multiple scales (quantum fields -> particles -> atoms -> molecules -> objects -> organisms -> societies).

6. **Guardrail objectives.** Safety and alignment are built into the architecture as *immutable cost functions* applied to the entire predicted state trajectory. They cannot be overridden by the task objective. Safety is by design, not by fine-tuning.

**LeCun's concrete recommendations (slide 83):**
- Abandon generative models in favor of joint-embedding architectures
- Abandon probabilistic models in favor of energy-based models
- Abandon contrastive methods in favor of regularized methods (VICReg, SIGReg)
- Abandon reinforcement learning in favor of model-predictive control
- "IF YOU ARE INTERESTED IN HUMAN-LEVEL AI, DON'T WORK ON LLMs"

### 5.2 What AVRAI Already Aligns With

| LeCun Principle | AVRAI Component | Alignment |
|---|---|---|
| Abstract representation space | 12D personality embeddings, knot invariants | Strong -- personality is already an abstract representation, not raw data |
| Learn from sensory inputs | `CallingScoreDataCollector` collecting real outcomes | Structural alignment, but pipeline not activated yet |
| Hierarchical abstraction | Spots -> Communities -> Events -> Life journey | Philosophical alignment, but not architecturally implemented |
| On-device intelligence | Federated learning, ONNX on-device inference | Strong -- aligns with LeCun's view that intelligence should be embodied |
| Temporal evolution modeling | Worldsheets tracking personality evolution over time | Strong conceptual alignment with `state(t+1) = Pred(state(t), action)` |
| Topological invariants as representations | Knot invariants (crossing number, Jones polynomial) | Novel approach to finding representations that capture fundamental structure |

### 5.3 Where AVRAI Partially Aligns

**Two-tower architecture (planned) = Joint Embedding Architecture.** The planned two-tower model (Section 9, Phase 3) is structurally a Joint Embedding Architecture (JEA). User tower and spot tower each learn abstract representations, compatibility is measured in embedding space via dot product. This is the architecture family LeCun recommends. However, it's a static JEA (learns fixed embeddings) rather than a predictive JEPA (predicts how embeddings evolve).

**Cross-domain learning = proto-hierarchical model.** Section 10's cross-domain learning (spots inform community recommendations, community membership informs event suggestions) is the seed of a hierarchical world model. But it's currently implemented as shared state (personality dimensions) rather than as explicit multi-level prediction. The personality profile is the *result* of cross-domain influence, not a *predictor* of cross-domain outcomes.

**Worldsheet dynamics = proto-world model.** The `KnotWorldsheetService` tracking personality evolution over time is conceptually close to `state(t+1) = Pred(state(t), action)`. The gap: worldsheets record what happened (interpolation between snapshots) rather than predicting what will happen given a hypothetical action (forward simulation).

**Multi-task learning = shared representation.** Training calling score and outcome prediction with a shared encoder aligns with JEPA's principle that a good representation supports multiple downstream tasks. But it's still a static scorer, not a predictor of state evolution.

**Entanglement detection from real outcomes = learned representation.** Replacing heuristic correlations with empirically-grounded entanglement patterns aligns with learning representations from data rather than hand-crafting them.

### 5.4 Where AVRAI Diverges

**No world model.** This is the central gap. Every model in Section 1 is a static scorer: given (user, spot), output a number. None answers: "if this user visits this spot, what will their personality state be afterwards?" None can simulate forward through a sequence of recommendations. The system is entirely System 1 (reactive) with no System 2 (deliberate planning through forward simulation).

**No planning / no MPC.** The recommendation pipeline is: score all options, rank, show top results. There's no mechanism to plan a *sequence* of recommendations optimized for a trajectory. LeCun's MPC would: (1) propose a sequence of 5 recommendations, (2) simulate the user's state evolution through each, (3) optimize the sequence to minimize cost (maximize meaning/fulfillment), (4) execute the first recommendation, (5) re-observe and re-plan. AVRAI's Spots -> Community -> Life journey is described philosophically but has zero architectural support for trajectory planning.

**No guardrail objectives.** "Doors, not badges" and "no gamification" are enforced by documentation and code review. There's no architectural mechanism -- no immutable cost function applied to the predicted recommendation trajectory -- that prevents the system from optimizing for engagement over meaningful connections. Guardrail objectives would make this structural: `GuardrailCost("real_world") > 0` if any recommendation sequence increases app time without increasing real-world activity.

**No latent variables for uncertainty.** Every model outputs a point prediction. The calling score is 0.73. The outcome probability is 0.81. LeCun's non-deterministic world model uses latent variables to represent the *range* of plausible futures. This matters for planning: "reliably decent" vs "high variance / could be amazing or terrible" should produce different recommendation strategies.

**Compatibility as fixed formula, not learned energy function.** The compatibility formula `0.5 * quantum_fidelity + 0.3 * topological + 0.2 * weave` is a hand-crafted scoring function. LeCun would frame this as an energy-based model: learn `E(user, entity)` end-to-end from outcome data. Low energy = compatible, high energy = incompatible. Train with regularized methods (VICReg-style) to prevent collapse. The formula weights, the relative importance of quantum vs topological vs weave, and even whether those three components are the right decomposition -- all would emerge from training rather than being assumed.

**Probabilistic quantum framing vs EBM.** The Born rule measurement `|psi|^2 = probability` is fundamentally probabilistic. LeCun explicitly recommends energy-based models over probabilistic models for high-dimensional continuous domains because EBMs avoid intractable partition functions and allow more flexible scoring. The quantum fidelity calculation could be reframed as an energy function with equivalent mathematical content but greater architectural flexibility.

### 5.5 Assessment Summary

| Roadmap Item | LeCun Alignment | Verdict |
|---|---|---|
| Learned embeddings | Strong pass | Directly implements JEPA principle |
| Two-tower architecture | Strong pass | Joint Embedding Architecture |
| Close feedback loop | Strong pass | Learn from real sensory inputs |
| Cross-domain learning | Strong pass | Enables hierarchical model |
| Multi-task shared encoder | Pass | Better abstract representations |
| Worldsheet as features | Pass | Seed of a world model |
| Real entanglement training | Pass | Learn, don't hand-craft |
| Calibration testing | Pass | Prerequisite for MPC planning |
| Cross-features (user_i * spot_i) | Partial | Band-aid for concatenation architecture |
| LSTM sequence modeling | Partial | System 1 only, no forward planning |
| Adaptive quantum weights | Partial | Optimizing within fixed formula |
| Richer knot invariants | Partial fail | More hand-crafting, not more learning |
| Adaptive 70/30 blending | Partial | Should distill, not blend |
| **No world model** | **Fail** | **Biggest missing piece** |
| **No MPC planning** | **Fail** | **No trajectory optimization** |
| **No guardrail objectives** | **Fail** | **Philosophy without architecture** |
| **No latent variables** | **Fail** | **No uncertainty modeling** |
| **Formula as EBM** | **Fail** | **Should be learned energy function** |
| Jones polynomial on QPU | Fail | Faster hand-crafting is still hand-crafting |
| QAOA parameter optimization | Fail | Wrong level of optimization |

---

## 6. Spot / Community / Event Models for Users

### 6.1 Current State

**Spot recommendations:** The calling score model IS your spot recommendation model. The flow is:
1. `SpotVibe` computes 12D vibe for each spot (rule-based keyword heuristics)
2. `CallingScoreCalculator` scores each spot against the user using the 5-component formula
3. Optionally blends in ONNX neural prediction (behind A/B test flag, defaults to formula-only)
4. `OutcomePredictionService` can filter out spots with predicted negative outcomes
5. Users see ranked recommendations but not the score itself

**Community recommendations:** Uses quantum fidelity (cosine-similarity-squared on 12D vectors) + knot topological compatibility + weave stability. Formula: `0.5 * quantum + 0.3 * topological + 0.2 * weaveFit`. No ONNX model. `getRecommendedCommunitiesForUser()` is wired to the discover page.

**Event recommendations:** Uses weighted formula: `0.35 * matchingScore + 0.35 * preferenceScore + 0.15 * crossLocality + 0.15 * knotCompatibility`. The knot component optionally uses `QuantumMatchingController`. No ONNX model. Wired to the events browse page via `AIRecommendationController`.

### 6.2 Key Insight: The Three Systems Don't Talk to Each Other

Right now, spot/community/event recommendations are completely independent pipelines. A user's positive experience at a spot doesn't improve their community recommendations. A community membership doesn't inform event suggestions. This is a major gap -- the shared state (12D personality profile) connects them implicitly, but there's no explicit cross-domain signal flow.

---

## 7. Improving Models Now (With Quantum, String Theory, and World Models in Mind)

### 7.1 Near-Term Model Improvements (No Quantum Needed)

**Learned embeddings instead of hand-crafted features.**

Right now, personality and spot vibes are 12 floats computed by keyword heuristics. A small embedding network could learn richer representations from raw spot metadata (category, tags, price, review count, hours) instead of manually defining what "energy" means for each category. A spot embedding would capture latent features that keyword matching misses -- for example, that two spots with completely different categories (a vinyl record shop and a craft cocktail bar) attract similar people.

**Cross-features.**

The 39D input is just concatenation: `[user_12D, spot_12D, context_10D, timing_5D]`. The model has to learn user-spot interactions from scratch. Adding explicit cross-features (per-dimension `user_i * spot_i` product, `user_i - spot_i` difference) gives the model a head start. This is the insight behind DeepFM and Wide & Deep architectures -- a "wide" component handles memorized feature interactions while the "deep" MLP handles generalization.

**Sequence modeling for history.**

The outcome prediction model takes 6 history features as flat numbers (past_positive_rate, average_engagement, etc.). A small LSTM or attention mechanism over a user's last N interactions would capture temporal patterns that flat aggregates miss -- patterns like "this user likes coffeeshops on Saturday mornings" or "this user's preferences shift seasonally."

**Multi-task learning.**

Instead of training calling score and outcome prediction as separate models, train a single model with two heads: one predicting calling score, one predicting outcome. The shared encoder learns better representations because both tasks provide supervision signal. The calling score head tells the encoder "what makes a good match" while the outcome head tells it "what makes a good experience" -- these are correlated but distinct signals.

### 7.2 Quantum-Ready Improvements

**Train entanglement model on real outcomes.**

Right now it learns from synthetic heuristic correlations (exploration group, social group at correlation 0.3). Instead: when two users match well (high calling score + positive outcome), record which of their dimensions were similar and which were complementary. This gives you empirically-grounded entanglement patterns that reveal real personality structure, not assumed structure.

**Adaptive quantum compilation.**

The quantum vibe engine currently uses fixed weights for superposition (personality, behavioral, social, relationship, temporal sources). The quantum optimization ONNX model dynamically adjusts these weights per user and use case. But it's trained on heuristic labels. Once you have real outcome data, retrain the optimization model to learn: "for users with THIS personality profile doing THIS task, what superposition weights produce the best outcomes?"

**Jones polynomial computation as a quantum advantage target.**

Your `VibeCompatibilityService` already uses Jones polynomial similarity (0.4 weight in knot weave scoring). Computing Jones polynomials is a BQP-complete problem -- quantum computers can evaluate them exponentially faster than classical computers. As personality knots become more complex (more crossings, richer braid representations), this becomes the first concrete place where cloud quantum hardware gives a real speedup. Your `QuantumComputeProvider` already routes to cloud quantum when conditions are met, so the architecture is ready.

**N-way group entanglement.**

The `ClassicalQuantumBackend.createEntangledState()` currently does pairwise fidelities and averages for N entities -- O(N^2) operations. True N-way entanglement on quantum hardware would handle groups of 5+ people natively, with the state space growing as 2^N (exponentially expensive classically, native on quantum). Your architecture already routes to cloud quantum when `entityCount >= 5 && isOnline && featureFlag`.

### 7.3 String Theory / Knot Theory Improvements

**Richer knot invariants.**

Currently using crossing number, writhe, bridge number, unknotting number, and Jones polynomial. Adding Alexander polynomials and HOMFLYPT polynomials would provide finer-grained topological signatures. The validation scripts in `scripts/knot_validation/test_topological_improvements.py` already test Jones + Alexander combinations.

**Worldsheet dynamics.**

The `KnotWorldsheetService` models how personality knots evolve over time as 2D worldsheets (the string theory concept where a 1D string traces a 2D surface through time). This temporal evolution data could be used as training features for the calling score model -- not just "what is the user's personality NOW" but "how has it been changing and where is it headed."

**Fabric weave stability.**

The `KnotFabricService` computes how well a user's knot "weaves" into a community's fabric. This weave stability metric could be used as an additional feature in the calling score model for community-related spots/events -- a user with a stable weave into a community is more likely to attend events hosted by that community.

### 7.4 World Model Architecture Improvements (from LeCun Framework)

These improvements address the paradigm gaps identified in Section 5. They represent a shift from "score individual items" to "predict state evolution and plan trajectories." Ordered from most accessible to most ambitious.

**7.4.1 Personality State Transition Model (the minimal world model)**

Train a model that predicts: "given user personality state S(t) and action A (visiting a spot, joining a community, attending an event), what will personality state S(t+1) be?"

```
Input:  user_personality_12D (state at time t)
        + action_type (spot_visit, community_join, event_attend, ai2ai_interaction)
        + action_embedding (12D vibe of the spot/community/event)
Output: predicted_personality_12D (state at time t+1)
        + predicted_delta_12D (change vector)
```

This is the foundational world model. `PersonalityLearning.evolveFromUserAction()` already computes personality deltas from actions -- but it uses hand-crafted rules (e.g., "joining a large community increases crowd_tolerance by learning_rate * 0.15"). A trained model would learn these transitions from real outcome data collected via `CallingScoreDataCollector`. The training signal is: before-personality, action, after-personality (measured at next interaction).

This model transforms AVRAI from reactive ("what's good for you now?") to predictive ("if you do X, you'll become more Y, which opens door Z").

**Training data source:** Every `processUserInteraction()` call that triggers `PersonalityLearning.evolveFromUserAction()` already produces (before_state, action, after_state) triples. These are currently computed by rules. Collecting actual before/after personality snapshots around real interactions produces real transition data.

**Effort:** 1-2 weeks (model training + Dart inference integration)

**7.4.2 Model-Predictive Control for Recommendation Sequences**

Once the personality state transition model exists, use it for MPC-style planning:

```
1. Given current user state S(0), generate candidate recommendation sequences:
   [spot_A, event_B, community_C], [spot_D, spot_E, event_F], ...

2. For each sequence, simulate forward using the state transition model:
   S(1) = Pred(S(0), spot_A)
   S(2) = Pred(S(1), event_B)
   S(3) = Pred(S(2), community_C)

3. Evaluate each trajectory against:
   - Task objective: maximize meaning/fulfillment/happiness at S(T)
   - Guardrail objectives: ensure real-world engagement, no gamification

4. Select the sequence that minimizes total cost.

5. Recommend the FIRST item in the optimal sequence.

6. After the user acts, re-observe personality state and re-plan.
```

This is how AVRAI would architecturally implement the Spots -> Community -> Life journey. Instead of independently scoring spots, communities, and events, the system plans a *trajectory* through all three domains optimized for long-term outcomes.

**Key insight:** MPC doesn't require the world model to be perfect. Because you re-plan after every action (step 6), small prediction errors are corrected at each step. The model only needs to be accurate enough for the next 3-5 actions, not for the entire life trajectory.

**Effort:** 2-3 weeks (planning loop + trajectory scoring + integration with recommendation pipeline)

**7.4.3 Guardrail Objectives as Immutable Cost Functions**

Implement "doors, not badges" and "no gamification" as architectural constraints in the planning loop:

```dart
// These costs are applied to EVERY predicted state in the trajectory.
// They CANNOT be overridden by the task objective.

double guardrailCost(PredictedState state, RecommendationAction action) {
  double cost = 0.0;

  // Penalize recommendations that increase app time without real-world activity
  if (state.predictedAppTime > state.predictedRealWorldTime) {
    cost += 10.0; // Hard penalty
  }

  // Penalize engagement-optimizing recommendations
  if (action.optimizesForRetention && !action.optimizesForMeaning) {
    cost += 10.0; // Hard penalty
  }

  // Penalize recommendations that reduce diversity of experiences
  if (state.experienceDiversity < threshold) {
    cost += 5.0; // Soft penalty -- encourage exploration
  }

  return cost; // Immutable -- task objective cannot override
}
```

This turns AVRAI's philosophy into math. The planning loop from 7.4.2 applies guardrail costs to every predicted state in the trajectory. A recommendation sequence that technically scores high on calling score but violates a guardrail gets rejected, no exceptions.

**Effort:** 1 week (define guardrail functions + integrate into planning loop)

**7.4.4 Latent Variables for Uncertainty in Predictions**

Add latent variables to the personality state transition model so it outputs a *distribution* of possible next states, not a single point prediction:

```
Input:  user_personality_12D + action_embedding + latent_z (sampled or swept)
Output: predicted_personality_12D (one of many plausible futures)
```

By varying the latent variable z, the model produces different plausible outcomes for the same action. This enables:
- **Expected-case planning:** Average over multiple z samples to find recommendations that are *reliably* good
- **Worst-case planning:** Find the z that produces the worst outcome, and avoid recommendations where even the worst case is bad
- **Confidence communication:** "I'm 90% sure you'll enjoy this" (low variance across z) vs "This is a wildcard" (high variance across z)

This directly addresses the limitation that current models output single point predictions with no uncertainty quantification.

**Effort:** 1-2 weeks (VAE-style training + integration with MPC planner)

**7.4.5 Energy-Based Compatibility Function**

Replace the hand-crafted compatibility formula with a learned energy function:

```
Current:  compatibility = 0.5 * quantum_fidelity + 0.3 * topological + 0.2 * weave
Proposed: compatibility = -E(user_embedding, entity_embedding)
          where E is a trained neural energy function
```

Train E using VICReg-style regularization (variance-invariance-covariance) to prevent energy collapse:
- **Variance:** Ensure embeddings use all dimensions (prevent dimensions from going constant)
- **Invariance:** Ensure compatible pairs have similar embeddings (low energy)
- **Covariance:** Ensure embedding dimensions are decorrelated (each carries unique information)

The energy function learns which aspects of compatibility matter from outcome data. The quantum fidelity, topological compatibility, and weave stability might emerge as learned features -- or the model might discover entirely different compatibility dimensions that are more predictive.

**Why this matters for AVRAI's quantum system:** The quantum state representation (complex amplitudes, superposition, interference) can serve as the *input* to the energy function rather than being the *scoring function itself*. The quantum states provide a mathematically rich representation; the energy function learns how to use that representation for compatibility prediction. This preserves the quantum mathematics while making the compatibility scoring learnable.

**Effort:** 2-3 weeks (energy function architecture + VICReg training + replace formula in VibeCompatibilityService)

**7.4.6 JEPA for Personality Representation Learning**

Instead of hand-crafting which 12 dimensions matter and how they're computed from Big Five OCEAN data, use a JEPA to *discover* the optimal personality embedding:

```
Context encoder:  Raw user behavior (spot visits, feedback, timing patterns, community activity)
                  -> abstract personality representation (learned dimensionality)

Target encoder:   Future user behavior (next week's spots, next month's community engagement)
                  -> abstract personality representation

Predictor:        Given context representation + hypothetical action
                  -> predicted target representation
```

Train with information maximization (VICReg/SIGReg):
- **Variance term:** All embedding dimensions are used (no collapse)
- **Covariance term:** Dimensions are decorrelated (each carries unique info)
- **Prediction term:** Context + action accurately predicts target

The learned embedding might not be 12D. It might be 24D or 8D. The dimensions might not map to human-interpretable concepts like "openness" or "energy_preference." But they'd be *optimally predictive* of user behavior -- which is what matters for recommendations.

**Important nuance:** This doesn't eliminate the 12D personality model for user-facing features (showing personality insights, explaining recommendations). It creates a *parallel* learned embedding used internally for prediction and planning, while the interpretable 12D model remains for UI/UX.

**Effort:** 3-4 weeks (JEPA architecture + self-supervised training pipeline + parallel embedding system)

**7.4.7 System 1/System 2 Compilation (Distillation)**

Once the MPC planner (7.4.2) produces high-quality recommendation sequences, distill its decisions into a fast reactive model:

```
System 2 (slow, deliberate):
  MPC planner simulates 100 candidate sequences
  Selects optimal trajectory considering guardrails
  Produces: (user_state, recommended_action, planned_trajectory)

System 1 (fast, reactive):
  Neural policy trained on System 2's outputs
  Input: user_state
  Output: recommended_action
  Inference: microseconds (on-device ONNX)
```

The fast model handles 95% of recommendations instantly. The slow planner is invoked for high-stakes decisions (first community recommendation, major life event) or when the fast model's confidence is low.

This mirrors how human cognition works: most daily decisions are fast/automatic (System 1), but important decisions involve deliberate planning (System 2). Over time, System 2's wisdom gets compiled into System 1's reflexes.

**In AVRAI terms:** The current formula + ONNX hybrid IS System 1. There is no System 2. Building the MPC planner creates System 2. Distilling its outputs into the ONNX model creates a better System 1 that incorporates trajectory-aware reasoning even though it runs in microseconds.

**Effort:** 2-3 weeks (distillation training loop + confidence-based routing between System 1 and System 2)

**7.4.8 AI2AI World Model for Proactive Conversation Planning**

Build a world model specifically for AI2AI interactions that predicts: "if my AI talks to this other AI about topic X, what personality dimensions will shift and by how much?"

```
Input:  my_personality_12D + peer_personality_12D + conversation_topic + conversation_depth
Output: predicted_personality_delta_12D + predicted_learning_quality + predicted_insights
```

Instead of reactively analyzing conversations after they happen (current `AI2AIChatAnalyzer`), the AI plans conversations proactively: "This peer's personality profile suggests that discussing topic X would produce high-quality learning in dimension Y. Topic Z would be lower quality." The AI then steers the conversation toward topics with the highest predicted learning value.

This transforms AI2AI from "meet and see what happens" to "meet with a plan for what to explore."

**Effort:** 2-3 weeks (interaction outcome dataset + transition model + conversation planning integration)

---

## 8. Improving Model Testing With Synthetic Data

### 8.1 Calibration Testing

Plot a reliability diagram: divide predictions into 10 bins (0.0-0.1, 0.1-0.2, ..., 0.9-1.0), compute the actual positive rate in each bin. A perfectly calibrated model has predicted probability = actual frequency. If the model says 0.8 but only 50% of examples are positive, the model is overconfident. Apply temperature scaling to fix.

This matters especially for the outcome prediction model, which gates recommendations at threshold 0.7. Poor calibration means either blocking good recommendations (threshold too aggressive) or showing bad ones (threshold too lenient).

### 8.2 Stratified Evaluation

Break test set performance by:
- **User archetype:** Explorer vs. Connector vs. Creator (from knot-to-archetype mapping)
- **Spot category:** Food vs. Nightlife vs. Attractions vs. Shopping
- **Time context:** Morning vs. Afternoon vs. Evening vs. Late Night
- **History depth:** New users (0-5 interactions) vs. Established users (50+ interactions)

A model averaging 75% accuracy might be 95% for restaurants and 30% for museums. Stratified metrics reveal where the model fails and where to focus data collection.

### 8.3 Adversarial Synthetic Users

Generate deliberate edge cases:
- All-zero personality (does the model output a sensible default?)
- All-one personality (same question)
- Exact inverse of spot vibe (should score low -- does it?)
- Extreme context (proximity = 0.0, all timing = 0.0 -- does the model still make reasonable predictions?)
- Duplicate user = spot personality (should score very high)

These test whether the model learned meaningful patterns or just memorized the training distribution.

### 8.4 Round-Trip Consistency

Export 100 test records. Run them through:
1. Python `extract_features()` + ONNX model -> prediction_python
2. Dart `prepareFeatures()` + OrtSession -> prediction_dart

Compare outputs. Any discrepancy > 1e-5 means a feature extraction bug. This is critical because feature extraction code exists in two places (Python training and Dart inference) and must match exactly.

### 8.5 A/B Simulation

The `CallingScoreABTestingService` infrastructure exists. Before real users, simulate:
- Control group: Formula-only calling score
- Treatment group: 70% formula + 30% neural hybrid

Run both on the test set. Compare average score, correlation with outcome, and threshold calibration. This validates the infrastructure and gives a baseline lift estimate.

### 8.6 Temporal Validation

Split the training data chronologically rather than randomly. Train on the first 80K samples, test on the last 20K. This simulates real-world deployment where the model predicts on data from the future. Random splits can overfit to distributional properties that don't hold over time.

---

## 9. Competitive Models Using Real Data + Privacy

### 9.1 Available Data Sources (Privacy-Safe)

| Data Source | What It Provides | Privacy Mechanism | Currently Collected? |
|---|---|---|---|
| Calling score outcomes | Visit/no-visit + positive/negative/neutral | Agent ID + noisy dimensions via CallingScoreDataCollector | Yes (Supabase) |
| Dwell time / engagement | Duration, interaction count | On-device only, aggregate before upload | No |
| Feedback events | Love/like/dislike/hate on spots | On-device via FeedbackProcessor (currently stub) | No |
| Cross-app signals | Calendar (schedule), health (energy), music (mood) | Opt-in via CrossAppConsentService, on-device processing | Partially (location and weather functional, calendar/health/media partially functional) |
| AI2AI learning deltas | Personality shifts from meeting others | 22% threshold, 12-connection limit, +-0.20 max bias | Yes |
| Real spot metadata | Rating, price, review count, hours, category | Public data (OSM/Google Places) | Pipeline built, not yet run |
| Community membership signals | Join/leave, participation level | Agent ID, on-device first | No |
| Event attendance signals | RSVP, attendance, post-event feedback | Agent ID, on-device first | No |

### 9.2 Path to Industry-Competitive Models

**Phase 1: Activate the feedback loop (highest ROI)**

The `CallingScoreDataCollector` already sends training data to Supabase. Build a monthly batch retraining pipeline:
1. Pull collected data from Supabase (already agent-ID pseudonymized)
2. Merge with synthetic data (to maintain coverage where real data is sparse)
3. Retrain calling score + outcome prediction models
4. Ship updated models via app update or on-device download

This alone would make the models dramatically better because they'd learn from actual user behavior rather than synthetic approximations.

**Phase 2: Wire missing data collectors**

Create equivalent collectors for communities and events:
- `CommunityMembershipDataCollector`: logs community join/leave events with anonymized compatibility scores
- `EventAttendanceDataCollector`: logs event RSVP + attendance + post-event sentiment

Wire `FeedbackProcessor` into `ContinuousLearningSystem.processUserInteraction()` so explicit feedback (love/hate) reaches the learning pipeline.

**Phase 3: Two-tower architecture**

Replace the 39D concatenated input with a two-tower model:
- **User tower:** user_12D + history_6D + cross-app_signals -> 32D user embedding
- **Spot tower:** spot_12D + metadata (rating, price, reviews, hours, category) -> 32D spot embedding
- **Score:** dot product of embeddings + optional cross-network on concatenated embeddings

This scales to millions of spots because each embedding is computed once. The towers can be trained federatedly (user tower on-device, spot tower centrally). This is what YouTube, TikTok, and Pinterest use.

**Phase 4: Federated calling score model**

Wire the `FederatedLearningSystem` to actually train the calling score MLP on-device using local interaction data. Aggregate gradients (with Laplace noise) via the `federated-sync` edge function. Each user's model improves from their own data; the central model improves from anonymized gradients. This is how Google's keyboard prediction and Apple's Siri work.

### 9.3 Privacy Hardening for Real Data

1. **Activate Laplace noise.** Replace uniform noise in `UserVibe.fromPersonalityProfile` with the already-stubbed `_generateLaplaceNoise`. Calibrate epsilon = 1.0 as starting point. Track cumulative epsilon per user per time window.

2. **Generalize opportunity_id.** Before cloud upload, replace exact spot IDs with `spot_category + city_region` to prevent re-identification.

3. **Fix CloudIntelligenceSync.** It queries by `user_id` instead of `agent_id`, breaking the anonymization boundary.

4. **Implement account deletion.** GDPR Article 17 requires it. The compliance docs describe the flow, but no `AccountDeletionService` exists.

5. **Implement data export/portability.** GDPR Article 20 requires it. Same gap.

6. **Switch cross-app consent to opt-in for EU users.** Currently defaults to enabled (CCPA model). GDPR requires affirmative opt-in.

---

## 10. Cross-Domain Learning as Hierarchical World Model

### 10.1 Current Problem

The three recommendation systems are completely independent:
- **Spots:** Calling score formula + optional ONNX
- **Communities:** Quantum fidelity + knot compatibility
- **Events:** Weighted formula + optional knot compatibility

None feed information back to each other. A user's positive experience at a spot doesn't improve community recommendations. A community membership doesn't inform event suggestions.

### 10.2 LeCun's Hierarchical Model Applied to AVRAI

LeCun's hierarchical planning framework (slide 25, 30) maps directly to AVRAI's domain structure. The key insight: different recommendation domains operate at different time scales and abstraction levels -- exactly the property that a hierarchical world model exploits.

```
Level 0 (Spots):       Short-term, detailed predictions
                        "If user visits Third Coast Coffee Tuesday morning,
                         predicted satisfaction = 0.85, energy_preference shifts +0.03"
                        Time horizon: hours to days
                        Prediction detail: specific spot outcomes

Level 1 (Communities):  Medium-term, moderate abstraction
                        "If user joins the Writers' Group, predicted community
                         engagement trajectory over 3 months = steady increase,
                         social dimensions shift toward community_orientation +0.08"
                        Time horizon: weeks to months
                        Prediction detail: community engagement patterns

Level 2 (Life):         Long-term, high abstraction
                        "If user follows this path (coffee spots -> writing community
                         -> literary events), predicted meaning/fulfillment trajectory
                         over 1 year = significant growth in authenticity_preference
                         and meaning_alignment"
                        Time horizon: months to years
                        Prediction detail: life trajectory direction
```

**How the levels interact (top-down and bottom-up):**

- **Bottom-up:** Level 0 outcomes (spot visits) produce personality state changes that Level 1 uses to predict community compatibility. Level 1 outcomes (community membership) produce trajectory data that Level 2 uses to predict life direction.

- **Top-down:** Level 2 objectives ("user is moving toward meaning through creative expression") constrain Level 1 planning ("recommend communities aligned with creative expression") which constrains Level 0 planning ("recommend spots where creative people gather").

This is exactly LeCun's hierarchical planning example (slide 30): the high-level plan "get to Paris" constrains the mid-level plan "get to the airport" which constrains the low-level plan "walk to the street and hail a taxi." Applied to AVRAI: the high-level plan "help user find meaningful connections through creative expression" constrains "recommend writing community" constrains "recommend Third Coast Coffee on Tuesday when the writers meet."

**Architectural implication:** The personality state transition model (Section 7.4.1) needs to operate at all three levels. Level 0 predicts personality shifts from individual spot visits. Level 1 predicts trajectory shifts from community membership patterns. Level 2 predicts life direction from the combination of spots + communities + events. Each level's world model runs at a different time granularity with a different abstraction level, but they share the underlying personality state representation.

### 10.3 The Shared Personality Link

The 12D personality profile IS the shared state connecting all three domains. The `ContinuousLearningSystem` already adjusts personality from spot visits via `PersonalityLearning.evolveFromUserAction()`. When personality changes, community and event scores recalculate automatically.

The gap: **community joins and event attendance aren't wired as interaction events.** `processUserInteraction()` handles spot visits, respect taps, dwell time, and searches, but not community joins or event RSVPs.

### 10.4 How to Wire Cross-Domain Learning

**Step 1: Add interaction types.**

Extend `ContinuousLearningSystem.processUserInteraction()` to handle:
- `community_join` / `community_leave` / `community_participate`
- `event_rsvp` / `event_attend` / `event_feedback`

Each maps to a personality dimension adjustment (e.g., joining a large active community increases `crowd_tolerance` and `community_orientation`).

**Step 2: Cross-domain transfer signals.**

If a user loves indie coffee shops (spots), they'll probably like an artisan coffee community and a latte art event. The personality dimensions capture this implicitly (high `authenticity_preference`, high `curation_tendency`), but explicit category affinity tracking would be stronger:
- Track which spot categories produce positive outcomes
- Boost communities and events in matching categories
- Decay affinity over time (preferences shift)

**Step 3: Community context for spot recommendations.**

Community cohesion metrics (from `CommunityService.getCommunityMetrics()`) should inform spot recommendations for community members. If a community has high average `energy_preference`, spots recommended during community events should skew high-energy.

**Step 4: Event outcomes feed back to community matching.**

If a user RSVPs to an event, has a positive experience, and joins a community afterwards, that's a strong signal about community compatibility. Track this event-to-community conversion rate and weight it in community recommendations.

**Step 5: Unified multi-domain bias overlay.**

The `OnnxDimensionScorer` already receives bias deltas from AI2AI connections. Extend to receive deltas from all three domains:
- Spot outcome delta: "after visiting this type of spot, dimension X shifted by Y"
- Community membership delta: "being in this community shifted dimension X by Y"
- Event attendance delta: "attending this type of event shifted dimension X by Y"

The bias overlay learns from all three domains simultaneously, creating a unified personalization signal.

---

## 11. Gaps You're Not Seeing

### 11.1 Architectural Gaps

1. **No feedback loop from inference to training.** `CallingScoreDataCollector` collects data in Supabase but nothing trains on it. Data accumulates unused. Even monthly batch retraining would dramatically improve model quality.

2. **FeedbackProcessor is dead code.** Not connected to the learning pipeline. When a user loves/hates a spot, that signal never reaches the ONNX models or personality learning. Wire it to `ContinuousLearningSystem.processUserInteraction()`.

3. **4 stub ML services consume code space and suggest features that don't work.** `PatternRecognition`, `PredictiveAnalytics`, `PreferenceLearning`, `SocialContextAnalyzer` all return hardcoded values. Either implement or remove.

4. **`_propagateLearningToMesh()` never sends.** The continuous learning system logs "propagating to mesh" but `ConnectionOrchestrator` has no public `propagateLearningInsight()` API. Learning insights stay local.

5. **No cold-start strategy.** A new user with no history gets the same formula-based score as someone with 1000 interactions. The onboarding data helps, but there's no explicit cold-start path using community averages or popular spots as priors.

6. **Model versions are all "staging."** None have been promoted to "active" production status. The A/B testing infrastructure exists but has never been activated.

### 11.2 Data Gaps

7. **Spot vibes are keyword heuristics.** `SpotVibe._inferDimensionsFromCharacteristics()` assigns "0.80 energy for nightclubs." The OSM/Google Places pipeline exists but hasn't been run. Real spot data with ratings, price levels, and review counts would improve every downstream model.

8. **No negative examples from real behavior.** Training data is 55% called / 45% not called based on formula thresholds. Real users produce harder negatives -- spots they SAW but didn't visit, events they RSVPd to but didn't attend. These are far more informative than synthetic negatives.

9. **Community and event data never used in ONNX training.** The calling score model only trains on user-spot pairs. No `CommunityScoreDataCollector` or `EventOutcomeDataCollector` exists.

10. **AI2AI learning data not collected.** `LearningDataCollector.collectAI2AIData()` returns empty (TODO). AI2AI interaction patterns are a rich signal source that's unused.

### 11.3 Privacy Gaps

11. **No account deletion implementation.** GDPR Article 17 requires it. Documented but not built.

12. **No data export/portability.** GDPR Article 20 requires it. Documented but not built.

13. **Cross-app consent defaults to opt-in.** Not GDPR-compliant for EU users.

14. **`_checkDataLeakage` and `_validateEntropyLevels` are stubs.** Anonymization quality validation returns hardcoded values (0.05 and 0.9). Not actually validating anything.

15. **`CloudIntelligenceSync` uses `user_id` instead of `agent_id`** in `getNetworkInsights`, breaking the anonymization boundary.

16. **`CallingScoreDataCollector` sends exact `opportunity_id`** to cloud. Combined with `agent_id` and timestamp, this is a re-identification vector.

### 11.4 Model Quality Gaps

17. **No online learning.** All models are static after training. Real recommendation systems continuously update. Even simple online gradient descent on recent batches helps significantly.

18. **No model monitoring.** No prediction distribution drift detection, no feature drift detection, no alerting. If the model starts predicting 0.9 for everything, nobody would know.

19. **v2 outcome prediction accuracy dropped from 88% to 75%.** The full 5-component labels are harder to predict. Options: larger architecture (add another hidden layer), label smoothing, or curriculum learning (train on easy labels first, then hard ones).

20. **`evaluateModel()` returns hardcoded 0.8 and `predict()` returns empty map** in `ContinuousLearningSystem`. Model quality evaluation is not functional.

21. **No ensemble method.** The formula and neural model are blended with fixed weights (70/30). An adaptive blending that learns the optimal weight per context would outperform both individual approaches.

### 11.5 Architectural Paradigm Gaps (from LeCun Framework Analysis)

These are not bugs or missing features -- they're fundamental architectural paradigms that the system lacks entirely. Identified by evaluating AVRAI against LeCun's World Model framework (Section 5).

22. **No world model / no forward prediction.** Every model is a static scorer: (user, spot) -> number. No model predicts "if user does X, their state becomes Y." This means the system cannot plan, cannot simulate outcomes, and cannot optimize for trajectories. The Spots -> Community -> Life journey has no architectural support. See Section 7.4.1 for the fix.

23. **No trajectory planning / no MPC.** Recommendations are one-shot: score all options, rank, show top. There's no mechanism to plan a *sequence* of recommendations optimized for long-term outcomes. The system answers "what's good now?" but never "what sequence of experiences leads to meaning?" See Section 7.4.2 for the fix.

24. **No immutable guardrail objectives.** "Doors, not badges" and "no gamification" are policy, not architecture. There's no cost function in the recommendation loop that *structurally prevents* engagement optimization over meaningful connections. A future developer could accidentally optimize for retention without anything in the architecture stopping them. See Section 7.4.3 for the fix.

25. **No uncertainty modeling.** All predictions are point estimates (calling score = 0.73, outcome probability = 0.81). No model represents the range of plausible outcomes or distinguishes "reliably decent" from "high variance wildcard." This matters for planning: different recommendation strategies are appropriate for different uncertainty levels. See Section 7.4.4 for the fix.

26. **Compatibility is formula, not learned function.** The `0.5 * quantum + 0.3 * topological + 0.2 * weave` formula assumes both the decomposition and the weights. An energy-based model would learn the entire compatibility function end-to-end from outcome data. The formula might be approximately correct, but it's not *provably optimal*, and it can't adapt as the system learns. See Section 7.4.5 for the fix.

27. **System 1 only, no System 2.** Every recommendation path is reactive (fast pattern matching). There's no deliberate planning mode for high-stakes decisions (first community recommendation, career networking events). The formula + ONNX hybrid is a fast reflex, not a deliberate planner. See Section 7.4.7 for the fix.

28. **Personality dimensions are hand-crafted, not learned.** The 12 dimensions were designed (Big Five OCEAN -> SPOTS mapping). A JEPA-style self-supervised approach would discover optimal embedding dimensions from user behavior data. The hand-crafted dimensions might be close to optimal, but learned dimensions would be provably optimal for prediction. See Section 7.4.6 for the fix.

---

## 12. Privacy Infrastructure Audit

### 12.1 What's Implemented and Working

| Protection | Status |
|---|---|
| Agent ID pseudonymization (AES-256-GCM, key rotation) | Production |
| Differential privacy noise on vibe dimensions | Production (uniform noise; Laplace stubbed) |
| Multi-level DP with epsilon calibration (0.5-2.0) | Production |
| AI2AI payload validation (40+ forbidden keys, regex patterns, recursive) | Production |
| Location obfuscation (~1km rounding, +500m noise, home blacklist, 24h expiry) | Production |
| Message encryption (AES-256-GCM, constant-time comparison) | Production |
| Multi-hop onion routing (up to 5 hops) | Production |
| Temporal decay (vibe signatures expire) | Production |
| User anonymization service (strips ALL personal fields) | Production |
| Cross-app per-source consent (calendar, health, media, app usage) | Production |
| Federated learning with DP on gradients | Production (structure, simulated training) |
| Field encryption at rest | Production |
| Audit logging for agent ID access | Production |

### 12.2 What's Missing

| Gap | Impact |
|---|---|
| Account deletion cascade | GDPR Article 17 violation |
| Data export/portability | GDPR Article 20 violation |
| Opt-in consent for EU (currently opt-out) | GDPR consent violation |
| Laplace noise (stubbed, not active) | Weaker formal DP guarantees |
| Privacy budget tracking | No cumulative epsilon accounting |
| Automated key rotation | Manual-only |
| Data leakage validation (stub) | Anonymization quality unknown |
| Breach detection/notification | No anomaly detection |
| DPIA (Data Protection Impact Assessment) | No artifact |
| DPO contact info | Placeholder in docs |

---

## 13. Federated Learning Infrastructure

### 13.1 Current Architecture

```
User Interaction
    |
    v
ContinuousLearningSystem
    |-- processUserInteraction()
    |   |-- 4 AI2AI safeguards (20min throttle, 65% quality, rate limit, 22% delta)
    |   |-- 30% max drift prevention from original personality
    |   |-- PersonalityLearning.evolveFromUserAction()
    |   |-- OnnxDimensionScorer.updateWithDeltas()
    |   |-- StructuredFactsExtractor (facts -> index)
    |   |-- _propagateLearningToMesh() [TODO: no public API]
    |
    v
ContinuousLearningOrchestrator
    |-- 1-second Timer.periodic learning cycle
    |-- 5 learning engines (personality, behavior, preference, interaction, location)
    |-- LearningDataCollector (10 sources, some TODO)
    |-- PersonalityLearning.evolveFromExternalContext()
    |-- AdvancedAICommunication (share insights to mesh)

AI2AI Connection
    |
    v
FederatedLearningHooks.onConnectionEstablished()
    |-- EmbeddingDeltaCollector.collectDeltas()
    |   (12D delta, 22% per-dim threshold, 12-connection max)
    |-- OnnxDimensionScorer.updateWithDeltas()
    |   (bias overlay: +-0.05 per batch, +-0.20 max)

CallingScoreDataCollector --> Supabase (training data for future retraining)
```

### 13.2 What Works

- Personality evolution from user actions (spot visits, respect taps, dwell time)
- AI2AI delta collection with quality thresholds
- ONNX bias overlay with bounded updates
- Cross-app consent per data source
- Data collection for future neural network training

### 13.3 What Doesn't Work Yet

- Mesh propagation (no public API on ConnectionOrchestrator)
- AI2AI data collection (returns empty)
- User action collection in LearningDataCollector (returns empty)
- FederatedLearningSystem round management (simulates training, random loss/accuracy)
- Retraining pipeline from collected Supabase data to updated ONNX models
- Community join / event attendance as learning signals

---

## 14. Quantum and Knot Theory Systems

### 14.1 Quantum State Representation

Each personality dimension is a complex amplitude `(real, imaginary)` rather than a single float. This enables:

- **Superposition:** `|psi> = sqrt(w1)|psi1> + sqrt(w2)|psi2>` -- mathematically correct (amplitudes weighted by square root because probabilities are squared amplitudes)
- **Interference:** Constructive (amplitudes add) or destructive (amplitudes subtract) when states align/oppose
- **Entanglement:** Phase correlation between dimension pairs -- measuring one dimension constrains the other
- **Decoherence:** Imaginary component decays over time, collapsing toward classical values
- **Measurement:** Born rule `|psi|^2 = real^2 + imaginary^2` produces classical 0.0-1.0 values

### 14.2 Quantum Vibe Engine Pipeline

```
5 Data Sources (personality, behavioral, social, relationship, temporal)
    |
    v
Classical-to-Quantum: score -> QuantumVibeState(sqrt(score), 0.0)
    |
    v
Superposition: iterative weighted combination per dimension
    |
    v
Interference: if states aligned (phases within pi/4), constructive interference (70/30 blend)
    |
    v
Entanglement: ONNX model or hardcoded groups shift phases toward group average
    |
    v
Decoherence: imaginary component decays by temporal factor (0.0-0.2)
    |
    v
Collapse: Born rule measurement -> Map<String, double> (12D classical)
```

### 14.3 Knot Theory Integration

Each personality profile generates a `PersonalityKnot` with invariants:
- **Crossing number:** Complexity of the personality structure
- **Writhe:** Directional bias (positive = extroverted tendency, negative = introverted)
- **Bridge number:** Number of "peaks" in personality (versatility)
- **Unknotting number:** How many changes needed to reach a "neutral" personality
- **Jones polynomial:** Fine-grained topological signature

**Compatibility scoring (VibeCompatibilityService):**
```
combined = 0.5 * quantum_fidelity + 0.3 * topological_knot + 0.2 * weave_stability
```

Where:
- `quantum_fidelity = |<a|b>|^2` (squared inner product of normalized 12D vectors)
- `topological_knot = braid_compatibility` (via knot math bridge)
- `weave_stability = 0.6 * crossing_similarity + 0.4 * polynomial_similarity`

### 14.4 Temporal Quantum State

Time is also represented as a quantum state:
```
|psi_temporal> = |t_atomic> tensor |t_quantum> tensor |t_phase>
```
- `|t_atomic>`: 3D precision vector (nano/milli/second)
- `|t_quantum>`: 35D temporal encoding (24 hours + 7 weekdays + 4 seasons)
- `|t_phase>`: 6D phase oscillations (daily, weekly, seasonal cycles)

Temporal compatibility: `|<psi_A|psi_B>|^2` -- users who operate on similar temporal rhythms match better.

### 14.5 Where Quantum Hardware Would Help

| Operation | Current (Classical) | Quantum Advantage |
|---|---|---|
| N-way group entanglement | Pairwise fidelities, O(N^2) | Native on QPU, exponential speedup for N >= 5 |
| Jones polynomial evaluation | Classical computation | BQP-complete -- exponential speedup |
| Entanglement pattern detection | ONNX MLP / hardcoded groups | Quantum feature maps for non-linear correlations |
| Parameter optimization | ONNX MLP / hardcoded weights | QAOA / VQE for larger parameter spaces |
| State fidelity | Inner product on float vectors | SWAP test on QPU for true quantum fidelity |
| Error correction | Classical majority voting on redundant copies | Surface codes for true quantum error protection |

---

## 15. Building the World Model: Complete Blueprint

This section provides the concrete, buildable specification for the AVRAI World Model. No images, no video, no computer vision required. The JEPA principle (predict in embedding space, not observation space) is modality-agnostic -- it works on structured numerical data the same way it works on pixels.

### 15.1 Why No Images Are Needed

I-JEPA predicts masked image patch embeddings. V-JEPA predicts future video frame embeddings. AVRAI's world model predicts **future user state embeddings**. The underlying math is identical across all three:

```
Loss = distance(predicted_embedding, actual_embedding) + regularization
```

The "world" in AVRAI is not visual. It consists of:
- A user's personality state (12D + context + history)
- Available actions (visit a spot, join a community, attend an event, skip)
- What happens when the user takes an action (their state changes)

The world model's job: given the user's current state and an action, predict what the user's state will be after taking that action. No pixels, no spatial structure. Just structured numerical data flowing through neural networks.

### 15.2 The Four Networks

The world model is composed of four small neural networks that work together. Total size: ~240K parameters, under 1MB, microsecond inference.

#### Network 1: State Encoder (~50K params)

Takes raw user state and compresses it into a latent embedding.

```
Input (structured, ~50-70 features):
├── 12D personality dimensions (from quantum vibe state, Born rule measured)
├── 6D behavioral patterns:
│   ├── activity_level (interactions per week, normalized)
│   ├── engagement_depth (average dwell time, normalized)
│   ├── visit_frequency (visits per week, normalized)
│   ├── feedback_rate (explicit feedback per visit, normalized)
│   ├── social_interaction_rate (AI2AI connections per week, normalized)
│   └── exploration_rate (new spots / total visits, normalized)
├── 12D current context:
│   ├── location_type (one-hot: downtown, suburb, park, transit, home)
│   ├── time_sin, time_cos (circular encoding of hour)
│   ├── day_sin, day_cos (circular encoding of day of week)
│   ├── season_sin, season_cos (circular encoding of season)
│   ├── energy_level (from cross-app health signal or default 0.5)
│   ├── schedule_openness (from cross-app calendar or default 0.5)
│   ├── weather_pleasantness (from weather API or default 0.5)
│   ├── battery_level (device battery, affects agent behavior)
│   └── connectivity (0.0 = offline, 0.5 = BLE only, 1.0 = full internet)
├── 10D interaction history:
│   ├── last_5_outcomes (0.0 = negative, 0.5 = neutral, 1.0 = positive)
│   ├── rolling_positive_rate (last 20 interactions)
│   ├── rolling_engagement (last 20 interactions, normalized dwell)
│   ├── hours_since_last_interaction (log-scaled)
│   ├── days_since_last_positive (log-scaled)
│   └── interaction_count_total (log-scaled)
├── 5D social context:
│   ├── nearby_agent_count (from AI2AI BLE scanning, log-scaled)
│   ├── community_activity_level (messages/events in user's communities)
│   ├── pending_event_count (upcoming events user is RSVPd to)
│   ├── recent_ai2ai_delta_magnitude (how much personality shifted recently)
│   └── mesh_connection_quality (average signal quality of nearby agents)
└── 5D trajectory state (NEW -- makes the world model meaningful):
    ├── satisfaction_trajectory (slope of last 10 outcomes: improving or declining?)
    ├── novelty_saturation (variety of spot categories in last 20 visits)
    ├── social_fulfillment (time since meaningful social interaction, inverted)
    ├── domain_diversity (entropy across spot/community/event interactions)
    └── momentum (are they in an active exploration phase or a rest phase?)

Architecture: MLP 50→256→128→64 (ReLU activations, LayerNorm after each layer)
Output: 64D latent state embedding
```

Why 64D: Large enough to capture the meaningful variation in user state (12D personality alone isn't enough -- context, history, trajectory matter). Small enough for microsecond inference and feasible on-device training.

#### Network 2: Action Encoder (~25K params)

Takes a proposed action and encodes it into the same 64D latent space as the state encoder.

```
Input (structured, ~30-40 features):
├── 5D action type (one-hot):
│   [visit_spot, join_community, attend_event, ai2ai_interact, skip/rest]
├── 12D target vibe:
│   (spot vibe, community vibe, or event vibe -- 12D personality-space embedding)
├── 5D target metadata:
│   ├── rating (normalized 0-1, from Google Places or community rating)
│   ├── price_level (normalized 0-1, from Google Places or event price)
│   ├── popularity (normalized 0-1, from review count or member count)
│   ├── distance_km (log-scaled, from user's current location)
│   └── novelty (0.0 = visited many times, 1.0 = completely new)
├── 5D social context of target:
│   ├── friends_present (count of known connections at target, log-scaled)
│   ├── community_overlap (fraction of user's community members at target)
│   ├── crowd_level (estimated crowd size relative to capacity)
│   ├── vibe_match_peers (how many nearby agents have high vibe match)
│   └── expert_present (is a golden expert at this spot/event?)
└── 5D temporal fit:
    ├── time_match (how well does current time match spot's peak hours?)
    ├── day_match (how well does current day match spot's peak days?)
    ├── schedule_fit (does user have time for this based on calendar?)
    ├── energy_match (does user's current energy match spot's energy?)
    └── recency (how recently did user visit this or similar spot?)

Architecture: MLP 32→128→64 (ReLU activations, LayerNorm)
Output: 64D latent action embedding (same space as state embedding)
```

#### Network 3: Transition Predictor -- THE World Model (~150K params)

Takes state embedding + action embedding, predicts the next state embedding.

```
Input: state_embedding (64D) ⊕ action_embedding (64D) = 128D concatenation
Architecture: MLP 128→256→256→64 (ReLU, LayerNorm, Dropout 0.1)
             WITH RESIDUAL CONNECTION from state_embedding
Output: predicted_next_state_embedding (64D)

The residual connection is critical:
    predicted_next_state = state_embedding + delta_network(concat(state, action))

Why residual: Most of a user's state stays the same after one action.
Visiting a coffee shop doesn't change 90% of your personality. The network
only needs to learn the CHANGE (delta), not reconstruct the entire state.
This makes training dramatically easier and predictions more stable.
```

**Prediction horizon:** One action step. The planning loop (Section 15.5) chains multiple predictions for trajectory simulation.

**Uncertainty output (optional, for Section 7.4.4):** Add a second head that predicts the variance of the next-state embedding. This outputs 64D of log-variance values. The transition predictor becomes a conditional Gaussian: `N(predicted_mean, exp(predicted_logvar))`. Sampling from this distribution with different random seeds produces different plausible futures.

#### Network 4: Critic / Unified Energy Function (~15K params)

Takes a state embedding and scores how good that state is for the user.

```
Input: state_embedding (64D)
Architecture: MLP 64→128→64→1 (ReLU, no output activation)
Output: scalar energy (lower = better state for the user)

This replaces ALL domain-specific scoring functions:
  - Calling score (spot recommendation quality)
  - Outcome prediction (will the experience be positive?)
  - Community compatibility (how well does user fit this community?)
  - Event matching (should user attend this event?)

All unified into one learned function that evaluates ANY predicted state.
```

**Training the critic:** The critic learns from outcome data. States where the user reported positive outcomes get low energy. States where outcomes were negative get high energy. The energy function learns what "good for this user" means from behavior, not from hand-crafted formulas.

**Guardrail integration:** The guardrail cost functions (Section 7.4.3) are added to the critic's energy but are NOT learned -- they're fixed, immutable penalty terms:

```
total_energy = critic_energy(state) + guardrail_cost(state, action)
```

The critic can be retrained. The guardrails cannot. This is how "doors, not badges" becomes architectural.

### 15.3 Training Data: Three Sources

The world model needs `(state, action, next_state)` tuples. No labels, no images, no classification targets.

#### Source 1: Simulated Trajectories (Available Immediately)

Use the existing formula-based system to simulate user journeys:

```python
# Pseudocode for trajectory generation
for user_profile in big_five_to_spots_profiles(n=10000):
    state = initialize_state(user_profile)

    for step in range(100):  # 100 actions per trajectory
        # Generate available actions from spot vibes + communities + events
        available_actions = generate_candidates(state, spot_vibes, communities, events)

        # Score with existing formula system
        scores = [calling_score_formula(state, action) for action in available_actions]

        # Pick action probabilistically (softmax on scores)
        chosen_action = sample(available_actions, weights=softmax(scores, temperature=0.5))

        # Compute next state using PersonalityLearning rules
        next_state = evolve_personality(state, chosen_action, outcome=sample_outcome(score))

        # Update context (time advances, location shifts, history updates)
        next_state = update_context(next_state, chosen_action)

        # Record training sample
        record(state, chosen_action, next_state)

        state = next_state

# Result: 10,000 users × 100 steps = 1,000,000 (state, action, next_state) samples
```

**Inputs available now:**
- 100K+ Big Five profiles converted to SPOTS 12D (from `load_and_convert_big_five_to_spots()`)
- Real spot vibes from OSM/Google Places pipeline (once run)
- Synthetic spot vibes (already in training data)
- `PersonalityLearning.evolveFromUserAction()` rules (already implemented in Dart, can be ported to Python)
- `CallingScoreCalculator` formula (already implemented in both Python and Dart)

**Generation time:** ~5-10 minutes on a MacBook CPU. No GPU needed. The formula system runs in microseconds per step.

#### Source 2: Bootstrapped from Existing Training Data (Available Immediately)

For each of the 100K existing training samples:

```python
for (user_state, spot_vibe, context, calling_score) in existing_training_data:
    action = encode_action(spot_vibe, context)

    if calling_score > 0.7:  # User "visits" (above threshold)
        # Positive visit: personality evolves based on spot characteristics
        next_state = apply_positive_visit_evolution(user_state, spot_vibe)
    elif calling_score > 0.4:  # User considers but skips
        # Near-miss: tiny shift toward curiosity/FOMO
        next_state = apply_near_miss_evolution(user_state, spot_vibe)
    else:  # User doesn't engage
        # Skip: state unchanged except time context advances
        next_state = advance_time_context(user_state)

    record(state=user_state, action=action, next_state=next_state)
```

#### Source 3: Real User Interactions (Future, Highest Value)

Once users interact with the app, every interaction IS a training sample:

```
1. Before interaction: snapshot user state (personality + context + history)
2. User takes action (visits spot, joins community, attends event, skips)
3. After interaction: snapshot user state again
4. Record: (state_before, action, state_after) to episodic memory
5. World model fine-tunes on these real transitions on-device
```

The `CallingScoreDataCollector` already captures user state + spot + outcome. The `ContinuousLearningSystem` already computes personality evolution via `PersonalityLearning.evolveFromUserAction()`. The gap: recording the full `(state_before, action, state_after)` triple to structured episodic memory.

### 15.4 Training Loop: Self-Supervised with VICReg

```python
# Training loop pseudocode
for epoch in range(num_epochs):
    for batch in data_loader:
        state, action, next_state_actual = batch

        # Forward pass
        state_emb = state_encoder(state)
        action_emb = action_encoder(action)
        next_state_emb_predicted = transition_predictor(state_emb, action_emb)
        next_state_emb_actual = state_encoder(next_state_actual)  # Target

        # ---- Loss computation ----

        # 1. Prediction loss (invariance): predicted ≈ actual
        prediction_loss = MSE(next_state_emb_predicted, next_state_emb_actual.detach())

        # 2. Variance regularization: each embedding dimension must have variance > threshold
        #    Prevents collapse to trivial solution (everything maps to same point)
        var_loss = variance_regularization(next_state_emb_predicted, gamma=1.0)
        var_loss += variance_regularization(state_emb, gamma=1.0)

        # 3. Covariance regularization: embedding dimensions should be decorrelated
        #    Prevents redundancy (two dimensions encoding the same thing)
        cov_loss = covariance_regularization(next_state_emb_predicted)
        cov_loss += covariance_regularization(state_emb)

        # 4. Critic loss: train energy function from outcome labels (when available)
        if has_outcome_labels:
            energy = critic(next_state_emb_predicted)
            critic_loss = MSE(energy, -outcome_score)  # Lower energy = better outcome

        # Combined loss
        total_loss = (
            25.0 * prediction_loss    # Main objective
            + 25.0 * var_loss         # Prevent collapse
            + 1.0 * cov_loss          # Decorrelation
            + 10.0 * critic_loss      # Learn energy landscape
        )

        total_loss.backward()
        optimizer.step()
```

**VICReg loss weights** (25-25-1) are from Bardes et al. 2022 (Meta AI). The variance term prevents the trivial solution where everything maps to the same embedding. The covariance term ensures each dimension carries unique information. Together they replace the EMA target encoder that I-JEPA uses, and are simpler to implement.

**No images, no masking, no spatial attention.** Pure tabular neural networks with a self-supervised loss. This trains on the same hardware that trained the existing ONNX models.

**Training compute:**
- 240K parameters total
- 1M training samples, batch size 256 → ~4000 batches/epoch
- ~10 epochs to convergence
- **~5 minutes on a MacBook CPU, ~30 seconds on MacBook GPU**
- No cloud GPUs needed

### 15.5 Planning: How the World Model Makes Decisions

Once trained, the agent plans by simulating futures:

```
function plan_recommendation(current_state, available_actions, depth=2):
    state_emb = state_encoder.encode(current_state)

    best_action = null
    best_energy = infinity

    for each action in available_actions:
        action_emb = action_encoder.encode(action)

        # Step 1: predict what happens if user takes this action
        next_state_emb = transition_predictor.predict(state_emb, action_emb)
        energy_1 = critic.evaluate(next_state_emb) + guardrail_cost(next_state_emb, action)

        # Step 2: look ahead one more step (optional, for trajectory planning)
        if depth >= 2:
            best_follow_up_energy = infinity
            for each follow_up in top_k_likely_actions(next_state_emb, k=5):
                follow_emb = action_encoder.encode(follow_up)
                state_2 = transition_predictor.predict(next_state_emb, follow_emb)
                energy_2 = critic.evaluate(state_2) + guardrail_cost(state_2, follow_up)
                best_follow_up_energy = min(best_follow_up_energy, energy_2)

            total_energy = energy_1 + 0.9 * best_follow_up_energy  # 0.9 = discount factor
        else:
            total_energy = energy_1

        if total_energy < best_energy:
            best_energy = total_energy
            best_action = action

    return best_action, best_energy
```

**Performance analysis:**
- 20 candidate spots × 1 forward pass each = 20 forward passes for 1-step
- 20 candidates × 5 follow-ups each = 120 forward passes for 2-step
- Each forward pass: ~50 microseconds (matrix multiply chain through 240K params)
- **Total 2-step planning time: ~6 milliseconds**
- Compare: SLM generating 50 reasoning tokens × 20 spots = 1000 tokens = ~125 seconds at 8 tok/s
- **The world model is ~20,000x faster than SLM-based reasoning**

### 15.6 On-Device Deployment

All four networks export to ONNX and run via the existing `onnxruntime_flutter` infrastructure:

```
assets/models/world_model/
├── state_encoder.onnx         (~200KB)
├── action_encoder.onnx        (~100KB)
├── transition_predictor.onnx  (~600KB)
└── critic.onnx                (~60KB)
                         Total: ~960KB (<1MB)
```

**Dart integration point:** A new `WorldModelAgent` service that:
1. Loads all 4 ONNX models on app start
2. Encodes current user state on each trigger event (app open, location change, timer)
3. Runs planning loop over available spots/communities/events
4. Returns ranked recommendations with predicted trajectories
5. Records actual outcomes to episodic memory for on-device fine-tuning

**Replaces vs. augments existing system:**
The world model does NOT replace the existing calling score formula immediately. It runs in parallel:
- Formula system: production, battle-tested, interpretable
- World model: shadow mode, predictions logged but not shown to user
- Once world model predictions correlate better with outcomes than the formula, gradually increase its weight (like the current 70/30 formula/neural blend)

### 15.7 On-Device Learning (World Model Self-Improvement)

The world model improves from every interaction without server-side retraining:

**Level 1: Memory-based improvement (immediate, no weight updates)**

The agent accumulates episodes in local SQLite. When planning, it retrieves similar past episodes and adjusts predictions. The model weights don't change, but behavior improves because input context is richer.

```dart
class EpisodicMemory {
  final Database _db;

  Future<void> recordEpisode(Episode episode) async {
    // Store: state_before, action, state_after, outcome, timestamp
    await _db.insert('episodes', episode.toMap());
  }

  Future<List<Episode>> retrieveSimilar(StateEmbedding current, {int limit = 5}) async {
    // Nearest-neighbor search on state embeddings
    // Returns most similar past experiences for context
  }
}
```

**Level 2: Bias overlay (already exists, extend to world model)**

The `OnnxDimensionScorer.updateWithDeltas()` pattern extends to the world model's critic. After each outcome, adjust the critic's output bias:

```
If predicted energy was -0.8 (good) but actual outcome was negative:
    critic_bias += 0.05  (shift toward predicting worse outcomes for similar states)
```

Bounded at +-0.20, same safeguards as the existing bias overlay system.

**Level 3: On-device gradient updates (feasible on modern phones)**

During overnight charging, run a few gradient steps on the transition predictor using accumulated episodic memory:

```
For each recent episode (state_before, action, state_after):
    predicted = transition_predictor(encode(state_before), encode(action))
    actual = encode(state_after)
    loss = MSE(predicted, actual)
    loss.backward()  # Compute gradients for transition predictor only
    optimizer.step() # Update transition predictor weights

    # Apply to ONNX model via weight replacement
```

**Memory requirements:** The transition predictor is 150K params. Training requires ~2x for gradients = 300K floats = 1.2MB. Well within any modern phone's capability.

**When it runs:** Only during charging + WiFi + idle. Uses `WorkManager` (Android) or `BGTaskScheduler` (iOS) for background execution. Typical session: 50-100 episodes, ~30 seconds of compute.

### 15.8 Federated World Model Learning

World model improvements propagate through two channels:

**Channel 1: Transition predictor weight deltas (via federated-sync)**

```
1. Agent trains transition predictor on local episodes (on-device, overnight)
2. Compute delta: new_weights - old_weights
3. Add calibrated Laplace noise (epsilon = 1.0) to delta
4. Clip delta to max L2 norm (prevents outlier leakage)
5. Submit noisy clipped delta to federated-sync edge function
6. Server averages deltas from N agents
7. Averaging further reduces noise by sqrt(N) factor
8. Aggregated delta pushed to all agents
9. Each agent applies: local_weights += learning_rate * aggregated_delta
```

This is mathematically identical to how Google trains Gboard's keyboard prediction and Apple trains Siri's on-device models. The privacy guarantees are formal: (epsilon, delta)-differential privacy with epsilon = 1.0 per round.

**Channel 2: Critic calibration via AI2AI mesh**

When two agents connect via BLE, they exchange compressed critic calibration data:

```dart
class CriticCalibration {
  final String spotCategory;   // "coffee", "nightlife", "nature" (not specific spot ID)
  final String cityRegion;     // "downtown", "midtown" (not exact location)
  final double predictedEnergy;
  final double actualOutcome;
  final double calibrationError; // predicted - actual
}
```

This tells other agents: "my critic was off by X for this category of spot in this region." Agents in the same area learn from each other's calibration errors without sharing any personal data.

### 15.9 What Makes This Different from the Existing ONNX Models

| Property | Current ONNX Models | World Model |
|---|---|---|
| **Question answered** | "Is this spot good for this user?" | "If this user visits this spot, what happens to them?" |
| **Output** | Single score (0.0-1.0) | Predicted future state (64D embedding) |
| **Planning capability** | None (one-shot scoring) | Multi-step trajectory simulation |
| **Cross-domain** | Separate models per domain | Unified: spots, communities, events in same space |
| **Learning** | Static after training | Continuous on-device improvement |
| **Uncertainty** | Point estimate only | Distribution over possible futures (with variance head) |
| **Guardrails** | None (policy only) | Immutable cost functions in planning loop |
| **Size** | 38K params total (~50KB) | 240K params total (~1MB) |
| **Inference speed** | ~50μs per prediction | ~6ms for full 2-step plan over 20 candidates |
| **Training data** | Labeled (score/outcome) | Self-supervised (predict next state) |

### 15.10 The Quantum Connection

The world model and quantum vibe engine are not competing architectures -- they're complementary layers:

| Quantum Concept | World Model Role |
|---|---|
| Quantum vibe state (complex amplitudes) | **Input representation** to the state encoder. Richer than 12 floats because phase encodes directionality. |
| Superposition | **Multi-hypothesis prediction.** The variance head on the transition predictor outputs a distribution -- this IS superposition in latent space. Multiple possible futures coexist until an action collapses them. |
| Entanglement | **Correlated latent dimensions.** The state encoder learns which embedding dimensions are correlated for each user. This is empirical entanglement -- discovered from data, not assumed. |
| Interference | **Trajectory composition.** When planning multi-step trajectories, some action sequences amplify each other (constructive) while others cancel out (destructive). The energy landscape captures this. |
| Decoherence | **Prediction uncertainty increasing with horizon.** The further ahead the world model predicts, the more the variance head reports uncertainty. This is temporal decoherence -- certainty about the future decays with distance. |
| Measurement / collapse | **Decision.** The planning loop evaluates all candidate futures and picks the lowest-energy one. This collapses the superposition of possible actions into a single recommendation. |
| Born rule | **Energy → probability.** `P(outcome) = exp(-E) / Z` converts critic energy to outcome probability, exactly as `|ψ|² = probability` converts amplitude to probability. |

The quantum math provides the representation. The world model provides the dynamics. Together: a quantum-native world model where personality states are quantum states and predictions operate on quantum amplitudes rather than classical floats.

### 15.11 Concrete Build Steps

**Step 1: Data generation** (~1 day)
- Port `PersonalityLearning.evolveFromUserAction()` logic to Python
- Write `scripts/ml/generate_trajectory_data.py`
- Generate 1M+ (state, action, next_state) samples from simulated trajectories
- Use real Big Five profiles + real/synthetic spot vibes

**Step 2: Model training** (~2-3 days)
- Write `scripts/ml/train_world_model.py`
- Implement state encoder, action encoder, transition predictor, critic
- Implement VICReg loss (variance + invariance + covariance)
- Train on trajectory data, validate on held-out trajectories
- Export all 4 models to ONNX
- Validate: prediction error on test trajectories, embedding quality metrics

**Step 3: Dart inference integration** (~2-3 days)
- Create `lib/core/ai/agent/world_model_service.dart`
- Load 4 ONNX models via existing OrtSession infrastructure
- Implement state encoding, action encoding, prediction, and planning
- Shadow mode: run alongside formula system, log predictions without affecting recommendations
- Register in DI (`injection_container.dart`)

**Step 4: Episodic memory** (~1-2 days)
- Create `lib/core/ai/agent/episodic_memory.dart`
- SQLite-backed episode storage with state_before, action, state_after, outcome
- Nearest-neighbor retrieval for context during planning
- Wire into `ContinuousLearningSystem.processUserInteraction()` to record episodes

**Step 5: Planning loop** (~2-3 days)
- Create `lib/core/ai/agent/agent_planner.dart`
- Implement 1-step and 2-step lookahead
- Integrate guardrail cost functions
- Wire into recommendation pipeline (parallel to formula system)
- A/B test infrastructure: formula-only vs. formula+worldmodel vs. worldmodel-only

**Step 6: On-device learning** (~2-3 days)
- Implement overnight bias overlay updates for critic
- Implement background gradient updates for transition predictor
- Wire federated delta sharing for world model weights
- Battery/charging/WiFi guards for background training

**Total estimated effort: 10-15 days**

---

## 16. On-Device AI Agent Architecture

This section describes how the world model, memory system, existing ML models, and communication layer compose into a complete on-device AI agent for each user.

### 16.1 What Makes It an Agent (Not Just Models)

An agent has four properties that a collection of ML models doesn't:

1. **Autonomous reasoning loop** -- it observes, plans, acts, and reflects. Continuously, without being asked. Not just "user taps button → model runs → number appears."
2. **Persistent memory** -- it remembers what happened, what worked, what didn't, and builds an increasingly accurate model of the user over months and years.
3. **Tool use** -- it orchestrates existing models, services, and data sources as tools within a coherent decision-making framework.
4. **Self-directed learning** -- it improves without being centrally retrained. New experiences change its behavior. Federated learning and AI2AI mesh expand its knowledge beyond individual experience.

### 16.2 Complete Agent Architecture

```
┌───────────────────────────────────────────────────────────┐
│           ON-DEVICE AI AGENT (per user)                   │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  PERCEPTION (State Encoder)                         │  │
│  │  Raw signals → 64D latent state embedding           │  │
│  │  Sources: personality, context, history, social,    │  │
│  │           trajectory, cross-app signals             │  │
│  │  ~50K params, <200KB                                │  │
│  └────────────────────┬────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  WORLD MODEL (Transition Predictor)                 │  │
│  │  state_emb + action_emb → predicted_next_state_emb  │  │
│  │  Plans by simulating multiple futures in parallel   │  │
│  │  With residual connection (learns deltas, not full  │  │
│  │  state reconstruction)                              │  │
│  │  ~150K params, <600KB                               │  │
│  └────────────────────┬────────────────────────────────┘  │
│                       │                                   │
│  ┌──────────┐  ┌──────▼──────┐  ┌──────────────────────┐ │
│  │  ACTOR   │  │   CRITIC    │  │  CONFIGURATOR        │ │
│  │          │  │  (Unified   │  │  (≈ Quantum Opt      │ │
│  │ Proposes │  │   Energy    │  │   Model, extended)   │ │
│  │ actions  │  │   Function) │  │  Adjusts all modules │ │
│  │ across   │◄─│             │  │  per user + task     │ │
│  │ all      │  │  + Guardrail│  │                      │ │
│  │ domains  │  │  cost fns   │  │  Existing: Quantum   │ │
│  │          │  │  (immutable)│  │  Optimization Model  │ │
│  │ Spots    │  │             │  │  (superposition wts, │ │
│  │ Communit.│  │  ~15K params│  │   threshold, basis)  │ │
│  │ Events   │  │  <60KB      │  │  ~3.5K params        │ │
│  │ AI2AI    │  │             │  │                      │ │
│  │ Rest     │  │             │  │                      │ │
│  └──────────┘  └─────────────┘  └──────────────────────┘ │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  MEMORY SYSTEM                                      │  │
│  │                                                     │  │
│  │  Working Memory (RAM -- current session)            │  │
│  │  ├── Current state embedding                        │  │
│  │  ├── Recent observations (last 5 minutes)           │  │
│  │  ├── Active plan (current recommendation sequence)  │  │
│  │  └── Cleared when app backgrounds                   │  │
│  │                                                     │  │
│  │  Episodic Memory (SQLite -- experiences)            │  │
│  │  ├── Every meaningful interaction as structured     │  │
│  │  │   episode: (state, action, next_state, outcome)  │  │
│  │  ├── Queryable by similarity (nearest-neighbor)     │  │
│  │  ├── Agent reflection: 1-sentence summary per       │  │
│  │  │   episode (optional, from SLM if available)      │  │
│  │  └── Pruned during nightly consolidation            │  │
│  │                                                     │  │
│  │  Semantic Memory (vector store -- knowledge)        │  │
│  │  ├── Compressed generalizations from episodes       │  │
│  │  │   "User enjoys high-curation spots on weekends"  │  │
│  │  ├── Stored as embeddings, retrieved semantically   │  │
│  │  ├── Built from: StructuredFactsIndex (existing)    │  │
│  │  │   + learned patterns from episodic memory        │  │
│  │  └── Updated during nightly consolidation           │  │
│  │                                                     │  │
│  │  Procedural Memory (rules -- strategies)            │  │
│  │  ├── If-then rules extracted from episode patterns  │  │
│  │  │   "When novelty_saturation > 0.8 AND energy     │  │
│  │  │    is moderate, novel exploration spots          │  │
│  │  │    outperform familiar comfort spots by 23%"     │  │
│  │  ├── Used as heuristics in the planning loop        │  │
│  │  └── Updated during nightly consolidation           │  │
│  └─────────────────────────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  PERSONALITY CORE (existing, enhanced)              │  │
│  │  ├── 12D Quantum Vibe State (complex amplitudes)    │  │
│  │  ├── Knot Topology (Jones polynomial, invariants)   │  │
│  │  ├── Behavioral patterns (from ContinuousLearning)  │  │
│  │  ├── Entanglement patterns (from ONNX model)        │  │
│  │  └── All feed into State Encoder as input features  │  │
│  └─────────────────────────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  SKILL MODELS (existing ONNX, used as tools)        │  │
│  │  ├── CallingScoreModel (spot scoring, 39→1)         │  │
│  │  ├── OutcomePredictionModel (outcome gating, 45→1)  │  │
│  │  ├── QuantumOptimizationModel (parameter tuning)    │  │
│  │  ├── EntanglementDetectionModel (pair correlations) │  │
│  │  └── These are TOOLS the agent calls, not the brain │  │
│  └─────────────────────────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  LANGUAGE MODULE (SLM, 1-3B, OPTIONAL)              │  │
│  │  NOT the brain. An interface to the brain.          │  │
│  │  Used for:                                          │  │
│  │  ├── Explaining recommendations to the user         │  │
│  │  │   ("I think you'd love this because...")         │  │
│  │  ├── Onboarding conversation                        │  │
│  │  ├── Agent-to-agent negotiation (when structured    │  │
│  │  │   protocols aren't sufficient)                   │  │
│  │  └── Complex reasoning that world model can't do    │  │
│  │  Only activates when needed. World model handles    │  │
│  │  95% of decisions without language.                  │  │
│  │  ~1-3B params, 700MB-2GB (downloaded separately)    │  │
│  └─────────────────────────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  LEARNING ENGINE                                    │  │
│  │  ├── Memory-based: episodes improve planning        │  │
│  │  │   context (immediate, no weight updates)         │  │
│  │  ├── Bias overlay: critic output adjustments        │  │
│  │  │   (after each outcome, bounded +-0.20)           │  │
│  │  ├── On-device training: gradient updates to        │  │
│  │  │   transition predictor during overnight charging │  │
│  │  ├── Personality evolution: existing system          │  │
│  │  │   (PersonalityLearning + ONNX bias overlay)     │  │
│  │  └── Nightly consolidation: compress episodes →     │  │
│  │      semantic memory, extract procedural rules,     │  │
│  │      prune old episodes                             │  │
│  └─────────────────────────────────────────────────────┘  │
│                       │                                   │
│  ┌────────────────────▼────────────────────────────────┐  │
│  │  COMMUNICATION LAYER                                │  │
│  │                                                     │  │
│  │  AI2AI Mesh (BLE proximity):                        │  │
│  │  ├── Share: compressed critic calibration data      │  │
│  │  │   (category + region + calibration error)        │  │
│  │  ├── Share: personality embedding deltas            │  │
│  │  │   (existing 12D, 22% threshold, bounded)        │  │
│  │  ├── Share: compressed experience insights          │  │
│  │  │   (generalized patterns, not raw episodes)       │  │
│  │  └── Negotiate: group activities between agents     │  │
│  │      (matching scores, availability, preferences)   │  │
│  │                                                     │  │
│  │  Federated Sync (Supabase edge function):           │  │
│  │  ├── Share: DP-noised transition predictor deltas   │  │
│  │  ├── Share: DP-noised critic weight deltas          │  │
│  │  ├── Share: anonymized outcome data for retraining  │  │
│  │  └── Receive: aggregated model improvements         │  │
│  │                                                     │  │
│  │  Privacy guarantees:                                │  │
│  │  ├── All shared data uses agent_id (not user_id)    │  │
│  │  ├── Laplace noise on all weight deltas (ε=1.0)     │  │
│  │  ├── No raw episodes or personal data ever shared   │  │
│  │  ├── Spot/event IDs generalized to category+region  │  │
│  │  └── Cumulative privacy budget tracked per window   │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  TOTAL ON-DEVICE FOOTPRINT:                               │
│  ├── World model (4 ONNX models):     ~1MB                │
│  ├── Existing skill models (4 ONNX):  ~50KB               │
│  ├── Episodic memory (SQLite):         ~5-50MB over time   │
│  ├── Semantic memory (vector store):   ~1-5MB              │
│  ├── Optional SLM:                     700MB-2GB           │
│  └── Total without SLM:               ~10-60MB             │
│      Total with SLM:                  ~710MB-2.1GB         │
│                                                           │
│  INFERENCE PERFORMANCE:                                   │
│  ├── Full planning loop (20 spots, 2-step): ~6ms          │
│  ├── Single prediction:                     ~50μs          │
│  ├── Compare: SLM reasoning for same task:  ~125 seconds   │
│  └── World model is ~20,000x faster than SLM reasoning    │
└───────────────────────────────────────────────────────────┘
```

### 16.3 Agent Trigger System

The agent does NOT run continuously (battery death). It activates on events:

| Trigger | What Happens | Frequency |
|---|---|---|
| App opened | Full planning cycle: encode state, plan over all candidates, present recommendations | ~5-15x/day |
| Significant location change | Re-plan with new location context, check nearby spots/events | ~5-20x/day |
| Timer (active hours only) | Background check: any high-energy opportunities nearby? | Every 2 hours |
| AI2AI connection established | Exchange insights, update critic calibration, check group activity potential | Varies (~0-10x/day) |
| Community/event notification | Evaluate notification against current plan, decide whether to surface | Varies |
| Calendar event approaching | Check if preparation or alternative suggestion is appropriate | ~0-5x/day |
| Overnight (charging + WiFi) | Memory consolidation, on-device training, federated sync | 1x/day |

Between triggers, the agent sleeps. Each activation: 1-5 reasoning steps, ~6-30ms total compute, negligible battery impact.

### 16.4 Device Capability Tiers

Not every phone can run every component. The agent gracefully degrades:

| Tier | Device Example | Components Available |
|---|---|---|
| **Tier 3 (Full)** | iPhone 15 Pro+, Pixel 8 Pro+ | World model + SLM + all memory + federated learning + on-device training |
| **Tier 2 (Standard)** | iPhone 13+, Pixel 7+ | World model + all memory + federated learning. No SLM, no on-device training. |
| **Tier 1 (Basic)** | iPhone 11+, Pixel 5+ | Existing ONNX models + episodic memory + bias overlay learning. No world model. |
| **Tier 0 (Minimal)** | Older devices | Formula-only calling score. No ONNX models. Rule-based personality evolution. |

The existing `on_device_ai_capability_gate.dart` already performs device capability checks. Extend it:

```dart
enum AgentCapabilityTier {
  full,      // World model + SLM + on-device training
  standard,  // World model + memory + federated learning
  basic,     // ONNX models + episodic memory + bias overlay
  minimal,   // Formula-only, rule-based evolution
}
```

Every user gets an AI agent. The agent's capabilities scale with their device. The core experience (recommendations that improve over time) works on all tiers.

### 16.5 What Existing AVRAI Infrastructure Maps To

| Agent Component | Existing AVRAI Code | Gap |
|---|---|---|
| Perception (state encoder) | `CallingContext`, `TimingFactors`, `PersonalityLearning` | Need to train encoder network, currently hand-crafted features |
| World model | `PersonalityLearning.evolveFromUserAction()` (rule-based) | Need trained transition predictor that replaces rules with learned dynamics |
| Critic | `CallingScoreCalculator`, `OutcomePredictionService`, `VibeCompatibilityService` | Need unified energy function that replaces 3+ separate scorers |
| Configurator | `QuantumMLOptimizer` (adjusts superposition weights per user/task) | Already functional, extend to configure world model parameters |
| Working memory | `CallingContext` + sensor data | Consolidate into `WorkingMemory` class |
| Episodic memory | Nothing structured | **Build from scratch** -- SQLite-backed episode storage |
| Semantic memory | `StructuredFactsIndex` (basic key-value) | Need vector embeddings for semantic retrieval |
| Procedural memory | Nothing | **Build from scratch** -- learned strategy rules |
| Memory consolidation | Nothing | **Build from scratch** -- nightly episode → knowledge compression |
| Skill models (tools) | 4 ONNX models, all functional | Keep as-is, used as tools by the agent |
| Language module | `mlc_llm` running Qwen 2.5 3B / Llama 3.2 1B | Used as JSON structural formatter and natural language translator, not as a brain |
| Learning engine | `ContinuousLearningSystem`, `OnnxDimensionScorer.updateWithDeltas()` | Extend with on-device gradient updates for world model |
| AI2AI communication | `EmbeddingDelta`, `FederatedLearningHooks`, `ConnectionOrchestrator` | Extend to share critic calibration + world model deltas |
| Trigger system | `ContinuousLearningOrchestrator` (1s polling timer) | Replace with event-driven triggers (battery-efficient) |
| Capability gate | `on_device_ai_capability_gate.dart` | Extend with `AgentCapabilityTier` enum |

### 16.6 Agent-to-Agent Communication (Evolution of AI2AI)

The current AI2AI layer exchanges 12D personality deltas. For agent-to-agent communication, extend to three data types:

**Type 1: Personality deltas (existing)**
```dart
// Already implemented
class EmbeddingDelta {
  final Map<String, double> dimensionDeltas; // 12D, bounded +-0.20
}
```

**Type 2: Experience insights (new)**
```dart
class AgentInsight {
  final String category;        // "coffee_spots", "nightlife", "nature"
  final String region;          // "downtown", "midtown" (not exact location)
  final String generalization;  // "high_curation_morning_positive"
  final double confidence;      // 0.0-1.0
  final int evidenceCount;      // How many episodes support this
  final DateTime timestamp;
}
```

When agents connect, they share generalizations, not raw episodes. Agent A learns "coffee spots on weekend mornings tend to be positive for similar personality profiles" without learning anything about Agent B's specific visits.

**Type 3: Group negotiation (new)**
```dart
class GroupProposal {
  final String proposedActivityType;  // "spot_visit", "event_attend"
  final String category;              // "coffee", "music", "outdoor"
  final String timeWindow;            // "saturday_evening"
  final double compatibilityScore;    // How well this matches both agents
  final Map<String, double> vibeProfile; // 12D vibe of proposed activity
}
```

When agents detect high entanglement scores between their users, they negotiate group activities:
1. Agent A: "My user is free Saturday evening, moderate energy, prefers intimate spots"
2. Agent B: "My user is free Saturday evening, high energy, open to exploration"
3. Both agents run world model planning for joint activities
4. Negotiate: find the action with lowest combined energy for both users
5. Both users get a suggestion: "Want to check out this wine bar Saturday?"

This is genuinely novel. No existing app has agents that plan social activities on behalf of users while keeping all personal data on-device.

---

## 17. Priority Roadmap

### Tier 1: Highest ROI, Do Now

| # | Action | Why | Effort |
|---|---|---|---|
| 1 | Run OSM spot data pipeline, retrain models on real spots | Every downstream model improves | 1 day |
| 2 | Wire FeedbackProcessor to ContinuousLearningSystem | Explicit user feedback is the strongest learning signal | 1-2 days |
| 3 | Build monthly batch retraining pipeline from Supabase data | Closes the feedback loop -- models learn from real outcomes | 2-3 days |
| 4 | Add community_join and event_attend as interaction types | Enables cross-domain learning | 1 day |
| 5 | Round-trip consistency test (Python vs. Dart feature extraction) | Prevents silent inference bugs | 0.5 day |

### Tier 2: Meaningful Improvements

| # | Action | Why | Effort |
|---|---|---|---|
| 6 | Add cross-features (user_i * spot_i products) to calling score model | Free accuracy improvement, no architecture change needed | 1 day |
| 7 | Calibration testing + temperature scaling | Ensures prediction probabilities are meaningful | 1 day |
| 8 | Stratified evaluation by user type, spot category, time | Reveals where model fails | 0.5 day |
| 9 | Generalize opportunity_id before cloud upload | Privacy hardening | 0.5 day |
| 10 | Fix CloudIntelligenceSync user_id -> agent_id | Privacy leak | 0.5 day |
| 11 | Activate Laplace noise, track privacy budget | Formal DP guarantees | 1 day |

### Tier 3: Competitive Upgrades

| # | Action | Why | Effort |
|---|---|---|---|
| 12 | Train entanglement model on real outcome correlations | Learned (not heuristic) personality structure | 2-3 days |
| 13 | Multi-task learning (calling score + outcome prediction shared encoder) | Better representations from dual supervision | 2-3 days |
| 14 | Category affinity tracking across spot/community/event | Explicit cross-domain signal | 2-3 days |
| 15 | Implement account deletion + data export | GDPR compliance | 3-5 days |
| 16 | Two-tower user/spot embedding model | Scalable, industry-standard architecture | 1-2 weeks |

### Tier 4: Quantum / String Theory Frontier

| # | Action | Why | Effort |
|---|---|---|---|
| 17 | Connect CloudQuantumBackend to IBM Quantum for Jones polynomial evaluation | First real quantum advantage | 1-2 weeks |
| 18 | Validate N-way group entanglement on quantum hardware | Exponential speedup for large groups | 1-2 weeks |
| 19 | Add Alexander + HOMFLYPT polynomials to knot invariants | Richer topological signatures (note: Section 5 flags this as partial-fail under LeCun -- more hand-crafting) | 1 week |
| 20 | Use worldsheet evolution data as calling score features | Temporal personality trajectory prediction | 1-2 weeks |
| 21 | QAOA for quantum parameter optimization | Replace heuristic labels with quantum-optimized parameters (note: Section 5 flags this as wrong-level optimization under LeCun) | 2-3 weeks |

### Tier 5: World Model Architecture (from LeCun Framework)

This tier represents the paradigm shift from "score individual items" to "predict state evolution and plan trajectories." Items are ordered by dependency -- each builds on the previous. This tier addresses the fundamental architectural gaps identified in Section 5.4 and 11.5.

**Prerequisites:** Tier 1 items 1-3 (real data + feedback loop) must be complete before training any world model, because world models trained on synthetic data would learn synthetic dynamics rather than real human behavior.

| # | Action | Section | Why | Effort | Depends On |
|---|---|---|---|---|---|
| 22 | **Personality State Transition Model** | 7.4.1 | Foundation world model: predicts how user personality evolves after each action. Transforms system from reactive to predictive. Required for everything below. | 1-2 weeks | Tier 1 (#1-3) |
| 23 | **Guardrail Objectives as Cost Functions** | 7.4.3 | Makes "doors, not badges" and "no gamification" architectural rather than policy. Immutable constraints in the recommendation loop. Can be built independently of the world model but required before MPC. | 1 week | None (can start now) |
| 24 | **Model-Predictive Control for Recommendations** | 7.4.2 | Plans recommendation *sequences* optimized for long-term outcomes. Architecturally implements the Spots -> Community -> Life journey. This is the single biggest paradigm upgrade. | 2-3 weeks | #22 + #23 |
| 25 | **Latent Variables for Uncertainty** | 7.4.4 | Predictions become distributions, not point estimates. Enables confidence-aware recommendations and risk-adjusted planning. | 1-2 weeks | #22 |
| 26 | **Energy-Based Compatibility Function** | 7.4.5 | Replaces hand-crafted `0.5*quantum + 0.3*topological + 0.2*weave` with a learned energy function trained with VICReg regularization. Preserves quantum state inputs but makes the compatibility scoring learnable. | 2-3 weeks | Tier 1 (#1-3) |
| 27 | **System 1/System 2 Compilation** | 7.4.7 | Distills MPC planner's decisions into fast reactive ONNX model. 95% of recommendations are instant; 5% (high-stakes) use deliberate planning. | 2-3 weeks | #24 |
| 28 | **AI2AI World Model** | 7.4.8 | Predicts conversation outcomes before they happen. AI plans what topics to explore with each peer for maximum learning value. | 2-3 weeks | #22 |
| 29 | **JEPA for Personality Representation** | 7.4.6 | Self-supervised learning discovers optimal personality embedding dimensions from behavior data. Parallel to hand-crafted 12D (used for UI), optimized for prediction. Most ambitious item. | 3-4 weeks | Tier 1 (#1-3) + substantial real user data |

**Total Tier 5 effort:** ~15-22 weeks if sequential, ~8-12 weeks with parallelism (#23 and #26 can start immediately; #25 and #28 can parallel #24; #29 is independent).

**Expected impact:** Transforms AVRAI from a recommendation system (scores items) into an intelligent planning system (plans trajectories toward meaning). This is the architectural leap that connects the current ML infrastructure to the SPOTS philosophy of opening doors to meaning, fulfillment, and happiness.

### Tier 6: Full On-Device AI Agent (from Sections 15 & 16)

This tier assembles the world model (Tier 5) with memory, trigger system, agent-to-agent communication, and device-tier routing into a complete autonomous agent per user. Items ordered by dependency.

**Prerequisites:** Tier 5 #22 (transition predictor) and #23 (guardrails) must be complete. Tier 1 items 1-3 provide training data.

| # | Action | Section | Why | Effort | Depends On |
|---|---|---|---|---|---|
| 30 | **Episodic Memory System** | 16.2 | SQLite-backed episode storage. Records (state, action, next_state, outcome) from every interaction. Enables memory-based learning and provides on-device training data. | 1-2 days | None (can start now) |
| 31 | **Semantic Memory (vector store)** | 16.2 | Extends existing `StructuredFactsIndex` with embeddings for semantic retrieval. Agent queries "what does this user like on Saturday evenings?" and gets relevant compressed knowledge. | 2-3 days | #30 |
| 32 | **Procedural Memory (learned strategies)** | 16.2 | Extracts if-then rules from episode patterns. "When novelty_saturation > 0.8, exploration outperforms comfort by 23%." Used as heuristics in planning loop. | 1-2 days | #30 |
| 33 | **Memory Consolidation (nightly)** | 15.7 | Compress episodes into semantic memory, extract procedural rules, prune old episodes. Runs during charging + WiFi + idle via `WorkManager`/`BGTaskScheduler`. | 2-3 days | #30, #31, #32 |
| 34 | **Agent Trigger System** | 16.3 | Replace 1-second polling timer with event-driven triggers (app open, location change, AI2AI connection, timer during active hours). Battery-efficient activation. | 1-2 days | None (can start now) |
| 35 | **Device Capability Tiers** | 16.4 | Extend `on_device_ai_capability_gate.dart` with `AgentCapabilityTier` enum. Route: full agent on powerful phones, ONNX-only on older phones, formula-only on minimal devices. | 1 day | None (can start now) |
| 36 | **Agent Reasoning Orchestrator** | 16.2 | Central coordinator: on trigger, encodes state, runs world model planning, evaluates with critic + guardrails, presents recommendation, records outcome to episodic memory. The "main loop" of the agent. | 3-5 days | #22, #23, #30, #34 |
| 37 | **On-Device World Model Training** | 15.7 | Overnight gradient updates to transition predictor using accumulated episodes. ~30 seconds of compute during charging. 150K params, 1.2MB memory. | 2-3 days | #22, #30, #36 |
| 38 | **Federated World Model Sync** | 15.8 | Share DP-noised transition predictor and critic weight deltas via federated-sync. Receive aggregated improvements. Privacy: Laplace noise epsilon=1.0, L2 norm clipping. | 2-3 days | #37 |
| 39 | **Agent-to-Agent Insight Exchange** | 16.6 | Extend AI2AI from 12D embedding deltas to structured `AgentInsight`s (category + region + generalization + confidence). Agents learn from each other's compressed experience without sharing personal data. | 2-3 days | #30, #36 |
| 40 | **Agent-to-Agent Group Negotiation** | 16.6 | When agents detect high entanglement between users, they negotiate group activities. Both agents run world model planning for joint actions and recommend the lowest combined energy option. | 3-5 days | #36, #39 |
| 41 | **SLM Language Interface** | 16.2 | Download 1-3B model via `model_pack_manager`. Use as explanation interface ("I think you'd love this because..."), NOT as reasoning brain. World model handles decisions; SLM explains them. Only on Tier 3 devices. | 2-3 days | #35, #36 |

**Total Tier 6 effort:** ~20-30 days if sequential, ~12-18 days with parallelism (#30, #34, #35 can start immediately in parallel; #31, #32 follow #30; #36 integrates everything).

**Expected impact:** Every user has a personal AI agent that knows them, learns from experience, communicates with other agents, plans trajectories toward meaning, and gets better over time -- all running on their phone, all working offline, all privacy-preserving by architecture.

---

### Priority Cross-Reference: LeCun Alignment by Tier

| Tier | LeCun Alignment | Role |
|---|---|---|
| Tier 1 | Strong | Foundation: real data, feedback loops -- prerequisite for all learning |
| Tier 2 | Moderate | Incremental: better features, better calibration within current paradigm |
| Tier 3 | Moderate-Strong | Structural: two-tower (JEA), multi-task, learned representations |
| Tier 4 | Mixed | Novel math, but some items are "faster hand-crafting" rather than "more learning" |
| Tier 5 | **Very Strong** | **Paradigm shift: world models, planning, guardrails, EBMs, JEPA** |
| Tier 6 | **Very Strong** | **Complete agent: memory, triggers, agent-to-agent, device tiers, autonomy** |

### Recommended Execution Order

```
Phase A (Foundation -- do first, always):
  Tier 1: #1-5 (real data, feedback loop, consistency tests)

Phase B (Can start in parallel with Phase A):
  Tier 5 #23: Guardrail objectives (zero dependencies)
  Tier 6 #30: Episodic memory (zero dependencies)
  Tier 6 #34: Trigger system (zero dependencies)
  Tier 6 #35: Device capability tiers (zero dependencies)

Phase C (After Phase A completes):
  Tier 3 #16: Two-tower architecture (JEA foundation)
  Tier 5 #22: World model transition predictor (needs real data)
  Tier 5 #26: Energy-based compatibility (needs real data)

Phase D (After Phase C completes):
  Tier 5 #24: MPC planning (needs world model + guardrails)
  Tier 5 #25: Latent variables for uncertainty (needs world model)
  Tier 6 #31-33: Full memory system (needs episodic memory)
  Tier 6 #36: Agent reasoning orchestrator (needs world model + memory + triggers)

Phase E (After Phase D completes):
  Tier 5 #27: System 1/System 2 compilation (needs MPC planner)
  Tier 6 #37-38: On-device training + federated sync (needs orchestrator)
  Tier 6 #39-40: Agent-to-agent communication (needs orchestrator)
  Tier 6 #41: SLM language interface (needs orchestrator)

Phase F (Long-term, requires substantial real user data):
  Tier 5 #28: AI2AI world model (needs real AI2AI data)
  Tier 5 #29: JEPA personality representation (needs months of real data)

Tiers 2 and 4 can be interleaved at any point as needed.
```

**Total estimated timeline:**
- Phase A: 1-2 weeks
- Phase B: 1 week (parallel with A)
- Phase C: 2-3 weeks
- Phase D: 3-4 weeks
- Phase E: 3-4 weeks
- Phase F: 4-6 weeks (depends on user data accumulation)
- **Total: ~14-20 weeks to full agent, with incremental value at each phase**
