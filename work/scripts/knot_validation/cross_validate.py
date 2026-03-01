#!/usr/bin/env python3
"""
Cross-Validation for Knot Validation

Performs k-fold cross-validation for more robust results.
"""

import json
import sys
import os
import random
import numpy as np
from pathlib import Path
from typing import List, Dict, Any
from dataclasses import dataclass

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.knot_validation.generate_knots_from_profiles import (
    load_personality_profiles, create_sample_profiles, KnotGenerator
)
from scripts.knot_validation.compare_matching_accuracy import (
    MatchingAccuracyComparator, create_sample_ground_truth, load_data
)

@dataclass
class CrossValidationResult:
    """Results from cross-validation."""
    k_folds: int
    quantum_accuracy_mean: float
    quantum_accuracy_std: float
    integrated_accuracy_mean: float
    integrated_accuracy_std: float
    improvement_mean: float
    improvement_std: float
    fold_results: List[Dict[str, Any]]

def k_fold_split(data: List[Any], k: int, shuffle: bool = True) -> List[tuple]:
    """Split data into k folds."""
    if shuffle:
        data = data.copy()
        random.shuffle(data)
    
    fold_size = len(data) // k
    folds = []
    
    for i in range(k):
        start_idx = i * fold_size
        end_idx = (i + 1) * fold_size if i < k - 1 else len(data)
        test_indices = list(range(start_idx, end_idx))
        train_indices = [j for j in range(len(data)) if j not in test_indices]
        folds.append((train_indices, test_indices))
    
    return folds

def cross_validate(
    profiles: List[Dict],
    knots: List[Dict],
    k_folds: int = 5
) -> CrossValidationResult:
    """Perform k-fold cross-validation."""
    
    # Create ground truth for all pairs
    ground_truth = create_sample_ground_truth(profiles)
    
    # Split profiles into folds
    folds = k_fold_split(profiles, k_folds, shuffle=True)
    
    fold_results = []
    quantum_accuracies = []
    integrated_accuracies = []
    improvements = []
    
    comparator = MatchingAccuracyComparator()
    
    for fold_idx, (train_indices, test_indices) in enumerate(folds):
        print(f"  Processing fold {fold_idx + 1}/{k_folds}...")
        
        # Get train and test sets
        train_profiles = [profiles[i] for i in train_indices]
        test_profiles = [profiles[i] for i in test_indices]
        
        # Get corresponding knots
        train_user_ids = {p['user_id'] for p in train_profiles}
        test_user_ids = {p['user_id'] for p in test_profiles}
        
        train_knots = [k for k in knots if k['user_id'] in train_user_ids]
        test_knots = [k for k in knots if k['user_id'] in test_user_ids]
        
        # Filter ground truth to test pairs only
        test_ground_truth = [
            gt for gt in ground_truth
            if gt['user_a'] in test_user_ids and gt['user_b'] in test_user_ids
        ]
        
        if not test_ground_truth:
            continue
        
        # Compare matching accuracy on test set
        result = comparator.compare_matching(
            test_profiles,
            test_knots,
            test_ground_truth
        )
        
        fold_results.append({
            'fold': fold_idx + 1,
            'quantum_accuracy': result.quantum_only_accuracy,
            'integrated_accuracy': result.integrated_accuracy,
            'improvement': result.improvement_percentage,
            'total_pairs': result.total_pairs
        })
        
        quantum_accuracies.append(result.quantum_only_accuracy)
        integrated_accuracies.append(result.integrated_accuracy)
        improvements.append(result.improvement_percentage)
    
    # Calculate statistics
    quantum_mean = np.mean(quantum_accuracies) if quantum_accuracies else 0.0
    quantum_std = np.std(quantum_accuracies) if len(quantum_accuracies) > 1 else 0.0
    integrated_mean = np.mean(integrated_accuracies) if integrated_accuracies else 0.0
    integrated_std = np.std(integrated_accuracies) if len(integrated_accuracies) > 1 else 0.0
    improvement_mean = np.mean(improvements) if improvements else 0.0
    improvement_std = np.std(improvements) if len(improvements) > 1 else 0.0
    
    return CrossValidationResult(
        k_folds=k_folds,
        quantum_accuracy_mean=float(quantum_mean),
        quantum_accuracy_std=float(quantum_std),
        integrated_accuracy_mean=float(integrated_mean),
        integrated_accuracy_std=float(integrated_std),
        improvement_mean=float(improvement_mean),
        improvement_std=float(improvement_std),
        fold_results=fold_results
    )

