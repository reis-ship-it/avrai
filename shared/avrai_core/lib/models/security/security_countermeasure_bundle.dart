import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class SecurityCountermeasureBundle {
  const SecurityCountermeasureBundle({
    required this.bundleId,
    required this.targetScope,
    required this.allowedStrata,
    required this.tenantScope,
    required this.evidenceEnvelopeTraceIds,
    required this.requiredApprovals,
    this.tenantId,
    this.expiresAt,
    this.rollbackTtl,
    this.minimumAcknowledgements = 1,
    this.signature,
    this.signedBy,
    this.signedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String bundleId;
  final TruthScopeDescriptor targetScope;
  final List<GovernanceStratum> allowedStrata;
  final TruthTenantScope tenantScope;
  final String? tenantId;
  final DateTime? expiresAt;
  final Duration? rollbackTtl;
  final int minimumAcknowledgements;
  final String? signature;
  final String? signedBy;
  final DateTime? signedAt;
  final List<String> evidenceEnvelopeTraceIds;
  final List<String> requiredApprovals;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bundleId': bundleId,
      'targetScope': targetScope.toJson(),
      'allowedStrata': allowedStrata.map((entry) => entry.name).toList(),
      'tenantScope': tenantScope.name,
      'tenantId': tenantId,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
      'rollbackTtlMs': rollbackTtl?.inMilliseconds,
      'minimumAcknowledgements': minimumAcknowledgements,
      'signature': signature,
      'signedBy': signedBy,
      'signedAt': signedAt?.toUtc().toIso8601String(),
      'evidenceEnvelopeTraceIds': evidenceEnvelopeTraceIds,
      'requiredApprovals': requiredApprovals,
      'metadata': metadata,
    };
  }

  factory SecurityCountermeasureBundle.fromJson(Map<String, dynamic> json) {
    return SecurityCountermeasureBundle(
      bundleId: json['bundleId'] as String? ?? '',
      targetScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(json['targetScope'] as Map? ?? const {}),
      ),
      allowedStrata: (json['allowedStrata'] as List?)
              ?.map(
                (entry) => GovernanceStratum.values.firstWhere(
                  (value) => value.name == entry,
                  orElse: () => GovernanceStratum.personal,
                ),
              )
              .toList() ??
          const <GovernanceStratum>[],
      tenantScope: TruthTenantScope.values.firstWhere(
        (value) => value.name == json['tenantScope'],
        orElse: () => TruthTenantScope.avraiNative,
      ),
      tenantId: json['tenantId'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'] as String)?.toUtc(),
      rollbackTtl: json['rollbackTtlMs'] == null
          ? null
          : Duration(
              milliseconds: (json['rollbackTtlMs'] as num?)?.toInt() ?? 0,
            ),
      minimumAcknowledgements:
          (json['minimumAcknowledgements'] as num?)?.toInt() ?? 1,
      signature: json['signature'] as String?,
      signedBy: json['signedBy'] as String?,
      signedAt: json['signedAt'] == null
          ? null
          : DateTime.tryParse(json['signedAt'] as String)?.toUtc(),
      evidenceEnvelopeTraceIds: (json['evidenceEnvelopeTraceIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      requiredApprovals: (json['requiredApprovals'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
