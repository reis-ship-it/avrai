#!/usr/bin/env python3
"""
Run Full AVRAI Quantum Experiment Suite

Runs all 14 quantum experiments. Estimated IBM Quantum time: 45-60 minutes.

Usage:
    python run_full_suite.py
    python run_full_suite.py --simulator
    python run_full_suite.py --output results/full_suite.json --report results/report.md
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import argparse
from datetime import datetime
from typing import Dict

from common.avrai_data_loader import (
    load_sample_profiles,
    load_sample_knot,
    load_sample_worldsheet,
    load_sample_fabric,
    load_sample_locations,
)
from common.result_analyzer import (
    analyze_results,
    generate_report,
    save_results,
    plot_comparison,
)


def run_full_suite(shots: int = 4096, use_simulator: bool = False) -> Dict:
    """Run all 14 AVRAI quantum experiments."""
    
    results = {
        'metadata': {
            'suite': 'full',
            'timestamp': datetime.now().isoformat(),
            'shots': shots,
            'simulator': use_simulator,
        }
    }
    
    # Load all data upfront
    print("Loading AVRAI data...")
    profiles = load_sample_profiles(10)
    knot = load_sample_knot()
    worldsheet1 = load_sample_worldsheet(4, 5)
    worldsheet2 = load_sample_worldsheet(3, 4)
    fabric = load_sample_fabric(6)
    locations = load_sample_locations(4)
    
    experiments = [
        ('01_swap_test', 'Core Compatibility: SWAP Test'),
        ('02_tensor_product', 'Core Compatibility: Tensor Product'),
        ('03_location', 'Core Compatibility: Location'),
        ('04_jones', 'Knot Polynomials: Jones'),
        ('05_alexander', 'Knot Polynomials: Alexander'),
        ('06_homfly', 'Knot Polynomials: HOMFLY'),
        ('07_nway', 'Group Matching: N-Way Entanglement'),
        ('08_grover', 'Group Matching: Grover Search'),
        ('09_qaoa', 'Group Matching: QAOA Clustering'),
        ('10_string', 'Temporal: String Evolution'),
        ('11_worldsheet', 'Temporal: Worldsheet Similarity'),
        ('12_decoherence', 'Temporal: Decoherence'),
        ('13_vqc', 'ML: VQC Classifier'),
        ('14_schmidt', 'ML: Schmidt Decomposition'),
    ]
    
    for i, (exp_id, name) in enumerate(experiments, 1):
        print(f"\n{'='*60}")
        print(f"{i}/14: {name}")
        print(f"{'='*60}")
        
        try:
            if exp_id == '01_swap_test':
                from core_compatibility.01_swap_test_compatibility import run_swap_test
                results[exp_id] = run_swap_test(profiles[0], profiles[1], shots, use_simulator)
                
            elif exp_id == '02_tensor_product':
                from core_compatibility.02_tensor_product_fidelity import run_tensor_product_test
                results[exp_id] = run_tensor_product_test(profiles[0], profiles[1], shots, use_simulator)
                
            elif exp_id == '03_location':
                from core_compatibility.03_location_compatibility import run_location_compatibility_test
                results[exp_id] = run_location_compatibility_test(locations[0], locations[1], shots, use_simulator)
                
            elif exp_id == '04_jones':
                from knot_polynomials.04_jones_polynomial import run_jones_polynomial_test
                results[exp_id] = run_jones_polynomial_test(knot['braidData'], shots, use_simulator)
                
            elif exp_id == '05_alexander':
                from knot_polynomials.05_alexander_polynomial import run_alexander_polynomial_test
                results[exp_id] = run_alexander_polynomial_test(knot['braidData'], shots, use_simulator)
                
            elif exp_id == '06_homfly':
                from knot_polynomials.06_homfly_polynomial import run_homfly_test
                results[exp_id] = run_homfly_test(knot['braidData'], shots, use_simulator)
                
            elif exp_id == '07_nway':
                from group_matching.07_nway_entanglement import run_nway_entanglement_test
                results[exp_id] = run_nway_entanglement_test(profiles[:3], shots, use_simulator)
                
            elif exp_id == '08_grover':
                from group_matching.08_grover_optimal_match import run_grover_search_test
                results[exp_id] = run_grover_search_test(profiles[0], profiles[1:9], 0.5, shots, use_simulator)
                
            elif exp_id == '09_qaoa':
                from group_matching.09_qaoa_clustering import run_qaoa_clustering_test
                results[exp_id] = run_qaoa_clustering_test(fabric, 2, shots, use_simulator)
                
            elif exp_id == '10_string':
                from temporal_evolution.10_string_evolution import run_string_evolution_test
                results[exp_id] = run_string_evolution_test(knot, 1.0, shots, use_simulator)
                
            elif exp_id == '11_worldsheet':
                from temporal_evolution.11_worldsheet_similarity import run_worldsheet_similarity_test
                results[exp_id] = run_worldsheet_similarity_test(worldsheet1, worldsheet2, shots, use_simulator)
                
            elif exp_id == '12_decoherence':
                from temporal_evolution.12_decoherence_measurement import run_decoherence_measurement
                results[exp_id] = run_decoherence_measurement(profiles[0], [0, 50, 100], shots, use_simulator)
                
            elif exp_id == '13_vqc':
                from ml_optimization.13_vqc_classifier import run_vqc_batch_test
                results[exp_id] = run_vqc_batch_test(profiles[:6], shots // 4, use_simulator)
                
            elif exp_id == '14_schmidt':
                from ml_optimization.14_schmidt_decomposition import run_schmidt_decomposition_test
                results[exp_id] = run_schmidt_decomposition_test(profiles[0], profiles[1], shots, use_simulator)
            
            passed = results[exp_id].get('passed', False)
            print(f"  Status: {'✅ PASSED' if passed else '❌ FAILED'}")
            
        except Exception as e:
            print(f"  Error: {e}")
            results[exp_id] = {'error': str(e), 'passed': False}
    
    # Summary
    print("\n" + "="*60)
    print("FULL SUITE SUMMARY")
    print("="*60)
    
    passed = sum(1 for k, v in results.items() 
                 if k != 'metadata' and isinstance(v, dict) and v.get('passed', False))
    total = sum(1 for k, v in results.items() 
                if k != 'metadata' and isinstance(v, dict))
    
    results['summary'] = {
        'passed': passed,
        'total': total,
        'pass_rate': passed / total if total > 0 else 0,
    }
    
    print(f"\n  Passed: {passed}/{total}")
    print(f"  Pass Rate: {results['summary']['pass_rate']:.1%}")
    
    return results


def main():
    parser = argparse.ArgumentParser(
        description='Run full AVRAI Quantum Experiment Suite'
    )
    parser.add_argument('--shots', '-s', type=int, default=4096)
    parser.add_argument('--simulator', action='store_true')
    parser.add_argument('--output', '-o', type=str)
    parser.add_argument('--report', '-r', type=str)
    parser.add_argument('--plot', '-p', type=str)
    args = parser.parse_args()
    
    results = run_full_suite(args.shots, args.simulator)
    
    if args.output:
        save_results(results, args.output)
        print(f"\nResults saved to: {args.output}")
    
    if args.report:
        analysis = analyze_results(results)
        generate_report(analysis, args.report)
        print(f"Report saved to: {args.report}")
    
    if args.plot:
        plot_comparison(results, args.plot)


if __name__ == '__main__':
    main()
