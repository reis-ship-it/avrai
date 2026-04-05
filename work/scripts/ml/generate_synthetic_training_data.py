#!/usr/bin/env python3
"""
Synthetic Training Data Generator for Calling Score Model
Phase 12 Section 2: Neural Network Implementation

Generates synthetic training data that mimics real calling score data
for initial model training and testing.

Usage:
    python scripts/ml/generate_synthetic_training_data.py [--num-samples NUM] [--output-path OUTPUT_PATH]
"""

import argparse
import json
import os
import random
from pathlib import Path
from typing import Dict, List

import numpy as np


def generate_synthetic_record(seed: int = None) -> Dict:
    """
    Generate a single synthetic training record
    
    Args:
        seed: Random seed for reproducibility
    
    Returns:
        Dictionary with training record structure
    """
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
    
    # Generate user vibe dimensions (12D)
    user_vibe = {}
    dimension_names = [
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
    for dim in dimension_names:
        # Generate values with some correlation
        user_vibe[dim] = round(np.random.beta(2, 2), 4)
    
    # Generate spot vibe dimensions (12D)
    # Correlate with user vibe but add some variation
    spot_vibe = {}
    for dim in dimension_names:
        # Spot vibe is correlated with user vibe but has its own variation
        base_value = user_vibe[dim]
        variation = np.random.normal(0, 0.2)
        spot_vibe[dim] = round(np.clip(base_value + variation, 0.0, 1.0), 4)
    
    # Generate context features (10 features)
    context_features = {
        'location_proximity': round(np.random.beta(2, 2), 4),
        'journey_alignment': round(np.random.beta(2, 2), 4),
        'user_receptivity': round(np.random.beta(2, 2), 4),
        'opportunity_availability': round(np.random.beta(2, 2), 4),
        'network_effects': round(np.random.beta(2, 2), 4),
        'community_patterns': round(np.random.beta(2, 2), 4),
    }
    # Add 4 placeholder context features
    for i in range(4):
        context_features[f'context_feature_{i+7}'] = round(np.random.beta(2, 2), 4)
    
    # Generate timing features (5 features)
    timing_features = {
        'optimal_time_of_day': round(np.random.beta(2, 2), 4),
        'optimal_day_of_week': round(np.random.beta(2, 2), 4),
        'user_patterns': round(np.random.beta(2, 2), 4),
        'opportunity_timing': round(np.random.beta(2, 2), 4),
        'timing_feature_5': round(np.random.beta(2, 2), 4),
    }
    
    # Calculate formula-based calling score (simplified version)
    # This mimics the actual formula-based calculation
    vibe_compatibility = np.mean([
        1.0 - abs(user_vibe[dim] - spot_vibe[dim])
        for dim in dimension_names
    ])
    
    context_factor = np.mean(list(context_features.values())[:6])
    timing_factor = np.mean(list(timing_features.values())[:4])
    
    formula_calling_score = round(
        (vibe_compatibility * 0.50 + context_factor * 0.30 + timing_factor * 0.20),
        4
    )
    formula_calling_score = np.clip(formula_calling_score, 0.0, 1.0)
    
    # Determine if user was "called" (threshold-based)
    is_called = formula_calling_score >= 0.6
    
    # Generate outcome score
    # If called, outcome is correlated with calling score but has noise
    if is_called:
        # Positive outcomes are more likely with higher calling scores
        base_outcome = formula_calling_score
        noise = np.random.normal(0, 0.15)
        outcome_score = round(np.clip(base_outcome + noise, 0.0, 1.0), 4)
    else:
        # Lower outcomes for not-called cases
        outcome_score = round(np.random.beta(1, 3), 4)
    
    # Determine outcome type
    if outcome_score >= 0.7:
        outcome_type = 'positive'
    elif outcome_score >= 0.4:
        outcome_type = 'neutral'
    else:
        outcome_type = 'negative'
    
    return {
        'user_vibe_dimensions': user_vibe,
        'spot_vibe_dimensions': spot_vibe,
        'context_features': context_features,
        'timing_features': timing_features,
        'formula_calling_score': formula_calling_score,
        'is_called': is_called,
        'outcome_type': outcome_type,
        'outcome_score': outcome_score,
    }


def generate_synthetic_dataset(num_samples: int, output_path: str):
    """
    Generate synthetic training dataset
    
    Args:
        num_samples: Number of samples to generate
        output_path: Path to output JSON file
    """
    print(f"Generating {num_samples} synthetic training samples...")
    
    records = []
    for i in range(num_samples):
        record = generate_synthetic_record(seed=i)
        records.append(record)
        
        if (i + 1) % 1000 == 0:
            print(f"Generated {i + 1}/{num_samples} samples...")
    
    # Create output structure
    output_data = {
        'metadata': {
            'num_samples': num_samples,
            'generated_by': 'generate_synthetic_training_data.py',
            'description': 'Synthetic training data for calling score neural network model',
        },
        'training_data': records,
    }
    
    # Write to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        # Convert numpy types to native Python types for JSON serialization
        def convert_to_native(obj):
            if isinstance(obj, np.integer):
                return int(obj)
            elif isinstance(obj, np.floating):
                return float(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            elif isinstance(obj, dict):
                return {key: convert_to_native(value) for key, value in obj.items()}
            elif isinstance(obj, list):
                return [convert_to_native(item) for item in obj]
            elif isinstance(obj, (np.bool_, bool)):
                return bool(obj)
            return obj
        
        output_data_native = convert_to_native(output_data)
        json.dump(output_data_native, f, indent=2)
    
    print(f"✅ Generated {num_samples} synthetic samples")
    print(f"Saved to: {output_path}")
    
    # Print statistics
    called_count = sum(1 for r in records if r['is_called'])
    positive_outcomes = sum(1 for r in records if r['outcome_type'] == 'positive')
    
    print(f"\nStatistics:")
    print(f"  - Called: {called_count} ({called_count/num_samples*100:.1f}%)")
    print(f"  - Not Called: {num_samples - called_count} ({(num_samples-called_count)/num_samples*100:.1f}%)")
    print(f"  - Positive Outcomes: {positive_outcomes} ({positive_outcomes/num_samples*100:.1f}%)")
    print(f"  - Average Calling Score: {np.mean([r['formula_calling_score'] for r in records]):.4f}")
    print(f"  - Average Outcome Score: {np.mean([r['outcome_score'] for r in records]):.4f}")


def main():
    parser = argparse.ArgumentParser(description='Generate synthetic training data for calling score model')
    parser.add_argument(
        '--num-samples',
        type=int,
        default=10000,
        help='Number of synthetic samples to generate',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default='data/calling_score_training_data.json',
        help='Path to output JSON file',
    )
    
    args = parser.parse_args()
    
    generate_synthetic_dataset(args.num_samples, args.output_path)


if __name__ == '__main__':
    main()
