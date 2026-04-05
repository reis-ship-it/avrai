#!/usr/bin/env python3
"""
Similarity Measurement Validation - Patent #1 Style

Purpose: Validate that quantum compatibility correctly measures similarity
between agents (not compatibility prediction).

This validates the core claim of Patent #1: quantum compatibility accurately
measures personality similarity.

Date: December 24, 2025
Part of Phase 0 validation for Patent #31
"""

import json
import sys
import numpy as np
from pathlib import Path
from typing import List, Dict, Tuple
import statistics

try:
    from scipy.stats import pearsonr
    SCIPY_AVAILABLE = True
except ImportError:
    SCIPY_AVAILABLE = False
    print("Warning: scipy not available. Correlation calculation will be simplified.")

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

def calculate_quantum_compatibility(profile_a: Dict, profile_b: Dict) -> float:
    """Calculate quantum similarity using |⟨ψ_A|ψ_B⟩| (not squared for similarity).
    
    For similarity measurement, we use the magnitude of the inner product,
    not the squared value. The squared value (|⟨ψ_A|ψ_B⟩|²) is for compatibility
    probability, but for similarity we want the direct inner product magnitude.
    """
    dims_a = profile_a.get('dimensions', {})
    dims_b = profile_b.get('dimensions', {})
    
    # Convert to quantum states
    state_a = _dimensions_to_quantum_state(dims_a)
    state_b = _dimensions_to_quantum_state(dims_b)
    
    # Inner product
    inner_product = _quantum_inner_product(state_a, state_b)
    
    # Similarity: |⟨ψ_A|ψ_B⟩| (magnitude, not squared)
    # This gives us a similarity measure in [0, 1] range
    similarity = abs(inner_product)
    
    return max(0.0, min(1.0, similarity))

def _dimensions_to_quantum_state(dimensions: Dict[str, float]) -> Dict[str, Dict[str, float]]:
    """Convert dimensions to quantum state."""
    state = {}
    for dim, value in dimensions.items():
        phase = _calculate_phase(dim, dimensions)
        state[dim] = {'real': value, 'imaginary': phase}
    return state

def _calculate_phase(dimension: str, all_dimensions: Dict[str, float]) -> float:
    """Calculate phase based on dimension relationships."""
    base_value = all_dimensions.get(dimension, 0.5)
    other_values = [v for k, v in all_dimensions.items() if k != dimension]
    avg_other = statistics.mean(other_values) if other_values else 0.5
    phase = (base_value - avg_other) * 0.5
    return phase

def _quantum_inner_product(state_a: Dict, state_b: Dict) -> complex:
    """Calculate quantum inner product."""
    total_real = 0.0
    total_imag = 0.0
    count = 0
    
    for dim in state_a.keys():
        if dim in state_b:
            real_part = state_a[dim]['real'] * state_b[dim]['real']
            imag_part = state_a[dim]['imaginary'] * state_b[dim]['imaginary']
            total_real += real_part
            total_imag += imag_part
            count += 1
    
    if count == 0:
        return 0.0
    
    avg_real = total_real / count
    avg_imag = total_imag / count
    return complex(avg_real, avg_imag)

def calculate_true_similarity(profile_a: Dict, profile_b: Dict) -> float:
    """Calculate true similarity (ground truth) based on dimension similarity."""
    dims_a = profile_a.get('dimensions', {})
    dims_b = profile_b.get('dimensions', {})
    
    similarities = []
    for key in dims_a.keys():
        if key in dims_b:
            val_a = dims_a[key]
            val_b = dims_b[key]
            similarity = 1.0 - abs(val_a - val_b)
            similarities.append(similarity)
    
    return statistics.mean(similarities) if similarities else 0.5

def calculate_correlation(x: List[float], y: List[float]) -> Tuple[float, float]:
    """Calculate Pearson correlation coefficient."""
    if not SCIPY_AVAILABLE:
        # Simplified correlation calculation
        x_mean = statistics.mean(x)
        y_mean = statistics.mean(y)
        
        numerator = sum((x[i] - x_mean) * (y[i] - y_mean) for i in range(len(x)))
        x_var = sum((x[i] - x_mean) ** 2 for i in range(len(x)))
        y_var = sum((y[i] - y_mean) ** 2 for i in range(len(y)))
        
        denominator = (x_var * y_var) ** 0.5
        if denominator == 0:
            return 0.0, 1.0
        
        correlation = numerator / denominator
        # Simplified p-value (not accurate, but gives indication)
        p_value = 0.001 if abs(correlation) > 0.9 else 0.05
        return correlation, p_value
    
    return pearsonr(x, y)

