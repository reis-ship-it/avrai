// Type adapter layer for library interoperability
// 
// This module provides conversion utilities between different Rust libraries:
// - nalgebra (linear algebra) <-> standard Rust types
// - russell (scientific computing) <-> nalgebra
// - rug (arbitrary precision) <-> standard Rust types

pub mod nalgebra;
pub mod russell;
#[cfg(not(target_os = "ios"))]
pub mod rug;
pub mod standard;
