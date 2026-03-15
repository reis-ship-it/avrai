// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLegacyAi2AiExchangeTransportAdapter extends Mock
    implements LegacyAi2AiExchangeTransportAdapter {}

void main() {
  group('Ai2AiExchangeSubmissionLane', () {
    late _MockLegacyAi2AiExchangeTransportAdapter transportAdapter;
    late Ai2AiRendezvousStore rendezvousStore;
    late DartAi2AiRuntimeKernel kernel;
    late Ai2AiExchangeSubmissionLane lane;

    setUp(() {
      transportAdapter = _MockLegacyAi2AiExchangeTransportAdapter();
      rendezvousStore = Ai2AiRendezvousStore();
      kernel = DartAi2AiRuntimeKernel(
        rendezvousStore: rendezvousStore,
      );
      lane = Ai2AiExchangeSubmissionLane(
        ai2aiKernel: kernel,
        transportAdapter: transportAdapter,
      );
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
    });

    test('dispatches immediate exchange through the private adapter', () async {
      final result = await lane.submit(
        const Ai2AiExchangeSubmissionRequest(
          exchangeId: 'exchange-now',
          conversationId: 'conversation-1',
          peerId: 'peer-1',
          artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
          payload: <String, dynamic>{'content': 'payload'},
        ),
      );

      expect(result.deferred, isFalse);
      expect(result.dispatched, isTrue);
      expect(result.commitReceipt, isNotNull);
      final captured = verify(
        () => transportAdapter.dispatchExchange(
          peerId: 'peer-1',
          artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
          payload: captureAny(named: 'payload'),
          legacyMessageTypeName: null,
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['content'], 'payload');
      expect(captured['ai2ai_exchange_id'], 'exchange-now');
      expect(captured['ai2ai_artifact_class'], 'memoryArtifact');
      expect(captured['ai2ai_requires_apply_receipt'], isFalse);
      final snapshot = kernel.snapshotExchange('exchange-now');
      expect(snapshot, isNotNull);
      expect(
        snapshot!.lifecycleState,
        isNot(Ai2AiExchangeLifecycleState.peerReceived),
      );
      expect(
        snapshot.lifecycleState,
        isNot(Ai2AiExchangeLifecycleState.peerValidated),
      );
      expect(
        snapshot.lifecycleState,
        isNot(Ai2AiExchangeLifecycleState.peerConsumed),
      );
      expect(
        snapshot.lifecycleState,
        isNot(Ai2AiExchangeLifecycleState.peerApplied),
      );
    });

    test('stores deferred exchange as a rendezvous ticket', () async {
      final result = await lane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: 'exchange-deferred',
          conversationId: 'conversation-2',
          peerId: 'peer-2',
          artifactClass: Ai2AiExchangeArtifactClass.dnaDelta,
          payload: const <String, dynamic>{'delta': 0.42},
          decision: Ai2AiExchangeDecision.exchangeWhenWifi,
          rendezvousPolicy: Ai2AiRendezvousPolicy(
            requiredConditions: const <Ai2AiRendezvousCondition>{
              Ai2AiRendezvousCondition.wifi,
            },
            expiresAtUtc: DateTime.utc(2026, 3, 13),
          ),
        ),
      );

      expect(result.deferred, isTrue);
      expect(rendezvousStore.activeCount(), 1);
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
