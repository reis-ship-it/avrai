import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_runtime_os/ai2ai/orchestrator_components.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_protocol_codec_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';
import 'package:reality_engine/reality_engine.dart';

import '../support/fake_kernel_governance.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

class _InMemoryGetStorage extends Mock implements GetStorage {
  _InMemoryGetStorage(this.boxName) {
    when(() => write(any(), any())).thenAnswer((invocation) async {
      _storage[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1];
    });
    when(() => remove(any())).thenAnswer((invocation) async {
      _storage.remove(invocation.positionalArguments[0] as String);
    });
    when(() => erase()).thenAnswer((_) async => _storage.clear());
    when(() => hasData(any())).thenAnswer(
      (invocation) =>
          _storage.containsKey(invocation.positionalArguments[0] as String),
    );
    when(() => getKeys()).thenReturn(<String>[]);
  }

  final String boxName;
  final Map<String, dynamic> _storage = <String, dynamic>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read &&
        invocation.positionalArguments.length == 1) {
      return _storage[invocation.positionalArguments[0] as String];
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockGetStorage {
  static final Map<String, _InMemoryGetStorage> _instances =
      <String, _InMemoryGetStorage>{};

  static GetStorage getInstance({String boxName = 'test_box'}) {
    return _instances.putIfAbsent(
      boxName,
      () => _InMemoryGetStorage(boxName),
    );
  }

  static void clear({String boxName = 'test_box'}) {
    _instances[boxName]?._storage.clear();
  }
}

class _FakeLegacyProtocolCodecAdapter implements LegacyProtocolCodecAdapter {
  _FakeLegacyProtocolCodecAdapter({
    CanonicalPeerResolutionService? peerResolutionService,
  }) : _peerResolutionService = peerResolutionService ??
            CanonicalPeerResolutionService(
              governanceKernelService: buildTestGovernanceKernelService(),
            );

  int personalityExchangeCalls = 0;
  int canonicalPeerPayloadCalls = 0;
  Ai2AiCanonicalPeerPayload? lastPeerPayload;
  Ai2AiCanonicalPeerPayload? remotePeerPayload;
  PersonalityProfile? legacyRemoteProfile;
  final CanonicalPeerResolutionService _peerResolutionService;

  @override
  MessageEncryptionService get encryptionService => throw UnimplementedError();

  @override
  Future<PersonalityProfile?> exchangePersonalityProfile({
    required String remoteDeviceId,
    required PersonalityProfile localPersonality,
  }) async {
    personalityExchangeCalls += 1;
    return legacyRemoteProfile;
  }

  @override
  Future<Ai2AiCanonicalPeerPayload?> exchangeCanonicalPeerPayload({
    required String remoteDeviceId,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  }) async {
    canonicalPeerPayloadCalls += 1;
    lastPeerPayload = localPeerPayload;
    return remotePeerPayload;
  }

  @override
  Future<ResolvedPeerVibeContext?> exchangeResolvedPeerContext({
    required String remoteDeviceId,
    required String localAgentId,
    required PersonalityProfile localPersonality,
    required Ai2AiCanonicalPeerPayload localPeerPayload,
  }) async {
    final canonicalPayload = await exchangeCanonicalPeerPayload(
      remoteDeviceId: remoteDeviceId,
      localPeerPayload: localPeerPayload,
    );
    if (canonicalPayload != null) {
      return _peerResolutionService.resolveInboundPayload(
        localAgentId: localAgentId,
        remotePayload: canonicalPayload,
      );
    }
    final legacyProfile = await exchangePersonalityProfile(
      remoteDeviceId: remoteDeviceId,
      localPersonality: localPersonality,
    );
    if (legacyProfile == null) {
      return null;
    }
    return _peerResolutionService.resolveLegacyPersonalityProfile(
      localAgentId: localAgentId,
      remoteProfile: legacyProfile,
    );
  }
}

void main() {
  setUpAll(() async {
    await StorageService.instance.initForTesting(
      defaultStorage: _MockGetStorage.getInstance(boxName: 'spots_default'),
      userStorage: _MockGetStorage.getInstance(boxName: 'spots_user'),
      aiStorage: _MockGetStorage.getInstance(boxName: 'spots_ai'),
      analyticsStorage: _MockGetStorage.getInstance(boxName: 'spots_analytics'),
    );
  });

  setUp(() {
    _MockGetStorage.clear(boxName: 'spots_default');
    _MockGetStorage.clear(boxName: 'spots_user');
    _MockGetStorage.clear(boxName: 'spots_ai');
    _MockGetStorage.clear(boxName: 'spots_analytics');
    VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
    final vibeKernel = VibeKernel();
    final trajectoryKernel = TrajectoryKernel();
    vibeKernel.importSnapshotEnvelope(
      VibeSnapshotEnvelope(exportedAtUtc: DateTime.utc(2026, 3, 12)),
    );
    trajectoryKernel.importJournalWindow(
      records: const <TrajectoryMutationRecord>[],
    );
  });

  tearDown(() {
    VibeKernelRuntimeBindings.persistenceBridge = null;
  });

  test(
      'offline peer setup exchanges governed canonical peer payloads and returns live metrics',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: _MockGetStorage.getInstance(boxName: 'spots_default'),
    );
    final vibeKernel = VibeKernel();
    vibeKernel.seedUserStateFromOnboarding(
      subjectId: 'agent-test-user',
      dimensions: const <String, double>{
        'exploration_eagerness': 0.71,
        'community_orientation': 0.64,
        'authenticity_preference': 0.66,
        'temporal_flexibility': 0.62,
        'energy_preference': 0.6,
        'novelty_seeking': 0.68,
        'value_orientation': 0.5,
        'crowd_tolerance': 0.57,
      },
      provenanceTags: const <String>['test:ai2ai_freeze'],
    );

    final adapter = _FakeLegacyProtocolCodecAdapter(
      peerResolutionService: CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      ),
    );
    adapter.remotePeerPayload = Ai2AiCanonicalPeerPayload(
      reference: Ai2AiVibeReference(
        subjectRef: VibeSubjectRef.personal('agent-remote-user'),
        scope: 'personal',
        confidence: 0.82,
        geographicBinding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality('bham-downtown'),
          stableKey: 'bham-downtown',
          higherGeographicRefs: <VibeSubjectRef>[
            VibeSubjectRef.city('bham'),
            VibeSubjectRef.region('al'),
            VibeSubjectRef.global('earth'),
          ],
          cityCode: 'bham',
          regionCode: 'al',
          globalCode: 'earth',
        ),
        scopedBindings: <ScopedVibeBinding>[
          ScopedVibeBinding(
            contextRef: VibeSubjectRef.scoped(
              scopedId: 'scene:locality-agent:bham-downtown:indie-music',
              scopedKind: ScopedAgentKind.scene,
            ),
            scopedKind: ScopedAgentKind.scene,
            anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
          ),
        ],
        snapshotUpdatedAtUtc: DateTime.now().toUtc(),
      ),
      personalSurface: const CanonicalPeerCompatibilitySurface(
        signatureHash: 'remote-signature-hash',
        archetype: 'social_connector',
        dimensionWindow: <String, double>{
          'exploration_eagerness': 0.73,
          'community_orientation': 0.68,
          'authenticity_preference': 0.66,
          'temporal_flexibility': 0.61,
          'energy_preference': 0.64,
          'novelty_seeking': 0.69,
          'value_orientation': 0.51,
          'crowd_tolerance': 0.62,
        },
        energy: 0.64,
        socialCadence: 0.72,
        directness: 0.59,
        confidence: 0.82,
      ),
      geographicBinding: GeographicVibeBinding(
        localityRef: VibeSubjectRef.locality('bham-downtown'),
        stableKey: 'bham-downtown',
        higherGeographicRefs: <VibeSubjectRef>[
          VibeSubjectRef.city('bham'),
          VibeSubjectRef.region('al'),
          VibeSubjectRef.global('earth'),
        ],
        cityCode: 'bham',
        regionCode: 'al',
        globalCode: 'earth',
      ),
      scopedBindings: <ScopedVibeBinding>[
        ScopedVibeBinding(
          contextRef: VibeSubjectRef.scoped(
            scopedId: 'scene:locality-agent:bham-downtown:indie-music',
            scopedKind: ScopedAgentKind.scene,
          ),
          scopedKind: ScopedAgentKind.scene,
          anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
        ),
      ],
      freshnessHours: 2.0,
      confidence: 0.82,
      generatedAtUtc: DateTime.now().toUtc(),
    );
    final manager = ConnectionManager(
      vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
      protocolCodecAdapter: adapter,
      canonicalPeerResolutionService: CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      ),
    );

    final result = await manager.establishOfflinePeerConnection(
      'user-test',
      PersonalityProfile.initial('agent-test-user', userId: 'user-test'),
      'remote-device-1',
    );

    expect(result, isNotNull);
    expect(adapter.canonicalPeerPayloadCalls, 1);
    expect(adapter.personalityExchangeCalls, 0);
    expect(
      adapter.lastPeerPayload,
      isNotNull,
    );
    expect(
      adapter.lastPeerPayload!.reference.subjectRef,
      equals(VibeSubjectRef.personal('agent-test-user')),
    );
    expect(adapter.lastPeerPayload!.reference.scope, equals('personal'));
    expect(
      result!.currentCompatibility,
      greaterThan(VibeConstants.minimumCompatibilityThreshold),
    );
    expect(
      result.learningOutcomes['canonical_reason_codes'],
      isA<List<dynamic>>(),
    );
    expect(result.learningOutcomes['peer_why_summary'], isA<String>());
  });

  test('legacy profile exchange degrades into canonical peer context only',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: _MockGetStorage.getInstance(boxName: 'spots_default'),
    );
    final vibeKernel = VibeKernel();
    vibeKernel.seedUserStateFromOnboarding(
      subjectId: 'agent-test-user',
      dimensions: const <String, double>{
        'exploration_eagerness': 0.7,
        'community_orientation': 0.62,
        'authenticity_preference': 0.66,
        'temporal_flexibility': 0.6,
        'energy_preference': 0.57,
        'novelty_seeking': 0.65,
      },
      provenanceTags: const <String>['test:ai2ai_freeze'],
    );

    final adapter = _FakeLegacyProtocolCodecAdapter(
      peerResolutionService: CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      ),
    )..legacyRemoteProfile = PersonalityProfile.initial(
        'agent-legacy-remote',
        userId: 'legacy-user',
      ).evolve(
        newArchetype: 'legacy_social_connector',
        newDimensions: const <String, double>{
          'exploration_eagerness': 0.71,
          'community_orientation': 0.67,
          'authenticity_preference': 0.63,
          'temporal_flexibility': 0.62,
          'energy_preference': 0.59,
          'novelty_seeking': 0.68,
        },
      );
    final manager = ConnectionManager(
      vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
      protocolCodecAdapter: adapter,
      canonicalPeerResolutionService: CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      ),
    );

    final resolved = await manager.resolveRemotePeerContextForDevice(
      localUserId: 'user-test',
      localPersonality:
          PersonalityProfile.initial('agent-test-user', userId: 'user-test'),
      remoteDeviceId: 'legacy-remote-device',
    );

    expect(resolved, isNotNull);
    expect(adapter.canonicalPeerPayloadCalls, 1);
    expect(adapter.personalityExchangeCalls, 1);
    expect(resolved!.metadata['legacy_personality_exchange'], isTrue);
  });
}
