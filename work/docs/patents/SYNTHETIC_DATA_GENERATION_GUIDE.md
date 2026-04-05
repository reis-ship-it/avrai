# Synthetic Data Generation Guide for Patent Experiments

**Date:** December 19, 2025, 2:35 PM CST  
**Purpose:** Guide for generating synthetic data for patent validation experiments  
**Status:** 📋 Ready for Implementation

---

## 🎯 **Overview**

Synthetic data is **RECOMMENDED** for patent validation experiments because:
- ✅ **No Privacy Concerns:** No real user data required
- ✅ **Immediate Availability:** Can start experiments immediately
- ✅ **Reproducible:** Same data can be regenerated for validation
- ✅ **Controlled Scenarios:** Can create specific test cases
- ✅ **Acceptable for Patents:** Demonstrates algorithmic advantages, not absolute accuracy

---

## 📊 **Data Structure**

### **12-Dimensional Quantum Vibe Space**

The personality dimensions are:
1. `exploration_eagerness` (0.0-1.0)
2. `community_orientation` (0.0-1.0)
3. `authenticity_preference` (0.0-1.0)
4. `social_discovery_style` (0.0-1.0)
5. `temporal_flexibility` (0.0-1.0)
6. `location_adventurousness` (0.0-1.0)
7. `curation_tendency` (0.0-1.0)
8. `trust_network_reliance` (0.0-1.0)
9. `energy_preference` (0.0-1.0)
10. `novelty_seeking` (0.0-1.0)
11. `value_orientation` (0.0-1.0)
12. `crowd_tolerance` (0.0-1.0)

**Format:** Each personality profile is a 12-dimensional vector `[d₁, d₂, ..., d₁₂]` where each `dᵢ ∈ [0.0, 1.0]`

---

## 🔬 **Patent #1: Quantum Compatibility Experiments**

### **Synthetic Data Generation**

**Step 1: Generate Personality Profiles**

```python
import numpy as np
import random

import hashlib

def generate_unique_agent_id(profile, index):
    """
    Generate unique agentId for synthetic agent.
    
    Guarantees:
    - Every agent gets unique ID
    - Deterministic (same profile + index = same ID)
    - Format matches SPOTS agentId: agent_[32+ char base64url]
    """
    # Create unique identifier from profile and index
    profile_bytes = profile.tobytes()
    index_bytes = str(index).encode()
    combined = profile_bytes + index_bytes
    
    # Hash to create unique ID
    hash_obj = hashlib.sha256(combined)
    hash_hex = hash_obj.hexdigest()
    
    # Convert to base64url-like format (SPOTS format)
    # Format: agent_[32+ character string]
    agent_id = f"agent_synthetic_{hash_hex[:32]}"
    
    return agent_id

def generate_personality_profile(seed=None):
    """Generate a synthetic 12-dimensional personality profile."""
    if seed is not None:
        np.random.seed(seed)
    
    # Option 1: Uniform distribution
    profile = np.random.uniform(0.0, 1.0, 12)
    
    # Option 2: Beta distribution (more realistic, clustered around 0.3-0.7)
    # profile = np.random.beta(2, 2, 12)
    
    # Option 3: Normal distribution (clipped to [0, 1])
    # profile = np.clip(np.random.normal(0.5, 0.2, 12), 0.0, 1.0)
    
    return profile

def generate_unique_profiles(n, seed=42):
    """
    Generate n unique synthetic personality profiles with unique agentIds.
    
    Guarantees:
    - Every profile is unique (different values)
    - Every agentId is unique
    - Deterministic (same seed = same profiles)
    - No duplicates
    """
    np.random.seed(seed)
    profiles = []
    profile_set = set()  # Track unique profiles
    agent_ids_set = set()  # Track unique agent IDs
    
    attempts = 0
    max_attempts = n * 100  # Prevent infinite loop
    
    while len(profiles) < n and attempts < max_attempts:
        # Generate candidate profile
        candidate = np.random.uniform(0.0, 1.0, 12)
        
        # Create hash of profile for uniqueness check
        profile_hash = hash(candidate.tobytes())
        
        # Check if unique
        if profile_hash not in profile_set:
            profiles.append(candidate)
            profile_set.add(profile_hash)
        
        attempts += 1
    
    if len(profiles) < n:
        raise ValueError(f"Could not generate {n} unique profiles after {max_attempts} attempts")
    
    # Generate unique agent IDs
    agents = []
    for i, profile in enumerate(profiles):
        agent_id = generate_unique_agent_id(profile, i)
        
        # Ensure agent ID is unique (should be, but double-check)
        while agent_id in agent_ids_set:
            # If collision (extremely rare), add index to make unique
            agent_id = generate_unique_agent_id(profile, i + len(agents) * 1000)
        
        agent_ids_set.add(agent_id)
        
        agents.append({
            'agentId': agent_id,
            'profile': profile.tolist(),
            'index': i
        })
    
    # Final validation
    agent_ids = [a['agentId'] for a in agents]
    assert len(agent_ids) == len(set(agent_ids)), "Duplicate agent IDs found!"
    assert len(profiles) == len(set([hash(p.tobytes()) for p in profiles])), "Duplicate profiles found!"
    
    return agents

# Generate 500 unique agents
agents = generate_unique_profiles(500, seed=42)
print(f"✅ Generated {len(agents)} unique agents")
print(f"✅ All agent IDs are unique: {len(set([a['agentId'] for a in agents])) == len(agents)}")
```

