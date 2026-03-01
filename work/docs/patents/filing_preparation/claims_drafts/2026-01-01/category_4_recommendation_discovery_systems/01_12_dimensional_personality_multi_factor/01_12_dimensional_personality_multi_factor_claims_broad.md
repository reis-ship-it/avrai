# 12-Dimensional Personality System with Multi-Factor Compatibility — Claims Draft (BROAD)

**Source spec:** `docs/patents/category_4_recommendation_discovery_systems/01_12_dimensional_personality_multi_factor/01_12_dimensional_personality_multi_factor.md`
**Generated:** 2026-01-01

> **NOTE:** Draft for counsel review. This file does not change the underlying spec; it proposes an alternative Claim 1 scope posture.

## Claims

1. A method for multi-dimensional personality modeling with weighted compatibility scoring, comprising:
(a) Representing a user's personality using 12 distinct dimensions, wherein 8 dimensions represent discovery style preferences and 4 dimensions represent experience preferences;
(b) Storing dimension values on a normalized scale from a threshold value to 1.0;
(c) Storing confidence scores for each dimension indicating measurement reliability;
(d) Calculating dimension compatibility by computing similarity for each dimension as `1.0 - |dimension_A - dimension_B|`;
(e) Weighting dimension similarity by average confidence of both users for that dimension.

2. A system for calculating compatibility across 12 personality dimensions, comprising:
(a) A personality profile data structure storing 12 dimension values and confidence scores;
(b) A dimension compatibility calculator that computes similarity per dimension with confidence weighting;
(c) An energy compatibility calculator that computes alignment of energy-related dimensions;
(d) An exploration compatibility calculator that computes alignment of exploration-related dimensions;
(e) A multi-factor fusion module that combines dimension (60%), energy (20%), and exploration (20%) compatibility;
(f) A confidence threshold filter that excludes dimensions below 0.6 confidence;
(g) A normalization module that ensures compatibility scores are in 0.0-1.0 range.

3. The method of claim 1, further comprising confidence-weighted personality compatibility calculation:
(a) Storing personality dimensions with associated confidence scores;
(b) Filtering dimensions by confidence threshold (≥ 0.6 for both users);
(c) Calculating dimension similarity as `1.0 - |value_A - value_B|`;
(d) Weighting similarity by average confidence: `(confidence_A + confidence_B) / 2.0`;
(e) Aggregating weighted similarities across valid dimensions;
(f) Calculating additional compatibility factors (energy, exploration);
(g) Combining factors using specific weights (60% dimension, 20% energy, 20% exploration);
(h) Returning final compatibility score.

4. A 12-dimensional personality model with multi-factor compatibility calculation, comprising:
(a) 8 discovery dimensions: exploration_eagerness, community_orientation, authenticity_preference, social_discovery_style, temporal_flexibility, location_adventurousness, curation_tendency, trust_network_reliance;
(b) 4 experience dimensions: energy_preference, novelty_seeking, value_orientation, crowd_tolerance;
(c) Dimension compatibility calculation with confidence weighting;
(d) Energy compatibility calculation from energy-related dimensions;
(e) Exploration compatibility calculation from exploration-related dimensions;
(f) Weighted multi-factor fusion: 60% dimension + 20% energy + 20% exploration;
(g) Confidence threshold filtering (≥ 0.6) for dimension inclusion.

## Appendix

### Optional companion independent claims (for counsel)

- **System claim (optional):** A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.
- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.
