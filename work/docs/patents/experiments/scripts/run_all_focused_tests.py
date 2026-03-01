#!/usr/bin/env python3
"""
Master Focused Test Runner - All Patents

Runs all focused tests for Patents #1, #3, #21, #29

Phase 1 (Critical):
- Patent #3: Mechanism Isolation
- Patent #29: Mechanism Isolation
- Patent #21: Parameter Sensitivity (Epsilon)

Date: December 20, 2025
"""

import sys
import time
from pathlib import Path

# Add scripts directory to path
SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPTS_DIR))

def main():
    """Run all focused tests."""
    print("=" * 70)
    print("MASTER FOCUSED TEST RUNNER")
    print("=" * 70)
    print()
    print("Running Phase 1 Critical Tests + Phase 2 High-Value Tests")
    print()
    print("Phase 1:")
    print("  1. Patent #3: Mechanism Isolation")
    print("  2. Patent #29: Mechanism Isolation")
    print("  3. Patent #21: Parameter Sensitivity (Epsilon)")
    print()
    print("Phase 2:")
    print("  4. Patent #3: Parameter Sensitivity (Thresholds)")
    print("  5. Patent #3: Alternative Comparisons")
    print("  6. Patent #29: Parameter Sensitivity (Decoherence)")
    print("  7. Patent #21: Mechanism Isolation")
    print()
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Phase 1: Critical Tests
    print("PHASE 1: CRITICAL TESTS")
    print("=" * 70)
    print()
    
    # Test 1: Patent #3 Mechanism Isolation
    print("🔬 Test 1: Patent #3 - Mechanism Isolation")
    print("-" * 70)
    try:
        from run_focused_tests_patent_3_mechanism_isolation import test_mechanism_isolation
        test_mechanism_isolation()
        print("✅ Patent #3 mechanism isolation test completed")
    except Exception as e:
        print(f"❌ Patent #3 mechanism isolation test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Test 2: Patent #29 Mechanism Isolation
    print("🔬 Test 2: Patent #29 - Mechanism Isolation")
    print("-" * 70)
    try:
        from run_focused_tests_patent_29_mechanism_isolation import test_mechanism_isolation
        test_mechanism_isolation()
        print("✅ Patent #29 mechanism isolation test completed")
    except Exception as e:
        print(f"❌ Patent #29 mechanism isolation test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Test 3: Patent #21 Epsilon Sensitivity
    print("🔬 Test 3: Patent #21 - Epsilon Parameter Sensitivity")
    print("-" * 70)
    try:
        from run_focused_tests_patent_21_epsilon_sensitivity import test_epsilon_sensitivity
        test_epsilon_sensitivity()
        print("✅ Patent #21 epsilon sensitivity test completed")
    except Exception as e:
        print(f"❌ Patent #21 epsilon sensitivity test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Phase 2: High-Value Tests
    print("PHASE 2: HIGH-VALUE TESTS")
    print("=" * 70)
    print()
    
    # Test 4: Patent #3 Parameter Sensitivity
    print("🔬 Test 4: Patent #3 - Parameter Sensitivity (Thresholds)")
    print("-" * 70)
    try:
        from run_focused_tests_patent_3_parameter_sensitivity import test_threshold_sensitivity
        test_threshold_sensitivity()
        print("✅ Patent #3 threshold sensitivity test completed")
    except Exception as e:
        print(f"❌ Patent #3 threshold sensitivity test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Test 5: Patent #3 Alternative Comparisons
    print("🔬 Test 5: Patent #3 - Alternative Comparisons")
    print("-" * 70)
    try:
        from run_focused_tests_patent_3_alternative_comparisons import test_alternative_comparisons
        test_alternative_comparisons()
        print("✅ Patent #3 alternative comparisons test completed")
    except Exception as e:
        print(f"❌ Patent #3 alternative comparisons test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Test 6: Patent #29 Parameter Sensitivity
    print("🔬 Test 6: Patent #29 - Parameter Sensitivity (Decoherence)")
    print("-" * 70)
    try:
        from run_focused_tests_patent_29_parameter_sensitivity import test_decoherence_sensitivity
        test_decoherence_sensitivity()
        print("✅ Patent #29 decoherence sensitivity test completed")
    except Exception as e:
        print(f"❌ Patent #29 decoherence sensitivity test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    # Test 7: Patent #21 Mechanism Isolation
    print("🔬 Test 7: Patent #21 - Mechanism Isolation")
    print("-" * 70)
    try:
        from run_focused_tests_patent_21_mechanism_isolation import test_mechanism_isolation
        test_mechanism_isolation()
        print("✅ Patent #21 mechanism isolation test completed")
    except Exception as e:
        print(f"❌ Patent #21 mechanism isolation test failed: {e}")
        import traceback
        traceback.print_exc()
    print()
    
    elapsed = time.time() - start_time
    
    print("=" * 70)
    print("✅ ALL FOCUSED TESTS COMPLETE")
    print("=" * 70)
    print(f"Total Time: {elapsed:.2f} seconds ({elapsed/60:.2f} minutes)")
    print()
    print("Results saved to:")
    print("  - docs/patents/experiments/results/patent_3/focused_tests/")
    print("  - docs/patents/experiments/results/patent_29/focused_tests/")
    print("  - docs/patents/experiments/results/patent_21/focused_tests/")
    print()


if __name__ == '__main__':
    main()

