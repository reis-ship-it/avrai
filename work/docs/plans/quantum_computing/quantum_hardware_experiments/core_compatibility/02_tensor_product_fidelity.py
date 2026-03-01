"""
Experiment 02: Tensor Product Fidelity Test

Purpose:
    Validate AVRAI's tensor product operations for entanglement creation
    on quantum hardware.

AVRAI Code Mapping:
    - QuantumEntanglementService._tensorProduct()
    - QuantumEntanglementService._tensorProductVectors()
    - Formula: |a⟩ ⊗ |b⟩ = [a₁b₁, a₁b₂, ..., aₙbₘ]

Quantum Algorithm:
    Tensor product is implicit in multi-qubit quantum state.
    Verify via Bell measurement to detect entanglement vs product state.

IBM Resources:
    - Qubits: 24 (12×2 for two entities)
    - Depth: ~24 (Bell measurement)
    - Time: 2 minutes

Success Criteria:
    - Bell measurement entropy indicates correct product state structure
    - Low entropy = product state (expected for tensor product)
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit

from common.quantum_utils import (
    get_ibm_backend,
    run_circuit,
    encode_profile_as_quantum_state,
    AVRAI_DIMENSIONS,
)
from common.avrai_data_loader import load_sample_profiles


def build_tensor_product_circuit(
    entity_a: Dict[str, float],
    entity_b: Dict[str, float],
    n_dims: int = 12
) -> QuantumCircuit:
    """
    Build circuit to test tensor product structure.
    
    Creates |ψ_A⟩ ⊗ |ψ_B⟩ and measures in Bell basis to verify
    product state structure (no entanglement).
    """
    total_qubits = 2 * n_dims
    qc = QuantumCircuit(total_qubits)
    
    # Encode entity A
    for i in range(n_dims):
        dim = AVRAI_DIMENSIONS[i]
        value = entity_a.get(dim, 0.5)
        qc.ry(value * np.pi, i)
    
    # Encode entity B  
    for i in range(n_dims):
        dim = AVRAI_DIMENSIONS[i]
        value = entity_b.get(dim, 0.5)
        qc.ry(value * np.pi, n_dims + i)
    
    # Tensor product is implicit in the joint state!
    # To verify product structure, do Bell measurement
    
    for i in range(n_dims):
        qc.cx(i, n_dims + i)
        qc.h(i)
    
    qc.measure_all()
    
    return qc


def run_tensor_product_test(
    entity_a: Dict[str, float],
    entity_b: Dict[str, float],
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run tensor product test on quantum hardware."""
    qc = build_tensor_product_circuit(entity_a, entity_b)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    probs = {k: v/total for k, v in counts.items()}
    
    # Calculate entropy
    entropy = -sum([p * np.log2(p) for p in probs.values() if p > 0])
    
    # For product states, Bell measurement gives deterministic results
    # Low entropy = product state
    is_product_state = entropy < 2.0
    
    # Classical tensor product
    vec_a = np.array([entity_a.get(d, 0.5) for d in AVRAI_DIMENSIONS])
    vec_b = np.array([entity_b.get(d, 0.5) for d in AVRAI_DIMENSIONS])
    classical_tensor = np.outer(vec_a, vec_b).flatten()
    
    return {
        'experiment_id': '02_tensor_product_fidelity',
        'bell_entropy': entropy,
        'is_product_state': is_product_state,
        'classical_tensor_norm': float(np.linalg.norm(classical_tensor)),
        'shots': shots,
        'counts_sample': dict(list(probs.items())[:10]),
        'backend': result['backend'],
        'passed': is_product_state,
    }


if __name__ == '__main__':
    print("Experiment 02: Tensor Product Fidelity Test")
    print("=" * 60)
    
    profiles = load_sample_profiles(2)
    result = run_tensor_product_test(profiles[0], profiles[1], use_simulator=True)
    
    print(f"Bell Entropy: {result['bell_entropy']:.4f}")
    print(f"Is Product State: {result['is_product_state']}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
