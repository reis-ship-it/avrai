import 'dart:io';

import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeBridgeBindings', () {
    test('invokes the built locality dylib when available', () {
      if (!_hasBuiltLocalityLibrary()) {
        return;
      }

      final bridge = LocalityNativeBridgeBindings(
        libraryManager: LocalityLibraryManager(),
      );
      final persistedStateFile = File(
        '${Directory.systemTemp.path}/avrai_locality_kernel_state_v1.json',
      );
      if (persistedStateFile.existsSync()) {
        persistedStateFile.deleteSync();
      }

      bridge.initialize();

      expect(bridge.isAvailable, isTrue);

      final projectResponse = bridge.invoke(
        syscall: 'project_locality',
        payload: LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          includePrediction: true,
          state: LocalityState(
            activeToken: const LocalityToken(
              kind: LocalityTokenKind.geohashCell,
              id: 'gh7:avondale_3352_8677',
              alias: 'Avondale',
            ),
            embedding: const <double>[
              0.8,
              0.74,
              0.9,
              0.58,
              0.61,
              0.73,
              0.44,
              0.39,
              0.53,
              0.57,
              0.46,
              0.51,
            ],
            confidence: 0.82,
            boundaryTension: 0.28,
            reliabilityTier: LocalityReliabilityTier.established,
            freshness: DateTime.utc(2026, 3, 6),
            evidenceCount: 11,
            evolutionRate: 0.04,
            advisoryStatus: LocalityAdvisoryStatus.inactive,
            sourceMix: const LocalitySourceMix(
              local: 0.38,
              mesh: 0.12,
              federated: 0.34,
              geometry: 0.16,
              syntheticPrior: 0.0,
            ),
            topAlias: 'Avondale',
          ),
        ).toJson(),
      );

      final resolvePointResponse = bridge.invoke(
        syscall: 'resolve_point_locality',
        payload: LocalityPointQuery(
          latitude: 33.5247,
          longitude: -86.7740,
          occurredAtUtc: DateTime.utc(2026, 3, 6),
          audience: LocalityProjectionAudience.admin,
          includePrediction: true,
        ).toJson(),
      );

      expect(projectResponse['handled'], isTrue);
      final projectionPayload =
          projectResponse['payload'] as Map<String, dynamic>;
      final projectionMetadata =
          projectionPayload['metadata'] as Map<String, dynamic>;
      expect(projectionPayload['primaryLabel'], 'Avondale');
      expect(projectionMetadata['dominantSource'], 'local');
      expect(projectionMetadata['sourceMixSummary'], 'localLed');
      expect(projectionMetadata['stabilityClass'], 'stable');
      expect(projectionMetadata['nextStateRisk'], 'low');
      expect(projectionMetadata['promotionReadiness'], 'established');
      expect(projectionMetadata['predictiveTrend'], 'stable');
      expect(
          projectionMetadata['explanatoryFactors'], contains('highConfidence'));
      expect(resolvePointResponse['handled'], isTrue);
      expect(
        ((resolvePointResponse['payload'] as Map<String, dynamic>)['projection']
            as Map<String, dynamic>)['primaryLabel'],
        'Avondale',
      );

      final resolvedState = bridge.invoke(
        syscall: 'resolve_where',
        payload: LocalityPerceptionInput(
          agentId: 'agent-1',
          latitude: 33.5247,
          longitude: -86.7740,
          occurredAtUtc: DateTime.utc(2026, 3, 6),
          topAlias: 'Avondale',
        ).toJson(),
      );
      expect(resolvedState['handled'], isTrue);

      final syncResponse = bridge.invoke(
        syscall: 'sync_locality',
        payload: {
          'agentId': 'agent-1',
          'allowCloud': true,
          'allowMesh': true,
          'syncedAtUtc': DateTime.utc(2026, 3, 6, 12).toIso8601String(),
          'snapshot': {
            'agentId': 'agent-1',
            'state': resolvedState['payload'],
            'savedAtUtc': DateTime.utc(2026, 3, 6).toIso8601String(),
          },
          'globalState': LocalityAgentGlobalStateV1(
            key: const LocalityAgentKeyV1(
              geohashPrefix: 'dr5ru7k',
              precision: 7,
              cityCode: 'birmingham_alabama',
            ),
            vector12: const <double>[
              0.91,
              0.88,
              0.84,
              0.79,
              0.76,
              0.73,
              0.66,
              0.61,
              0.58,
              0.56,
              0.52,
              0.49,
            ],
            sampleCount: 12,
            updatedAtUtc: DateTime.utc(2026, 3, 6),
          ).toJson(),
          'neighborMeshUpdates': const <List<double>>[
            <double>[
              0.2,
              0.1,
              0.0,
              0.1,
              0.2,
              0.0,
              0.0,
              0.1,
              0.0,
              0.1,
              0.0,
              0.0
            ],
            <double>[
              0.1,
              0.0,
              0.1,
              0.0,
              0.2,
              0.1,
              0.0,
              0.0,
              0.1,
              0.0,
              0.1,
              0.0
            ],
          ],
        },
      );
      expect(syncResponse['handled'], isTrue);
      expect(
        (syncResponse['payload'] as Map<String, dynamic>)['synced'],
        isTrue,
      );
      expect(persistedStateFile.existsSync(), isTrue);

      final recovered = bridge.invoke(
        syscall: 'recover_locality',
        payload: const <String, dynamic>{'agentId': 'agent-1'},
      );
      expect(recovered['handled'], isTrue);
      expect(
        ((recovered['payload'] as Map<String, dynamic>)['state']
            as Map<String, dynamic>)['confidence'],
        greaterThan(0.5),
      );

      Map<String, dynamic>? lastObservationPayload;
      for (var i = 0; i < 8; i += 1) {
        final observation = bridge.invoke(
          syscall: 'observe_locality',
          payload: LocalityObservation(
            userId: 'user-1',
            agentId: 'agent-1',
            type: LocalityObservationType.visitComplete,
            key: const LocalityAgentKeyV1(
              geohashPrefix: 'dr5ru7k',
              precision: 7,
              cityCode: 'birmingham_alabama',
            ),
            occurredAtUtc: DateTime.utc(2026, 3, 6, 12, i),
            source: 'test',
            reportedCityCode: 'birmingham_alabama',
            topAlias: 'Avondale',
          ).toJson(),
        );
        lastObservationPayload = observation['payload'] as Map<String, dynamic>;
      }

      expect(lastObservationPayload, isNotNull);
      expect(
        ((lastObservationPayload!['state']
            as Map<String, dynamic>)['reliabilityTier']),
        'established',
      );
      expect(
        ((lastObservationPayload['state']
            as Map<String, dynamic>)['evidenceCount']),
        greaterThanOrEqualTo(8),
      );

      final advisoryObservation = bridge.invoke(
        syscall: 'observe_locality',
        payload: LocalityObservation(
          userId: 'user-1',
          agentId: 'agent-1',
          type: LocalityObservationType.happinessSignal,
          key: const LocalityAgentKeyV1(
            geohashPrefix: 'dr5ru7k',
            precision: 7,
            cityCode: 'birmingham_alabama',
          ),
          occurredAtUtc: DateTime.utc(2026, 3, 6, 13),
          source: 'test',
          qualityScore: 0.32,
          reportedCityCode: 'birmingham_alabama',
          topAlias: 'Avondale',
        ).toJson(),
      );
      final advisoryState = (advisoryObservation['payload']
          as Map<String, dynamic>)['state'] as Map<String, dynamic>;
      expect(advisoryState['reliabilityTier'], 'advisory');
      expect(advisoryState['advisoryStatus'], 'active');
    });
  });
}

bool _hasBuiltLocalityLibrary() {
  if (Platform.isMacOS) {
    return File(
      '${Directory.current.path}/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.dylib',
    ).existsSync();
  }
  if (Platform.isLinux) {
    return File(
      '${Directory.current.path}/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.so',
    ).existsSync();
  }
  return false;
}
