import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';
import 'package:avrai_core/models/temporal/temporal_uncertainty.dart';

class TemporalInstant {
  const TemporalInstant({
    required this.referenceTime,
    required this.civilTime,
    required this.timezoneId,
    required this.provenance,
    required this.uncertainty,
    this.monotonicTicks,
    this.atomicTimestamp,
  });

  final DateTime referenceTime;
  final DateTime civilTime;
  final String timezoneId;
  final TemporalProvenance provenance;
  final TemporalUncertainty uncertainty;
  final int? monotonicTicks;
  final AtomicTimestamp? atomicTimestamp;

  Map<String, dynamic> toJson() {
    return {
      'referenceTime': referenceTime.toIso8601String(),
      'civilTime': civilTime.toIso8601String(),
      'timezoneId': timezoneId,
      'provenance': provenance.toJson(),
      'uncertainty': uncertainty.toJson(),
      'monotonicTicks': monotonicTicks,
      'atomicTimestamp': atomicTimestamp?.toJson(),
    };
  }

  factory TemporalInstant.fromJson(Map<String, dynamic> json) {
    final atomicJson = json['atomicTimestamp'];
    return TemporalInstant(
      referenceTime: DateTime.parse(json['referenceTime'] as String),
      civilTime: DateTime.parse(json['civilTime'] as String),
      timezoneId: json['timezoneId'] as String? ?? 'UTC',
      provenance: TemporalProvenance.fromJson(
        Map<String, dynamic>.from(
          json['provenance'] as Map<String, dynamic>? ?? const {},
        ),
      ),
      uncertainty: TemporalUncertainty.fromJson(
        Map<String, dynamic>.from(
          json['uncertainty'] as Map<String, dynamic>? ?? const {},
        ),
      ),
      monotonicTicks: (json['monotonicTicks'] as num?)?.toInt(),
      atomicTimestamp: atomicJson is Map<String, dynamic>
          ? AtomicTimestamp.fromJson(atomicJson)
          : atomicJson is Map
              ? AtomicTimestamp.fromJson(Map<String, dynamic>.from(atomicJson))
              : null,
    );
  }
}
