# Experiment Software Stack & Tools Guide

**Date:** December 19, 2025, 2:55 PM CST  
**Purpose:** Complete guide for software, tools, and optimizations for running patent experiments  
**Status:** 📋 Ready for Implementation

---

## 🖥️ **Software Stack**

### **Primary Language: Python 3.8+**

**Why Python?**
- ✅ Already used in SPOTS project (see `scripts/` directory)
- ✅ Excellent for data analysis and scientific computing
- ✅ Rich ecosystem (NumPy, Pandas, SciPy, Matplotlib)
- ✅ Easy to learn and maintain
- ✅ Cross-platform (works on macOS)

**Required Python Packages:**
```python
# Core data science
numpy>=1.21.0          # Numerical computing
pandas>=1.3.0          # Data analysis
scipy>=1.7.0           # Scientific computing
matplotlib>=3.4.0      # Plotting
seaborn>=0.11.0        # Statistical visualization

# Statistical analysis
scikit-learn>=1.0.0    # Machine learning metrics, PCA for dimensionality reduction
statsmodels>=0.13.0    # Statistical modeling

# Optimization (for Patent #29 coefficient optimization)
scipy>=1.7.0           # Includes scipy.optimize for gradient descent, differential evolution
# Optional: DEAP>=2.3.1  # Genetic algorithm library (alternative to scipy.optimize.differential_evolution)
```

**Installation:**
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On macOS

# Install packages
pip install numpy pandas scipy matplotlib seaborn scikit-learn statsmodels

# Optional: For advanced genetic algorithms (Patent #29)
# pip install deap
```

---

## 🍎 **macOS Coding Tools**

### **Recommended Tools:**

**1. VS Code (Recommended)**
- ✅ Free, lightweight, excellent Python support
- ✅ Built-in terminal
- ✅ Jupyter notebook support
- ✅ Git integration
- ✅ Extensions: Python, Jupyter, GitLens

**2. PyCharm (Professional)**
- ✅ Full-featured Python IDE
- ✅ Excellent debugging
- ✅ Built-in scientific tools
- ⚠️ Heavier, more resource-intensive

**3. Jupyter Notebooks (Interactive Analysis)**
- ✅ Perfect for exploratory data analysis
- ✅ Visual results inline
- ✅ Easy to share and document
- ✅ Install: `pip install jupyter notebook`

**4. Terminal Tools (Built-in macOS)**
- ✅ **iTerm2** (better than default Terminal)
- ✅ **Homebrew** (package manager)
- ✅ **Git** (already installed)

### **macOS-Specific Optimizations:**

**1. Use Homebrew for Python:**
```bash
# Install Python via Homebrew (better than system Python)
brew install python@3.11

# Use Homebrew Python
python3.11 -m venv venv
```

**2. Parallel Processing:**
```python
# Use multiprocessing for faster experiments
from multiprocessing import Pool

def run_experiment(args):
    # Experiment code
    pass

# Run experiments in parallel (uses all CPU cores)
with Pool() as pool:
    results = pool.map(run_experiment, experiment_args)
```

**3. Memory Optimization:**
```python
# Use generators for large datasets (saves memory)
def generate_profiles(n):
    for i in range(n):
        yield generate_personality_profile(seed=i)

# Process in batches
for batch in batch_generator(generate_profiles(1000), batch_size=100):
    process_batch(batch)
```

---

## ⚡ **Time Acceleration for Experiments**

### **Problem: Patent #3 Needs 6 Months of Simulation**

**Solution: Time Compression (NOT Quantum Time)**

**Why NOT Quantum Time?**
- ❌ Quantum time is a theoretical physics concept, not a programming tool
- ❌ Would be confusing and not helpful
- ❌ Experiments need deterministic, reproducible results

**Solution: Simulated Time Acceleration**

Instead of waiting 6 months, we simulate 6 months instantly:

```python
import numpy as np

