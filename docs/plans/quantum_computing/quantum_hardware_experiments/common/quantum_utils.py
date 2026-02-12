"""
Quantum Utilities for AVRAI Experiments

Common quantum circuit functions used across multiple experiments.
These utilities abstract away Qiskit boilerplate and provide
AVRAI-specific quantum operations.

Maps to AVRAI Dart code:
- QuantumEntanglementService (lib/core/services/quantum/)
- QuantumVibeEngine (lib/core/ai/quantum/)
- QuantumTemporalState (lib/core/ai/quantum/)
"""

import numpy as np
from typing import Dict, List, Optional, Tuple
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit_ibm_runtime import QiskitRuntimeService, Sampler

# AVRAI's 12 core personality dimensions
# From: packages/avrai_core/lib/utils/vibe_constants.dart
AVRAI_DIMENSIONS = [
    'exploration_eagerness',
    'community_orientation', 
    'authenticity_preference',
    'social_discovery_style',
    'temporal_flexibility',
    'location_adventurousness',
    'curation_tendency',
    'trust_network_reliance',
    'energy_preference',
    'novelty_seeking',
    'value_orientation',
    'crowd_tolerance',
]


def get_ibm_backend(
    min_qubits: int = 25,
    use_simulator: bool = False,
    channel: str = "ibm_quantum"
):
    """
    Get the best available IBM Quantum backend.
    
    Args:
        min_qubits: Minimum number of qubits required
        use_simulator: If True, use simulator instead of real hardware
        channel: IBM Quantum channel ("ibm_quantum" or "ibm_cloud")
    
    Returns:
        Backend object ready for job submission
    """
    service = QiskitRuntimeService(channel=channel)
    
    if use_simulator:
        # Use Aer simulator for testing
        from qiskit_aer import AerSimulator
        return AerSimulator()
    
    # Get least busy real backend with sufficient qubits
    backend = service.least_busy(
        operational=True,
        simulator=False,
        min_num_qubits=min_qubits
    )
    
    return backend


def run_circuit(
    circuit: QuantumCircuit,
    backend=None,
    shots: int = 8192,
    use_simulator: bool = False
) -> Dict:
    """
    Run a quantum circuit on IBM Quantum hardware.
    
    Args:
        circuit: Qiskit QuantumCircuit to run
        backend: Optional backend (if None, will get least busy)
        shots: Number of measurement shots
        use_simulator: If True, use simulator
    
    Returns:
        Dictionary with counts and probabilities
    """
    if backend is None:
        backend = get_ibm_backend(
            min_qubits=circuit.num_qubits,
            use_simulator=use_simulator
        )
    
    sampler = Sampler(backend)
    job = sampler.run([circuit], shots=shots)
    result = job.result()
    
    # Extract quasi-distributions
    quasi_dists = result.quasi_dists[0]
    
    # Convert to counts format
    counts = {k: int(v * shots) for k, v in quasi_dists.items()}
    
    return {
        'counts': counts,
        'quasi_dists': quasi_dists,
        'shots': shots,
        'backend': str(backend),
        'job_id': job.job_id() if hasattr(job, 'job_id') else None
    }


def encode_profile_as_quantum_state(
    profile: Dict[str, float],
    circuit: QuantumCircuit,
    start_qubit: int = 0
) -> QuantumCircuit:
    """
    Encode an AVRAI personality profile as quantum state.
    
    Uses RY rotation: |ψ⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩
    Where θ = value × π maps [0,1] to [0,π]
    
    Maps to: QuantumVibeEngine.compileVibeDimensionsQuantum()
    
    Args:
        profile: Dict with personality dimension values (0.0-1.0)
        circuit: QuantumCircuit to add gates to
        start_qubit: Starting qubit index
    
    Returns:
        Modified circuit
    """
    for i, dim in enumerate(AVRAI_DIMENSIONS):
        value = profile.get(dim, 0.5)  # Default to 0.5 if missing
        theta = value * np.pi  # Map [0,1] to [0,π]
        circuit.ry(theta, start_qubit + i)
    
    return circuit


def swap_test_circuit(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float],
    n_dims: int = 12
) -> QuantumCircuit:
    """
    Create SWAP test circuit for personality compatibility.
    
    SWAP test measures: P(|0⟩) = (1 + |⟨ψ_A|ψ_B⟩|²) / 2
    
    Maps to: QuantumEntanglementService.calculateFidelity()
    
    Args:
        profile_a: First personality profile
        profile_b: Second personality profile
        n_dims: Number of dimensions to use (default: 12)
    
    Returns:
        Quantum circuit ready for execution
    """
    # Create registers
    ancilla = QuantumRegister(1, 'ancilla')
    reg_a = QuantumRegister(n_dims, 'profile_a')
    reg_b = QuantumRegister(n_dims, 'profile_b')
    creg = ClassicalRegister(1, 'result')
    
    qc = QuantumCircuit(ancilla, reg_a, reg_b, creg)
    
    # Encode profile A
    for i, dim in enumerate(AVRAI_DIMENSIONS[:n_dims]):
        value_a = profile_a.get(dim, 0.5)
        qc.ry(value_a * np.pi, reg_a[i])
    
    # Encode profile B
    for i, dim in enumerate(AVRAI_DIMENSIONS[:n_dims]):
        value_b = profile_b.get(dim, 0.5)
        qc.ry(value_b * np.pi, reg_b[i])
    
    # SWAP test
    qc.h(ancilla[0])
    for i in range(n_dims):
        qc.cswap(ancilla[0], reg_a[i], reg_b[i])
    qc.h(ancilla[0])
    
    # Measure ancilla
    qc.measure(ancilla[0], creg[0])
    
    return qc


