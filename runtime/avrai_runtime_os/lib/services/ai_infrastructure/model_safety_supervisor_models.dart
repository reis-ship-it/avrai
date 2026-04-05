part of 'model_safety_supervisor.dart';

class _Avg {
  final double avg;
  final int count;

  const _Avg({required this.avg, required this.count});
}

class _SignalEntry {
  final int? tsMs;
  final double? score;

  const _SignalEntry({required this.tsMs, required this.score});
}
