// Knot energy calculations
// 
// Implements knot energy: E_K = ∫_K |κ(s)|² ds
// Where κ(s) is the curvature at point s along the knot

use nalgebra::DVector;
use quadrature;

/// Calculate curvature at point along knot
/// 
/// Knot is represented as a parametric curve r(s) = (x(s), y(s), z(s))
/// Curvature: κ(s) = |d²r/ds²| = |r''(s)|
/// 
/// For discrete points, we use finite differences to approximate derivatives
pub fn calculate_curvature(
    _position: &DVector<f64>,
    _first_derivative: &DVector<f64>,
    second_derivative: &DVector<f64>,
) -> f64 {
    // Curvature magnitude: |r''(s)|
    // For a parametric curve, curvature = |r''(s)| / |r'(s)|³
    // But for knot energy, we use |r''(s)| directly
    second_derivative.norm()
}

/// Calculate curvature from discrete knot points
/// 
/// Uses finite differences to approximate derivatives
/// For point i:
/// - r'(s) ≈ (r_{i+1} - r_{i-1}) / (2*ds)
/// - r''(s) ≈ (r_{i+1} - 2*r_i + r_{i-1}) / ds²
pub fn calculate_curvature_from_points(
    points: &[DVector<f64>],
    index: usize,
) -> f64 {
    if points.len() < 3 {
        return 0.0; // Not enough points for curvature
    }
    
    if index == 0 || index >= points.len() - 1 {
        // Use forward/backward differences at boundaries
        if index == 0 {
            let ds = 1.0; // Normalized parameter
            let r0 = &points[0];
            let r1 = &points[1];
            let r2 = &points[2.min(points.len() - 1)];
            
            // Forward difference: r'' ≈ (r2 - 2*r1 + r0) / ds²
            let second_deriv = (r2 - r1) - (r1 - r0);
            return second_deriv.norm() / (ds * ds);
        } else {
            let ds = 1.0;
            let r_n = &points[index];
            let r_n1 = &points[index - 1];
            let r_n2 = &points[index.max(2) - 2];
            
            // Backward difference: r'' ≈ (r_n - 2*r_{n-1} + r_{n-2}) / ds²
            let second_deriv = (r_n - r_n1) - (r_n1 - r_n2);
            return second_deriv.norm() / (ds * ds);
        }
    }
    
    // Central difference for interior points
    let ds = 1.0; // Normalized parameter
    let r_prev = &points[index - 1];
    let r_curr = &points[index];
    let r_next = &points[index + 1];
    
    // Second derivative: r'' ≈ (r_{i+1} - 2*r_i + r_{i-1}) / ds²
    let second_deriv = (r_next - r_curr) - (r_curr - r_prev);
    second_deriv.norm() / (ds * ds)
}

/// Calculate knot energy: E_K = ∫_K |κ(s)|² ds
/// 
/// Uses numerical integration (quadrature) to integrate curvature squared
/// 
/// Input: curve_points as discrete points along the knot
/// Output: Total energy
pub fn calculate_knot_energy(curve_points: &[DVector<f64>]) -> f64 {
    if curve_points.len() < 3 {
        return 0.0; // Not enough points for energy calculation
    }
    
    // Create curvature function from discrete points
    // We'll integrate |κ(s)|² over the normalized parameter space [0, 1]
    let n = curve_points.len();
    
    // Use Simpson's rule via quadrature library
    // We need to create a function that maps parameter s ∈ [0, 1] to curvature
    let curvature_squared = |s: f64| -> f64 {
        // Map s ∈ [0, 1] to index in curve_points
        let index_f = s * (n - 1) as f64;
        let index = index_f.floor() as usize;
        let frac = index_f - index as f64;
        
        // Clamp index to valid range
        let idx = index.min(n - 1);
        let next_idx = (index + 1).min(n - 1);
        
        // Interpolate curvature between points
        let kappa_curr = calculate_curvature_from_points(curve_points, idx);
        let kappa_next = if next_idx != idx {
            calculate_curvature_from_points(curve_points, next_idx)
        } else {
            kappa_curr
        };
        
        // Linear interpolation
        let kappa = kappa_curr * (1.0 - frac) + kappa_next * frac;
        
        // Return |κ(s)|²
        kappa * kappa
    };
    
    // Integrate |κ(s)|² over [0, 1]
    let result = quadrature::integrate(
        curvature_squared,
        0.0,
        1.0,
        1e-6, // Tolerance
    );
    
    result.integral
}

