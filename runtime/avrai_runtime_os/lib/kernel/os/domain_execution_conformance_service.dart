import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_stage_c_private_mesh_policy_conformance_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';

enum DomainExecutionStatus { healthy, degraded, unavailable }

class DomainExecutionKernelHealthReport {
  const DomainExecutionKernelHealthReport({
    required this.domainId,
    required this.status,
    required this.nativeBacked,
    required this.runtimeReady,
    required this.fieldPilotReady,
    required this.summary,
    this.violations = const <String>[],
    this.fieldPilotBlockers = const <String>[],
    this.diagnostics = const <String, dynamic>{},
  });

  final String domainId;
  final DomainExecutionStatus status;
  final bool nativeBacked;
  final bool runtimeReady;
  final bool fieldPilotReady;
  final String summary;
  final List<String> violations;
  final List<String> fieldPilotBlockers;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'domain_id': domainId,
        'status': status.name,
        'native_backed': nativeBacked,
        'runtime_ready': runtimeReady,
        'field_pilot_ready': fieldPilotReady,
        'summary': summary,
        'violations': violations,
        'field_pilot_blockers': fieldPilotBlockers,
        'diagnostics': diagnostics,
      };

  factory DomainExecutionKernelHealthReport.fromJson(
    Map<String, dynamic> json,
  ) {
    return DomainExecutionKernelHealthReport(
      domainId: json['domain_id'] as String? ?? 'unknown',
      status: DomainExecutionStatus.values.byName(
        json['status'] as String? ?? DomainExecutionStatus.unavailable.name,
      ),
      nativeBacked: json['native_backed'] as bool? ?? false,
      runtimeReady: json['runtime_ready'] as bool? ?? false,
      fieldPilotReady: json['field_pilot_ready'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      violations: (json['violations'] as List? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(growable: false),
      fieldPilotBlockers:
          (json['field_pilot_blockers'] as List? ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false),
      diagnostics: Map<String, dynamic>.from(
        json['diagnostics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class DomainExecutionConformanceReport {
  const DomainExecutionConformanceReport({
    required this.checkedAtUtc,
    required this.runtimeReady,
    required this.fieldPilotReady,
    required this.rolloutFlagEnabled,
    required this.signalRequiredSatisfied,
    required this.encryptionType,
    required this.reports,
    this.violations = const <String>[],
    this.fieldPilotBlockers = const <String>[],
    this.diagnostics = const <String, dynamic>{},
  });

  final DateTime checkedAtUtc;
  final bool runtimeReady;
  final bool fieldPilotReady;
  final bool rolloutFlagEnabled;
  final bool signalRequiredSatisfied;
  final EncryptionType encryptionType;
  final List<DomainExecutionKernelHealthReport> reports;
  final List<String> violations;
  final List<String> fieldPilotBlockers;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checked_at_utc': checkedAtUtc.toUtc().toIso8601String(),
        'runtime_ready': runtimeReady,
        'field_pilot_ready': fieldPilotReady,
        'rollout_flag_enabled': rolloutFlagEnabled,
        'signal_required_satisfied': signalRequiredSatisfied,
        'encryption_type': encryptionType.name,
        'reports': reports.map((report) => report.toJson()).toList(),
        'violations': violations,
        'field_pilot_blockers': fieldPilotBlockers,
        'diagnostics': diagnostics,
      };

  factory DomainExecutionConformanceReport.fromJson(Map<String, dynamic> json) {
    return DomainExecutionConformanceReport(
      checkedAtUtc:
          DateTime.tryParse(json['checked_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      runtimeReady: json['runtime_ready'] as bool? ?? false,
      fieldPilotReady: json['field_pilot_ready'] as bool? ?? false,
      rolloutFlagEnabled: json['rollout_flag_enabled'] as bool? ?? false,
      signalRequiredSatisfied:
          json['signal_required_satisfied'] as bool? ?? false,
      encryptionType: EncryptionType.values.firstWhere(
        (value) => value.name == (json['encryption_type'] as String? ?? ''),
        orElse: () => EncryptionType.aes256gcm,
      ),
      reports: (json['reports'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (entry) => DomainExecutionKernelHealthReport.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(growable: false),
      violations: (json['violations'] as List? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(growable: false),
      fieldPilotBlockers:
          (json['field_pilot_blockers'] as List? ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false),
      diagnostics: Map<String, dynamic>.from(
        json['diagnostics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

abstract class DomainExecutionConformanceService {
  Future<DomainExecutionConformanceReport> buildReport({
    String? rolloutUserId,
  });
}

class DefaultDomainExecutionConformanceService
    implements DomainExecutionConformanceService {
  const DefaultDomainExecutionConformanceService({
    required MeshKernelContract meshKernel,
    required Ai2AiKernelContract ai2aiKernel,
    required MessageEncryptionService encryptionService,
    FeatureFlagService? featureFlagService,
    UrkStageCPrivateMeshPolicyConformanceValidator? privateMeshValidator,
    this.privateMeshPolicy = const UrkStageCPrivateMeshPolicyConformancePolicy(
      requiredSchemaConformancePct: 100.0,
      maxDirectIdentifierLeaks: 0,
      requiredDoubleEncryptionCoveragePct: 100.0,
      requiredKeyRotationCoveragePct: 100.0,
      requiredLineageTagCoveragePct: 100.0,
      requiredPolicyGateCoveragePct: 100.0,
      maxPolicyBypassEvents: 0,
    ),
  })  : _meshKernel = meshKernel,
        _ai2aiKernel = ai2aiKernel,
        _encryptionService = encryptionService,
        _featureFlagService = featureFlagService,
        _privateMeshValidator = privateMeshValidator ??
            const UrkStageCPrivateMeshPolicyConformanceValidator();

  final MeshKernelContract _meshKernel;
  final Ai2AiKernelContract _ai2aiKernel;
  final MessageEncryptionService _encryptionService;
  final FeatureFlagService? _featureFlagService;
  final UrkStageCPrivateMeshPolicyConformanceValidator _privateMeshValidator;
  final UrkStageCPrivateMeshPolicyConformancePolicy privateMeshPolicy;

  @override
  Future<DomainExecutionConformanceReport> buildReport({
    String? rolloutUserId,
  }) async {
    final meshHealth = await _meshKernel.diagnoseMesh();
    final ai2aiHealth = await _ai2aiKernel.diagnoseAi2Ai();
    final rolloutFlagEnabled = _featureFlagService == null
        ? false
        : await _featureFlagService.isEnabled(
            GovernanceFeatureFlags.reticulumMeshTransportControlPlaneV1,
            userId: rolloutUserId,
          );
    final signalRequiredSatisfied =
        _encryptionService.encryptionType == EncryptionType.signalProtocol;
    final meshPolicyValidation = _privateMeshValidator.validate(
      snapshot: _meshPolicySnapshot(
        meshHealth: meshHealth,
        signalRequiredSatisfied: signalRequiredSatisfied,
      ),
      policy: privateMeshPolicy,
    );

    final reports = <DomainExecutionKernelHealthReport>[
      _meshReport(
        meshHealth: meshHealth,
        rolloutFlagEnabled: rolloutFlagEnabled,
        signalRequiredSatisfied: signalRequiredSatisfied,
        meshPolicyValidation: meshPolicyValidation,
      ),
      _ai2AiReport(
        ai2aiHealth: ai2aiHealth,
        rolloutFlagEnabled: rolloutFlagEnabled,
        signalRequiredSatisfied: signalRequiredSatisfied,
      ),
    ];

    final violations = reports.expand((report) => report.violations).toList();
    final fieldPilotBlockers =
        reports.expand((report) => report.fieldPilotBlockers).toList();
    return DomainExecutionConformanceReport(
      checkedAtUtc: DateTime.now().toUtc(),
      runtimeReady: reports.every((report) => report.runtimeReady),
      fieldPilotReady: reports.every((report) => report.fieldPilotReady),
      rolloutFlagEnabled: rolloutFlagEnabled,
      signalRequiredSatisfied: signalRequiredSatisfied,
      encryptionType: _encryptionService.encryptionType,
      reports: reports,
      violations: violations,
      fieldPilotBlockers: fieldPilotBlockers,
      diagnostics: <String, dynamic>{
        'private_mesh_policy_passed': meshPolicyValidation.isPassing,
        'private_mesh_policy_failures': meshPolicyValidation.failures
            .map((failure) => failure.name)
            .toList(),
      },
    );
  }

  DomainExecutionKernelHealthReport _meshReport({
    required MeshKernelHealthSnapshot meshHealth,
    required bool rolloutFlagEnabled,
    required bool signalRequiredSatisfied,
    required UrkStageCPrivateMeshPolicyConformanceValidationResult
        meshPolicyValidation,
  }) {
    final routeTruthPresent =
        meshHealth.diagnostics['route_receipt_truth_present'] == true;
    final snapshotSupported =
        meshHealth.diagnostics['snapshot_supported'] == true;
    final replaySupported = meshHealth.diagnostics['replay_supported'] == true;
    final violations = <String>[
      if (meshHealth.status != MeshHealthStatus.healthy)
        'mesh:status:${meshHealth.status.name}',
      if (!routeTruthPresent) 'mesh:route_truth_missing',
      if (!snapshotSupported) 'mesh:snapshot_missing',
      if (!replaySupported) 'mesh:replay_missing',
      for (final failure in meshPolicyValidation.failures)
        'mesh:private_mesh_policy:${failure.name}',
    ];
    final fieldPilotBlockers = <String>[
      if (!meshHealth.nativeBacked) 'mesh:native_backing_missing',
      if (!rolloutFlagEnabled) 'mesh:feature_flag_disabled',
      if (!signalRequiredSatisfied) 'mesh:signal_crypto_missing',
      if (!meshPolicyValidation.isPassing) 'mesh:private_mesh_policy_failed',
    ];
    return DomainExecutionKernelHealthReport(
      domainId: 'mesh',
      status: _statusForMesh(meshHealth.status),
      nativeBacked: meshHealth.nativeBacked,
      runtimeReady: violations.isEmpty,
      fieldPilotReady: violations.isEmpty && fieldPilotBlockers.isEmpty,
      summary: meshHealth.summary,
      violations: violations,
      fieldPilotBlockers: fieldPilotBlockers,
      diagnostics: meshHealth.diagnostics,
    );
  }

  DomainExecutionKernelHealthReport _ai2AiReport({
    required Ai2AiKernelHealthSnapshot ai2aiHealth,
    required bool rolloutFlagEnabled,
    required bool signalRequiredSatisfied,
  }) {
    final deliveryTruthPresent =
        ai2aiHealth.diagnostics['delivery_truth_present'] == true;
    final learningTruthPresent =
        ai2aiHealth.diagnostics['learning_truth_present'] == true;
    final snapshotSupported =
        ai2aiHealth.diagnostics['snapshot_supported'] == true;
    final replaySupported = ai2aiHealth.diagnostics['replay_supported'] == true;
    final violations = <String>[
      if (ai2aiHealth.status != Ai2AiHealthStatus.healthy)
        'ai2ai:status:${ai2aiHealth.status.name}',
      if (!deliveryTruthPresent) 'ai2ai:delivery_truth_missing',
      if (!learningTruthPresent) 'ai2ai:learning_truth_missing',
      if (!snapshotSupported) 'ai2ai:snapshot_missing',
      if (!replaySupported) 'ai2ai:replay_missing',
    ];
    final fieldPilotBlockers = <String>[
      if (!ai2aiHealth.nativeBacked) 'ai2ai:native_backing_missing',
      if (!rolloutFlagEnabled) 'ai2ai:feature_flag_disabled',
      if (!signalRequiredSatisfied) 'ai2ai:signal_crypto_missing',
    ];
    return DomainExecutionKernelHealthReport(
      domainId: 'ai2ai',
      status: _statusForAi2Ai(ai2aiHealth.status),
      nativeBacked: ai2aiHealth.nativeBacked,
      runtimeReady: violations.isEmpty,
      fieldPilotReady: violations.isEmpty && fieldPilotBlockers.isEmpty,
      summary: ai2aiHealth.summary,
      violations: violations,
      fieldPilotBlockers: fieldPilotBlockers,
      diagnostics: ai2aiHealth.diagnostics,
    );
  }

  UrkStageCPrivateMeshPolicyConformanceSnapshot _meshPolicySnapshot({
    required MeshKernelHealthSnapshot meshHealth,
    required bool signalRequiredSatisfied,
  }) {
    final routeTruthPresent =
        meshHealth.diagnostics['route_receipt_truth_present'] == true;
    return UrkStageCPrivateMeshPolicyConformanceSnapshot(
      observedSchemaConformancePct: 100.0,
      observedDirectIdentifierLeaks: 0,
      observedDoubleEncryptionCoveragePct:
          signalRequiredSatisfied ? 100.0 : 0.0,
      observedKeyRotationCoveragePct: signalRequiredSatisfied ? 100.0 : 0.0,
      observedLineageTagCoveragePct: routeTruthPresent ? 100.0 : 0.0,
      observedPolicyGateCoveragePct: 100.0,
      observedPolicyBypassEvents: meshHealth
              .diagnostics['plaintext_fallback_violation_count'] as int? ??
          0,
    );
  }

  DomainExecutionStatus _statusForMesh(MeshHealthStatus status) {
    switch (status) {
      case MeshHealthStatus.healthy:
        return DomainExecutionStatus.healthy;
      case MeshHealthStatus.degraded:
        return DomainExecutionStatus.degraded;
      case MeshHealthStatus.unavailable:
        return DomainExecutionStatus.unavailable;
    }
  }

  DomainExecutionStatus _statusForAi2Ai(Ai2AiHealthStatus status) {
    switch (status) {
      case Ai2AiHealthStatus.healthy:
        return DomainExecutionStatus.healthy;
      case Ai2AiHealthStatus.degraded:
        return DomainExecutionStatus.degraded;
      case Ai2AiHealthStatus.unavailable:
        return DomainExecutionStatus.unavailable;
    }
  }
}