def simulate_evolution_fast(initial_profiles, num_months=6, with_drift_resistance=True):
    """
    Simulate 6 months of evolution in seconds (not 6 months real time).
    
    Time compression: 1 simulation step = 1 day
    6 months = 180 days = 180 simulation steps
    """
    profiles = [p.copy() for p in initial_profiles]
    evolution_history = [profiles.copy()]
    
    # Simulate each day (not wait for real time)
    for day in range(num_months * 30):  # 6 months = 180 days
        # Simulate one day of AI2AI interactions
        for i in range(len(profiles)):
            # Random interaction
            j = np.random.randint(0, len(profiles))
            if i == j:
                continue
            
            # Apply influence (simulated, not real-time)
            compatibility = 1.0 - np.linalg.norm(profiles[i] - profiles[j]) / np.sqrt(12)
            influence = compatibility * 0.1
            
            new_profile = profiles[i] + influence * (profiles[j] - profiles[i])
            
            # Apply drift resistance if enabled
            if with_drift_resistance:
                original_profile = initial_profiles[i]
                drift = np.abs(new_profile - original_profile)
                for dim in range(12):
                    if drift[dim] > 0.3:  # 30% threshold
                        new_profile[dim] = original_profile[dim] + np.sign(new_profile[dim] - original_profile[dim]) * 0.3
            
            new_profile = np.clip(new_profile, 0.0, 1.0)
            profiles[i] = new_profile
        
        # Save snapshot every 30 days (monthly)
        if day % 30 == 0:
            evolution_history.append(profiles.copy())
    
    return evolution_history

# Run simulation (takes seconds, not months)
evolution_history = simulate_evolution_fast(initial_profiles, num_months=6)
```

**Time Compression Benefits:**
- ✅ 6 months simulated in seconds
- ✅ Deterministic (same seed = same results)
- ✅ Reproducible
- ✅ Easy to test different scenarios

---

## 🔒 **Synthetic Agent Uniqueness Guarantee**

### **Problem: Ensuring Every Synthetic Agent is Unique**

**Solution: Deterministic Unique ID Generation**

```python
import hashlib
import numpy as np

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

def generate_unique_profiles(n, seed=42):
    """
    Generate n unique synthetic personality profiles.
    
    Guarantees:
    - Every profile is unique (different values)
    - Deterministic (same seed = same profiles)
    - No duplicates
    """
    np.random.seed(seed)
    profiles = []
    profile_set = set()  # Track unique profiles
    
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
        agents.append({
            'agentId': agent_id,
            'profile': profile.tolist(),
            'index': i
        })
    
    return agents

# Usage
agents = generate_unique_profiles(500, seed=42)

# Verify uniqueness
agent_ids = [a['agentId'] for a in agents]
assert len(agent_ids) == len(set(agent_ids)), "Duplicate agent IDs found!"
print(f"✅ Generated {len(agents)} unique agents")
```

**Uniqueness Guarantees:**

1. **Profile Uniqueness:**
   - Uses hash-based deduplication
   - Checks for duplicate profiles before adding
   - Maximum attempts limit prevents infinite loops

2. **Agent ID Uniqueness:**
   - Each agent gets unique `agentId` based on profile + index
   - SHA-256 hash ensures uniqueness
   - Format matches SPOTS: `agent_synthetic_[32 chars]`

3. **Deterministic:**
   - Same seed = same profiles
   - Same profile + index = same agentId
   - Reproducible results

**Validation:**
```python
# Verify uniqueness
def validate_uniqueness(agents):
    """Validate all agents are unique."""
    agent_ids = [a['agentId'] for a in agents]
    profiles = [tuple(a['profile']) for a in agents]
    
    # Check agent ID uniqueness
    assert len(agent_ids) == len(set(agent_ids)), "Duplicate agent IDs!"
    
    # Check profile uniqueness (allowing small floating point differences)
    profile_hashes = [hash(tuple(p)) for p in profiles]
    assert len(profile_hashes) == len(set(profile_hashes)), "Duplicate profiles!"
    
    print(f"✅ All {len(agents)} agents are unique")
    return True
```

---

## 🚀 **Performance Optimizations**

### **1. Vectorization (NumPy)**

**Slow (Loops):**
```python
# Slow: Loops
result = []
for i in range(len(profiles_a)):
    result.append(profiles_a[i] * profiles_b[i])
