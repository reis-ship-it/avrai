// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLegacyAi2AiExchangeTransportAdapter extends Mock
    implements LegacyAi2AiExchangeTransportAdapter {}

void main() {
  group('Ai2AiRendezvousScheduler', () {
    late _MockLegacyAi2AiExchangeTransportAdapter transportAdapter;
    late Ai2AiRendezvousStore store;
    late Ai2AiExchangeSubmissionLane submissionLane;
    late Ai2AiRendezvousScheduler scheduler;

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
      scheduler = Ai2AiRendezvousScheduler(
        store: store,
        submissionLane: submissionLane,
        releasePolicy: const Ai2AiRendezvousReleasePolicy(),
      );
    });

    test('releases wifi rendezvous once wifi becomes available', () async {
      await submissionLane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: 'wifi-exchange',
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

      expect(store.activeCount(), 1);

      final notReleased = await scheduler.releaseEligibleTickets();
      expect(notReleased, 0);
      verifyNever(
        () => transportAdapter.dispatchExchange(
          peerId: any(named: 'peerId'),
          artifactClass: any(named: 'artifactClass'),
          payload: any(named: 'payload'),
          legacyMessageTypeName: any(named: 'legacyMessageTypeName'),
        ),
      );

      await scheduler.updateRuntimeState(isWifiAvailable: true);

      expect(store.activeCount(), 0);
      final captured = verify(
        () => transportAdapter.dispatchExchange(
          peerId: 'peer-1',
          artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
          payload: captureAny(named: 'payload'),
          legacyMessageTypeName: null,
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['delta'], 1);
      expect(captured['ai2ai_exchange_id'], 'wifi-exchange');
      expect(captured['ai2ai_artifact_class'], 'dnaDelta');
      expect(captured['ai2ai_requires_apply_receipt'], isFalse);
    });

    test('keeps rendezvous deferred when trusted route is unavailable',
        () async {
      scheduler = Ai2AiRendezvousScheduler(
        store: store,
        submissionLane: submissionLane,
        releasePolicy: const Ai2AiRendezvousReleasePolicy(),
        hasTrustedRoute: (_) async => false,
      );

      await submissionLane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: 'wifi-trusted-route',
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

      await scheduler.updateRuntimeState(isWifiAvailable: true);

      expect(store.activeCount(), 1);
      expect(scheduler.lastBlockedReason, 'trusted_route_unavailable');
      expect(scheduler.trustedRouteUnavailableBlockCount, 1);
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
