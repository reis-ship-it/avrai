// Multi-Scale Quantum State Model
// 
// Model for quantum states at different temporal and contextual scales
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'package:avrai_core/models/quantum_entity_state.dart';

/// Temporal scale for quantum states
enum TemporalScale {
  shortTerm, // Last 7 days
  longTerm, // All historical data
}

/// Contextual scale for quantum states
enum ContextualScale {
  general, // General personality (no specific context)
  work, // Work/professional context
  social, // Social/leisure context
  creative, // Creative/artistic context
  analytical, // Analytical/problem-solving context
}

/// Multi-scale quantum state
/// 
/// Represents quantum states at different temporal and contextual scales
class MultiScaleQuantumState {
  /// Entity ID
  final String entityId;
  
  /// Short-term quantum state (last 7 days)
  final QuantumEntityState? shortTerm;
  
  /// Long-term quantum state (all historical data)
  final QuantumEntityState? longTerm;
  
  /// Contextual quantum states
  final Map<ContextualScale, QuantumEntityState> contextual;
  
  /// Created timestamp
  final DateTime createdAt;
  
  MultiScaleQuantumState({
    required this.entityId,
    this.shortTerm,
    this.longTerm,
    required this.contextual,
    required this.createdAt,
  });
  
  /// Get state for specific context
  QuantumEntityState? getStateForContext(ContextualScale context) {
    return contextual[context];
  }
  
  /// Get all available scales
  List<String> get availableScales {
    final scales = <String>[];
    if (shortTerm != null) scales.add('shortTerm');
    if (longTerm != null) scales.add('longTerm');
    scales.addAll(contextual.keys.map((k) => 'contextual_${k.name}'));
    return scales;
  }
  
  /// Create from JSON
  factory MultiScaleQuantumState.fromJson(Map<String, dynamic> json) {
    final contextualMap = <ContextualScale, QuantumEntityState>{};
    final contextualJson = json['contextual'] as Map<dynamic, dynamic>? ?? {};
    
    for (final entry in contextualJson.entries) {
      final scale = ContextualScale.values.firstWhere(
        (s) => s.name == entry.key.toString(),
        orElse: () => ContextualScale.general,
      );
      contextualMap[scale] = QuantumEntityState.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }
    
    return MultiScaleQuantumState(
      entityId: json['entityId'] as String,
      shortTerm: json['shortTerm'] != null
          ? QuantumEntityState.fromJson(json['shortTerm'] as Map<String, dynamic>)
          : null,
      longTerm: json['longTerm'] != null
          ? QuantumEntityState.fromJson(json['longTerm'] as Map<String, dynamic>)
          : null,
      contextual: contextualMap,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final contextualJson = <String, dynamic>{};
    for (final entry in contextual.entries) {
      contextualJson[entry.key.name] = entry.value.toJson();
    }
    
    return {
      'entityId': entityId,
      'shortTerm': shortTerm?.toJson(),
      'longTerm': longTerm?.toJson(),
      'contextual': contextualJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Weights for combining scales
class ScaleWeights {
  /// Weight for short-term state (0.0-1.0)
  final double shortTermWeight;
  
  /// Weight for long-term state (0.0-1.0)
  final double longTermWeight;
  
  /// Weight for contextual states (0.0-1.0)
  final double contextualWeight;
  
  /// Specific contextual weights (if provided)
  final Map<ContextualScale, double>? contextualWeights;
  
  ScaleWeights({
    this.shortTermWeight = 0.3,
    this.longTermWeight = 0.5,
    this.contextualWeight = 0.2,
    this.contextualWeights,
  }) : assert(
          (shortTermWeight + longTermWeight + contextualWeight - 1.0).abs() < 0.01,
          'Weights must sum to 1.0',
        );
  
  /// Get weight for specific contextual scale
  double getContextualWeight(ContextualScale scale) {
    if (contextualWeights != null && contextualWeights!.containsKey(scale)) {
      return contextualWeights![scale]!;
    }
    // Distribute contextual weight equally among available contexts
    return contextualWeight;
  }
}
