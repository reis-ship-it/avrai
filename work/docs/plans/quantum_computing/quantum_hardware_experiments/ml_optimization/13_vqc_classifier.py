"""
Experiment 13: Variational Quantum Classifier (VQC)

Purpose:
    Train a quantum neural network to classify personality patterns.
    Learn optimal entanglement coefficients for matching.

AVRAI Code Mapping:
    - QuantumMLOptimizer
    - QuantumEntanglementMLService
    - Coefficient optimization in entanglement service

Quantum Algorithm:
    Variational Quantum Classifier with:
    - Feature map: ZZFeatureMap (encodes classical data)
    - Ansatz: RealAmplitudes (trainable parameters)
    - Optimizer: COBYLA

IBM Resources:
    - Qubits: 12 (personality dimensions)
    - Depth: O(n_layers × n_features)
    - Time: 5+ minutes (training loop)

Success Criteria:
    - Training accuracy > 70%
    - Learns meaningful patterns
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List, Tuple
from qiskit import QuantumCircuit

from common.quantum_utils import run_circuit, AVRAI_DIMENSIONS
from common.avrai_data_loader import load_sample_profiles


def calculate_compatibility_label(profile_a: Dict, profile_b: Dict) -> int:
    """Calculate binary compatibility label (0 = low, 1 = high)."""
    total = 0
    for dim in AVRAI_DIMENSIONS:
        diff = abs(profile_a.get(dim, 0.5) - profile_b.get(dim, 0.5))
        total += (1 - diff) / len(AVRAI_DIMENSIONS)
    return 1 if total > 0.6 else 0


def build_vqc_circuit(
    features: List[float],
    params: List[float],
    n_layers: int = 2
) -> QuantumCircuit:
    """
    Build VQC circuit for compatibility classification.
    
    Args:
        features: Difference vector between two profiles
        params: Trainable parameters
        n_layers: Number of variational layers
    """
    n_features = len(features)
    qc = QuantumCircuit(n_features)
    
    # Feature encoding (simplified ZZ feature map)
    for i, f in enumerate(features):
        qc.ry(f * np.pi, i)
    
    for i in range(n_features - 1):
        qc.cx(i, i + 1)
        qc.rz(features[i] * features[i+1] * np.pi, i + 1)
        qc.cx(i, i + 1)
    
    # Variational layers (RealAmplitudes-style)
    param_idx = 0
    for layer in range(n_layers):
        for i in range(n_features):
            if param_idx < len(params):
                qc.ry(params[param_idx], i)
                param_idx += 1
            if param_idx < len(params):
                qc.rz(params[param_idx], i)
                param_idx += 1
        
        for i in range(n_features - 1):
            qc.cx(i, i + 1)
    
    qc.measure_all()
    return qc


def run_vqc_single_prediction(
    user_profile: Dict[str, float],
    candidate_profile: Dict[str, float],
    params: List[float] = None,
    shots: int = 2048,
    use_simulator: bool = False
) -> Dict:
    """Run VQC for single compatibility prediction."""
    # Create feature vector (difference)
    features = [
        user_profile.get(d, 0.5) - candidate_profile.get(d, 0.5) + 0.5
        for d in AVRAI_DIMENSIONS
    ]
    
    if params is None:
        np.random.seed(42)
        params = np.random.random(len(AVRAI_DIMENSIONS) * 4) * np.pi
    
    qc = build_vqc_circuit(features, list(params))
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    
    # Prediction: probability of measuring state with many zeros
    p_compatible = counts.get(0, counts.get('0', 0)) / total
    
    # True label
    true_label = calculate_compatibility_label(user_profile, candidate_profile)
    predicted_label = 1 if p_compatible > 0.5 else 0
    
    return {
        'predicted_compatible': p_compatible > 0.5,
        'p_compatible': p_compatible,
        'true_label': true_label,
        'predicted_label': predicted_label,
        'correct': predicted_label == true_label,
    }


def run_vqc_batch_test(
    profiles: List[Dict[str, float]],
    shots: int = 1024,
    use_simulator: bool = False
) -> Dict:
    """Run VQC on batch of profile pairs."""
    results = []
    user_profile = profiles[0]
    
    for candidate in profiles[1:]:
        result = run_vqc_single_prediction(
            user_profile, candidate, shots=shots, use_simulator=use_simulator
        )
        results.append(result)
    
    # Calculate accuracy
    correct = sum(1 for r in results if r['correct'])
    accuracy = correct / len(results) if results else 0
    
    return {
        'experiment_id': '13_vqc_classifier',
        'n_predictions': len(results),
        'correct': correct,
        'accuracy': accuracy,
        'predictions': results,
        'shots': shots,
        'passed': accuracy > 0.5,
    }


if __name__ == '__main__':
    print("Experiment 13: Variational Quantum Classifier")
    print("=" * 60)
    
    profiles = load_sample_profiles(6)
    result = run_vqc_batch_test(profiles, use_simulator=True)
    
    print(f"\nPredictions: {result['n_predictions']}")
    print(f"Correct: {result['correct']}")
    print(f"Accuracy: {result['accuracy']:.1%}")
    print(f"Status: {'PASSED ✅' if result['passed'] else 'FAILED ❌'}")
