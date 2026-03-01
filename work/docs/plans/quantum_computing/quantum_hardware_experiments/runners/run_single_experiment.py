#!/usr/bin/env python3
"""
Run Single Quantum Experiment

Usage:
    python run_single_experiment.py --experiment 01_swap_test
    python run_single_experiment.py --experiment 04_jones_polynomial --shots 4096
    python run_single_experiment.py --experiment 07_nway_entanglement --simulator
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import argparse
import json
from datetime import datetime

from common.avrai_data_loader import (
    load_sample_profiles,
    load_sample_knot,
    load_sample_worldsheet,
    load_sample_fabric,
)
from common.result_analyzer import save_results, generate_report


# Experiment registry
EXPERIMENTS = {
    '01_swap_test': {
        'module': 'core_compatibility.01_swap_test_compatibility',
        'function': 'run_swap_test',
        'data_loader': lambda: tuple(load_sample_profiles(2)),
        'description': 'SWAP test for personality compatibility',
    },
    '02_tensor_product': {
        'module': 'core_compatibility.02_tensor_product_fidelity',
        'function': 'run_tensor_product_test',
        'data_loader': lambda: tuple(load_sample_profiles(2)),
        'description': 'Tensor product fidelity test',
    },
    '03_location': {
        'module': 'core_compatibility.03_location_compatibility',
        'function': 'run_location_compatibility_test',
        'data_loader': lambda: ({'latitude': 40.7, 'longitude': -74.0}, 
                                 {'latitude': 34.0, 'longitude': -118.2}),
        'description': 'Location quantum compatibility',
    },
    '04_jones_polynomial': {
        'module': 'knot_polynomials.04_jones_polynomial',
        'function': 'run_jones_polynomial_test',
        'data_loader': lambda: (load_sample_knot()['braidData'],),
        'description': 'Jones polynomial calculation',
    },
    '05_alexander_polynomial': {
        'module': 'knot_polynomials.05_alexander_polynomial',
        'function': 'run_alexander_polynomial_test',
        'data_loader': lambda: (load_sample_knot()['braidData'],),
        'description': 'Alexander polynomial calculation',
    },
    '06_homfly_polynomial': {
        'module': 'knot_polynomials.06_homfly_polynomial',
        'function': 'run_homfly_test',
        'data_loader': lambda: (load_sample_knot()['braidData'],),
        'description': 'HOMFLY-PT polynomial calculation',
    },
    '07_nway_entanglement': {
        'module': 'group_matching.07_nway_entanglement',
        'function': 'run_nway_entanglement_test',
        'data_loader': lambda: (load_sample_profiles(3),),
        'description': 'N-way group entanglement',
    },
    '08_grover_search': {
        'module': 'group_matching.08_grover_optimal_match',
        'function': 'run_grover_search_test',
        'data_loader': lambda: (load_sample_profiles(1)[0], load_sample_profiles(8)),
        'description': 'Grover search for optimal match',
    },
    '09_qaoa_clustering': {
        'module': 'group_matching.09_qaoa_clustering',
        'function': 'run_qaoa_clustering_test',
        'data_loader': lambda: (load_sample_fabric(6),),
        'description': 'QAOA fabric clustering',
    },
    '10_string_evolution': {
        'module': 'temporal_evolution.10_string_evolution',
        'function': 'run_string_evolution_test',
        'data_loader': lambda: (load_sample_knot(),),
        'description': 'String evolution prediction',
    },
    '11_worldsheet_similarity': {
        'module': 'temporal_evolution.11_worldsheet_similarity',
        'function': 'run_worldsheet_similarity_test',
        'data_loader': lambda: (load_sample_worldsheet(4), load_sample_worldsheet(3)),
        'description': 'Worldsheet similarity detection',
    },
    '12_decoherence': {
        'module': 'temporal_evolution.12_decoherence_measurement',
        'function': 'run_decoherence_measurement',
        'data_loader': lambda: (load_sample_profiles(1)[0],),
        'description': 'Quantum decoherence measurement',
    },
    '13_vqc_classifier': {
        'module': 'ml_optimization.13_vqc_classifier',
        'function': 'run_vqc_batch_test',
        'data_loader': lambda: (load_sample_profiles(6),),
        'description': 'Variational quantum classifier',
    },
    '14_schmidt_decomposition': {
        'module': 'ml_optimization.14_schmidt_decomposition',
        'function': 'run_schmidt_decomposition_test',
        'data_loader': lambda: tuple(load_sample_profiles(2)),
        'description': 'Quantum Schmidt decomposition',
    },
}


def run_experiment(experiment_id: str, shots: int, use_simulator: bool) -> dict:
    """Run a single experiment by ID."""
    if experiment_id not in EXPERIMENTS:
        print(f"Unknown experiment: {experiment_id}")
        print(f"Available: {list(EXPERIMENTS.keys())}")
        sys.exit(1)
    
    exp_config = EXPERIMENTS[experiment_id]
    
    print(f"\n{'='*60}")
    print(f"Running: {experiment_id}")
    print(f"Description: {exp_config['description']}")
    print(f"Shots: {shots}")
    print(f"Backend: {'Simulator' if use_simulator else 'IBM Quantum'}")
    print(f"{'='*60}\n")
    
    # Import experiment module
    import importlib
    module = importlib.import_module(exp_config['module'])
    run_func = getattr(module, exp_config['function'])
    
    # Load data
    data = exp_config['data_loader']()
    
    # Run experiment
    result = run_func(*data, shots=shots, use_simulator=use_simulator)
    
    # Add metadata
    result['timestamp'] = datetime.now().isoformat()
    result['shots'] = shots
    result['simulator'] = use_simulator
    
    return result


def main():
    parser = argparse.ArgumentParser(
        description='Run single AVRAI quantum experiment',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Available experiments:
  01_swap_test          - SWAP test for personality compatibility
  02_tensor_product     - Tensor product fidelity test
  03_location           - Location quantum compatibility
  04_jones_polynomial   - Jones polynomial calculation
  05_alexander_polynomial - Alexander polynomial calculation
  06_homfly_polynomial  - HOMFLY-PT polynomial calculation
  07_nway_entanglement  - N-way group entanglement
  08_grover_search      - Grover search for optimal match
  09_qaoa_clustering    - QAOA fabric clustering
  10_string_evolution   - String evolution prediction
  11_worldsheet_similarity - Worldsheet similarity detection
  12_decoherence        - Quantum decoherence measurement
  13_vqc_classifier     - Variational quantum classifier
  14_schmidt_decomposition - Quantum Schmidt decomposition
        """
    )
    parser.add_argument('--experiment', '-e', required=True,
                        help='Experiment ID to run')
    parser.add_argument('--shots', '-s', type=int, default=8192,
                        help='Number of measurement shots')
    parser.add_argument('--simulator', action='store_true',
                        help='Use simulator instead of real hardware')
    parser.add_argument('--output', '-o', type=str,
                        help='Output file path (JSON)')
    args = parser.parse_args()
    
    # Run experiment
    result = run_experiment(args.experiment, args.shots, args.simulator)
    
    # Print result
    print("\n" + "="*60)
    print("RESULT")
    print("="*60)
    
    for key, value in result.items():
        if key not in ['counts', 'counts_sample', 'predictions']:
            print(f"  {key}: {value}")
    
    passed = result.get('passed', None)
    if passed is not None:
        print(f"\nStatus: {'PASSED ✅' if passed else 'FAILED ❌'}")
    
    # Save if output specified
    if args.output:
        save_results(result, args.output)
        print(f"\nResults saved to: {args.output}")


if __name__ == '__main__':
    main()
