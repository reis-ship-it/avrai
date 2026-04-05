import 'package:equatable/equatable.dart';

enum AirGapCompressionArtifactType {
  semanticTupleBundle,
  safeEmbeddingVector,
  truthEvidenceEnvelope,
  higherLayerArtifact,
}

enum AirGapCompressionMode {
  boundedProjection,
  quantizedEmbedding,
  referenceEnvelope,
  hierarchyPacket,
}

enum AirGapKnowledgeLayer {
  personal,
  locality,
  world,
  universal,
}

class DetailResolutionBudget extends Equatable {
  const DetailResolutionBudget({
    required this.gasUnits,
    required this.liquidUnits,
    required this.solidUnits,
  });

  final int gasUnits;
  final int liquidUnits;
  final int solidUnits;

  int get totalUnits => gasUnits + liquidUnits + solidUnits;

  DetailResolutionBudget normalized() {
    return DetailResolutionBudget(
      gasUnits: gasUnits < 0 ? 0 : gasUnits,
      liquidUnits: liquidUnits < 0 ? 0 : liquidUnits,
      solidUnits: solidUnits < 0 ? 0 : solidUnits,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gasUnits': gasUnits,
      'liquidUnits': liquidUnits,
      'solidUnits': solidUnits,
    };
  }

  factory DetailResolutionBudget.fromJson(Map<String, dynamic> json) {
    return DetailResolutionBudget(
      gasUnits: (json['gasUnits'] as num?)?.toInt() ?? 0,
      liquidUnits: (json['liquidUnits'] as num?)?.toInt() ?? 0,
      solidUnits: (json['solidUnits'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[gasUnits, liquidUnits, solidUnits];
}

class CompressionBudgetProfile extends Equatable {
  const CompressionBudgetProfile({
    required this.profileId,
    required this.maxDistortionBudget,
    required this.maxProvenanceRefs,
    required this.maxSourceRefs,
    required this.maxMetadataEntries,
    required this.maxSemanticTuples,
    required this.maxEmbeddingDimensions,
    required this.embeddingPrecision,
    required this.detailBudget,
    this.layerResolutionBudgets = const <AirGapKnowledgeLayer, int>{},
  });

  final String profileId;
  final double maxDistortionBudget;
  final int maxProvenanceRefs;
  final int maxSourceRefs;
  final int maxMetadataEntries;
  final int maxSemanticTuples;
  final int maxEmbeddingDimensions;
  final int embeddingPrecision;
  final DetailResolutionBudget detailBudget;
  final Map<AirGapKnowledgeLayer, int> layerResolutionBudgets;

  CompressionBudgetProfile normalized() {
    final normalizedLayerBudgets = <AirGapKnowledgeLayer, int>{
      for (final layer in AirGapKnowledgeLayer.values)
        layer: (layerResolutionBudgets[layer] ?? detailBudget.totalUnits)
            .clamp(0, 1 << 20),
    };
    return CompressionBudgetProfile(
      profileId:
          profileId.trim().isEmpty ? 'default_profile' : profileId.trim(),
      maxDistortionBudget: maxDistortionBudget.clamp(0.0, 1.0),
      maxProvenanceRefs: maxProvenanceRefs <= 0 ? 1 : maxProvenanceRefs,
      maxSourceRefs: maxSourceRefs <= 0 ? 1 : maxSourceRefs,
      maxMetadataEntries: maxMetadataEntries <= 0 ? 1 : maxMetadataEntries,
      maxSemanticTuples: maxSemanticTuples <= 0 ? 1 : maxSemanticTuples,
      maxEmbeddingDimensions:
          maxEmbeddingDimensions <= 0 ? 1 : maxEmbeddingDimensions,
      embeddingPrecision: embeddingPrecision.clamp(1, 8),
      detailBudget: detailBudget.normalized(),
      layerResolutionBudgets: normalizedLayerBudgets,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'profileId': profileId,
      'maxDistortionBudget': maxDistortionBudget,
      'maxProvenanceRefs': maxProvenanceRefs,
      'maxSourceRefs': maxSourceRefs,
      'maxMetadataEntries': maxMetadataEntries,
      'maxSemanticTuples': maxSemanticTuples,
      'maxEmbeddingDimensions': maxEmbeddingDimensions,
      'embeddingPrecision': embeddingPrecision,
      'detailBudget': detailBudget.toJson(),
      'layerResolutionBudgets': <String, int>{
        for (final entry in layerResolutionBudgets.entries)
          entry.key.name: entry.value,
      },
    };
  }

  factory CompressionBudgetProfile.fromJson(Map<String, dynamic> json) {
    final rawLayerBudgets =
        Map<String, dynamic>.from(json['layerResolutionBudgets'] as Map? ?? {});
    return CompressionBudgetProfile(
      profileId: json['profileId'] as String? ?? 'default_profile',
      maxDistortionBudget:
          (json['maxDistortionBudget'] as num?)?.toDouble() ?? 0.0,
      maxProvenanceRefs: (json['maxProvenanceRefs'] as num?)?.toInt() ?? 1,
      maxSourceRefs: (json['maxSourceRefs'] as num?)?.toInt() ?? 1,
      maxMetadataEntries: (json['maxMetadataEntries'] as num?)?.toInt() ?? 1,
      maxSemanticTuples: (json['maxSemanticTuples'] as num?)?.toInt() ?? 1,
      maxEmbeddingDimensions:
          (json['maxEmbeddingDimensions'] as num?)?.toInt() ?? 1,
      embeddingPrecision: (json['embeddingPrecision'] as num?)?.toInt() ?? 3,
      detailBudget: DetailResolutionBudget.fromJson(
        Map<String, dynamic>.from(
          json['detailBudget'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      layerResolutionBudgets: <AirGapKnowledgeLayer, int>{
        for (final entry in rawLayerBudgets.entries)
          AirGapKnowledgeLayer.values.firstWhere(
            (value) => value.name == entry.key,
            orElse: () => AirGapKnowledgeLayer.personal,
          ): (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }

  @override
  List<Object?> get props => <Object?>[
        profileId,
        maxDistortionBudget,
        maxProvenanceRefs,
        maxSourceRefs,
        maxMetadataEntries,
        maxSemanticTuples,
        maxEmbeddingDimensions,
        embeddingPrecision,
        detailBudget,
        layerResolutionBudgets,
      ];
}

class SafeArtifactEnvelope extends Equatable {
  const SafeArtifactEnvelope({
    required this.envelopeId,
    required this.artifactType,
    required this.compressionMode,
    required this.privacyLadderTag,
    required this.provenanceRefs,
    required this.detailBudget,
    required this.measuredDistortion,
    required this.nonReconstructable,
    required this.artifactHash,
    required this.compressedArtifact,
    this.audit = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  final String envelopeId;
  final AirGapCompressionArtifactType artifactType;
  final AirGapCompressionMode compressionMode;
  final String privacyLadderTag;
  final List<String> provenanceRefs;
  final DetailResolutionBudget detailBudget;
  final double measuredDistortion;
  final bool nonReconstructable;
  final String artifactHash;
  final Map<String, dynamic> compressedArtifact;
  final Map<String, dynamic> audit;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'envelopeId': envelopeId,
      'artifactType': artifactType.name,
      'compressionMode': compressionMode.name,
      'privacyLadderTag': privacyLadderTag,
      'provenanceRefs': provenanceRefs,
      'detailBudget': detailBudget.toJson(),
      'measuredDistortion': measuredDistortion,
      'nonReconstructable': nonReconstructable,
      'artifactHash': artifactHash,
      'compressedArtifact': compressedArtifact,
      'audit': audit,
      'metadata': metadata,
    };
  }

  factory SafeArtifactEnvelope.fromJson(Map<String, dynamic> json) {
    return SafeArtifactEnvelope(
      envelopeId: json['envelopeId'] as String? ?? '',
      artifactType: AirGapCompressionArtifactType.values.firstWhere(
        (value) => value.name == json['artifactType'],
        orElse: () => AirGapCompressionArtifactType.higherLayerArtifact,
      ),
      compressionMode: AirGapCompressionMode.values.firstWhere(
        (value) => value.name == json['compressionMode'],
        orElse: () => AirGapCompressionMode.boundedProjection,
      ),
      privacyLadderTag: json['privacyLadderTag'] as String? ?? 'redacted',
      provenanceRefs: (json['provenanceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      detailBudget: DetailResolutionBudget.fromJson(
        Map<String, dynamic>.from(
          json['detailBudget'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      measuredDistortion:
          (json['measuredDistortion'] as num?)?.toDouble() ?? 0.0,
      nonReconstructable: json['nonReconstructable'] as bool? ?? false,
      artifactHash: json['artifactHash'] as String? ?? '',
      compressedArtifact: Map<String, dynamic>.from(
        json['compressedArtifact'] as Map? ?? const <String, dynamic>{},
      ),
      audit: Map<String, dynamic>.from(
        json['audit'] as Map? ?? const <String, dynamic>{},
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        envelopeId,
        artifactType,
        compressionMode,
        privacyLadderTag,
        provenanceRefs,
        detailBudget,
        measuredDistortion,
        nonReconstructable,
        artifactHash,
        compressedArtifact,
        audit,
        metadata,
      ];
}

class CompressedKnowledgePacket extends Equatable {
  const CompressedKnowledgePacket({
    required this.packetId,
    required this.environmentId,
    required this.layerEnvelopes,
    required this.detailBudget,
    this.provenanceRefs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String packetId;
  final String environmentId;
  final Map<AirGapKnowledgeLayer, SafeArtifactEnvelope> layerEnvelopes;
  final DetailResolutionBudget detailBudget;
  final List<String> provenanceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'packetId': packetId,
      'environmentId': environmentId,
      'layerEnvelopes': <String, dynamic>{
        for (final entry in layerEnvelopes.entries)
          entry.key.name: entry.value.toJson(),
      },
      'detailBudget': detailBudget.toJson(),
      'provenanceRefs': provenanceRefs,
      'metadata': metadata,
    };
  }

  factory CompressedKnowledgePacket.fromJson(Map<String, dynamic> json) {
    final rawEnvelopes =
        Map<String, dynamic>.from(json['layerEnvelopes'] as Map? ?? {});
    return CompressedKnowledgePacket(
      packetId: json['packetId'] as String? ?? '',
      environmentId: json['environmentId'] as String? ?? '',
      layerEnvelopes: <AirGapKnowledgeLayer, SafeArtifactEnvelope>{
        for (final entry in rawEnvelopes.entries)
          AirGapKnowledgeLayer.values.firstWhere(
            (value) => value.name == entry.key,
            orElse: () => AirGapKnowledgeLayer.personal,
          ): SafeArtifactEnvelope.fromJson(
            Map<String, dynamic>.from(
              entry.value as Map? ?? const <String, dynamic>{},
            ),
          ),
      },
      detailBudget: DetailResolutionBudget.fromJson(
        Map<String, dynamic>.from(
          json['detailBudget'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      provenanceRefs: (json['provenanceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        packetId,
        environmentId,
        layerEnvelopes,
        detailBudget,
        provenanceRefs,
        metadata,
      ];
}
