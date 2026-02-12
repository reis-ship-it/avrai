// Polynomial Interpolation Utilities
// 
// Provides cubic spline, Bézier, and Hermite interpolation methods
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Enhanced Worldsheet Interpolation, Phase 3: Polynomial String Interpolation

import 'dart:math' as math;

/// Point in 2D space (for interpolation)
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator -(Point other) => Point(x - other.x, y - other.y);
  Point operator *(double scalar) => Point(x * scalar, y * scalar);
  Point operator /(double scalar) => Point(x / scalar, y / scalar);

  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'Point($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Vector in 2D space (for derivatives/tangents)
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);

  double get length => math.sqrt(x * x + y * y);
  Vector2 get normalized => length > 0 ? this / length : this;

  @override
  String toString() => 'Vector2($x, $y)';
}

/// Cubic spline interpolation
/// 
/// Creates smooth curves through a set of points using cubic polynomials
/// 
/// **Algorithm:**
/// - Calculate cubic spline coefficients for each segment
/// - Interpolate at parameter t (0.0 to 1.0) between points
/// 
/// **Formula:**
/// S(t) = a + b*t + c*t² + d*t³
/// 
/// Where coefficients are calculated to ensure:
/// - Continuity (S_i(1) = S_{i+1}(0))
/// - Smoothness (S'_i(1) = S'_{i+1}(0))
/// - Curvature continuity (S''_i(1) = S''_{i+1}(0))
Point cubicSplineInterpolate(List<Point> points, double t) {
  if (points.isEmpty) {
    throw ArgumentError('Points list cannot be empty');
  }
  
  if (points.length == 1) {
    return points[0];
  }
  
  // Clamp t to [0, 1]
  t = t.clamp(0.0, 1.0);
  
  // For 2 points, use linear interpolation
  if (points.length == 2) {
    return Point(
      points[0].x * (1 - t) + points[1].x * t,
      points[0].y * (1 - t) + points[1].y * t,
    );
  }
  
  // For 3+ points, use natural cubic spline
  // Calculate spline coefficients
  final n = points.length - 1;
  final h = List<double>.generate(n, (i) => 
    points[i + 1].x - points[i].x);
  
  // Calculate second derivatives (natural spline: second derivative = 0 at endpoints)
  final ypp = _calculateSecondDerivatives(points, h);
  
  // Find which segment t falls into
  final segmentIndex = (t * n).floor().clamp(0, n - 1);
  final localT = (t * n) - segmentIndex;
  
  // Interpolate in this segment
  final i = segmentIndex;
  final a = points[i].y;
  final b = (points[i + 1].y - points[i].y) / h[i] - 
            h[i] * (ypp[i + 1] + 2 * ypp[i]) / 6;
  final c = ypp[i] / 2;
  final d = (ypp[i + 1] - ypp[i]) / (6 * h[i]);
  
  final y = a + b * localT + c * localT * localT + d * localT * localT * localT;
  
  // Interpolate x linearly (assuming uniform spacing or use actual x values)
  final x = points[i].x * (1 - localT) + points[i + 1].x * localT;
  
  return Point(x, y);
}

/// Calculate second derivatives for natural cubic spline
List<double> _calculateSecondDerivatives(List<Point> points, List<double> h) {
  final n = points.length - 1;
  final ypp = List<double>.filled(n + 1, 0.0);
  
  if (n < 2) {
    return ypp; // Not enough points for cubic spline
  }
  
  // Tridiagonal system: solve for second derivatives
  final u = List<double>.filled(n, 0.0);
  
  // Forward elimination
  for (int i = 1; i < n; i++) {
    final sig = h[i - 1] / (h[i - 1] + h[i]);
    final p = sig * ypp[i - 1] + 2.0;
    ypp[i] = (sig - 1.0) / p;
    u[i] = (points[i + 1].y - points[i].y) / h[i] - 
           (points[i].y - points[i - 1].y) / h[i - 1];
    u[i] = (6.0 * u[i] / (h[i - 1] + h[i]) - sig * u[i - 1]) / p;
  }
  
  // Back substitution (natural spline: ypp[0] = ypp[n] = 0)
  for (int i = n - 1; i >= 1; i--) {
    ypp[i] = ypp[i] * ypp[i + 1] + u[i];
  }
  
  return ypp;
}

/// Bézier curve interpolation
/// 
/// Interpolates along a Bézier curve defined by control points
/// 
/// **Formula:**
/// B(t) = Σ(i=0 to n) C(n,i) * (1-t)^(n-i) * t^i * P_i
/// 
/// Where:
/// - C(n,i) = binomial coefficient
/// - P_i = control points
/// - t = parameter (0.0 to 1.0)
Point bezierInterpolate(List<Point> controlPoints, double t) {
  if (controlPoints.isEmpty) {
    throw ArgumentError('Control points cannot be empty');
  }
  
  if (controlPoints.length == 1) {
    return controlPoints[0];
  }
  
  // Clamp t to [0, 1]
  t = t.clamp(0.0, 1.0);
  
  final n = controlPoints.length - 1;
  var result = Point(0.0, 0.0);
  
  for (int i = 0; i <= n; i++) {
    final binomial = _binomialCoefficient(n, i);
    final bernstein = binomial * 
                      math.pow(1 - t, n - i) * 
                      math.pow(t, i);
    
    result = Point(
      result.x + controlPoints[i].x * bernstein,
      result.y + controlPoints[i].y * bernstein,
    );
  }
  
  return result;
}

