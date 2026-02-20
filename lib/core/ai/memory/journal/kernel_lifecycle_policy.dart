enum KernelFamily {
  purpose,
  safety,
  truth,
  recovery,
  learning,
  exploration,
  federation,
  resource,
  humanOverride,
}

enum LifecycleDirection {
  upgrade,
  downgrade,
}

class SignedChangeWindow {
  final DateTime startInclusive;
  final DateTime endExclusive;
  final String signerId;
  final String signatureRef;

  const SignedChangeWindow({
    required this.startInclusive,
    required this.endExclusive,
    required this.signerId,
    required this.signatureRef,
  });

  bool get isValid {
    if (signerId.trim().isEmpty) return false;
    if (signatureRef.trim().isEmpty) return false;
    return endExclusive.isAfter(startInclusive);
  }

  bool allows(DateTime now) {
    final utcNow = now.toUtc();
    return (utcNow.isAtSameMomentAs(startInclusive) ||
            utcNow.isAfter(startInclusive)) &&
        utcNow.isBefore(endExclusive);
  }
}

class KernelCompatibilityRule {
  final KernelFamily family;
  final Set<String> supportedVersions;

  const KernelCompatibilityRule({
    required this.family,
    required this.supportedVersions,
  });
}

class KernelLifecyclePolicy {
  final KernelFamily family;
  final LifecycleDirection direction;
  final String fromVersion;
  final String toVersion;
  final Duration rollbackTtl;
  final SignedChangeWindow changeWindow;
  final List<KernelCompatibilityRule> compatibilityMatrix;

  const KernelLifecyclePolicy({
    required this.family,
    required this.direction,
    required this.fromVersion,
    required this.toVersion,
    required this.rollbackTtl,
    required this.changeWindow,
    this.compatibilityMatrix = const [],
  });

  bool get isValid {
    if (fromVersion.trim().isEmpty) return false;
    if (toVersion.trim().isEmpty) return false;
    if (rollbackTtl.inSeconds < 1) return false;
    if (!changeWindow.isValid) return false;
    return true;
  }

  bool isWithinChangeWindow(DateTime now) => changeWindow.allows(now);

  bool isCompatibilitySatisfied(Map<KernelFamily, String> runtimeVersions) {
    for (final rule in compatibilityMatrix) {
      final runtimeVersion = runtimeVersions[rule.family];
      if (runtimeVersion == null) {
        return false;
      }
      if (!rule.supportedVersions.contains(runtimeVersion)) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family.name,
      'direction': direction.name,
      'from_version': fromVersion,
      'to_version': toVersion,
      'rollback_ttl_seconds': rollbackTtl.inSeconds,
      'change_window': {
        'start_inclusive':
            changeWindow.startInclusive.toUtc().toIso8601String(),
        'end_exclusive': changeWindow.endExclusive.toUtc().toIso8601String(),
        'signer_id': changeWindow.signerId,
        'signature_ref': changeWindow.signatureRef,
      },
      'compatibility_matrix': compatibilityMatrix
          .map((rule) => {
                'family': rule.family.name,
                'supported_versions':
                    rule.supportedVersions.toList(growable: false)..sort(),
              })
          .toList(growable: false),
    };
  }

  factory KernelLifecyclePolicy.fromJson(Map<String, dynamic> json) {
    T parse<T extends Enum>(List<T> values, Object? raw, String field) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('Unknown $field "$name".'),
      );
    }

    final rawWindow = Map<String, dynamic>.from(
      json['change_window'] as Map? ?? const <String, dynamic>{},
    );
    final rawMatrix = (json['compatibility_matrix'] as List? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);

    return KernelLifecyclePolicy(
      family: parse(KernelFamily.values, json['family'], 'family'),
      direction: parse(
        LifecycleDirection.values,
        json['direction'],
        'direction',
      ),
      fromVersion: json['from_version'] as String? ?? '',
      toVersion: json['to_version'] as String? ?? '',
      rollbackTtl: Duration(
        seconds: json['rollback_ttl_seconds'] as int? ?? 0,
      ),
      changeWindow: SignedChangeWindow(
        startInclusive:
            DateTime.tryParse(rawWindow['start_inclusive'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        endExclusive:
            DateTime.tryParse(rawWindow['end_exclusive'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        signerId: rawWindow['signer_id'] as String? ?? '',
        signatureRef: rawWindow['signature_ref'] as String? ?? '',
      ),
      compatibilityMatrix: rawMatrix
          .map(
            (entry) => KernelCompatibilityRule(
              family: parse(KernelFamily.values, entry['family'], 'family'),
              supportedVersions:
                  (entry['supported_versions'] as List? ?? const [])
                      .map((version) => '$version')
                      .toSet(),
            ),
          )
          .toList(growable: false),
    );
  }
}
