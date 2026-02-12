// Braid group operations
// 
// Implements braid group mathematics using nalgebra for matrix operations

use nalgebra::DMatrix;
use serde::{Deserialize, Serialize};

/// Braid representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Braid {
    number_of_strands: usize,
    crossings: Vec<BraidCrossing>,
}

/// Braid crossing (generator)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BraidCrossing {
    /// Strand index (0-based)
    pub strand: usize,
    /// Direction: true = over, false = under
    pub is_over: bool,
}

impl Braid {
    /// Create new braid with n strands
    pub fn new(number_of_strands: usize) -> Self {
        Braid {
            number_of_strands,
            crossings: Vec::new(),
        }
    }

    /// Add crossing (generator σ_i)
    pub fn add_crossing(&mut self, strand: usize, is_over: bool) -> Result<(), String> {
        if strand >= self.number_of_strands - 1 {
            return Err(format!(
                "Strand index {} out of range for {} strands",
                strand, self.number_of_strands
            ));
        }
        self.crossings.push(BraidCrossing { strand, is_over });
        Ok(())
    }

    /// Get number of strands
    pub fn strands(&self) -> usize {
        self.number_of_strands
    }

    /// Get all crossings
    pub fn get_crossings(&self) -> &[BraidCrossing] {
        &self.crossings
    }

    /// Convert to matrix representation (for braid group operations)
    pub fn to_matrix(&self) -> DMatrix<f64> {
        // Create identity matrix as base
        let mut matrix = DMatrix::<f64>::identity(self.number_of_strands, self.number_of_strands);
        
        // Apply each crossing (generator σ_i)
        for crossing in &self.crossings {
            let gen_matrix = self.generator_matrix(crossing.strand, crossing.is_over);
            matrix = gen_matrix * matrix;
        }
        
        matrix
    }

    /// Generate matrix for braid generator σ_i
    fn generator_matrix(&self, i: usize, is_over: bool) -> DMatrix<f64> {
        let n = self.number_of_strands;
        let mut matrix = DMatrix::<f64>::identity(n, n);
        
        // Braid generator σ_i exchanges strands i and i+1
        // This is a permutation matrix with additional phase if under-crossing
        if is_over {
            // Standard over-crossing (identity-like permutation)
            matrix[(i, i)] = 0.0;
            matrix[(i, i + 1)] = 1.0;
            matrix[(i + 1, i)] = 1.0;
            matrix[(i + 1, i + 1)] = 0.0;
        } else {
            // Under-crossing (inverse permutation)
            matrix[(i, i)] = 0.0;
            matrix[(i, i + 1)] = -1.0;
            matrix[(i + 1, i)] = -1.0;
            matrix[(i + 1, i + 1)] = 0.0;
        }
        
        matrix
    }

    /// Close braid to form a knot
    /// 
    /// Topological closure connects the top strands to bottom strands
    /// This creates a knot from the braid representation
    pub fn close_to_knot(&self) -> Knot {
        // For now, create a simple knot representation
        // Actual implementation would perform topological closure
        Knot {
            braid: self.clone(),
            crossing_number: self.crossings.len(),
        }
    }

    /// Calculate braid word (sequence of generators)
    /// 
    /// Returns string representation like "σ₁ σ₂⁻¹ σ₁"
    pub fn braid_word(&self) -> String {
        let mut word = String::new();
        for (i, crossing) in self.crossings.iter().enumerate() {
            if i > 0 {
                word.push(' ');
            }
            word.push_str(&format!("σ{}", crossing.strand + 1));
            if !crossing.is_over {
                word.push_str("⁻¹");
            }
        }
        word
    }
}

/// Knot representation (created from braid closure)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Knot {
    pub braid: Braid,
    pub crossing_number: usize,
}

impl Knot {
    /// Create new knot from braid
    pub fn from_braid(braid: Braid) -> Self {
        Knot {
            crossing_number: braid.get_crossings().len(),
            braid,
        }
    }

    /// Get crossing number
    pub fn crossing_number(&self) -> usize {
        self.crossing_number
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_braid_creation() {
        let braid = Braid::new(4);
        assert_eq!(braid.strands(), 4);
        assert_eq!(braid.get_crossings().len(), 0);
    }

    #[test]
    fn test_add_crossing() {
        let mut braid = Braid::new(4);
        braid.add_crossing(1, true).unwrap();
        assert_eq!(braid.get_crossings().len(), 1);
    }

    #[test]
    fn test_crossing_out_of_range() {
        let mut braid = Braid::new(4);
        let result = braid.add_crossing(4, true);
        assert!(result.is_err());
    }
}