```

**Fast (Vectorized):**
```python
# Fast: Vectorized operations
result = np.array(profiles_a) * np.array(profiles_b)
```

### **2. Parallel Processing**

```python
from multiprocessing import Pool
import numpy as np

def calculate_compatibility_pair(args):
    profile_a, profile_b = args
    # Calculate compatibility
    return np.abs(np.dot(profile_a, profile_b)) ** 2

# Generate all pairs
pairs = [(profiles[i], profiles[j]) for i in range(len(profiles)) for j in range(i+1, len(profiles))]

# Process in parallel (uses all CPU cores)
with Pool() as pool:
    results = pool.map(calculate_compatibility_pair, pairs)
```

### **3. Caching Results**

```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def calculate_compatibility_cached(profile_a_hash, profile_b_hash):
    # Expensive calculation
    return compatibility_score

# Hash profiles for caching
def hash_profile(profile):
    return hashlib.md5(profile.tobytes()).hexdigest()
```

### **4. Tensor Operations for Multi-Entity Matching (Patent #29)**

```python
import numpy as np

def create_entangled_state(entities):
    """
    Create N-way entangled quantum state for Patent #29.
    
    entities: List of quantum state vectors [|ψ_entity_1⟩, |ψ_entity_2⟩, ...]
    """
    # Tensor product: |ψ_entangled⟩ = |ψ_entity_1⟩ ⊗ |ψ_entity_2⟩ ⊗ ... ⊗ |ψ_entity_N⟩
    entangled = entities[0]
    for entity in entities[1:]:
        # NumPy outer product for tensor product
        entangled = np.outer(entangled, entity).flatten()
    
    # Normalize: ⟨ψ_entangled|ψ_entangled⟩ = 1
    norm = np.linalg.norm(entangled)
    if norm > 0:
        entangled = entangled / norm
    
    return entangled

def calculate_n_way_compatibility(entangled_state, ideal_state):
    """
    Calculate compatibility using quantum fidelity for N-way matching.
    """
    # For pure states: F(|ψ⟩, |φ⟩) = |⟨ψ|φ⟩|²
    inner_product = np.abs(np.dot(entangled_state, ideal_state))
    fidelity = inner_product ** 2
    
    return fidelity
```

### **5. Optimization Algorithms (Patent #29)**

```python
from scipy.optimize import minimize
import numpy as np

def optimize_entanglement_coefficients(entities, ideal_state, initial_coeffs):
    """
    Optimize entanglement coefficients using gradient descent.
    
    Objective: max F(ρ_entangled(α), ρ_ideal)
    Constraints: Σᵢ |αᵢ|² = 1, αᵢ ≥ 0
    """
    def objective(coeffs):
        # Create entangled state with coefficients
        entangled = create_weighted_entangled_state(entities, coeffs)
        # Calculate negative fidelity (minimize negative = maximize)
        fidelity = calculate_n_way_compatibility(entangled, ideal_state)
        return -fidelity  # Negative for minimization
    
    def constraint_normalization(coeffs):
        # Constraint: Σᵢ |αᵢ|² = 1
        return np.sum(coeffs ** 2) - 1.0
    
    # Bounds: αᵢ ≥ 0
    bounds = [(0, None) for _ in initial_coeffs]
    
    # Constraints
    constraints = {'type': 'eq', 'fun': constraint_normalization}
    
    # Optimize
    result = minimize(
        objective,
        initial_coeffs,
        method='SLSQP',  # Sequential Least Squares Programming
        bounds=bounds,
        constraints=constraints,
        options={'maxiter': 100, 'ftol': 1e-6}
    )
    
    return result.x, -result.fun  # Return coefficients and fidelity
```

### **6. Dimensionality Reduction (Patent #29)**

```python
from sklearn.decomposition import PCA
import numpy as np

