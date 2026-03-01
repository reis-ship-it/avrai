#!/usr/bin/env python3
"""
Hybrid Training Data Generator for Calling Score Model
Phase 12 Section 2: Neural Network Implementation

Generates training data using Big Five converted profiles as user vibes,
combined with synthetic spot vibes, context, timing, and outcomes.

This provides better personality distributions than 100% synthetic data
while still being synthetic for spots/context/timing/outcomes.

Usage:
    # First, convert Big Five dataset to SPOTS format:
    python scripts/knot_validation/data_converter.py data/raw/big_five.csv --output data/raw/big_five_spots.json
    
    # Then generate hybrid training data:
    python scripts/ml/generate_hybrid_training_data.py \
      data/raw/big_five_spots.json \
      --output data/calling_score_training_data_hybrid.json \
      --num-samples 10000
"""

import argparse
import json
import os
import random
import sys
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np

# Add scripts/ml to path for dataset_base import
scripts_ml_path = Path(__file__).parent
sys.path.insert(0, str(scripts_ml_path))

# Import new dataset architecture
from dataset_base import TrainingDataset, TrainingRecord, DatasetMetadata


def load_spots_profiles(spots_profiles_path: Path) -> List[Dict]:
    """Load SPOTS profiles from data_converter output"""
    if not spots_profiles_path.exists():
        raise FileNotFoundError(f"SPOTS profiles file not found: {spots_profiles_path}")
    
    with open(spots_profiles_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Handle different JSON structures
    if isinstance(data, list):
        return data
    elif isinstance(data, dict) and 'profiles' in data:
        return data['profiles']
    elif isinstance(data, dict) and 'data' in data:
        return data['data']
    else:
        # Assume it's a single profile
        return [data]


def map_spots_dimensions_to_training_format(spots_dimensions: Dict) -> Dict:
    """
    Map SPOTS dimensions from data_converter output to training format.
    
    Map SPOTS dimensions from data_converter output to training format.
    
    data_converter uses slightly different dimension names:
    - 'adventure_seeking' → 'location_adventurousness'
    - 'authenticity' → 'authenticity_preference'
    - 'trust_level' → 'trust_network_reliance'
    - 'openness' → can be used for 'curation_tendency'
    - 'social_preference' → 'social_discovery_style'
    
    Target names match VibeConstants.coreDimensions exactly.
    Missing dimensions will be derived or defaulted.
    """
    # Dimension mapping from data_converter names to training format
    # Target names match VibeConstants.coreDimensions exactly
    dimension_mapping = {
        'exploration_eagerness': 'exploration_eagerness',
        'community_orientation': 'community_orientation',
        'adventure_seeking': 'location_adventurousness',
        'social_preference': 'social_discovery_style',
        'social_discovery_style': 'social_discovery_style',
        'energy_preference': 'energy_preference',
        'novelty_seeking': 'novelty_seeking',
        'value_orientation': 'value_orientation',
        'crowd_tolerance': 'crowd_tolerance',
        'authenticity': 'authenticity_preference',
        'authenticity_preference': 'authenticity_preference',
        'trust_level': 'trust_network_reliance',
        'trust_network_reliance': 'trust_network_reliance',
        'openness': 'curation_tendency',  # Use openness as curation_tendency proxy
        'curation_tendency': 'curation_tendency',
        'temporal_flexibility': 'temporal_flexibility',
        'location_adventurousness': 'location_adventurousness',
    }
    
    training_dimensions = {}
    
    # Map known dimensions
    for spots_key, training_key in dimension_mapping.items():
        if spots_key in spots_dimensions:
            value = spots_dimensions[spots_key]
            # Ensure value is in [0.0, 1.0]
            if isinstance(value, (int, float)):
                training_dimensions[training_key] = float(np.clip(value, 0.0, 1.0))
    
    # Required dimensions for training (12 total)
    # Must match VibeConstants.coreDimensions exactly
    required_dims = [
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
    
    # Fill missing dimensions
    # temporal_flexibility: Derive from conscientiousness (if available) or use default
    if 'temporal_flexibility' not in training_dimensions:
        # If we have conscientiousness info, use inverse (high C = low flexibility)
        # Otherwise use exploration_eagerness as proxy
        if 'conscientiousness' in spots_dimensions:
            conscientiousness = float(spots_dimensions['conscientiousness'])
            training_dimensions['temporal_flexibility'] = float(1.0 - conscientiousness)
        elif 'exploration_eagerness' in training_dimensions:
            # More exploration = more flexibility
            training_dimensions['temporal_flexibility'] = training_dimensions['exploration_eagerness']
        else:
            training_dimensions['temporal_flexibility'] = 0.5
    
    # Ensure all required dimensions are present
    for dim in required_dims:
        if dim not in training_dimensions:
            # Use default or derive from other dimensions
            if dim == 'curation_tendency' and 'authenticity_preference' in training_dimensions:
                # Curation tendency correlates inversely with authenticity preference
                training_dimensions[dim] = 1.0 - training_dimensions['authenticity_preference']
            elif dim == 'location_adventurousness' and 'exploration_eagerness' in training_dimensions:
                training_dimensions[dim] = training_dimensions['exploration_eagerness']
            else:
                training_dimensions[dim] = 0.5  # Default
    
    return training_dimensions


def generate_synthetic_spot_vibe(user_vibe: Dict, seed: int = None) -> Dict:
    """
    Generate a SYNTHETIC spot vibe correlated with user vibe.
    
    This is the fallback when no real spot data is available.
    Spot vibes are somewhat compatible with user vibes with variation.
    """
    if seed is not None:
        np.random.seed(seed)
    
    spot_vibe = {}
    for dim, value in user_vibe.items():
        correlation = np.random.uniform(0.6, 0.9)
        variation = np.random.normal(0, 0.15)
        spot_vibe[dim] = float(np.clip(value * correlation + variation, 0.0, 1.0))
    
    return spot_vibe


def load_real_spot_vibes(spot_vibes_path: Path) -> List[Dict]:
    """Load real spot vibes from spot_vibe_converter output."""
    if not spot_vibes_path.exists():
        raise FileNotFoundError(f"Real spot vibes file not found: {spot_vibes_path}")
    
    with open(spot_vibes_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    spots = data.get('spots', [])
    return spots


def select_real_spot(real_spots: List[Dict], user_vibe: Dict, compatibility_target: str, seed: int = None) -> Dict:
    """
    Select a real spot with a target compatibility level.
    
    Args:
        real_spots: List of real spot records with vibe_dimensions
        user_vibe: User vibe dimensions
        compatibility_target: 'high', 'medium', or 'low'
        seed: Random seed
    
    Returns:
        Selected spot's vibe dimensions and metadata
    """
    if seed is not None:
        np.random.seed(seed)
    
    # Calculate compatibility with all spots (fast: just mean dimension similarity)
    compatibilities = []
    for spot in real_spots:
        spot_dims = spot.get('vibe_dimensions', {})
        if not spot_dims:
            continue
        sim = np.mean([
            1.0 - abs(user_vibe.get(dim, 0.5) - spot_dims.get(dim, 0.5))
            for dim in user_vibe.keys()
        ])
        compatibilities.append((sim, spot))
    
    if not compatibilities:
        # Fallback to synthetic
        return {
            'vibe_dimensions': generate_synthetic_spot_vibe(user_vibe, seed=seed),
            'rating': None,
            'price_level': None,
            'review_count': None,
        }
    
    compatibilities.sort(key=lambda x: x[0])
    n = len(compatibilities)
    
    # Select from appropriate quartile
    if compatibility_target == 'high':
        idx = np.random.randint(int(n * 0.75), n)
    elif compatibility_target == 'low':
        idx = np.random.randint(0, max(1, int(n * 0.25)))
    else:  # medium
        idx = np.random.randint(int(n * 0.25), int(n * 0.75))
    
    return compatibilities[idx][1]


def generate_context_features(seed: int = None) -> Dict:
    """Generate context features (synthetic)"""
    if seed is not None:
        np.random.seed(seed)
    
    context_features = {
        'location_proximity': round(float(np.random.beta(2, 2)), 4),
        'journey_alignment': round(float(np.random.beta(2, 2)), 4),
        'user_receptivity': round(float(np.random.beta(2, 2)), 4),
        'opportunity_availability': round(float(np.random.beta(2, 2)), 4),
        'network_effects': round(float(np.random.beta(2, 2)), 4),
        'community_patterns': round(float(np.random.beta(2, 2)), 4),
    }
    
    # Add 4 placeholder context features
    for i in range(4):
        context_features[f'context_feature_{i+7}'] = round(float(np.random.beta(2, 2)), 4)
    
    return context_features


def generate_timing_features(seed: int = None) -> Dict:
    """Generate timing features (synthetic)"""
    if seed is not None:
        np.random.seed(seed)
    
    timing_features = {
        'optimal_time_of_day': round(float(np.random.beta(2, 2)), 4),
        'optimal_day_of_week': round(float(np.random.beta(2, 2)), 4),
        'user_patterns': round(float(np.random.beta(2, 2)), 4),
        'opportunity_timing': round(float(np.random.beta(2, 2)), 4),
        'timing_feature_5': round(float(np.random.beta(2, 2)), 4),
    }
    
    return timing_features


def calculate_formula_calling_score(
    user_vibe: Dict,
    spot_vibe: Dict,
    context_features: Dict,
    timing_features: Dict,
) -> float:
    """
    Calculate formula-based calling score matching the full Dart implementation.
    
    This matches lib/core/services/calling_score_calculator.dart:
        vibeCompatibility * 0.40 +
        lifeBetterment * 0.30 +
        meaningfulConnectionProb * 0.15 +
        contextFactor * 0.10 +
        timingFactor * 0.05
    
    See the Dart code for the authoritative implementation.
    """
    # 1. Vibe Compatibility (40% weight)
    # Matches SpotVibe.calculateVibeCompatibility()
    dimension_similarities = [
        1.0 - abs(user_vibe.get(dim, 0.5) - spot_vibe.get(dim, 0.5))
        for dim in user_vibe.keys()
    ]
    dimension_compatibility = float(np.mean(dimension_similarities)) if dimension_similarities else 0.5

    # Derived metrics for spot (matching Dart _calculateOverallEnergy etc.)
    spot_energy = (spot_vibe.get('energy_preference', 0.5) + spot_vibe.get('exploration_eagerness', 0.5)) / 2.0
    spot_social = (spot_vibe.get('community_orientation', 0.5) + spot_vibe.get('social_discovery_style', 0.5)) / 2.0
    spot_exploration = (spot_vibe.get('exploration_eagerness', 0.5) + spot_vibe.get('novelty_seeking', 0.5)) / 2.0

    user_energy = (user_vibe.get('energy_preference', 0.5) + user_vibe.get('exploration_eagerness', 0.5)) / 2.0
    user_social = (user_vibe.get('community_orientation', 0.5) + user_vibe.get('social_discovery_style', 0.5)) / 2.0
    user_exploration = (user_vibe.get('exploration_eagerness', 0.5) + user_vibe.get('novelty_seeking', 0.5)) / 2.0

    energy_compat = 1.0 - abs(spot_energy - user_energy)
    exploration_compat = 1.0 - abs(spot_exploration - user_exploration)
    social_compat = 1.0 - abs(spot_social - user_social)

    vibe_compatibility = float(np.clip(
        dimension_compatibility * 0.5 +
        energy_compat * 0.2 +
        exploration_compat * 0.15 +
        social_compat * 0.15,
        0.0, 1.0,
    ))

    # 2. Life Betterment Factor (30% weight)
    # Matches _calculateLifeBettermentFactor():
    #   trajectoryPotential * 0.40 + meaningfulConn * 0.30 + positiveInfluence * 0.20 + fulfillment * 0.10
    trajectory_potential = float(np.clip(
        dimension_compatibility * 0.7 + 0.3 * np.random.beta(3, 2),
        0.0, 1.0,
    ))

    # Meaningful connection probability (sub-formula)
    network_effects = context_features.get('network_effects', 0.5)
    community_patterns = context_features.get('community_patterns', 0.5)
    connection_potential = (spot_energy * 0.5 + spot_social * 0.5)
    meaningful_connection_prob = float(np.clip(
        vibe_compatibility * 0.40 +
        network_effects * 0.25 +
        community_patterns * 0.20 +
        connection_potential * 0.15,
        0.0, 1.0,
    ))

    # Positive influence score
    positive_influence = float(np.clip(
        dimension_compatibility * 0.6 + 0.4 * np.random.beta(3, 2),
        0.0, 1.0,
    ))

    # Fulfillment potential
    fulfillment_potential = float(np.clip(
        energy_compat * 0.40 +
        exploration_compat * 0.35 +
        social_compat * 0.25,
        0.0, 1.0,
    ))

    life_betterment = float(np.clip(
        trajectory_potential * 0.40 +
        meaningful_connection_prob * 0.30 +
        positive_influence * 0.20 +
        fulfillment_potential * 0.10,
        0.0, 1.0,
    ))

    # 3. Meaningful Connection Probability (15% weight) -- already computed above

    # 4. Context Factor (10% weight)
    # Matches _calculateContextFactor() multiplicative logic
    context_factor = 1.0
    proximity = context_features.get('location_proximity', 0.5)
    if proximity < 0.5:
        context_factor *= 0.9
    elif proximity > 0.8:
        context_factor *= 1.1
    journey = context_features.get('journey_alignment', 0.5)
    context_factor *= (0.8 + journey * 0.2)
    receptivity = context_features.get('user_receptivity', 0.5)
    context_factor *= (0.7 + receptivity * 0.3)
    availability = context_features.get('opportunity_availability', 0.5)
    context_factor *= availability
    context_factor = float(np.clip(context_factor, 0.0, 1.0))

    # 5. Timing Factor (5% weight)
    # Matches _calculateTimingFactor() multiplicative logic
    timing_factor = 1.0
    time_of_day = timing_features.get('optimal_time_of_day', 0.5)
    timing_factor *= (0.8 + time_of_day * 0.2)
    day_of_week = timing_features.get('optimal_day_of_week', 0.5)
    timing_factor *= (0.8 + day_of_week * 0.2)
    user_patterns = timing_features.get('user_patterns', 0.5)
    timing_factor *= (0.7 + user_patterns * 0.3)
    opp_timing = timing_features.get('opportunity_timing', 0.5)
    timing_factor *= opp_timing
    timing_factor = float(np.clip(timing_factor, 0.0, 1.0))

    # Full 5-component weighted formula
    formula_calling_score = (
        vibe_compatibility * 0.40 +
        life_betterment * 0.30 +
        meaningful_connection_prob * 0.15 +
        context_factor * 0.10 +
        timing_factor * 0.05
    )

    return float(np.clip(formula_calling_score, 0.0, 1.0))


def generate_outcome(formula_calling_score: float, is_called: bool, seed: int = None) -> tuple:
    """
    Generate outcome based on calling score.
    
    Returns:
        (outcome_type, outcome_score)
    """
    if seed is not None:
        np.random.seed(seed)
    
    if is_called:
        # Positive outcomes more likely with higher calling scores
        # Add some noise for realism
        outcome_score = float(np.clip(
            formula_calling_score + np.random.normal(0, 0.1),
            0.0, 1.0
        ))
        outcome_type = 'positive' if outcome_score >= 0.7 else 'neutral'
    else:
        # Not called = negative or neutral outcome
        outcome_score = float(np.random.uniform(0.0, 0.5))
        outcome_type = 'negative' if outcome_score < 0.3 else 'neutral'
    
    return outcome_type, outcome_score


def generate_training_record(
    spots_profile: Dict,
    record_index: int = 0,
    real_spots: Optional[List[Dict]] = None,
) -> TrainingRecord:
    """
    Generate training record from SPOTS profile.
    
    Args:
        spots_profile: Profile from data_converter output
        record_index: Index for this record (for seeding)
        real_spots: Optional list of real spot records with vibe_dimensions.
                    If provided, uses real spot data instead of synthetic.
    
    Returns:
        TrainingRecord object
    """
    # Get user vibe from converted profile
    spots_dimensions = spots_profile.get('dimensions', {})
    user_vibe = map_spots_dimensions_to_training_format(spots_dimensions)
    
    # Select spot vibe -- real or synthetic
    spot_metadata = {}
    if real_spots and len(real_spots) > 0:
        # Vary compatibility target: 40% high, 30% medium, 30% low
        rng = np.random.RandomState(record_index)
        target_roll = rng.random()
        if target_roll < 0.4:
            compat_target = 'high'
        elif target_roll < 0.7:
            compat_target = 'medium'
        else:
            compat_target = 'low'
        
        selected_spot = select_real_spot(real_spots, user_vibe, compat_target, seed=record_index)
        spot_vibe = selected_spot.get('vibe_dimensions', generate_synthetic_spot_vibe(user_vibe, seed=record_index))
        spot_metadata = {
            'rating': selected_spot.get('rating'),
            'price_level': selected_spot.get('price_level'),
            'review_count': selected_spot.get('review_count'),
        }
    else:
        spot_vibe = generate_synthetic_spot_vibe(user_vibe, seed=record_index)
    
    # Generate context and timing (synthetic but semi-realistic)
    context_features = generate_context_features(seed=record_index + 1000)
    timing_features = generate_timing_features(seed=record_index + 2000)
    
    # Add extra features from spot metadata if available
    if spot_metadata.get('rating') is not None:
        context_features['spot_rating'] = round(float(spot_metadata['rating']) / 5.0, 4)
    else:
        context_features['spot_rating'] = round(float(np.random.beta(5, 2)), 4)
    
    if spot_metadata.get('price_level') is not None:
        context_features['spot_price_level'] = round(float(spot_metadata['price_level']) / 4.0, 4)
    else:
        context_features['spot_price_level'] = round(float(np.random.beta(2, 2)), 4)
    
    if spot_metadata.get('review_count') is not None:
        # Normalize review count: log scale, cap at 10000
        rc = min(spot_metadata['review_count'], 10000)
        context_features['spot_popularity'] = round(float(np.log1p(rc) / np.log1p(10000)), 4)
    else:
        context_features['spot_popularity'] = round(float(np.random.beta(2, 3)), 4)
    
    # Distance feature (randomized)
    context_features['distance_km'] = round(float(np.random.exponential(3.0)), 4)
    
    # Calculate calling score using the full 5-component formula
    formula_calling_score = calculate_formula_calling_score(
        user_vibe, spot_vibe, context_features, timing_features
    )
    
    is_called = formula_calling_score >= 0.7
    
    # Generate outcome
    outcome_type, outcome_score = generate_outcome(
        formula_calling_score, is_called, seed=record_index + 3000
    )
    
    # Get user_id from profile if available
    user_id = spots_profile.get('user_id') or spots_profile.get('id')
    
    return TrainingRecord(
        user_vibe_dimensions=user_vibe,
        spot_vibe_dimensions=spot_vibe,
        context_features=context_features,
        timing_features=timing_features,
        formula_calling_score=round(formula_calling_score, 4),
        is_called=is_called,
        outcome_type=outcome_type,
        outcome_score=round(outcome_score, 4),
        user_id=str(user_id) if user_id else None,
    )


def generate_hybrid_dataset(
    spots_profiles_path: Path,
    output_path: Path,
    num_samples: int = 10000,
    records_per_profile: int = None,
    spot_vibes_path: Optional[Path] = None,
):
    """
    Generate hybrid training dataset using new dataset architecture.
    
    Args:
        spots_profiles_path: Path to SPOTS profiles JSON (from data_converter.py)
        output_path: Path to save training data JSON
        num_samples: Total number of training samples to generate
        records_per_profile: Number of records per profile (auto-calculated if None)
    """
    print(f"Loading SPOTS profiles from: {spots_profiles_path}")
    spots_profiles = load_spots_profiles(spots_profiles_path)
    
    if len(spots_profiles) == 0:
        raise ValueError(f"No profiles found in {spots_profiles_path}")
    
    print(f"Loaded {len(spots_profiles)} SPOTS profiles")
    
    # Load real spot vibes if available
    real_spots = None
    if spot_vibes_path and spot_vibes_path.exists():
        real_spots = load_real_spot_vibes(spot_vibes_path)
        print(f"Loaded {len(real_spots)} real spot vibes from {spot_vibes_path}")
    elif spot_vibes_path:
        print(f"Warning: Real spot vibes file not found: {spot_vibes_path}")
        print("Falling back to synthetic spot vibes")
    
    # Calculate records per profile
    if records_per_profile is None:
        records_per_profile = max(1, num_samples // len(spots_profiles))
    
    print(f"Generating {records_per_profile} records per profile...")
    
    # Create dataset with metadata
    source = 'real_osm_google_big_five' if real_spots else 'hybrid_big_five'
    desc = (
        'Training data using Big Five profiles + real OSM/Google spot vibes + full 5-component calling score'
        if real_spots
        else 'Hybrid training data using Big Five converted profiles (real personality + synthetic spots/context/timing)'
    )
    metadata = DatasetMetadata(
        num_samples=0,  # Will be updated as records are added
        source=source,
        description=desc,
        user_profiles_source=str(spots_profiles_path),
        records_per_profile=records_per_profile,
        generation_params={
            'num_samples': num_samples,
            'records_per_profile': records_per_profile,
            'spot_vibes_path': str(spot_vibes_path) if spot_vibes_path else None,
            'real_spots_count': len(real_spots) if real_spots else 0,
            'formula': '5-component (vibe 40%, life_betterment 30%, meaningful_conn 15%, context 10%, timing 5%)',
        },
    )
    
    dataset = TrainingDataset(metadata=metadata)
    
    # Generate training records
    record_index = 0
    
    for profile in spots_profiles:
        for _ in range(records_per_profile):
            if record_index >= num_samples:
                break
            
            record = generate_training_record(
                profile,
                record_index=record_index,
                real_spots=real_spots,
            )
            dataset.add_record(record)
            record_index += 1
        
        if record_index >= num_samples:
            break
    
    # Trim to exact number if needed
    dataset.records = dataset.records[:num_samples]
    dataset.metadata.num_samples = len(dataset.records)
    
    # Calculate statistics
    dataset.calculate_statistics()
    
    # Validate dataset
    validation_issues = dataset.validate()
    if validation_issues:
        print(f"⚠️  Validation warnings ({len(validation_issues)}):")
        for issue in validation_issues[:10]:  # Show first 10
            print(f"   - {issue}")
        if len(validation_issues) > 10:
            print(f"   ... and {len(validation_issues) - 10} more")
    
    # Save dataset
    dataset.save(output_path)
    
    # Print summary
    stats = dataset.metadata.statistics
    print(f"\n✅ Generated {len(dataset)} hybrid training records")
    print(f"   Saved to: {output_path}")
    print(f"\n📊 Statistics:")
    print(f"   Called: {stats.get('called_percentage', 0):.1f}%")
    print(f"   Positive outcomes: {stats.get('positive_outcome_percentage', 0):.1f}%")
    print(f"   Average calling score: {stats.get('average_calling_score', 0):.4f}")
    print(f"   Average outcome score: {stats.get('average_outcome_score', 0):.4f}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Generate hybrid training data using Big Five converted profiles',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Step 1: Convert Big Five dataset to SPOTS format
  python scripts/knot_validation/data_converter.py data/raw/big_five.csv --output data/raw/big_five_spots.json
  
  # Step 2: Generate hybrid training data
  python scripts/ml/generate_hybrid_training_data.py \\
    data/raw/big_five_spots.json \\
    --output data/calling_score_training_data_hybrid.json \\
    --num-samples 10000
        """
    )
    
    parser.add_argument(
        'spots_profiles',
        type=Path,
        help='Path to SPOTS profiles JSON (from data_converter.py)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/calling_score_training_data.json'),
        help='Output training data JSON path (default: data/calling_score_training_data.json)'
    )
    parser.add_argument(
        '--num-samples',
        type=int,
        default=10000,
        help='Number of training samples to generate (default: 10000)'
    )
    parser.add_argument(
        '--records-per-profile',
        type=int,
        default=None,
        help='Number of records per profile (auto-calculated if not specified)'
    )
    parser.add_argument(
        '--spot-vibes',
        type=Path,
        default=None,
        help='Path to real spot vibes JSON (from spot_vibe_converter.py). If provided, uses real spots instead of synthetic.'
    )
    
    args = parser.parse_args()
    
    try:
        generate_hybrid_dataset(
            args.spots_profiles,
            args.output,
            args.num_samples,
            args.records_per_profile,
            spot_vibes_path=args.spot_vibes,
        )
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
