import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

enum Ai2AiTransportRetentionChannel {
  dm,
  community,
}

enum Ai2AiTransportRetentionOutcome {
  consumed,
  failed,
}

class Ai2AiTransportRetentionEvent {
  final Ai2AiTransportRetentionChannel channel;
  final Ai2AiTransportRetentionOutcome outcome;
  final String messageId;
  final String recipientUserId;
  final String? recipientDeviceId;
  final DateTime occurredAtUtc;
  final int deletedTransportCount;
  final int remainingTransportCount;
  final String? errorSummary;

  const Ai2AiTransportRetentionEvent({
    required this.channel,
    required this.outcome,
    required this.messageId,
    required this.recipientUserId,
    required this.occurredAtUtc,
    this.recipientDeviceId,
    this.deletedTransportCount = 0,
    this.remainingTransportCount = 0,
    this.errorSummary,
  });

  factory Ai2AiTransportRetentionEvent.fromJson(Map<String, dynamic> json) {
    return Ai2AiTransportRetentionEvent(
      channel: Ai2AiTransportRetentionChannel.values.firstWhere(
        (value) => value.name == json['channel'],
        orElse: () => Ai2AiTransportRetentionChannel.dm,
      ),
      outcome: Ai2AiTransportRetentionOutcome.values.firstWhere(
        (value) => value.name == json['outcome'],
        orElse: () => Ai2AiTransportRetentionOutcome.failed,
      ),
      messageId: json['message_id'] as String? ?? '',
      recipientUserId: json['recipient_user_id'] as String? ?? '',
      recipientDeviceId: json['recipient_device_id'] as String?,
      occurredAtUtc: DateTime.tryParse(json['occurred_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deletedTransportCount:
          (json['deleted_transport_count'] as num?)?.toInt() ?? 0,
      remainingTransportCount:
          (json['remaining_transport_count'] as num?)?.toInt() ?? 0,
      errorSummary: json['error_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channel': channel.name,
      'outcome': outcome.name,
      'message_id': messageId,
      'recipient_user_id': recipientUserId,
      'recipient_device_id': recipientDeviceId,
      'occurred_at_utc': occurredAtUtc.toIso8601String(),
      'deleted_transport_count': deletedTransportCount,
      'remaining_transport_count': remainingTransportCount,
      'error_summary': errorSummary,
    };
  }
}

class Ai2AiTransportRetentionSnapshot {
  final DateTime capturedAtUtc;
  final int dmConsumedCount;
  final int dmFailureCount;
  final int communityConsumedCount;
  final int communityFailureCount;
  final String? latestFailureSummary;
  final DateTime? latestFailureAtUtc;
  final List<Ai2AiTransportRetentionEvent> recentEvents;

  const Ai2AiTransportRetentionSnapshot({
    required this.capturedAtUtc,
    required this.dmConsumedCount,
    required this.dmFailureCount,
    required this.communityConsumedCount,
    required this.communityFailureCount,
    this.latestFailureSummary,
    this.latestFailureAtUtc,
    this.recentEvents = const <Ai2AiTransportRetentionEvent>[],
  });
}

class Ai2AiTransportRetentionTelemetryStore {
  static const String _boxName = 'spots_ai';
  static const String _stateKey = 'ai2ai_transport_retention_telemetry_v1';
  static const int _maxRecentEvents = 16;

  final StorageService _storageService;
  final DateTime Function() _nowUtc;

  Ai2AiTransportRetentionTelemetryStore({
    StorageService? storageService,
    DateTime Function()? nowUtc,
  })  : _storageService = storageService ?? StorageService.instance,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  Future<void> recordDmConsumeSuccess({
    required String messageId,
    required String recipientUserId,
    String? recipientDeviceId,
    required int deletedTransportCount,
    required int remainingTransportCount,
  }) {
    return _recordEvent(
      channel: Ai2AiTransportRetentionChannel.dm,
      outcome: Ai2AiTransportRetentionOutcome.consumed,
      messageId: messageId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      deletedTransportCount: deletedTransportCount,
      remainingTransportCount: remainingTransportCount,
    );
  }

  Future<void> recordDmConsumeFailure({
    required String messageId,
    required String recipientUserId,
    String? recipientDeviceId,
    required String errorSummary,
  }) {
    return _recordEvent(
      channel: Ai2AiTransportRetentionChannel.dm,
      outcome: Ai2AiTransportRetentionOutcome.failed,
      messageId: messageId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      errorSummary: errorSummary,
    );
  }

  Future<void> recordCommunityConsumeSuccess({
    required String messageId,
    required String recipientUserId,
    required int deletedTransportCount,
    required int remainingTransportCount,
  }) {
    return _recordEvent(
      channel: Ai2AiTransportRetentionChannel.community,
      outcome: Ai2AiTransportRetentionOutcome.consumed,
      messageId: messageId,
      recipientUserId: recipientUserId,
      deletedTransportCount: deletedTransportCount,
      remainingTransportCount: remainingTransportCount,
    );
  }

  Future<void> recordCommunityConsumeFailure({
    required String messageId,
    required String recipientUserId,
    required String errorSummary,
  }) {
    return _recordEvent(
      channel: Ai2AiTransportRetentionChannel.community,
      outcome: Ai2AiTransportRetentionOutcome.failed,
      messageId: messageId,
      recipientUserId: recipientUserId,
      errorSummary: errorSummary,
    );
  }

  Ai2AiTransportRetentionSnapshot snapshot({
    DateTime? capturedAtUtc,
  }) {
    final state = _readState();
    final recent =
        (state['recent_events'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (entry) => Ai2AiTransportRetentionEvent.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(growable: false);
    final latestFailureAtRaw = state['latest_failure_at_utc'] as String?;
    return Ai2AiTransportRetentionSnapshot(
      capturedAtUtc: capturedAtUtc ?? _nowUtc(),
      dmConsumedCount: (state['dm_consumed_count'] as num?)?.toInt() ?? 0,
      dmFailureCount: (state['dm_failure_count'] as num?)?.toInt() ?? 0,
      communityConsumedCount:
          (state['community_consumed_count'] as num?)?.toInt() ?? 0,
      communityFailureCount:
          (state['community_failure_count'] as num?)?.toInt() ?? 0,
      latestFailureSummary: state['latest_failure_summary'] as String?,
      latestFailureAtUtc: latestFailureAtRaw == null
          ? null
          : DateTime.tryParse(latestFailureAtRaw)?.toUtc(),
      recentEvents: recent,
    );
  }

  Future<void> _recordEvent({
    required Ai2AiTransportRetentionChannel channel,
    required Ai2AiTransportRetentionOutcome outcome,
    required String messageId,
    required String recipientUserId,
    String? recipientDeviceId,
    int deletedTransportCount = 0,
    int remainingTransportCount = 0,
    String? errorSummary,
  }) async {
    final state = _readState();
    final event = Ai2AiTransportRetentionEvent(
      channel: channel,
      outcome: outcome,
      messageId: messageId,
      recipientUserId: recipientUserId,
      recipientDeviceId: recipientDeviceId,
      occurredAtUtc: _nowUtc(),
      deletedTransportCount: deletedTransportCount,
      remainingTransportCount: remainingTransportCount,
      errorSummary: errorSummary,
    );
    final recent = (state['recent_events'] as List<dynamic>? ?? <dynamic>[])
        .cast<dynamic>()
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: true);
    recent.insert(0, event.toJson());
    if (recent.length > _maxRecentEvents) {
      recent.removeRange(_maxRecentEvents, recent.length);
    }

    switch (channel) {
      case Ai2AiTransportRetentionChannel.dm:
        final key = outcome == Ai2AiTransportRetentionOutcome.consumed
            ? 'dm_consumed_count'
            : 'dm_failure_count';
        state[key] = ((state[key] as num?)?.toInt() ?? 0) + 1;
        break;
      case Ai2AiTransportRetentionChannel.community:
        final key = outcome == Ai2AiTransportRetentionOutcome.consumed
            ? 'community_consumed_count'
            : 'community_failure_count';
        state[key] = ((state[key] as num?)?.toInt() ?? 0) + 1;
        break;
    }

    if (outcome == Ai2AiTransportRetentionOutcome.failed &&
        errorSummary != null &&
        errorSummary.isNotEmpty) {
      state['latest_failure_summary'] = errorSummary;
      state['latest_failure_at_utc'] = event.occurredAtUtc.toIso8601String();
    }

    state['recent_events'] = recent;
    await _writeState(state);
  }

  Map<String, dynamic> _readState() {
    try {
      final raw = _storageService.getObject<dynamic>(
        _stateKey,
        box: _boxName,
      );
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } on StateError {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  Future<void> _writeState(Map<String, dynamic> state) async {
    try {
      await _storageService.setObject(
        _stateKey,
        state,
        box: _boxName,
      );
    } on StateError {
      // Storage is not initialized in every execution surface; telemetry is
      // best-effort and should not disrupt transport or delivery.
    }
  }
}
