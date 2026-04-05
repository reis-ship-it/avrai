#!/usr/bin/env python3
"""
Run AVRAI Quantum Validation Suite

Runs the 5 priority experiments in <10 minutes IBM Quantum time.

Priority Experiments:
1. SWAP Test (2 min) - Core compatibility validation
2. Jones Polynomial (2 min) - Topological validation
3. N-Way Entanglement (3 min) - Group matching validation
4. Decoherence (1 min) - Temporal decay validation
5. Grover Search (2 min) - Optimization validation

Usage:
    python run_validation_suite.py
    python run_validation_suite.py --simulator
    python run_validation_suite.py --output results/validation.json
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import argparse
import json
from datetime import datetime
from typing import Dict

from common.avrai_data_loader import (
    load_sample_profiles,
    load_sample_knot,
)
from common.result_analyzer import (
    analyze_results,
    generate_report,
    save_results,
    plot_comparison,
)


def run_validation_suite(
    shots: int = 4096,
    use_simulator: bool = False
) -> Dict:
    """
    Run the 5 priority quantum validation experiments.
    
    Total estimated IBM Quantum time: ~10 minutes
    
    Returns:
        Dictionary with all experiment results and summary
    """
    results = {
        'metadata': {
            'suite': 'validation',
            'timestamp': datetime.now().isoformat(),
            'shots': shots,
            'simulator': use_simulator,
        }
    }
    
    profiles = load_sample_profiles(10)
    knot = load_sample_knot()
    
    # Experiment 1: SWAP Test (Priority 0)
    print("\n" + "="*60)
    print("1/5: SWAP Test for Personality Compatibility")
    print("="*60)
    
    try:
        from core_compatibility.01_swap_test_compatibility import run_swap_test
        results['swap_test'] = run_swap_test(
            profiles[0], profiles[1],
            shots=shots,
            use_simulator=use_simulator
        )
        print(f"  Quantum: {results['swap_test']['quantum_fidelity']:.4f}")
        print(f"  Classical: {results['swap_test']['classical_fidelity']:.4f}")
        print(f"  Status: {'✅' if results['swap_test'].get('passed', results['swap_test']['difference'] < 0.05) else '❌'}")
    except Exception as e:
        print(f"  Error: {e}")
        results['swap_test'] = {'error': str(e), 'passed': False}
    
    # Experiment 2: Jones Polynomial (Priority 1)
    print("\n" + "="*60)
    print("2/5: Jones Polynomial Calculation")
    print("="*60)
    
    try:
        from knot_polynomials.04_jones_polynomial import run_jones_polynomial_test
        results['jones_polynomial'] = run_jones_polynomial_test(
            knot['braidData'],
            shots=shots // 2,  # Fewer shots OK for polynomial
            use_simulator=use_simulator
        )
        print(f"  Quantum: {results['jones_polynomial']['quantum_jones_real']:.4f}")
        print(f"  Classical: {results['jones_polynomial']['classical_jones']:.4f}")
        print(f"  Status: {'✅' if results['jones_polynomial'].get('passed', results['jones_polynomial'].get('signs_match', False)) else '❌'}")
    except Exception as e:
        print(f"  Error: {e}")
        results['jones_polynomial'] = {'error': str(e), 'passed': False}
    
    # Experiment 3: N-Way Entanglement (Priority 0)
    print("\n" + "="*60)
    print("3/5: N-Way Group Entanglement")
    print("="*60)
    
    try:
        from group_matching.07_nway_entanglement import run_nway_entanglement_test
        results['nway_entanglement'] = run_nway_entanglement_test(
            profiles[:3],  # 3-way entanglement
            shots=shots,
            use_simulator=use_simulator
        )
        print(f"  Entropy: {results['nway_entanglement']['entanglement_entropy']:.4f}")
        print(f"  Normalized: {results['nway_entanglement']['normalized_entropy']:.4f}")
        print(f"  Entangled: {results['nway_entanglement']['is_entangled']}")
        print(f"  Status: {'✅' if results['nway_entanglement'].get('passed', results['nway_entanglement']['is_entangled']) else '❌'}")
    except Exception as e:
        print(f"  Error: {e}")
        results['nway_entanglement'] = {'error': str(e), 'passed': False}
    
    # Experiment 4: Decoherence (Priority 1)
    print("\n" + "="*60)
    print("4/5: Quantum Decoherence Measurement")
    print("="*60)
    
    try:
        from temporal_evolution.12_decoherence_measurement import run_decoherence_measurement
        results['decoherence'] = run_decoherence_measurement(
            profiles[0],
            delay_steps=[0, 50, 100],
            shots=shots // 2,
            use_simulator=use_simulator
        )
        print(f"  Estimated T2: {results['decoherence']['estimated_T2_gates']:.0f} gates")
        print(f"  Fidelity Decay: {results['decoherence']['fidelity_decay']:.4f}")
        print(f"  Status: ✅ (measurement experiment)")
        results['decoherence']['passed'] = True
    except Exception as e:
        print(f"  Error: {e}")
        results['decoherence'] = {'error': str(e), 'passed': False}
    
    # Experiment 5: Grover Search (Priority 1)
    print("\n" + "="*60)
    print("5/5: Grover Search for Optimal Match")
    print("="*60)
    
    try:
        from group_matching.08_grover_optimal_match import run_grover_search_test
        results['grover_search'] = run_grover_search_test(
            profiles[0],
            profiles[1:9],  # 8 candidates
            compatibility_threshold=0.5,
            shots=shots,
            use_simulator=use_simulator
        )
        print(f"  Found Match: {results['grover_search']['found_match']}")
        print(f"  Best Index: {results['grover_search'].get('best_idx', 'N/A')}")
        print(f"  Speedup: {results['grover_search'].get('quantum_speedup', 'N/A')}")
        print(f"  Status: {'✅' if results['grover_search'].get('passed', results['grover_search'].get('found_match', False)) else '❌'}")
    except Exception as e:
        print(f"  Error: {e}")
        results['grover_search'] = {'error': str(e), 'passed': False}
    
    # Summary
    print("\n" + "="*60)
    print("VALIDATION SUITE SUMMARY")
    print("="*60)
    
    passed = sum(1 for k, v in results.items() 
                 if k != 'metadata' and isinstance(v, dict) and v.get('passed', False))
    total = sum(1 for k, v in results.items() 
                if k != 'metadata' and isinstance(v, dict))
    
    results['summary'] = {
        'passed': passed,
        'total': total,
        'pass_rate': passed / total if total > 0 else 0,
        'validation_success': passed >= 3,  # At least 3/5 must pass
    }
    
    print(f"\n  Passed: {passed}/{total}")
    print(f"  Pass Rate: {results['summary']['pass_rate']:.1%}")
    print(f"\n  {'🎉 VALIDATION SUCCESSFUL' if results['summary']['validation_success'] else '⚠️ VALIDATION INCOMPLETE'}")
    
    return results


def main():
    parser = argparse.ArgumentParser(
        description='Run AVRAI Quantum Validation Suite (<10 min IBM time)'
    )
    parser.add_argument('--shots', '-s', type=int, default=4096,
                        help='Shots per experiment (default: 4096)')
    parser.add_argument('--simulator', action='store_true',
                        help='Use simulator instead of real hardware')
    parser.add_argument('--output', '-o', type=str,
                        help='Output file path (JSON)')
    parser.add_argument('--report', '-r', type=str,
                        help='Generate markdown report to path')
    parser.add_argument('--plot', '-p', type=str,
                        help='Generate comparison plot to path')
    args = parser.parse_args()
    
    # Run suite
    results = run_validation_suite(args.shots, args.simulator)
    
    # Save results
    if args.output:
        save_results(results, args.output)
        print(f"\nResults saved to: {args.output}")
    
    # Generate report
    if args.report:
        analysis = analyze_results(results)
        report = generate_report(analysis, args.report)
        print(f"Report saved to: {args.report}")
    
    # Generate plot
    if args.plot:
        plot_comparison(results, args.plot)
    
    # Exit with appropriate code
    sys.exit(0 if results['summary']['validation_success'] else 1)


if __name__ == '__main__':
    main()