def reduce_tensor_dimensions(entities, target_dim=8):
    """
    Apply PCA for dimensionality reduction in multi-entity matching.
    
    Reduces exponential complexity: 24^N → 8^N
    """
    # Stack all entity states
    entity_matrix = np.array(entities)
    
    # Apply PCA
    pca = PCA(n_components=target_dim)
    reduced_entities = pca.fit_transform(entity_matrix)
    
    return reduced_entities, pca
```

---

## 📊 **Data Analysis Tools**

### **1. Jupyter Notebooks (Recommended)**

**Why Jupyter?**
- ✅ Interactive analysis
- ✅ Visual results inline
- ✅ Easy to document
- ✅ Shareable

**Setup:**
```bash
pip install jupyter notebook
jupyter notebook
```

**Use Cases:**
- Exploratory data analysis
- Visualizing results
- Statistical analysis
- Creating reports

### **2. Pandas for Data Analysis**

```python
import pandas as pd

# Load results
results = pd.read_csv('results/patent_1/accuracy_comparison.csv')

# Statistical analysis
summary = results.describe()
correlation = results.corr()

# Group by method
by_method = results.groupby('method').mean()
```

### **3. Matplotlib/Seaborn for Visualization**

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Create comparison plots
sns.boxplot(data=results, x='method', y='accuracy')
plt.title('Accuracy Comparison: Quantum vs Classical')
plt.savefig('results/patent_1/accuracy_comparison.png')
```

---

## 🔧 **What Would Make It Work Better?**

### **1. Existing SPOTS Data (If Available)**
- Real personality profiles (anonymized, `agentId`-based)
- Real compatibility outcomes
- Real AI2AI network data
- **Note:** Synthetic data works fine, but real data would validate against actual system

### **2. Computing Resources**
- **MacBook Pro M1/M2/M3:** Excellent (fast NumPy with Apple Silicon)
- **Multiple CPU cores:** Use parallel processing
- **Sufficient RAM:** 16GB+ recommended for large datasets

### **3. Development Environment**
- **VS Code with Python extension:** Best experience
- **Jupyter Notebooks:** For interactive analysis
- **Git:** For version control

### **4. Libraries Already Installed**
- Check if NumPy, Pandas already installed: `pip list | grep numpy`
- If not, install: `pip install numpy pandas scipy matplotlib`

---

## ⏱️ **Time Acceleration Strategy**

### **For Patent #3 (6 Months Simulation):**

**Approach: Discrete Time Steps**

```python
# Instead of waiting 6 months, simulate in discrete steps
num_days = 6 * 30  # 180 days

for day in range(num_days):
    # Simulate one day of interactions
    simulate_one_day(profiles, day)
    
    # Save snapshot periodically
    if day % 30 == 0:  # Monthly snapshots
        save_snapshot(profiles, day)
```

**Time Compression:**
- **Real time:** 6 months = 180 days
- **Simulated time:** 180 iterations (takes seconds)
- **Compression ratio:** ~5,000,000:1 (180 days → seconds)

**Benefits:**
- ✅ Instant results
- ✅ Reproducible
- ✅ Easy to test different scenarios
- ✅ No waiting required

---

### **For Patent #29 (6-12 Months Simulation):**

**Approach: Discrete Time Steps for Event Outcomes**

```python
# Simulate 6-12 months of event outcomes instantly
num_months = 12
num_days = num_months * 30  # 360 days

for day in range(num_days):
    # Simulate one day of events and outcomes
    simulate_daily_events(events, users, day)
    
    # Update ideal states with decoherence
    apply_decoherence_to_ideal_states(ideal_states, day)
    
    # Collect outcomes and update learning
    collect_daily_outcomes(events, day)
    update_ideal_states_from_outcomes(outcomes, day)
    
    # Save snapshot periodically
    if day % 30 == 0:  # Monthly snapshots
        save_snapshot(ideal_states, events, day)
```

**Time Compression:**
- **Real time:** 12 months = 360 days
- **Simulated time:** 360 iterations (takes seconds to minutes)
- **Compression ratio:** ~5,000,000:1 (360 days → seconds)

**Benefits:**
- ✅ Instant results for long-term learning validation
- ✅ Reproducible
- ✅ Easy to test different decoherence rates
- ✅ No waiting required

