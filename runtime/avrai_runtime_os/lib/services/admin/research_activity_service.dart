import 'dart:async';
import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/config/admin_control_plane_config.dart';
import 'package:avrai_runtime_os/services/admin/admin_privacy_filter.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:http/http.dart' as http;

enum AdminControlPlaneRole { adminOperator }

enum AdminControlPlaneSensitiveAction {
  stopRun,
  redirectRun,
  approveOpenWeb,
  reviewDisposition,
  triggerKillSwitch,
  downloadEvidencePack,
}

class AdminControlPlaneDeviceAttestation {
  const AdminControlPlaneDeviceAttestation({
    required this.deviceId,
    required this.platform,
    required this.privateMeshProvider,
    required this.meshIdentity,
    required this.clientCertificateFingerprint,
    required this.signedDesktopBinary,
    required this.managedDevice,
    required this.diskEncryptionEnabled,
    required this.osPatchBaselineSatisfied,
  });

  final String deviceId;
  final String platform;
  final String privateMeshProvider;
  final String meshIdentity;
  final String clientCertificateFingerprint;
  final bool signedDesktopBinary;
  final bool managedDevice;
  final bool diskEncryptionEnabled;
  final bool osPatchBaselineSatisfied;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'deviceId': deviceId,
        'platform': platform,
        'privateMeshProvider': privateMeshProvider,
        'meshIdentity': meshIdentity,
        'clientCertificateFingerprint': clientCertificateFingerprint,
        'signedDesktopBinary': signedDesktopBinary,
        'managedDevice': managedDevice,
        'diskEncryptionEnabled': diskEncryptionEnabled,
        'osPatchBaselineSatisfied': osPatchBaselineSatisfied,
      };
}

class AdminControlPlaneSessionRequest {
  const AdminControlPlaneSessionRequest({
    required this.operatorAlias,
    required this.oidcAssertion,
    required this.mfaProof,
    required this.deviceAttestation,
    this.allowedGroups = const <String>['admin_operator'],
  });

  final String operatorAlias;
  final String oidcAssertion;
  final String mfaProof;
  final AdminControlPlaneDeviceAttestation deviceAttestation;
  final List<String> allowedGroups;
}

class AdminControlPlaneSessionGrant {
  const AdminControlPlaneSessionGrant({
    required this.sessionToken,
    required this.sessionTokenId,
    required this.actorAlias,
    required this.role,
    required this.expiresAt,
    required this.issuedBy,
    required this.policyVersion,
    required this.deviceId,
    required this.meshIdentity,
    required this.clientCertificateFingerprint,
    required this.requiresPrivateControlPlane,
  });

  final String sessionToken;
  final String sessionTokenId;
  final String actorAlias;
  final AdminControlPlaneRole role;
  final DateTime expiresAt;
  final String issuedBy;
  final String policyVersion;
  final String deviceId;
  final String meshIdentity;
  final String clientCertificateFingerprint;
  final bool requiresPrivateControlPlane;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sessionToken': sessionToken,
        'sessionTokenId': sessionTokenId,
        'actorAlias': actorAlias,
        'role': role.name,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedBy': issuedBy,
        'policyVersion': policyVersion,
        'deviceId': deviceId,
        'meshIdentity': meshIdentity,
        'clientCertificateFingerprint': clientCertificateFingerprint,
        'requiresPrivateControlPlane': requiresPrivateControlPlane,
      };
}

class AdminControlPlaneStepUpProof {
  const AdminControlPlaneStepUpProof({
    required this.proof,
    required this.issuedAt,
    this.factor = 'mfa_step_up',
  });

  final String proof;
  final DateTime issuedAt;
  final String factor;

  bool get isRecent =>
      DateTime.now().toUtc().difference(issuedAt) <=
      const Duration(minutes: 10);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'proof': proof,
        'issuedAt': issuedAt.toIso8601String(),
        'factor': factor,
      };
}

class AdminControlPlaneSecondOperatorApproval {
  const AdminControlPlaneSecondOperatorApproval({
    required this.actorAlias,
    required this.proof,
    required this.approvedAt,
  });

  final String actorAlias;
  final String proof;
  final DateTime approvedAt;

  bool get isRecent =>
      DateTime.now().toUtc().difference(approvedAt) <=
      const Duration(minutes: 10);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'actorAlias': actorAlias,
        'proof': proof,
        'approvedAt': approvedAt.toIso8601String(),
      };
}

abstract class AdminControlPlaneGateway {
  Future<bool> canConnect();
  bool get hasActiveSession;
  AdminControlPlaneSessionGrant? get activeSession;
  Future<AdminControlPlaneSessionGrant> createSession({
    required AdminControlPlaneSessionRequest request,
  });
  Future<void> revokeActiveSession();
  Stream<List<ResearchRunState>> watchResearchRuns();
  Future<List<ResearchRunState>> listResearchRuns();
  Future<ResearchRunState?> watchResearchRun(String runId);
  Future<List<ResearchAlert>> listResearchAlerts();
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  });
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  });
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  });
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  });
  Future<void> emitAlert(ResearchAlert alert);
  Future<ResearchApproval> requestOpenWebApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  });
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  });
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  });
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
  });
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  });
}

class GovernedAutoresearchUnavailableException implements Exception {
  GovernedAutoresearchUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GovernedAutoresearchActionBlockedException implements Exception {
  GovernedAutoresearchActionBlockedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminControlPlaneAuthException implements Exception {
  AdminControlPlaneAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HttpAdminControlPlaneGateway implements AdminControlPlaneGateway {
  HttpAdminControlPlaneGateway({
    required Uri baseUri,
    http.Client? httpClient,
    Duration pollInterval = const Duration(seconds: 5),
  })  : _baseUri = baseUri,
        _httpClient = httpClient ?? http.Client(),
        _pollInterval = pollInterval;

  final Uri _baseUri;
  final http.Client _httpClient;
  final Duration _pollInterval;

  AdminControlPlaneSessionGrant? _activeSession;

  bool get _isConfigured => _baseUri.toString().trim().isNotEmpty;

  @override
  bool get hasActiveSession =>
      _activeSession != null && !_activeSession!.isExpired;

  @override
  AdminControlPlaneSessionGrant? get activeSession =>
      hasActiveSession ? _activeSession : null;

  @override
  Future<bool> canConnect() async {
    if (!_isConfigured) {
      return false;
    }
    try {
      final response = await _httpClient.get(_resolve('/health')).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AdminControlPlaneSessionGrant> createSession({
    required AdminControlPlaneSessionRequest request,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/sessions',
      body: <String, dynamic>{
        'operatorAlias': request.operatorAlias,
        'oidcAssertion': request.oidcAssertion,
        'mfaProof': request.mfaProof,
        'deviceAttestation': request.deviceAttestation.toJson(),
        'allowedGroups': request.allowedGroups,
      },
      includeSession: false,
      authCall: true,
    );
    final grant = AdminControlPlaneSessionGrant(
      sessionToken: payload['sessionToken']?.toString() ?? '',
      sessionTokenId: payload['sessionTokenId']?.toString() ?? '',
      actorAlias: payload['actorAlias']?.toString() ?? request.operatorAlias,
      role: _parseControlPlaneRole(payload['role']?.toString()),
      expiresAt:
          DateTime.tryParse(payload['expiresAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc().add(const Duration(minutes: 60)),
      issuedBy:
          payload['issuedBy']?.toString() ?? 'private_admin_control_plane',
      policyVersion: payload['policyVersion']?.toString() ?? 'unknown',
      deviceId:
          payload['deviceId']?.toString() ?? request.deviceAttestation.deviceId,
      meshIdentity: payload['meshIdentity']?.toString() ??
          request.deviceAttestation.meshIdentity,
      clientCertificateFingerprint:
          payload['clientCertificateFingerprint']?.toString() ??
              request.deviceAttestation.clientCertificateFingerprint,
      requiresPrivateControlPlane:
          payload['requiresPrivateControlPlane'] as bool? ?? true,
    );
    _activeSession = grant;
    return grant;
  }

  @override
  Future<void> revokeActiveSession() async {
    if (!hasActiveSession) {
      _activeSession = null;
      return;
    }
    try {
      await _sendForObject(
        method: 'POST',
        path: '/v1/sessions/revoke',
        body: const <String, dynamic>{},
      );
    } finally {
      _activeSession = null;
    }
  }

  @override
  Stream<List<ResearchRunState>> watchResearchRuns() {
    late StreamController<List<ResearchRunState>> controller;
    Timer? poller;

    Future<void> emit() async {
      try {
        controller.add(await listResearchRuns());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<ResearchRunState>>.broadcast(
      onListen: () {
        unawaited(emit());
        poller = Timer.periodic(_pollInterval, (_) => unawaited(emit()));
      },
      onCancel: () {
        poller?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<ResearchRunState>> listResearchRuns() async {
    final payload = await _sendForObject(
      method: 'GET',
      path: '/v1/research/runs',
      includeSession: true,
    );
    return _decodeRunList(payload['runs']);
  }

  @override
  Future<ResearchRunState?> watchResearchRun(String runId) async {
    final payload = await _sendForObject(
      method: 'GET',
      path: '/v1/research/runs/$runId',
    );
    final dynamic runPayload = payload['run'];
    if (runPayload is! Map<String, dynamic>) {
      return null;
    }
    return ResearchRunState.fromJson(runPayload);
  }

  @override
  Future<List<ResearchAlert>> listResearchAlerts() async {
    final payload = await _sendForObject(
      method: 'GET',
      path: '/v1/research/alerts',
    );
    final rawAlerts = payload['alerts'];
    if (rawAlerts is! List<dynamic>) {
      return const <ResearchAlert>[];
    }
    return rawAlerts
        .whereType<Map<String, dynamic>>()
        .map(ResearchAlert.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    return _sendForRun(
      runId: runId,
      action: 'approve_charter',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
      },
    );
  }

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    return _sendForRun(
      runId: runId,
      action: 'reject_charter',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
      },
    );
  }

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'queue_run',
      body: <String, dynamic>{'actorAlias': actorAlias},
    );
  }

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'start_sandbox_run',
      body: <String, dynamic>{'actorAlias': actorAlias},
    );
  }

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) {
    return _sendForRun(
      runId: runId,
      action: 'pause_run',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
      },
    );
  }

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'resume_run',
      body: <String, dynamic>{'actorAlias': actorAlias},
    );
  }

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'stop_run',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
      },
    );
  }

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'redirect_run',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'directive': directive,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
      },
    );
  }

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/get_explanation',
      body: <String, dynamic>{'actorAlias': actorAlias},
    );
    final rawExplanation = payload['explanation'];
    if (rawExplanation is! Map<String, dynamic>) {
      throw GovernedAutoresearchUnavailableException(
        'Private admin control plane returned no explanation payload.',
      );
    }
    return ResearchExplanation.fromJson(rawExplanation);
  }

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'review_candidate',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'approved': approved,
        'rationale': rationale,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
        if (secondOperatorApproval != null)
          'secondOperatorApproval': secondOperatorApproval.toJson(),
      },
    );
  }

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'add_operator_note',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'note': note,
      },
    );
  }

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/checkpoint_run',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'summary': summary,
        'metricSnapshot': metricSnapshot,
        'requiresHumanReview': requiresHumanReview,
        'contradictionDetected': contradictionDetected,
      },
    );
    final rawCheckpoint = payload['checkpoint'];
    if (rawCheckpoint is Map<String, dynamic>) {
      return ResearchCheckpoint.fromJson(rawCheckpoint);
    }
    final ResearchRunState? refreshedRun = await watchResearchRun(runId);
    final List<ResearchCheckpoint> checkpoints =
        refreshedRun?.checkpoints ?? const <ResearchCheckpoint>[];
    if (checkpoints.isEmpty) {
      throw GovernedAutoresearchUnavailableException(
        'Checkpoint payload missing and no checkpoint found on refreshed run.',
      );
    }
    return checkpoints.last;
  }

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/append_artifact',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'kind': kind.name,
        'storageKey': storageKey,
        'summary': summary,
        'isRedacted': isRedacted,
        if (checksum != null) 'checksum': checksum,
      },
    );
    return _decodeArtifact(payload);
  }

  @override
  Future<void> emitAlert(ResearchAlert alert) async {
    await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/${alert.runId}/actions/emit_alert',
      body: <String, dynamic>{
        'alert': alert.toJson(),
      },
    );
  }

  @override
  Future<ResearchApproval> requestOpenWebApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/request_open_web',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'ttlMinutes': ttl.inMinutes,
        'rationale': rationale,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
      },
    );
    return _decodeApproval(payload);
  }

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/approve_open_web',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'ttlMinutes': ttl.inMinutes,
        'rationale': rationale,
        'stepUpProof': stepUpProof.toJson(),
        'secondOperatorApproval': secondOperatorApproval.toJson(),
      },
    );
    return _decodeApproval(payload);
  }

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/reject_open_web',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
      },
    );
    return _decodeApproval(payload);
  }

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/fetch_evidence',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'sourceUri': sourceUri.toString(),
      },
    );
    return _decodeArtifact(payload);
  }

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/revoke_access',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
      },
    );
  }

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/record_disposition',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'approved': approved,
        'rationale': rationale,
      },
    );
    return _decodeApproval(payload);
  }

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
  }) {
    return _sendForRun(
      runId: runId,
      action: 'trigger_kill_switch',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'rationale': rationale,
        'stepUpProof': stepUpProof.toJson(),
        'secondOperatorApproval': secondOperatorApproval.toJson(),
      },
    );
  }

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/download_evidence_pack',
      body: <String, dynamic>{
        'actorAlias': actorAlias,
        'artifactIds': artifactIds,
        if (stepUpProof != null) 'stepUpProof': stepUpProof.toJson(),
      },
    );
    return _decodeArtifact(payload);
  }

  Future<ResearchRunState> _sendForRun({
    required String runId,
    required String action,
    required Map<String, dynamic> body,
  }) async {
    final payload = await _sendForObject(
      method: 'POST',
      path: '/v1/research/runs/$runId/actions/$action',
      body: body,
    );
    final rawRun = payload['run'];
    if (rawRun is! Map<String, dynamic>) {
      throw GovernedAutoresearchUnavailableException(
        'Private admin control plane returned no run payload for $action.',
      );
    }
    return ResearchRunState.fromJson(rawRun);
  }

  Future<Map<String, dynamic>> _sendForObject({
    required String method,
    required String path,
    Map<String, dynamic> body = const <String, dynamic>{},
    bool includeSession = true,
    bool authCall = false,
  }) async {
    _requireConfigured();
    final response = await _request(
      method: method,
      path: path,
      body: body,
      includeSession: includeSession,
    );
    final payload = _decodePayload(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    final message = payload['error']?.toString() ??
        'Private admin control-plane request failed.';
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 400) {
      if (authCall) {
        throw AdminControlPlaneAuthException(message);
      }
      throw GovernedAutoresearchActionBlockedException(message);
    }
    throw GovernedAutoresearchUnavailableException(message);
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required bool includeSession,
  }) {
    final Uri uri = _resolve(path);
    final Map<String, String> headers = <String, String>{
      'content-type': 'application/json',
      'accept': 'application/json',
      if (includeSession && hasActiveSession)
        'authorization': 'Bearer ${activeSession!.sessionToken}',
    };
    switch (method.toUpperCase()) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      default:
        throw UnsupportedError('Unsupported control-plane method: $method');
    }
  }

  Map<String, dynamic> _decodePayload(http.Response response) {
    if (response.body.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return const <String, dynamic>{};
  }

  ResearchApproval _decodeApproval(Map<String, dynamic> payload) {
    final rawApproval = payload['approval'];
    if (rawApproval is! Map<String, dynamic>) {
      throw GovernedAutoresearchUnavailableException(
        'Private admin control plane returned no approval payload.',
      );
    }
    return ResearchApproval.fromJson(rawApproval);
  }

  ResearchArtifactRef _decodeArtifact(Map<String, dynamic> payload) {
    final rawArtifact = payload['artifact'];
    if (rawArtifact is! Map<String, dynamic>) {
      throw GovernedAutoresearchUnavailableException(
        'Private admin control plane returned no artifact payload.',
      );
    }
    return ResearchArtifactRef.fromJson(rawArtifact);
  }

  List<ResearchRunState> _decodeRunList(dynamic rawRuns) {
    if (rawRuns is! List<dynamic>) {
      return const <ResearchRunState>[];
    }
    return rawRuns
        .whereType<Map<String, dynamic>>()
        .map(ResearchRunState.fromJson)
        .toList(growable: false);
  }

  void _requireConfigured() {
    if (!_isConfigured) {
      throw GovernedAutoresearchUnavailableException(
        'ADMIN_CONTROL_PLANE_URL is not configured. '
        'Beta admin control will not fall back to direct database access.',
      );
    }
  }

  Uri _resolve(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.resolve(normalized);
  }

  AdminControlPlaneRole _parseControlPlaneRole(String? raw) {
    return AdminControlPlaneRole.values.firstWhere(
      (AdminControlPlaneRole value) => value.name == raw,
      orElse: () => AdminControlPlaneRole.adminOperator,
    );
  }
}

