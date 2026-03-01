// Knot dynamics calculations
// 
// Implements knot motion equation: ∂K/∂t = -∇E_K + F_external
// Uses simplified Euler method for integration (russell_ode deferred due to BLAS dependency)

use nalgebra::DVector;
use crate::knot_energy::{calculate_energy_gradient, calculate_knot_energy};

/// Knot dynamics parameters
#[derive(Debug, Clone)]
pub struct KnotDynamicsParams {
    pub time_step: f64,
    pub relaxation_rate: f64,  // α in equation: K(t+Δt) = K(t) - α·∇E_K + β·F_external
    pub external_force_strength: f64,  // β in equation
    pub external_force: Option<DVector<f64>>,
}

impl Default for KnotDynamicsParams {
    fn default() -> Self {
        KnotDynamicsParams {
            time_step: 0.01,
            relaxation_rate: 0.1,  // Moderate relaxation
            external_force_strength: 0.05,  // Small external influence
            external_force: None,
        }
    }
}

/// Evolve knot according to dynamics equation
/// 
/// ∂K/∂t = -∇E_K + F_external
/// Where:
/// - ∇E_K is the energy gradient (drives toward lower energy)
/// - F_external is external force (mood, energy, stress, experiences)
/// 
/// Using Euler method: K(t+Δt) = K(t) + Δt · (∂K/∂t)
pub fn evolve_knot(
    initial_knot: &[DVector<f64>],
    params: &KnotDynamicsParams,
) -> Result<Vec<DVector<f64>>, String> {
    if initial_knot.is_empty() {
        return Err("Initial knot cannot be empty".to_string());
    }
    
    // Calculate energy gradient
    let energy_gradient = calculate_energy_gradient(initial_knot);
    
    if energy_gradient.len() != initial_knot.len() {
        return Err("Energy gradient length mismatch".to_string());
    }
    
    // Apply dynamics equation: ∂K/∂t = -∇E_K + F_external
    // K(t+Δt) = K(t) - α·∇E_K·Δt + β·F_external·Δt
    let mut evolved_knot = Vec::new();
    
    for (i, point) in initial_knot.iter().enumerate() {
        let mut new_point = point.clone();
        
        // Subtract energy gradient (energy minimization)
        // -α·∇E_K·Δt
        let gradient_term = &energy_gradient[i] * params.relaxation_rate * params.time_step;
        new_point -= &gradient_term;
        
        // Add external force (if present)
        // β·F_external·Δt
        if let Some(ref force) = params.external_force {
            let force_term = force * params.external_force_strength * params.time_step;
            new_point += &force_term;
        }
        
        evolved_knot.push(new_point);
    }
    
    Ok(evolved_knot)
}

/// Evolve knot for multiple time steps
/// 
/// Returns sequence of knot configurations: [K(t₀), K(t₁), ..., K(tₙ)]
pub fn evolve_knot_multiple_steps(
    initial_knot: &[DVector<f64>],
    params: &KnotDynamicsParams,
    num_steps: usize,
) -> Result<Vec<Vec<DVector<f64>>>, String> {
    let mut evolution = Vec::new();
    let mut current_knot = initial_knot.to_vec();
    
    evolution.push(current_knot.clone());
    
    for _ in 0..num_steps {
        current_knot = evolve_knot(&current_knot, params)?;
        evolution.push(current_knot.clone());
    }
    
    Ok(evolution)
}

/// Calculate knot stability: -d²E_K/dK²
/// 
/// High stability = knot resists deformation
/// Uses finite differences to approximate second derivative
pub fn calculate_stability(knot: &[DVector<f64>]) -> f64 {
    if knot.is_empty() {
        return 0.0;
    }
    
    // Calculate energy at current configuration
    let energy_current = crate::knot_energy::calculate_knot_energy(knot);
    
    // Perturb knot slightly and calculate energy change
    let epsilon = 1e-4;
    let mut energy_sum = 0.0;
    let mut count = 0;
    
    // Perturb each point slightly and measure energy response
    for i in 0..knot.len() {
        for coord in 0..3 {
            let mut perturbed = knot.to_vec();
            perturbed[i][coord] += epsilon;
            
            let energy_plus = crate::knot_energy::calculate_knot_energy(&perturbed);
            let delta_energy = energy_plus - energy_current;
            
            // Second derivative approximation: d²E/dr² ≈ ΔE / ε²
            energy_sum += delta_energy / (epsilon * epsilon);
            count += 1;
        }
    }
    
    if count == 0 {
        return 0.0;
    }
    
    // Average second derivative (negative for stability)
    let avg_second_deriv = energy_sum / count as f64;
    -avg_second_deriv  // Negative for stability
}

/// Calculate energy change during evolution
/// 
/// Returns (initial_energy, final_energy, energy_change)
pub fn calculate_energy_change(
    initial_knot: &[DVector<f64>],
    final_knot: &[DVector<f64>],
) -> (f64, f64, f64) {
    let energy_initial = calculate_knot_energy(initial_knot);
    let energy_final = calculate_knot_energy(final_knot);
    let energy_change = energy_final - energy_initial;
    
    (energy_initial, energy_final, energy_change)
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DVector;

    #[test]
    fn test_evolve_knot() {
        let initial = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
        ];
        
        let params = KnotDynamicsParams::default();
        let evolved = evolve_knot(&initial, &params).unwrap();
        
        assert_eq!(evolved.len(), initial.len());
        // Evolved knot should have same number of points
        for (orig, evol) in initial.iter().zip(evolved.iter()) {
            assert_eq!(orig.len(), evol.len());
        }
    }

    #[test]
    fn test_evolve_knot_multiple_steps() {
        let initial = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
        ];
        
        let params = KnotDynamicsParams::default();
        let evolution = evolve_knot_multiple_steps(&initial, &params, 3).unwrap();
        
        // Should have initial + 3 steps = 4 configurations
        assert_eq!(evolution.len(), 4);
    }

    #[test]
    fn test_calculate_stability() {
        let knot = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
        ];
        
        let stability = calculate_stability(&knot);
        // Stability should be a real number
        assert!(stability.is_finite());
    }

    #[test]
    fn test_calculate_energy_change() {
        let initial = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
        ];
        
        let final_knot = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
        ];
        
        let (e_initial, e_final, e_change) = calculate_energy_change(&initial, &final_knot);
        
        assert!(e_initial >= 0.0);
        assert!(e_final >= 0.0);
        assert!((e_change - (e_final - e_initial)).abs() < 1e-10);
    }

    #[test]
    fn test_evolve_knot_with_external_force() {
        let initial = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
        ];
        
        let mut params = KnotDynamicsParams::default();
        params.external_force = Some(DVector::from_vec(vec![0.1, 0.0, 0.0]));
        
        let evolved = evolve_knot(&initial, &params).unwrap();
        
        // With external force, knot should evolve
        assert_eq!(evolved.len(), initial.len());
    }
}