def calculate_classical_fidelity(
    profile_a: Dict[str, float],
    profile_b: Dict[str, float]
) -> float:
    """
    Calculate classical inner product fidelity.
    
    This is what AVRAI currently does:
    F = |⟨ψ_A|ψ_B⟩|² = (v_a · v_b)²
    
    Maps to: QuantumEntanglementService.calculateFidelity()
    
    Args:
        profile_a: First personality profile
        profile_b: Second personality profile
    
    Returns:
        Fidelity score (0.0 to 1.0)
    """
    # Convert to vectors
    vec_a = np.array([profile_a.get(d, 0.5) for d in AVRAI_DIMENSIONS])
    vec_b = np.array([profile_b.get(d, 0.5) for d in AVRAI_DIMENSIONS])
    
    # Normalize
    norm_a = np.linalg.norm(vec_a)
    norm_b = np.linalg.norm(vec_b)
    
    if norm_a == 0 or norm_b == 0:
        return 0.0
    
    vec_a = vec_a / norm_a
    vec_b = vec_b / norm_b
    
    # Inner product squared
    inner_product = np.dot(vec_a, vec_b)
    fidelity = inner_product ** 2
    
    return float(fidelity)


def create_entanglement_circuit(
    profiles: List[Dict[str, float]],
    coefficients: Optional[List[float]] = None
) -> QuantumCircuit:
    """
    Create N-way entangled state from multiple profiles.
    
    Maps to: QuantumEntanglementService.createEntangledState()
    
    Formula: |ψ_entangled⟩ = Σᵢ αᵢ |ψ₁⟩ ⊗ |ψ₂⟩ ⊗ ... ⊗ |ψₙ⟩
    
    Args:
        profiles: List of personality profile dicts
        coefficients: Entanglement weights (default: equal)
    
    Returns:
        Quantum circuit with entangled state
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
        encode_profile_as_quantum_state(profile, qc, offset)
    
    # Apply coefficient scaling
    for m, coeff in enumerate(coefficients):
        offset = m * n_dims
        coeff_angle = 2 * np.arccos(np.clip(coeff, -1, 1))
        for i in range(n_dims):
            qc.rz(coeff_angle, offset + i)
    
    # Create entanglement between members
    for m in range(n_members - 1):
        offset_curr = m * n_dims
        offset_next = (m + 1) * n_dims
        for i in range(n_dims):
            qc.cx(offset_curr + i, offset_next + i)
    
    return qc


def braid_to_crossings(braid_data: List[float]) -> List[int]:
    """
    Convert AVRAI braid_data to crossing sequence.
    
    AVRAI's braid_data (from PersonalityKnot.braidData) is a list of 
    floats representing braid generators. Positive = overcrossing,
    negative = undercrossing.
    
    Args:
        braid_data: List of floats from PersonalityKnot.braidData
    
    Returns:
        List of +1/-1 representing crossing signs
    """
    crossings = []
    for val in braid_data:
        if abs(val) > 0.01:  # Threshold for significant crossing
            crossings.append(1 if val > 0 else -1)
    return crossings


def inverse_qft(n: int) -> QuantumCircuit:
    """
    Create inverse Quantum Fourier Transform circuit.
    
    Used for polynomial evaluation in knot experiments.
    
    Args:
        n: Number of qubits
    
    Returns:
        Inverse QFT circuit
    """
    qc = QuantumCircuit(n)
    
    # Swap qubits
    for i in range(n // 2):
        qc.swap(i, n - i - 1)
    
    # Controlled rotations
    for i in range(n):
        for j in range(i):
            qc.cp(-np.pi / (2 ** (i - j)), j, i)
        qc.h(i)
    
    return qc


def grover_diffusion(n_qubits: int) -> QuantumCircuit:
    """
    Create Grover diffusion operator.
    
    Used in Grover search for optimal matching.
    
    Args:
        n_qubits: Number of qubits
    
    Returns:
        Diffusion operator circuit
    """
    qc = QuantumCircuit(n_qubits)
    
    qc.h(range(n_qubits))
    qc.x(range(n_qubits))
    
    # Multi-controlled Z
    qc.h(n_qubits - 1)
    qc.mcx(list(range(n_qubits - 1)), n_qubits - 1)
    qc.h(n_qubits - 1)
    
    qc.x(range(n_qubits))
    qc.h(range(n_qubits))
    
    return qc


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate great-circle distance between two points in km.
    
    Used for location compatibility experiments.
    
    Args:
        lat1, lon1: First location coordinates
        lat2, lon2: Second location coordinates
    
    Returns:
        Distance in kilometers
    """
    R = 6371  # Earth radius in km
    
    lat1, lon1, lat2, lon2 = map(np.radians, [lat1, lon1, lat2, lon2])
    
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2)**2
    c = 2 * np.arcsin(np.sqrt(a))
    
    return R * c
