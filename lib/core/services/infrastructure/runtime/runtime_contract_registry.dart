/// Runtime contract IDs that all hosts/runtime adapters must implement.
enum RuntimeContractId {
  identity,
  transport,
  policy,
  scheduler,
  storage,
  telemetry,
  capabilities,
}

/// Semantic version for runtime contracts.
class RuntimeContractVersion {
  final int major;
  final int minor;
  final int patch;

  const RuntimeContractVersion(this.major, this.minor, this.patch);

  factory RuntimeContractVersion.parse(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      throw ArgumentError('Invalid runtime contract version: $value');
    }
    return RuntimeContractVersion(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class RuntimeContractSpec {
  final RuntimeContractId id;
  final RuntimeContractVersion version;
  final String description;

  const RuntimeContractSpec({
    required this.id,
    required this.version,
    required this.description,
  });
}

class RuntimeCompatibilityReport {
  final bool compatible;
  final String reason;

  const RuntimeCompatibilityReport({
    required this.compatible,
    required this.reason,
  });
}

class RuntimeContractIncompatibilityException implements Exception {
  final String reason;

  const RuntimeContractIncompatibilityException(this.reason);

  @override
  String toString() => 'RuntimeContractIncompatibilityException: $reason';
}

/// Registry and compatibility policy for runtime contracts.
///
/// Policy: host/runtime adapters must satisfy N/N-1 compatibility by default.
class RuntimeContractRegistry {
  final Map<RuntimeContractId, RuntimeContractSpec> _contracts = {};

  void register(RuntimeContractSpec spec) {
    _contracts[spec.id] = spec;
  }

  RuntimeContractSpec? get(RuntimeContractId id) => _contracts[id];

  Map<RuntimeContractId, RuntimeContractSpec> snapshot() =>
      Map<RuntimeContractId, RuntimeContractSpec>.unmodifiable(_contracts);

  RuntimeCompatibilityReport validateHostContracts({
    required Map<RuntimeContractId, RuntimeContractVersion> hostVersions,
    int allowedMajorLag = 1,
  }) {
    for (final entry in _contracts.entries) {
      final id = entry.key;
      final runtimeVersion = entry.value.version;
      final hostVersion = hostVersions[id];

      if (hostVersion == null) {
        return RuntimeCompatibilityReport(
          compatible: false,
          reason: 'Missing host contract for $id',
        );
      }

      final report = _validatePair(
        contractId: id,
        runtime: runtimeVersion,
        host: hostVersion,
        allowedMajorLag: allowedMajorLag,
      );
      if (!report.compatible) {
        return report;
      }
    }

    return const RuntimeCompatibilityReport(
      compatible: true,
      reason: 'Host contracts satisfy runtime compatibility policy.',
    );
  }

  RuntimeCompatibilityReport _validatePair({
    required RuntimeContractId contractId,
    required RuntimeContractVersion runtime,
    required RuntimeContractVersion host,
    required int allowedMajorLag,
  }) {
    final majorLag = runtime.major - host.major;
    if (majorLag < 0) {
      return RuntimeCompatibilityReport(
        compatible: false,
        reason:
            'Host contract $contractId is newer than runtime ($host > $runtime)',
      );
    }
    if (majorLag > allowedMajorLag) {
      return RuntimeCompatibilityReport(
        compatible: false,
        reason:
            'Host contract $contractId exceeds allowed N/N-1 lag ($host vs $runtime)',
      );
    }
    if (majorLag == 0 && host.minor > runtime.minor) {
      return RuntimeCompatibilityReport(
        compatible: false,
        reason:
            'Host contract $contractId minor version ahead of runtime ($host > $runtime)',
      );
    }

    return RuntimeCompatibilityReport(
      compatible: true,
      reason: '$contractId compatible ($host vs $runtime)',
    );
  }
}

/// Canonical runtime contract baseline for current architecture.
RuntimeContractRegistry buildDefaultRuntimeContractRegistry() {
  final registry = RuntimeContractRegistry();
  for (final id in RuntimeContractId.values) {
    registry.register(
      RuntimeContractSpec(
        id: id,
        version: const RuntimeContractVersion(1, 0, 0),
        description: 'Baseline runtime contract for $id',
      ),
    );
  }
  return registry;
}
