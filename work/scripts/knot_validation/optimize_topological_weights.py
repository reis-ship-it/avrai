#!/usr/bin/env python3
"""
Optimize Topological Compatibility Weights

Purpose: Find optimal weights for topological components (Jones, Alexander, crossing, writhe)
to maximize matching accuracy when combined with quantum compatibility.

Date: December 16, 2025
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
)

def test_topological_weights(
    profiles: List[Dict],
    knots: List[Dict],
    ground_truth: List[Dict],
    jones_weight: float,
    alexander_weight: float,
    crossing_weight: float,
    writhe_weight: float,
    integration_method: str = 'weighted_average'
) -> Dict:
    """Test a specific topological weight combination."""
    # Normalize weights
    total = jones_weight + alexander_weight + crossing_weight + writhe_weight
    if total > 0:
        jones_weight /= total
        alexander_weight /= total
        crossing_weight /= total
        writhe_weight /= total
    
    ground_truth_map = {
        (gt['user_a'], gt['user_b']): gt['is_compatible']
        for gt in ground_truth
    }
    
    profile_map = {p['user_id']: p for p in profiles}
    knot_map = {k['user_id']: k for k in knots}
    
    scores = []
    ground_truth_list = []
    
    comparator = MatchingAccuracyComparator()
    
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i < j:
                pair_key = (profile_a['user_id'], profile_b['user_id'])
                if pair_key not in ground_truth_map:
                    continue
                
                is_compatible = ground_truth_map[pair_key]
                
                # Calculate quantum compatibility
                quantum = comparator.calculate_quantum_compatibility(profile_a, profile_b)
                
                # Calculate topological compatibility with test weights
                knot_a = knot_map.get(profile_a['user_id'])
                knot_b = knot_map.get(profile_b['user_id'])
                
                if knot_a and knot_b:
                    topological = comparator.calculate_topological_compatibility_improved(
                        knot_a, knot_b,
                        jones_weight=jones_weight,
                        alexander_weight=alexander_weight,
                        crossing_weight=crossing_weight,
                        writhe_weight=writhe_weight
                    )
                    
                    # Use specified integration method
                    if integration_method == 'weighted_average':
                        integrated = 0.7 * quantum + 0.3 * topological
                    elif integration_method == 'conditional':
                        integrated = comparator.calculate_integrated_compatibility_conditional(
                            quantum, topological
                        )
                    elif integration_method == 'multiplicative':
                        integrated = comparator.calculate_integrated_compatibility_multiplicative(
                            quantum, topological
                        )
                    elif integration_method == 'two_stage':
                        integrated = comparator.calculate_integrated_compatibility_two_stage(
                            quantum, topological
                        )
                    else:
                        integrated = 0.7 * quantum + 0.3 * topological
                else:
                    integrated = quantum
                
                scores.append(integrated)
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
        'jones_weight': jones_weight,
        'alexander_weight': alexander_weight,
        'crossing_weight': crossing_weight,
        'writhe_weight': writhe_weight,
        'accuracy': best_accuracy,
        'threshold': best_threshold,
        'integration_method': integration_method
    }

def optimize_topological_weights(
    profiles: List[Dict],
    knots: List[Dict],
    ground_truth: List[Dict],
    integration_method: str = 'weighted_average'
) -> Dict:
    """Find optimal topological weight combination."""
    print(f"Optimizing topological weights (integration: {integration_method})...")
    
    # Test different weight combinations
    jones_weights = [0.2, 0.3, 0.35, 0.4, 0.5]
    alexander_weights = [0.2, 0.3, 0.35, 0.4, 0.5]
    crossing_weights = [0.1, 0.15, 0.2, 0.25]
    writhe_weights = [0.0, 0.1, 0.15, 0.2]
    
    best_result = None
    best_accuracy = 0.0
    
    total_combinations = len(jones_weights) * len(alexander_weights) * len(crossing_weights) * len(writhe_weights)
    tested = 0
    
    for jw in jones_weights:
        for aw in alexander_weights:
            for cw in crossing_weights:
                for ww in writhe_weights:
                    # Check if weights sum to reasonable range
                    total = jw + aw + cw + ww
                    if total < 0.8 or total > 1.2:
                        continue
                    
                    tested += 1
                    result = test_topological_weights(
                        profiles, knots, ground_truth,
                        jw, aw, cw, ww, integration_method
                    )
                    
                    if result['accuracy'] > best_accuracy:
                        best_accuracy = result['accuracy']
                        best_result = result
                    
                    if tested % 20 == 0:
                        print(f"  Tested {tested}/{total_combinations} combinations... Best: {best_accuracy:.2%}")
    
    print(f"\nBest accuracy: {best_accuracy:.2%}")
    
    return best_result

def main():
    """Main optimization."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Optimize topological compatibility weights')
    parser.add_argument('--profiles', type=str,
                       default="test/fixtures/personality_profiles.json",
                       help='Path to personality profiles JSON file')
    parser.add_argument('--knots', type=str,
                       default="docs/plans/knot_theory/validation/knot_generation_results.json",
                       help='Path to knots JSON file')
    parser.add_argument('--ground-truth', type=str,
                       default="test/fixtures/compatibility_ground_truth.json",
                       help='Path to ground truth JSON file')
    parser.add_argument('--integration', type=str,
                       choices=['weighted_average', 'conditional', 'multiplicative', 'two_stage'],
                       default='weighted_average',
                       help='Integration method to use')
    parser.add_argument('--output', type=str,
                       default="docs/plans/knot_theory/validation/optimal_topological_weights.json",
                       help='Output JSON file path')
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("Topological Weight Optimization")
    print("=" * 80)
    print()
    
    # Load data
    profiles, knots, ground_truth = load_data(
        args.profiles,
        args.knots,
        args.ground_truth
    )
    
    print(f"Loaded {len(profiles)} profiles, {len(knots)} knots, {len(ground_truth)} ground truth pairs")
    print()
    
    # Optimize
    best = optimize_topological_weights(profiles, knots, ground_truth, args.integration)
    
    print()
    print("=" * 80)
    print("OPTIMAL TOPOLOGICAL WEIGHTS")
    print("=" * 80)
    print(f"Integration Method: {best['integration_method']}")
    print(f"Jones Weight: {best['jones_weight']:.2%}")
    print(f"Alexander Weight: {best['alexander_weight']:.2%}")
    print(f"Crossing Weight: {best['crossing_weight']:.2%}")
    print(f"Writhe Weight: {best['writhe_weight']:.2%}")
    print(f"Optimal Threshold: {best['threshold']:.3f}")
    print(f"Accuracy: {best['accuracy']:.2%}")
    print()
    
    if best['accuracy'] >= 0.75:
        print("✅ SUCCESS: Achieved 75%+ accuracy!")
    else:
        print(f"⚠️  Accuracy {best['accuracy']:.2%} < 75% target")
        print("   Consider trying different integration methods")
    
    # Save results
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(best, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_path}")
    
    return best

if __name__ == '__main__':
    main()