class AdminControlPlaneGatewayFactory {
  static AdminControlPlaneGateway? _sharedGateway;

  static AdminControlPlaneGateway resolveDefault({
    required SharedPreferencesCompat prefs,
  }) {
    return _sharedGateway ??= HttpAdminControlPlaneGateway(
      baseUri: Uri.parse(AdminControlPlaneConfig.url),
      pollInterval: Duration(
        seconds: AdminControlPlaneConfig.pollIntervalSeconds,
      ),
    );
  }

  static AdminControlPlaneGateway createForTesting({
    required SharedPreferencesCompat prefs,
  }) {
    return TestAdminControlPlaneGateway(
      delegate: LocalResearchActivityService(prefs: prefs),
      auditPrefs: prefs,
    );
  }

  static void resetSharedGatewayForTests() {
    _sharedGateway = null;
  }
}

enum GovernedAutoresearchSource { localFixture, privateBackend }

class GovernedAutoresearchResolution {
  const GovernedAutoresearchResolution({
    required this.service,
    required this.source,
    required this.sourceLabel,
    required this.isBackendConnected,
  });

  final GovernedAutoresearchSupervisor service;
  final GovernedAutoresearchSource source;
  final String sourceLabel;
  final bool isBackendConnected;
}

abstract class GovernedAutoresearchSupervisor
    implements
        AdminResearchControlContract,
        ResearchSupervisorContract,
        ResearchEgressBrokerContract {
  Future<List<ResearchAlert>> listAlerts();
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  });
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  });
  @override
  Future<ResearchApproval> requestOpenWebAccess({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  });
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  });
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  });
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  });
}

class GovernedAutoresearchSupervisorFactory {
  static const String _sourceEnvKey = 'ADMIN_RESEARCH_SOURCE';

  static Future<GovernedAutoresearchResolution> createDefault({
    required SharedPreferencesCompat prefs,
    bool allowLocalFixture = false,
  }) {
    const requested = String.fromEnvironment(_sourceEnvKey, defaultValue: '');
    final preferredSource = requested.trim().toLowerCase() == 'local_fixture'
        ? GovernedAutoresearchSource.localFixture
        : GovernedAutoresearchSource.privateBackend;
    return create(
      prefs: prefs,
      preferredSource: preferredSource,
      allowLocalFixture: allowLocalFixture,
    );
  }

  static Future<GovernedAutoresearchResolution> create({
    required SharedPreferencesCompat prefs,
    required GovernedAutoresearchSource preferredSource,
    bool allowLocalFixture = false,
  }) async {
    switch (preferredSource) {
      case GovernedAutoresearchSource.localFixture:
        if (!allowLocalFixture) {
          throw GovernedAutoresearchUnavailableException(
            'Local autoresearch fixtures are disabled for beta. '
            'Admin control must bind to the private backend.',
          );
        }
        return GovernedAutoresearchResolution(
          service: LocalResearchActivityService(prefs: prefs),
          source: GovernedAutoresearchSource.localFixture,
          sourceLabel: 'local fixture',
          isBackendConnected: false,
        );
      case GovernedAutoresearchSource.privateBackend:
        final backend = InternalBackendGovernedAutoresearchSupervisor(
          gateway: AdminControlPlaneGatewayFactory.resolveDefault(
            prefs: prefs,
          ),
        );
        final connected = await backend.canConnect();
        if (!connected) {
          throw GovernedAutoresearchUnavailableException(
            'Private autoresearch backend unavailable. '
            'Beta admin control will not fall back to local storage.',
          );
        }
        return GovernedAutoresearchResolution(
          service: backend,
          source: GovernedAutoresearchSource.privateBackend,
          sourceLabel: 'private backend',
          isBackendConnected: true,
        );
    }
  }

  static GovernedAutoresearchResolution createForTesting({
    required SharedPreferencesCompat prefs,
  }) {
    return GovernedAutoresearchResolution(
      service: LocalResearchActivityService(prefs: prefs),
      source: GovernedAutoresearchSource.localFixture,
      sourceLabel: 'local fixture',
      isBackendConnected: false,
    );
  }
}

class LocalResearchActivityService implements GovernedAutoresearchSupervisor {
  LocalResearchActivityService({required SharedPreferencesCompat prefs})
      : _prefs = prefs;

  static const String _storageKey = 'admin.research.governed_runs.v2';

  final SharedPreferencesCompat _prefs;
  final StreamController<List<ResearchRunState>> _controller =
      StreamController<List<ResearchRunState>>.broadcast();

  bool _initialized = false;
  List<ResearchRunState> _runs = <ResearchRunState>[];

  @override
  Stream<List<ResearchRunState>> watchRuns() async* {
    await _ensureInitialized();
    yield List<ResearchRunState>.unmodifiable(_sortedRuns(_runs));
    yield* _controller.stream;
  }

  @override
  Future<List<ResearchRunState>> listRuns() async {
    await _ensureInitialized();
    return List<ResearchRunState>.unmodifiable(_sortedRuns(_runs));
  }

  @override
  Future<ResearchRunState?> watchRun(String runId) async {
    final runs = await listRuns();
    for (final ResearchRunState run in runs) {
      if (run.id == runId) {
        return run;
      }
    }
    return null;
  }