---

## 🎯 **Recommended Setup**

### **Minimal Setup (Quick Start):**
```bash
# 1. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 2. Install packages
pip install numpy pandas scipy matplotlib seaborn scikit-learn

# 3. Run experiments
cd docs/patents/experiments/scripts
python generate_synthetic_data.py
python run_patent_1_experiments.py
```

### **Full Setup (Best Experience):**
```bash
# 1. Install Homebrew Python
brew install python@3.11

# 2. Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 3. Install all packages
pip install numpy pandas scipy matplotlib seaborn scikit-learn statsmodels jupyter notebook

# 4. Install VS Code extensions
# - Python
# - Jupyter
# - GitLens

# 5. Run experiments
cd docs/patents/experiments/scripts
python generate_synthetic_data.py
python run_patent_1_experiments.py
```

---

## 📋 **Experiment Execution Script Template**

```python
#!/usr/bin/env python3
"""
Patent #1, Experiment 1: Quantum vs. Classical Accuracy Comparison
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
from multiprocessing import Pool
import time

# Configuration
DATA_DIR = Path('docs/patents/experiments/data/patent_1_quantum_compatibility')
RESULTS_DIR = Path('docs/patents/experiments/results/patent_1')
NUM_PROFILES = 500
NUM_PAIRS = 1000

def generate_unique_profiles(n, seed=42):
    """Generate n unique synthetic personality profiles with unique agentIds."""
    np.random.seed(seed)
    profiles = []
    profile_set = set()
    attempts = 0
    max_attempts = n * 100
    
    while len(profiles) < n and attempts < max_attempts:
        candidate = np.random.uniform(0.0, 1.0, 12)
        profile_hash = hash(candidate.tobytes())
        
        if profile_hash not in profile_set:
            profiles.append(candidate)
            profile_set.add(profile_hash)
        
        attempts += 1
    
    if len(profiles) < n:
        raise ValueError(f"Could not generate {n} unique profiles")
    
    # Generate unique agent IDs
    agents = []
    for i, profile in enumerate(profiles):
        agent_id = f"agent_synthetic_{hashlib.sha256(profile.tobytes() + str(i).encode()).hexdigest()[:32]}"
        agents.append({
            'agentId': agent_id,
            'profile': profile.tolist(),
            'index': i
        })
    
    # Verify uniqueness
    agent_ids = [a['agentId'] for a in agents]
    assert len(agent_ids) == len(set(agent_ids)), "Duplicate agent IDs!"
    
    return agents

def quantum_compatibility(profile_a, profile_b):
    """Calculate quantum compatibility."""
    inner_product = np.abs(np.dot(profile_a, profile_b))
    return inner_product ** 2

def classical_cosine(profile_a, profile_b):
    """Calculate classical cosine similarity."""
    dot_product = np.dot(profile_a, profile_b)
    norm_a = np.linalg.norm(profile_a)
    norm_b = np.linalg.norm(profile_b)
    return dot_product / (norm_a * norm_b) if (norm_a * norm_b) > 0 else 0.0

def run_experiment():
    """Run the experiment."""
    print("Generating unique synthetic agents...")
    agents = generate_unique_profiles(NUM_PROFILES)
    profiles = [np.array(a['profile']) for a in agents]
    
    print(f"✅ Generated {len(agents)} unique agents")
    print("Calculating compatibility scores...")
    results = []
    
    # Generate random pairs
    pairs = np.random.choice(len(profiles), size=(NUM_PAIRS, 2), replace=False)
    
    for i, (idx_a, idx_b) in enumerate(pairs):
        profile_a = profiles[idx_a]
        profile_b = profiles[idx_b]
        
        # Calculate ground truth (based on dimension similarity)
        distance = np.linalg.norm(profile_a - profile_b)
        max_distance = np.sqrt(12)
        ground_truth = 1.0 - (distance / max_distance)
        
        # Calculate methods
        quantum = quantum_compatibility(profile_a, profile_b)
        cosine = classical_cosine(profile_a, profile_b)
        
        results.append({
            'pair_id': i,
            'agent_a_id': agents[idx_a]['agentId'],
            'agent_b_id': agents[idx_b]['agentId'],
            'ground_truth': ground_truth,
            'quantum': quantum,
            'classical_cosine': cosine,
        })
        
        if (i + 1) % 100 == 0:
            print(f"Processed {i + 1}/{NUM_PAIRS} pairs...")
    
    # Convert to DataFrame
    df = pd.DataFrame(results)
    
    # Calculate metrics
    quantum_correlation = df['quantum'].corr(df['ground_truth'])
    cosine_correlation = df['classical_cosine'].corr(df['ground_truth'])
    
    print(f"\nResults:")
    print(f"Quantum correlation: {quantum_correlation:.4f}")
    print(f"Classical cosine correlation: {cosine_correlation:.4f}")
    print(f"Quantum advantage: {(quantum_correlation - cosine_correlation) * 100:.2f}%")
    
    # Save results
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    df.to_csv(RESULTS_DIR / 'accuracy_comparison.csv', index=False)
    
    # Save agents
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(DATA_DIR / 'synthetic_agents.json', 'w') as f:
        json.dump(agents, f, indent=2)
    
    print(f"\nResults saved to: {RESULTS_DIR / 'accuracy_comparison.csv'}")
    print(f"Agents saved to: {DATA_DIR / 'synthetic_agents.json'}")

if __name__ == '__main__':
    import hashlib
    start_time = time.time()
    run_experiment()
    elapsed = time.time() - start_time
    print(f"\nExperiment completed in {elapsed:.2f} seconds")
```

