// Rug (arbitrary precision) type adapter
// 
// Provides conversions between rug::Float and standard f64

use rug::Float;
use crate::adapters::nalgebra::vec_to_vector;
use nalgebra::DVector;

/// Convert nalgebra DVector to rug::Float vector
pub fn vector_to_rug(v: &DVector<f64>, precision: u32) -> Vec<Float> {
    v.iter()
        .map(|&x| Float::with_val(precision, x))
        .collect()
}

/// Convert rug::Float vector to nalgebra DVector
pub fn rug_to_vector(v: Vec<Float>) -> DVector<f64> {
    let f64_vec: Vec<f64> = v.iter().map(|x| x.to_f64()).collect();
    vec_to_vector(f64_vec)
}

/// Convert f64 to rug::Float with specified precision
pub fn f64_to_float(x: f64, precision: u32) -> Float {
    Float::with_val(precision, x)
}

/// Convert rug::Float to f64
pub fn float_to_f64(x: &Float) -> f64 {
    x.to_f64()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rug_conversion() {
        let precision = 256;
        let dvec = nalgebra::DVector::from_vec(vec![1.0, 2.0, 3.0]);
        let rug_vec = vector_to_rug(&dvec, precision);
        let converted_back = rug_to_vector(rug_vec);
        
        let expected_data = dvec.as_slice();
        let actual_data = converted_back.as_slice();
        assert_eq!(expected_data, actual_data);
    }

    #[test]
    fn test_float_conversion() {
        let precision = 256;
        let f = 3.14159;
        let float_val = f64_to_float(f, precision);
        let converted_back = float_to_f64(&float_val);
        
        // Allow for small floating point differences
        assert!((f - converted_back).abs() < 1e-10);
    }
}
