import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart'
    as governance_inspection;
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/services/admin/reality_model_checkin_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/temporal/runtime_temporal_context_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('RealityModelCheckInService', () {
    late SharedPreferencesCompat prefs;
    late UrkGovernedRuntimeRegistryService registry;
    late RealityModelCheckInService service;
    late RuntimeTemporalContextService temporalContextService;
    late LanguagePatternLearningService languageLearningService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        },
      );
      await GetStorage.init('language_patterns');
    });

    setUp(() async {
      await cleanupTestStorage();
      await GetStorage('language_patterns').erase();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (GetIt.instance.isRegistered<AdminAuthService>()) {
        await GetIt.instance.unregister<AdminAuthService>();
      }
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'reality_model_checkin_runtime_registry_test',
        ),
      );
      registry = UrkGovernedRuntimeRegistryService(prefs: prefs);
      temporalContextService = RuntimeTemporalContextService(
        temporalKernelAdminService: _StubTemporalKernelAdminService(),
      );
      languageLearningService = LanguagePatternLearningService(
        agentIdService: _StubAgentIdService(),
      );
      service = RealityModelCheckInService(
        governedRuntimeRegistryService: registry,
        runtimeTemporalContextService: temporalContextService,
        languageLearningService: languageLearningService,
      );
    });

    test('registers world runtime bindings when world check-ins run', () async {
      final response = await service.checkIn(
        layer: 'world',
        prompt: 'Status?',
        context: const <String, dynamic>{'surface': 'test'},
        approvedGroupings: const <String>[],
      );

      expect(response, isNotEmpty);
      final bindings = await registry.listBindings(
        limit: 20,
        stratum: governance_inspection.GovernanceStratum.world,
      );
      expect(
        bindings.map((binding) => binding.runtimeId).toSet(),
        UrkGovernedRuntimeRegistryService.canonicalTopLayerRuntimeIds(
          stratum: governance_inspection.GovernanceStratum.world,
          layer: 'world',
        ).toSet(),
      );
      expect(
        bindings.every(
          (binding) => binding.source == 'reality_model_checkin_runtime',
        ),
        isTrue,
      );
    });

    test(
        'registers universal runtime bindings when universe grouping proposals run',
        () async {
      final proposals = await service.proposeGroupings(
        layer: 'universe',
        observedTypes: const <String>['community', 'event'],
        approvedGroupings: const <String>[],
      );

      expect(proposals, isNotEmpty);
      final bindings = await registry.listBindings(
        limit: 20,
        stratum: governance_inspection.GovernanceStratum.universal,
      );
      expect(
        bindings.map((binding) => binding.runtimeId).toSet(),
        UrkGovernedRuntimeRegistryService.canonicalTopLayerRuntimeIds(
          stratum: governance_inspection.GovernanceStratum.universal,
          layer: 'universe',
        ).toSet(),
      );
    });

    test('fallback check-in includes temporal context summary', () async {
      final response = await service.checkIn(
        layer: 'reality',
        prompt: 'What changed?',
        context: const <String, dynamic>{'surface': 'test'},
        approvedGroupings: const <String>[],
      );

      expect(response, contains('Recent runtime lineage shows'));
      expect(response, contains('top peer is peer-sequencer'));
    });

    test('stores sanitized governance learning profile from admin prompt',
        () async {
      await service.checkIn(
        layer: 'reality',
        prompt: 'Group low-coherence anomalies under transport drift.',
        context: const <String, dynamic>{
          'surface': 'oversight',
          'operatorId': 'test-admin-1',
        },
        approvedGroupings: const <String>[],
      );

      final profile = await languageLearningService.getLanguageProfileByRef(
        'governance_operator_test_admin_1',
      );

      expect(profile, isNotNull);
      expect(profile!.messageCount, 1);
      expect(profile.vocabulary.keys, contains('coherence'));
      expect(profile.metadata['learningScope'], 'governance');
      expect(profile.metadata['lastSurface'], 'admin_reality_system_check_in');
    });

    test('stores governance feedback learning from approved rewrite', () async {
      await service.recordCheckInFeedback(
        layer: 'reality',
        prompt: 'What changed?',
        modelResponse: 'Transport drift needs attention next.',
        approvedResponse:
            'Call out transport drift first and keep the summary shorter.',
        outcome: CheckInFeedbackOutcome.rewritten,
        context: const <String, dynamic>{
          'surface': 'oversight',
          'operatorId': 'test-admin-feedback',
        },
      );

      final profile = await languageLearningService.getLanguageProfileByRef(
        'governance_operator_test_admin_feedback',
      );

      expect(profile, isNotNull);
      expect(profile!.messageCount, 1);
      expect(profile.vocabulary.keys, contains('transport'));
      expect(
        profile.metadata['learningScope'],
        'governance_feedback_rewrite',
      );
      expect(
        profile.metadata['lastSurface'],
        'admin_reality_system_check_in_feedback',
      );
    });

    test('falls back to signed-in admin session identity for learning profile',
        () async {
      final adminAuthService = AdminAuthService(prefs);
      final session = AdminSession(
        username: 'session.operator',
        loginTime: DateTime.utc(2026, 3, 12, 9),
        expiresAt: DateTime.utc(2026, 3, 12, 17),
        accessLevel: AdminAccessLevel.godMode,
        permissions: AdminPermissions.all(),
      );
      await prefs.setString('admin_session', jsonEncode(session.toJson()));
      GetIt.instance.registerSingleton<AdminAuthService>(adminAuthService);

      await service.checkIn(
        layer: 'reality',
        prompt: 'Summarize transport drift first.',
        context: const <String, dynamic>{'surface': 'oversight'},
        approvedGroupings: const <String>[],
      );

      final profile = await languageLearningService.getLanguageProfileByRef(
        'governance_operator_admin_session_operator',
      );

      expect(profile, isNotNull);
      expect(profile!.messageCount, 1);
    });
  });
}

