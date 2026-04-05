import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_normalizer.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';

void main() {
  group('AirGapNormalizer', () {
    const normalizer = AirGapNormalizer();
    final source = ExternalSourceDescriptor(
      id: 'source-1',
      ownerUserId: 'owner-1',
      sourceProvider: 'calendar',
      sourceUrl: 'https://example.com/feed',
      createdAt: DateTime.utc(2026, 3, 31),
      updatedAt: DateTime.utc(2026, 3, 31),
    );

    test('normalizes canonical air gap compression signals from payload', () {
      const budget = CompressionBudgetProfile(
        profileId: 'runtime_air_gap_default',
        maxDistortionBudget: 0.2,
        maxProvenanceRefs: 2,
        maxSourceRefs: 2,
        maxMetadataEntries: 4,
        maxSemanticTuples: 4,
        maxEmbeddingDimensions: 8,
        embeddingPrecision: 3,
        detailBudget: DetailResolutionBudget(
          gasUnits: 1,
          liquidUnits: 2,
          solidUnits: 3,
        ),
      );
      final envelope = SafeArtifactEnvelope(
        envelopeId: 'envelope-1',
        artifactType: AirGapCompressionArtifactType.semanticTupleBundle,
        compressionMode: AirGapCompressionMode.boundedProjection,
        privacyLadderTag: 'amber',
        provenanceRefs: const <String>['tuple-1'],
        detailBudget: budget.detailBudget,
        measuredDistortion: 0.1,
        nonReconstructable: true,
        artifactHash: 'hash-1',
        compressedArtifact: const <String, dynamic>{
          'tupleCount': 1,
          'retainedTupleCount': 1,
          'tuples': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'tuple-1'},
          ],
        },
      );
      final packet = CompressedKnowledgePacket(
        packetId: 'packet-1',
        environmentId: 'event_planning__us-bhm',
        layerEnvelopes: <AirGapKnowledgeLayer, SafeArtifactEnvelope>{
          AirGapKnowledgeLayer.personal: envelope,
        },
        detailBudget: budget.detailBudget,
        provenanceRefs: const <String>['tuple-1'],
      );

      final candidate = normalizer.normalize(
        payload: <String, dynamic>{
          'title': 'Neighborhood Jam',
          'airGapCompression': <String, dynamic>{
            'primaryEnvelope': envelope.toJson(),
            'knowledgePacket': packet.toJson(),
            'budgetProfile': budget.toJson(),
            'encodedKnowledgePacket': 'encoded-packet',
          },
        },
        source: source,
      );

      expect(candidate.compressedArtifactEnvelope?.envelopeId, 'envelope-1');
      expect(candidate.compressedKnowledgePacket?.packetId, 'packet-1');
      expect(candidate.compressionBudgetProfile?.profileId,
          'runtime_air_gap_default');
      expect(candidate.rawPayload, isNot(contains('airGapCompression')));
      expect(candidate.rawPayload['air_gap_compression'],
          isA<Map<String, dynamic>>());
    });

    test('fails closed when compression payload is malformed', () {
      expect(
        () => normalizer.normalize(
          payload: <String, dynamic>{
            'title': 'Neighborhood Jam',
            'air_gap_compression': 'not-a-map',
          },
          source: source,
        ),
        throwsFormatException,
      );
    });
  });
}
