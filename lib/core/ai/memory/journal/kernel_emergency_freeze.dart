enum FreezeTriggerClass {
  safetyViolation,
  truthIntegrityFailure,
  runawayOptimization,
  modelDriftCritical,
  policyTamperDetected,
}

enum FreezeScope {
  singleKernel,
  family,
  global,
}

class HumanReleasePath {
  final String approverId;
  final String approverRole;
  final String releaseTicketId;
  final DateTime releaseWindowStart;
  final DateTime releaseWindowEnd;

  const HumanReleasePath({
    required this.approverId,
    required this.approverRole,
    required this.releaseTicketId,
    required this.releaseWindowStart,
    required this.releaseWindowEnd,
  });

  bool get isValid {
    if (approverId.trim().isEmpty) return false;
    if (approverRole.trim().isEmpty) return false;
    if (releaseTicketId.trim().isEmpty) return false;
    return releaseWindowEnd.isAfter(releaseWindowStart);
  }
}

class KernelEmergencyFreeze {
  final String freezeId;
  final FreezeTriggerClass triggerClass;
  final FreezeScope freezeScope;
  final String? kernelFamily;
  final String? kernelId;
  final DateTime activatedAt;
  final HumanReleasePath requiredHumanReleasePath;

  const KernelEmergencyFreeze({
    required this.freezeId,
    required this.triggerClass,
    required this.freezeScope,
    this.kernelFamily,
    this.kernelId,
    required this.activatedAt,
    required this.requiredHumanReleasePath,
  });

  bool get isValid {
    if (freezeId.trim().isEmpty) return false;
    if (!requiredHumanReleasePath.isValid) return false;
    switch (freezeScope) {
      case FreezeScope.singleKernel:
        return (kernelId?.trim().isNotEmpty ?? false);
      case FreezeScope.family:
        return (kernelFamily?.trim().isNotEmpty ?? false);
      case FreezeScope.global:
        return true;
    }
  }

  bool requiresManualRelease() => true;

  Map<String, dynamic> toJson() {
    return {
      'freeze_id': freezeId,
      'trigger_class': triggerClass.name,
      'freeze_scope': freezeScope.name,
      'kernel_family': kernelFamily,
      'kernel_id': kernelId,
      'activated_at': activatedAt.toUtc().toIso8601String(),
      'required_human_release_path': {
        'approver_id': requiredHumanReleasePath.approverId,
        'approver_role': requiredHumanReleasePath.approverRole,
        'release_ticket_id': requiredHumanReleasePath.releaseTicketId,
        'release_window_start': requiredHumanReleasePath.releaseWindowStart
            .toUtc()
            .toIso8601String(),
        'release_window_end':
            requiredHumanReleasePath.releaseWindowEnd.toUtc().toIso8601String(),
      },
    };
  }

  factory KernelEmergencyFreeze.fromJson(Map<String, dynamic> json) {
    T parse<T extends Enum>(List<T> values, Object? raw, String field) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('Unknown $field "$name".'),
      );
    }

    final release = Map<String, dynamic>.from(
      json['required_human_release_path'] as Map? ?? const <String, dynamic>{},
    );

    return KernelEmergencyFreeze(
      freezeId: json['freeze_id'] as String? ?? '',
      triggerClass: parse(
        FreezeTriggerClass.values,
        json['trigger_class'],
        'trigger_class',
      ),
      freezeScope: parse(
        FreezeScope.values,
        json['freeze_scope'],
        'freeze_scope',
      ),
      kernelFamily: json['kernel_family'] as String?,
      kernelId: json['kernel_id'] as String?,
      activatedAt: DateTime.tryParse(json['activated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      requiredHumanReleasePath: HumanReleasePath(
        approverId: release['approver_id'] as String? ?? '',
        approverRole: release['approver_role'] as String? ?? '',
        releaseTicketId: release['release_ticket_id'] as String? ?? '',
        releaseWindowStart: DateTime.tryParse(
                release['release_window_start'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        releaseWindowEnd:
            DateTime.tryParse(release['release_window_end'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );
  }
}