class _StubTemporalKernelAdminService extends TemporalKernelAdminService {
  _StubTemporalKernelAdminService()
      : super(temporalKernel: _UnsupportedTemporalKernel());

  @override
  Future<TemporalRuntimeEventSnapshot> getRuntimeEventSnapshot({
    String source = 'ai2ai_protocol',
    String? peerId,
    Duration lookbackWindow = const Duration(minutes: 15),
    int limit = 200,
  }) async {
    return TemporalRuntimeEventSnapshot(
      generatedAt: DateTime.utc(2026, 3, 6, 12),
      windowStart: DateTime.utc(2026, 3, 6, 11, 45),
      windowEnd: DateTime.utc(2026, 3, 6, 12),
      totalEvents: 4,
      encodedCount: 1,
      decodedCount: 1,
      bufferedCount: 1,
      orderedCount: 2,
      uniquePeerCount: 2,
      latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
      recentEvents: const [],
      topPeers: [
        TemporalRuntimeEventPeerSummary(
          peerId: 'peer-sequencer',
          eventCount: 3,
          orderedCount: 2,
          bufferedCount: 1,
          latestOccurredAt: DateTime.utc(2026, 3, 6, 11, 59),
        ),
      ],
    );
  }
}

class _UnsupportedTemporalKernel implements TemporalKernel {
  @override
  Future<TemporalOrderingResult> compare(
    TemporalSnapshot left,
    TemporalSnapshot right,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TemporalFreshnessResult> freshnessOf(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ForecastTemporalClaimLookup?> getForecast(String claimId) {
    throw UnimplementedError();
  }

  @override
  Future<HistoricalTemporalEvidenceLookup?> getHistoricalEvidence(
    String evidenceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RuntimeTemporalEventLookup?> getRuntimeEvent(String eventId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isExpired(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TemporalInstant> nowCivil() {
    throw UnimplementedError();
  }

  @override
  Future<TemporalInstant> nowMonotonic() {
    throw UnimplementedError();
  }

  @override
  Future<List<RuntimeTemporalEventLookup>> queryRuntimeEvents(
    RuntimeTemporalEventQuery query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ForecastTemporalClaimReceipt> recordForecast(
    ForecastTemporalClaim claim,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HistoricalTemporalEvidenceReceipt> recordHistoricalEvidence(
    HistoricalTemporalEvidence evidence,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RuntimeTemporalEventReceipt> recordRuntimeEvent(
    RuntimeTemporalEvent event,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TemporalSnapshot> snapshot(TemporalSnapshotRequest request) {
    throw UnimplementedError();
  }
}

class _StubAgentIdService extends AgentIdService {
  _StubAgentIdService();

  @override
  Future<String> getUserAgentId(String userId) async => 'agt_stub_$userId';
}