  @override
  Future<List<ResearchAlert>> listAlerts() async {
    await _ensureInitialized();
    return _deriveAlerts(_runs);
  }

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.approveCharter,
      rationale:
          rationale.isEmpty ? 'Charter approved for beta sandbox.' : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        if (run.lifecycleState != ResearchRunLifecycleState.draft &&
            run.lifecycleState != ResearchRunLifecycleState.review) {
          throw GovernedAutoresearchActionBlockedException(
            'Only draft or review runs can have their charter approved.',
          );
        }
        final approval = ResearchApproval(
          id: _generateId('apr'),
          runId: run.id,
          kind: ResearchApprovalKind.charter,
          status: ResearchApprovalStatus.approved,
          createdAt: now,
          actorAlias: actorAlias,
          reason: rationale,
          decidedAt: now,
        );
        final updatedCharter = run.charter.copyWith(
          approvedBy: actorAlias,
          approvedAt: now,
          updatedAt: now,
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.approved,
          charter: updatedCharter,
          approvals: <ResearchApproval>[...run.approvals, approval],
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.reviewCandidate,
      rationale: rationale.isEmpty ? 'Charter rejected by admin.' : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        if (run.lifecycleState != ResearchRunLifecycleState.draft &&
            run.lifecycleState != ResearchRunLifecycleState.review) {
          throw GovernedAutoresearchActionBlockedException(
            'Only draft or review runs can be rejected.',
          );
        }
        final approval = ResearchApproval(
          id: _generateId('apr'),
          runId: run.id,
          kind: ResearchApprovalKind.charter,
          status: ResearchApprovalStatus.rejected,
          createdAt: now,
          actorAlias: actorAlias,
          reason: rationale,
          decidedAt: now,
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.archived,
          approvals: <ResearchApproval>[...run.approvals, approval],
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.queueRun,
      rationale: 'Queued for sandbox execution.',
      mutate: (ResearchRunState run, DateTime now) {
        if (run.requiresAdminApproval && !run.hasApprovedCharter) {
          throw GovernedAutoresearchActionBlockedException(
            'Run cannot be queued before charter approval.',
          );
        }
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.approved,
            ResearchRunLifecycleState.paused,
          ],
          message: 'Only approved or paused runs can be queued.',
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.queued,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.queueRun,
      rationale: 'Sandbox run started in replay lane.',
      mutate: (ResearchRunState run, DateTime now) {
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.queued,
          ],
          message: 'Sandbox execution can start only from queued state.',
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.running,
          updatedAt: now,
          lastHeartbeatAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.pauseRun,
      rationale: rationale.isEmpty
          ? 'Paused at the next safe sandbox checkpoint.'
          : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.running,
          ],
          message: 'Only running runs can be paused.',
        );
        final checkpoint = _buildCheckpoint(
          runId: run.id,
          state: ResearchRunLifecycleState.paused,
          summary: 'Operator pause checkpoint',
          metricSnapshot: run.metrics,
          createdAt: now,
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.paused,
          checkpoints: <ResearchCheckpoint>[...run.checkpoints, checkpoint],
          activeCheckpointId: checkpoint.id,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.resumeRun,
      rationale: 'Resumed from latest sandbox checkpoint.',
      mutate: (ResearchRunState run, DateTime now) {
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.paused,
          ],
          message: 'Only paused runs can be resumed.',
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.running,
          updatedAt: now,
          lastHeartbeatAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.stopRun,
      rationale: rationale.isEmpty
          ? 'Stopped by admin and preserved for review.'
          : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.draft,
            ResearchRunLifecycleState.approved,
            ResearchRunLifecycleState.queued,
            ResearchRunLifecycleState.running,
            ResearchRunLifecycleState.pausing,
            ResearchRunLifecycleState.paused,
            ResearchRunLifecycleState.review,
            ResearchRunLifecycleState.redirectPending,
          ],
          message: 'Only active governed runs can be stopped.',
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.stopped,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.redirectRun,
      rationale: directive,
      mutate: (ResearchRunState run, DateTime now) {
        _requireState(
          run,
          allowed: const <ResearchRunLifecycleState>[
            ResearchRunLifecycleState.draft,
            ResearchRunLifecycleState.approved,
            ResearchRunLifecycleState.paused,
            ResearchRunLifecycleState.review,
          ],
          message:
              'Redirects must occur from draft, approved, paused, or review.',
        );
        return run.copyWith(
          lifecycleState: ResearchRunLifecycleState.redirectPending,
          redirectDirective: directive,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) async {
    await _ensureInitialized();
    final run = _runById(runId);
    final now = DateTime.now().toUtc();
    final explanation = ResearchExplanation(
      id: _generateId('exp'),
      runId: run.id,
      summary:
          '${run.title} is in ${run.lifecycleState.name} with ${run.checkpoints.length} checkpoints and ${run.alerts.length} alerts.',
      currentStep: _currentStepForState(run.lifecycleState),
      rationale: run.redirectDirective ?? run.charter.objective,
      nextStep: _nextStepForState(run.lifecycleState),
      evidenceSummary: _evidenceSummary(run),
      createdAt: now,
      checkpointId: run.activeCheckpointId,
    );
    await _replaceRun(
      run.copyWith(
        latestExplanation: explanation,
        updatedAt: now,
        controlActions: <ResearchControlAction>[
          ...run.controlActions,
          _buildControlAction(
            runId: run.id,
            actorAlias: actorAlias,
            actionType: ResearchControlActionType.requestExplanation,
            rationale: 'Generated live explanation for admin.',
            createdAt: now,
            modelVersion: run.modelVersion,
            policyVersion: run.policyVersion,
          ),
        ],
      ),
    );
    return explanation;
  }

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.reviewCandidate,
      rationale: rationale.isEmpty
          ? approved
              ? 'Sandbox candidate approved for promotion review.'
              : 'Sandbox candidate rejected.'
          : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        final hasPendingEgress = run.approvals.any(
          (ResearchApproval approval) =>
              approval.kind == ResearchApprovalKind.egressOpenWeb &&
              approval.status == ResearchApprovalStatus.pending,
        );
        final approval = ResearchApproval(
          id: _generateId('apr'),
          runId: run.id,
          kind: hasPendingEgress
              ? ResearchApprovalKind.egressOpenWeb
              : ResearchApprovalKind.reviewDisposition,
          status: approved
              ? ResearchApprovalStatus.approved
              : ResearchApprovalStatus.rejected,
          createdAt: now,
          actorAlias: actorAlias,
          reason: rationale,
          decidedAt: now,
          expiresAt: hasPendingEgress && approved
              ? now.add(const Duration(hours: 4))
              : null,
        );
        final approvals = _replacePendingApproval(run.approvals, approval);
        return run.copyWith(
          lifecycleState: hasPendingEgress
              ? run.lifecycleState
              : approved
                  ? ResearchRunLifecycleState.completed
                  : ResearchRunLifecycleState.archived,
          approvals: approvals,
          egressMode: hasPendingEgress && approved
              ? ResearchEgressMode.brokeredOpenWeb
              : run.egressMode,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.appendNote,
      rationale: note,
      mutate: (ResearchRunState run, DateTime now) {
        final explanation = run.latestExplanation ??
            ResearchExplanation(
              id: _generateId('exp'),
              runId: run.id,
              summary: 'Operator note recorded.',
              currentStep: _currentStepForState(run.lifecycleState),
              rationale: note,
              nextStep: _nextStepForState(run.lifecycleState),
              evidenceSummary: _evidenceSummary(run),
              createdAt: now,
              checkpointId: run.activeCheckpointId,
            );
        return run.copyWith(
          latestExplanation: explanation,
          updatedAt: now,
        );
      },
    );
  }

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final run = _runById(runId);
    final checkpoint = _buildCheckpoint(
      runId: run.id,
      state: requiresHumanReview || contradictionDetected
          ? ResearchRunLifecycleState.review
          : run.lifecycleState,
      summary: summary,
      metricSnapshot: metricSnapshot.isEmpty ? run.metrics : metricSnapshot,
      createdAt: now,
      requiresHumanReview: requiresHumanReview,
      contradictionDetected: contradictionDetected,
    );
    final projection = ResearchSandboxResultProjection(
      runId: run.id,
      checkpointId: checkpoint.id,
      summary: summary,
      metrics: metricSnapshot.isEmpty ? run.metrics : metricSnapshot,
      createdAt: now,
      promotionCandidate: (metricSnapshot['promotionReadiness'] ??
              run.metrics['promotionReadiness'] ??
              0) >=
          0.8,
      safeForModelConsumption: true,
      violationCount: contradictionDetected ? 1 : 0,
    );
    await _replaceRun(
      run.copyWith(
        lifecycleState: requiresHumanReview || contradictionDetected
            ? ResearchRunLifecycleState.review
            : run.lifecycleState,
        checkpoints: <ResearchCheckpoint>[...run.checkpoints, checkpoint],
        latestSandboxProjection: projection,
        activeCheckpointId: checkpoint.id,
        contradictionDetected: contradictionDetected,
        updatedAt: now,
        lastHeartbeatAt: now,
        controlActions: <ResearchControlAction>[
          ...run.controlActions,
          _buildControlAction(
            runId: run.id,
            actorAlias: actorAlias,
            actionType: ResearchControlActionType.checkpointRun,
            rationale: summary,
            createdAt: now,
            modelVersion: run.modelVersion,
            policyVersion: run.policyVersion,
            checkpointId: checkpoint.id,
          ),
        ],
      ),
    );
    return checkpoint;
  }

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final run = _runById(runId);
    final artifact = ResearchArtifactRef(
      id: _generateId('art'),
      runId: run.id,
      kind: kind,
      storageKey: storageKey,
      summary: summary,
      createdAt: now,
      isRedacted: isRedacted,
      checksum: checksum,
      expiresAt: kind == ResearchArtifactKind.evidenceBundle
          ? now.add(const Duration(hours: 4))
          : null,
    );
    await _replaceRun(
      run.copyWith(
        artifacts: <ResearchArtifactRef>[...run.artifacts, artifact],
        updatedAt: now,
        controlActions: <ResearchControlAction>[
          ...run.controlActions,
          _buildControlAction(
            runId: run.id,
            actorAlias: actorAlias,
            actionType: ResearchControlActionType.appendNote,
            rationale: 'Artifact appended: ${kind.name}',
            createdAt: now,
            modelVersion: run.modelVersion,
            policyVersion: run.policyVersion,
            details: <String, dynamic>{'storageKey': storageKey},
          ),
        ],
      ),
    );
    return artifact;
  }

  @override
  Future<void> emitAlert(ResearchAlert alert) async {
    await _ensureInitialized();
    final run = _runById(alert.runId);
    await _replaceRun(
      run.copyWith(
        alerts: <ResearchAlert>[...run.alerts, alert],
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<ResearchApproval> requestEgressApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
  }) {
    return requestOpenWebAccess(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchApproval> requestOpenWebAccess({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final run = _runById(runId);
    if (run.egressMode == ResearchEgressMode.brokeredOpenWeb &&
        run.hasApprovedOpenWebAccess) {
      throw GovernedAutoresearchActionBlockedException(
        'Open-web egress is already approved for this run.',
      );
    }
    final approval = ResearchApproval(
      id: _generateId('apr'),
      runId: run.id,
      kind: ResearchApprovalKind.egressOpenWeb,
      status: ResearchApprovalStatus.pending,
      createdAt: now,
      actorAlias: actorAlias,
      reason: rationale.isEmpty
          ? 'Internal evidence exhausted; requesting brokered outbound web access.'
          : rationale,
      expiresAt: now.add(ttl),
    );
    await _replaceRun(
      run.copyWith(
        approvals: <ResearchApproval>[...run.approvals, approval],
        updatedAt: now,
        controlActions: <ResearchControlAction>[
          ...run.controlActions,
          _buildControlAction(
            runId: run.id,
            actorAlias: actorAlias,
            actionType: ResearchControlActionType.requestEgressApproval,
            rationale: approval.reason ?? '',
            createdAt: now,
            modelVersion: run.modelVersion,
            policyVersion: run.policyVersion,
          ),
        ],
      ),
    );
    return approval;
  }

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) async {
    final updated = await reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: true,
      rationale: rationale.isEmpty
          ? 'Brokered open-web access approved by dual control.'
          : rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
    return updated.approvals.lastWhere(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb,
    );
  }

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final updated = await reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: false,
      rationale:
          rationale.isEmpty ? 'Brokered open-web access denied.' : rationale,
      stepUpProof: stepUpProof,
    );
    return updated.approvals.lastWhere(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb,
    );
  }

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) async {
    await _ensureInitialized();
    final run = _runById(runId);
    final isOpenWeb = sourceUri.scheme == 'http' || sourceUri.scheme == 'https';
    if (isOpenWeb && !run.hasApprovedOpenWebAccess) {
      throw GovernedAutoresearchActionBlockedException(
        'Open-web evidence is blocked until admin approves brokered access.',
      );
    }
    final storageKey = isOpenWeb
        ? "broker://quarantine/${run.id}/${_generateId('evidence')}"
        : "internal://evidence/${run.id}/${_generateId('evidence')}";
    return appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: ResearchArtifactKind.evidenceBundle,
      storageKey: storageKey,
      summary: isOpenWeb
          ? 'Brokered evidence captured from ${sourceUri.host} and quarantined for normalization.'
          : 'Internal evidence bundle staged for sandbox analysis.',
      isRedacted: true,
    );
  }

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final run = _runById(runId);
    final approvals = run.approvals.map((ResearchApproval approval) {
      if (approval.kind == ResearchApprovalKind.egressOpenWeb &&
          approval.status == ResearchApprovalStatus.approved) {
        return ResearchApproval(
          id: _generateId('apr'),
          runId: run.id,
          kind: ResearchApprovalKind.egressOpenWeb,
          status: ResearchApprovalStatus.revoked,
          createdAt: now,
          actorAlias: actorAlias,
          reason: rationale,
          decidedAt: now,
        );
      }
      return approval;
    }).toList(growable: false);
    await _replaceRun(
      run.copyWith(
        approvals: approvals,
        egressMode: ResearchEgressMode.internalOnly,
        updatedAt: now,
        controlActions: <ResearchControlAction>[
          ...run.controlActions,
          _buildControlAction(
            runId: run.id,
            actorAlias: actorAlias,
            actionType: ResearchControlActionType.revokeEgressApproval,
            rationale:
                rationale.isEmpty ? 'Brokered egress revoked.' : rationale,
            createdAt: now,
            modelVersion: run.modelVersion,
            policyVersion: run.policyVersion,
          ),
        ],
      ),
    );
  }

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    return appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: ResearchArtifactKind.signedEvidencePack,
      storageKey: 'evidence-pack://$runId/${_generateId('pack')}',
      summary:
          'Signed redacted evidence pack for ${artifactIds.length} artifacts.',
      isRedacted: true,
      checksum: base64Url.encode(utf8.encode('$runId:$artifactIds')),
    );
  }

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final approval = ResearchApproval(
      id: _generateId('apr'),
      runId: runId,
      kind: ResearchApprovalKind.reviewDisposition,
      status: approved
          ? ResearchApprovalStatus.approved
          : ResearchApprovalStatus.rejected,
      createdAt: now,
      actorAlias: actorAlias,
      reason: rationale,
      decidedAt: now,
    );
    final run = _runById(runId);
    await _replaceRun(
      run.copyWith(
        approvals: <ResearchApproval>[...run.approvals, approval],
        lifecycleState: approved
            ? ResearchRunLifecycleState.completed
            : ResearchRunLifecycleState.archived,
        updatedAt: now,
      ),
    );
    return approval;
  }

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) async {
    return _mutateRun(
      runId: runId,
      actorAlias: actorAlias,
      actionType: ResearchControlActionType.triggerKillSwitch,
      rationale:
          rationale.isEmpty ? 'Break-glass kill switch activated.' : rationale,
      mutate: (ResearchRunState run, DateTime now) {
        return run.copyWith(
          killSwitchActive: true,
          lifecycleState: ResearchRunLifecycleState.stopped,
          updatedAt: now,
        );
      },
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _runs = _seedRuns();
      await _persist();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _runs = decoded
          .whereType<Map<String, dynamic>>()
          .map(ResearchRunState.fromJson)
          .toList(growable: false);
      _emit();
    } catch (_) {
      _runs = _seedRuns();
      await _persist();
    }
  }

  Future<ResearchRunState> _mutateRun({
    required String runId,
    required String actorAlias,
    required ResearchControlActionType actionType,
    required String rationale,
    required ResearchRunState Function(ResearchRunState run, DateTime now)
        mutate,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final run = _runById(runId);
    final next = mutate(run, now);
    final action = _buildControlAction(
      runId: runId,
      actorAlias: actorAlias,
      actionType: actionType,
      rationale: rationale,
      createdAt: now,
      modelVersion: run.modelVersion,
      policyVersion: run.policyVersion,
      checkpointId: next.activeCheckpointId,
    );
    final updated = next.copyWith(
      controlActions: <ResearchControlAction>[
        ...next.controlActions,
        action,
      ],
      alerts: _deriveAlerts(<ResearchRunState>[next]),
      updatedAt: now,
    );
    await _replaceRun(updated);
    return updated;
  }

  ResearchRunState _runById(String runId) {
    return _runs.firstWhere(
      (ResearchRunState run) => run.id == runId,
      orElse: () => throw GovernedAutoresearchActionBlockedException(
        'Unknown research run: $runId',
      ),
    );
  }

  Future<void> _replaceRun(ResearchRunState updated) async {
    _runs = _runs
        .map(
          (ResearchRunState run) => run.id == updated.id ? updated : run,
        )
        .toList(growable: false);
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(_runs.map((ResearchRunState run) => run.toJson()).toList()),
    );
    _emit();
  }

  void _emit() {
    _controller.add(List<ResearchRunState>.unmodifiable(_sortedRuns(_runs)));
  }

  List<ResearchRunState> _seedRuns() {
    final now = DateTime.now().toUtc();
    return <ResearchRunState>[
      ResearchRunState(
        id: 'gar_beta_reality_01',
        title: 'Reality replay prior tuning',
        hypothesis:
            'Replay prior ranking improves if approved historical outcomes are weighted above synthetic heuristics.',
        layer: ResearchLayer.reality,
        ownerAgentAlias: 'reality_worker_a',
        lifecycleState: ResearchRunLifecycleState.running,
        humanAccess: ResearchHumanAccess.adminOnly,
        visibilityScope: ResearchVisibilityScope.runtimeInternalProjection,
        lane: ResearchRunLane.sandboxReplay,
        charter: ResearchCharter(
          id: 'charter_reality_01',
          title: 'Reality replay prior tuning',
          objective:
              'Improve sandbox replay ranking without enabling production mutation.',
          hypothesis:
              'Approved outcome examples improve replay ranking stability.',
          allowedExperimentSurfaces: const <String>[
            'replay_priors',
            'holdout_ranker',
            'sandbox_only_thresholds',
          ],
          successMetrics: const <String>[
            'promotionReadiness >= 0.80',
            'policyViolationCount == 0',
          ],
          stopConditions: const <String>[
            'contradiction_detected',
            'driftScore > 0.70',
          ],
          hardBans: const <String>[
            'production_mutation',
            'consumer_endpoint_access',
            'raw_external_payload_rendering',
          ],
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(hours: 3)),
          approvedBy: 'admin_operator',
          approvedAt: now.subtract(const Duration(days: 2)),
        ),
        egressMode: ResearchEgressMode.internalOnly,
        requiresAdminApproval: true,
        sandboxOnly: true,
        modelVersion: 'beta-reality-model-2026.03',
        policyVersion: 'gar-beta-policy-v1',
        metrics: const <String, double>{
          'promotionReadiness': 0.78,
          'driftScore': 0.18,
          'policyViolationCount': 0,
          'approvalConfidence': 0.88,
        },
        tags: const <String>['reality', 'replay', 'sandbox'],
        controlActions: <ResearchControlAction>[
          ResearchControlAction(
            id: 'ctl_reality_seed_01',
            runId: 'gar_beta_reality_01',
            actionType: ResearchControlActionType.approveCharter,
            actorAlias: 'admin_operator',
            rationale: 'Charter approved for beta sandbox.',
            createdAt: now.subtract(const Duration(days: 2)),
            modelVersion: 'beta-reality-model-2026.03',
            policyVersion: 'gar-beta-policy-v1',
            details: const <String, dynamic>{},
          ),
        ],
        checkpoints: <ResearchCheckpoint>[
          ResearchCheckpoint(
            id: 'chk_reality_seed_01',
            runId: 'gar_beta_reality_01',
            summary:
                'Replay-only tuning improved holdout score without violations.',
            state: ResearchRunLifecycleState.running,
            createdAt: now.subtract(const Duration(hours: 2)),
            metricSnapshot: const <String, double>{
              'promotionReadiness': 0.78,
              'driftScore': 0.18,
            },
            artifactIds: const <String>[],
            requiresHumanReview: false,
            contradictionDetected: false,
          ),
        ],
        approvals: <ResearchApproval>[
          ResearchApproval(
            id: 'apr_reality_seed_01',
            runId: 'gar_beta_reality_01',
            kind: ResearchApprovalKind.charter,
            status: ResearchApprovalStatus.approved,
            createdAt: now.subtract(const Duration(days: 2)),
            actorAlias: 'admin_operator',
            decidedAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        artifacts: const <ResearchArtifactRef>[],
        alerts: const <ResearchAlert>[],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        latestExplanation: ResearchExplanation(
          id: 'exp_reality_seed_01',
          runId: 'gar_beta_reality_01',
          summary:
              'The sandbox worker is comparing internal ledgers and replay traces only.',
          currentStep: 'Evaluating replay-only evidence.',
          rationale:
              'Internal evidence remains sufficient; open-web access has not been requested.',
          nextStep: 'Checkpoint again after the next replay batch.',
          evidenceSummary:
              'Using replay holdouts, internal ledgers, and approved local artifacts.',
          createdAt: now.subtract(const Duration(hours: 2)),
          checkpointId: 'chk_reality_seed_01',
        ),
        latestSandboxProjection: ResearchSandboxResultProjection(
          runId: 'gar_beta_reality_01',
          checkpointId: 'chk_reality_seed_01',
          summary:
              'Sanitized replay results available for model-side consumption.',
          metrics: const <String, double>{
            'promotionReadiness': 0.78,
            'driftScore': 0.18,
          },
          createdAt: now.subtract(const Duration(hours: 2)),
          promotionCandidate: false,
          safeForModelConsumption: true,
          violationCount: 0,
        ),
        lastHeartbeatAt: now.subtract(const Duration(minutes: 30)),
        activeCheckpointId: 'chk_reality_seed_01',
      ),
      ResearchRunState(
        id: 'gar_beta_world_01',
        title: 'World agent route contradiction probe',
        hypothesis:
            'Temporal route weighting reduces contradiction frequency in sandbox path generation.',
        layer: ResearchLayer.world,
        ownerAgentAlias: 'world_worker_b',
        lifecycleState: ResearchRunLifecycleState.draft,
        humanAccess: ResearchHumanAccess.adminOnly,
        visibilityScope: ResearchVisibilityScope.runtimeInternalProjection,
        lane: ResearchRunLane.sandboxReplay,
        charter: ResearchCharter(
          id: 'charter_world_01',
          title: 'World agent route contradiction probe',
          objective:
              'Reduce contradiction-triggered auto-pauses during route simulation.',
          hypothesis:
              'Temporal route weighting reduces invalid branch selection.',
          allowedExperimentSurfaces: const <String>[
            'sandbox_route_ranker',
            'route_confidence_thresholds',
          ],
          successMetrics: const <String>[
            'contradictionRate <= 0.05',
            'promotionReadiness >= 0.75',
          ],
          stopConditions: const <String>['contradiction_detected'],
          hardBans: const <String>[
            'production_mutation',
            'consumer_surface_access',
          ],
          createdAt: now.subtract(const Duration(hours: 10)),
          updatedAt: now.subtract(const Duration(hours: 10)),
        ),
        egressMode: ResearchEgressMode.internalOnly,
        requiresAdminApproval: true,
        sandboxOnly: true,
        modelVersion: 'beta-world-model-2026.03',
        policyVersion: 'gar-beta-policy-v1',
        metrics: const <String, double>{
          'promotionReadiness': 0.34,
          'contradictionRate': 0.12,
          'policyViolationCount': 0,
        },
        tags: const <String>['world', 'routes', 'contradiction'],
        controlActions: const <ResearchControlAction>[],
        checkpoints: const <ResearchCheckpoint>[],
        approvals: const <ResearchApproval>[],
        artifacts: const <ResearchArtifactRef>[],
        alerts: const <ResearchAlert>[],
        createdAt: now.subtract(const Duration(hours: 10)),
        updatedAt: now.subtract(const Duration(hours: 10)),
      ),
    ];
  }
}

