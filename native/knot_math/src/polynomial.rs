// Polynomial mathematics for knot invariants
// 
// Implements polynomial operations needed for Jones and Alexander polynomials
// Uses rug::Float on non-iOS targets, f64 fallback on iOS

use crate::precision_float::{Float, pow};
use serde::{Deserialize, Serialize};

/// Polynomial with arbitrary precision coefficients
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Polynomial {
    coefficients: Vec<Float>,
}

impl Polynomial {
    /// Create new polynomial from coefficients (lowest degree first)
    pub fn new(coefficients: Vec<f64>) -> Self {
        let precision = 256; // 256 bits of precision
        Polynomial {
            coefficients: coefficients
                .iter()
                .map(|&c| Float::with_val(precision, c))
                .collect(),
        }
    }

    /// Evaluate polynomial at point x
    pub fn evaluate(&self, x: f64) -> f64 {
        let precision = 256;
        let x_float = Float::with_val(precision, x);
        let mut result = Float::with_val(precision, 0.0);
        
        for (i, coeff) in self.coefficients.iter().enumerate() {
            let x_power = if i == 0 {
                Float::with_val(precision, 1.0)
            } else {
                pow(x_float.clone(), i as u32)
            };
            let term = coeff.clone() * x_power;
            result += term;
        }
        
        result.to_f64()
    }

    /// Get degree of polynomial
    pub fn degree(&self) -> usize {
        // Find highest non-zero coefficient
        for (i, coeff) in self.coefficients.iter().enumerate().rev() {
            if coeff.to_f64().abs() > 1e-10 {
                return i;
            }
        }
        0
    }

    /// Get coefficient at given degree
    pub fn coefficient(&self, degree: usize) -> f64 {
        if degree >= self.coefficients.len() {
            0.0
        } else {
            self.coefficients[degree].to_f64()
        }
    }

    /// Convert to Vec<f64> for FFI
    pub fn to_vec(&self) -> Vec<f64> {
        self.coefficients.iter().map(|c| c.to_f64()).collect()
    }

    /// Create from Vec<f64> (for FFI)
    pub fn from_vec(v: Vec<f64>) -> Self {
        Self::new(v)
    }

    /// Add two polynomials
    pub fn add(&self, other: &Polynomial) -> Polynomial {
        let max_len = self.coefficients.len().max(other.coefficients.len());
        let precision = 256;
        let mut result_coeffs = Vec::new();
        
        for i in 0..max_len {
            let a = if i < self.coefficients.len() {
                self.coefficients[i].clone()
            } else {
                Float::with_val(precision, 0.0)
            };
            let b = if i < other.coefficients.len() {
                other.coefficients[i].clone()
            } else {
                Float::with_val(precision, 0.0)
            };
            result_coeffs.push(a + b);
        }
        
        Polynomial {
            coefficients: result_coeffs,
        }
    }

    /// Multiply two polynomials
    pub fn multiply(&self, other: &Polynomial) -> Polynomial {
        let precision = 256;
        let result_len = self.coefficients.len() + other.coefficients.len() - 1;
        let mut result_coeffs = vec![Float::with_val(precision, 0.0); result_len];
        
        for (i, a) in self.coefficients.iter().enumerate() {
            for (j, b) in other.coefficients.iter().enumerate() {
                result_coeffs[i + j] += a.clone() * b.clone();
            }
        }
        
        Polynomial {
            coefficients: result_coeffs,
        }
    }

    /// Calculate distance between two polynomials
    /// Uses L2 norm: d = sqrt(Σ(a_i - b_i)²)
    pub fn distance(&self, other: &Polynomial) -> f64 {
        let max_len = self.coefficients.len().max(other.coefficients.len());
        let precision = 256;
        let mut sum_sq = Float::with_val(precision, 0.0);
        
        for i in 0..max_len {
            let a = if i < self.coefficients.len() {
                self.coefficients[i].clone()
            } else {
                Float::with_val(precision, 0.0)
            };
            let b = if i < other.coefficients.len() {
                other.coefficients[i].clone()
            } else {
                Float::with_val(precision, 0.0)
            };
            let diff = a - b;
            sum_sq += diff.clone() * diff;
        }
        
        sum_sq.sqrt().to_f64()
    }

    /// Normalize polynomial (scale so leading coefficient is 1)
    pub fn normalize(&self) -> Polynomial {
        let _precision = 256;
        if let Some(leading) = self.coefficients.last() {
            if leading.to_f64().abs() > 1e-10 {
                let scale = leading.clone();
                Polynomial {
                    coefficients: self.coefficients.iter()
                        .map(|c| c.clone() / scale.clone())
                        .collect(),
                }
            } else {
                self.clone()
            }
        } else {
            self.clone()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_polynomial_evaluation() {
        // Test polynomial: 1 + 2x + 3x²
        let poly = Polynomial::new(vec![1.0, 2.0, 3.0]);
        
        // At x = 0: should be 1
        assert!((poly.evaluate(0.0) - 1.0).abs() < 1e-10);
        
        // At x = 1: should be 1 + 2 + 3 = 6
        assert!((poly.evaluate(1.0) - 6.0).abs() < 1e-10);
    }

    #[test]
    fn test_polynomial_degree() {
        let poly = Polynomial::new(vec![1.0, 2.0, 3.0, 0.0]);
        assert_eq!(poly.degree(), 2); // Highest non-zero is degree 2
    }

    #[test]
    fn test_polynomial_add() {
        let p1 = Polynomial::new(vec![1.0, 2.0]);
        let p2 = Polynomial::new(vec![3.0, 4.0, 5.0]);
        let sum = p1.add(&p2);
        
        // Should be: 1+3, 2+4, 0+5 = [4, 6, 5]
        assert!((sum.coefficient(0) - 4.0).abs() < 1e-10);
        assert!((sum.coefficient(1) - 6.0).abs() < 1e-10);
        assert!((sum.coefficient(2) - 5.0).abs() < 1e-10);
    }

    #[test]
    fn test_polynomial_multiply() {
        let p1 = Polynomial::new(vec![1.0, 2.0]);  // 1 + 2x
        let p2 = Polynomial::new(vec![3.0, 4.0]);  // 3 + 4x
        let product = p1.multiply(&p2);
        
        // Should be: (1+2x)(3+4x) = 3 + 10x + 8x²
        assert!((product.coefficient(0) - 3.0).abs() < 1e-10);
        assert!((product.coefficient(1) - 10.0).abs() < 1e-10);
        assert!((product.coefficient(2) - 8.0).abs() < 1e-10);
    }

    #[test]
    fn test_polynomial_distance() {
        let p1 = Polynomial::new(vec![1.0, 2.0, 3.0]);
        let p2 = Polynomial::new(vec![1.0, 2.0, 4.0]);
        let dist = p1.distance(&p2);
        
        // Distance should be |3-4| = 1
        assert!((dist - 1.0).abs() < 1e-10);
    }
}
