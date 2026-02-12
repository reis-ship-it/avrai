// Precision float abstraction
//
// Uses rug::Float on non-iOS targets and a lightweight f64 wrapper on iOS to
// avoid GMP/MPFR cross-compilation issues during demo builds.

#[cfg(not(target_os = "ios"))]
pub use rug::Float;

#[cfg(target_os = "ios")]
use serde::{Deserialize, Serialize};

#[cfg(target_os = "ios")]
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Serialize, Deserialize)]
pub struct Float(pub f64);

#[cfg(target_os = "ios")]
impl Float {
    pub fn with_val(_precision: u32, value: f64) -> Self {
        Float(value)
    }

    pub fn to_f64(&self) -> f64 {
        self.0
    }

    pub fn sqrt(self) -> Self {
        Float(self.0.sqrt())
    }
}

#[cfg(target_os = "ios")]
impl std::ops::Add for Float {
    type Output = Float;

    fn add(self, rhs: Float) -> Float {
        Float(self.0 + rhs.0)
    }
}

#[cfg(target_os = "ios")]
impl std::ops::Sub for Float {
    type Output = Float;

    fn sub(self, rhs: Float) -> Float {
        Float(self.0 - rhs.0)
    }
}

#[cfg(target_os = "ios")]
impl std::ops::Mul for Float {
    type Output = Float;

    fn mul(self, rhs: Float) -> Float {
        Float(self.0 * rhs.0)
    }
}

#[cfg(target_os = "ios")]
impl std::ops::Div for Float {
    type Output = Float;

    fn div(self, rhs: Float) -> Float {
        Float(self.0 / rhs.0)
    }
}

#[cfg(target_os = "ios")]
impl std::ops::AddAssign for Float {
    fn add_assign(&mut self, rhs: Float) {
        self.0 += rhs.0;
    }
}

#[cfg(target_os = "ios")]
impl std::ops::SubAssign for Float {
    fn sub_assign(&mut self, rhs: Float) {
        self.0 -= rhs.0;
    }
}

#[cfg(target_os = "ios")]
impl std::ops::MulAssign for Float {
    fn mul_assign(&mut self, rhs: Float) {
        self.0 *= rhs.0;
    }
}

#[cfg(target_os = "ios")]
impl std::ops::DivAssign for Float {
    fn div_assign(&mut self, rhs: Float) {
        self.0 /= rhs.0;
    }
}

#[cfg(not(target_os = "ios"))]
pub fn pow(base: Float, exp: u32) -> Float {
    rug::ops::Pow::pow(base, exp)
}

#[cfg(target_os = "ios")]
pub fn pow(base: Float, exp: u32) -> Float {
    Float(base.0.powi(exp as i32))
}
