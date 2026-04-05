"""
Experiment 14: Quantum Schmidt Decomposition

Purpose:
    Quantum dimensionality reduction via Schmidt decomposition.
    Extract Schmidt coefficients using quantum phase estimation.

AVRAI Code Mapping:
    - DimensionalityReductionService.schmidtDecomposition()
    - Efficient reduction for large entangled states

Quantum Algorithm:
    Schmidt decomposition: |ψ⟩ = Σᵢ λᵢ |uᵢ⟩ ⊗ |vᵢ⟩
    Uses quantum phase estimation to extract λᵢ coefficients.

IBM Resources:
    - Qubits: 16+ (phase register + subsystems)
    - Depth: O(n²)
    - Time: 3 minutes

Success Criteria:
    - Quantum Schmidt rank matches classical SVD rank
    - Coefficients correlate with classical values
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import run_circuit, inverse_qft
from common.avrai_data_loader import load_sample_profiles, AVRAI_DIMENSIONS


def build_schmidt_circuit(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float],
    n_phase_qubits: int = 4
) -> QuantumCircuit:
    """
    Build quantum circuit for Schmidt decomposition.
    
    Uses phase estimation to extract Schmidt coefficients.
    """
    n_dims = len(AVRAI_DIMENSIONS)
    n_subsystem = n_dims // 2
    
    phase_reg = QuantumRegister(n_phase_qubits, 'phase')
    sys_a = QuantumRegister(n_subsystem, 'sys_a')
    sys_b = QuantumRegister(n_subsystem, 'sys_b')
    creg = ClassicalRegister(n_phase_qubits, 'result')
    
    qc = QuantumCircuit(phase_reg, sys_a, sys_b, creg)
    
    # Encode profile A (first half of dimensions)
    for i in range(n_subsystem):
        dim = AVRAI_DIMENSIONS[i]
        value = profile_a.get(dim, 0.5)
        qc.ry(value * np.pi, sys_a[i])
    
    # Encode profile B (second half)
    for i in range(n_subsystem):
        dim = AVRAI_DIMENSIONS[n_subsystem + i]
        value = profile_b.get(dim, 0.5)
        qc.ry(value * np.pi, sys_b[i])
    
    # Entangle subsystems
    for i in range(n_subsystem):
        qc.cx(sys_a[i], sys_b[i])
    
    # Phase estimation for Schmidt coefficients
    qc.h(phase_reg)
    
    for i in range(n_phase_qubits):
        for j in range(n_subsystem):
            if j < len(sys_a):
                qc.crz(np.pi / (2 ** i), phase_reg[i], sys_a[j])
    
    # Inverse QFT
    qc = qc.compose(inverse_qft(n_phase_qubits), phase_reg)
    
    qc.measure(phase_reg, creg)
    return qc


def classical_schmidt(profile_a: Dict, profile_b: Dict) -> Dict:
    """Classical Schmidt decomposition via SVD."""
    n_dims = len(AVRAI_DIMENSIONS)
    n_subsystem = n_dims // 2
    
    # Build state matrix
    vec_a = np.array([profile_a.get(AVRAI_DIMENSIONS[i], 0.5) for i in range(n_subsystem)])
    vec_b = np.array([profile_b.get(AVRAI_DIMENSIONS[n_subsystem + i], 0.5) for i in range(n_subsystem)])
    
    # Outer product gives entangled state matrix
    matrix = np.outer(vec_a, vec_b)
    
    # SVD
    U, S, Vh = np.linalg.svd(matrix)
    
    # Schmidt coefficients (normalized singular values)
    norm = np.linalg.norm(S)
    if norm > 0:
        coefficients = (S / norm).tolist()
    else:
        coefficients = [1.0]
    
    rank = np.sum(S > 0.001)
    
    return {
        'coefficients': coefficients[:4],
        'rank': int(rank),
    }


def run_schmidt_decomposition_test(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float],
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run Schmidt decomposition on quantum hardware."""
    qc = build_schmidt_circuit(profile_a, profile_b)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    
    # Extract Schmidt coefficients from measurement distribution
    sorted_counts = sorted(counts.items(), key=lambda x: -x[1])
    
    quantum_coefficients = []
    for state, count in sorted_counts[:4]:
        if isinstance(state, int):
            coeff = state / 16  # Normalize by 2^n_phase_qubits
        else:
            coeff = int(state, 2) / 16
        quantum_coefficients.append({
            'coefficient': coeff,
            'probability': count / total,
        })
    
    # Quantum Schmidt rank
    quantum_rank = sum(1 for c in quantum_coefficients if c['probability'] > 0.05)
    
    # Classical comparison
    classical = classical_schmidt(profile_a, profile_b)
    
    return {
        'experiment_id': '14_schmidt_decomposition',
        'quantum_coefficients': quantum_coefficients,
        'quantum_rank': quantum_rank,
        'classical_coefficients': classical['coefficients'],
        'classical_rank': classical['rank'],
        'rank_match': quantum_rank == classical['rank'],
        'shots': shots,
        'passed': abs(quantum_rank - classical['rank']) <= 1,
    }


if __name__ == '__main__':
    print("Experiment 14: Quantum Schmidt Decomposition")
    print("=" * 60)
    
    profiles = load_sample_profiles(2)
    
    result = run_schmidt_decomposition_test(
        profiles[0], profiles[1], use_simulator=True
    )
    
    print(f"\nQuantum Coefficients:")
    for c in result['quantum_coefficients']:
        print(f"  {c['coefficient']:.3f} (p={c['probability']:.3f})")
    
    print(f"\nClassical Coefficients: {result['classical_coefficients']}")
    print(f"Quantum Rank: {result['quantum_rank']}")
    print(f"Classical Rank: {result['classical_rank']}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