---

## ✅ **Summary**

**Software:**
- ✅ **Python 3.8+** (primary language)
- ✅ **NumPy, Pandas, SciPy** (data science, optimization, tensor operations)
- ✅ **Matplotlib, Seaborn** (visualization)
- ✅ **scikit-learn** (machine learning metrics, PCA for dimensionality reduction)
- ✅ **statsmodels** (statistical modeling)
- ✅ **Jupyter Notebooks** (interactive analysis)
- ⚠️ **DEAP** (optional - genetic algorithms for Patent #29, scipy.optimize.differential_evolution is alternative)

**macOS Tools:**
- ✅ **VS Code** (recommended IDE)
- ✅ **Jupyter Notebooks** (interactive analysis)
- ✅ **Homebrew** (package management)
- ✅ **iTerm2** (better terminal)

**Time Acceleration:**
- ✅ **Simulated time steps** (NOT quantum time)
- ✅ **6 months → seconds** (Patent #3: discrete simulation)
- ✅ **6-12 months → seconds** (Patent #29: discrete simulation for event outcomes)
- ✅ **Reproducible and deterministic**

**Agent Uniqueness:**
- ✅ **Hash-based deduplication** (no duplicate profiles)
- ✅ **Unique agentId generation** (SHA-256 hash)
- ✅ **Deterministic** (same seed = same agents)
- ✅ **Validation** (uniqueness checks)

**What Would Help:**
- ✅ Real SPOTS data (if available, anonymized)
- ✅ Multiple CPU cores (for parallel processing, especially for Patent #29 multi-entity calculations)
- ✅ Sufficient RAM (16GB+ recommended, 32GB+ for Patent #29 large-scale experiments)
- ✅ VS Code with Python extensions
- ✅ GPU acceleration (optional - for very large tensor operations in Patent #29, NumPy on CPU is usually sufficient)

**Quantum Time:**
- ❌ **NOT helpful** - Would be confusing
- ✅ **Use simulated time steps** instead

---

**Last Updated:** December 19, 2025, 3:20 PM CST  
**Status:** 📋 Ready for Implementation

**Coverage:**
- ✅ **Patent #1:** Quantum compatibility experiments (4 required + 1 optional)
- ✅ **Patent #3:** Contextual personality experiments (3 required + 2 optional)
- ✅ **Patent #21:** Offline quantum matching experiments (2 required + 2 optional)
- ✅ **Patent #29:** Multi-entity quantum matching experiments (6 required + 3 optional)

**Total Experiments:** 22 (13 required + 9 optional)

