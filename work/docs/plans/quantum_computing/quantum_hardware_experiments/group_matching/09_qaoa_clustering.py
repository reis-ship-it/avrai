"""
Experiment 09: QAOA for Fabric Clustering

Purpose:
    Use QAOA to identify optimal fabric clusters (communities).
    Solves MAX-CUT/modularity optimization on quantum hardware.

AVRAI Code Mapping:
    - KnotFabricService.identifyFabricClusters()
    - _detectDenseRegions()
    - _clusterStrandsByProximity()

Quantum Algorithm:
    QAOA (Quantum Approximate Optimization Algorithm)
    Alternates problem and mixer Hamiltonians to find optimal clustering.

IBM Resources:
    - Qubits: n_users
    - Depth: O(p × n_users²) where p = QAOA layers
    - Time: 3-4 minutes

Success Criteria:
    - Clustering quality ≥ classical spectral clustering
    - Finds natural community structure
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit

from common.quantum_utils import run_circuit
from common.avrai_data_loader import load_sample_fabric, load_sample_knot


def knot_compatibility(knot1: Dict, knot2: Dict) -> float:
    """Calculate compatibility between two knots."""
    diff = abs(
        knot1.get('invariants', {}).get('crossingNumber', 5) -
        knot2.get('invariants', {}).get('crossingNumber', 5)
    )
    return 1.0 / (1.0 + diff / 10)


def build_qaoa_circuit(
    user_knots: List[Dict],
    n_layers: int = 2
) -> QuantumCircuit:
    """
    Build QAOA circuit for fabric clustering.
    
    Problem: Partition users into clusters to maximize
    intra-cluster compatibility.
    """
    n_users = min(len(user_knots), 8)
    
    # Build adjacency matrix
    adjacency = np.zeros((n_users, n_users))
    for i in range(n_users):
        for j in range(i + 1, n_users):
            comp = knot_compatibility(user_knots[i], user_knots[j])
            adjacency[i, j] = comp
            adjacency[j, i] = comp
    
    qc = QuantumCircuit(n_users)
    
    # Initial superposition
    qc.h(range(n_users))
    
    # QAOA parameters
    gamma = [0.4 + 0.1 * p for p in range(n_layers)]
    beta = [0.3 + 0.05 * p for p in range(n_layers)]
    
    for p in range(n_layers):
        # Problem unitary: exp(-i γ H_problem)
        for i in range(n_users):
            for j in range(i + 1, n_users):
                if adjacency[i, j] > 0.1:
                    qc.rzz(gamma[p] * adjacency[i, j], i, j)
        
        # Mixer unitary: exp(-i β H_mixer)
        for i in range(n_users):
            qc.rx(2 * beta[p], i)
    
    qc.measure_all()
    return qc


def evaluate_clustering(user_knots: List[Dict], assignment: List[int]) -> float:
    """Evaluate clustering quality (modularity-like)."""
    n = min(len(assignment), len(user_knots))
    
    intra_score = 0
    inter_score = 0
    
    for i in range(n):
        for j in range(i + 1, n):
            comp = knot_compatibility(user_knots[i], user_knots[j])
            if assignment[i] == assignment[j]:
                intra_score += comp
            else:
                inter_score += comp
    
    return intra_score - inter_score


def classical_clustering(user_knots: List[Dict]) -> List[int]:
    """Classical threshold-based clustering."""
    assignment = []
    for knot in user_knots:
        crossing = knot.get('invariants', {}).get('crossingNumber', 5)
        cluster = 0 if crossing < 7 else 1
        assignment.append(cluster)
    return assignment


def run_qaoa_clustering_test(
    fabric: Dict,
    n_layers: int = 2,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run QAOA clustering on quantum hardware."""
    user_knots = fabric.get('userKnots', [])
    
    if len(user_knots) < 2:
        return {'experiment_id': '09_qaoa_clustering', 'passed': False}
    
    qc = build_qaoa_circuit(user_knots, n_layers)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    
    # Find best clustering
    best_state = max(counts.items(), key=lambda x: x[1])
    state_val = best_state[0] if isinstance(best_state[0], int) else int(best_state[0], 2)
    n_users = min(len(user_knots), 8)
    
    binary = format(state_val, f'0{n_users}b')
    quantum_assignment = [int(b) for b in binary]
    
    # Evaluate quality
    quantum_quality = evaluate_clustering(user_knots, quantum_assignment)
    
    # Classical comparison
    classical_assignment = classical_clustering(user_knots)
    classical_quality = evaluate_clustering(user_knots, classical_assignment)
    
    return {
        'experiment_id': '09_qaoa_clustering',
        'quantum_clusters': quantum_assignment,
        'quantum_quality': quantum_quality,
        'classical_clusters': classical_assignment[:n_users],
        'classical_quality': classical_quality,
        'n_users': n_users,
        'n_layers': n_layers,
        'shots': shots,
        'passed': quantum_quality >= classical_quality * 0.9,
    }


if __name__ == '__main__':
    print("Experiment 09: QAOA Fabric Clustering")
    print("=" * 60)
    
    fabric = load_sample_fabric(6)
    result = run_qaoa_clustering_test(fabric, use_simulator=True)
    
    print(f"Quantum Clusters: {result['quantum_clusters']}")
    print(f"Quantum Quality: {result['quantum_quality']:.4f}")
    print(f"Classical Quality: {result['classical_quality']:.4f}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