class _SupabaseGovernedAutoresearchStore
    implements GovernedAutoresearchSupervisor {
  _SupabaseGovernedAutoresearchStore({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  static const String _runsTable = 'admin_research_runs';
  static const String _controlActionsTable = 'admin_research_control_actions';
  static const String _checkpointsTable = 'admin_research_checkpoints';
  static const String _approvalsTable = 'admin_research_approvals';
  static const String _artifactsTable = 'admin_research_artifacts';
  static const String _alertsTable = 'admin_research_alerts';

  final SupabaseService _supabaseService;

  Future<bool> canConnect() async {
    try {
      if (!_supabaseService.isAvailable) {
        return false;
      }
      await _supabaseService.client.from(_runsTable).select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<ResearchRunState>> watchRuns() async* {
    yield await listRuns();
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      return;
    }

    final controller = StreamController<List<ResearchRunState>>();

    Future<void> emit() async {
      try {
        controller.add(await listRuns());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    final subscriptions = <StreamSubscription<dynamic>>[
      client.from(_runsTable).stream(primaryKey: ['id']).listen((_) => emit()),
      client
          .from(_controlActionsTable)
          .stream(primaryKey: ['id']).listen((_) => emit()),
      client
          .from(_checkpointsTable)
          .stream(primaryKey: ['id']).listen((_) => emit()),
      client
          .from(_approvalsTable)
          .stream(primaryKey: ['id']).listen((_) => emit()),
      client
          .from(_artifactsTable)
          .stream(primaryKey: ['id']).listen((_) => emit()),
      client
          .from(_alertsTable)
          .stream(primaryKey: ['id']).listen((_) => emit()),
    ];

    controller.onCancel = () async {
      for (final StreamSubscription<dynamic> subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    yield* controller.stream;
  }

  @override
  Future<List<ResearchRunState>> listRuns() async {
    final client = _supabaseService.client;
    final runRows = await client
        .from(_runsTable)
        .select('*')
        .order('updated_at', ascending: false);
    final runs = (runRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (runs.isEmpty) {
      return const <ResearchRunState>[];
    }

    final runIds = runs
        .map((Map<String, dynamic> row) => row['id']?.toString())
        .whereType<String>()
        .toSet();

    final controlRows = await client
        .from(_controlActionsTable)
        .select('*')
        .order('created_at', ascending: true);
    final checkpointRows = await client
        .from(_checkpointsTable)
        .select('*')
        .order('created_at', ascending: true);
    final approvalRows = await client
        .from(_approvalsTable)
        .select('*')
        .order('created_at', ascending: true);
    final artifactRows = await client
        .from(_artifactsTable)
        .select('*')
        .order('created_at', ascending: true);
    final alertRows = await client
        .from(_alertsTable)
        .select('*')
        .order('created_at', ascending: false);

    final controlsByRun = <String, List<ResearchControlAction>>{};
    for (final dynamic row in controlRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final runId = row['run_id']?.toString() ?? '';
      if (!runIds.contains(runId)) {
        continue;
      }
      controlsByRun.putIfAbsent(runId, () => <ResearchControlAction>[]).add(
            ResearchControlAction.fromJson(<String, dynamic>{
              'id': row['id'],
              'runId': runId,
              'actionType': row['action_type'],
              'actorAlias': row['actor_alias'],
              'rationale': row['rationale'],
              'createdAt': row['created_at'],
              'modelVersion': row['model_version'],
              'policyVersion': row['policy_version'],
              'details': row['details'],
              'checkpointId': row['checkpoint_id'],
            }),
          );
    }

    final checkpointsByRun = <String, List<ResearchCheckpoint>>{};
    for (final dynamic row in checkpointRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final runId = row['run_id']?.toString() ?? '';
      if (!runIds.contains(runId)) {
        continue;
      }
      checkpointsByRun.putIfAbsent(runId, () => <ResearchCheckpoint>[]).add(
            ResearchCheckpoint.fromJson(<String, dynamic>{
              'id': row['id'],
              'runId': runId,
              'summary': row['summary'],
              'state': row['state'],
              'createdAt': row['created_at'],
              'metricSnapshot': row['metric_snapshot'],
              'artifactIds': row['artifact_ids'],
              'requiresHumanReview': row['requires_human_review'],
              'contradictionDetected': row['contradiction_detected'],
            }),
          );
    }

    final approvalsByRun = <String, List<ResearchApproval>>{};
    for (final dynamic row in approvalRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final runId = row['run_id']?.toString() ?? '';
      if (!runIds.contains(runId)) {
        continue;
      }
      approvalsByRun.putIfAbsent(runId, () => <ResearchApproval>[]).add(
            ResearchApproval.fromJson(<String, dynamic>{
              'id': row['id'],
              'runId': runId,
              'kind': row['kind'],
              'status': row['status'],
              'createdAt': row['created_at'],
              'actorAlias': row['actor_alias'],
              'reason': row['reason'],
              'decidedAt': row['decided_at'],
              'expiresAt': row['expires_at'],
            }),
          );
    }

    final artifactsByRun = <String, List<ResearchArtifactRef>>{};
    for (final dynamic row in artifactRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final runId = row['run_id']?.toString() ?? '';
      if (!runIds.contains(runId)) {
        continue;
      }
      artifactsByRun.putIfAbsent(runId, () => <ResearchArtifactRef>[]).add(
            ResearchArtifactRef.fromJson(<String, dynamic>{
              'id': row['id'],
              'runId': runId,
              'kind': row['kind'],
              'storageKey': row['storage_key'],
              'summary': row['summary'],
              'createdAt': row['created_at'],
              'isRedacted': row['is_redacted'],
              'checksum': row['checksum'],
              'expiresAt': row['expires_at'],
            }),
          );
    }

    final alertsByRun = <String, List<ResearchAlert>>{};
    for (final dynamic row in alertRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final runId = row['run_id']?.toString() ?? '';
      if (!runIds.contains(runId)) {
        continue;
      }
      alertsByRun.putIfAbsent(runId, () => <ResearchAlert>[]).add(
            ResearchAlert.fromJson(<String, dynamic>{
              'id': row['id'],
              'runId': runId,
              'severity': row['severity'],
              'title': row['title'],
              'message': row['message'],
              'createdAt': row['created_at'],
            }),
          );
    }

    return runs.map((Map<String, dynamic> row) {
      final runId = row['id']?.toString() ?? '';
      return ResearchRunState.fromJson(<String, dynamic>{
        'id': runId,
        'title': row['title'],
        'hypothesis': row['hypothesis'],
        'layer': row['layer'],
        'ownerAgentAlias': row['owner_agent_alias'],
        'lifecycleState': row['lifecycle_state'],
        'humanAccess': row['human_access'],
        'visibilityScope': row['visibility_scope'],
        'lane': row['lane'],
        'charter': row['charter'],
        'egressMode': row['egress_mode'],
        'requiresAdminApproval': row['requires_admin_approval'],
        'sandboxOnly': row['sandbox_only'],
        'modelVersion': row['model_version'],
        'policyVersion': row['policy_version'],
        'metrics': row['metrics'],
        'tags': row['tags'],
        'controlActions':
            controlsByRun[runId]?.map((item) => item.toJson()).toList() ??
                const <Map<String, dynamic>>[],
        'checkpoints':
            checkpointsByRun[runId]?.map((item) => item.toJson()).toList() ??
                const <Map<String, dynamic>>[],
        'approvals':
            approvalsByRun[runId]?.map((item) => item.toJson()).toList() ??
                const <Map<String, dynamic>>[],
        'artifacts':
            artifactsByRun[runId]?.map((item) => item.toJson()).toList() ??
                const <Map<String, dynamic>>[],
        'alerts': alertsByRun[runId]?.map((item) => item.toJson()).toList() ??
            const <Map<String, dynamic>>[],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
        'latestExplanation': row['latest_explanation'],
        'latestSandboxProjection': row['latest_sandbox_projection'],
        'lastHeartbeatAt': row['last_heartbeat_at'],
        'activeCheckpointId': row['active_checkpoint_id'],
        'redirectDirective': row['redirect_directive'],
        'contradictionDetected': row['contradiction_detected'],
        'killSwitchActive': row['kill_switch_active'],
      });
    }).toList(growable: false);
  }

  @override
  Future<ResearchRunState?> watchRun(String runId) async {
    final runs = await listRuns();
    for (final ResearchRunState run in runs) {
      if (run.id == runId) {
        return run;
      }
    }
    return null;
  }

  @override
  Future<List<ResearchAlert>> listAlerts() async {
    final runs = await listRuns();
    final alerts = <ResearchAlert>[];
    for (final ResearchRunState run in runs) {
      alerts.addAll(run.alerts);
    }
    return alerts;
  }

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final updatedCharter = run.charter.copyWith(
      approvedBy: actorAlias,
      approvedAt: now,
      updatedAt: now,
    );
    final updated = run.copyWith(
      charter: updatedCharter,
      lifecycleState: ResearchRunLifecycleState.approved,
      updatedAt: now,
    );
    await _writeApproval(
      ResearchApproval(
        id: _generateId('apr'),
        runId: runId,
        kind: ResearchApprovalKind.charter,
        status: ResearchApprovalStatus.approved,
        createdAt: now,
        actorAlias: actorAlias,
        reason: rationale,
        decidedAt: now,
      ),
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.approveCharter,
        rationale: rationale.isEmpty ? 'Charter approved.' : rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final updated = run.copyWith(
      lifecycleState: ResearchRunLifecycleState.archived,
      updatedAt: now,
    );
    await _writeApproval(
      ResearchApproval(
        id: _generateId('apr'),
        runId: runId,
        kind: ResearchApprovalKind.charter,
        status: ResearchApprovalStatus.rejected,
        createdAt: now,
        actorAlias: actorAlias,
        reason: rationale,
        decidedAt: now,
      ),
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.reviewCandidate,
        rationale: rationale.isEmpty ? 'Charter rejected.' : rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) async {
    return _writeLifecycleTransition(
      runId: runId,
      actorAlias: actorAlias,
      nextState: ResearchRunLifecycleState.queued,
      actionType: ResearchControlActionType.queueRun,
      rationale: 'Queued for sandbox execution.',
    );
  }

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) async {
    return _writeLifecycleTransition(
      runId: runId,
      actorAlias: actorAlias,
      nextState: ResearchRunLifecycleState.running,
      actionType: ResearchControlActionType.queueRun,
      rationale: 'Sandbox run started.',
    );
  }

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    final run = await _writeLifecycleTransition(
      runId: runId,
      actorAlias: actorAlias,
      nextState: ResearchRunLifecycleState.paused,
      actionType: ResearchControlActionType.pauseRun,
      rationale:
          rationale.isEmpty ? 'Paused at the next safe checkpoint.' : rationale,
    );
    await checkpointRun(
      runId: runId,
      actorAlias: actorAlias,
      summary: 'Operator pause checkpoint',
      metricSnapshot: run.metrics,
    );
    return _requireRun(runId);
  }

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) {
    return _writeLifecycleTransition(
      runId: runId,
      actorAlias: actorAlias,
      nextState: ResearchRunLifecycleState.running,
      actionType: ResearchControlActionType.resumeRun,
      rationale: 'Resumed from checkpoint.',
    );
  }

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    return _writeLifecycleTransition(
      runId: runId,
      actorAlias: actorAlias,
      nextState: ResearchRunLifecycleState.stopped,
      actionType: ResearchControlActionType.stopRun,
      rationale: rationale.isEmpty ? 'Stopped by admin.' : rationale,
    );
  }

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final updated = run.copyWith(
      lifecycleState: ResearchRunLifecycleState.redirectPending,
      redirectDirective: directive,
      updatedAt: now,
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.redirectRun,
        rationale: directive,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final explanation = ResearchExplanation(
      id: _generateId('exp'),
      runId: run.id,
      summary:
          '${run.title} is in ${run.lifecycleState.name} and remains sandbox-only.',
      currentStep: _currentStepForState(run.lifecycleState),
      rationale: run.redirectDirective ?? run.charter.objective,
      nextStep: _nextStepForState(run.lifecycleState),
      evidenceSummary: _evidenceSummary(run),
      createdAt: now,
      checkpointId: run.activeCheckpointId,
    );
    await _writeRun(
      run.copyWith(
        latestExplanation: explanation,
        updatedAt: now,
      ),
    );
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.requestExplanation,
        rationale: 'Generated explanation.',
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return explanation;
  }

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final hasPendingEgress = run.approvals.any(
      (approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb &&
          approval.status == ResearchApprovalStatus.pending,
    );
    final status = approved
        ? ResearchApprovalStatus.approved
        : ResearchApprovalStatus.rejected;
    await _writeApproval(
      ResearchApproval(
        id: _generateId('apr'),
        runId: run.id,
        kind: hasPendingEgress
            ? ResearchApprovalKind.egressOpenWeb
            : ResearchApprovalKind.reviewDisposition,
        status: status,
        createdAt: now,
        actorAlias: actorAlias,
        reason: rationale,
        decidedAt: now,
        expiresAt: hasPendingEgress && approved
            ? now.add(const Duration(hours: 4))
            : null,
      ),
    );
    final updated = run.copyWith(
      lifecycleState: hasPendingEgress
          ? run.lifecycleState
          : approved
              ? ResearchRunLifecycleState.completed
              : ResearchRunLifecycleState.archived,
      egressMode: hasPendingEgress && approved
          ? ResearchEgressMode.brokeredOpenWeb
          : run.egressMode,
      updatedAt: now,
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.reviewCandidate,
        rationale: rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.appendNote,
        rationale: note,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return run.copyWith(updatedAt: now);
  }

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final checkpoint = _buildCheckpoint(
      runId: run.id,
      state: requiresHumanReview || contradictionDetected
          ? ResearchRunLifecycleState.review
          : run.lifecycleState,
      summary: summary,
      metricSnapshot: metricSnapshot.isEmpty ? run.metrics : metricSnapshot,
      createdAt: now,
      requiresHumanReview: requiresHumanReview,
      contradictionDetected: contradictionDetected,
    );
    await _supabaseService.client
        .from(_checkpointsTable)
        .insert(<String, dynamic>{
      'id': checkpoint.id,
      'run_id': checkpoint.runId,
      'summary': checkpoint.summary,
      'state': checkpoint.state.name,
      'created_at': checkpoint.createdAt.toIso8601String(),
      'metric_snapshot': checkpoint.metricSnapshot,
      'artifact_ids': checkpoint.artifactIds,
      'requires_human_review': checkpoint.requiresHumanReview,
      'contradiction_detected': checkpoint.contradictionDetected,
    });
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.checkpointRun,
        rationale: summary,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
        checkpointId: checkpoint.id,
      ),
    );
    await _writeRun(
      run.copyWith(
        latestSandboxProjection: ResearchSandboxResultProjection(
          runId: run.id,
          checkpointId: checkpoint.id,
          summary: summary,
          metrics: checkpoint.metricSnapshot,
          createdAt: now,
          promotionCandidate:
              (checkpoint.metricSnapshot['promotionReadiness'] ?? 0) >= 0.8,
          safeForModelConsumption: true,
          violationCount: contradictionDetected ? 1 : 0,
        ),
        activeCheckpointId: checkpoint.id,
        contradictionDetected: contradictionDetected,
        lifecycleState: requiresHumanReview || contradictionDetected
            ? ResearchRunLifecycleState.review
            : run.lifecycleState,
        updatedAt: now,
        lastHeartbeatAt: now,
      ),
    );
    return checkpoint;
  }

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final artifact = ResearchArtifactRef(
      id: _generateId('art'),
      runId: runId,
      kind: kind,
      storageKey: storageKey,
      summary: summary,
      createdAt: now,
      isRedacted: isRedacted,
      checksum: checksum,
      expiresAt: kind == ResearchArtifactKind.evidenceBundle
          ? now.add(const Duration(hours: 4))
          : null,
    );
    await _supabaseService.client
        .from(_artifactsTable)
        .insert(<String, dynamic>{
      'id': artifact.id,
      'run_id': artifact.runId,
      'kind': artifact.kind.name,
      'storage_key': artifact.storageKey,
      'summary': artifact.summary,
      'created_at': artifact.createdAt.toIso8601String(),
      'is_redacted': artifact.isRedacted,
      'checksum': artifact.checksum,
      'expires_at': artifact.expiresAt?.toIso8601String(),
    });
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.appendNote,
        rationale: 'Artifact appended: ${kind.name}',
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
        details: <String, dynamic>{'storageKey': storageKey},
      ),
    );
    return artifact;
  }

  @override
  Future<void> emitAlert(ResearchAlert alert) async {
    await _supabaseService.client.from(_alertsTable).insert(<String, dynamic>{
      'id': alert.id,
      'run_id': alert.runId,
      'severity': alert.severity.name,
      'title': alert.title,
      'message': alert.message,
      'created_at': alert.createdAt.toIso8601String(),
    });
  }

  @override
  Future<ResearchApproval> requestEgressApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
  }) {
    return requestOpenWebAccess(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchApproval> requestOpenWebAccess({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final now = DateTime.now().toUtc();
    final approval = ResearchApproval(
      id: _generateId('apr'),
      runId: runId,
      kind: ResearchApprovalKind.egressOpenWeb,
      status: ResearchApprovalStatus.pending,
      createdAt: now,
      actorAlias: actorAlias,
      reason: rationale,
      expiresAt: now.add(ttl),
    );
    await _writeApproval(approval);
    final run = await _requireRun(runId);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.requestEgressApproval,
        rationale: rationale.isEmpty
            ? 'Open-web access requested after internal evidence exhaustion.'
            : rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return approval;
  }

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) async {
    final updated = await reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: true,
      rationale: rationale.isEmpty
          ? 'Brokered open-web access approved by dual control.'
          : rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
    return updated.approvals.lastWhere(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb,
    );
  }

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final updated = await reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: false,
      rationale:
          rationale.isEmpty ? 'Brokered open-web access denied.' : rationale,
      stepUpProof: stepUpProof,
    );
    return updated.approvals.lastWhere(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb,
    );
  }

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) async {
    final run = await _requireRun(runId);
    final isOpenWeb = sourceUri.scheme == 'http' || sourceUri.scheme == 'https';
    if (isOpenWeb && !run.hasApprovedOpenWebAccess) {
      throw GovernedAutoresearchActionBlockedException(
        'Open-web access has not been approved for this run.',
      );
    }
    return appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: ResearchArtifactKind.evidenceBundle,
      storageKey: isOpenWeb
          ? "broker://quarantine/$runId/${_generateId('evidence')}"
          : "internal://evidence/$runId/${_generateId('evidence')}",
      summary: isOpenWeb
          ? 'Brokered outbound fetch completed and payload quarantined.'
          : 'Internal evidence bundle staged.',
      isRedacted: true,
    );
  }

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    final now = DateTime.now().toUtc();
    await _writeApproval(
      ResearchApproval(
        id: _generateId('apr'),
        runId: runId,
        kind: ResearchApprovalKind.egressOpenWeb,
        status: ResearchApprovalStatus.revoked,
        createdAt: now,
        actorAlias: actorAlias,
        reason: rationale,
        decidedAt: now,
      ),
    );
    final run = await _requireRun(runId);
    await _writeRun(
      run.copyWith(
        egressMode: ResearchEgressMode.internalOnly,
        updatedAt: now,
      ),
    );
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.revokeEgressApproval,
        rationale: rationale.isEmpty ? 'Brokered access revoked.' : rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
  }

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final summary =
        'Signed redacted evidence pack for ${artifactIds.length} artifacts.';
    return appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: ResearchArtifactKind.signedEvidencePack,
      storageKey: 'evidence-pack://$runId/${_generateId('pack')}',
      summary: summary,
      isRedacted: true,
      checksum: base64Url.encode(utf8.encode('$runId:$artifactIds:$summary')),
    );
  }

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) async {
    final now = DateTime.now().toUtc();
    final approval = ResearchApproval(
      id: _generateId('apr'),
      runId: runId,
      kind: ResearchApprovalKind.reviewDisposition,
      status: approved
          ? ResearchApprovalStatus.approved
          : ResearchApprovalStatus.rejected,
      createdAt: now,
      actorAlias: actorAlias,
      reason: rationale,
      decidedAt: now,
    );
    await _writeApproval(approval);
    return approval;
  }

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final updated = run.copyWith(
      killSwitchActive: true,
      lifecycleState: ResearchRunLifecycleState.stopped,
      updatedAt: now,
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: ResearchControlActionType.triggerKillSwitch,
        rationale: rationale.isEmpty ? 'Break-glass kill switch.' : rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  Future<ResearchRunState> _writeLifecycleTransition({
    required String runId,
    required String actorAlias,
    required ResearchRunLifecycleState nextState,
    required ResearchControlActionType actionType,
    required String rationale,
  }) async {
    final run = await _requireRun(runId);
    final now = DateTime.now().toUtc();
    final updated = run.copyWith(
      lifecycleState: nextState,
      updatedAt: now,
      lastHeartbeatAt: nextState == ResearchRunLifecycleState.running
          ? now
          : run.lastHeartbeatAt,
    );
    await _writeRun(updated);
    await _writeControlAction(
      _buildControlAction(
        runId: runId,
        actorAlias: actorAlias,
        actionType: actionType,
        rationale: rationale,
        createdAt: now,
        modelVersion: run.modelVersion,
        policyVersion: run.policyVersion,
      ),
    );
    return updated;
  }

  Future<void> _writeRun(ResearchRunState run) async {
    await _supabaseService.client.from(_runsTable).upsert(<String, dynamic>{
      'id': run.id,
      'title': run.title,
      'hypothesis': run.hypothesis,
      'layer': run.layer.name,
      'owner_agent_alias': run.ownerAgentAlias,
      'lifecycle_state': run.lifecycleState.name,
      'human_access': run.humanAccess.name,
      'visibility_scope': run.visibilityScope.name,
      'lane': run.lane.name,
      'charter': run.charter.toJson(),
      'egress_mode': run.egressMode.name,
      'requires_admin_approval': run.requiresAdminApproval,
      'sandbox_only': run.sandboxOnly,
      'model_version': run.modelVersion,
      'policy_version': run.policyVersion,
      'metrics': run.metrics,
      'tags': run.tags,
      'created_at': run.createdAt.toIso8601String(),
      'updated_at': run.updatedAt.toIso8601String(),
      'latest_explanation': run.latestExplanation?.toJson(),
      'latest_sandbox_projection': run.latestSandboxProjection?.toJson(),
      'last_heartbeat_at': run.lastHeartbeatAt?.toIso8601String(),
      'active_checkpoint_id': run.activeCheckpointId,
      'redirect_directive': run.redirectDirective,
      'contradiction_detected': run.contradictionDetected,
      'kill_switch_active': run.killSwitchActive,
    });
  }

  Future<void> _writeControlAction(ResearchControlAction action) async {
    await _supabaseService.client
        .from(_controlActionsTable)
        .insert(<String, dynamic>{
      'id': action.id,
      'run_id': action.runId,
      'action_type': action.actionType.name,
      'actor_alias': action.actorAlias,
      'rationale': action.rationale,
      'created_at': action.createdAt.toIso8601String(),
      'model_version': action.modelVersion,
      'policy_version': action.policyVersion,
      'details': action.details,
      'checkpoint_id': action.checkpointId,
    });
  }

  Future<void> _writeApproval(ResearchApproval approval) async {
    await _supabaseService.client
        .from(_approvalsTable)
        .insert(<String, dynamic>{
      'id': approval.id,
      'run_id': approval.runId,
      'kind': approval.kind.name,
      'status': approval.status.name,
      'created_at': approval.createdAt.toIso8601String(),
      'actor_alias': approval.actorAlias,
      'reason': approval.reason,
      'decided_at': approval.decidedAt?.toIso8601String(),
      'expires_at': approval.expiresAt?.toIso8601String(),
    });
  }

  Future<ResearchRunState> _requireRun(String runId) async {
    final run = await watchRun(runId);
    if (run == null) {
      throw GovernedAutoresearchActionBlockedException(
        'Unknown research run: $runId',
      );
    }
    return run;
  }
}

