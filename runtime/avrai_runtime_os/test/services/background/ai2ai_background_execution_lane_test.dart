// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/background/ai2ai_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLegacyAi2AiExchangeTransportAdapter extends Mock
    implements LegacyAi2AiExchangeTransportAdapter {}

void main() {
  group('Ai2AiBackgroundExecutionLane', () {
    late _MockLegacyAi2AiExchangeTransportAdapter transportAdapter;
    late Ai2AiRendezvousStore store;
    late Ai2AiExchangeSubmissionLane submissionLane;
    late Ai2AiBackgroundExecutionLane lane;

    setUp(() {
      transportAdapter = _MockLegacyAi2AiExchangeTransportAdapter();
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(Ai2AiExchangeArtifactClass.memoryArtifact);
      when(
        () => transportAdapter.dispatchExchange(
          peerId: any(named: 'peerId'),
          artifactClass: any(named: 'artifactClass'),
          payload: any(named: 'payload'),
          legacyMessageTypeName: any(named: 'legacyMessageTypeName'),
        ),
      ).thenAnswer((_) async {});
      store = Ai2AiRendezvousStore();
      submissionLane = Ai2AiExchangeSubmissionLane(
        ai2aiKernel: DartAi2AiRuntimeKernel(
          rendezvousStore: store,
        ),
        transportAdapter: transportAdapter,
      );
      lane = Ai2AiBackgroundExecutionLane(
        scheduler: Ai2AiRendezvousScheduler(
          store: store,
          submissionLane: submissionLane,
          releasePolicy: const Ai2AiRendezvousReleasePolicy(),
        ),
      );
    });

    test('releases deferred exchange when background wake satisfies policy',
        () async {
      await submissionLane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: 'wifi-release',
          conversationId: 'conversation-1',
          peerId: 'peer-1',
          artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
          payload: const <String, dynamic>{'delta': 1},
          decision: Ai2AiExchangeDecision.exchangeWhenWifi,
          rendezvousPolicy: Ai2AiRendezvousPolicy(
            requiredConditions: const <Ai2AiRendezvousCondition>{
              Ai2AiRendezvousCondition.wifi,
            },
            expiresAtUtc: DateTime.utc(2026, 12, 31),
          ),
        ),
      );

      final result = await lane.handleWake(
        reason: BackgroundWakeReason.connectivityWifi,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.connectivityWifi,
          privacyMode: 'private_mesh',
          isWifiAvailable: true,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: false,
        ),
      );

      expect(result.releasedCount, 1);
      expect(store.activeCount(), 0);
      verify(
        () => transportAdapter.dispatchExchange(
          peerId: 'peer-1',
          artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
          payload: any(named: 'payload'),
          legacyMessageTypeName: null,
        ),
      ).called(1);
    });

    test('keeps exchange deferred when trusted route is unavailable', () async {
      final trustedRouteBlockingLane = Ai2AiBackgroundExecutionLane(
        scheduler: Ai2AiRendezvousScheduler(
          store: store,
          submissionLane: submissionLane,
          releasePolicy: const Ai2AiRendezvousReleasePolicy(),
          hasTrustedRoute: (_) async => false,
        ),
      );
      await submissionLane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: 'wifi-blocked',
          conversationId: 'conversation-2',
          peerId: 'peer-2',
          artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
          payload: const <String, dynamic>{'delta': 2},
          decision: Ai2AiExchangeDecision.exchangeWhenWifi,
          rendezvousPolicy: Ai2AiRendezvousPolicy(
            requiredConditions: const <Ai2AiRendezvousCondition>{
              Ai2AiRendezvousCondition.wifi,
            },
            expiresAtUtc: DateTime.utc(2026, 12, 31),
          ),
        ),
      );

      final result = await trustedRouteBlockingLane.handleWake(
        reason: BackgroundWakeReason.connectivityWifi,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.connectivityWifi,
          privacyMode: 'private_mesh',
          isWifiAvailable: true,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: true,
        ),
      );

      expect(result.releasedCount, 0);
      expect(result.trustedRouteUnavailableBlockCount, 1);
      expect(store.activeCount(), 1);
      verifyNever(
        () => transportAdapter.dispatchExchange(
          peerId: any(named: 'peerId'),
          artifactClass: any(named: 'artifactClass'),
          payload: any(named: 'payload'),
          legacyMessageTypeName: any(named: 'legacyMessageTypeName'),
        ),
      );
    });
  });
}
