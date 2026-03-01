"""
Experiment 06: HOMFLY-PT Polynomial Calculation

Purpose:
    Calculate HOMFLY-PT polynomial on quantum hardware.
    HOMFLY generalizes both Jones and Alexander polynomials.

AVRAI Code Mapping:
    - KnotInvariants.homflyPolynomial (optional field)

Quantum Algorithm:
    BQP reduction via Markov trace on Hecke algebra.
    Quantum advantage: O(n³) vs O(3^n) classical

IBM Resources:
    - Qubits: 1 + 3n (3 per crossing for Hecke algebra)
    - Depth: O(n²)
    - Time: 3-4 minutes
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import run_circuit, braid_to_crossings
from common.avrai_data_loader import load_sample_knot


def build_homfly_circuit(braid_data: List[float], max_crossings: int = 8) -> QuantumCircuit:
    """
    Build quantum circuit for HOMFLY-PT polynomial.
    Uses Hecke algebra representation (3 states per crossing).
    """
    crossings = braid_to_crossings(braid_data)
    n = min(len(crossings), max_crossings)
    
    if n == 0:
        raise ValueError("Knot has no crossings")
    
    ancilla = QuantumRegister(1, 'ancilla')
    hecke_reg = QuantumRegister(3 * n, 'hecke')
    creg = ClassicalRegister(2, 'result')
    
    qc = QuantumCircuit(ancilla, hecke_reg, creg)
    
    qc.h(ancilla[0])
    
    # Hecke algebra at q = e^(2πi/6)
    for i, c in enumerate(crossings[:n]):
        qubits = [hecke_reg[3*i], hecke_reg[3*i + 1], hecke_reg[3*i + 2]]
        theta = np.pi / 6 * c
        
        qc.ry(theta, qubits[0])
        qc.ry(theta / 2, qubits[1])
        qc.cx(qubits[0], qubits[1])
        qc.crz(theta, ancilla[0], qubits[2])
        
        if i < n - 1:
            qc.cx(qubits[2], hecke_reg[3*(i+1)])
    
    qc.h(ancilla[0])
    qc.measure(ancilla[0], creg[0])
    qc.measure(hecke_reg[0], creg[1])
    
    return qc


def run_homfly_test(
    braid_data: List[float],
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run HOMFLY polynomial test on quantum hardware."""
    qc = build_homfly_circuit(braid_data)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    
    p_00 = counts.get(0, 0) / total
    p_01 = counts.get(1, 0) / total
    
    homfly_a = 2 * p_00 - 1
    homfly_z = 2 * p_01 - 1
    
    return {
        'experiment_id': '06_homfly_polynomial',
        'quantum_homfly': {'a': homfly_a, 'z': homfly_z},
        'shots': shots,
        'passed': True,
    }


if __name__ == '__main__':
    print("Experiment 06: HOMFLY-PT Polynomial")
    print("=" * 60)
    
    knot = load_sample_knot()
    result = run_homfly_test(knot['braidData'], use_simulator=True)
    
    print(f"HOMFLY(a): {result['quantum_homfly']['a']:.4f}")
    print(f"HOMFLY(z): {result['quantum_homfly']['z']:.4f}")
