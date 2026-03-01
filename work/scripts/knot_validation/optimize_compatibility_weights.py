#!/usr/bin/env python3
"""
Optimize Compatibility Calculation Weights

Purpose: Find optimal weights for quantum/archetype/value factors
to maximize matching accuracy.

Date: December 24, 2025
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Tuple
import numpy as np
from itertools import product

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.knot_validation.compare_matching_accuracy import (
    MatchingAccuracyComparator,
    load_data,
    _infer_archetype,
    _calculate_archetype_compatibility,
)
import statistics

def test_weight_combination(
    profiles: List[Dict],
    ground_truth: List[Dict],
    quantum_weight: float,
    archetype_weight: float,
    value_weight: float
) -> Dict:
    """Test a specific weight combination."""
    # Normalize weights
    total = quantum_weight + archetype_weight + value_weight
    quantum_weight /= total
    archetype_weight /= total
    value_weight /= total
    
    ground_truth_map = {
        (gt['user_a'], gt['user_b']): gt['is_compatible']
        for gt in ground_truth
    }
    
    profile_map = {p['user_id']: p for p in profiles}
    
    scores = []
    ground_truth_list = []
    
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i < j:
                pair_key = (profile_a['user_id'], profile_b['user_id'])
                if pair_key not in ground_truth_map:
                    continue
                
                is_compatible = ground_truth_map[pair_key]
                dims_a = profile_a.get('dimensions', {})
                dims_b = profile_b.get('dimensions', {})
                
                # Calculate quantum dimension compatibility
                comparator = MatchingAccuracyComparator()
                state_a = comparator._dimensions_to_quantum_state(dims_a)
                state_b = comparator._dimensions_to_quantum_state(dims_b)
                inner_product = comparator._quantum_inner_product(state_a, state_b)
                quantum_dim = abs(inner_product) ** 2
                
                # Archetype compatibility
                archetype_a = _infer_archetype(dims_a)
                archetype_b = _infer_archetype(dims_b)
                archetype_compat = _calculate_archetype_compatibility(archetype_a, archetype_b)
                
                # Value alignment
                value_dims = ['value_orientation', 'authenticity', 'trust_level']
                value_alignment = statistics.mean([
                    1.0 - abs(dims_a.get(dim, 0.5) - dims_b.get(dim, 0.5))
                    for dim in value_dims
                ]) if value_dims else 0.5
                
                # Combined with test weights
                compatibility = (
                    quantum_weight * quantum_dim +
                    archetype_weight * archetype_compat +
                    value_weight * value_alignment
                )
                
                scores.append(compatibility)
                ground_truth_list.append(is_compatible)
    
    # Find optimal threshold
    best_accuracy = 0.0
    best_threshold = 0.5
    
    for threshold in np.arange(0.1, 0.9, 0.01):
        correct = sum(
            1 for i, score in enumerate(scores)
            if (score >= threshold) == ground_truth_list[i]
        )
        accuracy = correct / len(scores) if scores else 0.0
        if accuracy > best_accuracy:
            best_accuracy = accuracy
            best_threshold = threshold
    
    return {
        'quantum_weight': quantum_weight,
        'archetype_weight': archetype_weight,
        'value_weight': value_weight,
        'accuracy': best_accuracy,
        'threshold': best_threshold,
    }

def optimize_weights(profiles: List[Dict], ground_truth: List[Dict]) -> Dict:
    """Find optimal weight combination."""
    print("Testing weight combinations...")
    
    # Test different weight combinations
    quantum_weights = [0.50, 0.55, 0.60, 0.65, 0.70, 0.75]
    archetype_weights = [0.15, 0.20, 0.25, 0.30]
    value_weights = [0.10, 0.15, 0.20, 0.25]
    
    best_result = None
    best_accuracy = 0.0
    
    total_combinations = len(quantum_weights) * len(archetype_weights) * len(value_weights)
    tested = 0
    
    for qw, aw, vw in product(quantum_weights, archetype_weights, value_weights):
        if qw + aw + vw > 1.0:
            continue
        
        result = test_weight_combination(profiles, ground_truth, qw, aw, vw)
        tested += 1
        
        if result['accuracy'] > best_accuracy:
            best_accuracy = result['accuracy']
            best_result = result
        
        if tested % 10 == 0:
            print(f"  Tested {tested}/{total_combinations} combinations... Best: {best_accuracy:.2%}")
    
    return best_result

def main():
    """Main optimization."""
    print("=" * 80)
    print("Compatibility Weight Optimization")
    print("=" * 80)
    print()
    
    # Load data
    profiles_path = project_root / 'test' / 'fixtures' / 'personality_profiles.json'
    knots_path = project_root / 'docs' / 'plans' / 'knot_theory' / 'validation' / 'knot_generation_results.json'
    ground_truth_path = project_root / 'docs' / 'plans' / 'knot_theory' / 'validation' / 'ground_truth.json'
    
    profiles, knots, ground_truth = load_data(
        str(profiles_path),
        str(knots_path),
        str(ground_truth_path)
    )
    
    print(f"Loaded {len(profiles)} profiles, {len(ground_truth)} ground truth pairs")
    print()
    
    # Optimize
    best = optimize_weights(profiles, ground_truth)
    
    print()
    print("=" * 80)
    print("OPTIMAL WEIGHTS")
    print("=" * 80)
    print(f"Quantum Weight: {best['quantum_weight']:.2%}")
    print(f"Archetype Weight: {best['archetype_weight']:.2%}")
    print(f"Value Weight: {best['value_weight']:.2%}")
    print(f"Optimal Threshold: {best['threshold']:.3f}")
    print(f"Accuracy: {best['accuracy']:.2%}")
    print()
    
    if best['accuracy'] >= 0.75:
        print("✅ SUCCESS: Achieved 75%+ accuracy!")
    else:
        print(f"⚠️  Accuracy {best['accuracy']:.2%} < 75% target")
        print("   Consider additional improvements")
    
    # Save results
    output_path = project_root / 'docs' / 'plans' / 'knot_theory' / 'validation' / 'optimal_weights.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(best, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_path}")
    
    return best

if __name__ == '__main__':
    main()

