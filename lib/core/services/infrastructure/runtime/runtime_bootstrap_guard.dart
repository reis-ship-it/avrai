import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_host_contract_manifest.dart';

class RuntimeBootstrapGuard {
  static RuntimeCompatibilityReport validate({
    RuntimeContractRegistry? registry,
    RuntimeHostContractManifest? hostManifest,
  }) {
    final effectiveRegistry = registry ?? buildDefaultRuntimeContractRegistry();
    final effectiveHostManifest =
        hostManifest ?? RuntimeHostContractManifest.currentPlatform();

    return effectiveRegistry.validateHostContracts(
      hostVersions: effectiveHostManifest.contractVersions,
    );
  }

  static RuntimeCompatibilityReport validateOrThrow({
    RuntimeContractRegistry? registry,
    RuntimeHostContractManifest? hostManifest,
  }) {
    final report = validate(
      registry: registry,
      hostManifest: hostManifest,
    );
    if (!report.compatible) {
      throw RuntimeContractIncompatibilityException(report.reason);
    }
    return report;
  }
}
