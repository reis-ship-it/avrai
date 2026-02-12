import 'dart:convert';
import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for RAG embeddings
///
/// Stores vector embeddings for semantic search with HNSW index.
/// Supports 384-dimensional vectors (standard sentence-transformer size).
///
/// Phase 26: Multi-Device Storage Migration
@Entity()
class RAGEmbeddingEntity {
  /// ObjectBox ID (auto-assigned)
  @Id()
  int id = 0;

  /// Agent/User ID
  @Index()
  String? agentId;

  /// Embedding type (personality, facts, preferences, interaction)
  @Index()
  String embeddingType;

  /// Source identifier (e.g., message ID, fact ID)
  String? sourceId;

  /// The vector embedding (384 dimensions for sentence-transformers)
  /// Note: HNSW index annotation requires ObjectBox 4.0+
  /// @HnswIndex(dimensions: 384)
  @Property(type: PropertyType.floatVector)
  Float32List? embedding;

  /// Original text that was embedded (for debugging/display)
  String? sourceText;

  /// Structured facts as JSON (for StructuredFacts entities)
  String? factsJson;

  /// Embedding model used
  String? modelName;

  /// Embedding version for cache invalidation
  int embeddingVersion;

  /// Creation timestamp
  @Property(type: PropertyType.date)
  DateTime? createdAt;

  /// Last update timestamp
  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  /// Expiration timestamp (for cache cleanup)
  @Property(type: PropertyType.date)
  DateTime? expiresAt;

  RAGEmbeddingEntity({
    this.id = 0,
    this.agentId,
    this.embeddingType = 'facts',
    this.sourceId,
    this.embedding,
    this.sourceText,
    this.factsJson,
    this.modelName,
    this.embeddingVersion = 1,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  /// Get structured facts from JSON
  Map<String, dynamic>? get facts {
    if (factsJson == null || factsJson!.isEmpty) return null;
    try {
      return jsonDecode(factsJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Set structured facts
  set facts(Map<String, dynamic>? value) {
    factsJson = value != null ? jsonEncode(value) : null;
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'embedding_type': embeddingType,
        'source_id': sourceId,
        'embedding': embedding?.toList(),
        'source_text': sourceText,
        'facts': facts,
        'model_name': modelName,
        'embedding_version': embeddingVersion,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

  /// Create from JSON
  factory RAGEmbeddingEntity.fromJson(Map<String, dynamic> json) {
    Float32List? embeddingList;
    if (json['embedding'] != null) {
      final list = json['embedding'] as List;
      embeddingList = Float32List.fromList(
        list.map((e) => (e as num).toDouble()).toList(),
      );
    }

    return RAGEmbeddingEntity(
      agentId: json['agent_id'] as String?,
      embeddingType: json['embedding_type'] as String? ?? 'facts',
      sourceId: json['source_id'] as String?,
      embedding: embeddingList,
      sourceText: json['source_text'] as String?,
      factsJson: json['facts'] != null ? jsonEncode(json['facts']) : null,
      modelName: json['model_name'] as String?,
      embeddingVersion: json['embedding_version'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Create from StructuredFacts
  factory RAGEmbeddingEntity.fromStructuredFacts({
    required String agentId,
    required Map<String, dynamic> facts,
    Float32List? embedding,
    String? modelName,
  }) {
    return RAGEmbeddingEntity(
      agentId: agentId,
      embeddingType: 'facts',
      factsJson: jsonEncode(facts),
      embedding: embedding,
      modelName: modelName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