**Step 2: Create Compatibility Ground Truth**

```python
def calculate_ground_truth_compatibility(profile_a, profile_b):
    """Calculate synthetic compatibility based on dimension similarity."""
    # Calculate Euclidean distance
    distance = np.linalg.norm(profile_a - profile_b)
    
    # Convert distance to compatibility (inverse relationship)
    # Max distance for 12 dimensions: sqrt(12) ≈ 3.46
    max_distance = np.sqrt(12)
    normalized_distance = distance / max_distance
    
    # Compatibility: 1.0 = identical, 0.0 = completely different
    compatibility = 1.0 - normalized_distance
    
    # Add realistic noise (5-10% variation)
    noise = np.random.normal(0, 0.05)
    compatibility = np.clip(compatibility + noise, 0.0, 1.0)
    
    # Convert to 1-5 scale for ground truth
    rating = 1 + int(compatibility * 4)
    
    return rating, compatibility

# Generate compatibility pairs
pairs = []
for i in range(500):
    for j in range(i+1, 500):
        rating, compatibility = calculate_ground_truth_compatibility(
            profiles[i], profiles[j]
        )
        pairs.append({
            'profile_a': profiles[i],
            'profile_b': profiles[j],
            'ground_truth_rating': rating,
            'ground_truth_compatibility': compatibility
        })
```

**Step 3: Create Noise Scenarios**

```python
def add_noise(profile, noise_type, noise_level):
    """Add noise to profile for noise handling experiments."""
    noisy_profile = profile.copy()
    
    if noise_type == 'missing_dimensions':
        # Randomly set some dimensions to NaN
        num_missing = int(len(profile) * noise_level)
        missing_indices = np.random.choice(len(profile), num_missing, replace=False)
        noisy_profile[missing_indices] = np.nan
        
    elif noise_type == 'gaussian':
        # Add Gaussian noise
        noise = np.random.normal(0, noise_level, len(profile))
        noisy_profile = np.clip(noisy_profile + noise, 0.0, 1.0)
    
    return noisy_profile
```

---

## 🔬 **Patent #3: Contextual Personality Experiments**

### **Synthetic Data Generation**

**Step 1: Generate Initial Personality Profiles**

```python
def generate_initial_personalities(num_agents=100):
    """Generate diverse initial personality profiles."""
    profiles = []
    
    # Create diverse profiles (some high, some low, some mixed)
    for i in range(num_agents):
        if i % 4 == 0:
            # High-energy, adventurous profiles
            profile = np.random.uniform(0.7, 1.0, 12)
        elif i % 4 == 1:
            # Low-energy, cautious profiles
            profile = np.random.uniform(0.0, 0.3, 12)
        elif i % 4 == 2:
            # Mixed profiles
            profile = np.random.uniform(0.3, 0.7, 12)
        else:
            # Extreme profiles (some dimensions high, some low)
            profile = np.random.choice([0.0, 1.0], 12)
        
        profiles.append(profile)
    
    return profiles
```

**Step 2: Simulate AI2AI Network Evolution**

