import 'package:avrai_core/contracts/air_gap_compression_contract.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_core/models/truth/truth_evidence_envelope.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_core/services/air_gap_compression_kernel.dart';
import 'package:test/test.dart';

void main() {
  const kernel = AirGapCompressionKernel();
  const codec = CompressedKnowledgePacketCodec();
  const budget = CompressionBudgetProfile(
    profileId: 'air_gap_safe_default',
    maxDistortionBudget: 0.5,
    maxProvenanceRefs: 2,
    maxSourceRefs: 2,
    maxMetadataEntries: 3,
    maxSemanticTuples: 2,
    maxEmbeddingDimensions: 4,
    embeddingPrecision: 3,
    detailBudget: DetailResolutionBudget(
      gasUnits: 1,
      liquidUnits: 2,
      solidUnits: 3,
    ),
    layerResolutionBudgets: <AirGapKnowledgeLayer, int>{
      AirGapKnowledgeLayer.personal: 6,
      AirGapKnowledgeLayer.locality: 4,
      AirGapKnowledgeLayer.world: 3,
      AirGapKnowledgeLayer.universal: 2,
    },
  );

  test('compresses semantic tuple bundles into bounded safe envelopes', () {
    final contract = AirGapCompressionContract.semanticTupleBundle(
      contractId: ' tuples-baseline ',
      privacyLadderTag: 'green',
      provenanceRefs: const <String>['tuple:1', 'tuple:2', 'tuple:3'],
      requiredRetainedPaths: const <String>['tuples.0.id'],
      metadata: const <String, dynamic>{
        'environmentId': 'city-a-2026',
        'cityPackId': 'city-pack-a',
      },
      tuples: <SemanticTuple>[
        SemanticTuple(
          id: 'tuple-1',
          category: 'routine',
          subject: 'user:self',
          predicate: 'prefers',
          object: 'third_place',
          confidence: 0.92,
          extractedAt: DateTime.utc(2026, 3, 31, 10),
        ),
        SemanticTuple(
          id: 'tuple-2',
          category: 'routine',
          subject: 'user:self',
          predicate: 'visits',
          object: 'avondale',
          confidence: 0.71,
          extractedAt: DateTime.utc(2026, 3, 31, 11),
        ),
        SemanticTuple(
          id: 'tuple-3',
          category: 'social',
          subject: 'user:self',
          predicate: 'meets',
          object: 'friends',
          confidence: 0.53,
          extractedAt: DateTime.utc(2026, 3, 31, 12),
        ),
      ],
    );

    final envelope = kernel.compress(
      contract: contract,
      budgetProfile: budget,
    );

    expect(envelope.artifactType,
        AirGapCompressionArtifactType.semanticTupleBundle);
    expect(envelope.compressionMode, AirGapCompressionMode.boundedProjection);
    expect((envelope.compressedArtifact['tuples'] as List), hasLength(2));
    expect(
      envelope.compressedArtifact['retainedTupleCount'],
      2,
    );
    expect(
      envelope.measuredDistortion,
      closeTo(1 / 3, 0.0001),
    );
    expect(envelope.nonReconstructable, isTrue);
    expect(envelope.audit['rawPayloadForbidden'], isTrue);
  });

  test('rejects higher-layer artifacts that still carry raw payload markers',
      () {
    final contract = AirGapCompressionContract.higherLayerArtifact(
      contractId: 'bad-artifact',
      privacyLadderTag: 'amber',
      approvalRef: 'approval-1',
      artifact: const <String, dynamic>{
        'artifactRef': 'higher:1',
        'rawContent': 'still toxic',
      },
    );

    expect(
      () => kernel.compress(contract: contract, budgetProfile: budget),
      throwsA(
        isA<AirGapCompressionException>().having(
          (error) => error.message,
          'message',
          contains('Raw payload markers are forbidden'),
        ),
      ),
    );
  });

  test('compresses truth evidence and preserves required retained paths', () {
    final contract = AirGapCompressionContract.truthEvidenceEnvelope(
      contractId: 'evidence-envelope',
      envelope: TruthEvidenceEnvelope(
        scope: const TruthScopeDescriptor.defaultResearch(),
        traceId: 'trace-1',
        evidenceClass: 'simulation_grade',
        privacyLadderTag: 'amber',
        sourceRefs: const <String>['src-1', 'src-2', 'src-3'],
        approvals: const <String>['approve-1', 'approve-2', 'approve-3'],
        rollbackRefs: const <String>['rollback-1', 'rollback-2', 'rollback-3'],
        metadata: const <String, dynamic>{
          'environmentId': 'city-a-2026',
          'cityPackId': 'city-pack-a',
          'structuralRef': 'struct:1',
          'localityRef': 'locality:avondale',
        },
      ),
      requiredRetainedPaths: const <String>['traceId', 'scope.scopeKey'],
    );

    final envelope = kernel.compress(
      contract: contract,
      budgetProfile: budget,
    );

    expect(envelope.artifactType,
        AirGapCompressionArtifactType.truthEvidenceEnvelope);
    expect(envelope.compressionMode, AirGapCompressionMode.referenceEnvelope);
    expect(envelope.compressedArtifact['traceId'], 'trace-1');
    expect((envelope.compressedArtifact['sourceRefs'] as List), hasLength(2));
    expect(envelope.measuredDistortion, greaterThan(0));
  });

  test('encodes and decodes compressed knowledge packets deterministically',
      () {
    final personalEnvelope = kernel.compress(
      contract: AirGapCompressionContract.safeEmbeddingVector(
        contractId: 'embedding-envelope',
        privacyLadderTag: 'green',
        embeddingKind: 'routine_state',
        provenanceRefs: const <String>['embed:1'],
        values: const <double>[0.12345, 0.67891, -0.34321, 0.99123, 0.44444],
      ),
      budgetProfile: budget,
    );
    final worldEnvelope = kernel.compress(
      contract: AirGapCompressionContract.higherLayerArtifact(
        contractId: 'world-envelope',
        privacyLadderTag: 'amber',
        approvalRef: 'approval-2',
        requiredRetainedPaths: const <String>['artifactRef'],
        artifact: const <String, dynamic>{
          'artifactRef': 'world:signal:1',
          'summary': 'Safe higher-layer summary',
          'structuralRef': 'struct:world:1',
          'cityPackId': 'city-pack-a',
        },
      ),
      budgetProfile: budget,
    );

    final packet = CompressedKnowledgePacket(
      packetId: 'packet-1',
      environmentId: 'city-a-2026',
      detailBudget: budget.detailBudget,
      provenanceRefs: const <String>['packet:source:1'],
      metadata: const <String, dynamic>{'cityPackId': 'city-pack-a'},
      layerEnvelopes: <AirGapKnowledgeLayer, SafeArtifactEnvelope>{
        AirGapKnowledgeLayer.personal: personalEnvelope,
        AirGapKnowledgeLayer.world: worldEnvelope,
      },
    );

    final encoded = codec.encode(packet);
    final decoded = codec.decode(encoded);

    expect(decoded, packet);
    expect(decoded.layerEnvelopes[AirGapKnowledgeLayer.personal]?.artifactType,
        AirGapCompressionArtifactType.safeEmbeddingVector);
    expect(decoded.environmentId, 'city-a-2026');
  });
}
