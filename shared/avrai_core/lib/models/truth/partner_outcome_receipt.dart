import 'package:avrai_core/models/temporal/forecast_outcome_kind.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class PartnerOutcomeReceipt {
  const PartnerOutcomeReceipt({
    required this.tenantId,
    required this.scope,
    required this.forecastId,
    required this.subjectId,
    required this.outcomeKind,
    required this.resolvedAt,
    required this.signerId,
    required this.signature,
    required this.idempotencyKey,
    this.actualOutcomeLabel,
    this.actualOutcomeValue,
    this.metadata = const <String, dynamic>{},
  }) : assert(
          actualOutcomeLabel != null || actualOutcomeValue != null,
          'A partner outcome receipt must carry an actual outcome.',
        );

  final String tenantId;
  final TruthScopeDescriptor scope;
  final String forecastId;
  final String subjectId;
  final ForecastOutcomeKind outcomeKind;
  final DateTime resolvedAt;
  final String? actualOutcomeLabel;
  final double? actualOutcomeValue;
  final String signerId;
  final String signature;
  final String idempotencyKey;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tenantId': tenantId,
      'scope': scope.toJson(),
      'forecastId': forecastId,
      'subjectId': subjectId,
      'outcomeKind': outcomeKind.name,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'actualOutcomeLabel': actualOutcomeLabel,
      'actualOutcomeValue': actualOutcomeValue,
      'signerId': signerId,
      'signature': signature,
      'idempotencyKey': idempotencyKey,
      'metadata': metadata,
    };
  }

  factory PartnerOutcomeReceipt.fromJson(Map<String, dynamic> json) {
    return PartnerOutcomeReceipt(
      tenantId: json['tenantId'] as String? ?? '',
      scope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(json['scope'] as Map? ?? const {}),
      ),
      forecastId: json['forecastId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == json['outcomeKind'],
        orElse: () => ForecastOutcomeKind.binary,
      ),
      resolvedAt: DateTime.parse(
        json['resolvedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                .toIso8601String(),
      ),
      actualOutcomeLabel: json['actualOutcomeLabel'] as String?,
      actualOutcomeValue: (json['actualOutcomeValue'] as num?)?.toDouble(),
      signerId: json['signerId'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