class SupabaseAdminControlPlaneGateway implements AdminControlPlaneGateway {
  SupabaseAdminControlPlaneGateway({
    required SupabaseService supabaseService,
    required SharedPreferencesCompat auditPrefs,
  })  : _auditPrefs = auditPrefs,
        _store = _SupabaseGovernedAutoresearchStore(
          supabaseService: supabaseService,
        );

  static const String _auditLogKey =
      'admin.control_plane.audit_events.governed_autoresearch.v1';
  static const String _sessionsTable = 'admin_control_plane_sessions';
  static const String _auditTable = 'admin_control_plane_audit_events';
  static const String _policyTable = 'admin_control_plane_policy_decisions';

  final SharedPreferencesCompat _auditPrefs;
  final _SupabaseGovernedAutoresearchStore _store;
  AdminControlPlaneSessionGrant? _activeSession;

  @override
  bool get hasActiveSession =>
      _activeSession != null && !_activeSession!.isExpired;

  @override
  AdminControlPlaneSessionGrant? get activeSession =>
      hasActiveSession ? _activeSession : null;

  @override
  Future<bool> canConnect() async {
    final connected = await _store.canConnect();
    if (!connected) {
      return false;
    }
    try {
      await _store._supabaseService.client
          .from(_sessionsTable)
          .select('id')
          .limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AdminControlPlaneSessionGrant> createSession({
    required AdminControlPlaneSessionRequest request,
  }) async {
    _validateSessionRequest(request);
    final now = DateTime.now().toUtc();
    final grant = AdminControlPlaneSessionGrant(
      sessionToken: base64Url.encode(
        utf8.encode(
            '${request.operatorAlias}:${request.deviceAttestation.deviceId}:${now.microsecondsSinceEpoch}'),
      ),
      sessionTokenId: _generateId('cp_session'),
      actorAlias: request.operatorAlias,
      role: AdminControlPlaneRole.adminOperator,
      expiresAt: now.add(const Duration(minutes: 60)),
      issuedBy: 'private_admin_control_plane_gateway',
      policyVersion: 'opa-gar-beta-v1',
      deviceId: request.deviceAttestation.deviceId,
      meshIdentity: request.deviceAttestation.meshIdentity,
      clientCertificateFingerprint:
          request.deviceAttestation.clientCertificateFingerprint,
      requiresPrivateControlPlane: true,
    );
    _activeSession = grant;
    await _recordSession(grant, request.deviceAttestation);
    await _appendAudit(
      action: 'create_session',
      actorAlias: request.operatorAlias,
      stepUpSatisfied: false,
      details: <String, dynamic>{
        'meshIdentity': request.deviceAttestation.meshIdentity,
        'deviceId': request.deviceAttestation.deviceId,
        'platform': request.deviceAttestation.platform,
        'role': grant.role.name,
      },
    );
    return grant;
  }

  @override
  Future<void> revokeActiveSession() async {
    final session = _activeSession;
    _activeSession = null;
    if (session == null) {
      return;
    }
    await _appendAudit(
      action: 'revoke_session',
      actorAlias: session.actorAlias,
      stepUpSatisfied: false,
      details: <String, dynamic>{'sessionTokenId': session.sessionTokenId},
    );
  }

  @override
  Stream<List<ResearchRunState>> watchResearchRuns() async* {
    _requireActiveSession();
    await for (final runs in _store.watchRuns()) {
      yield runs.map(_sanitizeRunForAdmin).toList(growable: false);
    }
  }

  @override
  Future<List<ResearchRunState>> listResearchRuns() async {
    _requireActiveSession();
    final runs = await _store.listRuns();
    return runs.map(_sanitizeRunForAdmin).toList(growable: false);
  }

  @override
  Future<ResearchRunState?> watchResearchRun(String runId) async {
    _requireActiveSession();
    final run = await _store.watchRun(runId);
    return run == null ? null : _sanitizeRunForAdmin(run);
  }

  @override
  Future<List<ResearchAlert>> listResearchAlerts() async {
    _requireActiveSession();
    return _store.listAlerts();
  }

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    _requireActiveSession();
    final run = await _store.approveCharter(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
    await _appendRunAudit(
      run: run,
      action: 'approve_charter',
      actorAlias: actorAlias,
      rationale: rationale,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    _requireActiveSession();
    final run = await _store.rejectCharter(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
    await _appendRunAudit(
      run: run,
      action: 'reject_charter',
      actorAlias: actorAlias,
      rationale: rationale,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) async {
    _requireActiveSession();
    final run = await _store.queueRun(runId: runId, actorAlias: actorAlias);
    await _appendRunAudit(
      run: run,
      action: 'queue_run',
      actorAlias: actorAlias,
      rationale: 'Queued for sandbox execution.',
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) async {
    _requireActiveSession();
    final run = await _store.startSandboxRun(
      runId: runId,
      actorAlias: actorAlias,
    );
    await _appendRunAudit(
      run: run,
      action: 'start_sandbox_run',
      actorAlias: actorAlias,
      rationale: 'Started sandbox execution.',
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    _requireActiveSession();
    final run = await _store.pauseRun(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
    await _appendRunAudit(
      run: run,
      action: 'pause_run',
      actorAlias: actorAlias,
      rationale: rationale,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) async {
    _requireActiveSession();
    final run = await _store.resumeRun(runId: runId, actorAlias: actorAlias);
    await _appendRunAudit(
      run: run,
      action: 'resume_run',
      actorAlias: actorAlias,
      rationale: 'Resumed from checkpoint.',
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.stopRun,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
    );
    final run = await _store.stopRun(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
    await _appendRunAudit(
      run: run,
      action: 'stop_run',
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpSatisfied: true,
      session: session,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.redirectRun,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
    );
    final run = await _store.redirectRun(
      runId: runId,
      actorAlias: actorAlias,
      directive: directive,
      stepUpProof: stepUpProof,
    );
    await _appendRunAudit(
      run: run,
      action: 'redirect_run',
      actorAlias: actorAlias,
      rationale: directive,
      stepUpSatisfied: true,
      session: session,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) async {
    _requireActiveSession();
    final explanation = await _store.getExplanation(
      runId: runId,
      actorAlias: actorAlias,
    );
    await _appendAudit(
      action: 'get_explanation',
      actorAlias: actorAlias,
      runId: runId,
      checkpointId: explanation.checkpointId,
      stepUpSatisfied: false,
      details: <String, dynamic>{'summary': explanation.summary},
    );
    return explanation;
  }

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.reviewDisposition,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
      secondOperatorApproval: approved ? secondOperatorApproval : null,
      requiresSecondOperator: approved,
    );
    final run = await _store.reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: approved,
      rationale: rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
    await _appendRunAudit(
      run: run,
      action:
          approved ? 'review_candidate_approved' : 'review_candidate_rejected',
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpSatisfied: true,
      session: session,
      secondOperatorApproval: secondOperatorApproval,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) async {
    _requireActiveSession();
    final run = await _store.addOperatorNote(
      runId: runId,
      actorAlias: actorAlias,
      note: note,
    );
    await _appendRunAudit(
      run: run,
      action: 'add_operator_note',
      actorAlias: actorAlias,
      rationale: note,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) async {
    _requireActiveSession();
    final checkpoint = await _store.checkpointRun(
      runId: runId,
      actorAlias: actorAlias,
      summary: summary,
      metricSnapshot: metricSnapshot,
      requiresHumanReview: requiresHumanReview,
      contradictionDetected: contradictionDetected,
    );
    await _appendAudit(
      action: 'checkpoint_run',
      actorAlias: actorAlias,
      runId: runId,
      checkpointId: checkpoint.id,
      stepUpSatisfied: false,
      details: <String, dynamic>{
        'requiresHumanReview': requiresHumanReview,
        'contradictionDetected': contradictionDetected,
      },
    );
    return checkpoint;
  }

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) async {
    _requireActiveSession();
    final artifact = await _store.appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: kind,
      storageKey: storageKey,
      summary: summary,
      isRedacted: isRedacted,
      checksum: checksum,
    );
    await _appendAudit(
      action: 'append_artifact',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: false,
      details: <String, dynamic>{'kind': kind.name, 'storageKey': storageKey},
    );
    return artifact;
  }

  @override
  Future<void> emitAlert(ResearchAlert alert) async {
    _requireActiveSession();
    await _store.emitAlert(alert);
    await _appendAudit(
      action: 'emit_alert',
      actorAlias: activeSession?.actorAlias ?? 'runtime_supervisor',
      runId: alert.runId,
      stepUpSatisfied: false,
      details: <String, dynamic>{
        'severity': alert.severity.name,
        'title': alert.title,
      },
    );
  }

  @override
  Future<ResearchApproval> requestOpenWebApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.approveOpenWeb,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
    );
    final approval = await _store.requestOpenWebAccess(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
    await _appendAudit(
      action: 'request_open_web_approval',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: true,
      session: session,
      details: <String, dynamic>{
        'ttlMinutes': ttl.inMinutes,
        'rationale': rationale
      },
    );
    return approval;
  }

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.approveOpenWeb,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
      requiresSecondOperator: true,
    );
    final approval = await _store.approveOpenWeb(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      rationale: rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
    final run = await _store.watchRun(runId);
    if (run != null) {
      await _appendRunAudit(
        run: run,
        action: 'approve_open_web',
        actorAlias: actorAlias,
        rationale: rationale,
        stepUpSatisfied: true,
        session: session,
        secondOperatorApproval: secondOperatorApproval,
      );
    }
    return approval;
  }

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.approveOpenWeb,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
    );
    final approval = await _store.rejectOpenWeb(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
    final run = await _store.watchRun(runId);
    if (run != null) {
      await _appendRunAudit(
        run: run,
        action: 'reject_open_web',
        actorAlias: actorAlias,
        rationale: rationale,
        stepUpSatisfied: true,
        session: session,
      );
    }
    return approval;
  }

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) async {
    _requireActiveSession();
    final artifact = await _store.fetchEvidence(
      runId: runId,
      actorAlias: actorAlias,
      sourceUri: sourceUri,
    );
    await _appendAudit(
      action: 'fetch_evidence',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: false,
      details: <String, dynamic>{
        'sourceUri': sourceUri.toString(),
        'brokered': sourceUri.scheme == 'http' || sourceUri.scheme == 'https',
      },
    );
    return artifact;
  }

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) async {
    _requireActiveSession();
    await _store.revokeAccess(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
    await _appendAudit(
      action: 'revoke_open_web_access',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: false,
      details: <String, dynamic>{'rationale': rationale},
    );
  }

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) async {
    _requireActiveSession();
    final approval = await _store.recordDisposition(
      runId: runId,
      actorAlias: actorAlias,
      approved: approved,
      rationale: rationale,
    );
    await _appendAudit(
      action: approved
          ? 'record_disposition_approved'
          : 'record_disposition_rejected',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: false,
      details: <String, dynamic>{'rationale': rationale},
    );
    return approval;
  }

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.triggerKillSwitch,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
      requiresSecondOperator: true,
    );
    final run = await _store.triggerKillSwitch(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
    await _appendRunAudit(
      run: run,
      action: 'trigger_kill_switch',
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpSatisfied: true,
      session: session,
      secondOperatorApproval: secondOperatorApproval,
    );
    return _sanitizeRunForAdmin(run);
  }

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) async {
    final session = _requireSensitiveAccess(
      action: AdminControlPlaneSensitiveAction.downloadEvidencePack,
      actorAlias: actorAlias,
      stepUpProof: stepUpProof,
    );
    final artifact = await _store.downloadEvidencePack(
      runId: runId,
      actorAlias: actorAlias,
      artifactIds: artifactIds,
      stepUpProof: stepUpProof,
    );
    await _appendAudit(
      action: 'download_evidence_pack',
      actorAlias: actorAlias,
      runId: runId,
      stepUpSatisfied: true,
      session: session,
      details: <String, dynamic>{'artifactIds': artifactIds},
    );
    return artifact;
  }

  void _validateSessionRequest(AdminControlPlaneSessionRequest request) {
    if (request.oidcAssertion.trim().isEmpty) {
      throw AdminControlPlaneAuthException(
        'OIDC assertion is required for private admin control-plane access.',
      );
    }
    if (request.mfaProof.trim().isEmpty) {
      throw AdminControlPlaneAuthException(
        'MFA proof is required for private admin control-plane access.',
      );
    }
    final attestation = request.deviceAttestation;
    if (!attestation.managedDevice ||
        !attestation.diskEncryptionEnabled ||
        !attestation.osPatchBaselineSatisfied ||
        !attestation.signedDesktopBinary) {
      throw AdminControlPlaneAuthException(
        'Managed, signed desktop clients with compliant posture are required.',
      );
    }
    if (attestation.meshIdentity.trim().isEmpty ||
        attestation.clientCertificateFingerprint.trim().isEmpty) {
      throw AdminControlPlaneAuthException(
        'Private mesh identity and client certificate fingerprint are required.',
      );
    }
    final normalizedGroups = request.allowedGroups
        .map((String group) => group.trim().toLowerCase())
        .toSet();
    if (!normalizedGroups.contains('admin_operator') &&
        !normalizedGroups.contains('admin-operators')) {
      throw AdminControlPlaneAuthException(
        'Only the admin_operator role may access governed autoresearch.',
      );
    }
  }

  AdminControlPlaneSessionGrant _requireActiveSession() {
    final session = activeSession;
    if (session == null) {
      throw GovernedAutoresearchActionBlockedException(
        'Private admin control-plane session is missing or expired.',
      );
    }
    return session;
  }

  AdminControlPlaneSessionGrant _requireSensitiveAccess({
    required AdminControlPlaneSensitiveAction action,
    required String actorAlias,
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
    bool requiresSecondOperator = false,
  }) {
    final session = _requireActiveSession();
    if (stepUpProof == null ||
        stepUpProof.proof.trim().isEmpty ||
        !stepUpProof.isRecent) {
      throw GovernedAutoresearchActionBlockedException(
        'Step-up authentication is required for ${action.name}.',
      );
    }
    if (requiresSecondOperator) {
      if (secondOperatorApproval == null ||
          secondOperatorApproval.actorAlias.trim().isEmpty ||
          secondOperatorApproval.proof.trim().isEmpty ||
          !secondOperatorApproval.isRecent ||
          secondOperatorApproval.actorAlias == actorAlias) {
        throw GovernedAutoresearchActionBlockedException(
          'A second distinct admin_operator approval is required for ${action.name}.',
        );
      }
    }
    _recordPolicyDecision(
      action: action.name,
      actorAlias: actorAlias,
      allowed: true,
      rationale: 'Approved by gateway policy.',
      stepUpSatisfied: true,
      secondOperatorAlias: secondOperatorApproval?.actorAlias,
      session: session,
    );
    return session;
  }

  Future<void> _recordSession(
    AdminControlPlaneSessionGrant grant,
    AdminControlPlaneDeviceAttestation attestation,
  ) async {
    await _store._supabaseService.client.from(_sessionsTable).upsert(
      <String, dynamic>{
        'id': grant.sessionTokenId,
        'actor_alias': grant.actorAlias,
        'role': grant.role.name,
        'issued_by': grant.issuedBy,
        'policy_version': grant.policyVersion,
        'device_id': grant.deviceId,
        'mesh_identity': grant.meshIdentity,
        'client_certificate_fingerprint': grant.clientCertificateFingerprint,
        'expires_at': grant.expiresAt.toIso8601String(),
        'revoked_at': null,
        'device_attestation': attestation.toJson(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  void _recordPolicyDecision({
    required String action,
    required String actorAlias,
    required bool allowed,
    required String rationale,
    required bool stepUpSatisfied,
    required AdminControlPlaneSessionGrant session,
    String? secondOperatorAlias,
  }) {
    unawaited(
      _store._supabaseService.client.from(_policyTable).insert(
        <String, dynamic>{
          'id': _generateId('policy'),
          'session_id': session.sessionTokenId,
          'actor_alias': actorAlias,
          'action': action,
          'allowed': allowed,
          'rationale': rationale,
          'step_up_satisfied': stepUpSatisfied,
          'second_operator_alias': secondOperatorAlias,
          'policy_version': session.policyVersion,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ),
    );
  }

  Future<void> _appendRunAudit({
    required ResearchRunState run,
    required String action,
    required String actorAlias,
    required String rationale,
    bool stepUpSatisfied = false,
    AdminControlPlaneSessionGrant? session,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) {
    return _appendAudit(
      action: action,
      actorAlias: actorAlias,
      runId: run.id,
      checkpointId: run.activeCheckpointId,
      modelVersion: run.modelVersion,
      policyVersion: run.policyVersion,
      stepUpSatisfied: stepUpSatisfied,
      session: session,
      secondOperatorApproval: secondOperatorApproval,
      details: <String, dynamic>{'rationale': rationale},
    );
  }

  Future<void> _appendAudit({
    required String action,
    required String actorAlias,
    required bool stepUpSatisfied,
    String? runId,
    String? checkpointId,
    String? modelVersion,
    String? policyVersion,
    AdminControlPlaneSessionGrant? session,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
    Map<String, dynamic> details = const <String, dynamic>{},
  }) async {
    final sanitizedDetails = AdminPrivacyFilter.filterPersonalData(details);
    final entry = <String, dynamic>{
      'id': _generateId('audit'),
      'action': action,
      'actorAlias': actorAlias,
      'runId': runId,
      'checkpointId': checkpointId,
      'modelVersion': modelVersion,
      'policyVersion': policyVersion ?? activeSession?.policyVersion,
      'deviceId': session?.deviceId ?? activeSession?.deviceId,
      'sessionId': session?.sessionTokenId ?? activeSession?.sessionTokenId,
      'stepUpSatisfied': stepUpSatisfied,
      'secondOperatorAlias': secondOperatorApproval?.actorAlias,
      'details': sanitizedDetails,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final existingRaw = _auditPrefs.getString(_auditLogKey);
    final existing = existingRaw == null || existingRaw.isEmpty
        ? <Map<String, dynamic>>[]
        : (jsonDecode(existingRaw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList(growable: true);
    existing.add(entry);
    await _auditPrefs.setString(_auditLogKey, jsonEncode(existing));
    await _store._supabaseService.client.from(_auditTable).insert(
      <String, dynamic>{
        'id': entry['id'],
        'action': action,
        'actor_alias': actorAlias,
        'run_id': runId,
        'checkpoint_id': checkpointId,
        'model_version': modelVersion,
        'policy_version': policyVersion ?? activeSession?.policyVersion,
        'device_id': session?.deviceId ?? activeSession?.deviceId,
        'session_id': session?.sessionTokenId ?? activeSession?.sessionTokenId,
        'step_up_satisfied': stepUpSatisfied,
        'second_operator_alias': secondOperatorApproval?.actorAlias,
        'details': sanitizedDetails,
        'created_at': entry['createdAt'],
      },
    );
  }

  ResearchRunState _sanitizeRunForAdmin(ResearchRunState run) {
    return run.copyWith(
      controlActions: run.controlActions
          .map(
            (ResearchControlAction action) => ResearchControlAction(
              id: action.id,
              runId: action.runId,
              actionType: action.actionType,
              actorAlias: action.actorAlias,
              rationale: action.rationale,
              createdAt: action.createdAt,
              modelVersion: action.modelVersion,
              policyVersion: action.policyVersion,
              details: AdminPrivacyFilter.filterPersonalData(action.details),
              checkpointId: action.checkpointId,
            ),
          )
          .toList(growable: false),
      artifacts: run.artifacts
          .map(
            (ResearchArtifactRef artifact) => ResearchArtifactRef(
              id: artifact.id,
              runId: artifact.runId,
              kind: artifact.kind,
              storageKey: artifact.storageKey,
              summary: artifact.summary,
              createdAt: artifact.createdAt,
              isRedacted: true,
              checksum: artifact.checksum,
              expiresAt: artifact.expiresAt,
            ),
          )
          .toList(growable: false),
    );
  }
}

class TestAdminControlPlaneGateway implements AdminControlPlaneGateway {
  TestAdminControlPlaneGateway({
    required LocalResearchActivityService delegate,
    required SharedPreferencesCompat auditPrefs,
  })  : _delegate = delegate,
        _auditPrefs = auditPrefs;

  final LocalResearchActivityService _delegate;
  final SharedPreferencesCompat _auditPrefs;
  AdminControlPlaneSessionGrant? _activeSession;

  @override
  bool get hasActiveSession =>
      _activeSession != null && !_activeSession!.isExpired;

  @override
  AdminControlPlaneSessionGrant? get activeSession =>
      hasActiveSession ? _activeSession : null;

  @override
  Future<bool> canConnect() async => true;

  @override
  Future<AdminControlPlaneSessionGrant> createSession({
    required AdminControlPlaneSessionRequest request,
  }) async {
    if (request.oidcAssertion.trim().isEmpty ||
        request.mfaProof.trim().isEmpty) {
      throw AdminControlPlaneAuthException(
          'OIDC assertion and MFA proof are required.');
    }
    final attestation = request.deviceAttestation;
    if (!attestation.managedDevice ||
        !attestation.signedDesktopBinary ||
        attestation.meshIdentity.trim().isEmpty ||
        attestation.clientCertificateFingerprint.trim().isEmpty) {
      throw AdminControlPlaneAuthException(
        'Managed mesh-connected desktop posture is required.',
      );
    }
    final grant = AdminControlPlaneSessionGrant(
      sessionToken: _generateId('local_session_token'),
      sessionTokenId: _generateId('local_session'),
      actorAlias: request.operatorAlias,
      role: AdminControlPlaneRole.adminOperator,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 60)),
      issuedBy: 'local_test_gateway',
      policyVersion: 'opa-gar-beta-v1',
      deviceId: attestation.deviceId,
      meshIdentity: attestation.meshIdentity,
      clientCertificateFingerprint: attestation.clientCertificateFingerprint,
      requiresPrivateControlPlane: true,
    );
    _activeSession = grant;
    await _appendAudit('create_session',
        <String, dynamic>{'actorAlias': request.operatorAlias});
    return grant;
  }

  @override
  Future<void> revokeActiveSession() async {
    _activeSession = null;
  }

  @override
  Stream<List<ResearchRunState>> watchResearchRuns() {
    _requireSession();
    return _delegate.watchRuns();
  }

  @override
  Future<List<ResearchRunState>> listResearchRuns() async {
    _requireSession();
    return _delegate.listRuns();
  }

  @override
  Future<ResearchRunState?> watchResearchRun(String runId) async {
    _requireSession();
    return _delegate.watchRun(runId);
  }

  @override
  Future<List<ResearchAlert>> listResearchAlerts() async {
    _requireSession();
    return _delegate.listAlerts();
  }

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) {
    _requireSession();
    return _delegate.approveCharter(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) {
    _requireSession();
    return _delegate.rejectCharter(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) {
    _requireSession();
    return _delegate.queueRun(runId: runId, actorAlias: actorAlias);
  }

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) {
    _requireSession();
    return _delegate.startSandboxRun(runId: runId, actorAlias: actorAlias);
  }

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) {
    _requireSession();
    return _delegate.pauseRun(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) {
    _requireSession();
    return _delegate.resumeRun(runId: runId, actorAlias: actorAlias);
  }

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    _requireSensitive(stepUpProof: stepUpProof);
    return _delegate.stopRun(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
  }

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    _requireSensitive(stepUpProof: stepUpProof);
    return _delegate.redirectRun(
      runId: runId,
      actorAlias: actorAlias,
      directive: directive,
      stepUpProof: stepUpProof,
    );
  }

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) {
    _requireSession();
    return _delegate.getExplanation(runId: runId, actorAlias: actorAlias);
  }

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) {
    _requireSensitive(
      stepUpProof: stepUpProof,
      requiresSecondOperator: approved,
      secondOperatorApproval: secondOperatorApproval,
      actorAlias: actorAlias,
    );
    return _delegate.reviewCandidate(
      runId: runId,
      actorAlias: actorAlias,
      approved: approved,
      rationale: rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
  }

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) {
    _requireSession();
    return _delegate.addOperatorNote(
      runId: runId,
      actorAlias: actorAlias,
      note: note,
    );
  }

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) {
    _requireSession();
    return _delegate.checkpointRun(
      runId: runId,
      actorAlias: actorAlias,
      summary: summary,
      metricSnapshot: metricSnapshot,
      requiresHumanReview: requiresHumanReview,
      contradictionDetected: contradictionDetected,
    );
  }

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) {
    _requireSession();
    return _delegate.appendArtifact(
      runId: runId,
      actorAlias: actorAlias,
      kind: kind,
      storageKey: storageKey,
      summary: summary,
      isRedacted: isRedacted,
      checksum: checksum,
    );
  }

  @override
  Future<void> emitAlert(ResearchAlert alert) {
    _requireSession();
    return _delegate.emitAlert(alert);
  }

  @override
  Future<ResearchApproval> requestOpenWebApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    _requireSensitive(stepUpProof: stepUpProof);
    return _delegate.requestOpenWebAccess(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
  }

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) {
    _requireSensitive(
      stepUpProof: stepUpProof,
      requiresSecondOperator: true,
      secondOperatorApproval: secondOperatorApproval,
      actorAlias: actorAlias,
    );
    return _delegate.approveOpenWeb(
      runId: runId,
      actorAlias: actorAlias,
      ttl: ttl,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    _requireSensitive(stepUpProof: stepUpProof);
    return _delegate.rejectOpenWeb(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
    );
  }

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) {
    _requireSession();
    return _delegate.fetchEvidence(
      runId: runId,
      actorAlias: actorAlias,
      sourceUri: sourceUri,
    );
  }

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) {
    _requireSession();
    return _delegate.revokeAccess(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) {
    _requireSession();
    return _delegate.recordDisposition(
      runId: runId,
      actorAlias: actorAlias,
      approved: approved,
      rationale: rationale,
    );
  }

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
  }) {
    _requireSensitive(
      stepUpProof: stepUpProof,
      requiresSecondOperator: true,
      secondOperatorApproval: secondOperatorApproval,
      actorAlias: actorAlias,
    );
    return _delegate.triggerKillSwitch(
      runId: runId,
      actorAlias: actorAlias,
      rationale: rationale,
      stepUpProof: stepUpProof,
      secondOperatorApproval: secondOperatorApproval,
    );
  }

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) {
    _requireSensitive(stepUpProof: stepUpProof);
    return _delegate.downloadEvidencePack(
      runId: runId,
      actorAlias: actorAlias,
      artifactIds: artifactIds,
      stepUpProof: stepUpProof,
    );
  }