/// Calculate energy gradient: ∇E_K = ∂E_K/∂r
/// 
/// Returns gradient vector for energy minimization
/// Uses finite differences to approximate gradient
pub fn calculate_energy_gradient(
    curve_points: &[DVector<f64>],
) -> Vec<DVector<f64>> {
    if curve_points.is_empty() {
        return Vec::new();
    }
    
    let epsilon = 1e-6; // Small perturbation for finite differences
    let mut gradients = Vec::new();
    
    // Calculate gradient at each point
    for i in 0..curve_points.len() {
        let mut gradient = DVector::zeros(3);
        
        // Perturb each coordinate and calculate energy change
        for coord in 0..3 {
            let mut perturbed_points = curve_points.to_vec();
            perturbed_points[i][coord] += epsilon;
            
            let energy_plus = calculate_knot_energy(&perturbed_points);
            
            perturbed_points[i][coord] -= 2.0 * epsilon;
            let energy_minus = calculate_knot_energy(&perturbed_points);
            
            // Gradient component: ∂E/∂r_i = (E(r_i + ε) - E(r_i - ε)) / (2ε)
            gradient[coord] = (energy_plus - energy_minus) / (2.0 * epsilon);
        }
        
        gradients.push(gradient);
    }
    
    gradients
}

/// Calculate knot length
/// 
/// L = ∫_K ds = Σ |r_{i+1} - r_i|
pub fn calculate_knot_length(curve_points: &[DVector<f64>]) -> f64 {
    if curve_points.len() < 2 {
        return 0.0;
    }
    
    let mut length = 0.0;
    for i in 0..curve_points.len() - 1 {
        let segment = &curve_points[i + 1] - &curve_points[i];
        length += segment.norm();
    }
    
    length
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DVector;

    #[test]
    fn test_curvature_calculation() {
        // Test with simple curve: straight line should have zero curvature
        let position = DVector::from_vec(vec![0.0, 0.0, 0.0]);
        let first_deriv = DVector::from_vec(vec![1.0, 0.0, 0.0]);
        let second_deriv = DVector::from_vec(vec![0.0, 0.0, 0.0]);
        
        let curvature = calculate_curvature(&position, &first_deriv, &second_deriv);
        assert!((curvature - 0.0).abs() < 1e-10);
    }

    #[test]
    fn test_curvature_from_points() {
        // Straight line: all points on line, should have low curvature
        let points = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
        ];
        
        let curvature = calculate_curvature_from_points(&points, 1);
        // Straight line should have zero curvature
        assert!(curvature.abs() < 1e-6);
    }

    #[test]
    fn test_knot_energy() {
        // Straight line should have zero energy
        let points = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
            DVector::from_vec(vec![3.0, 0.0, 0.0]),
        ];
        
        let energy = calculate_knot_energy(&points);
        // Straight line should have very low energy
        assert!(energy >= 0.0);
        assert!(energy < 1e-3);
    }

    #[test]
    fn test_knot_length() {
        let points = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
        ];
        
        let length = calculate_knot_length(&points);
        assert!((length - 2.0).abs() < 1e-10); // Distance from 0 to 2
    }

    #[test]
    fn test_energy_gradient() {
        let points = vec![
            DVector::from_vec(vec![0.0, 0.0, 0.0]),
            DVector::from_vec(vec![1.0, 0.0, 0.0]),
            DVector::from_vec(vec![2.0, 0.0, 0.0]),
        ];
        
        let gradients = calculate_energy_gradient(&points);
        assert_eq!(gradients.len(), points.len());
        // Gradients should be vectors
        for grad in &gradients {
            assert_eq!(grad.len(), 3);
        }
    }
}
