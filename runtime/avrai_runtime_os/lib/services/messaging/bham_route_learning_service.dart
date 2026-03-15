import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:get_storage/get_storage.dart';

class BhamRouteLearningService {
  static const String _storeName = 'bham_route_learning';
  static const String _signalsKey = 'signals_v1';

  Future<void> recordSignal(RouteLearningSignal signal) async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>(_signalsKey) ?? <dynamic>[];
    raw.add(_toJson(signal));
    await box.write(_signalsKey, raw);
  }

  Future<List<RouteLearningSignal>> getSignals() async {
    final box = GetStorage(_storeName);
    final raw = box.read<List<dynamic>>(_signalsKey) ?? <dynamic>[];
    return raw
        .map(
          (entry) => _fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  Future<double> learningBoostForMode(TransportMode mode) async {
    final signals = await getSignals();
    final relevant = signals.where((signal) => signal.mode == mode).toList();
    if (relevant.isEmpty) {
      return 0.0;
    }
    final successes = relevant.where((signal) => signal.success).length;
    return successes / relevant.length;
  }

  Map<String, dynamic> _toJson(RouteLearningSignal signal) => <String, dynamic>{
        'message_id': signal.messageId,
        'mode': signal.mode.name,
        'success': signal.success,
        'observed_at_utc': signal.observedAtUtc.toUtc().toIso8601String(),
        if (signal.latencyMs != null) 'latency_ms': signal.latencyMs,
        if (signal.locality != null) 'locality': signal.locality,
        if (signal.timeBucket != null) 'time_bucket': signal.timeBucket,
        'metadata': signal.metadata,
      };

  RouteLearningSignal _fromJson(Map<String, dynamic> json) =>
      RouteLearningSignal(
        messageId: json['message_id'] as String? ?? 'unknown_message',
        mode: TransportMode.values.firstWhere(
          (mode) => mode.name == json['mode'],
          orElse: () => TransportMode.wormhole,
        ),
        success: json['success'] as bool? ?? false,
        observedAtUtc:
            DateTime.tryParse(json['observed_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        latencyMs: (json['latency_ms'] as num?)?.toInt(),
        locality: json['locality'] as String?,
        timeBucket: json['time_bucket'] as String?,
        metadata: Map<String, dynamic>.from(
          json['metadata'] as Map? ?? const <String, dynamic>{},
        ),
      );
}