  void _requireSession() {
    if (!hasActiveSession) {
      throw GovernedAutoresearchActionBlockedException(
        'Private admin control-plane session is missing or expired.',
      );
    }
  }

  void _requireSensitive({
    required AdminControlPlaneStepUpProof? stepUpProof,
    bool requiresSecondOperator = false,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
    String actorAlias = 'admin_operator',
  }) {
    _requireSession();
    if (stepUpProof == null ||
        stepUpProof.proof.trim().isEmpty ||
        !stepUpProof.isRecent) {
      throw GovernedAutoresearchActionBlockedException(
        'Step-up authentication is required for this action.',
      );
    }
    if (requiresSecondOperator &&
        (secondOperatorApproval == null ||
            secondOperatorApproval.actorAlias.trim().isEmpty ||
            secondOperatorApproval.actorAlias == actorAlias ||
            secondOperatorApproval.proof.trim().isEmpty ||
            !secondOperatorApproval.isRecent)) {
      throw GovernedAutoresearchActionBlockedException(
        'A second distinct admin_operator approval is required for this action.',
      );
    }
  }

  Future<void> _appendAudit(String action, Map<String, dynamic> details) async {
    final raw =
        _auditPrefs.getString('admin.control_plane.audit_events.test.v1');
    final entries = raw == null || raw.isEmpty
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList(growable: true);
    entries.add(<String, dynamic>{'action': action, 'details': details});
    await _auditPrefs.setString(
      'admin.control_plane.audit_events.test.v1',
      jsonEncode(entries),
    );
  }
}

