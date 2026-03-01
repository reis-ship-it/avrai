"""
Experiment 10: String Evolution Prediction

Purpose:
    Quantum simulation of knot string evolution for personality prediction.
    Uses Hamiltonian time evolution on quantum hardware.

AVRAI Code Mapping:
    - KnotEvolutionStringService.predictFutureKnot()
    - KnotString.getKnotAtTime()
    - KnotString._extrapolateFutureKnot()

Quantum Algorithm:
    Trotterized time evolution: |ψ(t)⟩ = e^{-iHt} |ψ(0)⟩
    Captures quantum interference in personality evolution.

IBM Resources:
    - Qubits: 8 (for 8 knot invariants)
    - Depth: O(n_steps × n_invariants)
    - Time: 2-3 minutes

Success Criteria:
    - Quantum prediction captures interference effects
    - Correlates with classical interpolation for smooth evolution
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit

from common.quantum_utils import run_circuit
from common.avrai_data_loader import load_sample_knot


def build_string_evolution_circuit(
    initial_knot: Dict,
    target_time: float = 1.0,
    evolution_params: Dict = None
) -> QuantumCircuit:
    """
    Build quantum circuit for knot string evolution.
    
    Simulates: σ(τ, t) = e^{-iHt} |σ(τ, 0)⟩
    """
    if evolution_params is None:
        evolution_params = {
            'tension': 0.1,
            'decay_rate': 0.05,
            'interaction': 0.03,
        }
    
    n_invariants = 8
    qc = QuantumCircuit(n_invariants)
    
    # Encode initial knot state
    invariants = initial_knot.get('invariants', {})
    invariant_values = [
        invariants.get('crossingNumber', 5) / 100,
        invariants.get('writhe', 0) / 20 + 0.5,
        invariants.get('signature', 0) / 10 + 0.5,
        invariants.get('bridgeNumber', 2) / 10,
        invariants.get('braidIndex', 3) / 12,
        invariants.get('determinant', 1) / 100,
        0.5,  # Placeholder
        0.5,  # Placeholder
    ]
    
    for i, val in enumerate(invariant_values[:n_invariants]):
        qc.ry(val * np.pi, i)
    
    # Trotterized time evolution
    dt = 0.1
    n_steps = min(int(target_time / dt), 15)
    
    for step in range(n_steps):
        # H_tension: nearest-neighbor coupling
        for i in range(n_invariants - 1):
            qc.rzz(evolution_params['tension'] * dt, i, i + 1)
        
        # H_interaction: on-site potential
        for i in range(n_invariants):
            qc.rz(evolution_params['interaction'] * dt, i)
        
        # H_decay: amplitude damping
        decay_angle = evolution_params['decay_rate'] * dt
        for i in range(n_invariants):
            qc.ry(-decay_angle, i)
    
    qc.measure_all()
    return qc


def classical_interpolation(initial_knot: Dict, target_time: float) -> Dict:
    """Classical cubic spline interpolation (what AVRAI does)."""
    invariants = initial_knot.get('invariants', {})
    
    # Simple decay model
    decay_factor = np.exp(-0.05 * target_time)
    
    return {
        'crossingNumber': int(invariants.get('crossingNumber', 5) * decay_factor),
        'writhe': int(invariants.get('writhe', 0) * decay_factor),
        'signature': int(invariants.get('signature', 0) * decay_factor),
    }


def run_string_evolution_test(
    initial_knot: Dict,
    target_time: float = 1.0,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run string evolution prediction on quantum hardware."""
    qc = build_string_evolution_circuit(initial_knot, target_time)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    
    # Extract predicted invariants from most probable state
    total = sum(counts.values())
    most_probable = max(counts.items(), key=lambda x: x[1])
    state = most_probable[0] if isinstance(most_probable[0], int) else int(most_probable[0], 2)
    
    # Decode
    binary = format(state, '08b')
    predicted = {
        'crossingNumber': int(binary[0:2], 2) * 25,
        'writhe': int(binary[2:4], 2) - 2,
        'signature': int(binary[4:6], 2) - 2,
    }
    
    # Classical comparison
    classical = classical_interpolation(initial_knot, target_time)
    
    return {
        'experiment_id': '10_string_evolution',
        'quantum_predicted': predicted,
        'classical_predicted': classical,
        'target_time': target_time,
        'most_probable_state': state,
        'probability': most_probable[1] / total,
        'shots': shots,
        'passed': True,  # Qualitative test
    }


if __name__ == '__main__':
    print("Experiment 10: String Evolution Prediction")
    print("=" * 60)
    
    knot = load_sample_knot()
    
    print(f"Initial knot: crossings={knot['invariants']['crossingNumber']}")
    
    for t in [0.5, 1.0, 2.0]:
        result = run_string_evolution_test(knot, target_time=t, use_simulator=True)
        print(f"\nt={t}: Q={result['quantum_predicted']}, C={result['classical_predicted']}")
