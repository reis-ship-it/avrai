"""
Experiment 01: SWAP Test for Personality Compatibility

Purpose:
    Validate AVRAI's core compatibility calculation (calculateFidelity)
    on real quantum hardware using the SWAP test.

AVRAI Code Mapping:
    - QuantumEntanglementService.calculateFidelity()
    - CrossEntityCompatibilityService._calculateQuantumCompatibility()
    - Formula: F = |⟨ψ_A|ψ_B⟩|²

Quantum Algorithm:
    SWAP test measures fidelity via: P(|0⟩) = (1 + |⟨ψ_A|ψ_B⟩|²) / 2
    
Circuit:
    |0⟩ ─────H─────●─────H───M
                   │
    |ψ_A⟩ ────────×─────────
                   │
    |ψ_B⟩ ────────×─────────

IBM Resources:
    - Qubits: 25 (1 ancilla + 12×2 for two profiles)
    - Depth: ~36 (12 CSWAP gates)
    - Time: 1-2 minutes

Success Criteria:
    - Quantum vs classical fidelity correlation > 0.95
    - Difference < 0.05 after error mitigation
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List, Optional
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import (
    get_ibm_backend,
    run_circuit,
    calculate_classical_fidelity,
    AVRAI_DIMENSIONS,
)
from common.avrai_data_loader import load_sample_profiles


def build_swap_test_circuit(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float],
    n_dims: int = 12
) -> QuantumCircuit:
    """
    Build SWAP test circuit for two personality profiles.
    
    The SWAP test measures: P(|0⟩) = (1 + |⟨ψ_A|ψ_B⟩|²) / 2
    Therefore: |⟨ψ_A|ψ_B⟩|² = 2 × P(|0⟩) - 1
    
    Args:
        profile_a: First personality profile (dict with 12 dimensions)
        profile_b: Second personality profile
        n_dims: Number of dimensions to use
    
    Returns:
        Quantum circuit ready for execution
    """
    # Create registers
    ancilla = QuantumRegister(1, 'ancilla')
    reg_a = QuantumRegister(n_dims, 'profile_a')
    reg_b = QuantumRegister(n_dims, 'profile_b')
    creg = ClassicalRegister(1, 'result')
    
    qc = QuantumCircuit(ancilla, reg_a, reg_b, creg)
    
    # Step 1: Encode profile A as quantum state
    # Each dimension value (0.0-1.0) becomes rotation angle (0 to π)
    for i in range(n_dims):
        dim = AVRAI_DIMENSIONS[i]
        value_a = profile_a.get(dim, 0.5)
        theta_a = value_a * np.pi
        qc.ry(theta_a, reg_a[i])
    
    # Step 2: Encode profile B as quantum state
    for i in range(n_dims):
        dim = AVRAI_DIMENSIONS[i]
        value_b = profile_b.get(dim, 0.5)
        theta_b = value_b * np.pi
        qc.ry(theta_b, reg_b[i])
    
    # Step 3: SWAP test circuit
    qc.h(ancilla[0])  # Put ancilla in superposition |+⟩
    
    # Controlled-SWAP (Fredkin gates) for each dimension pair
    for i in range(n_dims):
        qc.cswap(ancilla[0], reg_a[i], reg_b[i])
    
    qc.h(ancilla[0])  # Hadamard before measurement
    
    # Step 4: Measure ancilla
    qc.measure(ancilla[0], creg[0])
    
    return qc


def run_swap_test(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float],
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """
    Execute SWAP test on IBM Quantum hardware.
    
    Args:
        profile_a: First personality profile
        profile_b: Second personality profile
        shots: Number of measurement shots
        use_simulator: If True, use simulator
    
    Returns:
        Results including quantum fidelity, classical fidelity, and comparison
    """
    # Build circuit
    qc = build_swap_test_circuit(profile_a, profile_b)
    
    # Run on hardware
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    # Extract probability of measuring |0⟩
    counts = result['counts']
    total = sum(counts.values())
    p_zero = counts.get(0, counts.get('0', 0)) / total
    
    # SWAP test formula: F = 2 × P(|0⟩) - 1
    quantum_fidelity = max(0, 2 * p_zero - 1)
    
    # Classical comparison
    classical_fidelity = calculate_classical_fidelity(profile_a, profile_b)
    
    return {
        'experiment_id': '01_swap_test_compatibility',
        'quantum_fidelity': quantum_fidelity,
        'classical_fidelity': classical_fidelity,
        'difference': abs(quantum_fidelity - classical_fidelity),
        'p_zero': p_zero,
        'shots': shots,
        'counts': counts,
        'backend': result['backend'],
        'circuit_depth': qc.depth(),
        'n_qubits': qc.num_qubits,
    }


def run_batch_swap_tests(
    profile_pairs: List[tuple],
    shots: int = 4096,
    use_simulator: bool = False
) -> List[Dict]:
    """
    Run SWAP tests on multiple profile pairs.
    
    Args:
        profile_pairs: List of (profile_a, profile_b) tuples
        shots: Shots per test
        use_simulator: If True, use simulator
    
    Returns:
        List of results for each pair
    """
    results = []
    
    for i, (profile_a, profile_b) in enumerate(profile_pairs):
        print(f"Running SWAP test {i+1}/{len(profile_pairs)}...")
        result = run_swap_test(profile_a, profile_b, shots, use_simulator)
        result['pair_index'] = i
        results.append(result)
    
    return results


def analyze_swap_test_results(results: List[Dict]) -> Dict:
    """
    Analyze batch SWAP test results.
    
    Returns:
        Summary metrics including correlation and pass/fail status
    """
    quantum_vals = [r['quantum_fidelity'] for r in results]
    classical_vals = [r['classical_fidelity'] for r in results]
    
    # Correlation
    correlation = np.corrcoef(quantum_vals, classical_vals)[0, 1]
    
    # Error metrics
    differences = [r['difference'] for r in results]
    
    # Pass criteria: difference < 0.05
    passed = sum(1 for d in differences if d < 0.05)
    
    return {
        'n_tests': len(results),
        'correlation': correlation,
        'mean_difference': np.mean(differences),
        'max_difference': max(differences),
        'passed': passed,
        'pass_rate': passed / len(results),
        'validation_success': correlation > 0.95 and np.mean(differences) < 0.05,
    }


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Run SWAP Test Experiment')
    parser.add_argument('--shots', type=int, default=8192, help='Number of shots')
    parser.add_argument('--simulator', action='store_true', help='Use simulator')
    parser.add_argument('--n-pairs', type=int, default=5, help='Number of profile pairs')
    args = parser.parse_args()
    
    print("=" * 60)
    print("Experiment 01: SWAP Test for Personality Compatibility")
    print("=" * 60)
    
    # Load sample profiles
    profiles = load_sample_profiles(args.n_pairs * 2)
    pairs = [(profiles[i], profiles[i+1]) for i in range(0, len(profiles)-1, 2)]
    
    print(f"\nRunning {len(pairs)} SWAP tests with {args.shots} shots each...")
    print(f"Backend: {'Simulator' if args.simulator else 'IBM Quantum'}")
    
    # Run tests
    results = run_batch_swap_tests(pairs, args.shots, args.simulator)
    
    # Analyze
    analysis = analyze_swap_test_results(results)
    
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    
    for r in results:
        status = "✅" if r['difference'] < 0.05 else "❌"
        print(f"Pair {r['pair_index']}: Q={r['quantum_fidelity']:.4f}, "
              f"C={r['classical_fidelity']:.4f}, Δ={r['difference']:.4f} {status}")
    
    print("\n" + "-" * 60)
    print(f"Correlation: {analysis['correlation']:.4f}")
    print(f"Mean Difference: {analysis['mean_difference']:.4f}")
    print(f"Pass Rate: {analysis['pass_rate']:.1%}")
    print(f"Validation: {'PASSED ✅' if analysis['validation_success'] else 'FAILED ❌'}")
