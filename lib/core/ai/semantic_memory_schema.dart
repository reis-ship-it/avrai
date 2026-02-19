/// Semantic memory entry schema for compressed user knowledge.
///
/// Phase 1.1A.1 requires a schema carrying:
/// - embedding vector
/// - natural-language generalization
/// - evidence count
/// - confidence
/// - timestamp metadata
class SemanticMemoryEntry {
  final String id;
  final String agentId;
  final List<double> embedding;
  final String generalization;
  final int evidenceCount;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SemanticMemoryEntry({
    required this.id,
    required this.agentId,
    required this.embedding,
    required this.generalization,
    required this.evidenceCount,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  SemanticMemoryEntry copyWith({
    String? id,
    String? agentId,
    List<double>? embedding,
    String? generalization,
    int? evidenceCount,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SemanticMemoryEntry(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      embedding: embedding ?? this.embedding,
      generalization: generalization ?? this.generalization,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'embedding': embedding,
      'generalization': generalization,
      'evidence_count': evidenceCount,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SemanticMemoryEntry.fromJson(Map<String, dynamic> json) {
    return SemanticMemoryEntry(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      embedding: List<double>.from(
          (json['embedding'] as List).map((v) => (v as num).toDouble())),
      generalization: json['generalization'] as String,
      evidenceCount: (json['evidence_count'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Merges another observation into this semantic entry.
  ///
  /// Confidence is evidence-weighted and clamped to [0.0, 1.0].
  SemanticMemoryEntry mergeEvidence({
    required int additionalEvidence,
    required double observedConfidence,
    DateTime? mergedAt,
  }) {
    final safeAdditional = additionalEvidence < 0 ? 0 : additionalEvidence;
    final totalEvidence = evidenceCount + safeAdditional;

    final weightedConfidence = totalEvidence == 0
        ? confidence
        : ((confidence * evidenceCount) +
                (observedConfidence.clamp(0.0, 1.0) * safeAdditional)) /
            totalEvidence;

    return copyWith(
      evidenceCount: totalEvidence,
      confidence: weightedConfidence.clamp(0.0, 1.0),
      updatedAt: mergedAt ?? DateTime.now().toUtc(),
    );
  }
}
