import 'package:avrai_core/models/temporal/forecast_outcome_kind.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class ForecastResolutionRecord {
  const ForecastResolutionRecord({
    required this.resolutionId,
    required this.forecastId,
    required this.forecastFamilyId,
    required this.subjectId,
    required this.outcomeKind,
    required this.resolvedAt,
    this.actualOutcomeLabel,
    this.actualOutcomeValue,
    this.sphereId,
    this.truthScope,
    this.metadata = const <String, dynamic>{},
  });

  final String resolutionId;
  final String forecastId;
  final String forecastFamilyId;
  final String subjectId;
  final ForecastOutcomeKind outcomeKind;
  final DateTime resolvedAt;
  final String? actualOutcomeLabel;
  final double? actualOutcomeValue;
  final String? sphereId;
  final TruthScopeDescriptor? truthScope;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resolutionId': resolutionId,
      'forecastId': forecastId,
      'forecastFamilyId': forecastFamilyId,
      'subjectId': subjectId,
      'outcomeKind': outcomeKind.name,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'actualOutcomeLabel': actualOutcomeLabel,
      'actualOutcomeValue': actualOutcomeValue,
      'sphereId': sphereId,
      'truthScope': truthScope?.toJson(),
      'metadata': metadata,
    };
  }

  factory ForecastResolutionRecord.fromJson(Map<String, dynamic> json) {
    return ForecastResolutionRecord(
      resolutionId: json['resolutionId'] as String? ?? '',
      forecastId: json['forecastId'] as String? ?? '',
      forecastFamilyId: json['forecastFamilyId'] as String? ?? '',
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
      sphereId: json['sphereId'] as String?,
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
