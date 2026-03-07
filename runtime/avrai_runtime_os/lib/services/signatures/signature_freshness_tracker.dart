class SignatureFreshnessTracker {
  const SignatureFreshnessTracker();

  double fromTimestamp(
    DateTime? updatedAt, {
    Duration decayWindow = const Duration(days: 14),
    DateTime? now,
  }) {
    if (updatedAt == null) {
      return 0.45;
    }

    final reference = now ?? DateTime.now();
    final elapsed = reference.difference(updatedAt);
    if (elapsed.isNegative) {
      return 1.0;
    }

    final ratio = elapsed.inMilliseconds / decayWindow.inMilliseconds;
    return (1.0 - ratio).clamp(0.0, 1.0);
  }

  double blend(Iterable<double> parts, {double defaultValue = 0.5}) {
    final values = parts.toList();
    if (values.isEmpty) {
      return defaultValue;
    }
    return (values.fold<double>(0.0, (sum, value) => sum + value) /
            values.length)
        .clamp(0.0, 1.0);
  }
}