```python
def simulate_evolution(initial_profiles, num_months=6, with_drift_resistance=True, drift_threshold=0.3):
    """Simulate personality evolution over time."""
    profiles = [p.copy() for p in initial_profiles]
    evolution_history = [profiles.copy()]
    
    for month in range(num_months):
        # Simulate AI2AI interactions
        for i in range(len(profiles)):
            # Randomly select another agent to interact with
            j = np.random.randint(0, len(profiles))
            if i == j:
                continue
            
            # Calculate influence (based on compatibility)
            compatibility = 1.0 - np.linalg.norm(profiles[i] - profiles[j]) / np.sqrt(12)
            influence = compatibility * 0.1  # 10% influence per interaction
            
            # Apply influence
            new_profile = profiles[i] + influence * (profiles[j] - profiles[i])
            
            # Apply drift resistance if enabled
            if with_drift_resistance:
                original_profile = initial_profiles[i]
                drift = np.abs(new_profile - original_profile)
                # Clamp to drift threshold
                for dim in range(12):
                    if drift[dim] > drift_threshold:
                        # Resistant to change beyond threshold
                        new_profile[dim] = original_profile[dim] + np.sign(new_profile[dim] - original_profile[dim]) * drift_threshold
            
            # Clamp to [0, 1]
            new_profile = np.clip(new_profile, 0.0, 1.0)
            profiles[i] = new_profile
        
        evolution_history.append(profiles.copy())
    
    return evolution_history
```

**Step 3: Calculate Homogenization Metrics**

```python
def calculate_diversity(profiles):
    """Calculate personality diversity (average pairwise distance)."""
    distances = []
    for i in range(len(profiles)):
        for j in range(i+1, len(profiles)):
            distance = np.linalg.norm(profiles[i] - profiles[j])
            distances.append(distance)
    return np.mean(distances)

def calculate_homogenization_rate(initial_profiles, final_profiles):
    """Calculate homogenization rate."""
    initial_diversity = calculate_diversity(initial_profiles)
    final_diversity = calculate_diversity(final_profiles)
    
    if initial_diversity == 0:
        return 0.0
    
    homogenization = 1.0 - (final_diversity / initial_diversity)
    return homogenization
```

---

## 📋 **Implementation Checklist**

### **Patent #1 Experiments:**
- [ ] Generate 500 synthetic personality profiles (12-dimensional)
- [ ] Create compatibility ground truth (based on dimension similarity)
- [ ] Generate 100-500 agent pairs with ground truth ratings
- [ ] Create noise scenarios (missing dimensions, Gaussian noise)
- [ ] Validate data format matches real SPOTS data structure

### **Patent #3 Experiments:**
- [ ] Generate 100 synthetic initial personality profiles
- [ ] Simulate 6 months of AI2AI network evolution
- [ ] Create scenarios: with/without drift resistance, different thresholds
- [ ] Calculate homogenization metrics over time
- [ ] Generate evolution history data

---

## ✅ **Validation**

**Before using synthetic data, validate:**
1. **Structure:** Matches real SPOTS data format (12-dimensional vectors)
2. **Range:** All values in [0.0, 1.0]
3. **Distribution:** Realistic personality distributions (not all uniform)
4. **Compatibility:** Ground truth reflects dimension similarity
5. **Reproducibility:** Same seed produces same data

---

## 📊 **Expected Results with Synthetic Data**

**Patent #1:**
- Quantum method should show relative improvement over classical methods
- Noise handling should demonstrate quantum regularization advantage
- Entanglement should show measurable impact

**Patent #3:**
- Without drift resistance: Should show homogenization (diversity decreases)
- With drift resistance: Should prevent homogenization (diversity maintained)
- 30% threshold: Should show optimal balance

**Note:** Absolute accuracy numbers may differ from real data, but **relative improvements** (quantum vs classical, with vs without drift resistance) should be consistent.

---

## 🎯 **Advantages of Synthetic Data for Patents**

1. **Demonstrates Algorithmic Advantages:** Shows that quantum method is better than classical, regardless of absolute accuracy
2. **Reproducible:** Same results can be reproduced for patent examiner review
3. **Controlled:** Can test specific scenarios (high noise, extreme personalities, etc.)
4. **No Privacy Issues:** No GDPR/CCPA concerns
5. **Immediate:** Can start experiments immediately

---

**Last Updated:** December 19, 2025, 2:35 PM CST  
**Status:** 📋 Ready for Implementation

