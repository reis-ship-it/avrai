/// Procedural memory schema for learned strategy rules.
///
/// Phase 1.1B.1 requires:
/// - condition (feature thresholds)
/// - action preference
/// - evidence count
/// - success rate
class ProceduralRule {
  final String id;
  final String agentId;
  final Map<String, FeatureThreshold> conditions;
  final String actionPreference;
  final int evidenceCount;
  final double successRate;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProceduralRule({
    required this.id,
    required this.agentId,
    required this.conditions,
    required this.actionPreference,
    required this.evidenceCount,
    required this.successRate,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  ProceduralRule copyWith({
    String? id,
    String? agentId,
    Map<String, FeatureThreshold>? conditions,
    String? actionPreference,
    int? evidenceCount,
    double? successRate,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProceduralRule(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      conditions: conditions ?? this.conditions,
      actionPreference: actionPreference ?? this.actionPreference,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      successRate: successRate ?? this.successRate,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final encodedConditions = <String, dynamic>{};
    for (final entry in conditions.entries) {
      encodedConditions[entry.key] = entry.value.toJson();
    }

    return {
      'id': id,
      'agent_id': agentId,
      'conditions': encodedConditions,
      'action_preference': actionPreference,
      'evidence_count': evidenceCount,
      'success_rate': successRate,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProceduralRule.fromJson(Map<String, dynamic> json) {
    final decodedConditions = <String, FeatureThreshold>{};
    final rawConditions = json['conditions'];
    if (rawConditions is Map<String, dynamic>) {
      for (final entry in rawConditions.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          decodedConditions[entry.key] = FeatureThreshold.fromJson(value);
        }
      }
    }

    return ProceduralRule(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      conditions: decodedConditions,
      actionPreference: json['action_preference'] as String,
      evidenceCount: (json['evidence_count'] as num).toInt(),
      successRate: (json['success_rate'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Merge additional evidence into an existing rule.
  ///
  /// Success rate and confidence are evidence-weighted.
  ProceduralRule mergeEvidence({
    required int additionalEvidence,
    required double observedSuccessRate,
    required double observedConfidence,
    DateTime? mergedAt,
  }) {
    final safeAdditional = additionalEvidence < 0 ? 0 : additionalEvidence;
    final newEvidenceCount = evidenceCount + safeAdditional;
    if (newEvidenceCount == 0) {
      return copyWith(updatedAt: mergedAt ?? DateTime.now().toUtc());
    }

    final weightedSuccessRate = ((successRate * evidenceCount) +
            (observedSuccessRate.clamp(0.0, 1.0) * safeAdditional)) /
        newEvidenceCount;
    final weightedConfidence = ((confidence * evidenceCount) +
            (observedConfidence.clamp(0.0, 1.0) * safeAdditional)) /
        newEvidenceCount;

    return copyWith(
      evidenceCount: newEvidenceCount,
      successRate: weightedSuccessRate.clamp(0.0, 1.0),
      confidence: weightedConfidence.clamp(0.0, 1.0),
      updatedAt: mergedAt ?? DateTime.now().toUtc(),
    );
  }
}

class FeatureThreshold {
  final double? minInclusive;
  final double? maxInclusive;

  const FeatureThreshold({
    this.minInclusive,
    this.maxInclusive,
  });

  Map<String, dynamic> toJson() {
    return {
      'min_inclusive': minInclusive,
      'max_inclusive': maxInclusive,
    };
  }

  factory FeatureThreshold.fromJson(Map<String, dynamic> json) {
    return FeatureThreshold(
      minInclusive: (json['min_inclusive'] as num?)?.toDouble(),
      maxInclusive: (json['max_inclusive'] as num?)?.toDouble(),
    );
  }

  bool matches(double value) {
    final aboveMin = minInclusive == null || value >= minInclusive!;
    final belowMax = maxInclusive == null || value <= maxInclusive!;
    return aboveMin && belowMax;
  }
}
