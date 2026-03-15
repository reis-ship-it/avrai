import 'dart:async';

import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';

class MeshSegmentLifecycleRuntimeLane {
  MeshSegmentLifecycleRuntimeLane({
    required MeshSegmentCredentialRefreshService refreshService,
    Duration refreshThreshold = const Duration(minutes: 30),
    Duration refreshInterval = const Duration(minutes: 10),
    DateTime Function()? nowUtc,
  })  : _refreshService = refreshService,
        _refreshThreshold = refreshThreshold,
        _refreshInterval = refreshInterval,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final MeshSegmentCredentialRefreshService _refreshService;
  final Duration _refreshThreshold;
  final Duration _refreshInterval;
  final DateTime Function() _nowUtc;

  Timer? _timer;
  bool _started = false;
  int _lastRefreshedCount = 0;
  DateTime? _lastRanAtUtc;

  bool get started => _started;
  int get lastRefreshedCount => _lastRefreshedCount;
  DateTime? get lastRanAtUtc => _lastRanAtUtc;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await runRefreshCycle();
    _timer = Timer.periodic(_refreshInterval, (_) {
      unawaited(runRefreshCycle());
    });
  }

  Future<void> dispose() async {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<int> runRefreshCycle() async {
    _lastRanAtUtc = _nowUtc();
    _lastRefreshedCount = await _refreshService.refreshExpiringTrustMaterial(
      threshold: _refreshThreshold,
      nowUtc: _lastRanAtUtc,
    );
    return _lastRefreshedCount;
  }
}
