import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';

void main() {
  group('Runtime host adapter conformance', () {
    test(
        'ios/macos/android/windows/linux host adapters satisfy baseline contracts',
        () {
      final registry = buildDefaultRuntimeContractRegistry();

      Map<RuntimeContractId, RuntimeContractVersion> baseline() => {
            for (final id in RuntimeContractId.values)
              id: const RuntimeContractVersion(1, 0, 0),
          };

      final hosts = <String, Map<RuntimeContractId, RuntimeContractVersion>>{
        'ios': baseline(),
        'macos': baseline(),
        'android': baseline(),
        'windows': baseline(),
        'linux': baseline(),
      };

      for (final entry in hosts.entries) {
        final report = registry.validateHostContracts(
          hostVersions: entry.value,
        );
        expect(report.compatible, isTrue,
            reason: '${entry.key}: ${report.reason}');
      }
    });
  });
}
