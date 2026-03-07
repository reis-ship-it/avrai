import 'dart:io';

import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
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
      expect(
        (projectResponse['payload'] as Map<String, dynamic>)['primaryLabel'],
        'Avondale',
      );
      expect(resolvePointResponse['handled'], isTrue);
      expect(
        ((resolvePointResponse['payload'] as Map<String, dynamic>)['projection']
            as Map<String, dynamic>)['primaryLabel'],
        'Avondale',
      );
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
