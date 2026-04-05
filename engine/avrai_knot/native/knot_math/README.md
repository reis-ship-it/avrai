# Knot Math - Rust Library

Knot theory mathematics library for SPOTS personality representation system.

## Overview

This library provides Rust implementations of:
- Polynomial mathematics (Jones, Alexander polynomials)
- Braid group operations
- Knot invariants calculations
- Knot energy calculations (physics-based)
- Knot dynamics (ODE solvers)
- Statistical mechanics (Boltzmann distribution, entropy)

## Setup

### Prerequisites

1. **Install Rust**: Follow instructions at https://www.rust-lang.org/tools/install
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Verify installation**:
   ```bash
   cargo --version
   rustc --version
   ```

### Build

```bash
cd native/knot_math
cargo build
```

### Run Tests

```bash
cargo test
```

### Run Benchmarks

```bash
cargo bench
```

## Project Structure

```
src/
├── adapters/           # Type conversion utilities
│   ├── mod.rs
│   ├── nalgebra.rs    # nalgebra ↔ standard Rust types
│   ├── russell.rs     # russell ↔ nalgebra types
│   ├── rug.rs         # rug::Float ↔ f64
│   └── standard.rs    # Standard utility functions
├── polynomial.rs      # Polynomial mathematics
├── braid_group.rs     # Braid group operations
├── knot_invariants.rs # Knot invariants (Jones, Alexander)
├── knot_energy.rs     # Knot energy calculations
├── knot_dynamics.rs   # Knot dynamics (ODE integration)
├── knot_physics.rs    # Statistical mechanics
├── api.rs             # FFI API for Flutter
└── lib.rs             # Library root
```

## Dependencies

- **nalgebra**: Linear algebra (vectors, matrices) - primary type system
- **rug**: Arbitrary precision arithmetic (for polynomial coefficients)
- **russell_ode**: ODE solvers (for knot dynamics)
- **quadrature**: Numerical integration (for energy calculations)
- **statrs**: Statistical functions (Boltzmann, entropy)
- **serde**: Serialization (for FFI data passing)
- **flutter_rust_bridge**: Type-safe Rust-Dart FFI

## Implementation Status

**Phase 1 - Week 1: Foundation Setup** ✅
- [x] Rust crate structure
- [x] Cargo.toml configuration
- [x] Type adapter layer (skeleton)
- [ ] flutter_rust_bridge setup
- [ ] Basic FFI bindings
- [ ] Unit tests for adapters

**Next Steps:**
- Week 2: Core Mathematical Operations
- Week 3: Physics-Based Calculations
- Week 4: Dart Integration

## Notes

- This library is designed to integrate with Flutter/Dart via FFI
- All mathematical operations use high-precision arithmetic where needed
- The library follows Rust best practices for error handling and type safety
