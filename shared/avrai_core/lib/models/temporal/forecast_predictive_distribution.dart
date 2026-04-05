import 'package:avrai_core/models/temporal/forecast_outcome_kind.dart';
import 'package:avrai_core/models/truth/forecast_representation_component.dart';

class ForecastPredictiveDistribution {
  const ForecastPredictiveDistribution({
    required this.outcomeKind,
    this.discreteProbabilities = const <String, double>{},
    this.quantiles = const <String, double>{},
    this.mean,
    this.variance,
    this.componentId,
    this.representationComponent,
    this.metadata = const <String, dynamic>{},
  });

  final ForecastOutcomeKind outcomeKind;
  final Map<String, double> discreteProbabilities;
  final Map<String, double> quantiles;
  final double? mean;
  final double? variance;
  final String? componentId;
  final ForecastRepresentationComponent? representationComponent;
  final Map<String, dynamic> metadata;

  double get topProbability {
    if (discreteProbabilities.isEmpty) {
      return 0.0;
    }
    return discreteProbabilities.values.reduce(
      (left, right) => left >= right ? left : right,
    );
  }

  String? get topOutcome {
    if (discreteProbabilities.isEmpty) {
      return null;
    }
    final sorted = discreteProbabilities.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return sorted.first.key;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'outcomeKind': outcomeKind.name,
      'discreteProbabilities': discreteProbabilities,
      'quantiles': quantiles,
      'mean': mean,
      'variance': variance,
      'componentId': componentId,
      'representationComponent': representationComponent?.name,
      'metadata': metadata,
    };
  }

  factory ForecastPredictiveDistribution.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(Object? raw) {
      return (raw as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toDouble() ?? 0.0,
            ),
          ) ??
          const <String, double>{};
    }

    return ForecastPredictiveDistribution(
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == json['outcomeKind'],
        orElse: () => ForecastOutcomeKind.binary,
      ),
      discreteProbabilities: toDoubleMap(json['discreteProbabilities']),
      quantiles: toDoubleMap(json['quantiles']),
      mean: (json['mean'] as num?)?.toDouble(),
      variance: (json['variance'] as num?)?.toDouble(),
      componentId: json['componentId'] as String?,
      representationComponent:
          ForecastRepresentationComponent.values.firstWhere(
        (value) => value.name == json['representationComponent'],
        orElse: () => (json['representationComponent'] == null
            ? ForecastRepresentationComponent.classical
            : ForecastRepresentationComponent.classical),
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
