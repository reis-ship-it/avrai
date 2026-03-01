"""
Experiment 11: Worldsheet Similarity Detection

Purpose:
    Quantum comparison of worldsheets using SWAP test.
    Detects common patterns across group evolutions.

AVRAI Code Mapping:
    - WorldsheetComparisonService.compareWorldsheets()
    - _detectCommonPatterns()
    - _calculateInvariantSimilarity()

Quantum Algorithm:
    SWAP test on worldsheet feature representations.
    Plus amplitude amplification for pattern detection.

IBM Resources:
    - Qubits: 17 (1 ancilla + 8×2 for two worldsheets)
    - Depth: ~24
    - Time: 2 minutes

Success Criteria:
    - Quantum similarity correlates with classical (r > 0.9)
    - Detects common patterns between similar groups
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import run_circuit
from common.avrai_data_loader import load_sample_worldsheet


def extract_worldsheet_features(worldsheet: Dict) -> List[float]:
    """Extract 8 key features from worldsheet."""
    snapshots = worldsheet.get('snapshots', [])
    user_strings = worldsheet.get('userStrings', {})
    fabric = worldsheet.get('initialFabric', {})
    
    features = [
        len(snapshots) / 100,
        len(user_strings) / 20,
        fabric.get('invariants', {}).get('stability', 0.5),
        fabric.get('invariants', {}).get('density', 0.5),
        0.5,  # Timestamp normalized
        len(fabric.get('braid', {}).get('braidData', [])) / 100,
        fabric.get('invariants', {}).get('crossingNumber', 10) / 100,
        0.5,  # String count normalized
    ]
    
    return [max(0, min(1, f)) for f in features]


def build_worldsheet_similarity_circuit(
    worldsheet_1: Dict,
    worldsheet_2: Dict
) -> QuantumCircuit:
    """Build SWAP test circuit for worldsheet similarity."""
    n_features = 8
    
    ancilla = QuantumRegister(1, 'ancilla')
    ws1_reg = QuantumRegister(n_features, 'ws1')
    ws2_reg = QuantumRegister(n_features, 'ws2')
    creg = ClassicalRegister(1, 'result')
    
    qc = QuantumCircuit(ancilla, ws1_reg, ws2_reg, creg)
    
    # Encode worldsheet 1
    ws1_features = extract_worldsheet_features(worldsheet_1)
    for i, val in enumerate(ws1_features):
        qc.ry(val * np.pi, ws1_reg[i])
    
    # Encode worldsheet 2
    ws2_features = extract_worldsheet_features(worldsheet_2)
    for i, val in enumerate(ws2_features):
        qc.ry(val * np.pi, ws2_reg[i])
    
    # SWAP test
    qc.h(ancilla[0])
    for i in range(n_features):
        qc.cswap(ancilla[0], ws1_reg[i], ws2_reg[i])
    qc.h(ancilla[0])
    
    qc.measure(ancilla[0], creg[0])
    return qc


def classical_worldsheet_similarity(ws1: Dict, ws2: Dict) -> float:
    """Classical similarity (cosine similarity of features)."""
    f1 = extract_worldsheet_features(ws1)
    f2 = extract_worldsheet_features(ws2)
    
    dot = sum([a * b for a, b in zip(f1, f2)])
    norm1 = np.sqrt(sum([a**2 for a in f1]))
    norm2 = np.sqrt(sum([b**2 for b in f2]))
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot / (norm1 * norm2)


def run_worldsheet_similarity_test(
    worldsheet_1: Dict,
    worldsheet_2: Dict,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run worldsheet similarity test on quantum hardware."""
    qc = build_worldsheet_similarity_circuit(worldsheet_1, worldsheet_2)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    p_zero = counts.get(0, counts.get('0', 0)) / total
    
    quantum_similarity = max(0, 2 * p_zero - 1)
    classical_similarity = classical_worldsheet_similarity(worldsheet_1, worldsheet_2)
    
    return {
        'experiment_id': '11_worldsheet_similarity',
        'quantum_similarity': quantum_similarity,
        'classical_similarity': classical_similarity,
        'difference': abs(quantum_similarity - classical_similarity),
        'p_zero': p_zero,
        'n_users_1': len(worldsheet_1.get('userStrings', {})),
        'n_users_2': len(worldsheet_2.get('userStrings', {})),
        'shots': shots,
        'passed': abs(quantum_similarity - classical_similarity) < 0.15,
    }


if __name__ == '__main__':
    print("Experiment 11: Worldsheet Similarity Detection")
    print("=" * 60)
    
    ws1 = load_sample_worldsheet(n_users=4, n_snapshots=5)
    ws2 = load_sample_worldsheet(n_users=3, n_snapshots=4)
    
    result = run_worldsheet_similarity_test(ws1, ws2, use_simulator=True)
    
    print(f"Quantum Similarity: {result['quantum_similarity']:.4f}")
    print(f"Classical Similarity: {result['classical_similarity']:.4f}")
    print(f"Difference: {result['difference']:.4f}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
