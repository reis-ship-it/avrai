import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';

class RuntimeAirGapCompressionBundle {
  const RuntimeAirGapCompressionBundle({
    required this.budgetProfile,
    required this.primaryEnvelope,
    required this.knowledgePacket,
    required this.encodedKnowledgePacket,
  });

  final CompressionBudgetProfile budgetProfile;
  final SafeArtifactEnvelope primaryEnvelope;
  final CompressedKnowledgePacket knowledgePacket;
  final String encodedKnowledgePacket;

  Map<String, dynamic> toStructuredSignals() {
    return <String, dynamic>{
      'budgetProfile': budgetProfile.toJson(),
      'primaryEnvelope': primaryEnvelope.toJson(),
      'knowledgePacket': knowledgePacket.toJson(),
      'encodedKnowledgePacket': encodedKnowledgePacket,
    };
  }
}

class RuntimeAirGapCompressionService {
  static const CompressionBudgetProfile _defaultBudgetProfile =
      CompressionBudgetProfile(
    profileId: 'runtime_air_gap_default',
    maxDistortionBudget: 0.5,
    maxProvenanceRefs: 3,
    maxSourceRefs: 3,
    maxMetadataEntries: 8,
    maxSemanticTuples: 8,
    maxEmbeddingDimensions: 16,
    embeddingPrecision: 3,
    detailBudget: DetailResolutionBudget(
      gasUnits: 2,
      liquidUnits: 4,
      solidUnits: 6,
    ),
    layerResolutionBudgets: <AirGapKnowledgeLayer, int>{
      AirGapKnowledgeLayer.personal: 12,
      AirGapKnowledgeLayer.locality: 10,
      AirGapKnowledgeLayer.world: 8,
      AirGapKnowledgeLayer.universal: 6,
    },
  );

  const RuntimeAirGapCompressionService({
    AirGapCompressionKernel kernel = const AirGapCompressionKernel(),
    CompressedKnowledgePacketCodec codec =
        const CompressedKnowledgePacketCodec(),
  })  : _kernel = kernel,
        _codec = codec;

  final AirGapCompressionKernel _kernel;
  final CompressedKnowledgePacketCodec _codec;

  RuntimeAirGapCompressionBundle compressSemanticTuples({
    required String contractId,
    required List<SemanticTuple> tuples,
    required String environmentId,
    required AirGapKnowledgeLayer primaryLayer,
    required String privacyLadderTag,
    List<String> provenanceRefs = const <String>[],
    TruthEvidenceEnvelope? evidenceEnvelope,
    AirGapKnowledgeLayer? evidenceLayer,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    CompressionBudgetProfile budgetProfile = _defaultBudgetProfile,
  }) {
    final primaryEnvelope = _kernel.compress(
      contract: AirGapCompressionContract.semanticTupleBundle(
        contractId: contractId,
        tuples: tuples,
        privacyLadderTag: privacyLadderTag,
        provenanceRefs: provenanceRefs,
        requiredRetainedPaths:
            tuples.isEmpty ? const <String>[] : const <String>['tuples.0.id'],
        metadata: metadata,
      ),
      budgetProfile: budgetProfile,
    );

    final layerEnvelopes = <AirGapKnowledgeLayer, SafeArtifactEnvelope>{
      primaryLayer: primaryEnvelope,
    };
    if (evidenceEnvelope != null) {
      final resolvedEvidenceLayer = evidenceLayer ?? primaryLayer;
      layerEnvelopes[resolvedEvidenceLayer] = _kernel.compress(
        contract: AirGapCompressionContract.truthEvidenceEnvelope(
          contractId: '${contractId}_evidence',
          envelope: evidenceEnvelope,
          requiredRetainedPaths: const <String>['traceId', 'scope.scopeKey'],
          metadata: metadata,
        ),
        budgetProfile: budgetProfile,
      );
    }

    final packet = CompressedKnowledgePacket(
      packetId: '${contractId}_packet',
      environmentId: environmentId,
      layerEnvelopes: layerEnvelopes,
      detailBudget: budgetProfile.detailBudget,
      provenanceRefs:
          provenanceRefs.isEmpty ? const <String>[] : provenanceRefs.toList(),
      metadata: metadata,
    );

    return RuntimeAirGapCompressionBundle(
      budgetProfile: budgetProfile,
      primaryEnvelope: primaryEnvelope,
      knowledgePacket: packet,
      encodedKnowledgePacket: _codec.encode(packet),
    );
  }

  String buildEnvironmentId({
    required String surface,
    String? cityCode,
    String? localityCode,
    String? scopeKey,
  }) {
    final segments = <String>[
      _normalizeSegment(surface),
      if (cityCode != null && cityCode.trim().isNotEmpty)
        _normalizeSegment(cityCode),
      if (localityCode != null && localityCode.trim().isNotEmpty)
        _normalizeSegment(localityCode),
      if (scopeKey != null && scopeKey.trim().isNotEmpty)
        _normalizeSegment(scopeKey),
    ];
    return segments.join('__');
  }

  AirGapKnowledgeLayer knowledgeLayerForScope(TruthScopeDescriptor scope) {
    return switch (scope.governanceStratum) {
      GovernanceStratum.personal => AirGapKnowledgeLayer.personal,
      GovernanceStratum.locality => AirGapKnowledgeLayer.locality,
      GovernanceStratum.world => AirGapKnowledgeLayer.world,
      GovernanceStratum.universal => AirGapKnowledgeLayer.universal,
    };
  }

  static String _normalizeSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'unspecified';
    }
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9:_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll('|', '_');
  }
}
