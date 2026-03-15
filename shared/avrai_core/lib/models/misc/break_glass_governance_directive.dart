import '../atomic_timestamp.dart';
import 'governance_inspection.dart';

enum BreakGlassActionType {
  featureDisable,
  rollbackToSafeVersion,
  trustAnchorRotation,
  quarantineRuntimeOrCluster,
  highDetailDiagnosticCapture,
}

class BreakGlassGovernanceDirective {
  BreakGlassGovernanceDirective({
    required this.directiveId,
    required this.actorId,
    required this.targetRuntimeId,
    required this.targetStratum,
    required this.actionType,
    required this.reasonCode,
    required this.signedDirectiveRef,
    required this.issuedAt,
    required this.expiresAt,
    required this.requiresDualApproval,
  });

  final String directiveId;
  final String actorId;
  final String targetRuntimeId;
  final GovernanceStratum targetStratum;
  final BreakGlassActionType actionType;
  final String reasonCode;
  final String signedDirectiveRef;
  final AtomicTimestamp issuedAt;
  final AtomicTimestamp expiresAt;
  final bool requiresDualApproval;

  Map<String, dynamic> toJson() {
    return {
      'directiveId': directiveId,
      'actorId': actorId,
      'targetRuntimeId': targetRuntimeId,
      'targetStratum': targetStratum.name,
      'actionType': actionType.name,
      'reasonCode': reasonCode,
      'signedDirectiveRef': signedDirectiveRef,
      'issuedAt': issuedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      'requiresDualApproval': requiresDualApproval,
    };
  }

  factory BreakGlassGovernanceDirective.fromJson(Map<String, dynamic> json) {
    return BreakGlassGovernanceDirective(
      directiveId: json['directiveId'] as String,
      actorId: json['actorId'] as String,
      targetRuntimeId: json['targetRuntimeId'] as String,
      targetStratum: GovernanceStratum.values.firstWhere(
        (value) => value.name == json['targetStratum'],
      ),
      actionType: BreakGlassActionType.values.firstWhere(
        (value) => value.name == json['actionType'],
      ),
      reasonCode: json['reasonCode'] as String,
      signedDirectiveRef: json['signedDirectiveRef'] as String,
      issuedAt:
          AtomicTimestamp.fromJson(json['issuedAt'] as Map<String, dynamic>),
      expiresAt:
          AtomicTimestamp.fromJson(json['expiresAt'] as Map<String, dynamic>),
      requiresDualApproval: json['requiresDualApproval'] as bool,
    );
  }
}

class BreakGlassGovernanceReceipt {
  BreakGlassGovernanceReceipt({
    required this.directive,
    required this.approved,
    required this.auditRef,
    required this.evaluatedAt,
    required this.failureCodes,
  });

  final BreakGlassGovernanceDirective directive;
  final bool approved;
  final String auditRef;
  final AtomicTimestamp evaluatedAt;
  final List<String> failureCodes;

  Map<String, dynamic> toJson() {
    return {
      'directive': directive.toJson(),
      'approved': approved,
      'auditRef': auditRef,
      'evaluatedAt': evaluatedAt.toJson(),
      'failureCodes': failureCodes,
    };
  }

  factory BreakGlassGovernanceReceipt.fromJson(Map<String, dynamic> json) {
    return BreakGlassGovernanceReceipt(
      directive: BreakGlassGovernanceDirective.fromJson(
        json['directive'] as Map<String, dynamic>,
      ),
      approved: json['approved'] as bool,
      auditRef: json['auditRef'] as String,
      evaluatedAt:
          AtomicTimestamp.fromJson(json['evaluatedAt'] as Map<String, dynamic>),
      failureCodes: List<String>.from(json['failureCodes'] as List<dynamic>),
    );
  }
}
