"""
AVRAI Data Loader for Quantum Experiments

Loads sample data from AVRAI for quantum hardware experiments.
Uses the Big Five → SPOTS conversion for real personality data.

Maps to AVRAI data sources:
- data/raw/big_five.csv (100k+ Big Five OCEAN profiles)
- scripts/personality_data/converters/big_five_to_spots.py
- packages/avrai_core/lib/models/personality_knot.dart
- packages/avrai_knot/lib/models/knot/knot_worldsheet.dart
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import numpy as np

# AVRAI's 12 core personality dimensions
AVRAI_DIMENSIONS = [
    'exploration_eagerness',
    'community_orientation', 
    'authenticity_preference',
    'social_discovery_style',
    'temporal_flexibility',
    'location_adventurousness',
    'curation_tendency',
    'trust_network_reliance',
    'energy_preference',
    'novelty_seeking',
    'value_orientation',
    'crowd_tolerance',
]


def get_project_root() -> Path:
    """Get AVRAI project root directory."""
    current = Path(__file__).resolve()
    # Navigate up from common/ to quantum_hardware_experiments/ to quantum_computing/ 
    # to plans/ to docs/ to AVRAI/
    for _ in range(6):
        current = current.parent
    return current


def load_sample_profiles(
    n_profiles: int = 10,
    source: str = 'auto'
) -> List[Dict[str, float]]:
    """
    Load sample personality profiles for experiments.
    
    Uses real Big Five data converted to SPOTS 12 dimensions
    when available, otherwise generates synthetic profiles.
    
    Args:
        n_profiles: Number of profiles to load
        source: 'auto', 'real', or 'synthetic'
    
    Returns:
        List of personality profile dicts
    """
    if source in ['auto', 'real']:
        try:
            profiles = _load_real_profiles(n_profiles)
            if profiles:
                return profiles
        except Exception as e:
            print(f"Could not load real profiles: {e}")
            if source == 'real':
                raise
    
    # Fall back to synthetic profiles
    return _generate_synthetic_profiles(n_profiles)


def _load_real_profiles(n_profiles: int) -> List[Dict[str, float]]:
    """Load profiles from Big Five → SPOTS converted data."""
    project_root = get_project_root()
    
    # Try JSON file first
    json_path = project_root / 'data' / 'raw' / 'big_five_spots.json'
    if json_path.exists():
        with open(json_path, 'r') as f:
            data = json.load(f)
        
        profiles = []
        for item in data[:n_profiles]:
            if 'dimensions' in item:
                profiles.append(item['dimensions'])
            elif 'original_data' in item and 'big_five' in item['original_data']:
                # Convert Big Five to SPOTS
                profiles.append(_convert_big_five_to_spots(item['original_data']['big_five']))
        
        return profiles
    
    # Try CSV file
    csv_path = project_root / 'data' / 'raw' / 'big_five.csv'
    if csv_path.exists():
        import csv
        profiles = []
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for i, row in enumerate(reader):
                if i >= n_profiles:
                    break
                big_five = {
                    'openness': float(row.get('openness', row.get('O', 0.5))),
                    'conscientiousness': float(row.get('conscientiousness', row.get('C', 0.5))),
                    'extraversion': float(row.get('extraversion', row.get('E', 0.5))),
                    'agreeableness': float(row.get('agreeableness', row.get('A', 0.5))),
                    'neuroticism': float(row.get('neuroticism', row.get('N', 0.5))),
                }
                profiles.append(_convert_big_five_to_spots(big_five))
        
        return profiles
    
    return []


def _convert_big_five_to_spots(big_five: Dict[str, float]) -> Dict[str, float]:
    """
    Convert Big Five OCEAN to SPOTS 12 dimensions.
    
    Mapping based on psychological research and AVRAI's dimension definitions.
    See: scripts/personality_data/converters/big_five_to_spots.py
    """
    O = big_five.get('openness', 0.5)
    C = big_five.get('conscientiousness', 0.5)
    E = big_five.get('extraversion', 0.5)
    A = big_five.get('agreeableness', 0.5)
    N = big_five.get('neuroticism', 0.5)
    
    return {
        'exploration_eagerness': np.clip(0.6 * O + 0.3 * E + 0.1 * (1 - N), 0, 1),
        'community_orientation': np.clip(0.5 * E + 0.3 * A + 0.2 * (1 - N), 0, 1),
        'authenticity_preference': np.clip(0.4 * O + 0.3 * A + 0.3 * (1 - N), 0, 1),
        'social_discovery_style': np.clip(0.6 * E + 0.2 * O + 0.2 * A, 0, 1),
        'temporal_flexibility': np.clip(0.4 * O + 0.3 * (1 - C) + 0.3 * (1 - N), 0, 1),
        'location_adventurousness': np.clip(0.5 * O + 0.3 * E + 0.2 * (1 - N), 0, 1),
        'curation_tendency': np.clip(0.4 * C + 0.3 * A + 0.3 * O, 0, 1),
        'trust_network_reliance': np.clip(0.5 * A + 0.3 * (1 - O) + 0.2 * (1 - N), 0, 1),
        'energy_preference': np.clip(0.6 * E + 0.2 * O + 0.2 * (1 - N), 0, 1),
        'novelty_seeking': np.clip(0.6 * O + 0.3 * E + 0.1 * (1 - C), 0, 1),
        'value_orientation': np.clip(0.4 * C + 0.3 * O + 0.3 * (1 - N), 0, 1),
        'crowd_tolerance': np.clip(0.5 * E + 0.3 * A + 0.2 * (1 - N), 0, 1),
    }


def _generate_synthetic_profiles(n_profiles: int) -> List[Dict[str, float]]:
    """Generate synthetic personality profiles for testing."""
    np.random.seed(42)  # Reproducible
    
    profiles = []
    for _ in range(n_profiles):
        profile = {}
        for dim in AVRAI_DIMENSIONS:
            # Use beta distribution for realistic personality spread
            profile[dim] = float(np.random.beta(2, 2))
        profiles.append(profile)
    
    return profiles


def load_sample_knot(profile: Optional[Dict[str, float]] = None) -> Dict:
    """
    Load or generate a sample personality knot.
    
    Maps to: packages/avrai_core/lib/models/personality_knot.dart
    
    Args:
        profile: Optional personality profile to generate knot from
    
    Returns:
        Dict with knot structure (invariants, braidData, etc.)
    """
    if profile is None:
        profile = load_sample_profiles(1)[0]
    
    # Generate braid data from profile
    braid_data = []
    for i, dim in enumerate(AVRAI_DIMENSIONS):
        value = profile.get(dim, 0.5)
        # Alternate positive/negative based on dimension index
        sign = 1 if i % 2 == 0 else -1
        braid_data.append(sign * value)
    
    # Calculate knot invariants (simplified)
    crossings = sum(1 for v in braid_data if abs(v) > 0.3)
    writhe = sum(1 if v > 0 else -1 for v in braid_data if abs(v) > 0.3)
    
    return {
        'agentId': 'sample_agent_001',
        'invariants': {
            'jonesPolynomial': [1.0, -1.0, 1.0, -0.5],
            'alexanderPolynomial': [1.0, -2.0, 1.0],
            'crossingNumber': max(3, crossings),
            'writhe': writhe,
            'signature': writhe // 2,
            'bridgeNumber': 2,
            'braidIndex': min(4, crossings // 2 + 1),
            'determinant': abs(writhe) + 1,
        },
        'braidData': braid_data,
        'createdAt': '2026-01-30T10:00:00Z',
    }


def load_sample_worldsheet(
    n_users: int = 4,
    n_snapshots: int = 5
) -> Dict:
    """
    Load or generate a sample worldsheet.
    
    Maps to: packages/avrai_knot/lib/models/knot/knot_worldsheet.dart
    
    A worldsheet represents group evolution over time:
    - Σ(σ, τ, t) = F(t)
    - σ = spatial parameter (position along each user's string)
    - τ = group parameter (which user)
    - t = time
    
    Args:
        n_users: Number of users in the group
        n_snapshots: Number of time snapshots
    
    Returns:
        Dict with worldsheet structure
    """
    profiles = load_sample_profiles(n_users)
    
    # Generate user strings
    user_strings = {}
    for i, profile in enumerate(profiles):
        user_id = f'user_{i:03d}'
        knot = load_sample_knot(profile)
        
        # Generate snapshots for this user's evolution
        snapshots = []
        for t in range(n_snapshots):
            evolved_knot = _evolve_knot(knot, t * 0.1)
            snapshots.append({
                'timestamp': f'2026-01-{t+1:02d}T10:00:00Z',
                'knot': evolved_knot,
            })
        
        user_strings[user_id] = {
            'initialKnot': knot,
            'snapshots': snapshots,
        }
    
    # Generate fabric snapshots
    fabric_snapshots = []
    for t in range(n_snapshots):
        fabric_snapshots.append({
            'timestamp': f'2026-01-{t+1:02d}T10:00:00Z',
            'stability': 0.7 + 0.05 * t,
            'density': 0.5 + 0.03 * t,
        })
    
    return {
        'groupId': 'sample_group_001',
        'userStrings': user_strings,
        'snapshots': fabric_snapshots,
        'initialFabric': load_sample_fabric(n_users),
        'createdAt': '2026-01-01T10:00:00Z',
        'lastUpdated': f'2026-01-{n_snapshots:02d}T10:00:00Z',
    }


def _evolve_knot(knot: Dict, time_delta: float) -> Dict:
    """Evolve knot by small time step (simplified)."""
    evolved = knot.copy()
    evolved['invariants'] = knot['invariants'].copy()
    
    # Small perturbation to crossing number and writhe
    evolved['invariants']['crossingNumber'] = max(
        3, 
        knot['invariants']['crossingNumber'] + int(np.random.normal(0, 0.5))
    )
    
    return evolved


def load_sample_fabric(n_users: int = 4) -> Dict:
    """
    Load or generate a sample knot fabric.
    
    Maps to: packages/avrai_knot/lib/models/knot/knot_fabric.dart
    
    A fabric represents the multi-strand braid of a group.
    
    Args:
        n_users: Number of users in the fabric
    
    Returns:
        Dict with fabric structure
    """
    profiles = load_sample_profiles(n_users)
    user_knots = [load_sample_knot(p) for p in profiles]
    
    # Generate braid data for fabric
    braid_data = []
    for i in range(n_users):
        for j in range(12):  # 12 dimensions
            braid_data.append(user_knots[i]['braidData'][j])
    
    return {
        'fabricId': 'sample_fabric_001',
        'userKnots': user_knots,
        'userCount': n_users,
        'braid': {
            'strandCount': n_users,
            'braidData': braid_data,
            'userToStrandIndex': {f'user_{i:03d}': i for i in range(n_users)},
        },
        'invariants': {
            'jonesPolynomial': {'coefficients': [1.0, -1.0, 0.5]},
            'alexanderPolynomial': {'coefficients': [1.0, -1.0]},
            'crossingNumber': sum(k['invariants']['crossingNumber'] for k in user_knots),
            'density': 0.5 + 0.1 * n_users,
            'stability': 0.7,
        },
        'createdAt': '2026-01-30T10:00:00Z',
    }


def load_sample_locations(n_locations: int = 5) -> List[Dict]:
    """
    Load sample location data for location experiments.
    
    Returns:
        List of location dicts with lat/lon and metadata
    """
    # Sample locations (major US cities)
    locations = [
        {'latitude': 40.7128, 'longitude': -74.0060, 'city': 'New York', 'locationType': 1.0, 'accessibilityScore': 0.9},
        {'latitude': 34.0522, 'longitude': -118.2437, 'city': 'Los Angeles', 'locationType': 1.0, 'accessibilityScore': 0.7},
        {'latitude': 41.8781, 'longitude': -87.6298, 'city': 'Chicago', 'locationType': 1.0, 'accessibilityScore': 0.85},
        {'latitude': 29.7604, 'longitude': -95.3698, 'city': 'Houston', 'locationType': 0.8, 'accessibilityScore': 0.7},
        {'latitude': 33.4484, 'longitude': -112.0740, 'city': 'Phoenix', 'locationType': 0.7, 'accessibilityScore': 0.65},
        {'latitude': 39.7392, 'longitude': -104.9903, 'city': 'Denver', 'locationType': 0.8, 'accessibilityScore': 0.75},
        {'latitude': 47.6062, 'longitude': -122.3321, 'city': 'Seattle', 'locationType': 0.9, 'accessibilityScore': 0.8},
        {'latitude': 25.7617, 'longitude': -80.1918, 'city': 'Miami', 'locationType': 0.9, 'accessibilityScore': 0.75},
    ]
    
    for loc in locations:
        loc['vibeLocationMatch'] = np.random.uniform(0.4, 0.9)
    
    return locations[:n_locations]
