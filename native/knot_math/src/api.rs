// FFI API for Flutter
// 
// This module defines the public API that will be exposed to Dart via flutter_rust_bridge
// All types and functions must be FFI-compatible

use crate::braid_group::Braid;
use crate::knot_invariants::{KnotInvariants, calculate_writhe, calculate_crossing_number};
use crate::polynomial::Polynomial;
use flutter_rust_bridge::frb;

/// Result type for knot generation (FFI-compatible)
/// Contains all knot invariants for complete knot classification
#[frb]
#[derive(Debug, Clone)]
pub struct KnotResult {
    pub knot_data: Vec<f64>,
    pub jones_polynomial: Vec<f64>,
    pub alexander_polynomial: Vec<f64>,
    pub crossing_number: usize,
    pub writhe: i32,
    pub signature: i32,
    pub unknotting_number: Option<usize>,
    pub bridge_number: usize,
    pub braid_index: usize,
    pub determinant: i32,
    pub arf_invariant: Option<i32>,
    pub hyperbolic_volume: Option<f64>,
    pub homfly_polynomial: Option<Vec<f64>>,
}

/// Generate knot from braid sequence data
/// 
/// Input: braid_data as flat vector [strands, crossing1_strand, crossing1_over, ...]
/// Output: KnotResult with knot data and invariants
#[frb(sync)]
pub fn generate_knot_from_braid(braid_data: Vec<f64>) -> Result<KnotResult, String> {
    if braid_data.is_empty() {
        return Err("Braid data cannot be empty".to_string());
    }
    
    let number_of_strands = braid_data[0] as usize;
    if number_of_strands < 2 {
        return Err("Braid must have at least 2 strands".to_string());
    }
    
    let mut braid = Braid::new(number_of_strands);
    
    // Parse crossings from braid_data
    let mut i = 1;
    while i < braid_data.len() {
        if i + 1 >= braid_data.len() {
            break;
        }
        let strand = braid_data[i] as usize;
        let is_over = braid_data[i + 1] > 0.5;
        braid.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    // Calculate invariants
    let invariants = KnotInvariants::from_braid(&braid);
    
    // Convert to output format
    let knot_data = vec![number_of_strands as f64]; // Simplified representation
    
    Ok(KnotResult {
        knot_data,
        jones_polynomial: invariants.jones_polynomial.to_vec(),
        alexander_polynomial: invariants.alexander_polynomial.to_vec(),
        crossing_number: invariants.crossing_number,
        writhe: invariants.writhe,
        signature: invariants.signature,
        unknotting_number: invariants.unknotting_number,
        bridge_number: invariants.bridge_number,
        braid_index: invariants.braid_index,
        determinant: invariants.determinant,
        arf_invariant: invariants.arf_invariant,
        hyperbolic_volume: invariants.hyperbolic_volume,
        homfly_polynomial: invariants.homfly_polynomial.map(|p| p.to_vec()),
    })
}

/// Calculate Jones polynomial from braid data
/// 
/// Input: braid_data as flat vector [strands, crossing1_strand, crossing1_over, ...]
/// Output: Polynomial coefficients (lowest degree first)
#[frb(sync)]
pub fn calculate_jones_polynomial(braid_data: Vec<f64>) -> Result<Vec<f64>, String> {
    if braid_data.is_empty() {
        return Err("Braid data cannot be empty".to_string());
    }
    
    let number_of_strands = braid_data[0] as usize;
    let mut braid = Braid::new(number_of_strands);
    
    // Parse crossings
    let mut i = 1;
    while i < braid_data.len() {
        if i + 1 >= braid_data.len() {
            break;
        }
        let strand = braid_data[i] as usize;
        let is_over = braid_data[i + 1] > 0.5;
        braid.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    let invariants = KnotInvariants::from_braid(&braid);
    Ok(invariants.jones_polynomial.to_vec())
}

/// Calculate Alexander polynomial from braid data
/// 
/// Input: braid_data as flat vector [strands, crossing1_strand, crossing1_over, ...]
/// Output: Polynomial coefficients (lowest degree first)
#[frb(sync)]
pub fn calculate_alexander_polynomial(braid_data: Vec<f64>) -> Result<Vec<f64>, String> {
    if braid_data.is_empty() {
        return Err("Braid data cannot be empty".to_string());
    }
    
    let number_of_strands = braid_data[0] as usize;
    let mut braid = Braid::new(number_of_strands);
    
    // Parse crossings
    let mut i = 1;
    while i < braid_data.len() {
        if i + 1 >= braid_data.len() {
            break;
        }
        let strand = braid_data[i] as usize;
        let is_over = braid_data[i + 1] > 0.5;
        braid.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    let invariants = KnotInvariants::from_braid(&braid);
    Ok(invariants.alexander_polynomial.to_vec())
}

/// Calculate topological compatibility between two knots
/// 
/// Input: Two braid_data vectors
/// Output: Compatibility score in [0, 1]
#[frb(sync)]
pub fn calculate_topological_compatibility(
    braid_data_a: Vec<f64>,
    braid_data_b: Vec<f64>,
) -> Result<f64, String> {
    // Parse first braid
    let number_of_strands_a = braid_data_a[0] as usize;
    let mut braid_a = Braid::new(number_of_strands_a);
    let mut i = 1;
    while i < braid_data_a.len() {
        if i + 1 >= braid_data_a.len() {
            break;
        }
        let strand = braid_data_a[i] as usize;
        let is_over = braid_data_a[i + 1] > 0.5;
        braid_a.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    // Parse second braid
    let number_of_strands_b = braid_data_b[0] as usize;
    let mut braid_b = Braid::new(number_of_strands_b);
    i = 1;
    while i < braid_data_b.len() {
        if i + 1 >= braid_data_b.len() {
            break;
        }
        let strand = braid_data_b[i] as usize;
        let is_over = braid_data_b[i + 1] > 0.5;
        braid_b.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    // Calculate invariants
    let invariants_a = KnotInvariants::from_braid(&braid_a);
    let invariants_b = KnotInvariants::from_braid(&braid_b);
    
    // Calculate compatibility
    Ok(invariants_a.topological_compatibility(&invariants_b))
}

/// Calculate writhe of a braid
/// 
/// Input: braid_data as flat vector [strands, crossing1_strand, crossing1_over, ...]
/// Output: Writhe (signed integer)
#[frb(sync)]
pub fn calculate_writhe_from_braid(braid_data: Vec<f64>) -> Result<i32, String> {
    if braid_data.is_empty() {
        return Err("Braid data cannot be empty".to_string());
    }
    
    let number_of_strands = braid_data[0] as usize;
    let mut braid = Braid::new(number_of_strands);
    
    // Parse crossings
    let mut i = 1;
    while i < braid_data.len() {
        if i + 1 >= braid_data.len() {
            break;
        }
        let strand = braid_data[i] as usize;
        let is_over = braid_data[i + 1] > 0.5;
        braid.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    Ok(calculate_writhe(&braid))
}

/// Calculate crossing number of a braid
/// 
/// Input: braid_data as flat vector [strands, crossing1_strand, crossing1_over, ...]
/// Output: Crossing number (unsigned integer)
#[frb(sync)]
pub fn calculate_crossing_number_from_braid(braid_data: Vec<f64>) -> Result<usize, String> {
    if braid_data.is_empty() {
        return Err("Braid data cannot be empty".to_string());
    }
    
    let number_of_strands = braid_data[0] as usize;
    let mut braid = Braid::new(number_of_strands);
    
    // Parse crossings
    let mut i = 1;
    while i < braid_data.len() {
        if i + 1 >= braid_data.len() {
            break;
        }
        let strand = braid_data[i] as usize;
        let is_over = braid_data[i + 1] > 0.5;
        braid.add_crossing(strand, is_over)?;
        i += 2;
    }
    
    Ok(calculate_crossing_number(&braid))
}

/// Evaluate polynomial at a point
/// 
/// Input: coefficients (lowest degree first), x value
/// Output: Polynomial value at x
#[frb(sync)]
pub fn evaluate_polynomial(coefficients: Vec<f64>, x: f64) -> f64 {
    let poly = Polynomial::new(coefficients);
    poly.evaluate(x)
}

/// Calculate distance between two polynomials
/// 
/// Input: Two coefficient vectors
/// Output: L2 distance
#[frb(sync)]
pub fn polynomial_distance(coefficients_a: Vec<f64>, coefficients_b: Vec<f64>) -> f64 {
    let poly_a = Polynomial::new(coefficients_a);
    let poly_b = Polynomial::new(coefficients_b);
    poly_a.distance(&poly_b)
}

/// Calculate knot energy from knot points
/// 
/// Input: knot_points as [x1, y1, z1, x2, y2, z2, ...]
/// Output: Energy value
#[frb(sync)]
pub fn calculate_knot_energy_from_points(knot_points: Vec<f64>) -> Result<f64, String> {
    if knot_points.len() % 3 != 0 {
        return Err("Knot points must be multiple of 3 (x, y, z coordinates)".to_string());
    }
    
    if knot_points.len() < 9 {
        return Err("Need at least 3 points (9 values) for energy calculation".to_string());
    }
    
    // Convert flat vector to DVector points
    use nalgebra::DVector;
    let mut points = Vec::new();
    for i in 0..(knot_points.len() / 3) {
        let x = knot_points[i * 3];
        let y = knot_points[i * 3 + 1];
        let z = knot_points[i * 3 + 2];
        points.push(DVector::from_vec(vec![x, y, z]));
    }
    
    Ok(crate::knot_energy::calculate_knot_energy(&points))
}

/// Calculate knot stability from knot points
/// 
/// Input: knot_points as [x1, y1, z1, x2, y2, z2, ...]
/// Output: Stability value
#[frb(sync)]
pub fn calculate_knot_stability_from_points(knot_points: Vec<f64>) -> Result<f64, String> {
    if knot_points.len() % 3 != 0 {
        return Err("Knot points must be multiple of 3 (x, y, z coordinates)".to_string());
    }
    
    if knot_points.is_empty() {
        return Err("Knot points cannot be empty".to_string());
    }
    
    // Convert flat vector to DVector points
    use nalgebra::DVector;
    let mut points = Vec::new();
    for i in 0..(knot_points.len() / 3) {
        let x = knot_points[i * 3];
        let y = knot_points[i * 3 + 1];
        let z = knot_points[i * 3 + 2];
        points.push(DVector::from_vec(vec![x, y, z]));
    }
    
    Ok(crate::knot_dynamics::calculate_stability(&points))
}

/// Calculate Boltzmann distribution
/// 
/// Input: energies (Vec<f64>), temperature (f64)
/// Output: Probability distribution (Vec<f64>)
#[frb(sync)]
pub fn calculate_boltzmann_distribution(
    energies: Vec<f64>,
    temperature: f64,
) -> Result<Vec<f64>, String> {
    if energies.is_empty() {
        return Err("Energies cannot be empty".to_string());
    }
    
    if temperature <= 0.0 {
        return Err("Temperature must be positive".to_string());
    }
    
    Ok(crate::knot_physics::calculate_boltzmann_distribution(&energies, temperature))
}

/// Calculate entropy from probability distribution
/// 
/// Input: probabilities (Vec<f64>)
/// Output: Entropy value
#[frb(sync)]
pub fn calculate_entropy(probabilities: Vec<f64>) -> Result<f64, String> {
    if probabilities.is_empty() {
        return Err("Probabilities cannot be empty".to_string());
    }
    
    Ok(crate::knot_physics::calculate_entropy(&probabilities))
}

/// Calculate free energy
/// 
/// Input: energy (f64), entropy (f64), temperature (f64)
/// Output: Free energy value
#[frb(sync)]
pub fn calculate_free_energy(
    energy: f64,
    entropy: f64,
    temperature: f64,
) -> Result<f64, String> {
    if temperature <= 0.0 {
        return Err("Temperature must be positive".to_string());
    }
    
    Ok(crate::knot_physics::calculate_free_energy(energy, entropy, temperature))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_knot_from_braid() {
        // Braid with 3 strands, 2 crossings
        // [3, 0, 1.0, 1, 1.0] = 3 strands, crossing at strand 0 (over), crossing at strand 1 (over)
        let braid_data = vec![3.0, 0.0, 1.0, 1.0, 1.0];
        let result = generate_knot_from_braid(braid_data).unwrap();
        
        assert_eq!(result.crossing_number, 2);
        assert_eq!(result.writhe, 2); // Both crossings are over (+1 each)
        assert!(!result.jones_polynomial.is_empty());
        assert!(!result.alexander_polynomial.is_empty());
    }

    #[test]
    fn test_calculate_jones_polynomial() {
        let braid_data = vec![3.0, 0.0, 1.0];
        let jones = calculate_jones_polynomial(braid_data).unwrap();
        assert!(!jones.is_empty());
    }

    #[test]
    fn test_calculate_alexander_polynomial() {
        let braid_data = vec![3.0, 0.0, 1.0];
        let alexander = calculate_alexander_polynomial(braid_data).unwrap();
        assert!(!alexander.is_empty());
    }

    #[test]
    fn test_calculate_topological_compatibility() {
        let braid_data_a = vec![3.0, 0.0, 1.0];
        let braid_data_b = vec![3.0, 0.0, 1.0];
        let compat = calculate_topological_compatibility(braid_data_a, braid_data_b).unwrap();
        
        // Same braids should have high compatibility
        assert!(compat > 0.5);
        assert!(compat <= 1.0);
    }

    #[test]
    fn test_calculate_writhe_from_braid() {
        // Braid with mixed crossings: +1, -1, +1 = writhe = 1
        let braid_data = vec![3.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0];
        let writhe = calculate_writhe_from_braid(braid_data).unwrap();
        assert_eq!(writhe, 1);
    }

    #[test]
    fn test_evaluate_polynomial() {
        // Polynomial: 1 + 2x + 3x²
        let coeffs = vec![1.0, 2.0, 3.0];
        let value = evaluate_polynomial(coeffs, 1.0);
        assert!((value - 6.0).abs() < 1e-10); // 1 + 2 + 3 = 6
    }

    #[test]
    fn test_polynomial_distance() {
        let coeffs_a = vec![1.0, 2.0, 3.0];
        let coeffs_b = vec![1.0, 2.0, 4.0];
        let dist = polynomial_distance(coeffs_a, coeffs_b);
        assert!((dist - 1.0).abs() < 1e-10); // Distance = |3-4| = 1
    }

    #[test]
    fn test_calculate_knot_energy_from_points() {
        // Straight line: should have low energy
        let points = vec![
            0.0, 0.0, 0.0,  // Point 1
            1.0, 0.0, 0.0,  // Point 2
            2.0, 0.0, 0.0,  // Point 3
            3.0, 0.0, 0.0,  // Point 4
        ];
        
        let energy = calculate_knot_energy_from_points(points).unwrap();
        assert!(energy >= 0.0);
        assert!(energy < 1.0); // Straight line should have low energy
    }

    #[test]
    fn test_calculate_knot_stability_from_points() {
        let points = vec![
            0.0, 0.0, 0.0,
            1.0, 0.0, 0.0,
            2.0, 0.0, 0.0,
        ];
        
        let stability = calculate_knot_stability_from_points(points).unwrap();
        assert!(stability.is_finite());
    }

    #[test]
    fn test_calculate_boltzmann_distribution() {
        let energies = vec![1.0, 2.0, 3.0];
        let temperature = 1.0;
        let distribution = calculate_boltzmann_distribution(energies, temperature).unwrap();
        
        // Probabilities should sum to 1
        let sum: f64 = distribution.iter().sum();
        assert!((sum - 1.0).abs() < 1e-10);
        
        // Lower energy should have higher probability
        assert!(distribution[0] > distribution[1]);
        assert!(distribution[1] > distribution[2]);
    }

    #[test]
    fn test_calculate_entropy() {
        let probabilities = vec![0.25, 0.25, 0.25, 0.25];
        let entropy = calculate_entropy(probabilities).unwrap();
        
        assert!(entropy > 0.0);
        assert!(entropy < 2.0); // Should be less than ln(4) ≈ 1.39
    }

    #[test]
    fn test_calculate_free_energy() {
        let energy = 10.0;
        let entropy = 2.0;
        let temperature = 1.0;
        let free_energy = calculate_free_energy(energy, entropy, temperature).unwrap();
        
        assert!((free_energy - 8.0).abs() < 1e-10); // F = E - TS = 10 - 1*2 = 8
    }

    #[test]
    fn test_calculate_knot_energy_invalid_input() {
        // Invalid: not multiple of 3
        let points = vec![0.0, 0.0, 0.0, 1.0];
        assert!(calculate_knot_energy_from_points(points).is_err());
        
        // Invalid: too few points
        let points = vec![0.0, 0.0, 0.0, 1.0, 0.0, 0.0];
        assert!(calculate_knot_energy_from_points(points).is_err());
    }
}
