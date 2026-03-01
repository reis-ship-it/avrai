# Quantum Hardware Experiments - Quick Reference

**Purpose:** One-page summary of all 14 quantum hardware experiments for AVRAI

---

## Experiment Categories

### 🎯 Core Compatibility (Experiments 1-3)
Validate AVRAI's fundamental quantum compatibility calculations.

| # | Name | Tests | Qubits | Time |
|---|------|-------|--------|------|
| 01 | SWAP Test Compatibility | `calculateFidelity()` - personality matching | 25 | 1-2 min |
| 02 | Tensor Product Fidelity | `_tensorProduct()` - state combination | 24 | 2 min |
| 03 | Location Compatibility | `LocationQuantumState` - geo matching | 11 | 1-2 min |

### 🪢 Knot Polynomials (Experiments 4-6)
Test topological knot invariant calculations on quantum hardware.

| # | Name | Tests | Qubits | Time |
|---|------|-------|--------|------|
| 04 | Jones Polynomial | `jonesPolynomial` via Hadamard test | 1+2n | 2-3 min |
| 05 | Alexander Polynomial | `alexanderPolynomial` via quantum walk | log₂(n)+n | 2-3 min |
| 06 | HOMFLY Polynomial | `homflyPolynomial` via Hecke algebra | 1+3n | 3-4 min |

### 👥 Group Matching (Experiments 7-9)
Validate N-way entanglement and optimization algorithms.

| # | Name | Tests | Qubits | Time |
|---|------|-------|--------|------|
| 07 | N-Way Entanglement | `createEntangledState()` - group state | n×12 | 3-4 min |
| 08 | Grover Optimal Match | `matchGroupAgainstSpots()` - search | log₂(n)+1 | 2-3 min |
| 09 | QAOA Clustering | `identifyFabricClusters()` - community | n_users | 3-4 min |

### ⏰ Temporal Evolution (Experiments 10-12)
Test time-based quantum predictions and decoherence.

| # | Name | Tests | Qubits | Time |
|---|------|-------|--------|------|
| 10 | String Evolution | `predictFutureKnot()` - Hamiltonian sim | 8 | 2-3 min |
| 11 | Worldsheet Similarity | `compareWorldsheets()` - SWAP test | 17 | 2 min |
| 12 | Decoherence Measurement | `QuantumTemporalState` - natural decay | 12 | 1 min |

### 🧠 ML Optimization (Experiments 13-14)
Validate quantum machine learning approaches.

| # | Name | Tests | Qubits | Time |
|---|------|-------|--------|------|
| 13 | VQC Classifier | `QuantumMLOptimizer` - pattern learning | 12 | 5+ min |
| 14 | Schmidt Decomposition | `schmidtDecomposition()` - reduction | 16+ | 3 min |

---

## 10-Minute Validation Suite

**For quick IBM Quantum validation, run these 5 experiments:**

1. **01: SWAP Test** (2 min) - Core validation
2. **04: Jones Polynomial** (2 min) - Topological validation  
3. **07: N-Way Entanglement** (3 min) - Group validation
4. **12: Decoherence** (1 min) - Temporal validation
5. **08: Grover Search** (2 min) - Optimization validation

**Total: ~10 minutes IBM Quantum time**

---

## Key Formulas

### SWAP Test (Exp 01)
```
P(|0⟩) = (1 + |⟨ψ_A|ψ_B⟩|²) / 2
Fidelity = 2 × P(|0⟩) - 1
```

### Jones Polynomial (Exp 04)
```
V(K; t) = ⟨Tr(ρ(b))⟩ where ρ is braid representation
Evaluated at t = e^(2πi/5) (5th root of unity)
```

### N-Way Entanglement (Exp 07)
```
|ψ_entangled⟩ = Σᵢ αᵢ |ψ₁⟩ ⊗ |ψ₂⟩ ⊗ ... ⊗ |ψₙ⟩
Normalization: Σᵢ |αᵢ|² = 1
```

### Grover Search (Exp 08)
```
Iterations = ⌊(π/4)√(N/M)⌋
Where N = search space, M = number of solutions
Speedup: O(√N) vs O(N)
```

### QAOA (Exp 09)
```
|ψ(γ,β)⟩ = U_mixer(β_p) U_problem(γ_p) ... U_mixer(β_1) U_problem(γ_1) |+⟩^n
```

---

## IBM Quantum Requirements

| Metric | Minimum | Recommended |
|--------|---------|-------------|
| Qubits | 25 | 127+ (Eagle) |
| Coherence Time (T2) | 100μs | 200μs+ |
| Gate Fidelity | 99% | 99.5%+ |
| Shots per experiment | 4096 | 8192+ |

**Recommended Backends:**
- IBM Eagle (127 qubits)
- IBM Heron (133 qubits)
- IBM Osprey (433 qubits) - for larger experiments

---

**Last Updated:** January 30, 2026
