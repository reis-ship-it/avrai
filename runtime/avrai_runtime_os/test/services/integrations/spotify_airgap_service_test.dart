import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/integrations/spotify_airgap_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/memory/semantic_knowledge_store.dart';

class _FakeAirGap implements AirGapContract {
  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload rawPayload) async {
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-spotify-1',
        category: 'music',
        subject: 'user',
        predicate: 'prefers',
        object: 'grunge',
        confidence: 0.95,
        extractedAt: DateTime.utc(2026, 3, 31, 18),
      ),
    ];
  }
}

class _FakeKnowledgeStore implements SemanticKnowledgeStore {
  List<SemanticTuple> saved = const <SemanticTuple>[];

  @override
  Future<void> saveTuples(List<SemanticTuple> tuples) async {
    saved = tuples;
  }

  @override
  Future<List<SemanticTuple>> getTuplesForSubject(String subject) async {
    return saved.where((tuple) => tuple.subject == subject).toList();
  }
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  Map<String, dynamic>? pluginStructuredSignals;
  List<SemanticTuple> tupleIngest = const <SemanticTuple>[];
  String? pluginAgentId;

  @override
  Future<String?> currentAgentId() async => 'agent-spotify';

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
    pluginAgentId = agentId;
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

class _FakeAgentIdService implements AgentIdService {
  @override
  Future<String> getUserAgentId(String userId) async => 'agent-for-$userId';

  @override
  Future<String> getBusinessAgentId(String businessId) async =>
      'agent-for-business-$businessId';

  @override
  Future<String> getExpertAgentId(String expertId) async =>
      'agent-for-expert-$expertId';

  @override
  void clearCache() {}

  @override
  Future<void> flushAuditLogs() async {}

  @override
  Future<void> rotateMappingEncryptionKey(
    String userId, {
    EncryptedMapping? existingEncryptedMapping,
  }) async {}
}

void main() {
  test('spotify sync emits compression signals for plugin observation',
      () async {
    final knowledgeStore = _FakeKnowledgeStore();
    final ingestion = _FakeWhatRuntimeIngestionService();
    final service = SpotifyAirgapIntegrationService(
      airGapEngine: _FakeAirGap(),
      knowledgeStore: knowledgeStore,
      whatIngestion: ingestion,
      agentIdService: _FakeAgentIdService(),
      fetchRecentListeningHistory: () async => <String, dynamic>{
        'recently_played': <Map<String, dynamic>>[
          <String, dynamic>{
            'track': 'Smells Like Teen Spirit',
            'artist': 'Nirvana',
            'played_at': DateTime.utc(2026, 3, 31, 17).toIso8601String(),
          },
        ],
      },
    );

    await service.syncRecentListeningHistory('user-1');

    expect(knowledgeStore.saved, hasLength(1));
    expect(ingestion.tupleIngest, hasLength(1));
    expect(ingestion.pluginAgentId, 'agent-for-user-1');
    final compression = ingestion.pluginStructuredSignals!['airGapCompression']
        as Map<String, dynamic>;
    final packet = compression['knowledgePacket'] as Map<String, dynamic>;
    expect(packet['environmentId'], 'spotify_recent_listening__user-1');
    expect(
      ingestion.pluginStructuredSignals!['recentTrackCount'],
      1,
    );
  });
}
