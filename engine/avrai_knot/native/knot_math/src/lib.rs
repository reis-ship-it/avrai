mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
// Knot Theory Mathematics Library
// Phase 1: Core Knot System
// 
// This library provides Rust implementations of:
// - Polynomial mathematics (Jones, Alexander polynomials)
// - Braid group operations
// - Knot invariants calculations
// - Knot energy calculations (physics-based)
// - Knot dynamics (ODE solvers)
// - Statistical mechanics (Boltzmann distribution, entropy)

pub mod adapters;
pub mod precision_float;
pub mod polynomial;
pub mod braid_group;
pub mod knot_invariants;
pub mod knot_energy;
pub mod knot_dynamics;
pub mod knot_physics;
pub mod api;

// Re-export main types for convenience
pub use braid_group::{Braid, Knot};
pub use knot_invariants::KnotInvariants;
pub use polynomial::Polynomial;

// FFI bindings are generated in build.rs
// Import the generated bindings (will be created during build)
