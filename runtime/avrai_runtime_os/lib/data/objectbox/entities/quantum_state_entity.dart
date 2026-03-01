import 'dart:convert';
import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for QuantumState
///
/// Stores quantum personality states with coherence metrics.
/// Supports vector storage for quantum state representation.
///
/// Phase 26: Multi-Device Storage Migration
@Entity()
class QuantumStateEntity {
  /// ObjectBox ID (auto-assigned)
  @Id()
  int id = 0;

  /// Agent/User ID (unique)
  @Unique()
  String? agentId;

  /// Quantum state type (vibe, temporal, entanglement, etc.)
  String stateType;

  /// State dimensions as JSON array of doubles
  /// Represents the quantum state vector
  String? dimensionsJson;

  /// Coherence level (0.0 to 1.0)
  double coherenceLevel;

  /// Entanglement strength with network
  double entanglementStrength;

  /// Superposition count (number of active states)
  int superpositionCount;

  /// Phase angle in radians
  double phaseAngle;

  /// Measurement count (how many times state was observed)
  int measurementCount;

  /// Last measurement timestamp
  @Property(type: PropertyType.date)
  DateTime? lastMeasurement;

  /// State metadata as JSON
  String? metadataJson;

  /// Creation timestamp
  @Property(type: PropertyType.date)
  DateTime? createdAt;

  /// Last update timestamp
  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  /// Cloud sync timestamp
  @Property(type: PropertyType.date)
  DateTime? syncedAt;

  QuantumStateEntity({
    this.id = 0,
    this.agentId,
    this.stateType = 'vibe',
    this.dimensionsJson,
    this.coherenceLevel = 1.0,
    this.entanglementStrength = 0.0,
    this.superpositionCount = 1,
    this.phaseAngle = 0.0,
    this.measurementCount = 0,
    this.lastMeasurement,
    this.metadataJson,
    this.createdAt,
    this.updatedAt,
    this.syncedAt,
  });

  /// Get dimensions as Float32List
  Float32List get dimensions {
    if (dimensionsJson == null || dimensionsJson!.isEmpty) {
      return Float32List(0);
    }
    try {
      final list = jsonDecode(dimensionsJson!) as List;
      return Float32List.fromList(
        list.map((e) => (e as num).toDouble()).toList(),
      );
    } catch (_) {
      return Float32List(0);
    }
  }

  /// Set dimensions from Float32List
  set dimensions(Float32List value) {
    dimensionsJson = jsonEncode(value.toList());
  }

  /// Get metadata as map
  Map<String, dynamic> get metadata {
    if (metadataJson == null || metadataJson!.isEmpty) return {};
    try {
      return jsonDecode(metadataJson!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Set metadata from map
  set metadata(Map<String, dynamic> value) {
    metadataJson = jsonEncode(value);
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'state_type': stateType,
        'dimensions': dimensions.toList(),
        'coherence_level': coherenceLevel,
        'entanglement_strength': entanglementStrength,
        'superposition_count': superpositionCount,
        'phase_angle': phaseAngle,
        'measurement_count': measurementCount,
        'last_measurement': lastMeasurement?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };

  /// Create from JSON
  factory QuantumStateEntity.fromJson(Map<String, dynamic> json) {
    return QuantumStateEntity(
      agentId: json['agent_id'] as String?,
      stateType: json['state_type'] as String? ?? 'vibe',
      dimensionsJson:
          json['dimensions'] != null ? jsonEncode(json['dimensions']) : null,
      coherenceLevel: (json['coherence_level'] as num?)?.toDouble() ?? 1.0,
      entanglementStrength:
          (json['entanglement_strength'] as num?)?.toDouble() ?? 0.0,
      superpositionCount: json['superposition_count'] as int? ?? 1,
      phaseAngle: (json['phase_angle'] as num?)?.toDouble() ?? 0.0,
      measurementCount: json['measurement_count'] as int? ?? 0,
      lastMeasurement: json['last_measurement'] != null
          ? DateTime.parse(json['last_measurement'] as String)
          : null,
      metadataJson:
          json['metadata'] != null ? jsonEncode(json['metadata']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }
}
