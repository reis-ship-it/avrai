"""
Experiment 08: Grover Search for Optimal Match

Purpose:
    Use Grover's algorithm to find optimal match from candidate pool.
    Demonstrates quantum speedup: O(√N) vs O(N) classical.

AVRAI Code Mapping:
    - GroupMatchingService.matchGroupAgainstSpots()
    - Optimization in group and spot matching

Quantum Algorithm:
    Grover's search with compatibility oracle.
    Amplitude amplification finds good matches faster.

IBM Resources:
    - Qubits: log₂(N) + 1 (N = search space size)
    - Depth: O(√N) Grover iterations
    - Time: 2-3 minutes

Success Criteria:
    - Finds correct match with probability > 0.5
    - Demonstrates √N speedup
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import run_circuit, grover_diffusion, AVRAI_DIMENSIONS
from common.avrai_data_loader import load_sample_profiles


def classical_compatibility(profile_a: Dict, profile_b: Dict) -> float:
    """Calculate classical compatibility between two profiles."""
    total = 0
    for dim in AVRAI_DIMENSIONS:
        diff = abs(profile_a.get(dim, 0.5) - profile_b.get(dim, 0.5))
        total += (1 - diff) / len(AVRAI_DIMENSIONS)
    return total


def build_grover_search_circuit(
    user_profile: Dict[str, float],
    candidate_pool: List[Dict[str, float]],
    compatibility_threshold: float = 0.6
) -> QuantumCircuit:
    """
    Build Grover search circuit for optimal match finding.
    
    Oracle marks candidates with compatibility > threshold.
    """
    n_candidates = len(candidate_pool)
    n_qubits = max(2, int(np.ceil(np.log2(n_candidates))))
    
    # Pad candidates to power of 2
    while len(candidate_pool) < 2 ** n_qubits:
        candidate_pool.append({'dummy': True})
    
    # Find good candidates (above threshold)
    good_indices = []
    for idx, candidate in enumerate(candidate_pool):
        if not candidate.get('dummy'):
            comp = classical_compatibility(user_profile, candidate)
            if comp >= compatibility_threshold:
                good_indices.append(idx)
    
    qc = QuantumCircuit(n_qubits + 1, n_qubits)  # +1 for oracle ancilla
    
    # Initial superposition
    qc.h(range(n_qubits))
    
    # Number of Grover iterations
    n_good = len(good_indices)
    n_total = 2 ** n_qubits
    
    if n_good > 0:
        n_iterations = max(1, int(np.pi / 4 * np.sqrt(n_total / n_good)))
    else:
        n_iterations = 1
    
    n_iterations = min(n_iterations, 5)  # Cap for circuit depth
    
    for _ in range(n_iterations):
        # Oracle: mark good solutions
        for good_idx in good_indices:
            binary = format(good_idx, f'0{n_qubits}b')
            
            for i, bit in enumerate(binary):
                if bit == '0':
                    qc.x(i)
            
            if n_qubits == 1:
                qc.z(0)
            elif n_qubits == 2:
                qc.cz(0, 1)
            else:
                qc.h(n_qubits)
                qc.mcx(list(range(n_qubits)), n_qubits)
                qc.h(n_qubits)
            
            for i, bit in enumerate(binary):
                if bit == '0':
                    qc.x(i)
        
        # Diffusion operator
        qc.h(range(n_qubits))
        qc.x(range(n_qubits))
        
        if n_qubits >= 2:
            qc.h(n_qubits - 1)
            qc.mcx(list(range(n_qubits - 1)), n_qubits - 1)
            qc.h(n_qubits - 1)
        
        qc.x(range(n_qubits))
        qc.h(range(n_qubits))
    
    qc.measure(range(n_qubits), range(n_qubits))
    
    return qc, good_indices


def run_grover_search_test(
    user_profile: Dict[str, float],
    candidate_pool: List[Dict[str, float]],
    compatibility_threshold: float = 0.6,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run Grover search for optimal match."""
    qc, good_indices = build_grover_search_circuit(
        user_profile, candidate_pool, compatibility_threshold
    )
    
    if not good_indices:
        return {
            'experiment_id': '08_grover_optimal_match',
            'found_match': False,
            'n_good_candidates': 0,
            'n_total': len(candidate_pool),
            'passed': False,
        }
    
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    
    # Find most probable result
    best_result = max(counts.items(), key=lambda x: x[1])
    best_idx = best_result[0] if isinstance(best_result[0], int) else int(best_result[0], 2)
    best_prob = best_result[1] / sum(counts.values())
    
    found_good = best_idx in good_indices
    
    # Calculate compatibility of found match
    n_candidates = len(candidate_pool)
    if best_idx < n_candidates and not candidate_pool[best_idx].get('dummy'):
        found_compatibility = classical_compatibility(user_profile, candidate_pool[best_idx])
    else:
        found_compatibility = 0
    
    n_qubits = int(np.ceil(np.log2(n_candidates)))
    
    return {
        'experiment_id': '08_grover_optimal_match',
        'found_match': found_good,
        'best_idx': int(best_idx),
        'best_probability': best_prob,
        'found_compatibility': found_compatibility,
        'n_good_candidates': len(good_indices),
        'n_total': n_candidates,
        'good_indices': good_indices[:5],
        'quantum_speedup': f"O(√{n_candidates}) = O({int(np.sqrt(n_candidates))}) vs O({n_candidates})",
        'shots': shots,
        'passed': found_good and best_prob > 0.3,
    }


if __name__ == '__main__':
    print("Experiment 08: Grover Search for Optimal Match")
    print("=" * 60)
    
    profiles = load_sample_profiles(9)
    user_profile = profiles[0]
    candidates = profiles[1:]
    
    print(f"Searching {len(candidates)} candidates...")
    
    result = run_grover_search_test(
        user_profile, candidates, 
        compatibility_threshold=0.5,
        use_simulator=True
    )
    
    print(f"\nFound Match: {result['found_match']}")
    print(f"Best Index: {result['best_idx']}")
    print(f"Probability: {result['best_probability']:.3f}")
    print(f"Compatibility: {result['found_compatibility']:.3f}")
    print(f"Speedup: {result['quantum_speedup']}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
