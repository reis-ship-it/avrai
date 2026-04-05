// Nalgebra type adapter
// 
// Provides conversions between nalgebra types (DVector, DMatrix) and standard Rust types (Vec<f64>)

use nalgebra::{DVector, DMatrix};

/// Convert nalgebra DVector to standard Vec<f64>
pub fn vector_to_vec(v: &DVector<f64>) -> Vec<f64> {
    v.iter().copied().collect()
}

/// Convert standard Vec<f64> to nalgebra DVector
pub fn vec_to_vector(v: Vec<f64>) -> DVector<f64> {
    DVector::from_vec(v)
}

/// Convert nalgebra DMatrix to Vec<Vec<f64>>
pub fn matrix_to_vec(m: &DMatrix<f64>) -> Vec<Vec<f64>> {
    (0..m.nrows())
        .map(|i| m.row(i).iter().copied().collect())
        .collect()
}

/// Convert Vec<Vec<f64>> to nalgebra DMatrix
pub fn vec_to_matrix(v: Vec<Vec<f64>>) -> DMatrix<f64> {
    let rows = v.len();
    if rows == 0 {
        return DMatrix::zeros(0, 0);
    }
    let cols = v[0].len();
    DMatrix::from_fn(rows, cols, |i, j| v[i][j])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vector_conversion() {
        let vec = vec![1.0, 2.0, 3.0];
        let dvec = vec_to_vector(vec.clone());
        let converted_back = vector_to_vec(&dvec);
        assert_eq!(vec, converted_back);
    }

    #[test]
    fn test_matrix_conversion() {
        let mat = vec![vec![1.0, 2.0], vec![3.0, 4.0]];
        let dmat = vec_to_matrix(mat.clone());
        let converted_back = matrix_to_vec(&dmat);
        assert_eq!(mat, converted_back);
    }
}