class InternalBackendGovernedAutoresearchSupervisor
    implements GovernedAutoresearchSupervisor {
  InternalBackendGovernedAutoresearchSupervisor({
    required AdminControlPlaneGateway gateway,
  }) : _gateway = gateway;

  final AdminControlPlaneGateway _gateway;

  Future<bool> canConnect() => _gateway.canConnect();

  @override
  Stream<List<ResearchRunState>> watchRuns() => _gateway.watchResearchRuns();

  @override
  Future<List<ResearchRunState>> listRuns() => _gateway.listResearchRuns();

  @override
  Future<ResearchRunState?> watchRun(String runId) =>
      _gateway.watchResearchRun(runId);

  @override
  Future<List<ResearchAlert>> listAlerts() => _gateway.listResearchAlerts();

  @override
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) =>
      _gateway.approveCharter(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
      );

  @override
  Future<ResearchRunState> rejectCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) =>
      _gateway.rejectCharter(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
      );

  @override
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  }) =>
      _gateway.queueRun(runId: runId, actorAlias: actorAlias);

  @override
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  }) =>
      _gateway.startSandboxRun(runId: runId, actorAlias: actorAlias);

  @override
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) =>
      _gateway.pauseRun(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
      );

  @override
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  }) =>
      _gateway.resumeRun(runId: runId, actorAlias: actorAlias);

  @override
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) =>
      _gateway.stopRun(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
        stepUpProof: stepUpProof,
      );

  @override
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) =>
      _gateway.redirectRun(
        runId: runId,
        actorAlias: actorAlias,
        directive: directive,
        stepUpProof: stepUpProof,
      );

  @override
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  }) =>
      _gateway.getExplanation(runId: runId, actorAlias: actorAlias);

  @override
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) =>
      _gateway.reviewCandidate(
        runId: runId,
        actorAlias: actorAlias,
        approved: approved,
        rationale: rationale,
        stepUpProof: stepUpProof,
        secondOperatorApproval: secondOperatorApproval,
      );

  @override
  Future<ResearchRunState> addOperatorNote({
    required String runId,
    required String actorAlias,
    required String note,
  }) =>
      _gateway.addOperatorNote(
        runId: runId,
        actorAlias: actorAlias,
        note: note,
      );

  @override
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  }) =>
      _gateway.checkpointRun(
        runId: runId,
        actorAlias: actorAlias,
        summary: summary,
        metricSnapshot: metricSnapshot,
        requiresHumanReview: requiresHumanReview,
        contradictionDetected: contradictionDetected,
      );

  @override
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  }) =>
      _gateway.appendArtifact(
        runId: runId,
        actorAlias: actorAlias,
        kind: kind,
        storageKey: storageKey,
        summary: summary,
        isRedacted: isRedacted,
        checksum: checksum,
      );

  @override
  Future<void> emitAlert(ResearchAlert alert) => _gateway.emitAlert(alert);

  @override
  Future<ResearchApproval> requestEgressApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
  }) =>
      _gateway.requestOpenWebApproval(
        runId: runId,
        actorAlias: actorAlias,
        ttl: ttl,
        rationale: rationale,
      );

  @override
  Future<ResearchApproval> requestOpenWebAccess({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) =>
      _gateway.requestOpenWebApproval(
        runId: runId,
        actorAlias: actorAlias,
        ttl: ttl,
        rationale: rationale,
        stepUpProof: stepUpProof,
      );

  @override
  Future<ResearchApproval> approveOpenWeb({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    required AdminControlPlaneStepUpProof stepUpProof,
    required AdminControlPlaneSecondOperatorApproval secondOperatorApproval,
    String rationale = '',
  }) =>
      _gateway.approveOpenWeb(
        runId: runId,
        actorAlias: actorAlias,
        ttl: ttl,
        stepUpProof: stepUpProof,
        secondOperatorApproval: secondOperatorApproval,
        rationale: rationale,
      );

  @override
  Future<ResearchApproval> rejectOpenWeb({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
  }) =>
      _gateway.rejectOpenWeb(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
        stepUpProof: stepUpProof,
      );

  @override
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  }) =>
      _gateway.fetchEvidence(
        runId: runId,
        actorAlias: actorAlias,
        sourceUri: sourceUri,
      );

  @override
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  }) =>
      _gateway.revokeAccess(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
      );

  @override
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  }) =>
      _gateway.recordDisposition(
        runId: runId,
        actorAlias: actorAlias,
        approved: approved,
        rationale: rationale,
      );

  @override
  Future<ResearchRunState> triggerKillSwitch({
    required String runId,
    required String actorAlias,
    String rationale = '',
    AdminControlPlaneStepUpProof? stepUpProof,
    AdminControlPlaneSecondOperatorApproval? secondOperatorApproval,
  }) =>
      _gateway.triggerKillSwitch(
        runId: runId,
        actorAlias: actorAlias,
        rationale: rationale,
        stepUpProof: stepUpProof ??
            AdminControlPlaneStepUpProof(
              proof: '',
              issuedAt: DateTime.now().toUtc(),
            ),
        secondOperatorApproval: secondOperatorApproval ??
            AdminControlPlaneSecondOperatorApproval(
              actorAlias: '',
              proof: '',
              approvedAt: DateTime.now().toUtc(),
            ),
      );

  @override
  Future<ResearchArtifactRef> downloadEvidencePack({
    required String runId,
    required String actorAlias,
    required List<String> artifactIds,
    AdminControlPlaneStepUpProof? stepUpProof,
  }) =>
      _gateway.downloadEvidencePack(
        runId: runId,
        actorAlias: actorAlias,
        artifactIds: artifactIds,
        stepUpProof: stepUpProof,
      );
}

