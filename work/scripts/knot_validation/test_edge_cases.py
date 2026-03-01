#!/usr/bin/env python3
"""
Edge Case Testing for Knot Validation

Tests boundary conditions and edge cases for knot generation and compatibility.
"""

import sys
import os
from pathlib import Path
from typing import List, Dict, Any

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.knot_validation.generate_knots_from_profiles import (
    PersonalityProfile, KnotGenerator
)
from scripts.knot_validation.compare_matching_accuracy import (
    MatchingAccuracyComparator
)

def test_identical_profiles():
    """Test compatibility of identical profiles."""
    print("Test 1: Identical Profiles")
    
    dimensions = {f'dim_{i}': 0.5 for i in range(12)}
    profile_a = PersonalityProfile(
        user_id="identical_a",
        dimensions=dimensions,
        created_at="2025-01-01"
    )
    profile_b = PersonalityProfile(
        user_id="identical_b",
        dimensions=dimensions.copy(),
        created_at="2025-01-01"
    )
    
    generator = KnotGenerator()
    knot_a = generator.generate_knot(profile_a)
    knot_b = generator.generate_knot(profile_b)
    
    comparator = MatchingAccuracyComparator()
    quantum = comparator.calculate_quantum_compatibility(
        {'dimensions': dimensions},
        {'dimensions': dimensions}
    )
    
    print(f"  Quantum compatibility: {quantum:.4f}")
    print(f"  Expected: High (>0.8)")
    print(f"  Result: {'✓ PASS' if quantum > 0.8 else '✗ FAIL'}")
    print()

def test_opposite_profiles():
    """Test compatibility of opposite profiles."""
    print("Test 2: Opposite Profiles")
    
    dimensions_a = {f'dim_{i}': 1.0 for i in range(12)}
    dimensions_b = {f'dim_{i}': 0.0 for i in range(12)}
    
    profile_a = PersonalityProfile(
        user_id="opposite_a",
        dimensions=dimensions_a,
        created_at="2025-01-01"
    )
    profile_b = PersonalityProfile(
        user_id="opposite_b",
        dimensions=dimensions_b,
        created_at="2025-01-01"
    )
    
    generator = KnotGenerator()
    knot_a = generator.generate_knot(profile_a)
    knot_b = generator.generate_knot(profile_b)
    
    comparator = MatchingAccuracyComparator()
    quantum = comparator.calculate_quantum_compatibility(
        {'dimensions': dimensions_a},
        {'dimensions': dimensions_b}
    )
    
    print(f"  Quantum compatibility: {quantum:.4f}")
    print(f"  Expected: Low (<0.3)")
    print(f"  Result: {'✓ PASS' if quantum < 0.3 else '✗ FAIL'}")
    print()

def test_unknot_vs_complex():
    """Test compatibility between unknot and complex knot."""
    print("Test 3: Unknot vs Complex Knot")
    
    # Unknot: all dimensions at 0.5 (no correlations)
    unknot_dims = {f'dim_{i}': 0.5 for i in range(12)}
    
    # Complex: varied dimensions (creates correlations)
    complex_dims = {
        f'dim_{i}': 0.1 if i % 2 == 0 else 0.9
        for i in range(12)
    }
    
    profile_unknot = PersonalityProfile(
        user_id="unknot",
        dimensions=unknot_dims,
        created_at="2025-01-01"
    )
    profile_complex = PersonalityProfile(
        user_id="complex",
        dimensions=complex_dims,
        created_at="2025-01-01"
    )
    
    generator = KnotGenerator()
    knot_unknot = generator.generate_knot(profile_unknot)
    knot_complex = generator.generate_knot(profile_complex)
    
    print(f"  Unknot type: {knot_unknot.knot_type}, crossings: {knot_unknot.invariants.crossing_number}")
    print(f"  Complex type: {knot_complex.knot_type}, crossings: {knot_complex.invariants.crossing_number}")
    print(f"  Expected: Different knot types")
    print(f"  Result: {'✓ PASS' if knot_unknot.knot_type != knot_complex.knot_type else '✗ FAIL'}")
    print()

def test_missing_dimensions():
    """Test handling of missing dimensions."""
    print("Test 4: Missing Dimensions")
    
    # Profile with missing dimensions
    incomplete_dims = {
        'dim_0': 0.5,
        'dim_1': 0.6,
        # Missing dim_2 through dim_11
    }
    
    full_dims = {f'dim_{i}': 0.5 for i in range(12)}
    
    profile_incomplete = PersonalityProfile(
        user_id="incomplete",
        dimensions=incomplete_dims,
        created_at="2025-01-01"
    )
    profile_full = PersonalityProfile(
        user_id="full",
        dimensions=full_dims,
        created_at="2025-01-01"
    )
    
    try:
        generator = KnotGenerator()
        knot_incomplete = generator.generate_knot(profile_incomplete)
        knot_full = generator.generate_knot(profile_full)
        
        print(f"  Incomplete profile knot: {knot_incomplete.knot_type}")
        print(f"  Full profile knot: {knot_full.knot_type}")
        print(f"  Expected: Graceful handling (no crash)")
        print(f"  Result: ✓ PASS (no exception)")
    except Exception as e:
        print(f"  Error: {e}")
        print(f"  Result: ✗ FAIL (exception raised)")
    print()

def test_extreme_values():
    """Test handling of extreme dimension values."""
    print("Test 5: Extreme Values")
    
    # Test with values at boundaries
    test_cases = [
        {'name': 'All zeros', 'dims': {f'dim_{i}': 0.0 for i in range(12)}},
        {'name': 'All ones', 'dims': {f'dim_{i}': 1.0 for i in range(12)}},
        {'name': 'Mixed extremes', 'dims': {f'dim_{i}': 0.0 if i < 6 else 1.0 for i in range(12)}},
    ]
    
    generator = KnotGenerator()
    all_passed = True
    
    for test_case in test_cases:
        try:
            profile = PersonalityProfile(
                user_id=f"extreme_{test_case['name']}",
                dimensions=test_case['dims'],
                created_at="2025-01-01"
            )
            knot = generator.generate_knot(profile)
            print(f"  {test_case['name']}: {knot.knot_type} (✓)")
        except Exception as e:
            print(f"  {test_case['name']}: Error - {e} (✗)")
            all_passed = False
    
    print(f"  Result: {'✓ PASS' if all_passed else '✗ FAIL'}")
    print()

def test_empty_profiles():
    """Test handling of empty profiles."""
    print("Test 6: Empty Profiles")
    
    empty_dims = {}
    
    try:
        profile = PersonalityProfile(
            user_id="empty",
            dimensions=empty_dims,
            created_at="2025-01-01"
        )
        generator = KnotGenerator()
        knot = generator.generate_knot(profile)
        
        print(f"  Empty profile knot: {knot.knot_type}")
        print(f"  Expected: Graceful handling (default/unknot)")
        print(f"  Result: ✓ PASS (no exception)")
    except Exception as e:
        print(f"  Error: {e}")
        print(f"  Result: ✗ FAIL (exception raised)")
    print()

def main():
    """Run all edge case tests."""
    print("=" * 80)
    print("Edge Case Testing - Knot Validation")
    print("=" * 80)
    print()
    
    test_identical_profiles()
    test_opposite_profiles()
    test_unknot_vs_complex()
    test_missing_dimensions()
    test_extreme_values()
    test_empty_profiles()
    
    print("=" * 80)
    print("Edge Case Testing Complete")
    print("=" * 80)

if __name__ == "__main__":
    main()

