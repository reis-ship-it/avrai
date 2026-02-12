// Russell (scientific computing) type adapter
// 
// Provides conversions between Russell ODE types and nalgebra types

// Russell ODE adapter
// Note: russell_ode API may differ - this is a placeholder implementation
// Actual implementation will be completed when integrating russell_ode in Week 3

use crate::adapters::nalgebra::{vector_to_vec, vec_to_vector};
use nalgebra::DVector;

/// Convert nalgebra DVector to Vec<f64> for Russell ODE
pub fn vector_to_russell(v: &DVector<f64>) -> Vec<f64> {
    vector_to_vec(v)
}

/// Convert Vec<f64> from Russell ODE to nalgebra DVector
pub fn russell_to_vector(v: Vec<f64>) -> DVector<f64> {
    vec_to_vector(v)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_russell_conversion() {
        let dvec = nalgebra::DVector::from_vec(vec![1.0, 2.0, 3.0]);
        let russell = vector_to_russell(&dvec);
        let converted_back = russell_to_vector(russell);
        
        let expected_data = dvec.as_slice();
        let actual_data = converted_back.as_slice();
        assert_eq!(expected_data, actual_data);
    }
}
