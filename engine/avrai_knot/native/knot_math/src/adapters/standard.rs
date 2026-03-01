// Standard type conversions
// 
// Provides utility functions for standard Rust type conversions used across adapters

/// Normalize a vector to unit length
pub fn normalize_vec(v: &[f64]) -> Vec<f64> {
    let magnitude: f64 = v.iter().map(|x| x * x).sum::<f64>().sqrt();
    if magnitude < 1e-10 {
        return v.to_vec(); // Return original if zero vector
    }
    v.iter().map(|&x| x / magnitude).collect()
}

/// Add two vectors element-wise
pub fn vec_add(a: &[f64], b: &[f64]) -> Result<Vec<f64>, String> {
    if a.len() != b.len() {
        return Err(format!("Vector length mismatch: {} != {}", a.len(), b.len()));
    }
    Ok(a.iter().zip(b.iter()).map(|(x, y)| x + y).collect())
}

/// Multiply vector by scalar
pub fn vec_scale(v: &[f64], scalar: f64) -> Vec<f64> {
    v.iter().map(|&x| x * scalar).collect()
}

/// Calculate dot product of two vectors
pub fn vec_dot(a: &[f64], b: &[f64]) -> Result<f64, String> {
    if a.len() != b.len() {
        return Err(format!("Vector length mismatch: {} != {}", a.len(), b.len()));
    }
    Ok(a.iter().zip(b.iter()).map(|(x, y)| x * y).sum())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize() {
        let v = vec![3.0, 4.0];
        let normalized = normalize_vec(&v);
        let magnitude: f64 = normalized.iter().map(|x| x * x).sum::<f64>().sqrt();
        assert!((magnitude - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_vec_add() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        let result = vec_add(&a, &b).unwrap();
        assert_eq!(result, vec![5.0, 7.0, 9.0]);
    }

    #[test]
    fn test_vec_dot() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        let result = vec_dot(&a, &b).unwrap();
        assert_eq!(result, 32.0); // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    }
}