void _requireState(
  ResearchRunState run, {
  required List<ResearchRunLifecycleState> allowed,
  required String message,
}) {
  if (!allowed.contains(run.lifecycleState)) {
    throw GovernedAutoresearchActionBlockedException(message);
  }
}

List<ResearchRunState> _sortedRuns(List<ResearchRunState> runs) {
  final sorted = List<ResearchRunState>.from(runs);
  sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sorted;
}

List<ResearchAlert> _deriveAlerts(List<ResearchRunState> runs) {
  final alerts = <ResearchAlert>[];
  final now = DateTime.now().toUtc();
  for (final ResearchRunState run in runs) {
    alerts.addAll(run.alerts);
    if (run.lifecycleState == ResearchRunLifecycleState.running &&
        run.lastHeartbeatAt != null &&
        now.difference(run.lastHeartbeatAt!) > const Duration(hours: 2)) {
      alerts.add(
        ResearchAlert(
          id: 'alert_stale_${run.id}',
          runId: run.id,
          severity: ResearchAlertSeverity.warning,
          title: 'Stale heartbeat',
          message: 'Running sandbox has not checkpointed recently.',
          createdAt: now,
        ),
      );
    }
    if ((run.metrics['policyViolationCount'] ?? 0) > 0 ||
        run.contradictionDetected) {
      alerts.add(
        ResearchAlert(
          id: 'alert_policy_${run.id}',
          runId: run.id,
          severity: ResearchAlertSeverity.critical,
          title: 'Policy safeguard triggered',
          message:
              'Contradiction or policy violation detected; review is required before continuation.',
          createdAt: now,
        ),
      );
    }
    final openWebPending = run.approvals.any(
      (ResearchApproval approval) =>
          approval.kind == ResearchApprovalKind.egressOpenWeb &&
          approval.status == ResearchApprovalStatus.pending,
    );
    if (openWebPending) {
      alerts.add(
        ResearchAlert(
          id: 'alert_egress_${run.id}',
          runId: run.id,
          severity: ResearchAlertSeverity.info,
          title: 'Egress approval pending',
          message:
              'Open-web evidence remains blocked until an admin approves brokered access.',
          createdAt: now,
        ),
      );
    }
  }
  return alerts;
}

ResearchCheckpoint _buildCheckpoint({
  required String runId,
  required ResearchRunLifecycleState state,
  required String summary,
  required Map<String, double> metricSnapshot,
  required DateTime createdAt,
  bool requiresHumanReview = false,
  bool contradictionDetected = false,
}) {
  return ResearchCheckpoint(
    id: _generateId('chk'),
    runId: runId,
    summary: summary,
    state: state,
    createdAt: createdAt,
    metricSnapshot: metricSnapshot,
    artifactIds: const <String>[],
    requiresHumanReview: requiresHumanReview,
    contradictionDetected: contradictionDetected,
  );
}

ResearchControlAction _buildControlAction({
  required String runId,
  required String actorAlias,
  required ResearchControlActionType actionType,
  required String rationale,
  required DateTime createdAt,
  required String modelVersion,
  required String policyVersion,
  String? checkpointId,
  Map<String, dynamic> details = const <String, dynamic>{},
}) {
  return ResearchControlAction(
    id: _generateId('ctl'),
    runId: runId,
    actionType: actionType,
    actorAlias: actorAlias,
    rationale: rationale,
    createdAt: createdAt,
    modelVersion: modelVersion,
    policyVersion: policyVersion,
    details: details,
    checkpointId: checkpointId,
  );
}

List<ResearchApproval> _replacePendingApproval(
  List<ResearchApproval> approvals,
  ResearchApproval replacement,
) {
  final updated = <ResearchApproval>[];
  var replaced = false;
  for (final ResearchApproval approval in approvals) {
    if (!replaced &&
        approval.kind == replacement.kind &&
        approval.status == ResearchApprovalStatus.pending) {
      updated.add(replacement);
      replaced = true;
      continue;
    }
    updated.add(approval);
  }
  if (!replaced) {
    updated.add(replacement);
  }
  return updated;
}

String _currentStepForState(ResearchRunLifecycleState state) {
  switch (state) {
    case ResearchRunLifecycleState.draft:
      return 'Awaiting admin charter review.';
    case ResearchRunLifecycleState.approved:
      return 'Ready for sandbox queueing.';
    case ResearchRunLifecycleState.queued:
      return 'Queued for replay/sandbox execution.';
    case ResearchRunLifecycleState.running:
      return 'Running in sandbox/replay lane.';
    case ResearchRunLifecycleState.pausing:
      return 'Cooperatively pausing at checkpoint boundary.';
    case ResearchRunLifecycleState.paused:
      return 'Paused and safe for human intervention.';
    case ResearchRunLifecycleState.review:
      return 'Waiting for human review.';
    case ResearchRunLifecycleState.stopped:
      return 'Stopped and preserved for audit.';
    case ResearchRunLifecycleState.completed:
      return 'Completed in sandbox and awaiting promotion path.';
    case ResearchRunLifecycleState.failed:
      return 'Failed and requires audit triage.';
    case ResearchRunLifecycleState.redirectPending:
      return 'Redirect captured and awaiting revised charter path.';
    case ResearchRunLifecycleState.archived:
      return 'Archived with immutable history.';
  }
}

String _nextStepForState(ResearchRunLifecycleState state) {
  switch (state) {
    case ResearchRunLifecycleState.draft:
      return 'Approve or reject the charter.';
    case ResearchRunLifecycleState.approved:
      return 'Queue the run for sandbox execution.';
    case ResearchRunLifecycleState.queued:
      return 'Runtime supervisor may start sandbox execution.';
    case ResearchRunLifecycleState.running:
      return 'Continue checkpointing until review or completion.';
    case ResearchRunLifecycleState.pausing:
      return 'Await a safe checkpoint.';
    case ResearchRunLifecycleState.paused:
      return 'Resume, stop, or redirect the run.';
    case ResearchRunLifecycleState.review:
      return 'Approve, reject, or redirect based on evidence.';
    case ResearchRunLifecycleState.stopped:
      return 'Review audit trail or archive.';
    case ResearchRunLifecycleState.completed:
      return 'Hand off to governed promotion review.';
    case ResearchRunLifecycleState.failed:
      return 'Inspect alerts and checkpoint evidence.';
    case ResearchRunLifecycleState.redirectPending:
      return 'Issue revised charter or archive.';
    case ResearchRunLifecycleState.archived:
      return 'No further action required.';
  }
}

String _evidenceSummary(ResearchRunState run) {
  final artifactCount = run.artifacts.length;
  final checkpointCount = run.checkpoints.length;
  final egress = run.hasApprovedOpenWebAccess
      ? 'brokered open-web approved'
      : 'internal evidence only';
  return '$checkpointCount checkpoints, $artifactCount artifacts, $egress.';
}

String _generateId(String prefix) {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  return '${prefix}_$micros';
}
