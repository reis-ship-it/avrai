class HotLatencySummary {
  final int count;
  final int p50;
  final int p95;

  const HotLatencySummary({
    required this.count,
    required this.p50,
    required this.p95,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
        'p50_ms': p50,
        'p95_ms': p95,
      };
}

/// Minimal ring-buffer latency collector.
///
/// Keeps the last N samples and computes p50/p95 on demand.
class HotLatencyWindow {
  final int maxSamples;
  final List<int> _samples = <int>[];
  int _cursor = 0;

  HotLatencyWindow({required this.maxSamples});

  void add(int ms) {
    if (ms < 0) return;
    if (_samples.length < maxSamples) {
      _samples.add(ms);
      return;
    }
    _samples[_cursor] = ms;
    _cursor = (_cursor + 1) % maxSamples;
  }

  HotLatencySummary summary() {
    if (_samples.isEmpty) {
      return const HotLatencySummary(count: 0, p50: 0, p95: 0);
    }
    final sorted = List<int>.from(_samples)..sort();
    int pick(double q) {
      final idx = ((sorted.length - 1) * q).round().clamp(0, sorted.length - 1);
      return sorted[idx];
    }

    return HotLatencySummary(
      count: sorted.length,
      p50: pick(0.50),
      p95: pick(0.95),
    );
  }
}
