import 'package:avrai_core/models/temporal/temporal_instant.dart';

class TemporalInterval {
  const TemporalInterval({
    required this.start,
    required this.end,
  });

  final TemporalInstant start;
  final TemporalInstant end;

  Duration get duration => end.referenceTime.difference(start.referenceTime);

  Map<String, dynamic> toJson() {
    return {
      'start': start.toJson(),
      'end': end.toJson(),
    };
  }

  factory TemporalInterval.fromJson(Map<String, dynamic> json) {
    return TemporalInterval(
      start: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['start'] as Map),
      ),
      end: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['end'] as Map),
      ),
    );
  }
}
