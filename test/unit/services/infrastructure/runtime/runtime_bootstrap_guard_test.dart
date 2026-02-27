import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_bootstrap_guard.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_host_contract_manifest.dart';

void main() {
  group('RuntimeBootstrapGuard', () {
    test('validateOrThrow passes for compatible host manifest', () {
      final registry = buildDefaultRuntimeContractRegistry();
      final host = RuntimeHostContractManifest(
        hostId: 'test',
        contractVersions: {
          for (final id in RuntimeContractId.values)
            id: const RuntimeContractVersion(1, 0, 0),
        },
      );

      final report = RuntimeBootstrapGuard.validateOrThrow(
        registry: registry,
        hostManifest: host,
      );
      expect(report.compatible, isTrue);
    });

    test('validateOrThrow throws on incompatible host manifest', () {
      final registry = buildDefaultRuntimeContractRegistry();
      registry.register(
        const RuntimeContractSpec(
          id: RuntimeContractId.telemetry,
          version: RuntimeContractVersion(3, 0, 0),
          description: 'telemetry v3',
        ),
      );
      final host = RuntimeHostContractManifest(
        hostId: 'test',
        contractVersions: {
          for (final id in RuntimeContractId.values)
            id: const RuntimeContractVersion(1, 0, 0),
        },
      );

      expect(
        () => RuntimeBootstrapGuard.validateOrThrow(
          registry: registry,
          hostManifest: host,
        ),
        throwsA(isA<RuntimeContractIncompatibilityException>()),
      );
    });
  });
}