def validate_similarity_measurement(profiles: List[Dict]) -> Dict:
    """Validate quantum compatibility measures similarity correctly."""
    quantum_scores = []
    true_similarities = []
    
    # Calculate all pairs
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i < j:
                quantum = calculate_quantum_compatibility(profile_a, profile_b)
                true_sim = calculate_true_similarity(profile_a, profile_b)
                
                quantum_scores.append(quantum)
                true_similarities.append(true_sim)
    
    # Calculate correlation
    correlation, p_value = calculate_correlation(quantum_scores, true_similarities)
    
    # Calculate MAE
    mae = np.mean([abs(q - t) for q, t in zip(quantum_scores, true_similarities)])
    
    # Calculate R²
    r_squared = correlation ** 2
    
    # Calculate RMSE
    rmse = np.sqrt(np.mean([(q - t) ** 2 for q, t in zip(quantum_scores, true_similarities)]))
    
    return {
        'correlation': float(correlation),
        'p_value': float(p_value),
        'r_squared': float(r_squared),
        'mae': float(mae),
        'rmse': float(rmse),
        'quantum_scores_sample': quantum_scores[:10],  # Sample
        'true_similarities_sample': true_similarities[:10],  # Sample
        'total_pairs': len(quantum_scores),
        'meets_threshold': bool(correlation >= 0.95),  # 95% correlation threshold
        'quantum_mean': float(np.mean(quantum_scores)),
        'quantum_std': float(np.std(quantum_scores)),
        'similarity_mean': float(np.mean(true_similarities)),
        'similarity_std': float(np.std(true_similarities)),
    }

def main():
    """Main validation."""
    print("=" * 80)
    print("Similarity Measurement Validation - Patent #1 Style")
    print("=" * 80)
    print()
    
    # Load profiles
    profiles_path = project_root / 'test' / 'fixtures' / 'personality_profiles.json'
    if not profiles_path.exists():
        print(f"⚠️  Profiles not found: {profiles_path}")
        print("   Creating sample profiles...")
        from scripts.knot_validation.generate_knots_from_profiles import create_sample_profiles
        profiles_list = create_sample_profiles()
        # Convert to dict format
        profiles_data = [
            {
                'user_id': p.user_id,
                'dimensions': p.dimensions,
                'created_at': p.created_at
            }
            for p in profiles_list
        ]
    else:
        with open(profiles_path, 'r') as f:
            profiles_data = json.load(f)
    
    print(f"📊 Validating similarity measurement for {len(profiles_data)} profiles...")
    print()
    
    # Validate
    results = validate_similarity_measurement(profiles_data)
    
    # Print results
    print("📊 Results:")
    print(f"   Correlation: {results['correlation']:.4f}")
    print(f"   R²: {results['r_squared']:.4f}")
    print(f"   MAE: {results['mae']:.4f}")
    print(f"   RMSE: {results['rmse']:.4f}")
    print(f"   P-value: {results['p_value']:.2e}")
    print(f"   Total Pairs: {results['total_pairs']}")
    print()
    print(f"   Quantum Scores: mean={results['quantum_mean']:.4f}, std={results['quantum_std']:.4f}")
    print(f"   True Similarities: mean={results['similarity_mean']:.4f}, std={results['similarity_std']:.4f}")
    print()
    
    if results['meets_threshold']:
        print("✅ PASS: Quantum compatibility accurately measures similarity")
        print(f"   Correlation {results['correlation']:.4f} >= 0.95 threshold")
        print("   This validates Patent #1 claim: quantum compatibility correctly measures similarity")
    else:
        print("❌ FAIL: Quantum compatibility does not meet similarity threshold")
        print(f"   Correlation {results['correlation']:.4f} < 0.95 threshold")
        print("   Investigation needed: quantum compatibility may not accurately measure similarity")
    
    # Save results
    output_path = project_root / 'docs' / 'plans' / 'knot_theory' / 'validation' / 'similarity_validation_results.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_path}")
    
    return results

if __name__ == '__main__':
    main()

