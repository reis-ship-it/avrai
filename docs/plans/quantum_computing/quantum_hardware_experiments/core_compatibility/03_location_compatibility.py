"""
Experiment 03: Location Quantum Compatibility

Purpose:
    Validate AVRAI's location quantum state compatibility calculations
    on real quantum hardware.

AVRAI Code Mapping:
    - LocationQuantumState.fromLocation()
    - LocationCompatibilityCalculator.calculateLocationCompatibility()
    - Formula: location_compatibility = |⟨ψ_loc_A|ψ_loc_B⟩|²

Location State Structure:
    |ψ_location⟩ = [lat_state, lon_state, location_type, accessibility, vibe_match]ᵀ

IBM Resources:
    - Qubits: 11 (1 ancilla + 5×2 for two locations)
    - Depth: ~15 (5 CSWAP gates)
    - Time: 1-2 minutes

Success Criteria:
    - Quantum compatibility correlates with classical (r > 0.9)
    - Nearby locations show higher compatibility
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import numpy as np
from typing import Dict, List
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

from common.quantum_utils import run_circuit, haversine_distance
from common.avrai_data_loader import load_sample_locations


def build_location_compatibility_circuit(
    location_a: Dict,
    location_b: Dict
) -> QuantumCircuit:
    """
    Build SWAP test circuit for location compatibility.
    
    Location quantum state has 5 components:
    - Latitude (normalized)
    - Longitude (normalized)
    - Location type (urban/suburban/rural)
    - Accessibility score
    - Vibe location match
    """
    n_components = 5
    
    ancilla = QuantumRegister(1, 'ancilla')
    loc_a = QuantumRegister(n_components, 'loc_a')
    loc_b = QuantumRegister(n_components, 'loc_b')
    creg = ClassicalRegister(1, 'result')
    
    qc = QuantumCircuit(ancilla, loc_a, loc_b, creg)
    
    # Normalize coordinates to [0, 1]
    lat_a = (location_a.get('latitude', 0) + 90) / 180
    lon_a = (location_a.get('longitude', 0) + 180) / 360
    lat_b = (location_b.get('latitude', 0) + 90) / 180
    lon_b = (location_b.get('longitude', 0) + 180) / 360
    
    # Encode location A
    qc.ry(lat_a * np.pi, loc_a[0])
    qc.ry(lon_a * np.pi, loc_a[1])
    qc.ry(location_a.get('locationType', 0.5) * np.pi, loc_a[2])
    qc.ry(location_a.get('accessibilityScore', 0.7) * np.pi, loc_a[3])
    qc.ry(location_a.get('vibeLocationMatch', 0.5) * np.pi, loc_a[4])
    
    # Encode location B
    qc.ry(lat_b * np.pi, loc_b[0])
    qc.ry(lon_b * np.pi, loc_b[1])
    qc.ry(location_b.get('locationType', 0.5) * np.pi, loc_b[2])
    qc.ry(location_b.get('accessibilityScore', 0.7) * np.pi, loc_b[3])
    qc.ry(location_b.get('vibeLocationMatch', 0.5) * np.pi, loc_b[4])
    
    # SWAP test
    qc.h(ancilla[0])
    for i in range(n_components):
        qc.cswap(ancilla[0], loc_a[i], loc_b[i])
    qc.h(ancilla[0])
    
    qc.measure(ancilla[0], creg[0])
    
    return qc


def classical_location_compatibility(loc_a: Dict, loc_b: Dict) -> float:
    """Classical location compatibility (what AVRAI does)."""
    # Distance-based decay
    distance = haversine_distance(
        loc_a.get('latitude', 0), loc_a.get('longitude', 0),
        loc_b.get('latitude', 0), loc_b.get('longitude', 0)
    )
    distance_score = np.exp(-distance / 50)  # 50km decay
    
    # Type compatibility
    type_diff = abs(loc_a.get('locationType', 0.5) - loc_b.get('locationType', 0.5))
    type_score = 1 - type_diff
    
    # Accessibility
    access_diff = abs(loc_a.get('accessibilityScore', 0.7) - loc_b.get('accessibilityScore', 0.7))
    access_score = 1 - access_diff
    
    return 0.5 * distance_score + 0.3 * type_score + 0.2 * access_score


def run_location_compatibility_test(
    location_a: Dict,
    location_b: Dict,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """Run location compatibility test on quantum hardware."""
    qc = build_location_compatibility_circuit(location_a, location_b)
    result = run_circuit(qc, shots=shots, use_simulator=use_simulator)
    
    counts = result['counts']
    total = sum(counts.values())
    p_zero = counts.get(0, counts.get('0', 0)) / total
    
    quantum_compatibility = max(0, 2 * p_zero - 1)
    classical_compatibility = classical_location_compatibility(location_a, location_b)
    
    distance = haversine_distance(
        location_a.get('latitude', 0), location_a.get('longitude', 0),
        location_b.get('latitude', 0), location_b.get('longitude', 0)
    )
    
    return {
        'experiment_id': '03_location_compatibility',
        'quantum_compatibility': quantum_compatibility,
        'classical_compatibility': classical_compatibility,
        'difference': abs(quantum_compatibility - classical_compatibility),
        'distance_km': distance,
        'location_a': location_a.get('city', 'Unknown'),
        'location_b': location_b.get('city', 'Unknown'),
        'p_zero': p_zero,
        'shots': shots,
        'passed': abs(quantum_compatibility - classical_compatibility) < 0.1,
    }


if __name__ == '__main__':
    print("Experiment 03: Location Quantum Compatibility")
    print("=" * 60)
    
    locations = load_sample_locations(4)
    
    for i in range(len(locations) - 1):
        result = run_location_compatibility_test(
            locations[i], locations[i+1], use_simulator=True
        )
        print(f"{result['location_a']} ↔ {result['location_b']}: "
              f"Q={result['quantum_compatibility']:.3f}, "
              f"C={result['classical_compatibility']:.3f}, "
              f"Dist={result['distance_km']:.0f}km")
