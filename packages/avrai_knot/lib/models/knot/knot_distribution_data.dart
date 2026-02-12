// Knot Distribution Data Model
// 
// Represents aggregate knot type distributions for research
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'package:equatable/equatable.dart';

/// Aggregate knot type distribution
class KnotDistributionData extends Equatable {
  /// Location filter (if applicable)
  final String? location;
  
  /// Category filter (if applicable)
  final String? category;
  
  /// Time range start
  final DateTime? timeRangeStart;
  
  /// Time range end
  final DateTime? timeRangeEnd;
  
  /// Distribution of knot types (knot type -> count)
  final Map<String, int> knotTypeDistribution;
  
  /// Distribution of crossing numbers (crossing number -> count)
  final Map<int, int> crossingNumberDistribution;
  
  /// Distribution of writhe values (writhe -> count)
  final Map<int, int> writheDistribution;
  
  /// Total number of knots in this distribution
  final int totalKnots;
  
  /// Timestamp when distribution was calculated
  final DateTime calculatedAt;

  const KnotDistributionData({
    this.location,
    this.category,
    this.timeRangeStart,
    this.timeRangeEnd,
    required this.knotTypeDistribution,
    required this.crossingNumberDistribution,
    required this.writheDistribution,
    required this.totalKnots,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        location,
        category,
        timeRangeStart,
        timeRangeEnd,
        knotTypeDistribution,
        crossingNumberDistribution,
        writheDistribution,
        totalKnots,
        calculatedAt,
      ];
}
