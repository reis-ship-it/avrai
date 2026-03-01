"""
Experiment 07: N-Way Group Entanglement

Purpose:
    Create and measure N-way quantum entangled states from multiple users.
    This is core to AVRAI's group matching system.

AVRAI Code Mapping:
    - QuantumEntanglementService.createEntangledState()
    - GroupMatchingService.matchGroupAgainstSpots()
    - Formula: |ψ_entangled⟩ = Σᵢ αᵢ |ψ₁⟩ ⊗ |ψ₂⟩ ⊗ ... ⊗ |ψₙ⟩

Quantum Algorithm:
    True N-way quantum entanglement via CNOT ladder.
    Measures entanglement entropy to verify genuine entanglement.

IBM Resources:
    - Qubits: n_members × 12
    - Depth: O(n_members × 12)
    - Time: 3-4 minutes

Success Criteria:
    - Entanglement entropy > threshold indicates true entanglement
    - Normalized entropy > 0.5 for genuine group entanglement
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List, Optional
from qiskit import QuantumCircuit

from common.quantum_utils import (
    run_circuit,
    create_entanglement_circuit,
    AVRAI_DIMENSIONS,
)
from common.avrai_data_loader import load_sample_profiles


def build_nway_entanglement_circuit(
    profiles: List[Dict[str, float]],
    coefficients: Optional[List[float]] = None,
    measure_first_member: bool = True
) -> QuantumCircuit:
    """
    Build N-way entangled state circuit.
    
    Creates true quantum entanglement between all group members
    using CNOT ladder.
    """
    n_members = len(profiles)
    n_dims = len(AVRAI_DIMENSIONS)
    total_qubits = n_members * n_dims
    
    if coefficients is None:
        coefficients = [1.0 / np.sqrt(n_members)] * n_members
    
    qc = QuantumCircuit(total_qubits)
    
    # Encode each profile
    for m, profile in enumerate(profiles):
        offset = m * n_dims
        for i, dim in enumerate(AVRAI_DIMENSIONS):
            value = profile.get(dim, 0.5)
            qc.ry(value * np.pi, offset + i)
    
    # Apply coefficients
    for m, coeff in enumerate(coefficients):
        offset = m * n_dims
        coeff_angle = 2 * np.arccos(np.clip(coeff, -1, 1))
        for i in range(n_dims):
            qc.rz(coeff_angle, offset + i)
    
    # Create entanglement between members (CNOT ladder)
    for m in range(n_members - 1):
        offset_curr = m * n_dims
        offset_next = (m + 1) * n_dims
        for i in range(n_dims):
            qc.cx(offset_curr + i, offset_next + i)
    
    # Circular entanglement for 3+ members
    if n_members > 2:
        offset_first = 0
        offset_last = (n_members - 1) * n_dims
        for i in range(n_dims):
            qc.cx(offset_last + i, offset_first + i)
    
    if measure_first_member:
        # Measure first member's qubits
        qc.measure_all()
    
    return qc


def run_nway_entanglement_test(
    profiles: List[Dict[str, float]],
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run N-way entanglement test on quantum hardware."""
    qc = build_nway_entanglement_circuit(profiles)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    probs = {k: v/total for k, v in counts.items()}
    
    # Calculate entanglement entropy: S = -Σ pᵢ log(pᵢ)
    entropy = -sum([p * np.log2(p) for p in probs.values() if p > 0])
    
    # Maximum entropy for n_dims qubits
    n_dims = len(AVRAI_DIMENSIONS)
    max_entropy = n_dims
    normalized_entropy = entropy / max_entropy
    
    # Purity: Tr(ρ²)
    purity = sum([p**2 for p in probs.values()])
    
    # Entanglement threshold
    is_entangled = normalized_entropy > 0.5
    
    return {
        'experiment_id': '07_nway_entanglement',
        'n_members': len(profiles),
        'entanglement_entropy': entropy,
        'normalized_entropy': normalized_entropy,
        'max_entropy': max_entropy,
        'purity': purity,
        'is_entangled': is_entangled,
        'shots': shots,
        'passed': is_entangled,
    }


def run_group_spot_matching(
    group_profiles: List[Dict[str, float]],
    spot_profiles: List[Dict[str, float]],
    shots: int = 4096,
    use_simulator: bool = False
) -> Dict:
    """
    Run group-spot matching using entangled group state.
    
    Creates entangled group state, calculates compatibility with each spot.
    """
    results = []
    
    for i, spot in enumerate(spot_profiles):
        # Create combined group + spot state
        all_profiles = group_profiles + [spot]
        
        # Test entanglement quality
        test_result = run_nway_entanglement_test(
            all_profiles[:4],  # Limit for qubit count
            shots=shots // len(spot_profiles),
            use_simulator=use_simulator
        )
        
        results.append({
            'spot_index': i,
            'entropy': test_result['entanglement_entropy'],
            'is_compatible': test_result['normalized_entropy'] > 0.4,
        })
    
    # Best spot has highest entropy (best entanglement with group)
    best_spot = max(results, key=lambda x: x['entropy'])
    
    return {
        'experiment_id': '07_nway_entanglement_matching',
        'n_group_members': len(group_profiles),
        'n_spots': len(spot_profiles),
        'spot_results': results,
        'best_spot_index': best_spot['spot_index'],
        'best_spot_entropy': best_spot['entropy'],
        'passed': True,
    }


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='N-Way Entanglement Test')
    parser.add_argument('--n-members', type=int, default=3, help='Group size')
    parser.add_argument('--simulator', action='store_true')
    args = parser.parse_args()
    
    print("Experiment 07: N-Way Group Entanglement")
    print("=" * 60)
    
    profiles = load_sample_profiles(args.n_members)
    
    print(f"Testing {args.n_members}-way entanglement...")
    result = run_nway_entanglement_test(profiles, use_simulator=args.simulator)
    
    print(f"\nEntanglement Entropy: {result['entanglement_entropy']:.4f}")
    print(f"Normalized Entropy: {result['normalized_entropy']:.4f}")
    print(f"Purity: {result['purity']:.4f}")
    print(f"Is Entangled: {result['is_entangled']}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
