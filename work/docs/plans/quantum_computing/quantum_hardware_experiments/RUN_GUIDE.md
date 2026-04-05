# IBM Quantum Experiment Execution Guide

**Purpose:** Step-by-step instructions for running AVRAI quantum experiments on IBM Quantum hardware

---

## 🔧 Setup

### 1. Create IBM Quantum Account

1. Go to [IBM Quantum](https://quantum.ibm.com/)
2. Create free account or sign in
3. Navigate to "Account Settings" → "API Token"
4. Copy your API token

### 2. Install Dependencies

```bash
# Create virtual environment (recommended)
python -m venv quantum_env
source quantum_env/bin/activate  # On Windows: quantum_env\Scripts\activate

# Install required packages
pip install qiskit==1.0.0
pip install qiskit-ibm-runtime==0.20.0
pip install qiskit-machine-learning==0.7.0
pip install numpy>=1.24.0
pip install matplotlib>=3.7.0  # For result visualization
```

### 3. Configure Credentials

```python
# Option A: Environment variable (recommended for security)
import os
os.environ["IBM_QUANTUM_TOKEN"] = "your_api_token_here"

# Option B: Direct configuration (for testing only)
from qiskit_ibm_runtime import QiskitRuntimeService
QiskitRuntimeService.save_account(channel="ibm_quantum", token="your_api_token")
```

### 4. Verify Setup

```python
from qiskit_ibm_runtime import QiskitRuntimeService

service = QiskitRuntimeService(channel="ibm_quantum")
backends = service.backends()
print(f"Available backends: {len(backends)}")
print(f"Best available: {service.least_busy(operational=True, simulator=False)}")
```

---

## 🚀 Running Experiments

### Quick Validation (< 10 minutes)

```bash
cd docs/plans/quantum_computing/quantum_hardware_experiments
python runners/run_validation_suite.py
```

### Single Experiment

```bash
# Run SWAP test
python runners/run_single_experiment.py --experiment 01_swap_test

# Run with custom shots
python runners/run_single_experiment.py --experiment 04_jones_polynomial --shots 4096

# Run on simulator first (for testing)
python runners/run_single_experiment.py --experiment 01_swap_test --simulator
```

### Full Suite (60+ minutes)

```bash
python runners/run_full_suite.py --output results/full_run_$(date +%Y%m%d).json
```

---

## 📊 Understanding Results

### Result Format

Each experiment returns a dictionary with:

```python
{
    'experiment_id': '01_swap_test',
    'timestamp': '2026-01-30T10:30:00Z',
    'backend': 'ibm_brisbane',
    'shots': 8192,
    
    # Quantum results
    'quantum_result': 0.847,
    
    # Classical comparison
    'classical_result': 0.851,
    
    # Difference/error
    'difference': 0.004,
    
    # Raw measurement data
    'counts': {'0': 7543, '1': 649},
    
    # Metadata
    'circuit_depth': 36,
    'n_qubits': 25,
    'execution_time_ms': 1234
}
```

### Success Indicators

| Experiment | Success Metric | Target |
|------------|---------------|--------|
| SWAP Test | `difference` | < 0.05 |
| Jones Polynomial | `quantum_jones_real` | Matches classical sign |
| N-Way Entanglement | `is_entangled` | `True` |
| Grover Search | `found_match` | `True` |
| Decoherence | `estimated_T2` | > 50μs |

---

## ⚠️ Troubleshooting

### Common Issues

**1. "No backends available"**
```python
# Check your account has access
service = QiskitRuntimeService(channel="ibm_quantum")
print(service.backends(operational=True))

# Try ibm_cloud channel if ibm_quantum doesn't work
service = QiskitRuntimeService(channel="ibm_cloud", instance="your/instance/name")
```

**2. "Job timeout"**
```python
# Increase timeout
job = sampler.run([qc], shots=shots)
result = job.result(timeout=600)  # 10 minute timeout
```

**3. "Circuit too deep for hardware"**
```python
# Reduce circuit depth
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager

pm = generate_preset_pass_manager(optimization_level=3, backend=backend)
optimized_qc = pm.run(qc)
```

**4. "Not enough qubits"**
```python
# Select backend with sufficient qubits
backend = service.least_busy(
    operational=True, 
    simulator=False, 
    min_num_qubits=50  # Adjust as needed
)
```

### Queue Management

IBM Quantum has queues. To minimize wait time:

```python
# Check queue status before submitting
backend = service.least_busy(operational=True, simulator=False)
print(f"Backend: {backend.name}")
print(f"Queue: {backend.status().pending_jobs} pending jobs")

# Use off-peak hours (nights/weekends in US timezone)
```

---

## 📈 Analyzing Results

### Compare Quantum vs Classical

```python
from common.result_analyzer import analyze_results

results = load_results("results/validation_run.json")

# Generate comparison report
report = analyze_results(results)
print(f"Correlation (quantum vs classical): {report['correlation']}")
print(f"Average difference: {report['avg_difference']}")
print(f"Experiments passed: {report['passed']}/{report['total']}")
```

### Visualize Results

```python
from common.result_analyzer import plot_comparison

plot_comparison(results, output="results/comparison_chart.png")
```

---

## 💰 Cost Considerations

### IBM Quantum Plans

| Plan | Monthly Cost | QPU Time | Best For |
|------|-------------|----------|----------|
| Open | Free | 10 min/month | Initial testing |
| Pay-as-you-go | ~$1.60/second | Unlimited | Production |
| Premium | Contact IBM | Dedicated | Enterprise |

### Estimated Costs (Pay-as-you-go)

| Experiment | QPU Time | Est. Cost |
|------------|----------|-----------|
| Validation Suite (5 exp) | ~10 min | ~$960 |
| Full Suite (14 exp) | ~45 min | ~$4,320 |
| Single Experiment | 1-5 min | $96-$480 |

**Cost Reduction Tips:**
1. Test on simulator first (`--simulator` flag)
2. Reduce shots for initial runs (2048 instead of 8192)
3. Use Open plan's 10 free minutes strategically
4. Run during off-peak hours for shorter queue times

---

## 📁 Output Files

Results are saved to:

```
results/
├── validation_suite_20260130.json    # Validation run results
├── full_suite_20260130.json          # Full run results
├── individual/
│   ├── 01_swap_test_20260130.json
│   ├── 04_jones_polynomial_20260130.json
│   └── ...
└── reports/
    ├── comparison_report.md
    └── charts/
        ├── fidelity_comparison.png
        └── entanglement_metrics.png
```

---

## 🔄 Integrating Results Back to AVRAI

After running experiments, update AVRAI configuration:

```dart
// In lib/core/config/quantum_config.dart

class QuantumConfig {
  // Updated from IBM Quantum validation
  static const double quantumFidelityOffset = 0.004;  // From SWAP test
  static const double decoherenceT2 = 150.0;          // From decoherence exp
  static const bool useQuantumCorrection = true;       // Enable if validated
}
```

---

**Last Updated:** January 30, 2026
