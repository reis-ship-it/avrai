// Statistical mechanics for knots
// 
// Implements thermodynamic properties: partition function, Boltzmann distribution, entropy, free energy

// Statistical mechanics for knots
// (Note: ln_gamma not used in current implementation, but available if needed)

/// Calculate partition function: Z = Σ exp(-E_i / k_B T)
/// 
/// Where:
/// - E_i = energy of knot configuration i
/// - k_B = Boltzmann constant
/// - T = temperature
pub fn calculate_partition_function(
    energies: &[f64],
    temperature: f64,
) -> f64 {
    let k_b = 1.0; // Boltzmann constant (normalized)
    let beta = 1.0 / (k_b * temperature);
    
    energies
        .iter()
        .map(|&e| (-beta * e).exp())
        .sum()
}

/// Calculate Boltzmann distribution: P_i = (1/Z) · exp(-E_i / k_B T)
pub fn calculate_boltzmann_distribution(
    energies: &[f64],
    temperature: f64,
) -> Vec<f64> {
    let z = calculate_partition_function(energies, temperature);
    let k_b = 1.0;
    let beta = 1.0 / (k_b * temperature);
    
    energies
        .iter()
        .map(|&e| (-beta * e).exp() / z)
        .collect()
}

/// Calculate entropy: S = -Σ P_i · ln(P_i)
pub fn calculate_entropy(probabilities: &[f64]) -> f64 {
    probabilities
        .iter()
        .filter(|&&p| p > 1e-10) // Avoid log(0)
        .map(|&p| -p * p.ln())
        .sum()
}

/// Calculate free energy: F = E - T·S
pub fn calculate_free_energy(
    energy: f64,
    entropy: f64,
    temperature: f64,
) -> f64 {
    energy - temperature * entropy
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_boltzmann_distribution() {
        let energies = vec![1.0, 2.0, 3.0];
        let temperature = 1.0;
        let distribution = calculate_boltzmann_distribution(&energies, temperature);
        
        // Probabilities should sum to 1
        let sum: f64 = distribution.iter().sum();
        assert!((sum - 1.0).abs() < 1e-10);
        
        // Lower energy should have higher probability
        assert!(distribution[0] > distribution[1]);
        assert!(distribution[1] > distribution[2]);
    }

    #[test]
    fn test_entropy() {
        // Maximum entropy for uniform distribution
        let uniform = vec![0.33, 0.33, 0.34];
        let entropy = calculate_entropy(&uniform);
        
        assert!(entropy > 0.0);
        assert!(entropy < 2.0); // Should be less than ln(3) ≈ 1.1
    }

    #[test]
    fn test_free_energy() {
        let energy = 10.0;
        let entropy = 2.0;
        let temperature = 1.0;
        let free_energy = calculate_free_energy(energy, entropy, temperature);
        
        assert!((free_energy - 8.0).abs() < 1e-10); // F = E - TS = 10 - 1*2 = 8
    }
}
