import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';

void main() {
  group('RuntimeContractRegistry', () {
    test('accepts exact N compatibility for all contracts', () {
      final registry = buildDefaultRuntimeContractRegistry();
      final host = {
        for (final id in RuntimeContractId.values)
          id: const RuntimeContractVersion(1, 0, 0),
      };

      final report = registry.validateHostContracts(hostVersions: host);
      expect(report.compatible, isTrue);
    });

    test('accepts N-1 major compatibility by policy', () {
      final registry = buildDefaultRuntimeContractRegistry();
      registry.register(
        const RuntimeContractSpec(
          id: RuntimeContractId.transport,
          version: RuntimeContractVersion(2, 0, 0),
          description: 'transport v2',
        ),
      );

      final host = {
        for (final id in RuntimeContractId.values)
          id: const RuntimeContractVersion(1, 0, 0),
      };

      final report = registry.validateHostContracts(hostVersions: host);
      expect(report.compatible, isTrue);
    });

    test('rejects host lag beyond N-1', () {
      final registry = buildDefaultRuntimeContractRegistry();
      registry.register(
        const RuntimeContractSpec(
          id: RuntimeContractId.scheduler,
          version: RuntimeContractVersion(3, 0, 0),
          description: 'scheduler v3',
        ),
      );

      final host = {
        for (final id in RuntimeContractId.values)
          id: const RuntimeContractVersion(1, 0, 0),
      };

      final report = registry.validateHostContracts(hostVersions: host);
      expect(report.compatible, isFalse);
      expect(report.reason, contains('N/N-1'));
    });
  });
}
