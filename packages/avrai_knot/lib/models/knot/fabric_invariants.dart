// Fabric Invariants Model
// 
// Represents topological invariants of a knot fabric
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';

/// Polynomial representation
/// 
/// Coefficients are stored in order of increasing degree
/// e.g., [1, 2, 3] represents 1 + 2x + 3x²
class Polynomial extends Equatable {
  final List<double> coefficients;
  
  const Polynomial(this.coefficients);
  
  /// Evaluate polynomial at x
  double evaluate(double x) {
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * _power(x, i);
    }
    return result;
  }
  
  double _power(double base, int exponent) {
    if (exponent == 0) return 1.0;
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
  
  /// Get degree of polynomial
  int get degree => coefficients.isEmpty ? 0 : coefficients.length - 1;
  
  @override
  List<Object?> get props => [coefficients];

  /// Create from JSON
  factory Polynomial.fromJson(Map<String, dynamic> json) {
    return Polynomial(List<double>.from(json['coefficients'] ?? []));
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'coefficients': coefficients,
    };
  }
}

/// Fabric Invariants
/// 
/// Topological invariants that characterize the fabric structure
class FabricInvariants extends Equatable {
  /// Jones polynomial of the fabric
  final Polynomial jonesPolynomial;
  
  /// Alexander polynomial of the fabric
  final Polynomial alexanderPolynomial;
  
  /// Total number of crossings in the fabric
  final int crossingNumber;
  
  /// Fabric density: crossings per strand
  /// Higher density = more interconnections
  final double density;
  
  /// Fabric stability: community cohesion measure (0.0-1.0)
  /// High stability = cohesive community
  /// Low stability = fragmented community
  final double stability;
  
  const FabricInvariants({
    required this.jonesPolynomial,
    required this.alexanderPolynomial,
    required this.crossingNumber,
    required this.density,
    required this.stability,
  });
  
  @override
  List<Object?> get props => [
    jonesPolynomial,
    alexanderPolynomial,
    crossingNumber,
    density,
    stability,
  ];
  
  /// Create a copy with updated fields
  FabricInvariants copyWith({
    Polynomial? jonesPolynomial,
    Polynomial? alexanderPolynomial,
    int? crossingNumber,
    double? density,
    double? stability,
  }) {
    return FabricInvariants(
      jonesPolynomial: jonesPolynomial ?? this.jonesPolynomial,
      alexanderPolynomial: alexanderPolynomial ?? this.alexanderPolynomial,
      crossingNumber: crossingNumber ?? this.crossingNumber,
      density: density ?? this.density,
      stability: stability ?? this.stability,
    );
  }

  /// Create from JSON
  factory FabricInvariants.fromJson(Map<String, dynamic> json) {
    return FabricInvariants(
      jonesPolynomial: Polynomial(
        List<double>.from(json['jonesPolynomial'] ?? []),
      ),
      alexanderPolynomial: Polynomial(
        List<double>.from(json['alexanderPolynomial'] ?? []),
      ),
      crossingNumber: json['crossingNumber'] ?? 0,
      density: (json['density'] ?? 0.0).toDouble(),
      stability: (json['stability'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'jonesPolynomial': jonesPolynomial.coefficients,
      'alexanderPolynomial': alexanderPolynomial.coefficients,
      'crossingNumber': crossingNumber,
      'density': density,
      'stability': stability,
    };
  }
}
