"""
AVRAI Quantum Hardware Experiments - Common Utilities

This package provides shared utilities for all quantum experiments:
- quantum_utils: Common quantum circuit functions
- avrai_data_loader: Load AVRAI data (profiles, knots, worldsheets)
- result_analyzer: Analyze and compare quantum vs classical results
"""

from .quantum_utils import (
    get_ibm_backend,
    run_circuit,
    swap_test_circuit,
    encode_profile_as_quantum_state,
    calculate_classical_fidelity,
)

from .avrai_data_loader import (
    load_sample_profiles,
    load_sample_knot,
    load_sample_worldsheet,
    load_sample_fabric,
    AVRAI_DIMENSIONS,
)

from .result_analyzer import (
    analyze_results,
    compare_quantum_classical,
    generate_report,
    plot_comparison,
)

__all__ = [
    # quantum_utils
    'get_ibm_backend',
    'run_circuit',
    'swap_test_circuit',
    'encode_profile_as_quantum_state',
    'calculate_classical_fidelity',
    # avrai_data_loader
    'load_sample_profiles',
    'load_sample_knot',
    'load_sample_worldsheet',
    'load_sample_fabric',
    'AVRAI_DIMENSIONS',
    # result_analyzer
    'analyze_results',
    'compare_quantum_classical',
    'generate_report',
    'plot_comparison',
]
