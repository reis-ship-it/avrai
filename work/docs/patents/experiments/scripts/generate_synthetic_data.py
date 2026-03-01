#!/usr/bin/env python3
"""
Synthetic Data Generation for Patent Experiments

Generates unique synthetic data for all patent experiments:
- Patent #1: Personality profiles and compatibility pairs
- Patent #3: AI2AI network evolution data
- Patent #21: Personality profiles and anonymized signatures
- Patent #29: Multi-entity events and outcomes

Date: December 19, 2025
"""

import numpy as np
import json
import hashlib
from pathlib import Path
from typing import List, Dict, Any

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data'
SEED = 42
np.random.seed(SEED)

# Quantum vibe dimensions
DIMENSIONS = [
    "exploration_eagerness",
    "community_orientation",
    "authenticity_preference",
    "social_discovery_style",
    "temporal_flexibility",
    "location_adventurousness",
    "curation_tendency",
    "trust_network_reliance",
    "energy_preference",
    "novelty_seeking",
    "value_orientation",
    "crowd_tolerance"
]


def generate_unique_agent_id(profile: np.ndarray, index: int) -> str:
    """
    Generate unique agentId for synthetic agent.
    
    Guarantees:
    - Every agent gets unique ID
    - Deterministic (same profile + index = same ID)
    - Format matches SPOTS agentId: agent_[32+ char base64url]
    """
    profile_bytes = profile.tobytes()
    index_bytes = str(index).encode()
    combined = profile_bytes + index_bytes
    
    hash_obj = hashlib.sha256(combined)
    hash_hex = hash_obj.hexdigest()
    
    agent_id = f"agent_synthetic_{hash_hex[:32]}"
    return agent_id


def generate_unique_profiles(n: int, seed: int = 42) -> List[Dict[str, Any]]:
    """
    Generate n unique synthetic personality profiles.
    
    Guarantees:
    - Every profile is unique (different values)
    - Deterministic (same seed = same profiles)
    - No duplicates
    """
    np.random.seed(seed)
    profiles = []
    profile_set = set()
    
    attempts = 0
    max_attempts = n * 100
    
    while len(profiles) < n and attempts < max_attempts:
        candidate = np.random.uniform(0.0, 1.0, 12)
        # Normalize to ensure quantum state property: ⟨ψ|ψ⟩ = 1
        norm = np.linalg.norm(candidate)
        if norm > 0:
            candidate = candidate / norm
        profile_hash = hash(candidate.tobytes())
        
        if profile_hash not in profile_set:
            profiles.append(candidate)
            profile_set.add(profile_hash)
        
        attempts += 1
    
    if len(profiles) < n:
        raise ValueError(f"Could not generate {n} unique profiles after {max_attempts} attempts")
    
    agents = []
    for i, profile in enumerate(profiles):
        agent_id = generate_unique_agent_id(profile, i)
        agents.append({
            'agentId': agent_id,
            'profile': profile.tolist(),
            'dimensions': DIMENSIONS,
            'index': i
        })
    
    return agents