def main():
    """Main cross-validation script."""
    print("=" * 80)
    print("Cross-Validation - Knot Validation")
    print("Phase 0: Patent #31 Validation")
    print("=" * 80)
    
    # Configuration
    profiles_path = "test/fixtures/personality_profiles.json"
    knots_path = "docs/plans/knot_theory/validation/knot_generation_results.json"
    output_path = "docs/plans/knot_theory/validation/cross_validation_results.json"
    k_folds = 5
    
    # Load data
    print("\n1. Loading data...")
    if os.path.exists(profiles_path):
        profiles = load_personality_profiles(profiles_path)
    else:
        print("   Creating sample profiles...")
        profiles_data = create_sample_profiles()
        profiles = [
            {
                'user_id': p.user_id,
                'dimensions': p.dimensions,
                'created_at': p.created_at
            }
            for p in profiles_data
        ]
    
    if not os.path.exists(knots_path):
        print("   Error: Knots file not found. Please run generate_knots_from_profiles.py first.")
        sys.exit(1)
    
    with open(knots_path, 'r') as f:
        knots_data = json.load(f)
        knots = knots_data.get('knots', [])
    
    print(f"   Loaded {len(profiles)} profiles")
    print(f"   Loaded {len(knots)} knots")
    
    # Perform cross-validation
    print(f"\n2. Performing {k_folds}-fold cross-validation...")
    result = cross_validate(profiles, knots, k_folds=k_folds)
    
    print(f"\n   Cross-Validation Results:")
    print(f"     Quantum-only accuracy: {result.quantum_accuracy_mean*100:.2f}% ± {result.quantum_accuracy_std*100:.2f}%")
    print(f"     Integrated accuracy: {result.integrated_accuracy_mean*100:.2f}% ± {result.integrated_accuracy_std*100:.2f}%")
    print(f"     Improvement: {result.improvement_mean:+.2f}% ± {result.improvement_std:.2f}%")
    
    print(f"\n   Per-Fold Results:")
    for fold_result in result.fold_results:
        print(f"     Fold {fold_result['fold']}: "
              f"Quantum={fold_result['quantum_accuracy']*100:.2f}%, "
              f"Integrated={fold_result['integrated_accuracy']*100:.2f}%, "
              f"Improvement={fold_result['improvement']:+.2f}%")
    
    # Save results
    print("\n3. Saving results...")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    results = {
        'k_folds': result.k_folds,
        'quantum_accuracy': {
            'mean': result.quantum_accuracy_mean,
            'std': result.quantum_accuracy_std
        },
        'integrated_accuracy': {
            'mean': result.integrated_accuracy_mean,
            'std': result.integrated_accuracy_std
        },
        'improvement': {
            'mean': result.improvement_mean,
            'std': result.improvement_std
        },
        'fold_results': result.fold_results
    }
    
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"   Results saved to: {output_path}")
    
    # Summary
    print("\n" + "=" * 80)
    print("CROSS-VALIDATION SUMMARY")
    print("=" * 80)
    print(f"✓ {k_folds}-fold cross-validation complete")
    print(f"✓ Quantum-only: {result.quantum_accuracy_mean*100:.2f}% ± {result.quantum_accuracy_std*100:.2f}%")
    print(f"✓ Integrated: {result.integrated_accuracy_mean*100:.2f}% ± {result.integrated_accuracy_std*100:.2f}%")
    print(f"✓ Improvement: {result.improvement_mean:+.2f}% ± {result.improvement_std:.2f}%")
    
    if result.improvement_mean >= 5.0:
        print(f"✓ MEETS THRESHOLD (≥5% improvement)")
    else:
        print(f"✗ DOES NOT MEET THRESHOLD (<5% improvement)")
    
    print("=" * 80)

if __name__ == "__main__":
    main()

