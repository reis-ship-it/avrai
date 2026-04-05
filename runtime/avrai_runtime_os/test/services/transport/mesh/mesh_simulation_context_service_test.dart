import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_simulation_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshSimulationContextService', () {
    test('attaches and extracts a mesh runtime state frame', () {
      final frame = MeshRuntimeStateFrame(
        capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
        routeDestinationCount: 3,
        routeEntryCount: 5,
        interfaceEnabledCounts: const <String, int>{'ble': 1},
        interfaceTotalCounts: const <String, int>{'ble': 1},
        activeAnnounceCount: 1,
        trustedActiveAnnounceCount: 1,
        expiredAnnounceCount: 0,
        rejectedAnnounceCount: 0,
        pendingCustodyCount: 2,
        dueCustodyCount: 1,
        encryptedAtRest: true,
        announceTriggeredReplayCount: 1,
        announceRefreshReplayCount: 0,
        interfaceRecoveredReplayCount: 0,
        trustedReplayTriggerCount: 1,
        trustedReplayTriggerSourceCounts: const <String, int>{
          'direct_discovery': 1,
        },
        rejectionReasonCounts: const <String, int>{},
        activeCredentialCount: 0,
        expiringSoonCredentialCount: 0,
        revokedCredentialCount: 0,
        queuedPayloadKindCounts: <String, int>{
          'organic_spot_discovery': 1,
        },
        destinations: <MeshRuntimeDestinationState>[
          MeshRuntimeDestinationState(
            destinationId: 'dest-alpha',
            knownRouteCount: 2,
            pendingCustodyCount: 1,
            bestSuccessRate: 1.0,
            totalSuccessCount: 2,
            totalFailureCount: 0,
            payloadKinds: <String>['organic_spot_discovery'],
            peerIds: <String>['peer-a'],
            activeAnnounceCount: 1,
            expiredAnnounceCount: 0,
            queuedInterfaceIds: <String>['ble'],
          ),
        ],
      );
      const runContext = MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-ctx-1',
        seed: 2023,
        divergencePolicy: 'none',
      );

      final service = const MeshSimulationContextService();
      final enriched = service.attachRuntimeStateFrame(
        runContext: runContext,
        frame: frame,
      );

      expect(
        service.extractRuntimeStateFrame(enriched)?.pendingCustodyCount,
        2,
      );
      expect(
        service.extractRuntimeStateSummary(enriched)?['encrypted_at_rest'],
        true,
      );
      expect(
        service.buildSimulationTopology(frame)['mesh_runtime_state_frame'],
        isA<Map>(),
      );
    });
  });
}