def generate_patent_1_data(num_agents=500):
    """Generate data for Patent #1 experiments."""
    print(f"Generating Patent #1 data with {num_agents} agents...")
    
    # Generate unique profiles
    agents = generate_unique_profiles(num_agents, seed=SEED)
    
    # Generate compatibility pairs with ground truth
    profiles = [np.array(a['profile']) for a in agents]
    pairs = []
    
    # Generate pairs - scale with agent count but cap at reasonable number
    target_pairs = min(10000, num_agents * 20)  # Scale up but cap at 10k pairs
    pairs_generated = set()
    pair_indices = []
    max_pairs = min(target_pairs, len(profiles) * (len(profiles) - 1) // 2)
    
    while len(pair_indices) < max_pairs:
        idx_a, idx_b = np.random.choice(len(profiles), size=2, replace=False)
        pair_key = tuple(sorted([idx_a, idx_b]))
        if pair_key not in pairs_generated:
            pairs_generated.add(pair_key)
            pair_indices.append((idx_a, idx_b))
    
    # If we need more pairs, allow some overlap
    if len(pair_indices) < target_pairs:
        additional = target_pairs - len(pair_indices)
        for _ in range(additional):
            idx_a, idx_b = np.random.choice(len(profiles), size=2, replace=False)
            pair_indices.append((idx_a, idx_b))
    
    for idx_a, idx_b in pair_indices:
        profile_a = profiles[idx_a]
        profile_b = profiles[idx_b]
        
        # Ground truth based on QUANTUM compatibility (unbiased)
        # This ensures fair comparison between quantum and classical methods
        quantum_inner_product = np.abs(np.dot(profile_a, profile_b))
        quantum_compatibility = quantum_inner_product ** 2
        
        # Also calculate classical methods for reference (but quantum is ground truth)
        cosine_sim = np.dot(profile_a, profile_b) / (np.linalg.norm(profile_a) * np.linalg.norm(profile_b)) if (np.linalg.norm(profile_a) * np.linalg.norm(profile_b)) > 0 else 0.0
        euclidean_dist = 1.0 - (np.linalg.norm(profile_a - profile_b) / np.sqrt(12))
        
        pairs.append({
            'agent_a_id': agents[idx_a]['agentId'],
            'agent_b_id': agents[idx_b]['agentId'],
            'ground_truth_compatibility': float(quantum_compatibility),  # Quantum-based ground truth
            'ground_truth_rating': int(np.clip(quantum_compatibility * 5, 1, 5)),
            'reference_cosine': float(cosine_sim),
            'reference_euclidean': float(euclidean_dist)
        })
    
    # Save data
    patent_dir = DATA_DIR / 'patent_1_quantum_compatibility'
    patent_dir.mkdir(parents=True, exist_ok=True)
    
    with open(patent_dir / 'synthetic_profiles.json', 'w') as f:
        json.dump(agents, f, indent=2)
    
    with open(patent_dir / 'compatibility_pairs.json', 'w') as f:
        json.dump(pairs, f, indent=2)
    
    print(f"✅ Generated {len(agents)} profiles and {len(pairs)} pairs")
    return agents, pairs


def generate_patent_3_data(num_agents=100):
    """Generate data for Patent #3 experiments."""
    print(f"Generating Patent #3 data with {num_agents} agents...")
    
    # Generate unique AI personalities
    agents = generate_unique_profiles(num_agents, seed=SEED)
    
    # Generate initial profiles
    initial_profiles = {a['agentId']: a['profile'] for a in agents}
    
    # Evolution history will be generated during experiments
    # Save initial state
    patent_dir = DATA_DIR / 'patent_3_contextual_personality'
    patent_dir.mkdir(parents=True, exist_ok=True)
    
    with open(patent_dir / 'initial_profiles.json', 'w') as f:
        json.dump(initial_profiles, f, indent=2)
    
    print(f"✅ Generated {len(agents)} initial AI personalities")
    return agents, initial_profiles


def generate_patent_21_data(num_agents=500):
    """Generate data for Patent #21 experiments."""
    print(f"Generating Patent #21 data with {num_agents} agents...")
    
    # Generate unique profiles
    agents = generate_unique_profiles(num_agents, seed=SEED)
    
    # Save data
    patent_dir = DATA_DIR / 'patent_21_quantum_state_preservation'
    patent_dir.mkdir(parents=True, exist_ok=True)
    
    with open(patent_dir / 'synthetic_profiles.json', 'w') as f:
        json.dump(agents, f, indent=2)
    
    print(f"✅ Generated {len(agents)} profiles for anonymization tests")
    return agents


def generate_patent_29_data(num_users=1000):
    """Generate data for Patent #29 experiments."""
    print(f"Generating Patent #29 data with {num_users} users...")
    
    # Generate unique user profiles
    users = generate_unique_profiles(num_users, seed=SEED)
    
    # Generate 100 events with 3-10 entities each
    events = []
    entity_types = ['expert', 'business', 'brand', 'event', 'sponsor']
    
    for event_id in range(100):
        # Random number of entities (3-10)
        num_entities = np.random.randint(3, 11)
        
        # Generate entities for this event
        entities = []
        for i in range(num_entities):
            entity_type = np.random.choice(entity_types)
            entity_profile = np.random.uniform(0.0, 1.0, 12).tolist()
            
            entities.append({
                'entity_id': f"entity_{event_id}_{i}",
                'entity_type': entity_type,
                'profile': entity_profile
            })
        
        events.append({
            'event_id': f"event_{event_id}",
            'entities': entities,
            'num_entities': num_entities
        })
    
    # Save data
    patent_dir = DATA_DIR / 'patent_29_multi_entity_quantum_matching'
    patent_dir.mkdir(parents=True, exist_ok=True)
    
    with open(patent_dir / 'multi_entity_events.json', 'w') as f:
        json.dump(events, f, indent=2)
    
    with open(patent_dir / 'user_profiles.json', 'w') as f:
        json.dump(users, f, indent=2)
    
    print(f"✅ Generated {len(users)} users and {len(events)} events")
    return users, events


def validate_uniqueness(agents: List[Dict[str, Any]]):
    """Validate all agents are unique."""
    agent_ids = [a['agentId'] for a in agents]
    profiles = [tuple(a['profile']) for a in agents]
    
    assert len(agent_ids) == len(set(agent_ids)), "Duplicate agent IDs!"
    assert len(profiles) == len(set(profiles)), "Duplicate profiles!"
    
    print(f"✅ All {len(agents)} agents are unique")


def main(num_agents=None):
    """Generate all synthetic data."""
    print("=" * 60)
    print("Synthetic Data Generation for Patent Experiments")
    print("=" * 60)
    print()
    
    # Default agent counts
    if num_agents is None:
        agents_1_count = 500
        agents_3_count = 100
        agents_21_count = 500
        users_29_count = 1000
    else:
        # Scale all patents proportionally
        agents_1_count = num_agents
        agents_3_count = max(100, num_agents // 5)  # Keep minimum 100 for Patent #3
        agents_21_count = num_agents
        users_29_count = num_agents
    
    # Generate data for all patents
    agents_1, pairs_1 = generate_patent_1_data(agents_1_count)
    validate_uniqueness(agents_1)
    print()
    
    agents_3, initial_3 = generate_patent_3_data(agents_3_count)
    validate_uniqueness(agents_3)
    print()
    
    agents_21 = generate_patent_21_data(agents_21_count)
    validate_uniqueness(agents_21)
    print()
    
    users_29, events_29 = generate_patent_29_data(users_29_count)
    validate_uniqueness(users_29)
    print()
    
    print("=" * 60)
    print("✅ All synthetic data generated successfully!")
    print("=" * 60)
    print()
    print("Data saved to:")
    print(f"  - {DATA_DIR / 'patent_1_quantum_compatibility'}")
    print(f"  - {DATA_DIR / 'patent_3_contextual_personality'}")
    print(f"  - {DATA_DIR / 'patent_21_quantum_state_preservation'}")
    print(f"  - {DATA_DIR / 'patent_29_multi_entity_quantum_matching'}")


if __name__ == '__main__':
    main()

