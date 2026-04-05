import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/endpoints/intake/social_media_intake_adapter.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAirGap implements AirGapContract {
  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload rawPayload) async {
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-social-1',
        category: 'social',
        subject: 'user',
        predicate: 'posts_about',
        object: 'community_music',
        confidence: 0.88,
        extractedAt: DateTime.utc(2026, 3, 31, 18),
      ),
    ];
  }
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  Map<String, dynamic>? pluginStructuredSignals;
  List<SemanticTuple> tupleIngest = const <SemanticTuple>[];

  @override
  Future<String?> currentAgentId() async => 'agent-1';

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async {
    tupleIngest = tuples;
    return null;
  }

  @override
  Future<WhatUpdateReceipt?> ingestPluginSemanticObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.58,
    String? lineageRef,
  }) async {
    pluginStructuredSignals = structuredSignals;
    return null;
  }

  @override
  Future<WhatUpdateReceipt?> ingestVisitObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.62,
    String? lineageRef,
  }) async =>
      null;

  @override
  Future<WhatUpdateReceipt?> ingestPassiveDwellObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.58,
    String? lineageRef,
  }) async =>
      null;

  @override
  Future<WhatUpdateReceipt?> ingestAmbientSocialObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async =>
      null;

  @override
  Future<WhatUpdateReceipt?> ingestEventAttendanceObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async =>
      null;

  @override
  Future<WhatUpdateReceipt?> ingestListInteractionObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.6,
    String? lineageRef,
  }) async =>
      null;
}

void main() {
  test('social intake emits air gap compression structured signals', () async {
    final ingestion = _FakeWhatRuntimeIngestionService();
    final adapter = SocialMediaIntakeAdapter(
      _FakeAirGap(),
      whatIngestion: ingestion,
    );

    await adapter.ingestSocialFeedChunk(
      'instagram',
      '{"caption":"sunset jazz at avondale"}',
    );

    expect(ingestion.tupleIngest, hasLength(1));
    final compression = ingestion.pluginStructuredSignals!['airGapCompression']
        as Map<String, dynamic>;
    final packet = compression['knowledgePacket'] as Map<String, dynamic>;
    expect(packet['environmentId'], 'social_media__instagram');
  });
}
