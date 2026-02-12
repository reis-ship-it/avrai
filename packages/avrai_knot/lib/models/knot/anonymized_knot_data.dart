// Anonymized Knot Data Model
// 
// Represents anonymized knot data for research streams
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Type of data stream
enum StreamType {
  realTime,      // Real-time stream of knot data
  batch,         // Batch updates
  aggregate,     // Aggregate statistics
}

/// Anonymized knot data for research
class AnonymizedKnotData extends Equatable {
  /// Stream type
  final StreamType type;
  
  /// Topological invariants only (no personal data)
  final KnotInvariants topology;
  
  /// Timestamp (anonymized to hour/day level)
  final DateTime anonymizedTimestamp;
  
  /// Optional metadata (anonymized)
  final Map<String, dynamic>? metadata;

  const AnonymizedKnotData({
    required this.type,
    required this.topology,
    required this.anonymizedTimestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [type, topology, anonymizedTimestamp, metadata];
}
