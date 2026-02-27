import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';

class RuntimeHostContractManifest {
  final String hostId;
  final Map<RuntimeContractId, RuntimeContractVersion> contractVersions;

  const RuntimeHostContractManifest({
    required this.hostId,
    required this.contractVersions,
  });

  static RuntimeHostContractManifest currentPlatform() {
    if (kIsWeb) {
      return RuntimeHostContractManifest(
        hostId: 'web',
        contractVersions: _baselineContracts(),
      );
    }

    final hostId = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };

    return RuntimeHostContractManifest(
      hostId: hostId,
      contractVersions: _baselineContracts(),
    );
  }

  static Map<RuntimeContractId, RuntimeContractVersion> _baselineContracts() {
    return {
      for (final id in RuntimeContractId.values)
        id: const RuntimeContractVersion(1, 0, 0),
    };
  }
}
