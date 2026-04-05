#!/usr/bin/env python3
"""
Test All Topological Matching Improvements

Purpose: Compare all improvement strategies for topological matching:
1. Baseline (current implementation)
2. Improved polynomial distances
3. Conditional integration
4. Multiplicative integration
5. Two-stage matching
6. Optimized topological weights

Date: December 16, 2025
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Any
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.knot_validation.compare_matching_accuracy import (
    MatchingAccuracyComparator,
    load_data,
)

def test_approach(
    profiles: List[Dict],
    knots: List[Dict],
    ground_truth: List[Dict],
    approach_name: str,
    comparator: MatchingAccuracyComparator,
    use_improved_topological: bool = False,
    integration_method: str = 'weighted_average',
    topological_weights: Dict[str, float] = None
) -> Dict[str, Any]:
    """Test a specific approach."""
    ground_truth_map = {
        (gt['user_a'], gt['user_b']): gt['is_compatible']
        for gt in ground_truth
    }
    
    profile_map = {p['user_id']: p for p in profiles}
    knot_map = {k['user_id']: k for k in knots}
    
    scores = []
    ground_truth_list = []
    
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i < j:
                pair_key = (profile_a['user_id'], profile_b['user_id'])
                if pair_key not in ground_truth_map:
                    continue
                
                is_compatible = ground_truth_map[pair_key]
                
                # Calculate quantum compatibility
                quantum = comparator.calculate_quantum_compatibility(profile_a, profile_b)
                
                # Calculate topological compatibility
                knot_a = knot_map.get(profile_a['user_id'])
                knot_b = knot_map.get(profile_b['user_id'])
                
                if knot_a and knot_b:
                    if use_improved_topological:
                        if topological_weights:
                            topological = comparator.calculate_topological_compatibility_improved(
                                knot_a, knot_b,
                                jones_weight=topological_weights.get('jones', 0.35),
                                alexander_weight=topological_weights.get('alexander', 0.35),
                                crossing_weight=topological_weights.get('crossing', 0.15),
                                writhe_weight=topological_weights.get('writhe', 0.15)
                            )
                        else:
                            topological = comparator.calculate_topological_compatibility_improved(
                                knot_a, knot_b
                            )
                    else:
                        topological = comparator.calculate_topological_compatibility(knot_a, knot_b)
                    
                    # Use specified integration method
                    if integration_method == 'weighted_average':
                        integrated = comparator.calculate_integrated_compatibility(quantum, topological)
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
                        integrated = comparator.calculate_integrated_compatibility(quantum, topological)
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
    
    # Calculate baseline (quantum-only) for comparison
    quantum_scores = []
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i < j:
                pair_key = (profile_a['user_id'], profile_b['user_id'])
                if pair_key not in ground_truth_map:
                    continue
                quantum = comparator.calculate_quantum_compatibility(profile_a, profile_b)
                quantum_scores.append((quantum, ground_truth_map[pair_key]))
    
    quantum_best_accuracy = 0.0
    quantum_best_threshold = 0.5
    for threshold in np.arange(0.1, 0.9, 0.01):
        correct = sum(
            1 for score, gt in quantum_scores
            if (score >= threshold) == gt
        )
        accuracy = correct / len(quantum_scores) if quantum_scores else 0.0
        if accuracy > quantum_best_accuracy:
            quantum_best_accuracy = accuracy
            quantum_best_threshold = threshold
    
    improvement = ((best_accuracy - quantum_best_accuracy) / quantum_best_accuracy * 100) if quantum_best_accuracy > 0 else 0
    
    return {
        'approach': approach_name,
        'accuracy': best_accuracy,
        'threshold': best_threshold,
        'quantum_only_accuracy': quantum_best_accuracy,
        'quantum_only_threshold': quantum_best_threshold,
        'improvement': improvement,
        'meets_threshold': improvement >= 5.0
    }

def test_all_approaches(
    profiles: List[Dict],
    knots: List[Dict],
    ground_truth: List[Dict],
    optimal_topological_weights: Dict[str, float] = None
) -> Dict[str, Any]:
    """Test all improvement strategies."""
    print("Testing all topological matching approaches...")
    print()
    
    results = {}
    comparator = MatchingAccuracyComparator()
    
    # 1. Baseline (current implementation)
    print("1. Testing baseline (current implementation)...")
    results['baseline'] = test_approach(
        profiles, knots, ground_truth,
        'Baseline (weighted average, simplified topological)',
        comparator,
        use_improved_topological=False,
        integration_method='weighted_average'
    )
    print(f"   Accuracy: {results['baseline']['accuracy']:.2%}")
    
    # 2. Improved polynomial distances
    print("2. Testing improved polynomial distances...")
    results['polynomial'] = test_approach(
        profiles, knots, ground_truth,
        'Improved Polynomial Distances',
        comparator,
        use_improved_topological=True,
        integration_method='weighted_average'
    )
    print(f"   Accuracy: {results['polynomial']['accuracy']:.2%}")
    
    # 3. Conditional integration
    print("3. Testing conditional integration...")
    results['conditional'] = test_approach(
        profiles, knots, ground_truth,
        'Conditional Integration',
        comparator,
        use_improved_topological=True,
        integration_method='conditional'
    )
    print(f"   Accuracy: {results['conditional']['accuracy']:.2%}")
    
    # 4. Multiplicative integration
    print("4. Testing multiplicative integration...")
    results['multiplicative'] = test_approach(
        profiles, knots, ground_truth,
        'Multiplicative Integration',
        comparator,
        use_improved_topological=True,
        integration_method='multiplicative'
    )
    print(f"   Accuracy: {results['multiplicative']['accuracy']:.2%}")
    
    # 5. Two-stage matching
    print("5. Testing two-stage matching...")
    results['two_stage'] = test_approach(
        profiles, knots, ground_truth,
        'Two-Stage Matching',
        comparator,
        use_improved_topological=True,
        integration_method='two_stage'
    )
    print(f"   Accuracy: {results['two_stage']['accuracy']:.2%}")
    
    # 6. Optimized topological weights (if available)
    if optimal_topological_weights:
        print("6. Testing optimized topological weights...")
        results['optimized_weights'] = test_approach(
            profiles, knots, ground_truth,
            'Optimized Topological Weights',
            comparator,
            use_improved_topological=True,
            integration_method=optimal_topological_weights.get('integration_method', 'weighted_average'),
            topological_weights={
                'jones': optimal_topological_weights.get('jones_weight', 0.35),
                'alexander': optimal_topological_weights.get('alexander_weight', 0.35),
                'crossing': optimal_topological_weights.get('crossing_weight', 0.15),
                'writhe': optimal_topological_weights.get('writhe_weight', 0.15)
            }
        )
        print(f"   Accuracy: {results['optimized_weights']['accuracy']:.2%}")
    
    return results

def main():
    """Main test script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Test all topological matching improvements')
    parser.add_argument('--profiles', type=str,
                       default="test/fixtures/personality_profiles.json",
                       help='Path to personality profiles JSON file')
    parser.add_argument('--knots', type=str,
                       default="docs/plans/knot_theory/validation/knot_generation_results.json",
                       help='Path to knots JSON file')
    parser.add_argument('--ground-truth', type=str,
                       default="test/fixtures/compatibility_ground_truth.json",
                       help='Path to ground truth JSON file')
    parser.add_argument('--optimal-weights', type=str,
                       help='Path to optimal topological weights JSON file')
    parser.add_argument('--output', type=str,
                       default="docs/plans/knot_theory/validation/topological_improvements_results.json",
                       help='Output JSON file path')
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("Topological Matching Improvements Test")
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
    
    # Load optimal weights if provided
    optimal_weights = None
    if args.optimal_weights and Path(args.optimal_weights).exists():
        with open(args.optimal_weights, 'r') as f:
            optimal_weights = json.load(f)
        print(f"Loaded optimal weights from: {args.optimal_weights}")
        print()
    
    # Test all approaches
    results = test_all_approaches(profiles, knots, ground_truth, optimal_weights)
    
    # Print comparison
    print()
    print("=" * 80)
    print("RESULTS COMPARISON")
    print("=" * 80)
    print()
    
    baseline_accuracy = results['baseline']['quantum_only_accuracy']
    print(f"Quantum-Only Baseline: {baseline_accuracy:.2%}")
    print()
    
    sorted_results = sorted(results.items(), key=lambda x: x[1]['accuracy'], reverse=True)
    
    print(f"{'Approach':<40} {'Accuracy':<12} {'Improvement':<12} {'Meets ≥5%':<10}")
    print("-" * 80)
    
    for name, result in sorted_results:
        improvement = result['improvement']
        meets = "✅" if result['meets_threshold'] else "❌"
        print(f"{result['approach']:<40} {result['accuracy']:>11.2%} {improvement:>+11.2f}% {meets:>10}")
    
    print()
    
    # Find best approach
    best_name, best_result = sorted_results[0]
    print(f"🏆 Best Approach: {best_result['approach']}")
    print(f"   Accuracy: {best_result['accuracy']:.2%}")
    print(f"   Improvement: {best_result['improvement']:+.2f}%")
    print(f"   Meets ≥5% threshold: {'✅ YES' if best_result['meets_threshold'] else '❌ NO'}")
    
    # Save results
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    output_data = {
        'baseline_quantum_only': baseline_accuracy,
        'approaches': {name: result for name, result in results.items()},
        'best_approach': best_name,
        'best_result': best_result
    }
    
    with open(output_path, 'w') as f:
        json.dump(output_data, f, indent=2)
    
    print()
    print(f"💾 Results saved to: {output_path}")
    
    return results

if __name__ == '__main__':
    main()