/// Calculate binomial coefficient C(n, k)
int _binomialCoefficient(int n, int k) {
  if (k > n - k) {
    k = n - k; // Use symmetry
  }
  
  int result = 1;
  for (int i = 0; i < k; i++) {
    result = result * (n - i) ~/ (i + 1);
  }
  
  return result;
}

/// Hermite interpolation
/// 
/// Interpolates between two points with specified tangents (derivatives)
/// 
/// **Formula:**
/// H(t) = h₀₀(t)*P₀ + h₁₀(t)*P₁ + h₀₁(t)*M₀ + h₁₁(t)*M₁
/// 
/// Where:
/// - h₀₀, h₁₀, h₀₁, h₁₁ = Hermite basis functions
/// - P₀, P₁ = points
/// - M₀, M₁ = tangents (derivatives)
Point hermiteInterpolate(
  Point p0,
  Point p1,
  Vector2 m0,
  Vector2 m1,
  double t,
) {
  // Clamp t to [0, 1]
  t = t.clamp(0.0, 1.0);
  
  // Hermite basis functions
  final t2 = t * t;
  final t3 = t2 * t;
  
  final h00 = 2 * t3 - 3 * t2 + 1;
  final h10 = -2 * t3 + 3 * t2;
  final h01 = t3 - 2 * t2 + t;
  final h11 = t3 - t2;
  
  return Point(
    h00 * p0.x + h10 * p1.x + h01 * m0.x + h11 * m1.x,
    h00 * p0.y + h10 * p1.y + h01 * m0.y + h11 * m1.y,
  );
}

/// Interpolate scalar value using cubic spline
/// 
/// Useful for interpolating knot invariants (crossing number, writhe, etc.)
double cubicSplineInterpolateScalar(List<double> values, double t) {
  if (values.isEmpty) {
    throw ArgumentError('Values list cannot be empty');
  }
  
  if (values.length == 1) {
    return values[0];
  }
  
  // Clamp t to [0, 1]
  t = t.clamp(0.0, 1.0);
  
  // For 2 values, use linear interpolation
  if (values.length == 2) {
    return values[0] * (1 - t) + values[1] * t;
  }
  
  // Create points from values (x = index, y = value)
  final points = List<Point>.generate(
    values.length,
    (i) => Point(i.toDouble(), values[i]),
  );
  
  // Interpolate
  final result = cubicSplineInterpolate(points, t);
  return result.y;
}

/// Interpolate list of values using cubic spline
/// 
/// Useful for interpolating polynomial coefficients
List<double> cubicSplineInterpolateList(
  List<double> values1,
  List<double> values2,
  double t,
) {
  // Clamp t to [0, 1]
  t = t.clamp(0.0, 1.0);
  
  final maxLength = values1.length > values2.length 
      ? values1.length 
      : values2.length;
  
  final result = <double>[];
  
  for (int i = 0; i < maxLength; i++) {
    final val1 = i < values1.length ? values1[i] : 0.0;
    final val2 = i < values2.length ? values2[i] : 0.0;
    
    // Use cubic spline interpolation for smoother curves
    if (values1.length >= 3 && values2.length >= 3) {
      // Create points for spline
      final points = [
        Point(0.0, val1),
        Point(0.5, (val1 + val2) / 2),
        Point(1.0, val2),
      ];
      final interpolated = cubicSplineInterpolate(points, t);
      result.add(interpolated.y);
    } else {
      // Fall back to linear interpolation
      result.add(val1 * (1 - t) + val2 * t);
    }
  }
  
  return result;
}

/// Calculate tangent (derivative) at point for Hermite interpolation
/// 
/// Uses finite differences to estimate tangent
Vector2 calculateTangent(List<Point> points, int index) {
  if (points.length < 2) {
    return const Vector2(0.0, 0.0);
  }
  
  if (index == 0) {
    // Forward difference
    return Vector2(
      points[1].x - points[0].x,
      points[1].y - points[0].y,
    );
  } else if (index == points.length - 1) {
    // Backward difference
    return Vector2(
      points[index].x - points[index - 1].x,
      points[index].y - points[index - 1].y,
    );
  } else {
    // Central difference (more accurate)
    return Vector2(
      (points[index + 1].x - points[index - 1].x) / 2,
      (points[index + 1].y - points[index - 1].y) / 2,
    );
  }
}

/// Interpolate multiple points using cubic spline
/// 
/// Returns list of interpolated points at regular intervals
List<Point> cubicSplineInterpolatePoints(
  List<Point> points,
  int numOutputPoints,
) {
  if (points.isEmpty) {
    return [];
  }
  
  if (points.length == 1) {
    return List<Point>.filled(numOutputPoints, points[0]);
  }
  
  final result = <Point>[];
  
  for (int i = 0; i < numOutputPoints; i++) {
    final t = i / (numOutputPoints - 1);
    result.add(cubicSplineInterpolate(points, t));
  }
  
  return result;
}
